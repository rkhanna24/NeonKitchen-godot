## The customer `ticket_key` field, per issue #42.
##
## Split out of `test_content_validator.gd` only because that file hit the
## 20-public-method lint cap; this is a validation rule like its neighbours.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"


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


func _shipped_customers() -> Array[CustomerDefinition]:
	var repository := TresContentRepository.new()
	var problems: PackedStringArray = repository.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(problems.size(), 0, "shipped content loads: %s" % _joined(problems))
	return repository.all_customers()


## Rule 2 of `Content Voice.md` exempts customer requests from the ban on
## naming a flavour dimension, and the ticket inherits that exemption because
## it is a condensation of the request -- so `Savory, hearty` is legal here and
## is not what this checks for. What is banned is the *evaluator's* vocabulary:
## a target, a weight, or the machinery's own words. `Savory 5, weight 2` hands
## over the answer key, and a digit is the tell.
func test_no_shipped_ticket_leaks_evaluator_vocabulary() -> void:
	TranslationServer.set_locale("en")
	var offenders: PackedStringArray = []
	for customer: CustomerDefinition in _shipped_customers():
		var text: String = String(TranslationServer.translate(customer.ticket_key))
		for banned: String in ["dimension", "weight", "target", "score", "penalty"]:
			if text.to_lower().contains(banned):
				offenders.append("%s: contains '%s'" % [customer.content_id, banned])
		for digit: String in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
			if text.contains(digit):
				offenders.append("%s: contains the digit '%s'" % [customer.content_id, digit])
	assert_eq(offenders.size(), 0, _joined(offenders))


## The bar from #42: a ticket is a condensation, so it must be materially
## shorter than the request it condenses. Stated as a ratio rather than a
## character count so it survives a request being rewritten.
func test_every_shipped_ticket_is_much_shorter_than_its_request() -> void:
	TranslationServer.set_locale("en")
	var offenders: PackedStringArray = []
	for customer: CustomerDefinition in _shipped_customers():
		var ticket: String = String(TranslationServer.translate(customer.ticket_key))
		var request: String = String(TranslationServer.translate(customer.request_key))
		# Also catches the failure that shipped for weeks: an unresolved key
		# returns itself, and `customer.old_local.ticket` is shorter than the
		# request, so a length check alone would have called the bug a pass.
		if ticket == String(customer.ticket_key):
			offenders.append("%s: ticket_key does not resolve" % customer.content_id)
			continue
		if ticket.length() * 2 >= request.length():
			offenders.append(
				(
					"%s: ticket %d chars against a %d-char request"
					% [customer.content_id, ticket.length(), request.length()]
				)
			)
	assert_eq(offenders.size(), 0, _joined(offenders))
