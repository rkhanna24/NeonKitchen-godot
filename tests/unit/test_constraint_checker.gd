## `ConstraintChecker` per ADR 0004 section 5: hard boundaries evaluated
## against ingredient identity and tags, never flavour values.
extends GutTest


static func _ingredient(
	content_id: StringName, tags: Array[StringName] = []
) -> IngredientDefinition:
	var ingredient := IngredientDefinition.new()
	ingredient.content_id = content_id
	ingredient.tags = tags
	return ingredient


static func _constraint(kind: CustomerConstraint.Kind, subject: StringName) -> CustomerConstraint:
	var constraint := CustomerConstraint.new()
	constraint.kind = kind
	constraint.subject = subject
	constraint.explanation_key = &"fixture.constraint"
	return constraint


static func _customer_with(constraints: Array[CustomerConstraint]) -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.constraints = constraints
	return customer


func test_no_constraints_is_always_satisfied() -> void:
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.noodles")], _customer_with([])
	)
	assert_true(result.satisfied)
	assert_eq(result.violated_constraint_ids.size(), 0)


func test_require_ingredient_is_violated_when_absent() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.chili_crisp")], customer
	)
	assert_false(result.satisfied)
	assert_eq(result.violated_constraint_ids, [&"ingredient.noodles"] as Array[StringName])


func test_require_ingredient_is_satisfied_when_present() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.noodles")], customer
	)
	assert_true(result.satisfied)


func test_forbid_ingredient_is_violated_when_present() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.FORBID_INGREDIENT, &"ingredient.chili_crisp")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.chili_crisp")], customer
	)
	assert_false(result.satisfied)
	assert_eq(result.violated_constraint_ids, [&"ingredient.chili_crisp"] as Array[StringName])


func test_forbid_ingredient_is_satisfied_when_absent() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.FORBID_INGREDIENT, &"ingredient.chili_crisp")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.noodles")], customer
	)
	assert_true(result.satisfied)


func test_require_tag_is_violated_when_no_ingredient_carries_it() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.REQUIRE_TAG, &"vegan")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.smoked_fish", [&"protein"] as Array[StringName])], customer
	)
	assert_false(result.satisfied)


func test_require_tag_is_satisfied_when_an_ingredient_carries_it() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.REQUIRE_TAG, &"vegan")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.citrus_herbs", [&"vegan"] as Array[StringName])], customer
	)
	assert_true(result.satisfied)


func test_forbid_tag_is_violated_when_any_ingredient_carries_it() -> void:
	# This is how dietary and allergen rules are expressed: one mechanism,
	# per ADR 0004 section 5.
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.FORBID_TAG, &"spice")]
	)
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.noodles"),
		_ingredient(&"ingredient.chili_crisp", [&"spice"] as Array[StringName]),
	]
	var result: ConstraintChecker.Result = ConstraintChecker.check(dish, customer)
	assert_false(result.satisfied)
	assert_eq(result.violated_constraint_ids, [&"spice"] as Array[StringName])


func test_forbid_tag_is_satisfied_when_no_ingredient_carries_it() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.FORBID_TAG, &"spice")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.noodles")], customer
	)
	assert_true(result.satisfied)


func test_multiple_constraints_report_every_violation() -> void:
	var customer: CustomerDefinition = _customer_with(
		[
			_constraint(CustomerConstraint.Kind.FORBID_TAG, &"spice"),
			_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles"),
		]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.chili_crisp", [&"spice"] as Array[StringName])], customer
	)
	assert_false(result.satisfied)
	assert_eq(result.violated_constraint_ids.size(), 2)
