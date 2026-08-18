## `KitchenScreen` -- the game's screen, locked in DEC-043.
##
## Disposable design evidence, not a cathedral: this covers the load-bearing
## claims -- the screen drives `KitchenSession` and renders only what its
## events carry, the ticket survives the view switch, a rejection is shown,
## and a constraint violation is visible both before and after serving --
## rather than exhaustively mirroring `tests/unit/test_kitchen_screen.gd`.
##
## Assertions read panel text, the way a player does, the same reason
## `test_kitchen_screen.gd` gives for doing the same.
extends GutTest

const SCENE_PATH: String = "res://adapters/godot_ui/kitchen_screen.tscn"

## `block_boss` scored Satisfied 83 on this dish -- the same fixture
## `test_kitchen_screen.gd` uses, so both screens can be checked against the
## same known-good arithmetic.
const BLOCK_BOSS_DISH: Array[StringName] = [
	&"ingredient.chili_crisp",
	&"ingredient.thick_wheat_noodles",
	&"ingredient.mushrooms",
]

var _screen: KitchenScreen = null


func before_each() -> void:
	_screen = KitchenScreen.new()
	add_child_autofree(_screen)


func _find_block(ingredient_id: StringName) -> IngredientBlock:
	for block: IngredientBlock in _screen._ingredient_blocks:
		if block.content_id == ingredient_id:
			return block
	return null


## Confirms the request, selects `dish`, and serves it -- the request view's
## "Okay" and the preparation view's "Serve", the same two confirmations the
## frame-notes brief calls out by name.
func _serve(dish: Array[StringName]) -> void:
	_screen._confirm_button.pressed.emit()
	for ingredient_id: StringName in dish:
		_find_block(ingredient_id).pressed.emit()
	_screen._serve_button.pressed.emit()


func _advance() -> void:
	_screen._next_customer_button.pressed.emit()


## Loads and instantiates the `.tscn`, not just the script -- proof the scene
## file this hands off is actually runnable, not only the class behind it.
func test_the_scene_launches_headless() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	assert_not_null(packed, "the scene resource loads")
	var instance: Node = packed.instantiate()
	add_child_autofree(instance)
	assert_true(instance is KitchenScreen)
	assert_eq((instance as KitchenScreen)._ingredient_blocks.size(), 12)


## The request view's five-second recall (frame-notes brief): who is this,
## what do they want, what must they avoid -- present before any input, and
## the "avoid" line present even though `block_boss` is one of the four of
## eight customers who has a constraint (the other four, with none, are
## covered by the empty-list branch in the next test).
func test_request_view_shows_who_what_and_what_to_avoid_before_any_input() -> void:
	assert_true(_screen._customer_view.visible)
	assert_false(_screen._preparation_view.visible)
	var shown: String = _screen._dialogue_request_label.text
	assert_string_contains(shown, String(TranslationServer.translate(&"customer.block_boss.name")))
	assert_string_contains(
		shown, String(TranslationServer.translate(&"customer.block_boss.request"))
	)
	assert_string_contains(
		_screen._dialogue_avoid_label.text,
		String(TranslationServer.translate(&"customer.block_boss.constraint.smoked")),
	)


## Service Cook.md names this exact hazard: a panel that collapses when the
## constraint list is empty reflows the screen between customers. Advances to
## `late_shift_medic`, who has none, and checks the line is still there.
func test_the_avoid_line_does_not_disappear_for_a_customer_with_no_constraints() -> void:
	_serve([&"ingredient.mushrooms"])
	_advance()
	assert_string_contains(
		_screen._dialogue_request_label.text,
		String(TranslationServer.translate(&"customer.late_shift_medic.name")),
	)
	assert_string_contains(_screen._dialogue_avoid_label.text, "Avoid:")


## The preparation view's five-second recall (frame-notes brief): what does
## the ticket say they want, what must they avoid, where are the ingredients,
## how do I commit -- all after confirming, none of it re-read from the
## request view, which is no longer visible.
func test_confirming_the_request_pins_a_ticket_that_carries_it_into_preparation() -> void:
	_screen._confirm_button.pressed.emit()

	assert_false(_screen._customer_view.visible)
	assert_true(_screen._preparation_view.visible)
	# Header is who, body is what.
	assert_eq(
		_screen._ticket_header_label.text,
		String(TranslationServer.translate(&"customer.block_boss.name"))
	)
	assert_eq(
		_screen._ticket_request_label.text,
		String(TranslationServer.translate(&"customer.block_boss.ticket"))
	)
	# The negative half, and the one that would have caught the original bug:
	# this asserted the ticket *contained* the full request, which pinned
	# rendering `request_key` here as correct. A ticket that is the request is
	# not a ticket.
	assert_false(
		_screen._ticket_request_label.text.contains(
			String(TranslationServer.translate(&"customer.block_boss.request"))
		),
		"the ticket condenses the request rather than reprinting it"
	)
	assert_string_contains(
		_screen._ticket_avoid_label.text,
		String(TranslationServer.translate(&"customer.block_boss.constraint.smoked")),
	)
	assert_eq(_screen._ingredient_blocks.size(), 12, "every ingredient is offered")
	assert_false(_screen._serve_button.disabled, "commit is reachable")


func test_pressing_an_ingredient_marks_it_and_fills_the_tray() -> void:
	_screen._confirm_button.pressed.emit()
	var block: IngredientBlock = _find_block(&"ingredient.mushrooms")

	block.pressed.emit()

	assert_string_contains(block.text, "[x]")
	assert_string_contains(
		_screen._dish_place_labels[0].text,
		String(TranslationServer.translate(&"ingredient.mushrooms.name"))
	)

	block.pressed.emit()
	assert_false(block.text.contains("[x]"), "pressing it again reverses the selection")
	# An unused place renders empty rather than announcing "(empty)" -- a place
	# that labels its own emptiness is a form field, not a surface (#44).
	assert_eq(_screen._dish_place_labels[0].text, "")


## Both mouse and keyboard land on `_on_ingredient_inspect` (plan section 3).
## `grab_focus()` is the keyboard path -- no mouse event is emitted here at
## all -- so this is the test that inspection reaches a keyboard-only player,
## not just the mouse-hover path.
func test_focusing_an_ingredient_by_keyboard_shows_its_full_description() -> void:
	_screen._confirm_button.pressed.emit()
	var block: IngredientBlock = _find_block(&"ingredient.coconut_milk")

	block.grab_focus()

	assert_string_contains(
		_screen._inspection_label.text,
		String(TranslationServer.translate(&"ingredient.coconut_milk.description")),
	)


func test_a_rejected_action_is_shown_rather_than_swallowed() -> void:
	_screen._confirm_button.pressed.emit()

	_screen._serve_button.pressed.emit()

	assert_ne(_screen._notice_label.text, "", "the refusal is visible")
	assert_string_contains(_screen._notice_label.text.to_lower(), "ingredient")


func test_serving_returns_to_the_customer_view_with_dish_and_feedback() -> void:
	_serve(BLOCK_BOSS_DISH)

	assert_true(_screen._customer_view.visible)
	assert_false(_screen._preparation_view.visible)
	assert_string_contains(_screen._feedback_label.text, "Satisfied")
	assert_string_contains(_screen._feedback_label.text, "83")
	assert_string_contains(
		_screen._served_dish_label.text,
		String(TranslationServer.translate(&"ingredient.chili_crisp.name")),
	)


## The 319-character `old_local` request and its constraint, rendered in full
## rather than a placeholder or a truncated stand-in.
func test_the_longest_shipped_request_and_constraint_render_in_full() -> void:
	for _i: int in range(4):
		_serve([&"ingredient.mushrooms"])
		_advance()

	assert_string_contains(
		_screen._dialogue_request_label.text,
		String(TranslationServer.translate(&"customer.old_local.request")),
	)
	assert_string_contains(
		_screen._dialogue_avoid_label.text,
		String(TranslationServer.translate(&"customer.old_local.constraint.held")),
	)

	# The worst case for the ticket, and the reason #42 exists: `old_local`'s
	# request is the longest shipped at 319 characters. The bound is stated as a
	# multiple of the request rather than an absolute character count, so it
	# still means something if the request is ever rewritten.
	_screen._confirm_button.pressed.emit()
	var request: String = String(TranslationServer.translate(&"customer.old_local.request"))
	var ticket: String = _screen._ticket_request_label.text
	assert_lt(
		ticket.length() * 3,
		request.length(),
		(
			"the ticket must be a condensation, not a copy (ticket %d chars, request %d)"
			% [ticket.length(), request.length()]
		)
	)


## The constraint is visible on the ticket before serving, and the violation
## is visible in the feedback after -- `night_courier` forbids the `fermented`
## tag `ingredient.kimchi` carries.
func test_a_constraint_violation_is_visible_before_and_after_serving() -> void:
	for _i: int in range(2):
		_serve([&"ingredient.mushrooms"])
		_advance()

	_screen._confirm_button.pressed.emit()
	assert_string_contains(
		_screen._ticket_avoid_label.text,
		String(TranslationServer.translate(&"customer.night_courier.constraint.fermented")),
	)

	_find_block(&"ingredient.kimchi").pressed.emit()
	_screen._serve_button.pressed.emit()

	assert_string_contains(
		_screen._feedback_label.text,
		String(TranslationServer.translate(&"customer.night_courier.constraint.fermented")),
	)


func test_the_night_ends_with_a_summary_and_nothing_left_to_press() -> void:
	for _i: int in range(8):
		_serve([&"ingredient.mushrooms"])
		_advance()

	assert_string_contains(_screen._feedback_label.text, "That's the night.")
	assert_string_contains(
		_screen._feedback_label.text,
		String(TranslationServer.translate(&"customer.solar_tech.name"))
	)
	assert_false(_screen._next_customer_button.visible)
	assert_false(_screen._confirm_button.visible)
	for block: IngredientBlock in _screen._ingredient_blocks:
		assert_true(block.disabled)


## Cheap test from the plan's section 7: the reusable block scales to 6, 12,
## and 24 items without touching real pantry content. Synthetic
## `IngredientDefinition`s, laid out in a scratch flow container -- this does
## not exercise `_screen` at all, only the reusable block/container pair.
func test_the_ingredient_block_scales_to_6_12_and_24_items() -> void:
	for count: int in [6, 12, 24]:
		var flow := HFlowContainer.new()
		add_child_autofree(flow)
		for index: int in range(count):
			var mock := IngredientDefinition.new()
			mock.content_id = StringName("ingredient.mock_%d" % index)
			mock.name_key = StringName("ingredient.mock_%d.name" % index)
			mock.group = &"staple"
			var block := IngredientBlock.new()
			block.setup(mock, Vector2(160.0, 56.0))
			flow.add_child(block)
		assert_eq(flow.get_child_count(), count, "%d mock blocks were laid out" % count)


## GDD section 5.1. The screen decides nothing about scoring or constraints;
## it renders what the domain's events carry. Scans the source rather than
## trusting the class doc that says so.
func test_the_screen_contains_no_scoring_or_constraint_logic() -> void:
	var forbidden: Array[String] = ["Evaluator", "FlavourScorer", "ConstraintChecker"]
	var dir := DirAccess.open("res://adapters/godot_ui")
	assert_not_null(dir, "the UI adapter directory exists")

	var checked: int = 0
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		checked += 1
		var source: String = FileAccess.get_file_as_string("res://adapters/godot_ui/%s" % file_name)
		for symbol: String in forbidden:
			assert_false(
				source.contains("%s." % symbol),
				"%s must not call %s -- scoring belongs to the domain" % [file_name, symbol]
			)
	assert_gt(checked, 0, "there is source to check")


## No `add_theme_*_override` call anywhere in the screen -- the same rule
## `test_kitchen_screen.gd` enforces for `KitchenScreen`, repeated here for
## the same reason as the check above.
func test_no_theme_property_is_set_inline_in_the_screen() -> void:
	var forbidden: Array[String] = [
		"add_theme_color_override",
		"add_theme_font_override",
		"add_theme_font_size_override",
		"add_theme_icon_override",
		"add_theme_stylebox_override",
		"add_theme_constant_override",
	]
	var dir := DirAccess.open("res://adapters/godot_ui")
	assert_not_null(dir, "the UI adapter directory exists")

	var checked: int = 0
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		checked += 1
		var source: String = FileAccess.get_file_as_string("res://adapters/godot_ui/%s" % file_name)
		for symbol: String in forbidden:
			assert_false(source.contains(symbol), "%s must not call %s" % [file_name, symbol])
	assert_gt(checked, 0, "there is source to check")


## Sizes the real viewport against the recorded window-size hypothesis
## (`HYPOTHESIS_MIN_SIZE`) and checks the screen still offers the whole
## pantry. `_screen`'s anchors span the full rect, so its size is derived
## from the viewport rather than settable directly -- the viewport is
## restored afterwards so this does not leak into later tests. This cannot
## check overlap or legibility at that size -- see the handoff for what a
## headless run cannot observe.
func test_the_pantry_still_offers_every_ingredient_at_the_hypothesis_minimum_size() -> void:
	var root_window: Window = _screen.get_viewport() as Window
	assert_not_null(root_window, "the test screen sits under the root window")
	var original_size: Vector2i = root_window.size

	root_window.size = Vector2i(KitchenScreen.HYPOTHESIS_MIN_SIZE)
	await wait_process_frames(1)

	assert_eq(_screen._ingredient_blocks.size(), 12)

	root_window.size = original_size


## DEC-044: the ticket is a reminder, not a replacement, so the full request
## stays reachable during preparation. The tray has to survive the trip --
## a player who looks something up and loses two chosen ingredients will stop
## looking things up, which defeats the affordance.
func test_reading_the_full_request_during_preparation_keeps_the_tray() -> void:
	_screen._confirm_button.pressed.emit()
	_find_block(&"ingredient.mushrooms").pressed.emit()
	_find_block(&"ingredient.chili_crisp").pressed.emit()

	_screen._read_request_button.pressed.emit()

	assert_true(_screen._customer_view.visible, "the request is readable again")
	assert_false(_screen._preparation_view.visible)
	assert_string_contains(
		_screen._dialogue_request_label.text,
		String(TranslationServer.translate(&"customer.block_boss.request")),
		"and it is the full request, not the ticket"
	)

	_screen._confirm_button.pressed.emit()

	assert_true(_screen._preparation_view.visible)
	assert_eq(_screen._session.state().current_dish.size(), 2, "both choices survived")
	assert_string_contains(
		_screen._dish_place_labels[0].text,
		String(TranslationServer.translate(&"ingredient.mushrooms.name"))
	)
