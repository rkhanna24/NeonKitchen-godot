## `TerminalPresenter.present_pantry` grouping, per ADR 0004 section 6a (DEC-029).
##
## Ordering assertions are on `content_id`, which is stable and never
## translated. Heading assertions resolve the key through `TranslationServer`
## the same way the presenter does: the project's `en` translation *is* loaded
## under test, so a literal "Staples" here would pass today and break the moment
## the display name is reworded, testing the wording rather than the grouping.
extends GutTest


func _ingredient(id: String, group: StringName) -> IngredientDefinition:
	var i := IngredientDefinition.new()
	i.content_id = StringName(id)
	i.name_key = StringName(id + ".name")
	i.description_key = StringName(id + ".description")
	i.group = group
	return i


## The display name for a group, resolved exactly as the presenter resolves it.
func _heading(group: StringName) -> String:
	return String(TranslationServer.translate(StringName("pantry.group.%s" % group)))


## Index of the first line mentioning `needle`, or -1.
func _line_with(lines: Array[String], needle: String) -> int:
	for i: int in range(lines.size()):
		if lines[i].contains(needle):
			return i
	return -1


func test_pantry_lists_groups_in_contract_order_not_repository_order() -> void:
	# Deliberately supplied in the reverse of `GROUPS` order, so passing by
	# accident is not possible: if the presenter simply echoed its input, every
	# assertion below would invert.
	var ingredients: Array[IngredientDefinition] = [
		_ingredient("ingredient.lettuce", &"fresh_and_cured"),
		_ingredient("ingredient.chili_crisp", &"heat_and_ferment"),
		_ingredient("ingredient.broth", &"broth_and_fat"),
		_ingredient("ingredient.noodles", &"staple"),
	]

	var lines: Array[String] = TerminalPresenter.present_pantry(
		ingredients, [] as Array[StringName]
	)

	var staple: int = _line_with(lines, "ingredient.noodles")
	var broth: int = _line_with(lines, "ingredient.broth")
	var heat: int = _line_with(lines, "ingredient.chili_crisp")
	var fresh: int = _line_with(lines, "ingredient.lettuce")

	assert_gt(staple, 0, "every ingredient is listed")
	assert_lt(staple, broth, "staple before broth_and_fat")
	assert_lt(broth, heat, "broth_and_fat before heat_and_ferment")
	assert_lt(heat, fresh, "heat_and_ferment before fresh_and_cured")


func test_pantry_never_drops_an_ingredient_with_an_unknown_group() -> void:
	# The validator rejects an unknown group at load, so this is unreachable in
	# the game. It is asserted anyway because the failure mode is silence: a
	# presenter iterating only over `GROUPS` would omit the ingredient with no
	# error, and a player would simply never see something they own.
	var ingredients: Array[IngredientDefinition] = [
		_ingredient("ingredient.noodles", &"staple"),
		_ingredient("ingredient.mystery", &"not_a_real_group"),
	]

	var lines: Array[String] = TerminalPresenter.present_pantry(
		ingredients, [] as Array[StringName]
	)

	assert_gt(_line_with(lines, "ingredient.mystery"), 0, "an unknown group is still listed")
	assert_lt(
		_line_with(lines, "ingredient.noodles"),
		_line_with(lines, "ingredient.mystery"),
		"known groups come first, leftovers after"
	)


func test_pantry_prints_a_heading_for_each_group_present() -> void:
	var ingredients: Array[IngredientDefinition] = [
		_ingredient("ingredient.noodles", &"staple"),
		_ingredient("ingredient.broth", &"broth_and_fat"),
	]

	var lines: Array[String] = TerminalPresenter.present_pantry(
		ingredients, [] as Array[StringName]
	)

	assert_gt(_line_with(lines, _heading(&"staple")), 0, "staple heading")
	assert_gt(_line_with(lines, _heading(&"broth_and_fat")), 0, "broth_and_fat heading")
	# Only groups that have something in them: an empty heading would be a
	# category the player cannot act on.
	assert_eq(_line_with(lines, _heading(&"heat_and_ferment")), -1, "no empty headings")


func test_group_headings_are_translated_rather_than_printing_the_key() -> void:
	# Guards the assumption the test above depends on. If the localisation key
	# were missing, `TranslationServer` returns the key unchanged, `_heading`
	# would return that key, and every heading assertion would still pass while
	# the player read "pantry.group.staple" on screen.
	var staple: String = _heading(&"staple")
	assert_ne(staple, "pantry.group.staple", "group heading must have a translation")
	assert_false(staple.begins_with("pantry.group."), "heading is a display name, not a key")
