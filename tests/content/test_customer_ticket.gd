## The customer `ticket_key` field, per issue #42.
##
## Split out of `test_content_validator.gd` only because that file hit the
## 20-public-method lint cap; this is a validation rule like its neighbours.
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
	c.ticket_key = StringName(id + ".ticket")
	c.comfort_target = 3
	c.comfort_weight = 3
	return c


func _problems(
	ingredients: Array[IngredientDefinition], customers: Array[CustomerDefinition]
) -> PackedStringArray:
	return ContentValidator.validate(ingredients, customers)


func _joined(problems: PackedStringArray) -> String:
	return "\n".join(problems)


func test_missing_ticket_key_is_reported() -> void:
	# Godot omits an exported field equal to its class default when writing a
	# `.tres`, so "never authored" and "authored as empty" are identical
	# bytes. The validator has to reject the empty value rather than a
	# presenter defaulting it, which would hide a missing authored ticket
	# behind a plausible-looking screen.
	var customer := _customer("customer.mina")
	customer.ticket_key = &""
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "missing ticket_key")


func test_a_ticket_key_alongside_other_localisation_keys_produces_no_problem() -> void:
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_eq(_problems(ingredients, customers).size(), 0, "a fully authored ticket_key is valid")
