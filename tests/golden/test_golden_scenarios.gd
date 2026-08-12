## Golden scenarios pinning `Evaluator.evaluate()` output for the shipped
## twelve-ingredient, eight-customer content, per ADR 0004 section 9.
##
## `tools/gap_scan.py` named `tests/golden/` (ADR 0002 section 6, issue #6's
## first bullet) the single genuine gap in the repository: the ratified layout
## lists this folder and nothing licensed its absence. This file closes it for
## the scenario slice only -- contract tests, the adversarial audit of existing
## assertions, and seed capture stay open on #6.
##
## Every expected value below was produced by running the real `Evaluator`
## against `content/base/` (not hand arithmetic), then re-derived by hand from
## ADR 0004 section 3's formula as a second, independent check. Both agree; the
## per-case comments show the second derivation so a reader can audit a value
## without re-running the engine.
##
## A golden case is a claim that behaviour will not silently drift. Each of
## these was confirmed to go red -- naming the changed field, not just
## "assertion failed" -- when the underlying content or a band edge was
## perturbed, then reverted. See the handoff for exactly what was changed and
## what the suite printed.
##
## Cases were not hand-picked to be easy. Each earns its place:
##
## - a comfortable DELIGHTED dish that also has no largest miss, because every
##   weighted dimension lands exactly on target (issue #6's "satisfying" case,
##   and the one shape `has_largest_miss` can be false in: section 6 makes that
##   possible only when every penalty is zero, which forces score 100);
## - a MIXED dish sitting exactly on the 40 lower edge (issue #6's
##   "borderline" case and a band-edge case in one);
## - a DISSATISFIED dish from an empty plate (issue #6's "failing" case, with
##   no constraint involved, so the failure is pure flavour mismatch);
## - a DISSATISFIED dish landing on 39 with **no constraint violation at
##   all** -- the natural lower edge of the band, kept beside the next case so
##   the two 39s cannot be confused with each other;
## - a constraint violation whose uncapped flavour score is 50, capped to 39,
##   with `per_dimension` still reporting the uncapped arithmetic -- the
##   specific claim in section 5 that "the flavour score is still computed and
##   reported" when a boundary is crossed;
## - the SATISFIED band's lower edge, 65, on a customer with no constraints at
##   all, so the edge is visible without a cap anywhere nearby;
## - the DELIGHTED band's lower edge, 85, one ingredient away from the 65 case
##   above, so the two edges are pinned from dishes that are obviously related
##   rather than from unrelated corners of the content.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

var repository: TresContentRepository = null


func before_each() -> void:
	repository = TresContentRepository.new()
	var problems: PackedStringArray = repository.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(problems.size(), 0, "shipped content must validate: %s" % "\n".join(problems))


func _ingredient(id: StringName) -> IngredientDefinition:
	var found: IngredientDefinition = repository.find_ingredient(id)
	assert_not_null(found, "missing ingredient %s" % id)
	return found


func _customer(id: StringName) -> CustomerDefinition:
	var found: CustomerDefinition = repository.find_customer(id)
	assert_not_null(found, "missing customer %s" % id)
	return found


func _dish(ids: Array[StringName]) -> Array[IngredientDefinition]:
	var out: Array[IngredientDefinition] = []
	for id: StringName in ids:
		out.append(_ingredient(id))
	return out


## One weighted dimension's arithmetic, compared field by field. `DimensionScore`
## has no `==`, so `assert_eq` on the object would compare identity, not value --
## it would pass for any two distinct instances only by accident of never being
## asked to fail. Verified: this helper was pointed at a deliberately wrong
## penalty and reported exactly that field.
func _assert_dimension(
	actual: Evaluation.DimensionScore,
	dimension: Flavor.Dimension,
	target: int,
	value: int,
	weight: int,
	penalty: int,
	context: String
) -> void:
	assert_eq(actual.dimension, dimension, "%s: dimension" % context)
	assert_eq(actual.target, target, "%s: target" % context)
	assert_eq(actual.actual, value, "%s: actual" % context)
	assert_eq(actual.weight, weight, "%s: weight" % context)
	assert_eq(actual.penalty, penalty, "%s: penalty" % context)


## Same reasoning as `_assert_dimension`: `ViolatedConstraint` has no `==`.
func _assert_violated(
	actual: Evaluation.ViolatedConstraint,
	kind: CustomerConstraint.Kind,
	subject: StringName,
	explanation_key: StringName,
	context: String
) -> void:
	assert_eq(actual.kind, kind, "%s: kind" % context)
	assert_eq(actual.subject, subject, "%s: subject" % context)
	assert_eq(actual.explanation_key, explanation_key, "%s: explanation_key" % context)


## Satisfying, DELIGHTED, and the only shape in which `has_largest_miss` can be
## false: every weighted penalty is exactly zero.
##
## thick_wheat_noodles (savory 1, comfort 3) + kimchi (savory 1, spicy 1,
## adventurous 3) composes to savory 2, spicy 1, comfort 3, adventurous 3.
## scrap_trader weights only spicy (1, target 1) and comfort (2, target 3).
## Both land exactly on target: penalty 0 on each, so sum(penalty) = 0 and
## score = 100 - (0 * 100) / 10 = 100.
##
## Section 6's exclusion (DEC-025) only removes a target-0/actual-0 dimension
## from the tie-break; it does not apply here, since both weighted targets are
## non-zero. This case pins the *other* route to an absent largest miss: every
## candidate scored zero, not every candidate being excluded.
func test_delighted_dish_with_no_largest_miss_because_every_penalty_is_zero() -> void:
	var customer: CustomerDefinition = _customer(&"customer.scrap_trader")
	var dish: Array[IngredientDefinition] = _dish(
		[&"ingredient.thick_wheat_noodles", &"ingredient.kimchi"]
	)

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 100)
	assert_eq(e.band, Evaluation.RatingBand.DELIGHTED, "band must be DELIGHTED")
	assert_true(e.constraint_satisfied)
	assert_eq(e.violated_constraints.size(), 0)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.COMFORT)
	assert_false(e.has_largest_miss, "every penalty is zero, so no dimension can be a miss")

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 1, 1, 1, 0, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.COMFORT, 3, 3, 2, 0, "comfort")


## Borderline, and simultaneously the MIXED band's lower edge at 40.
##
## kimchi alone (savory 1, spicy 1, adventurous 3) against scrap_trader:
## spicy lands exactly on target 1 (penalty 0, max_penalty 4); comfort misses
## target 3 by 3 at weight 2 (penalty 6, max_penalty 6). score =
## 100 - (6 * 100) / 10 = 40 -- MIXED, not DISSATISFIED, by exactly one point.
func test_mixed_band_edge_at_the_lower_boundary_of_forty() -> void:
	var customer: CustomerDefinition = _customer(&"customer.scrap_trader")
	var dish: Array[IngredientDefinition] = _dish([&"ingredient.kimchi"])

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 40)
	assert_eq(e.band, Evaluation.RatingBand.MIXED, "band must be MIXED")
	assert_true(e.constraint_satisfied)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.SPICY)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.COMFORT)

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 1, 1, 1, 0, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.COMFORT, 3, 0, 2, 6, "comfort")


## Failing, from an empty plate, with no constraint anywhere near it -- the
## purest possible flavour-only failure.
##
## night_courier weights spicy (2, target 3) and comfort (3, target 5). An
## empty dish scores actual 0 on both: spicy penalty 2*3=6 (max 6), comfort
## penalty 3*5=15 (max 15). sum(penalty) == sum(max_penalty) == 21, so
## score = 100 - (21 * 100) / 21 = 0. night_courier also carries a
## FORBID_TAG(fermented) boundary; an empty dish carries no tags at all, so it
## is trivially satisfied -- pinned here so this 0 cannot be mistaken for a cap.
func test_dissatisfied_dish_from_an_empty_plate() -> void:
	var customer: CustomerDefinition = _customer(&"customer.night_courier")
	var dish: Array[IngredientDefinition] = []

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 0)
	assert_eq(e.band, Evaluation.RatingBand.DISSATISFIED, "band must be DISSATISFIED")
	assert_true(e.constraint_satisfied, "an empty dish carries no forbidden tag")
	assert_eq(e.violated_constraints.size(), 0)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.SPICY)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.COMFORT)

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 3, 0, 2, 6, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.COMFORT, 5, 0, 3, 15, "comfort")


## The DISSATISFIED band's natural lower edge, 39, reached by flavour mismatch
## alone -- no constraint is violated, and none exists on this customer. Kept
## beside `test_constraint_violation_caps_at_thirty_nine_...` below so the two
## 39s are pinned as visibly different mechanisms producing the same number.
##
## solar_tech weights savory (2, target 3) and comfort (3, target 5). chickpeas
## contributes savory 1, comfort 2: savory penalty 2*2=4 (max 6), comfort
## penalty 3*3=9 (max 15). sum(penalty)=13, sum(max_penalty)=21,
## score = 100 - (13 * 100) / 21 = 100 - 61 = 39 (integer division truncates
## 1300/21 = 61.90... to 61).
func test_dissatisfied_band_edge_at_thirty_nine_without_any_constraint_violation() -> void:
	var customer: CustomerDefinition = _customer(&"customer.solar_tech")
	var dish: Array[IngredientDefinition] = _dish([&"ingredient.chickpeas"])

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 39)
	assert_eq(e.band, Evaluation.RatingBand.DISSATISFIED, "band must be DISSATISFIED")
	assert_true(e.constraint_satisfied, "solar_tech carries no constraints at all")
	assert_eq(e.violated_constraints.size(), 0)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.SAVORY)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.COMFORT)

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SAVORY, 3, 1, 2, 4, "savory")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.COMFORT, 5, 2, 3, 9, "comfort")


## The cap in action: ADR 0004 section 5 says a violation forces
## `score = min(score, 39)` while "the flavour score is still computed and
## reported". This dish's *uncapped* flavour score is 50 -- a clean, checkable
## number well above the cap -- so the 39 in the assertions below is visibly
## the cap doing work, not a coincidence of the underlying arithmetic.
##
## thick_wheat_noodles (savory 1, comfort 3) + soy_broth (savory 2, comfort 2,
## tag `soy`) composes to savory 3, comfort 5. scrap_trader weights spicy
## (1, target 1) and comfort (2, target 3): spicy actual 0, penalty 1*1=1
## (max 4); comfort actual 5, penalty 2*2=4 (max 6). sum(penalty)=5,
## sum(max_penalty)=10, flavour score = 100 - (5*100)/10 = 50.
## scrap_trader's only constraint is FORBID_TAG(soy); soy_broth carries it, so
## `final_score = min(50, 39) = 39`.
func test_constraint_violation_caps_at_thirty_nine_but_reports_the_flavour_score() -> void:
	var customer: CustomerDefinition = _customer(&"customer.scrap_trader")
	var dish: Array[IngredientDefinition] = _dish(
		[&"ingredient.thick_wheat_noodles", &"ingredient.soy_broth"]
	)

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 39, "the cap, not the uncapped flavour score of 50")
	assert_eq(e.band, Evaluation.RatingBand.DISSATISFIED, "band must be DISSATISFIED")
	assert_false(e.constraint_satisfied)
	assert_eq(e.violated_constraints.size(), 1)
	_assert_violated(
		e.violated_constraints[0],
		CustomerConstraint.Kind.FORBID_TAG,
		&"soy",
		&"customer.scrap_trader.constraint.soy",
		"violation"
	)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.SPICY)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.COMFORT)

	# The uncapped flavour arithmetic is exactly what section 5 says it must
	# still be: unaffected by the cap applied to `score` above.
	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 1, 0, 1, 1, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.COMFORT, 3, 5, 2, 4, "comfort")


## The SATISFIED band's lower edge, 65, on a customer (rig_partner) who carries
## no constraints at all, so the edge is visible with no cap anywhere near it.
##
## citrus_chili_paste (spicy 3, fresh 1, adventurous 2) + citrus_herbs (fresh 1,
## adventurous 2) composes to spicy 3, fresh 2, adventurous 4. rig_partner
## weights spicy (3, target 4) and fresh (2, target 4): spicy penalty 3*1=3
## (max 3*4=12); fresh penalty 2*2=4 (max 2*4=8). sum(penalty)=7,
## sum(max_penalty)=20, score = 100 - (7*100)/20 = 100 - 35 = 65.
func test_satisfied_band_edge_at_the_lower_boundary_of_sixty_five() -> void:
	var customer: CustomerDefinition = _customer(&"customer.rig_partner")
	var dish: Array[IngredientDefinition] = _dish(
		[&"ingredient.citrus_chili_paste", &"ingredient.citrus_herbs"]
	)

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 65)
	assert_eq(e.band, Evaluation.RatingBand.SATISFIED, "band must be SATISFIED")
	assert_true(e.constraint_satisfied)
	assert_eq(e.violated_constraints.size(), 0)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.SPICY)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.FRESH)

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 4, 3, 3, 3, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.FRESH, 4, 2, 2, 4, "fresh")


## The DELIGHTED band's lower edge, 85, one ingredient added to the 65 case
## above -- pickled_cucumber tops up Fresh to exactly its target and nothing
## else changes, so the two edges are pinned from dishes that are obviously
## related rather than from unrelated corners of the content.
##
## Adding pickled_cucumber (fresh 2, adventurous 1) to the dish above composes
## to spicy 3, fresh 4, adventurous 5. Spicy is unchanged (penalty 3, max 12);
## fresh now lands exactly on target 4 (penalty 0, max 2*4=8). sum(penalty)=3,
## sum(max_penalty)=20, score = 100 - (3*100)/20 = 100 - 15 = 85.
func test_delighted_band_edge_at_the_lower_boundary_of_eighty_five() -> void:
	var customer: CustomerDefinition = _customer(&"customer.rig_partner")
	var dish: Array[IngredientDefinition] = _dish(
		[
			&"ingredient.citrus_chili_paste",
			&"ingredient.citrus_herbs",
			&"ingredient.pickled_cucumber",
		]
	)

	var e: Evaluation = Evaluator.evaluate(dish, customer)

	assert_eq(e.score, 85)
	assert_eq(e.band, Evaluation.RatingBand.DELIGHTED, "band must be DELIGHTED")
	assert_true(e.constraint_satisfied)
	assert_eq(e.violated_constraints.size(), 0)
	assert_true(e.has_strongest_match)
	assert_eq(e.strongest_match, Flavor.Dimension.FRESH)
	assert_true(e.has_largest_miss)
	assert_eq(e.largest_miss, Flavor.Dimension.SPICY)

	assert_eq(e.per_dimension.size(), 2)
	_assert_dimension(e.per_dimension[0], Flavor.Dimension.SPICY, 4, 3, 3, 3, "spicy")
	_assert_dimension(e.per_dimension[1], Flavor.Dimension.FRESH, 4, 4, 2, 0, "fresh")
