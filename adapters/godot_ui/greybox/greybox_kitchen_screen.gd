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
## "large spatial zones" the plan's step 1 names. A `Container` is used
## **inside** each zone, for that zone's own children. That split -- anchors
## for zones, containers inside them -- is the plan's own guidance in section
## 1, followed literally here.
##
## ## The preparation view is a place, not a stack (#44)
##
## The first version of this screen laid the worktop out as three stacked
## bands: inspection text, a wrapping `HFlowContainer` pantry, then a tray row
## with Serve on the end. The owner's read was exact -- "the workspace screen
## doesn't represent an actual workspace, it's just an abstraction" -- and the
## diagnosis is that a worktop has locations while that had rows. Painting art
## onto it would only have painted the rows.
##
## It is now a **centre and a perimeter**, the one structure all four
## preparation references in the frame notes share: the dish surface owns the
## middle of the view and is its largest single region, with four stations
## placed around it, one per `IngredientDefinition.group`. DEC-029's groups
## stop being list headings and become **where a thing lives**; their unequal
## sizes (2/2/3/5) are what make them read as places rather than as cells.
##
## Both views paint a ground. Without one the panels floated on the window's
## clear colour, and in the customer view the city strip read as a black bar
## rather than as a darker street seen past a warmer interior.
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

## Every block's smallest permitted dimension, in pixels.
##
## Silhouettes vary in shape but never below this floor. Pekoe's don't-borrow
## note names the failure mode of a shelf of varied objects exactly -- "tiny
## unequal click targets" -- so the rule here is **varied to look at, uniform
## to hit**, with the name always visible on top of both.
##
## Deliberately not clamped in `_ingredient_block`: a clamp would make
## `test_every_ingredient_block_meets_the_interaction_floor` incapable of
## failing, which is worse than no test at all.
const MIN_INTERACTION_TARGET: float = 44.0

## Presentation-only block shapes per `IngredientDefinition.group` (plan
## section 3: "keep this size mapping in the presentation prototype; do not add
## it to `IngredientDefinition`"). Wide and low for a tray of staples, tall for
## a carton, squat for a jar, flat for something laid out on a board.
const _GROUP_SILHOUETTE: Dictionary[StringName, Vector2] = {
	&"staple": Vector2(180.0, 56.0),
	&"broth_and_fat": Vector2(112.0, 96.0),
	&"heat_and_ferment": Vector2(124.0, 64.0),
	&"fresh_and_cured": Vector2(152.0, 48.0),
}
const _DEFAULT_SILHOUETTE: Vector2 = Vector2(140.0, 56.0)

## Where each station sits, as anchor fractions of the preparation view:
## `position` is the top-left corner, `end` the bottom-right.
##
## A centre with a perimeter around it, which is the one structure all four
## preparation references in the frame notes share -- Good Pizza's bins
## surrounding the dish, Galaxy Burger's bins around a central assembly
## surface, Potion Craft's tools around one primary object with inventory at
## the edge, Pekoe's shelves with category markers. The stations are
## deliberately unequal (2/2/3/5 ingredients) because that is what makes them
## read as places rather than as cells.
const _STATION_ZONE: Dictionary[StringName, Rect2] = {
	&"staple": Rect2(0.27, 0.05, 0.33, 0.19),
	&"broth_and_fat": Rect2(0.63, 0.05, 0.34, 0.19),
	&"heat_and_ferment": Rect2(0.82, 0.28, 0.15, 0.46),
	&"fresh_and_cured": Rect2(0.27, 0.78, 0.70, 0.17),
}

## The jars stack in their narrow right-hand column; every other station runs
## along its edge.
const _STATION_IS_COLUMN: Dictionary[StringName, bool] = {
	&"staple": false,
	&"broth_and_fat": false,
	&"heat_and_ferment": true,
	&"fresh_and_cured": false,
}

## The dish surface. Sized to be the largest single region of the view, because
## it is the record of every choice the player has made -- the thing that was
## previously three small labels reading "(empty)".
const _PASS_ZONE: Rect2 = Rect2(0.27, 0.28, 0.52, 0.46)
const _TICKET_ZONE: Rect2 = Rect2(0.03, 0.05, 0.21, 0.37)
const _INSPECTION_ZONE: Rect2 = Rect2(0.03, 0.46, 0.21, 0.49)

## Serve is the only irreversible action on this view and it sits attached to
## the dish it sends. The reported defect was that it read as one more control
## in a row.
const _SERVE_MIN_HEIGHT: float = 64.0

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

## The item container of each station, keyed by `IngredientDefinition.group`.
var _station_slots: Dictionary[StringName, BoxContainer] = {}

## Every block, flattened in `IngredientDefinition.GROUPS` order. The stations
## own the blocks' layout; this owns their order, which is what the focus chain
## and the selection refresh both walk.
var _ingredient_blocks: Array[GreyboxIngredientBlock] = []

var _dish_place_labels: Array[Label] = []
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
	# The truck interior, painted first so everything else sits on it. Reported
	# defect: without a ground the city strip below read as a black bar across
	# the top 16% of the window instead of as a darker street seen past a warmer
	# inside -- which is the contrast the brief asks this view to test.
	var interior := ColorRect.new()
	interior.color = theme.get_color("surface", "Tokens")
	interior.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(interior)

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


## A centre and a perimeter. The previous version of this function produced
## three stacked bands -- inspection text, a wrapping pantry, a tray row with
## Serve on the end -- which the owner correctly read as "not an actual
## workspace, just an abstraction": a worktop has locations, and that had rows.
## Rewritten from scratch rather than adjusted, per #44.
func _build_preparation_view(parent: Control) -> void:
	# A worktop needs a ground. Without one the panels floated on the window's
	# own clear colour, which is most of what made this read as controls on
	# nothing rather than objects on a surface.
	var worktop_ground := ColorRect.new()
	worktop_ground.color = theme.get_color("surface", "Tokens")
	worktop_ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(worktop_ground)

	_build_ticket(parent)
	_build_inspection(parent)
	_build_pass(parent)
	_build_stations(parent)


## Anchors a zone from one of the `Rect2` constants above, so the geometry
## lives in the constant rather than being spelled out at each call site.
func _zone_rect(control: Control, rect: Rect2) -> void:
	_zone(control, rect.position.x, rect.position.y, rect.end.x, rect.end.y)


## Clipped to the rail on the left, where a docket goes -- not a full-width
## banner across the top. It has to stay legible for the whole of preparation,
## which is the entire claim of the two-view design.
func _build_ticket(parent: Control) -> void:
	var ticket := PanelContainer.new()
	_zone_rect(ticket, _TICKET_ZONE)
	parent.add_child(ticket)
	var ticket_column := VBoxContainer.new()
	ticket.add_child(ticket_column)
	_ticket_header_label = Label.new()
	_ticket_header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ticket_header_label.theme_type_variation = &"GroupHeading"
	ticket_column.add_child(_ticket_header_label)
	_ticket_request_label = RichTextLabel.new()
	_ticket_request_label.fit_content = true
	_ticket_request_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ticket_request_label.theme_type_variation = &"RequestText"
	ticket_column.add_child(_ticket_request_label)
	_ticket_avoid_label = Label.new()
	_ticket_avoid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_column.add_child(_ticket_avoid_label)


## Reference text, so it sits with the ticket rather than over the worktop.
func _build_inspection(parent: Control) -> void:
	var inspection := PanelContainer.new()
	_zone_rect(inspection, _INSPECTION_ZONE)
	parent.add_child(inspection)
	_inspection_label = RichTextLabel.new()
	_inspection_label.fit_content = true
	_inspection_label.text = "Focus or hover a pantry item to inspect it."
	inspection.add_child(_inspection_label)


## The centre: the dish being built, and the action that sends it. Three
## places on a surface rather than three labelled boxes in a row -- an empty
## place now looks empty instead of announcing "(empty)", which was one of the
## defects reported from the screenshots.
func _build_pass(parent: Control) -> void:
	var pass_panel := PanelContainer.new()
	_zone_rect(pass_panel, _PASS_ZONE)
	parent.add_child(pass_panel)
	var column := VBoxContainer.new()
	pass_panel.add_child(column)

	var heading := Label.new()
	heading.text = "The pass"
	heading.theme_type_variation = &"GroupHeading"
	column.add_child(heading)

	var places := HBoxContainer.new()
	places.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(places)
	_dish_place_labels = []
	for _place: int in range(Flavor.MAX_DISH_SIZE):
		var place := PanelContainer.new()
		place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		place.size_flags_vertical = Control.SIZE_EXPAND_FILL
		places.add_child(place)
		var place_label := Label.new()
		place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		place_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		place.add_child(place_label)
		_dish_place_labels.append(place_label)

	_serve_button = Button.new()
	_serve_button.text = "Serve"
	_serve_button.theme_type_variation = &"PrimaryButton"
	_serve_button.custom_minimum_size = Vector2(0.0, _SERVE_MIN_HEIGHT)
	_serve_button.pressed.connect(_on_serve_pressed)
	column.add_child(_serve_button)


## Four stations around the pass, one per `IngredientDefinition.group`, walked
## in that constant's declared display order. The heading is Pekoe's "category
## marker provides orientation" -- it works here and did not inside the old
## `HFlowContainer`, which wrapped a heading as just another block.
func _build_stations(parent: Control) -> void:
	_station_slots = {}
	for group: StringName in IngredientDefinition.GROUPS:
		if not _STATION_ZONE.has(group):
			continue
		var station := PanelContainer.new()
		_zone_rect(station, _STATION_ZONE[group])
		parent.add_child(station)
		var column := VBoxContainer.new()
		station.add_child(column)

		var heading := Label.new()
		heading.text = String(TranslationServer.translate(StringName("pantry.group.%s" % group)))
		heading.theme_type_variation = &"GroupHeading"
		column.add_child(heading)

		var is_column: bool = _STATION_IS_COLUMN[group]
		var items: BoxContainer = null
		if is_column:
			items = VBoxContainer.new()
		else:
			items = HBoxContainer.new()
		items.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(items)
		_station_slots[group] = items


## Fills the stations in `IngredientDefinition.GROUPS` order, which is a
## display contract rather than just a set, and records the flat order the
## focus chain walks.
func _populate_pantry() -> void:
	var by_group: Dictionary[StringName, Array] = {}
	for ingredient: IngredientDefinition in _session.content().all_ingredients():
		if not by_group.has(ingredient.group):
			by_group[ingredient.group] = []
		by_group[ingredient.group].append(ingredient)

	_ingredient_blocks = []
	for group: StringName in IngredientDefinition.GROUPS:
		if not _station_slots.has(group) or not by_group.has(group):
			continue
		for ingredient: IngredientDefinition in by_group[group]:
			var block: GreyboxIngredientBlock = _ingredient_block(ingredient)
			_station_slots[group].add_child(block)
			_ingredient_blocks.append(block)
	_link_focus_chain()


## Explicit focus neighbours, per the plan's section 5: "automatic focus
## guessing becomes unreliable in spatial layouts." That was a hypothesis when
## the pantry was one flow; with four stations arranged around a centre it is
## simply true, because Godot's geometric guess hops between stations in an
## order matching nothing the player can see.
##
## The chain closes into a loop through Serve, so Tab never dead-ends and a
## keyboard-only player can always reach the commit.
func _link_focus_chain() -> void:
	if _ingredient_blocks.is_empty():
		return
	var last: int = _ingredient_blocks.size() - 1
	for index: int in range(_ingredient_blocks.size()):
		var block: GreyboxIngredientBlock = _ingredient_blocks[index]
		if index < last:
			block.focus_next = _ingredient_blocks[index + 1].get_path()
		else:
			block.focus_next = _serve_button.get_path()
		if index > 0:
			block.focus_previous = _ingredient_blocks[index - 1].get_path()
		else:
			block.focus_previous = _serve_button.get_path()
	_serve_button.focus_next = _ingredient_blocks[0].get_path()
	_serve_button.focus_previous = _ingredient_blocks[last].get_path()


func _ingredient_block(ingredient: IngredientDefinition) -> GreyboxIngredientBlock:
	var block := GreyboxIngredientBlock.new()
	var silhouette: Vector2 = _DEFAULT_SILHOUETTE
	if _GROUP_SILHOUETTE.has(ingredient.group):
		silhouette = _GROUP_SILHOUETTE[ingredient.group]
	block.setup(ingredient, silhouette)
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
	_refresh_dish()


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
	# already calls `_refresh_dish()` after every accepted result, which reads
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
	# Header is who, body is what. The header read `ticket_key` while that field
	# was a placeholder holding the display name; now that it carries the
	# authored condensation, reading it here would print the order twice.
	_ticket_header_label.text = EncounterText.translate(customer.name_key)
	# `ticket_key`, never `request_key`. The ticket is the whole claim of the
	# two-view design -- it is what carries the request across the cut to the
	# preparation view -- and a ticket holding the full request is the Good
	# Pizza failure the frame notes named: a speech bubble as the only durable
	# record of a nuanced request. `old_local` alone is 319 characters against a
	# 68-character ticket, and truncating it lands mid-atmosphere, after two
	# sentences about watching trucks come and go.
	_ticket_request_label.text = EncounterText.translate(customer.ticket_key)
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


## An unused place on the pass renders empty rather than saying "(empty)".
## Three labels reading "(empty) (empty) (empty)" was one of the reported
## defects: a place that announces its own emptiness is a form field, and the
## point of the surface is that it is a record of choices.
func _refresh_dish() -> void:
	var dish: Array[StringName] = _session.state().current_dish
	for index: int in range(_dish_place_labels.size()):
		if index < dish.size():
			_dish_place_labels[index].text = EncounterText.ingredient_name(
				dish[index], _session.content()
			)
		else:
			_dish_place_labels[index].text = ""
	for block: GreyboxIngredientBlock in _ingredient_blocks:
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
	for block: GreyboxIngredientBlock in _ingredient_blocks:
		block.disabled = not active
	_serve_button.disabled = not active


func _focus_view_entry_point() -> void:
	if _view == View.REQUEST:
		_confirm_button.grab_focus()
	elif _view == View.RESULT:
		_next_customer_button.grab_focus()
	elif _view == View.PREPARATION and not _ingredient_blocks.is_empty():
		_ingredient_blocks[0].grab_focus()
