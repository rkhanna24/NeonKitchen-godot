## The pantry `group` field, per ADR 0004 section 6a (DEC-029).
##
## Split out of `test_content_validator.gd` only because that file hit the
## 20-public-method lint cap; these are validation rules like its neighbours.
extends GutTest


func _ingredient(id: String) -> IngredientDefinition:
	var i := IngredientDefinition.new()
	i.content_id = StringName(id)
	i.name_key = StringName(id + ".name")
	i.description_key = StringName(id + ".description")
	i.comfort = 2
	i.group = &"staple"
	return i


func _customer(id: String) -> CustomerDefinition:
	var c := CustomerDefinition.new()
	c.content_id = StringName(id)
	c.name_key = StringName(id + ".name")
	c.request_key = StringName(id + ".request")
	c.reaction_key = StringName(id + ".reaction")
	c.comfort_target = 3
	c.comfort_weight = 3
	return c


func _problems(
	ingredients: Array[IngredientDefinition], customers: Array[CustomerDefinition]
) -> PackedStringArray:
	return ContentValidator.validate(ingredients, customers)


func _joined(problems: PackedStringArray) -> String:
	return "\n".join(problems)


func test_a_missing_group_is_reported() -> void:
	# Godot omits an exported field equal to its class default when writing a
	# `.tres`, so "never authored" and "authored as empty" are identical bytes.
	# The validator has to reject the empty value or a whole ingredient reaches
	# the presenter with no place to be listed.
	var ungrouped := _ingredient("ingredient.noodles")
	ungrouped.group = &""
	var ingredients: Array[IngredientDefinition] = [ungrouped]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "missing group")


func test_an_unknown_group_is_reported() -> void:
	# A typo'd group is the dangerous case: it reads as authored, and the
	# presenter's fallback would print it under its raw value rather than
	# dropping it, so nothing visibly breaks. Only the validator catches it.
	var typo := _ingredient("ingredient.noodles")
	typo.group = &"stapel"
	var ingredients: Array[IngredientDefinition] = [typo]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	var joined: String = _joined(_problems(ingredients, customers))
	assert_string_contains(joined, "stapel")
	assert_string_contains(joined, "is not one of")


func test_every_declared_group_is_actually_used_by_shipped_content() -> void:
	# A group nobody uses is a heading that never prints — the listing silently
	# loses a category and no other check notices, since both the validator and
	# the presenter are satisfied by a group that simply matches nothing.
	var repository := TresContentRepository.new()
	var problems: PackedStringArray = repository.load_from(
		"res://content/base/ingredients", "res://content/base/customers"
	)
	assert_eq(problems.size(), 0, "shipped content must validate")

	var used: Dictionary[StringName, bool] = {}
	for ingredient: IngredientDefinition in repository.all_ingredients():
		used[ingredient.group] = true
	for group: StringName in IngredientDefinition.GROUPS:
		assert_true(used.has(group), "group '%s' is declared but unused" % group)
