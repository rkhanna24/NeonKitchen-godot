## Flavour scoring per ADR 0004 sections 3 and 6.
##
## Takes a composed `FlavorProfile` and a `CustomerDefinition` and returns the
## flavour half of an evaluation: a 0..100 score plus feedback selection.
## Constraint checking is a separate function (`ConstraintChecker`), per the
## section 9 correction — a change to constraint rules must not touch this
## arithmetic, and this function never inspects ingredient identity or tags.
##
## Touches no repository, clock, or randomness.
class_name FlavourScorer
extends RefCounted


## The flavour-only result of scoring one profile against one customer.
## Constraint outcome is not part of this; `Evaluator` combines it with
## `ConstraintChecker.Result` to build the final `Evaluation`.
class Result:
	extends RefCounted

	var score: int
	var has_strongest_match: bool
	var strongest_match: Flavor.Dimension
	var has_largest_miss: bool
	var largest_miss: Flavor.Dimension
	var per_dimension: Array[Evaluation.DimensionScore]

	func _init(
		p_score: int,
		p_has_strongest_match: bool,
		p_strongest_match: Flavor.Dimension,
		p_has_largest_miss: bool,
		p_largest_miss: Flavor.Dimension,
		p_per_dimension: Array[Evaluation.DimensionScore]
	) -> void:
		score = p_score
		has_strongest_match = p_has_strongest_match
		strongest_match = p_strongest_match
		has_largest_miss = p_has_largest_miss
		largest_miss = p_largest_miss
		per_dimension = p_per_dimension


## Scores `profile` against `customer`'s targets. A weight of 0 excludes a
## dimension from both the score and feedback selection entirely — section 2's
## "ignored, not wanted at zero" rule.
static func score(profile: FlavorProfile, customer: CustomerDefinition) -> Result:
	var per_dimension: Array[Evaluation.DimensionScore] = []
	var sum_penalty: int = 0
	var sum_max_penalty: int = 0
	var best_strongest: Evaluation.DimensionScore = null
	var best_largest: Evaluation.DimensionScore = null

	for dimension: Flavor.Dimension in customer.weighted_dimensions():
		var target: int = customer.target_of(dimension)
		var actual: int = profile.get_value(dimension)
		var weight: int = customer.weight_of(dimension)
		var error: int = absi(actual - target)
		var max_error: int = maxi(target, Flavor.MAX_DISH_VALUE - target)
		var penalty: int = weight * error
		var max_penalty: int = weight * max_error

		var entry := Evaluation.DimensionScore.new(dimension, target, actual, weight, penalty)
		per_dimension.append(entry)
		sum_penalty += penalty
		sum_max_penalty += max_penalty

		if best_strongest == null or _is_lower_penalty(entry, best_strongest):
			best_strongest = entry
		if best_largest == null or _is_higher_penalty(entry, best_largest):
			best_largest = entry

	# A bug marker, not a content error: ADR 0004 section 2 requires content
	# validation to reject an all-zero-weight customer before it ever reaches
	# the domain, so `sum_max_penalty` is never zero for well-formed input and
	# the division below is always defined.
	assert(sum_max_penalty > 0, "FlavourScorer: no weighted dimension to score against")

	# Multiplication precedes division so precision is lost only once, per
	# ADR 0004 section 3. Truncation direction matters at the 40/65/85 band
	# edges, so this is the project's one deliberate integer division.
	@warning_ignore("integer_division")
	var raw_score: int = 100 - (sum_penalty * 100) / sum_max_penalty

	# Largest miss is reported absent when every weighted penalty is zero.
	var has_largest_miss: bool = best_largest != null and best_largest.penalty > 0
	var largest_miss: Flavor.Dimension = Flavor.Dimension.SAVORY
	if has_largest_miss:
		largest_miss = best_largest.dimension

	var has_strongest_match: bool = best_strongest != null
	var strongest_match: Flavor.Dimension = Flavor.Dimension.SAVORY
	if has_strongest_match:
		strongest_match = best_strongest.dimension

	return Result.new(
		raw_score,
		has_strongest_match,
		strongest_match,
		has_largest_miss,
		largest_miss,
		per_dimension
	)


## Strongest match is the weighted dimension with the lowest penalty. Ties
## break by higher weight first, then by the fixed dimension order in section
## 1 — satisfied here by iterating in that order and only replacing on a
## strict improvement, so the first dimension seen keeps a full tie.
static func _is_lower_penalty(
	candidate: Evaluation.DimensionScore, current: Evaluation.DimensionScore
) -> bool:
	if candidate.penalty != current.penalty:
		return candidate.penalty < current.penalty
	return candidate.weight > current.weight


## Largest miss is the weighted dimension with the highest penalty. Same two
## tie-breaks as `_is_lower_penalty`, in the same order.
static func _is_higher_penalty(
	candidate: Evaluation.DimensionScore, current: Evaluation.DimensionScore
) -> bool:
	if candidate.penalty != current.penalty:
		return candidate.penalty > current.penalty
	return candidate.weight > current.weight
