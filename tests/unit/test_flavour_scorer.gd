## `FlavourScorer` per ADR 0004 sections 3 and 6.
##
## Vectors below reproduce the five verification cases recorded on issue #9,
## which come from a validated model of the contract. The first is the GDD's
## own worked example (narrated there as Satisfied 78; 81 is correct for the
## ratified formula, per ADR 0004 section 3).
extends GutTest


## Comfort 5 (weight 3), Spicy 4 (weight 2), Savory 3 (weight 1).
static func _night_courier() -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.savory_target = 3
	customer.savory_weight = 1
	customer.spicy_target = 4
	customer.spicy_weight = 2
	customer.fresh_target = 0
	customer.fresh_weight = 0
	customer.comfort_target = 5
	customer.comfort_weight = 3
	customer.adventurous_target = 0
	customer.adventurous_weight = 0
	return customer


## Comfort 5 (weight 3), Spicy 0 (weight 5) — "definitely not spicy".
static func _spice_averse() -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.savory_weight = 0
	customer.spicy_target = 0
	customer.spicy_weight = 5
	customer.fresh_weight = 0
	customer.comfort_target = 5
	customer.comfort_weight = 3
	customer.adventurous_weight = 0
	return customer


static func _profile(
	savory: int, spicy: int, fresh: int, comfort: int, adventurous: int
) -> FlavorProfile:
	return FlavorProfile.new([savory, spicy, fresh, comfort, adventurous] as Array[int])


func test_vector_1_night_courier_worked_example() -> void:
	var result: FlavourScorer.Result = FlavourScorer.score(
		_profile(4, 2, 0, 5, 0), _night_courier()
	)
	assert_eq(result.score, 81)
	assert_true(result.has_strongest_match)
	assert_eq(result.strongest_match, Flavor.Dimension.COMFORT)
	assert_true(result.has_largest_miss)
	assert_eq(result.largest_miss, Flavor.Dimension.SPICY)


func test_vector_2_dish_equals_targets() -> void:
	var result: FlavourScorer.Result = FlavourScorer.score(
		_profile(3, 4, 0, 5, 0), _night_courier()
	)
	assert_eq(result.score, 100)
	assert_false(result.has_largest_miss, "a perfect match reports no miss")


func test_vector_3_empty_dish() -> void:
	var result: FlavourScorer.Result = FlavourScorer.score(
		_profile(0, 0, 0, 0, 0), _night_courier()
	)
	assert_eq(result.score, 0)


func test_vector_4_spice_averse_served_no_spice() -> void:
	var result: FlavourScorer.Result = FlavourScorer.score(_profile(0, 0, 0, 5, 0), _spice_averse())
	assert_eq(result.score, 100)


func test_vector_5_spice_averse_served_maximally_spicy() -> void:
	var result: FlavourScorer.Result = FlavourScorer.score(_profile(0, 5, 0, 5, 0), _spice_averse())
	assert_eq(result.score, 38)
	assert_true(result.has_largest_miss)
	assert_eq(result.largest_miss, Flavor.Dimension.SPICY)


func test_weight_zero_excludes_a_dimension_from_score_and_feedback() -> void:
	var customer := CustomerDefinition.new()
	customer.savory_weight = 0
	customer.comfort_target = 3
	customer.comfort_weight = 1

	# Savory is wildly off-target but unweighted; it must not move the score
	# or surface as strongest match. It cannot surface as largest miss either,
	# because `has_largest_miss` is false here — the raw `largest_miss` field
	# holds SAVORY as the unset filler, which is exactly why the flag must be
	# checked and not the field.
	var with_savory: FlavourScorer.Result = FlavourScorer.score(_profile(5, 0, 0, 3, 0), customer)
	var without_savory: FlavourScorer.Result = FlavourScorer.score(
		_profile(0, 0, 0, 3, 0), customer
	)

	assert_eq(with_savory.score, without_savory.score)
	assert_eq(with_savory.score, 100)
	assert_ne(with_savory.strongest_match, Flavor.Dimension.SAVORY)
	assert_false(with_savory.has_largest_miss, "a perfect weighted match has no miss")
	assert_eq(with_savory.per_dimension.size(), 1, "only the weighted dimension is reported")


func test_feedback_tie_break_prefers_higher_weight_over_dimension_order() -> void:
	# Savory (weight 1, error 2) and Spicy (weight 2, error 1) both land on
	# penalty 2 — a genuine tie. Dimension order alone would favour Savory,
	# which comes first in section 1's order; the weight tie-break must
	# override that and pick Spicy instead, since 2 > 1.
	var customer := CustomerDefinition.new()
	customer.savory_target = 3
	customer.savory_weight = 1
	customer.spicy_target = 3
	customer.spicy_weight = 2
	customer.comfort_weight = 0

	var result: FlavourScorer.Result = FlavourScorer.score(_profile(5, 4, 0, 0, 0), customer)
	# Savory: error 2, penalty 1*2=2. Spicy: error 1, penalty 2*1=2. Tied
	# penalty; Spicy has the higher weight (2 > 1) and must win both
	# selections despite coming later in dimension order.
	assert_eq(result.strongest_match, Flavor.Dimension.SPICY)
	assert_eq(result.largest_miss, Flavor.Dimension.SPICY)


func test_feedback_tie_break_falls_back_to_dimension_order() -> void:
	# Savory and Spicy tied on both penalty and weight; Savory comes first in
	# the section 1 dimension order and must win both selections.
	var customer := CustomerDefinition.new()
	customer.savory_target = 3
	customer.savory_weight = 1
	customer.spicy_target = 3
	customer.spicy_weight = 1
	customer.comfort_weight = 0

	var result: FlavourScorer.Result = FlavourScorer.score(_profile(4, 4, 0, 0, 0), customer)
	assert_eq(result.strongest_match, Flavor.Dimension.SAVORY)
	assert_eq(result.largest_miss, Flavor.Dimension.SAVORY)


func test_score_asserts_when_no_dimension_is_weighted() -> void:
	# Content validation rejects an all-zero-weight customer before it reaches
	# the domain (ADR 0004 section 2), so this is deliberately malformed input
	# a caller must never construct. The assert is a bug marker, not a content
	# error, and this pins that it fires rather than dividing by zero.
	var customer := CustomerDefinition.new()
	customer.comfort_weight = 0
	FlavourScorer.score(_profile(0, 0, 0, 0, 0), customer)
	assert_engine_error("no weighted dimension to score against")
