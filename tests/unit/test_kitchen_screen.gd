## `KitchenScreen`, the Godot UI (#32, extended to the full service by #34).
##
## Instantiated into a real scene tree so `_ready` runs and the layout is really
## built. Assertions are on what the panels say, because that is the only thing
## a player gets; asserting on internal state would pass for a screen that
## computed everything correctly and displayed none of it.
##
## The roster runs in repository order, so the first customer is `block_boss`.
extends GutTest

## `block_boss` scored Satisfied 83 on this dish in playtest run 01, and the
## figure was re-derived through the evaluator when that run was recorded.
const BLOCK_BOSS_DISH: Array[StringName] = [
	&"ingredient.chili_crisp",
	&"ingredient.thick_wheat_noodles",
	&"ingredient.mushrooms",
]

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

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


func _serve(dish: Array[StringName]) -> void:
	for id: StringName in dish:
		_button_for(id).pressed.emit()
	_screen._primary_button.pressed.emit()


## Serve every customer on the roster, then press once more to end the night.
func _play_whole_service() -> int:
	var served: int = 0
	while _screen._session.state().phase != SessionState.Phase.ENDED:
		if _screen._session.state().phase == SessionState.Phase.BUILDING_DISH:
			_button_for(&"ingredient.mushrooms").pressed.emit()
			served += 1
		_screen._primary_button.pressed.emit()
	return served


func test_the_customer_and_their_request_are_on_screen_before_anything_is_chosen() -> void:
	var shown: String = _screen._request_label.text
	assert_string_contains(shown, String(TranslationServer.translate(&"customer.block_boss.name")))
	assert_string_contains(
		shown, String(TranslationServer.translate(&"customer.block_boss.request"))
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
	_screen._primary_button.pressed.emit()

	assert_ne(_screen._notice_label.text, "", "the refusal is visible")
	assert_string_contains(_screen._notice_label.text.to_lower(), "ingredient")


func test_serving_shows_the_band_and_score_from_the_event() -> void:
	_serve(BLOCK_BOSS_DISH)

	var feedback: String = _screen._feedback_label.text
	assert_string_contains(feedback, "Satisfied")
	assert_string_contains(feedback, "83")
	assert_eq(_screen._notice_label.text, "", "an accepted action clears the notice")


func test_the_pantry_goes_inert_while_a_result_is_showing() -> void:
	# The player has served; there is nothing to build until the next customer
	# arrives. Leaving the buttons live and letting the domain reject the press
	# is the terminal's behaviour, and it puts the refusal after the click
	# instead of never offering it.
	_serve(BLOCK_BOSS_DISH)

	assert_eq(_screen._session.state().phase, SessionState.Phase.SHOWING_RESULT)
	for child: Node in _screen._pantry_box.get_children():
		if child is Button:
			assert_true((child as Button).disabled, "ingredients are inert while showing a result")


func test_the_primary_button_becomes_the_way_to_the_next_customer() -> void:
	assert_eq(_screen._primary_button.text, "Serve")

	_serve(BLOCK_BOSS_DISH)
	assert_eq(_screen._primary_button.text, "Next customer")

	_screen._primary_button.pressed.emit()
	assert_eq(_screen._session.state().phase, SessionState.Phase.BUILDING_DISH)
	assert_eq(_screen._primary_button.text, "Serve")


func test_every_customer_can_be_served_in_one_run() -> void:
	var served: int = _play_whole_service()
	assert_eq(served, 8, "the whole roster is served without restarting")


func test_the_night_ends_with_a_summary_of_every_encounter() -> void:
	_play_whole_service()

	var summary: String = _screen._feedback_label.text
	for id: StringName in [
		&"customer.block_boss",
		&"customer.late_shift_medic",
		&"customer.night_courier",
		&"customer.office_worker",
		&"customer.old_local",
		&"customer.rig_partner",
		&"customer.scrap_trader",
		&"customer.solar_tech",
	]:
		var name_key: StringName = StringName("%s.name" % id)
		assert_string_contains(summary, String(TranslationServer.translate(name_key)))


func test_nothing_is_offered_once_the_night_is_over() -> void:
	_play_whole_service()

	assert_eq(_screen._session.state().phase, SessionState.Phase.ENDED)
	assert_false(_screen._primary_button.visible, "there is nothing left to press")
	for child: Node in _screen._pantry_box.get_children():
		if child is Button:
			assert_true((child as Button).disabled)


func test_the_ui_summary_matches_the_terminal_line_for_line() -> void:
	# The #33 parity question, scoped to the summary. Both adapters format from
	# `EncounterText` now; if either grows its own copy back, these diverge.
	_play_whole_service()
	var shown: String = _screen._feedback_label.text

	# The same eight dishes driven through a second session, formatted the way
	# the terminal formats them.
	var content := TresContentRepository.new()
	assert_eq(content.load_from(INGREDIENT_DIR, CUSTOMER_DIR).size(), 0)
	var session := KitchenSession.new(SessionState.new(), content)
	var roster: Array[StringName] = []
	for customer: CustomerDefinition in content.all_customers():
		roster.append(customer.content_id)
	session.start(roster)

	var ended: SessionEnded = null
	while ended == null:
		for event: DomainEvent in session.present().events:
			if event is SessionEnded:
				ended = event as SessionEnded
		if ended != null:
			break
		session.select(&"ingredient.mushrooms")
		session.submit()

	assert_not_null(ended, "the second session also ends")
	assert_eq(ended.results.size(), 8)
	for encounter: EncounterResult in ended.results:
		assert_string_contains(shown, TerminalPresenter._summary_line(encounter, content))


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
