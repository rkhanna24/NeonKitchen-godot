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

## The slice runs one customer. `solar_tech` has no constraint and eleven dishes
## that reach 100, which makes it the gentlest possible first target -- the point
## here is that the wiring works, not that the puzzle is hard.
const SLICE_CUSTOMER: StringName = &"customer.solar_tech"

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

var _session: KitchenSession = null

var _request_label: RichTextLabel = null
var _constraint_label: Label = null
var _dish_label: Label = null
var _feedback_label: RichTextLabel = null
var _notice_label: Label = null
var _serve_button: Button = null
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
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(left)

	_request_label = RichTextLabel.new()
	_request_label.fit_content = true
	_request_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_request_label)

	_constraint_label = Label.new()
	_constraint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_constraint_label)

	_dish_label = Label.new()
	left.add_child(_dish_label)

	_serve_button = Button.new()
	_serve_button.text = "Serve"
	_serve_button.pressed.connect(_on_serve_pressed)
	left.add_child(_serve_button)

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


func _begin() -> void:
	var roster: Array[StringName] = [SLICE_CUSTOMER]
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


func _on_serve_pressed() -> void:
	_apply(_session.submit())


## The single place a `CommandResult` reaches the screen. A rejection is shown,
## never swallowed: ADR 0004 section 10 makes an invalid action a real outcome
## with a reason, and a UI that greys the problem away teaches the player less
## than one that says what it refused and why.
func _apply(result: CommandResult) -> void:
	if not result.is_accepted:
		_notice_label.text = _rejection_text(result)
		return
	_notice_label.text = ""
	for event: DomainEvent in result.events:
		_render(event)
	_refresh_dish()


func _rejection_text(result: CommandResult) -> String:
	if not result.has_rejection_reason:
		return "That action was not accepted."

	# One assignment and one return rather than a return per branch, to stay
	# under the project's lint limit on returns per function.
	var text: String = "That action was not accepted."
	match result.rejection_reason:
		CommandResult.Reason.DISH_FULL:
			text = "The dish already holds %d ingredients." % Flavor.MAX_DISH_SIZE
		CommandResult.Reason.EMPTY_DISH:
			text = "Add at least one ingredient before serving."
		CommandResult.Reason.DUPLICATE_INGREDIENT:
			text = "That ingredient is already in the dish."
		CommandResult.Reason.NOT_SELECTED:
			text = "That ingredient is not in the dish."
		CommandResult.Reason.INVALID_PHASE:
			text = "Not now."
		CommandResult.Reason.UNKNOWN_INGREDIENT:
			text = "No such ingredient."
		CommandResult.Reason.UNKNOWN_CUSTOMER:
			text = "No such customer."
		CommandResult.Reason.EMPTY_ROSTER:
			text = "There is nobody to serve."
	return text


func _render(event: DomainEvent) -> void:
	if event is CustomerPresented:
		_render_customer((event as CustomerPresented).customer_id)
	elif event is DishEvaluated:
		_render_evaluation((event as DishEvaluated).evaluation)
	elif event is CustomerReacted:
		var key: StringName = (event as CustomerReacted).reaction_key
		_feedback_label.append_text("\n\n%s" % TranslationServer.translate(key))


func _render_customer(customer_id: StringName) -> void:
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
	var parts: Array[String] = ["%s -- %d" % [_band_name(evaluation.band), evaluation.score]]
	if evaluation.has_strongest_match:
		parts.append("Strongest match: %s" % Flavor.dimension_name(evaluation.strongest_match))
	if evaluation.has_largest_miss:
		parts.append("Largest miss: %s" % Flavor.dimension_name(evaluation.largest_miss))
	for violated: Evaluation.ViolatedConstraint in evaluation.violated_constraints:
		parts.append(String(TranslationServer.translate(violated.explanation_key)))
	_feedback_label.text = "\n".join(parts)


func _band_name(band: Evaluation.RatingBand) -> String:
	match band:
		Evaluation.RatingBand.DELIGHTED:
			return "Delighted"
		Evaluation.RatingBand.SATISFIED:
			return "Satisfied"
		Evaluation.RatingBand.MIXED:
			return "Mixed"
		_:
			return "Dissatisfied"


func _refresh_dish() -> void:
	var names: Array[String] = []
	for ingredient_id: StringName in _session.state().current_dish:
		var ingredient: IngredientDefinition = _session.content().find_ingredient(ingredient_id)
		if ingredient != null:
			names.append(String(TranslationServer.translate(ingredient.name_key)))
	_dish_label.text = "Dish: %s" % ("empty" if names.is_empty() else ", ".join(names))
