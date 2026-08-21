## Focused checks for issue #52's 152x48 gastronorm pan proof.
##
## These tests cover the structural claims a headless run can observe. Whether
## the result reads as steel remains a human screenshot judgement.
extends GutTest

const PAN_SCRIPT_PATH: String = "res://adapters/godot_ui/gastronorm_pan.gd"
const ALTERNATE_THEME_PATH: String = "res://tests/unit/fixtures/alternate_pan_theme.tres"

var _screen: KitchenScreen = null


func before_each() -> void:
	_screen = KitchenScreen.new()
	add_child_autofree(_screen)
	_screen._confirm_button.pressed.emit()
	await wait_process_frames(2)


func _find_block(ingredient_id: StringName) -> IngredientBlock:
	for block: IngredientBlock in _screen._ingredient_blocks:
		if block.content_id == ingredient_id:
			return block
	return null


func _find_pan(block: IngredientBlock) -> GastronormPan:
	for child: Node in block.get_children():
		if child is GastronormPan:
			return child as GastronormPan
	return null


func test_fresh_blocks_use_a_pan_without_changing_the_hit_rect() -> void:
	for ingredient: IngredientDefinition in _screen._session.content().all_ingredients():
		if ingredient.group != &"fresh_and_cured":
			continue
		var block: IngredientBlock = _find_block(ingredient.content_id)
		var pan: GastronormPan = _find_pan(block)
		assert_not_null(pan, "%s has the pan visual" % ingredient.content_id)
		assert_eq(block.theme_type_variation, GastronormPan.THEME_VARIATION)
		assert_eq(pan.size, block.size, "the pan visual and Button hit rect match")


func test_other_station_blocks_remain_plain_buttons() -> void:
	for ingredient: IngredientDefinition in _screen._session.content().all_ingredients():
		if ingredient.group == &"fresh_and_cured":
			continue
		var block: IngredientBlock = _find_block(ingredient.content_id)
		assert_null(_find_pan(block), "%s does not borrow the pan" % ingredient.content_id)
		assert_eq(block.theme_type_variation, &"")


func test_pan_layers_cannot_take_input_or_focus_from_the_button() -> void:
	var block: IngredientBlock = _find_block(&"ingredient.mushrooms")
	var pan: GastronormPan = _find_pan(block)
	assert_true(pan.show_behind_parent, "the visual draws behind the Button label")
	assert_eq(pan.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(pan.focus_mode, Control.FOCUS_NONE)
	for child: Node in pan.get_children():
		var layer := child as Control
		assert_not_null(layer, "every pan layer is a Control")
		assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(layer.focus_mode, Control.FOCUS_NONE)
	assert_false(pan.has_node("Specular"), "no floating highlight reads as a UI pill")


func test_accessible_name_stays_stable_when_selection_prefix_appears() -> void:
	var block: IngredientBlock = _find_block(&"ingredient.mushrooms")
	var ingredient_name := String(TranslationServer.translate(&"ingredient.mushrooms.name"))
	assert_eq(block.accessibility_name, ingredient_name)

	block.set_selected(true)

	assert_string_starts_with(block.text, "[x] ")
	assert_eq(block.accessibility_name, ingredient_name)


func test_pan_style_resolves_from_the_inherited_theme() -> void:
	var block: IngredientBlock = _find_block(&"ingredient.mushrooms")
	var pan: GastronormPan = _find_pan(block)
	var well := pan.get_node("Well") as Panel
	var initial := well.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(initial.bg_color, _screen.theme.get_color("vessel_well", "Tokens"))

	var alternate := load(ALTERNATE_THEME_PATH) as Theme
	_screen.theme = alternate
	await wait_process_frames(1)

	var resolved := well.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(resolved.bg_color, alternate.get_color("vessel_well", "Tokens"))
	assert_ne(resolved.bg_color, initial.bg_color)


func test_pan_script_contains_no_authored_colour() -> void:
	var source := FileAccess.get_file_as_string(PAN_SCRIPT_PATH)
	var hex_colour := RegEx.create_from_string("#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?")
	assert_false(source.contains("Color("), "pan colours belong to the Theme")
	assert_null(hex_colour.search(source), "pan script contains no hex colour")
