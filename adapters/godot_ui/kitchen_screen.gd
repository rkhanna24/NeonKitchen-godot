## The Phase 2 vertical slice screen (#32): one customer, request through
## feedback, in real `Control` nodes.
##
## Renders from the events `CommandHandler` emits, never by asking the domain to
## score anything. Nothing in this file imports `Evaluator`, `FlavourScorer` or
## `ConstraintChecker`, and a test asserts that stays true -- GDD section 5.1
## requires that neither interface "contain scoring or constraint logic", and the
## cheapest way for a UI to break that rule is to recompute a number it already
## has in an event.
##
## The layout is built in code rather than authored as a `.tscn`. Two reasons:
## a scene file is the one artefact in this repository a reviewer cannot read a
## diff of usefully, and the slice's whole claim is that the UI is a thin
## adapter -- which is checkable when the wiring is source and not when it is
## node metadata. Breadth work may well move this into a scene; the slice does
## not need to.
class_name KitchenScreen
extends Control

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

## The one place that names the active theme (docs/design/Visual Language.md,
## ADR 0002 section 6, DEC-034). Trying a different palette is editing this
## path, never a sweep of this file or any other.
const THEME_PATH: String = "res://assets/themes/solarpunk_tempered.tres"

var _session: KitchenSession = null

var _request_label: RichTextLabel = null
var _constraint_label: Label = null
var _dish_label: Label = null
var _feedback_label: RichTextLabel = null
var _notice_label: Label = null
var _primary_button: Button = null
var _pantry_box: VBoxContainer = null


func _ready() -> void:
	var content := TresContentRepository.new()
	var problems: PackedStringArray = content.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	if not problems.is_empty():
		_fail_loudly(problems)
		return

	_session = KitchenSession.new(SessionState.new(), content)
	_build_layout()
	_populate_pantry()
	_begin()


## A content error blanks the screen and says so, rather than opening an empty
## kitchen. The terminal prints the problems and exits non-zero; the equivalent
## here is refusing to present a playable-looking UI backed by nothing.
func _fail_loudly(problems: PackedStringArray) -> void:
	var label := Label.new()
	label.text = "Content failed to load:\n\n%s" % "\n".join(problems)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)


func _build_layout() -> void:
	# Applied once, here, at the screen root. Every child inherits it; no
	# descendant sets its own theme or an inline colour, size, or spacing
	# override (tests/unit/test_kitchen_screen.gd checks the source for that).
	theme = load(THEME_PATH) as Theme
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	_request_label = RichTextLabel.new()
	_request_label.fit_content = true
	_request_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# The `request` type size (docs/design/Visual Language.md section Type):
	# the customer speaking is the one thing on this screen sized apart from
	# body text. A role name, not a size -- the pixel value lives only in the
	# theme resource.
	_request_label.theme_type_variation = &"RequestText"
	left.add_child(_request_label)

	_constraint_label = Label.new()
	_constraint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_constraint_label)

	_dish_label = Label.new()
	left.add_child(_dish_label)

	_primary_button = Button.new()
	# `accent` names "the primary action" (docs/design/Visual Language.md);
	# Serve/Next customer is the only button that is one.
	_primary_button.theme_type_variation = &"PrimaryButton"
	_primary_button.pressed.connect(_on_primary_pressed)
	left.add_child(_primary_button)

	_notice_label = Label.new()
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_notice_label)

	_feedback_label = RichTextLabel.new()
	_feedback_label.fit_content = true
	_feedback_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_feedback_label)

	var right := ScrollContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)

	_pantry_box = VBoxContainer.new()
	_pantry_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_pantry_box)


## Grouped in `IngredientDefinition.GROUPS` order, matching the terminal listing
## (DEC-029). Headings only -- nothing here implies a dish wants one from each,
## because measuring that showed it is worse for six of the eight customers.
func _populate_pantry() -> void:
	var by_group: Dictionary[StringName, Array] = {}
	for ingredient: IngredientDefinition in _session.content().all_ingredients():
		if not by_group.has(ingredient.group):
			by_group[ingredient.group] = []
		by_group[ingredient.group].append(ingredient)

	for group: StringName in IngredientDefinition.GROUPS:
		if not by_group.has(group):
			continue
		var heading := Label.new()
		heading.text = String(TranslationServer.translate(StringName("pantry.group.%s" % group)))
		# The `label` type size names "group headings" by name
		# (docs/design/Visual Language.md section Type).
		heading.theme_type_variation = &"GroupHeading"
		_pantry_box.add_child(heading)
		for ingredient: IngredientDefinition in by_group[group]:
			_pantry_box.add_child(_ingredient_button(ingredient))


func _ingredient_button(ingredient: IngredientDefinition) -> Button:
	var button := Button.new()
	button.text = String(TranslationServer.translate(ingredient.name_key))
	button.tooltip_text = String(TranslationServer.translate(ingredient.description_key))
	# Bound rather than read back off the button text: the text is a translated
	# display name and the command needs the stable `content_id`.
	button.pressed.connect(_on_ingredient_pressed.bind(ingredient.content_id))
	return button


## Every customer in repository order -- the same list `TerminalSession`
## builds. #32 ran one customer because the slice was proving the wiring; the
## service is the whole roster.
func _begin() -> void:
	var roster: Array[StringName] = []
	for customer: CustomerDefinition in _session.content().all_customers():
		roster.append(customer.content_id)
	_apply(_session.start(roster))
	_apply(_session.present())


func _on_ingredient_pressed(ingredient_id: StringName) -> void:
	# One button toggles: selecting an ingredient already in the dish removes it.
	# `CommandHandler` rejects a duplicate rather than ignoring it, so reading
	# the dish first is what turns a rejection into an intent.
	if _session.state().current_dish.has(ingredient_id):
		_apply(_session.remove(ingredient_id))
	else:
		_apply(_session.select(ingredient_id))


## `SHOWING_RESULT` accepts `PresentCustomer`, which returns either the next
## customer or `SessionEnded` when the roster is exhausted (ADR 0004 section 7a).
## The screen cannot know which in advance and does not try: one button, and it
## renders whichever event comes back.
func _on_primary_pressed() -> void:
	if _session.state().phase == SessionState.Phase.SHOWING_RESULT:
		_apply(_session.present())
	else:
		_apply(_session.submit())


## The single place a `CommandResult` reaches the screen. A rejection is shown,
## never swallowed: ADR 0004 section 10 makes an invalid action a real outcome
## with a reason, and a UI that greys the problem away teaches the player less
## than one that says what it refused and why.
func _apply(result: CommandResult) -> void:
	if not result.is_accepted:
		_notice_label.text = _rejection_text(result)
		_sync_controls()
		return
	_notice_label.text = ""
	for event: DomainEvent in result.events:
		_render(event)
	_refresh_dish()
	_sync_controls()


## What the player can do depends on the phase, so the screen shows only that.
## Leaving every control live and letting `CommandHandler` reject the press is
## how the terminal behaves, and reproducing it here would be the terminal's
## failure mode wearing a button: the refusal arrives after the click instead of
## the click never being offered.
func _sync_controls() -> void:
	var phase: SessionState.Phase = _session.state().phase
	var building: bool = phase == SessionState.Phase.BUILDING_DISH
	var showing: bool = phase == SessionState.Phase.SHOWING_RESULT

	for child: Node in _pantry_box.get_children():
		if child is Button:
			(child as Button).disabled = not building

	_primary_button.visible = building or showing
	_primary_button.text = "Serve" if building else "Next customer"


func _rejection_text(result: CommandResult) -> String:
	if not result.has_rejection_reason:
		return "That action was not accepted."
	return EncounterText.rejection_text(result.rejection_reason)


func _render(event: DomainEvent) -> void:
	if event is CustomerPresented:
		_render_customer((event as CustomerPresented).customer_id)
	elif event is DishEvaluated:
		_render_evaluation((event as DishEvaluated).evaluation)
	elif event is SessionEnded:
		_render_summary((event as SessionEnded).results)
	elif event is CustomerReacted:
		var key: StringName = (event as CustomerReacted).reaction_key
		_feedback_label.append_text("\n\n%s" % TranslationServer.translate(key))


## A new customer arrives to a clear counter. The feedback panel still holds the
## previous encounter's band, score and reaction at this moment, and leaving it
## there would attach one customer's result to the next one's request -- the
## worst possible misreading, since the panel is exactly where the player looks
## to decide what to cook.
func _render_customer(customer_id: StringName) -> void:
	_feedback_label.text = ""
	var customer: CustomerDefinition = _session.content().find_customer(customer_id)
	if customer == null:
		return
	_request_label.text = (
		"%s\n\n%s"
		% [
			TranslationServer.translate(customer.name_key),
			TranslationServer.translate(customer.request_key),
		]
	)
	var lines: Array[String] = []
	for constraint: CustomerConstraint in customer.constraints:
		lines.append(String(TranslationServer.translate(constraint.explanation_key)))
	_constraint_label.text = "\n".join(lines)


## Reads the evaluation it was handed. Every number here was computed by the
## domain and carried in the event; none of it is recomputed.
func _render_evaluation(evaluation: Evaluation) -> void:
	var parts: Array[String] = [
		"%s -- %d" % [EncounterText.band_label(evaluation.band), evaluation.score]
	]
	if evaluation.has_strongest_match:
		parts.append(
			"Strongest match: %s" % EncounterText.dimension_label(evaluation.strongest_match)
		)
	if evaluation.has_largest_miss:
		parts.append("Largest miss: %s" % EncounterText.dimension_label(evaluation.largest_miss))
	for violated: Evaluation.ViolatedConstraint in evaluation.violated_constraints:
		parts.append(String(TranslationServer.translate(violated.explanation_key)))
	_feedback_label.text = "\n".join(parts)


## The end of the night. Reads `EncounterResult` values recorded at the time
## each dish was served -- ADR 0004 section 8 stores them by value precisely so
## no re-evaluation is needed here, and re-deriving anything would be a second
## scoring path.
func _render_summary(results: Array[EncounterResult]) -> void:
	var lines: Array[String] = ["That's the night."]
	var position: int = 1
	for result: EncounterResult in results:
		lines.append("%d. %s" % [position, EncounterText.summary_line(result, _session.content())])
		position += 1
	_feedback_label.text = "\n".join(lines)
	_request_label.text = ""
	_constraint_label.text = ""


func _refresh_dish() -> void:
	var names: Array[String] = []
	for ingredient_id: StringName in _session.state().current_dish:
		var ingredient: IngredientDefinition = _session.content().find_ingredient(ingredient_id)
		if ingredient != null:
			names.append(String(TranslationServer.translate(ingredient.name_key)))
	_dish_label.text = "Dish: %s" % ("empty" if names.is_empty() else ", ".join(names))
