## `TerminalSession`, per the approved proposal for #5 and its two overrules.
##
## Covers what is specific to this adapter rather than to `CommandHandler`
## (already covered by `tests/unit/test_command_handler.gd`): the
## consecutive-blank-line counter, that a rejection leaves `SessionState`
## usable rather than ending the session, and bare-ingredient-name
## normalisation.
extends GutTest

const NOODLES: StringName = &"ingredient.thick_wheat_noodles"
const GREENS: StringName = &"ingredient.rooftop_lettuce"
const ALPHA: StringName = &"customer.alpha"


static func _content() -> ContentRepository:
	# Real shipped localisation keys, so `list` resolves display names the same
	# way the terminal does. The project registers its translation (#19), so
	# these resolve rather than echoing back.
	var noodles := IngredientDefinition.new()
	noodles.content_id = NOODLES
	noodles.name_key = &"ingredient.thick_wheat_noodles.name"
	noodles.description_key = &"ingredient.thick_wheat_noodles.description"
	noodles.comfort = 3

	var greens := IngredientDefinition.new()
	greens.content_id = GREENS
	greens.name_key = &"ingredient.rooftop_lettuce.name"
	greens.description_key = &"ingredient.rooftop_lettuce.description"
	greens.fresh = 3

	var alpha := CustomerDefinition.new()
	alpha.content_id = ALPHA
	alpha.name_key = &"customer.alpha.name"
	alpha.request_key = &"customer.alpha.request"
	alpha.reaction_key = &"customer.alpha.reaction"
	alpha.comfort_target = 3
	alpha.comfort_weight = 2

	var ingredients: Array[IngredientDefinition] = [noodles, greens]
	var customers: Array[CustomerDefinition] = [alpha]
	return InMemoryContentRepository.new(ingredients, customers)


static func _session_in_building_dish() -> TerminalSession:
	var session := TerminalSession.new(SessionState.new(), _content())
	session.handle_line("start")
	session.handle_line("present")
	return session


# --------------------------------------------------------------- blank lines --


## Godot 4.7's `OS` cannot distinguish a mid-stream blank Enter from an
## exhausted stdin (both `read_string_from_stdin()` calls return `""`), so the
## counter is what keeps one accidental Enter from ending a playtest session:
## the first two blanks must re-prompt, not quit.
func test_first_two_consecutive_blank_lines_reprompt_rather_than_quit() -> void:
	var session := TerminalSession.new(SessionState.new(), _content())

	var first: TerminalSession.LineResult = session.handle_line("")
	assert_false(first.should_quit, "the first blank line must not quit")

	var second: TerminalSession.LineResult = session.handle_line("")
	assert_false(second.should_quit, "the second blank line must not quit")


## The third consecutive blank both quits and does so without hanging --
## at EOF, `read_string_from_stdin()` keeps returning `""`, so a caller
## looping on this result reaches `should_quit` in exactly three bounded
## iterations.
func test_a_third_consecutive_blank_line_quits() -> void:
	var session := TerminalSession.new(SessionState.new(), _content())

	session.handle_line("")
	session.handle_line("")
	var third: TerminalSession.LineResult = session.handle_line("")

	assert_true(third.should_quit, "three consecutive blanks must quit")


func test_a_non_blank_line_resets_the_consecutive_blank_counter() -> void:
	var session := TerminalSession.new(SessionState.new(), _content())

	session.handle_line("")
	session.handle_line("")
	session.handle_line("start")  # non-blank: resets the counter

	var first_after: TerminalSession.LineResult = session.handle_line("")
	assert_false(first_after.should_quit, "the counter must have reset")
	var second_after: TerminalSession.LineResult = session.handle_line("")
	assert_false(second_after.should_quit, "still only two consecutive blanks")
	var third_after: TerminalSession.LineResult = session.handle_line("")
	assert_true(third_after.should_quit, "three consecutive blanks since the reset")


func test_list_is_answered_without_reaching_the_domain() -> void:
	# `list` is a query, not a command. It must work in NOT_STARTED, where every
	# one of the five real commands except `start` is rejected as INVALID_PHASE
	# -- there is no phase in which "what is in the pantry?" is invalid.
	var state := SessionState.new()
	var session := TerminalSession.new(state, _content())

	var result: TerminalSession.LineResult = session.handle_line("list")

	assert_false(result.should_quit)
	assert_eq(state.phase, SessionState.Phase.NOT_STARTED, "list must not change phase")
	assert_true(state.current_dish.is_empty(), "list must not change the dish")
	var joined: String = "\n".join(result.output)
	assert_true(joined.contains(String(NOODLES)), "the pantry must name the ids a player types")
	assert_true(joined.contains("Dish: empty"))


func test_list_shows_the_dish_under_construction_by_display_name() -> void:
	var session: TerminalSession = _session_in_building_dish()
	session.handle_line("select %s" % NOODLES)

	var joined: String = "\n".join(session.handle_line("list").output)

	# The id is what you type; the name is what you read. Every other line this
	# adapter prints uses the display name, and this one must not be the odd one.
	assert_true(joined.contains("Dish: Thick Wheat Noodles"), "dish must list display names")
	assert_false(joined.contains("Dish: %s" % NOODLES), "dish must not print raw ids")


func test_quit_command_ends_the_session_immediately() -> void:
	var session := TerminalSession.new(SessionState.new(), _content())
	var result: TerminalSession.LineResult = session.handle_line("quit")
	assert_true(result.should_quit)


# ------------------------------------------------------ unparseable input --


func test_unparseable_input_does_not_quit_and_leaves_state_unchanged() -> void:
	var state := SessionState.new()
	var session := TerminalSession.new(state, _content())

	var result: TerminalSession.LineResult = session.handle_line("frobnicate")

	assert_false(result.should_quit)
	assert_eq(state.phase, SessionState.Phase.NOT_STARTED, "unparseable input must not reach state")


# ------------------------------------------------------- rejection recovery --


## The duplicated-`select`-then-succeed path required by the approval: a
## rejection must not corrupt the dish under construction, and the session
## must still be usable afterward.
func test_a_rejected_duplicate_select_leaves_state_usable_for_a_correct_one() -> void:
	var session: TerminalSession = _session_in_building_dish()

	var first_select: TerminalSession.LineResult = session.handle_line("select %s" % NOODLES)
	assert_false(first_select.should_quit)

	var duplicate: TerminalSession.LineResult = session.handle_line("select %s" % NOODLES)
	assert_false(duplicate.should_quit)
	assert_eq(duplicate.output.size(), 1)
	assert_string_contains(duplicate.output[0], "already in the dish")

	# The rejection did not corrupt state: submitting the still-valid dish
	# (noodles alone; comfort target 3, weight 2 -> a perfect match) succeeds.
	var submit: TerminalSession.LineResult = session.handle_line("submit")
	assert_false(submit.should_quit)
	var joined: String = "\n".join(submit.output)
	assert_string_contains(joined, "Delighted")


# --------------------------------------------------------- bare ingredient --


func test_select_accepts_a_bare_ingredient_name() -> void:
	var session: TerminalSession = _session_in_building_dish()
	var bare: TerminalSession.LineResult = session.handle_line("select thick_wheat_noodles")
	assert_false(bare.should_quit)
	assert_string_contains("\n".join(bare.output), "Added")


func test_select_accepts_the_full_ingredient_id() -> void:
	var session: TerminalSession = _session_in_building_dish()
	var full: TerminalSession.LineResult = session.handle_line(
		"select ingredient.thick_wheat_noodles"
	)
	assert_false(full.should_quit)
	assert_string_contains("\n".join(full.output), "Added")


func test_a_bare_name_and_its_full_id_select_the_same_ingredient() -> void:
	var bare_session: TerminalSession = _session_in_building_dish()
	bare_session.handle_line("select thick_wheat_noodles")
	var bare_result: TerminalSession.LineResult = bare_session.handle_line("submit")

	var full_session: TerminalSession = _session_in_building_dish()
	full_session.handle_line("select ingredient.thick_wheat_noodles")
	var full_result: TerminalSession.LineResult = full_session.handle_line("submit")

	assert_eq(bare_result.output, full_result.output, "both spellings must reach the same dish")


func test_an_unknown_bare_name_still_reports_unknown_ingredient() -> void:
	var session: TerminalSession = _session_in_building_dish()
	var result: TerminalSession.LineResult = session.handle_line("select bogus")
	assert_false(result.should_quit)
	assert_eq(result.output.size(), 1)
	assert_string_contains(result.output[0], "Unknown ingredient")
