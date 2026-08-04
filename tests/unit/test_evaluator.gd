## `Evaluator.evaluate()` per ADR 0004 section 9: the one entry point that
## orchestrates composition, flavour scoring, and constraint checking.
extends GutTest


static func _ingredient(
	content_id: StringName,
	savory: int = 0,
	spicy: int = 0,
	fresh: int = 0,
	comfort: int = 0,
	adventurous: int = 0,
	tags: Array[StringName] = []
) -> IngredientDefinition:
	var ingredient := IngredientDefinition.new()
	ingredient.content_id = content_id
	ingredient.savory = savory
	ingredient.spicy = spicy
	ingredient.fresh = fresh
	ingredient.comfort = comfort
	ingredient.adventurous = adventurous
	ingredient.tags = tags
	return ingredient


static func _forbid_tag(subject: StringName) -> CustomerConstraint:
	var constraint := CustomerConstraint.new()
	constraint.kind = CustomerConstraint.Kind.FORBID_TAG
	constraint.subject = subject
	constraint.explanation_key = &"fixture.no_spice"
	return constraint


## Comfort 5 (weight 3), Spicy 4 (weight 2), Savory 3 (weight 1) — the GDD's
## night courier, ADR 0004 section 3's worked example.
static func _night_courier() -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.savory_target = 3
	customer.savory_weight = 1
	customer.spicy_target = 4
	customer.spicy_weight = 2
	customer.fresh_weight = 0
	customer.comfort_target = 5
	customer.comfort_weight = 3
	customer.adventurous_weight = 0
	return customer


func test_worked_example_end_to_end_through_composition() -> void:
	# Two ingredients compose to Savory4 Spicy2 Comfort5 — the worked
	# example's dish — via ordinary sums, not a hand-built profile.
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.a", 3, 0, 0, 3, 0),
		_ingredient(&"ingredient.b", 1, 2, 0, 2, 0),
	]
	var evaluation: Evaluation = Evaluator.evaluate(dish, _night_courier())
	assert_eq(evaluation.score, 81)
	assert_eq(evaluation.band, Evaluation.RatingBand.SATISFIED)
	assert_true(evaluation.constraint_satisfied)
	assert_eq(evaluation.strongest_match, Flavor.Dimension.COMFORT)
	assert_eq(evaluation.largest_miss, Flavor.Dimension.SPICY)


func test_reordering_a_dish_does_not_change_its_evaluation() -> void:
	var a: IngredientDefinition = _ingredient(&"ingredient.a", 3, 0, 0, 3, 0)
	var b: IngredientDefinition = _ingredient(&"ingredient.b", 1, 2, 0, 2, 0)
	var customer: CustomerDefinition = _night_courier()

	var forward: Evaluation = Evaluator.evaluate([a, b], customer)
	var reversed_order: Evaluation = Evaluator.evaluate([b, a], customer)

	assert_eq(forward.score, reversed_order.score)
	assert_eq(forward.band, reversed_order.band)
	assert_eq(forward.strongest_match, reversed_order.strongest_match)
	assert_eq(forward.largest_miss, reversed_order.largest_miss)


func test_constraint_violation_caps_score_at_39_but_keeps_flavour_feedback() -> void:
	var customer: CustomerDefinition = _night_courier()
	customer.constraints = [_forbid_tag(&"spice")]
	# Same dish as the worked example (flavour score 81), but now carries a
	# forbidden tag.
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.a", 3, 0, 0, 3, 0),
		_ingredient(&"ingredient.b", 1, 2, 0, 2, 0, [&"spice"] as Array[StringName]),
	]

	var evaluation: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(evaluation.score, 39, "a hard violation caps the score at 39")
	assert_eq(evaluation.band, Evaluation.RatingBand.DISSATISFIED)
	assert_false(evaluation.constraint_satisfied)
	assert_eq(evaluation.violated_constraint_ids, [&"spice"] as Array[StringName])
	# The flavour match itself is unaffected by the cap: feedback and the
	# per-dimension breakdown still reflect the same good match the worked
	# example produced, proving the flavour score was computed and reported
	# rather than replaced by the cap. See ADR 0004 section 5.
	assert_eq(evaluation.strongest_match, Flavor.Dimension.COMFORT)
	assert_eq(evaluation.per_dimension.size(), 3)
	for entry: Evaluation.DimensionScore in evaluation.per_dimension:
		if entry.dimension == Flavor.Dimension.COMFORT:
			assert_eq(entry.penalty, 0, "Comfort still matches exactly under the cap")


func test_constraint_violation_never_raises_an_already_low_score() -> void:
	# A dish that misses badly on flavour AND violates a boundary must not
	# have its score pulled up to 39 — the cap is a min, not a fixed value.
	var customer: CustomerDefinition = _night_courier()
	customer.constraints = [_forbid_tag(&"spice")]
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.a", 0, 0, 0, 0, 0, [&"spice"] as Array[StringName]),
	]

	var evaluation: Evaluation = Evaluator.evaluate(dish, customer)

	assert_lt(evaluation.score, 39)
	assert_false(evaluation.constraint_satisfied)
	assert_eq(evaluation.band, Evaluation.RatingBand.DISSATISFIED)


func test_all_four_bands_are_reachable() -> void:
	var customer: CustomerDefinition = _night_courier()

	var delighted: Evaluation = Evaluator.evaluate(
		[_ingredient(&"ingredient.a", 3, 0, 0, 3, 0), _ingredient(&"ingredient.b", 0, 4, 0, 2, 0)],
		customer
	)
	assert_eq(delighted.score, 100)
	assert_eq(delighted.band, Evaluation.RatingBand.DELIGHTED)

	var satisfied: Evaluation = Evaluator.evaluate(
		[_ingredient(&"ingredient.a", 3, 0, 0, 3, 0), _ingredient(&"ingredient.b", 1, 2, 0, 2, 0)],
		customer
	)
	assert_eq(satisfied.score, 81)
	assert_eq(satisfied.band, Evaluation.RatingBand.SATISFIED)

	var dissatisfied: Evaluation = Evaluator.evaluate([], customer)
	assert_eq(dissatisfied.score, 0)
	assert_eq(dissatisfied.band, Evaluation.RatingBand.DISSATISFIED)

	var mixed_customer := CustomerDefinition.new()
	mixed_customer.comfort_target = 5
	mixed_customer.comfort_weight = 1
	var mixed: Evaluation = Evaluator.evaluate(
		[_ingredient(&"ingredient.a", 0, 0, 0, 3, 0)], mixed_customer
	)
	assert_eq(mixed.score, 60)
	assert_eq(mixed.band, Evaluation.RatingBand.MIXED)


func test_band_boundaries_are_exact_at_the_hard_edges() -> void:
	assert_eq(Evaluation.band_for_score(39), Evaluation.RatingBand.DISSATISFIED)
	assert_eq(Evaluation.band_for_score(40), Evaluation.RatingBand.MIXED)
	assert_eq(Evaluation.band_for_score(64), Evaluation.RatingBand.MIXED)
	assert_eq(Evaluation.band_for_score(65), Evaluation.RatingBand.SATISFIED)
	assert_eq(Evaluation.band_for_score(84), Evaluation.RatingBand.SATISFIED)
	assert_eq(Evaluation.band_for_score(85), Evaluation.RatingBand.DELIGHTED)
	assert_eq(Evaluation.band_for_score(0), Evaluation.RatingBand.DISSATISFIED)
	assert_eq(Evaluation.band_for_score(100), Evaluation.RatingBand.DELIGHTED)
