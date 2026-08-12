## Content validation rules, per ADR 0004 sections 1, 2 and 5.
##
## These assert that malformed content fails at load with an actionable
## message, rather than reaching the domain and producing a plausible wrong
## score during play.
extends GutTest


func _ingredient(id: String) -> IngredientDefinition:
	var i := IngredientDefinition.new()
	i.content_id = StringName(id)
	i.name_key = StringName(id + ".name")
	i.description_key = StringName(id + ".description")
	i.comfort = 2
	i.tags = [&"noodle"]
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


func _constraint(kind: CustomerConstraint.Kind, subject: StringName) -> CustomerConstraint:
	var k := CustomerConstraint.new()
	k.kind = kind
	k.subject = subject
	k.explanation_key = StringName("explain." + String(subject))
	return k


func _problems(
	ingredients: Array[IngredientDefinition], customers: Array[CustomerDefinition]
) -> PackedStringArray:
	return ContentValidator.validate(ingredients, customers)


func _joined(problems: PackedStringArray) -> String:
	return "\n".join(problems)


func test_valid_content_produces_no_problems() -> void:
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_eq(_problems(ingredients, customers).size(), 0, "clean content should validate")


func test_duplicate_ingredient_id_is_reported() -> void:
	var ingredients: Array[IngredientDefinition] = [
		_ingredient("ingredient.noodles"), _ingredient("ingredient.noodles")
	]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "duplicate content_id")


func test_content_id_must_be_namespaced() -> void:
	var bad := _ingredient("noodles")
	var ingredients: Array[IngredientDefinition] = [bad]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "namespaced lowercase")


func test_flavour_above_the_ingredient_ceiling_is_reported() -> void:
	var loud := _ingredient("ingredient.noodles")
	loud.comfort = Flavor.MAX_INGREDIENT_VALUE + 1
	var ingredients: Array[IngredientDefinition] = [loud]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "outside 0..3")


func test_negative_weight_is_rejected() -> void:
	# A negative weight inverts the scoring arithmetic and can drive the
	# divisor to zero or below. ADR 0004 section 2.
	var customer := _customer("customer.mina")
	customer.spicy_weight = -5
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "weight is -5")


func test_all_zero_weights_are_rejected() -> void:
	var customer := _customer("customer.mina")
	customer.comfort_weight = 0
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "nothing to score")


func test_missing_localisation_key_is_reported() -> void:
	var nameless := _ingredient("ingredient.noodles")
	nameless.name_key = &""
	var ingredients: Array[IngredientDefinition] = [nameless]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "missing name_key")


func test_constraint_referencing_an_unknown_ingredient_is_reported() -> void:
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.absent")
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "unknown ingredient")


func test_constraint_referencing_an_unused_tag_is_reported() -> void:
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"nonexistent")
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "no ingredient carries")


func test_requiring_and_forbidding_the_same_thing_is_reported_once() -> void:
	# The scan previously walked ordered pairs and reported every
	# contradiction twice.
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.REQUIRE_TAG, &"noodle"),
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"noodle"),
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]

	var problems: PackedStringArray = _problems(ingredients, customers)
	var matches: int = 0
	for problem: String in problems:
		if problem.contains("both requires and forbids"):
			matches += 1
	assert_eq(matches, 1, "a contradiction should be reported exactly once")
	assert_false(
		_joined(problems).contains("authored twice"),
		"a genuine contradiction is not the redundancy message"
	)


func test_an_ingredient_id_and_a_tag_sharing_text_are_not_a_contradiction() -> void:
	# Different namespaces. Requiring an ingredient while forbidding a tag of
	# the same text is legitimate, and was previously a false positive.
	var shared := _ingredient("ingredient.noodles")
	shared.tags = [&"shared_name"]
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles"),
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"shared_name"),
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [shared]
	var customers: Array[CustomerDefinition] = [customer]

	var joined: String = _joined(_problems(ingredients, customers))
	assert_false(
		joined.contains("both requires and forbids"),
		"different namespaces must not be treated as a contradiction"
	)


func test_two_identical_forbid_tag_constraints_are_rejected() -> void:
	# Two constraints stating the same boundary are not a richer boundary,
	# they are the same boundary authored twice, and a violation report can't
	# tell them apart. ADR 0004 section 5's amendment (DEC-021).
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"noodle"),
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"noodle"),
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]

	var joined: String = _joined(_problems(ingredients, customers))
	assert_string_contains(joined, "authored twice")
	assert_false(
		joined.contains("both requires and forbids"), "a redundant duplicate is not a contradiction"
	)


func test_more_than_two_constraints_is_reported() -> void:
	var customer := _customer("customer.mina")
	var rules: Array[CustomerConstraint] = [
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"noodle"),
		_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles"),
		_constraint(CustomerConstraint.Kind.FORBID_TAG, &"noodle"),
	]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "at most 2 permitted")


func test_missing_reaction_key_is_reported() -> void:
	var customer := _customer("customer.mina")
	customer.reaction_key = &""
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "missing reaction_key")


func test_constraint_without_an_explanation_key_is_reported() -> void:
	# This key is what tells the player why the dish was refused.
	var customer := _customer("customer.mina")
	var rule := CustomerConstraint.new()
	rule.kind = CustomerConstraint.Kind.FORBID_TAG
	rule.subject = &"noodle"
	var rules: Array[CustomerConstraint] = [rule]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "no explanation_key")


func test_out_of_range_constraint_kind_is_reported() -> void:
	# .tres is editable text and Godot does not clamp an exported enum on
	# load, so this silently behaved as a different rule than authored.
	var customer := _customer("customer.mina")
	var rule := CustomerConstraint.new()
	rule.kind = 9 as CustomerConstraint.Kind
	rule.subject = &"noodle"
	rule.explanation_key = &"explain.noodle"
	var rules: Array[CustomerConstraint] = [rule]
	customer.constraints = rules
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	assert_string_contains(_joined(_problems(ingredients, customers)), "is not a valid kind")


func test_negative_weight_does_not_also_claim_every_weight_is_zero() -> void:
	# Clamping a negative weight to 0 previously produced a second, false
	# message sending the author after a field they never set.
	var customer := _customer("customer.mina")
	customer.comfort_weight = 0
	customer.spicy_weight = -3
	var ingredients: Array[IngredientDefinition] = [_ingredient("ingredient.noodles")]
	var customers: Array[CustomerDefinition] = [customer]
	var joined: String = _joined(_problems(ingredients, customers))
	assert_string_contains(joined, "spicy weight is -3")
	assert_false(joined.contains("every weight is zero"), "the zero message is false here")


func test_constraint_to_string_survives_an_invalid_kind() -> void:
	# Printing the object is how the problem gets diagnosed; it must not be
	# what fails.
	var rule := CustomerConstraint.new()
	rule.kind = 9 as CustomerConstraint.Kind
	rule.subject = &"whatever"
	assert_string_contains(str(rule), "INVALID(9)")


func test_a_content_id_with_a_trailing_newline_is_rejected() -> void:
	# PCRE `$` also matches before a trailing newline, so anchoring alone let
	# this through. Such an id is not equal to the clean one, so every lookup
	# against it would miss.
	var sneaky := _ingredient("ingredient.noodles")
	sneaky.content_id = &"ingredient.noodles\n"
	var ingredients: Array[IngredientDefinition] = [sneaky]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(_joined(_problems(ingredients, customers)), "namespaced lowercase")


func test_a_future_schema_version_is_rejected() -> void:
	# Content authored at a later version may carry fields this build ignores;
	# interpreting it with today's semantics is worse than refusing it.
	var future := _ingredient("ingredient.noodles")
	future.schema_version = ContentValidator.MAX_SCHEMA_VERSION + 1
	var ingredients: Array[IngredientDefinition] = [future]
	var customers: Array[CustomerDefinition] = [_customer("customer.mina")]
	assert_string_contains(
		_joined(_problems(ingredients, customers)), "schema_version 2 is outside"
	)
