## A disposable greybox of the continuous customer/worktop framing
## (docs/design/references/godot-greybox-ideas.md,
## docs/design/references/frame-notes-and-greybox-brief.md).
##
## This is design evidence, not the screen `kitchen_screen.gd` is measured
## against. `kitchen_screen.gd` is untouched and its own tests still pass;
## this file is a second, parallel adapter meant to be judged and then thrown
## away or rewritten.
##
## Same two rules as `kitchen_screen.gd`, for the same reasons documented
## there:
##
## - it renders only from the `DomainEvent`s and `CommandResult`s
##   `KitchenSession` hands back, and never recomputes a number the domain
##   already produced (nothing here imports `Evaluator`, `FlavourScorer` or
##   `ConstraintChecker` -- `tests/unit/test_greybox_kitchen_screen.gd` checks
##   the source, the same way `test_kitchen_screen.gd` checks
##   `kitchen_screen.gd`, because that existing test only reads the top level
##   of `res://adapters/godot_ui` and does not see this subdirectory);
## - every colour lives in the theme resource, read at runtime by token name
##   rather than typed as a literal here (Visual Language.md), and no
##   `add_theme_*_override` call appears in this file.
##
## The request-to-ticket moment is a presentation-only substate inside
## `BUILDING_DISH` (`_Substate`), not a new domain phase -- ADR 0004 section
## 7a is untouched. It changes which region is visually emphasised and where
## keyboard focus starts; it never gates which command the pantry, tray or
## Serve button may send, because `CommandHandler` already owns that.
class_name GreyboxKitchenScreen
extends Control

## Pre-serve emphasis: the request is still being read, or the ticket is
## pinned and the worktop has the player's attention. Presentation only --
## see the class comment. Not meaningful outside `BUILDING_DISH`.
enum Substate { REQUEST, COMPOSE }

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"
const THEME_PATH: String = "res://assets/themes/solarpunk_tempered.tres"

var _session: KitchenSession = null
var _substate: Substate = Substate.REQUEST

var _city_backdrop: ColorRect = null
var _service_window: VBoxContainer = null
var _city_strip: ColorRect = null
var _customer_swatch: ColorRect = null
var _customer_name_label: Label = null
var _request_label: RichTextLabel = null
var _constraint_label: Label = null
var _begin_prep_button: Button = null
var _ticket_panel: PanelContainer = null
var _ticket_label: RichTextLabel = null
var _feedback_panel: PanelContainer = null
var _feedback_label: RichTextLabel = null

var _worktop_panel: PanelContainer = null
var _inspection_label: RichTextLabel = null
var _pantry_flow: HFlowContainer = null
var _tray_slots: Array[Button] = []
var _tray_ingredient_ids: Array[StringName] = [&"", &"", &""]
var _serve_button: Button = null
var _notice_label: Label = null

var _pantry_blocks_by_id: Dictionary[StringName, IngredientBlock] = {}


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


func _fail_loudly(problems: PackedStringArray) -> void:
	var label := Label.new()
	label.text = "Content failed to load:\n\n%s" % "\n".join(problems)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)


func _token_color(token_name: String) -> Color:
	return theme.get_color(token_name, "Tokens")


## Proportions: an untested hypothesis, not a settled ratio (open per the
## dispatch packet). One HBoxContainer, service window at stretch ratio 1,
## worktop at stretch ratio 2 -- the worktop is where the session is actually
## played, the service window is the persistent record beside it. Nobody has
## looked at this split; it may well be wrong.
func _build_layout() -> void:
	theme = load(THEME_PATH) as Theme
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_city_backdrop = ColorRect.new()
	_city_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_city_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_city_backdrop)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_build_service_window(root)
	_build_worktop(root)

	# Read after both halves exist so `Tokens` is guaranteed loaded.
	_city_backdrop.color = _token_color("background")


func _build_service_window(root: HBoxContainer) -> void:
	_service_window = VBoxContainer.new()
	_service_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_service_window.size_flags_stretch_ratio = 1.0
	root.add_child(_service_window)

	# A thin slice of the city outside the truck, per the frame brief's item 1
	# and the "cheap city hypothesis" in godot-greybox-ideas.md: a visible
	# exterior strip and a cold/warm contrast, nothing isometric or explorable.
	_city_strip = ColorRect.new()
	_city_strip.custom_minimum_size.y = 64.0
	_city_strip.color = _token_color("disabled_surface")
	_service_window.add_child(_city_strip)

	var customer_row := HBoxContainer.new()
	_service_window.add_child(customer_row)

	# Customer art placeholder: a labelled rectangle, per
	# godot-greybox-ideas.md section 2 ("Customer art can be a rectangle
	# labelled CUSTOMER").
	_customer_swatch = ColorRect.new()
	_customer_swatch.custom_minimum_size = Vector2(96, 96)
	customer_row.add_child(_customer_swatch)
	var swatch_label := Label.new()
	swatch_label.text = "CUSTOMER"
	customer_row.add_child(swatch_label)

	_customer_name_label = Label.new()
	_service_window.add_child(_customer_name_label)

	_request_label = RichTextLabel.new()
	_request_label.fit_content = true
	_request_label.theme_type_variation = &"RequestText"
	_service_window.add_child(_request_label)

	_constraint_label = Label.new()
	_constraint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_service_window.add_child(_constraint_label)

	# The transition hypothesis in frame-notes-and-greybox-brief.md: "the
	# final dialogue click/tap or confirm input pins the ticket and shifts
	# emphasis to the worktop." There is no dialogue tree here (one static
	# request), so this button stands in for that confirm input.
	_begin_prep_button = Button.new()
	_begin_prep_button.text = "Begin prep"
	_begin_prep_button.pressed.connect(_on_begin_prep_pressed)
	_service_window.add_child(_begin_prep_button)

	_ticket_panel = PanelContainer.new()
	_service_window.add_child(_ticket_panel)
	_ticket_label = RichTextLabel.new()
	_ticket_label.fit_content = true
	_ticket_panel.add_child(_ticket_label)

	_feedback_panel = PanelContainer.new()
	_service_window.add_child(_feedback_panel)
	_feedback_label = RichTextLabel.new()
	_feedback_label.fit_content = true
	_feedback_panel.add_child(_feedback_label)


func _build_worktop(root: HBoxContainer) -> void:
	_worktop_panel = PanelContainer.new()
	_worktop_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_worktop_panel.size_flags_stretch_ratio = 2.0
	root.add_child(_worktop_panel)

	var layout := VBoxContainer.new()
	_worktop_panel.add_child(layout)

	_inspection_label = RichTextLabel.new()
	_inspection_label.fit_content = true
	_inspection_label.custom_minimum_size.y = 96.0
	layout.add_child(_inspection_label)

	var pantry_scroll := ScrollContainer.new()
	pantry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pantry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(pantry_scroll)

	_pantry_flow = HFlowContainer.new()
	_pantry_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pantry_scroll.add_child(_pantry_flow)

	var composition_row := HBoxContainer.new()
	layout.add_child(composition_row)

	_tray_slots = []
	for slot_index: int in range(3):
		var slot := Button.new()
		slot.disabled = true
		slot.pressed.connect(_on_tray_slot_pressed.bind(slot_index))
		composition_row.add_child(slot)
		_tray_slots.append(slot)

	_serve_button = Button.new()
	_serve_button.theme_type_variation = &"PrimaryButton"
	_serve_button.pressed.connect(_on_primary_pressed)
	composition_row.add_child(_serve_button)

	_notice_label = Label.new()
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_notice_label)


## Grouping (`IngredientDefinition.GROUPS`) is dropped here on purpose: the
## reference scene tree in godot-greybox-ideas.md is one flat
## `PantryFlow (HFlowContainer)`, and this greybox is testing that shape, not
## `kitchen_screen.gd`'s grouped listing. Both are legitimate; they are not
## the same experiment.
func _populate_pantry() -> void:
	_pantry_blocks_by_id = {}
	for ingredient: IngredientDefinition in _session.content().all_ingredients():
		var block := _ingredient_block(ingredient)
		_pantry_flow.add_child(block)
		_pantry_blocks_by_id[ingredient.content_id] = block


func _ingredient_block(ingredient: IngredientDefinition) -> IngredientBlock:
	var block := IngredientBlock.new()
	block.setup(
		ingredient.content_id,
		String(TranslationServer.translate(ingredient.name_key)),
		String(TranslationServer.translate(ingredient.description_key)),
		_size_class_for(ingredient.content_id)
	)
	block.pressed.connect(_on_ingredient_pressed.bind(ingredient.content_id))
	block.inspected.connect(_on_ingredient_inspected)
	return block


## An unreviewed display guess (open per the dispatch packet), not a rule:
## chosen by content id, never derived from a flavour value -- #35 forbids
## putting flavour on screen in any form, and a size that tracked intensity
## would be exactly that.
func _size_class_for(ingredient_id: StringName) -> IngredientBlock.SizeClass:
	var small_ids: Array[StringName] = [
		&"ingredient.chili_crisp", &"ingredient.citrus_chili_paste", &"ingredient.kimchi"
	]
	var wide_ids: Array[StringName] = [
		&"ingredient.smoked_fish",
		&"ingredient.thick_wheat_noodles",
		&"ingredient.soy_broth",
		&"ingredient.coconut_milk",
	]
	if small_ids.has(ingredient_id):
		return IngredientBlock.SizeClass.SMALL
	if wide_ids.has(ingredient_id):
		return IngredientBlock.SizeClass.WIDE
	return IngredientBlock.SizeClass.STANDARD


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


func _on_tray_slot_pressed(slot_index: int) -> void:
	var ingredient_id: StringName = _tray_ingredient_ids[slot_index]
	if ingredient_id == &"":
		return
	_apply(_session.remove(ingredient_id))


## `_id` is unused: it identifies the source block for a future revision that
## might highlight it, and `IngredientBlock` should not need to change shape
## to add that later.
func _on_ingredient_inspected(_id: StringName, display_name: String, description: String) -> void:
	_inspection_label.text = "%s\n\n%s" % [display_name, description]


func _on_begin_prep_pressed() -> void:
	_substate = Substate.COMPOSE
	_sync_controls()
	if not _pantry_blocks_by_id.is_empty():
		var first_block: IngredientBlock = _pantry_blocks_by_id.values()[0]
		first_block.grab_focus()


func _on_primary_pressed() -> void:
	if _session.state().phase == SessionState.Phase.SHOWING_RESULT:
		_apply(_session.present())
	else:
		_apply(_session.submit())


func _apply(result: CommandResult) -> void:
	if not result.is_accepted:
		_notice_label.text = _rejection_text(result)
		_sync_controls()
		return
	_notice_label.text = ""
	for event: DomainEvent in result.events:
		_render(event)
	_refresh_tray()
	_sync_controls()


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


## New customer, quiet worktop: the request substate resets, and the previous
## encounter's feedback is cleared rather than left attached to the wrong
## customer (the exact hazard `kitchen_screen.gd`'s
## `test_the_previous_result_does_not_follow_the_next_customer` exists for).
func _render_customer(customer_id: StringName) -> void:
	_substate = Substate.REQUEST
	_feedback_label.text = ""
	var customer: CustomerDefinition = _session.content().find_customer(customer_id)
	if customer == null:
		return
	_customer_name_label.text = String(TranslationServer.translate(customer.name_key))
	_request_label.text = String(TranslationServer.translate(customer.request_key))
	_ticket_label.text = _ticket_text(customer)
	var lines: Array[String] = []
	for constraint: CustomerConstraint in customer.constraints:
		lines.append(String(TranslationServer.translate(constraint.explanation_key)))
	_constraint_label.text = "\n".join(lines)


## Renders `customer.<id>.ticket` when that localisation key resolves; falls
## back to the full request text otherwise (#42, the authored short forms,
## is not shipped yet). `TranslationServer.translate` returns the key itself
## unchanged when no translation exists, so an unresolved key is detected by
## comparing the result against the key rather than by checking a table this
## file has no business owning.
func _ticket_text(customer: CustomerDefinition) -> String:
	var ticket_key := StringName("%s.ticket" % customer.content_id)
	var resolved: String = String(TranslationServer.translate(ticket_key))
	if resolved != String(ticket_key):
		return resolved
	return String(TranslationServer.translate(customer.request_key))


## Reads the evaluation it was handed; nothing here is recomputed.
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


func _render_summary(results: Array[EncounterResult]) -> void:
	var lines: Array[String] = ["That's the night."]
	var position: int = 1
	for result: EncounterResult in results:
		lines.append("%d. %s" % [position, EncounterText.summary_line(result, _session.content())])
		position += 1
	_feedback_label.text = "\n".join(lines)
	_customer_name_label.text = ""
	_request_label.text = ""
	_constraint_label.text = ""
	_ticket_label.text = ""


func _refresh_tray() -> void:
	var dish: Array[StringName] = _session.state().current_dish
	var building: bool = _session.state().phase == SessionState.Phase.BUILDING_DISH
	for slot_index: int in range(_tray_slots.size()):
		var slot: Button = _tray_slots[slot_index]
		if slot_index < dish.size():
			var ingredient_id: StringName = dish[slot_index]
			_tray_ingredient_ids[slot_index] = ingredient_id
			slot.text = EncounterText.ingredient_name(ingredient_id, _session.content())
			slot.disabled = not building
		else:
			_tray_ingredient_ids[slot_index] = &""
			slot.text = "(empty)"
			slot.disabled = true
	for ingredient_id: StringName in _pantry_blocks_by_id:
		var block: IngredientBlock = _pantry_blocks_by_id[ingredient_id]
		block.set_selected(dish.has(ingredient_id))


## What the player can do, and which region is emphasised, both follow the
## phase -- matching `kitchen_screen.gd`'s `_sync_controls`, which disables
## rather than leaving a control live for `CommandHandler` to reject after
## the click.
func _sync_controls() -> void:
	var phase: SessionState.Phase = _session.state().phase
	var building: bool = phase == SessionState.Phase.BUILDING_DISH
	var showing: bool = phase == SessionState.Phase.SHOWING_RESULT

	for ingredient_id: StringName in _pantry_blocks_by_id:
		var block: IngredientBlock = _pantry_blocks_by_id[ingredient_id]
		block.disabled = not building
	for slot: Button in _tray_slots:
		slot.disabled = not building or slot.text == "(empty)"

	_serve_button.visible = building or showing
	_serve_button.text = "Serve" if building else "Next customer"
	_begin_prep_button.visible = building and _substate == Substate.REQUEST

	_apply_emphasis(phase)


## Modulate alpha, not a themed colour or a stylebox override: an emphasis
## level, not a palette choice, so it stays out of Visual Language.md's "no
## hex outside the theme" rule. The dimming amounts (0.55, 0.4) are this
## file's own implementation guess and unverified -- see the handoff for what
## that means headless.
func _apply_emphasis(phase: SessionState.Phase) -> void:
	var full := Color(1, 1, 1, 1)
	var quiet := Color(1, 1, 1, 0.55)
	match phase:
		SessionState.Phase.BUILDING_DISH:
			if _substate == Substate.REQUEST:
				_service_window.modulate = full
				_worktop_panel.modulate = quiet
			else:
				_service_window.modulate = Color(1, 1, 1, 0.85)
				_worktop_panel.modulate = full
		SessionState.Phase.SHOWING_RESULT:
			_service_window.modulate = full
			_worktop_panel.modulate = quiet
		SessionState.Phase.ENDED:
			_service_window.modulate = full
			_worktop_panel.modulate = Color(1, 1, 1, 0.4)
		_:
			_service_window.modulate = full
			_worktop_panel.modulate = full
