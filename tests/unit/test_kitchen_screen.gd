## `KitchenScreen`, the Phase 2 vertical slice (#32).
##
## Instantiated into a real scene tree so `_ready` runs and the layout is really
## built. Assertions are on what the panels say, because that is the only thing
## a player gets; asserting on internal state would pass for a screen that
## computed everything correctly and displayed none of it.
extends GutTest

var _screen: KitchenScreen = null


func before_each() -> void:
	_screen = KitchenScreen.new()
	add_child_autofree(_screen)


## The button for one ingredient, found by its translated label the way a player
## finds it. Returns null if absent.
func _button_for(ingredient_id: StringName) -> Button:
	var ingredient: IngredientDefinition = _screen._session.content().find_ingredient(ingredient_id)
	if ingredient == null:
		return null
	var wanted: String = String(TranslationServer.translate(ingredient.name_key))
	for child: Node in _screen._pantry_box.get_children():
		if child is Button and (child as Button).text == wanted:
			return child as Button
	return null


func test_the_customer_and_their_request_are_on_screen_before_anything_is_chosen() -> void:
	var shown: String = _screen._request_label.text
	assert_string_contains(shown, String(TranslationServer.translate(&"customer.solar_tech.name")))
	assert_string_contains(
		shown, String(TranslationServer.translate(&"customer.solar_tech.request"))
	)


func test_the_whole_pantry_is_offered_grouped() -> void:
	var buttons: int = 0
	var headings: int = 0
	for child: Node in _screen._pantry_box.get_children():
		if child is Button:
			buttons += 1
		elif child is Label:
			headings += 1
	assert_eq(buttons, 12, "every ingredient is selectable")
	assert_eq(headings, IngredientDefinition.GROUPS.size(), "one heading per group")


func test_pressing_an_ingredient_puts_it_in_the_dish() -> void:
	var button: Button = _button_for(&"ingredient.mushrooms")
	assert_not_null(button, "mushrooms are offered")

	button.pressed.emit()

	assert_eq(_screen._session.state().current_dish.size(), 1)
	assert_string_contains(
		_screen._dish_label.text, String(TranslationServer.translate(&"ingredient.mushrooms.name"))
	)


func test_pressing_the_same_ingredient_again_takes_it_out() -> void:
	var button: Button = _button_for(&"ingredient.mushrooms")
	button.pressed.emit()
	button.pressed.emit()

	assert_eq(_screen._session.state().current_dish.size(), 0)
	assert_string_contains(_screen._dish_label.text, "empty")


func test_a_rejected_action_is_shown_rather_than_swallowed() -> void:
	# Serving nothing. The screen must say why, not quietly do nothing -- a UI
	# that ignores the press teaches the player that the button is broken.
	_screen._serve_button.pressed.emit()

	assert_ne(_screen._notice_label.text, "", "the refusal is visible")
	assert_string_contains(_screen._notice_label.text.to_lower(), "ingredient")


func test_serving_shows_the_band_and_score_from_the_event() -> void:
	for id: StringName in [
		&"ingredient.chickpeas", &"ingredient.coconut_milk", &"ingredient.mushrooms"
	]:
		_button_for(id).pressed.emit()

	_screen._serve_button.pressed.emit()

	var feedback: String = _screen._feedback_label.text
	assert_string_contains(feedback, "Delighted")
	assert_string_contains(feedback, "100")
	assert_eq(_screen._notice_label.text, "", "an accepted action clears the notice")


func test_the_ui_adapter_contains_no_scoring_or_constraint_logic() -> void:
	# GDD section 5.1: neither interface may contain scoring or constraint logic.
	# Asserted against the source rather than trusted, because the cheapest way
	# for a UI to break this is to recompute a number it was already handed.
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
