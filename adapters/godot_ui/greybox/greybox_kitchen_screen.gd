## A time-boxed, disposable greybox of the phased request/preparation screen
## in docs/design/references/godot-greybox-ideas.md and
## docs/design/references/frame-notes-and-greybox-brief.md.
##
## `KitchenScreen` (../kitchen_screen.gd) is left untouched and keeps running
## the existing vertical slice. This file is design evidence, built against
## the same `KitchenSession` seam, to test a different presentation: the
## request and preparation are two focused player-facing screens inside one
## food truck rather than one combined panel.
##
## Renders only from `DomainEvent`/`CommandResult`, the same rule
## `KitchenScreen` documents: nothing here imports `Evaluator`, `FlavourScorer`
## or `ConstraintChecker`, and no flavour value (`FlavorProfile`,
## `IngredientSelected.dish_profile`, `IngredientRemoved.dish_profile`) is ever
## read for display -- ruled out on #35.
##
## ## Presentation-only view state
##
## The domain's `BUILDING_DISH` phase covers both the request and the
## preparation screen: `PresentCustomer` already leaves the session in
## `BUILDING_DISH` the moment a customer is presented, before the player has
## seen the request at all (`core/application/command_handler.gd`). The
## request-to-ticket moment is therefore a presentation-only substate the
## screen alone tracks (`_view`), exactly as the plan document specifies in
## its section 4: "The screen controller owns which view is visible and when
## the preparation controls become active." No domain phase, event, or
## command is added for it.
##
## ## Top-level containers, and why
##
## Each view's top-level children are positioned with **anchors**, not a
## `VBoxContainer`/`HBoxContainer` wrapping the whole view: they are the
## "large spatial zones" the plan's step 1 names, and the plan's own scene
## tree lists them as direct, anchored siblings of `CustomerView` and
## `PreparationView`. A `Container` is used **inside** each zone, for that
## zone's own children -- a `VBoxContainer` inside `DialoguePanel`, `Worktop`,
## and `FeedbackSlip`; an `HFlowContainer` for the pantry; an `HBoxContainer`
## for the tray row. That split -- anchors for zones, containers inside them
## -- is the plan's own guidance in section 1, followed literally here.
class_name GreyboxKitchenScreen
extends Control

## The presentation-only substates `BUILDING_DISH` covers, plus the two
## `SessionState.Phase` values that map onto a view one-for-one
## (`SHOWING_RESULT` -> `RESULT`, `ENDED` -> `ENDED`).
enum View { REQUEST, PREPARATION, RESULT, ENDED }

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

## The one place that names the active theme -- see `KitchenScreen.THEME_PATH`
## for why this is a path and never a sweep of the file.
const THEME_PATH: String = "res://assets/themes/solarpunk_tempered.tres"

## Recorded as a hypothesis (plan section 1), not adopted: `project.godot`'s
## window size is a project-wide setting and changing it is out of scope for
## a time-boxed experiment scoped to this one screen. Tests size the harness
## against this constant instead.
const HYPOTHESIS_MIN_SIZE: Vector2 = Vector2(1280, 720)

## Presentation-only bin widths per `IngredientDefinition.group` (plan section
## 3: "keep this size mapping in the presentation prototype; do not add it to
## `IngredientDefinition`"). A guess at which groups read as narrow, standard,
## or wide bins -- unverified without seeing it rendered; see the handoff.
const _GROUP_MIN_WIDTH: Dictionary[StringName, float] = {
	&"broth_and_fat": 232.0,
	&"heat_and_ferment": 128.0,
	&"fresh_and_cured": 152.0,
	&"staple": 176.0,
}
const _DEFAULT_MIN_WIDTH: float = 160.0

var _session: KitchenSession = null
var _view: View = View.REQUEST

var _customer_view: Control = null
var _dialogue_request_label: RichTextLabel = null
var _dialogue_avoid_label: Label = null
var _confirm_button: Button = null
var _served_dish_panel: PanelContainer = null
var _served_dish_label: Label = null
var _feedback_panel: PanelContainer = null
var _feedback_label: RichTextLabel = null
var _next_customer_button: Button = null

var _preparation_view: Control = null
var _ticket_header_label: Label = null
var _ticket_request_label: RichTextLabel = null
var _ticket_avoid_label: Label = null
var _inspection_label: RichTextLabel = null
var _pantry_flow: HFlowContainer = null
var _tray_labels: Array[Label] = []
var _serve_button: Button = null

var _notice_label: Label = null


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


## Mirrors `KitchenScreen._fail_loudly()`: a content error blanks the screen
## and says so rather than opening an empty kitchen.
func _fail_loudly(problems: PackedStringArray) -> void:
	var label := Label.new()
	label.text = "Content failed to load:\n\n%s" % "\n".join(problems)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)


# ------------------------------------------------------------- layout ----


func _build_layout() -> void:
	theme = load(THEME_PATH) as Theme
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_customer_view = Control.new()
	_customer_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_customer_view)
	_build_customer_view(_customer_view)

	_preparation_view = Control.new()
	_preparation_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preparation_view)
	_build_preparation_view(_preparation_view)

	# Added last so it draws over whichever view is visible -- a rejection
	# must stay legible regardless of which screen it interrupts.
	_notice_label = Label.new()
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_zone(_notice_label, 0.04, 0.94, 0.96, 1.0)
	add_child(_notice_label)


## Anchors one zone's four edges as fractions of its parent's rect. The one
## place every zone rectangle in this file is set, so the proportions below
## can be judged and changed in one pass -- see the handoff for which of these
## are guesses.
func _zone(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom


func _build_customer_view(parent: Control) -> void:
	# The city outside, in the token this palette already names for it: "the
	# block outside the truck" (docs/design/Visual Language.md's token table).
	# Read off the loaded theme at runtime rather than written as a literal:
	# rule 2's "no hex value appears anywhere but the theme resource" binds
	# here exactly as it binds `KitchenScreen`, and this is how
	# `tests/unit/test_kitchen_screen.gd` itself reads a token to check it.
	var city_backdrop := ColorRect.new()
	city_backdrop.color = theme.get_color("background", "Tokens")
	_zone(city_backdrop, 0.0, 0.0, 1.0, 0.16)
	parent.add_child(city_backdrop)

	_build_placeholder_block(parent, 0.04, 0.20, 0.28, 0.60)

	_served_dish_panel = PanelContainer.new()
	_zone(_served_dish_panel, 0.04, 0.64, 0.46, 0.92)
	parent.add_child(_served_dish_panel)
	_served_dish_label = Label.new()
	_served_dish_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_served_dish_panel.add_child(_served_dish_label)

	_feedback_panel = PanelContainer.new()
	_zone(_feedback_panel, 0.50, 0.64, 0.96, 0.92)
	parent.add_child(_feedback_panel)
	var feedback_column := VBoxContainer.new()
	_feedback_panel.add_child(feedback_column)
	_feedback_label = RichTextLabel.new()
	_feedback_label.fit_content = true
	_feedback_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feedback_column.add_child(_feedback_label)
	_next_customer_button = Button.new()
	_next_customer_button.text = "Next customer"
	_next_customer_button.theme_type_variation = &"PrimaryButton"
	_next_customer_button.pressed.connect(_on_next_pressed)
	feedback_column.add_child(_next_customer_button)

	var dialogue_panel := PanelContainer.new()
	_zone(dialogue_panel, 0.32, 0.20, 0.96, 0.60)
	parent.add_child(dialogue_panel)
	var dialogue_column := VBoxContainer.new()
	dialogue_panel.add_child(dialogue_column)
	_dialogue_request_label = RichTextLabel.new()
	_dialogue_request_label.fit_content = true
	_dialogue_request_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_request_label.theme_type_variation = &"RequestText"
	dialogue_column.add_child(_dialogue_request_label)
	_dialogue_avoid_label = Label.new()
	_dialogue_avoid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_column.add_child(_dialogue_avoid_label)
	_confirm_button = Button.new()
	_confirm_button.text = "Okay"
	_confirm_button.theme_type_variation = &"PrimaryButton"
	_confirm_button.pressed.connect(_on_confirm_pressed)
	dialogue_column.add_child(_confirm_button)


## The stand-in "CUSTOMER" art block (plan section 2: "Customer art can be a
## rectangle labelled CUSTOMER"). `disabled_surface` marks it as placeholder
## rather than finished art -- reusing an existing token rather than inventing
## one, for the same rule 2 reason `city_backdrop` reads its token at runtime.
func _build_placeholder_block(
	parent: Control, left: float, top: float, right: float, bottom: float
) -> void:
	var wrapper := Control.new()
	_zone(wrapper, left, top, right, bottom)
	parent.add_child(wrapper)
	var fill := ColorRect.new()
	fill.color = theme.get_color("disabled_surface", "Tokens")
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(fill)
	var label := Label.new()
	label.text = "CUSTOMER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(label)


func _build_preparation_view(parent: Control) -> void:
	var ticket := PanelContainer.new()
	_zone(ticket, 0.04, 0.04, 0.96, 0.22)
	parent.add_child(ticket)
	var ticket_column := VBoxContainer.new()
	ticket.add_child(ticket_column)
	_ticket_header_label = Label.new()
	_ticket_header_label.theme_type_variation = &"GroupHeading"
	ticket_column.add_child(_ticket_header_label)
	_ticket_request_label = RichTextLabel.new()
	_ticket_request_label.fit_content = true
	_ticket_request_label.theme_type_variation = &"RequestText"
	ticket_column.add_child(_ticket_request_label)
	_ticket_avoid_label = Label.new()
	_ticket_avoid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_column.add_child(_ticket_avoid_label)

	var worktop := PanelContainer.new()
	_zone(worktop, 0.04, 0.26, 0.96, 0.96)
	parent.add_child(worktop)
	var worktop_layout := VBoxContainer.new()
	worktop.add_child(worktop_layout)

	_inspection_label = RichTextLabel.new()
	_inspection_label.fit_content = true
	_inspection_label.text = "Focus or hover a pantry item to inspect it."
	worktop_layout.add_child(_inspection_label)

	var pantry_scroll := ScrollContainer.new()
	pantry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	worktop_layout.add_child(pantry_scroll)
	_pantry_flow = HFlowContainer.new()
	_pantry_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pantry_scroll.add_child(_pantry_flow)

	var composition_row := HBoxContainer.new()
	worktop_layout.add_child(composition_row)
	_tray_labels = []
	for _slot: int in range(Flavor.MAX_DISH_SIZE):
		var slot := PanelContainer.new()
		composition_row.add_child(slot)
		var slot_label := Label.new()
		slot_label.text = "(empty)"
		slot.add_child(slot_label)
		_tray_labels.append(slot_label)
	_serve_button = Button.new()
	_serve_button.text = "Serve"
	_serve_button.theme_type_variation = &"PrimaryButton"
	_serve_button.pressed.connect(_on_serve_pressed)
	composition_row.add_child(_serve_button)


## Grouped ingredient headings are dropped from this greybox's pantry -- the
## plan's own scene tree (section headline) lists one flat `PantryFlow`, and
## an `HFlowContainer` wraps a heading as just another block, which reads
## worse than `KitchenScreen`'s grouped `VBoxContainer` listing. Flagged in
## the handoff as a difference from `KitchenScreen` worth a second look.
func _populate_pantry() -> void:
	for ingredient: IngredientDefinition in _session.content().all_ingredients():
		_pantry_flow.add_child(_ingredient_block(ingredient))


func _ingredient_block(ingredient: IngredientDefinition) -> GreyboxIngredientBlock:
	var block := GreyboxIngredientBlock.new()
	var min_width: float = _DEFAULT_MIN_WIDTH
	if _GROUP_MIN_WIDTH.has(ingredient.group):
		min_width = _GROUP_MIN_WIDTH[ingredient.group]
	block.setup(ingredient, min_width)
	block.pressed.connect(_on_ingredient_pressed.bind(ingredient.content_id))
	block.mouse_entered.connect(_on_ingredient_inspect.bind(ingredient))
	block.focus_entered.connect(_on_ingredient_inspect.bind(ingredient))
	return block


# --------------------------------------------------------------- flow ----


func _begin() -> void:
	var roster: Array[StringName] = []
	for customer: CustomerDefinition in _session.content().all_customers():
		roster.append(customer.content_id)
	_apply(_session.start(roster))
	_apply(_session.present())


func _on_ingredient_pressed(ingredient_id: StringName) -> void:
	if _session.state().current_dish.has(ingredient_id):
		_apply(_session.remove(ingredient_id))
	else:
		_apply(_session.select(ingredient_id))


## `mouse_entered` and `focus_entered` both land here (plan section 3), so a
## mouse user hovering and a keyboard user tabbing see the same description.
func _on_ingredient_inspect(ingredient: IngredientDefinition) -> void:
	_inspection_label.text = (
		"%s\n\n%s"
		% [
			EncounterText.translate(ingredient.name_key),
			EncounterText.translate(ingredient.description_key),
		]
	)


## Screen-only: no `KitchenSession` call. This is the presentation-only
## substate transition the class doc describes -- the domain is already in
## `BUILDING_DISH` and has nothing left to accept here.
func _on_confirm_pressed() -> void:
	_set_view(View.PREPARATION)


func _on_serve_pressed() -> void:
	_apply(_session.submit())


func _on_next_pressed() -> void:
	_apply(_session.present())


func _apply(result: CommandResult) -> void:
	if not result.is_accepted:
		_notice_label.text = _rejection_text(result)
		return
	_notice_label.text = ""
	for event: DomainEvent in result.events:
		_render(event)
	_refresh_tray()


func _rejection_text(result: CommandResult) -> String:
	if not result.has_rejection_reason:
		return "That action was not accepted."
	return EncounterText.rejection_text(result.rejection_reason)


func _render(event: DomainEvent) -> void:
	if event is CustomerPresented:
		_render_customer((event as CustomerPresented).customer_id)
		_set_view(View.REQUEST)
	elif event is DishSubmitted:
		_render_served_dish((event as DishSubmitted).ingredient_ids)
		_set_view(View.RESULT)
	elif event is DishEvaluated:
		_render_evaluation((event as DishEvaluated).evaluation)
	elif event is CustomerReacted:
		var key: StringName = (event as CustomerReacted).reaction_key
		_feedback_label.append_text("\n\n%s" % EncounterText.translate(key))
	elif event is SessionEnded:
		_render_summary((event as SessionEnded).results)
		_set_view(View.ENDED)
	# IngredientSelected/IngredientRemoved: no per-event rendering. `_apply`
	# already calls `_refresh_tray()` after every accepted result, which reads
	# `current_dish` directly rather than either event's `dish_profile` --
	# reading `dish_profile` would put a flavour value on screen, ruled out on
	# #35.


func _render_customer(customer_id: StringName) -> void:
	_served_dish_label.text = ""
	_feedback_label.text = ""
	var customer: CustomerDefinition = _session.content().find_customer(customer_id)
	if customer == null:
		return
	_dialogue_request_label.text = (
		"%s\n\n%s"
		% [
			EncounterText.translate(customer.name_key),
			EncounterText.translate(customer.request_key)
		]
	)
	var avoid: String = _avoid_line(customer)
	_dialogue_avoid_label.text = avoid
	_ticket_header_label.text = _ticket_header_text(customer)
	_ticket_request_label.text = EncounterText.translate(customer.request_key)
	_ticket_avoid_label.text = avoid


## Always present, even for the four of eight customers with no constraints
## (Service Cook.md names this exact gap: a panel that collapses when the
## constraint list is empty reflows the screen between customers). The line
## itself is UI meta-copy, not authored content -- "Avoid:" names what
## follows the same way `KitchenScreen`'s "Dish: %s" does; every clause it
## joins is still `constraint.explanation_key` text, unedited.
func _avoid_line(customer: CustomerDefinition) -> String:
	var lines: Array[String] = []
	for constraint: CustomerConstraint in customer.constraints:
		lines.append(EncounterText.translate(constraint.explanation_key))
	if lines.is_empty():
		return "Avoid: nothing this time"
	return "Avoid: %s" % "; ".join(lines)


## Renders `customer.<id>.ticket` when it resolves, per the context packet.
## Every shipped and fixture customer carries a non-empty `ticket_key`
## (`ContentValidator` requires it), so the empty-string fallback below is a
## defensive path this content set never exercises rather than a real branch.
func _ticket_header_text(customer: CustomerDefinition) -> String:
	var ticket_text: String = EncounterText.translate(customer.ticket_key)
	if not ticket_text.is_empty():
		return ticket_text
	return EncounterText.translate(customer.name_key)


func _render_served_dish(ingredient_ids: Array[StringName]) -> void:
	var names: Array[String] = []
	for ingredient_id: StringName in ingredient_ids:
		names.append(EncounterText.ingredient_name(ingredient_id, _session.content()))
	_served_dish_label.text = "Served: %s" % ", ".join(names)


## Reads the evaluation it was handed. Every number here was computed by the
## domain and carried in the event; none of it is recomputed -- and no
## `per_dimension` or flavour value is read at all, on screen or off.
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
		parts.append(EncounterText.translate(violated.explanation_key))
	_feedback_label.text = "\n".join(parts)


func _render_summary(results: Array[EncounterResult]) -> void:
	var lines: Array[String] = ["That's the night."]
	var position: int = 1
	for result: EncounterResult in results:
		lines.append("%d. %s" % [position, EncounterText.summary_line(result, _session.content())])
		position += 1
	_feedback_label.text = "\n".join(lines)
	_served_dish_label.text = ""
	_dialogue_request_label.text = ""
	_dialogue_avoid_label.text = ""


func _refresh_tray() -> void:
	var dish: Array[StringName] = _session.state().current_dish
	for index: int in range(_tray_labels.size()):
		if index < dish.size():
			_tray_labels[index].text = EncounterText.ingredient_name(
				dish[index], _session.content()
			)
		else:
			_tray_labels[index].text = "(empty)"
	for child: Node in _pantry_flow.get_children():
		if child is GreyboxIngredientBlock:
			var block := child as GreyboxIngredientBlock
			block.set_selected(dish.has(block.content_id))


## The one place a view switch happens: visibility for both views, which of
## the per-view primary buttons is offered, and where keyboard focus lands on
## arrival -- plan section 5's "call `grab_focus()` on the first pantry item"
## when preparation begins, generalised to every view's own entry control.
func _set_view(view: View) -> void:
	_view = view
	_customer_view.visible = view != View.PREPARATION
	_preparation_view.visible = view == View.PREPARATION
	_confirm_button.visible = view == View.REQUEST
	_served_dish_panel.visible = view == View.RESULT
	_next_customer_button.visible = view == View.RESULT
	_feedback_panel.visible = view == View.RESULT or view == View.ENDED
	_sync_pantry_interactivity()
	_focus_view_entry_point()


func _sync_pantry_interactivity() -> void:
	var active: bool = _view == View.PREPARATION
	for child: Node in _pantry_flow.get_children():
		if child is Button:
			(child as Button).disabled = not active
	_serve_button.disabled = not active


func _focus_view_entry_point() -> void:
	if _view == View.REQUEST:
		_confirm_button.grab_focus()
	elif _view == View.RESULT:
		_next_customer_button.grab_focus()
	elif _view == View.PREPARATION and _pantry_flow.get_child_count() > 0:
		var first_block: Node = _pantry_flow.get_child(0)
		if first_block is Button:
			(first_block as Button).grab_focus()
