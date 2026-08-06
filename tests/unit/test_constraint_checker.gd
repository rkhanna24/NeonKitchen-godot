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


## The `subject` of each violated constraint, in report order. Extracted
## rather than comparing arrays directly: `ViolatedConstraint` is a
## `RefCounted` value copy with no equality override, so array equality would
## compare by identity, not content.
static func _subjects(violated: Array[Evaluation.ViolatedConstraint]) -> Array[StringName]:
	var subjects: Array[StringName] = []
	for entry: Evaluation.ViolatedConstraint in violated:
		subjects.append(entry.subject)
	return subjects


func test_no_constraints_is_always_satisfied() -> void:
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.noodles")], _customer_with([])
	)
	assert_true(result.satisfied)
	assert_eq(result.violated_constraints.size(), 0)


func test_require_ingredient_is_violated_when_absent() -> void:
	var customer: CustomerDefinition = _customer_with(
		[_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"ingredient.noodles")]
	)
	var result: ConstraintChecker.Result = ConstraintChecker.check(
		[_ingredient(&"ingredient.chili_crisp")], customer
	)
	assert_false(result.satisfied)
	assert_eq(_subjects(result.violated_constraints), [&"ingredient.noodles"] as Array[StringName])


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
	assert_eq(
		_subjects(result.violated_constraints), [&"ingredient.chili_crisp"] as Array[StringName]
	)


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
	assert_eq(_subjects(result.violated_constraints), [&"spice"] as Array[StringName])


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
	assert_eq(result.violated_constraints.size(), 2)


## The measured case DEC-021 identifies: a REQUIRE_INGREDIENT and a
## FORBID_TAG on the same subject can both fire, and a bare subject could not
## tell them apart. `kind` distinguishes them.
func test_require_ingredient_and_forbid_tag_on_the_same_subject_are_distinguishable() -> void:
	var customer: CustomerDefinition = _customer_with(
		[
			_constraint(CustomerConstraint.Kind.REQUIRE_INGREDIENT, &"soy"),
			_constraint(CustomerConstraint.Kind.FORBID_TAG, &"soy"),
		]
	)
	# No ingredient has content_id "soy" (so REQUIRE_INGREDIENT fails), but the
	# dish carries the "soy" tag (so FORBID_TAG fails too) — both fire.
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.broth", [&"soy"] as Array[StringName])
	]
	var result: ConstraintChecker.Result = ConstraintChecker.check(dish, customer)

	assert_false(result.satisfied)
	assert_eq(result.violated_constraints.size(), 2)
	var kinds: Array[CustomerConstraint.Kind] = []
	for entry: Evaluation.ViolatedConstraint in result.violated_constraints:
		assert_eq(entry.subject, &"soy", "both violations share the subject 'soy'")
		assert_eq(
			entry.explanation_key,
			&"fixture.constraint",
			"explanation_key must be reachable without re-scanning customer.constraints"
		)
		kinds.append(entry.kind)
	assert_true(
		kinds.has(CustomerConstraint.Kind.REQUIRE_INGREDIENT), "the require must be identifiable"
	)
	assert_true(kinds.has(CustomerConstraint.Kind.FORBID_TAG), "the forbid must be identifiable")


func test_an_uninterpretable_kind_fails_closed() -> void:
	# `.tres` is editable text and Godot does not clamp an exported enum on
	# load. Before this guard, kind=99 made both is_forbidding() and
	# is_ingredient_kind() false, which reads as REQUIRE_TAG — so a
	# soy-forbidding customer ACCEPTED a soy dish. Verified.
	var broth := IngredientDefinition.new()
	broth.content_id = &"ingredient.broth"
	broth.tags = [&"soy"]
	var rule := CustomerConstraint.new()
	rule.kind = 99 as CustomerConstraint.Kind
	rule.subject = &"soy"
	assert_false(rule.is_valid_kind(), "99 is not a declared kind")

	var customer := CustomerDefinition.new()
	customer.content_id = &"customer.probe"
	customer.comfort_target = 3
	customer.comfort_weight = 2
	var rules: Array[CustomerConstraint] = [rule]
	customer.constraints = rules
	var dish: Array[IngredientDefinition] = [broth]

	var result: ConstraintChecker.Result = ConstraintChecker.check(dish, customer)
	assert_false(result.satisfied, "an uninterpretable boundary must fail closed")
