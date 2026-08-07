## One played terminal session (#5): parses a line, issues at most one
## approved command, and formats the result as text.
##
## Owns no game rule. `TerminalInputParser` turns a line into an intent;
## `CommandHandler` (`core/application`) decides whether it is accepted and
## produces events; `TerminalPresenter` turns those events, or a rejection
## reason, into English. This file's own logic is limited to: recognising a
## blank line, building one of the five approved commands from a parsed
## intent, and normalising a bare ingredient name -- everything else is a
## direct call to one of those three.
##
## Constructed once by the composition root (`bootstrap/main.gd`) and driven
## one line at a time, in-process, so the smoke case
## (`tests/smoke/test_terminal_smoke.gd`) can call `handle_line()` directly
## with no subprocess and no real stdin -- exactly how `CommandHandler` itself
## is tested.
class_name TerminalSession
extends RefCounted

## Three consecutive blank lines end the session; see `_handle_blank_line`.
const _BLANK_QUIT_THRESHOLD: int = 3

var _state: SessionState
var _content: ContentRepository
var _consecutive_blank_lines: int = 0


func _init(state: SessionState, content: ContentRepository) -> void:
	_state = state
	_content = content


## The result of handling one line: text to print, and whether the session
## should end. `should_quit` is `true` only for an explicit `quit` or the
## third consecutive blank line -- never as a side effect of a rejection or of
## reaching `SessionState.Phase.ENDED`, since a human may still want to read
## the summary before quitting.
class LineResult:
	extends RefCounted

	var should_quit: bool
	var output: Array[String]

	func _init(p_should_quit: bool, p_output: Array[String]) -> void:
		should_quit = p_should_quit
		output = p_output


## Handles exactly one input line. A blank line and an unparseable line are
## both handled entirely on this side: neither reaches `CommandHandler`, so
## neither can corrupt `SessionState`.
func handle_line(line: String) -> LineResult:
	if line.strip_edges().is_empty():
		return _handle_blank_line()
	_consecutive_blank_lines = 0
	return _dispatch(TerminalInputParser.parse(line))


## Split from `handle_line` to keep the blank-line branch and the verb
## dispatch each below the project's lint limit on return statements per
## function. `INVALID` and `QUIT` are handled here, entirely on the adapter
## side; the five approved commands are routed on to `_dispatch_command`.
func _dispatch(parsed: TerminalInputParser.ParsedLine) -> LineResult:
	if parsed.verb == TerminalInputParser.Verb.INVALID:
		return LineResult.new(false, [parsed.error_message] as Array[String])
	if parsed.verb == TerminalInputParser.Verb.QUIT:
		return LineResult.new(true, ["Goodbye."] as Array[String])
	if parsed.verb == TerminalInputParser.Verb.LIST:
		return _handle_list()
	return _dispatch_command(parsed)


## `list` is a query, not a command: it reads content and session state,
## changes neither, and emits no event. So it is answered here rather than
## routed to `CommandHandler` — sending it there would mean inventing a sixth
## command ADR 0004 section 7 does not have.
##
## Legal in every phase, including `NOT_STARTED` and `ENDED`. There is no
## phase in which "what is in the pantry?" is an invalid question, and
## `INVALID_PHASE` exists for commands that would change state.
func _handle_list() -> LineResult:
	return LineResult.new(
		false, TerminalPresenter.present_pantry(_content.all_ingredients(), _state.current_dish)
	)


func _dispatch_command(parsed: TerminalInputParser.ParsedLine) -> LineResult:
	match parsed.verb:
		TerminalInputParser.Verb.START:
			return _handle_start()
		TerminalInputParser.Verb.PRESENT:
			return _handle_present()
		TerminalInputParser.Verb.SELECT:
			return _handle_select(parsed.argument)
		TerminalInputParser.Verb.REMOVE:
			return _handle_remove(parsed.argument)
		TerminalInputParser.Verb.SUBMIT:
			return _handle_submit()
		_:
			return LineResult.new(false, ["internal error: unhandled verb"] as Array[String])


## A blank line re-prompts rather than quitting -- overruling the original
## proposal, which would have treated it as `quit`.
##
## The reason a counter exists at all, rather than simply ignoring blank
## input: Godot 4.7's `OS` exposes only `read_string_from_stdin`,
## `read_buffer_from_stdin`, and `get_stdin_type`, and none of them
## distinguish a mid-stream blank Enter from an exhausted stream (EOF) --
## both return `""`. Treating `""` as `quit` outright means one accidental
## Enter ends a playtest session, which is the worst possible moment: ADR
## 0004 section 12's protocol has a human reading a result and thinking
## before the next encounter. So a single blank re-prompts, and only three in
## a row -- read as deliberate -- end the session. At EOF, every subsequent
## read also returns `""`, so the loop still terminates: three fast,
## bounded iterations, never a hang.
func _handle_blank_line() -> LineResult:
	_consecutive_blank_lines += 1
	if _consecutive_blank_lines >= _BLANK_QUIT_THRESHOLD:
		return LineResult.new(
			true, ["No input three times in a row -- ending session."] as Array[String]
		)
	return LineResult.new(false, ["(type a command, or press Enter twice more to quit)"])


func _handle_start() -> LineResult:
	var customer_ids: Array[StringName] = []
	for customer: CustomerDefinition in _content.all_customers():
		customer_ids.append(customer.content_id)
	var result: CommandResult = CommandHandler.handle_start_session(
		_state, _content, StartSession.new(customer_ids)
	)
	return _present_events(result)


func _handle_present() -> LineResult:
	var result: CommandResult = CommandHandler.handle_present_customer(
		_state, _content, PresentCustomer.new()
	)
	return _present_events(result)


## A bare ingredient name (no `.`) is prefixed with `ingredient.` before it is
## looked up, so `select thick_wheat_noodles` and `select ingredient.thick_wheat_noodles`
## both resolve to the same command. This is one deterministic rule, not an
## alias table -- it exists because ids are namespaced, and an id that still
## does not resolve after the prefix is added reaches `CommandHandler`
## unchanged and is rejected as `UNKNOWN_INGREDIENT` exactly as a full,
## unknown id would be.
func _handle_select(raw_id: String) -> LineResult:
	var ingredient_id: StringName = _normalize_ingredient_id(raw_id)
	var result: CommandResult = CommandHandler.handle_select_ingredient(
		_state, _content, SelectIngredient.new(ingredient_id)
	)
	return _present_events(result)


func _handle_remove(raw_id: String) -> LineResult:
	var ingredient_id: StringName = _normalize_ingredient_id(raw_id)
	var result: CommandResult = CommandHandler.handle_remove_ingredient(
		_state, _content, RemoveIngredient.new(ingredient_id)
	)
	return _present_events(result)


## The customer served is read before `SubmitDish` runs (rather than after)
## because `CommandHandler.handle_submit_dish` moves the phase to
## `SHOWING_RESULT`, not out of the roster -- `state.current_customer_id()`
## is unaffected either way. Read early only so this function does not depend
## on that phase transition leaving it readable, which section 7a already
## guarantees but which is not this file's contract to lean on silently.
func _handle_submit() -> LineResult:
	var customer: CustomerDefinition = _content.find_customer(_state.current_customer_id())
	var result: CommandResult = CommandHandler.handle_submit_dish(
		_state, _content, SubmitDish.new()
	)
	if not result.is_accepted:
		return _present_events(result)

	# Section 7a: SubmitDish emits exactly DishSubmitted, DishEvaluated,
	# CustomerReacted, in that order.
	var lines: Array[String] = []
	var dish_submitted := result.events[0] as DishSubmitted
	lines.append_array(TerminalPresenter.present_dish_submitted(dish_submitted, _content))
	var dish_evaluated := result.events[1] as DishEvaluated
	lines.append_array(TerminalPresenter.present_dish_evaluated(dish_evaluated, customer))
	var customer_reacted := result.events[2] as CustomerReacted
	lines.append_array(TerminalPresenter.present_customer_reacted(customer_reacted))
	return LineResult.new(false, lines)


func _normalize_ingredient_id(raw_id: String) -> StringName:
	if raw_id.contains("."):
		return StringName(raw_id)
	return StringName("ingredient.%s" % raw_id)


## Shared handling for the four commands whose accepted result is exactly
## one event: `StartSession` (`SessionStarted`), `SelectIngredient`
## (`IngredientSelected`), `RemoveIngredient` (`IngredientRemoved`), and
## `PresentCustomer` (`CustomerPresented` or `SessionEnded`, per section 7a).
## `SubmitDish` is handled separately by `_handle_submit`, since its three
## events (in fixed order) each need a different presenter call and
## `DishEvaluated` additionally needs the served customer.
func _present_events(result: CommandResult) -> LineResult:
	if not result.is_accepted:
		return LineResult.new(false, [TerminalPresenter.rejection_text(result.rejection_reason)])

	var lines: Array[String] = []
	for event: DomainEvent in result.events:
		if event is SessionStarted:
			lines.append_array(TerminalPresenter.present_session_started(event as SessionStarted))
		elif event is CustomerPresented:
			lines.append_array(
				TerminalPresenter.present_customer_presented(event as CustomerPresented, _content)
			)
		elif event is SessionEnded:
			lines.append_array(
				TerminalPresenter.present_session_ended(event as SessionEnded, _content)
			)
		elif event is IngredientSelected:
			lines.append_array(
				TerminalPresenter.present_ingredient_selected(event as IngredientSelected, _content)
			)
		elif event is IngredientRemoved:
			lines.append_array(
				TerminalPresenter.present_ingredient_removed(event as IngredientRemoved, _content)
			)
		else:
			lines.append("internal error: unpresented event %s" % event)
	return LineResult.new(false, lines)
