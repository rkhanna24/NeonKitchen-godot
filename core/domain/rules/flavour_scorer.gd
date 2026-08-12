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

		if _is_unengaged(entry):
			continue

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

	# One candidate cannot be both the best and the worst thing about a dish
	# (DEC-028). The opposed tie-breaks above separate two candidates whenever
	# their weights differ, but two cases still resolve to one dimension: a
	# single candidate, which has nothing to be compared against, and candidates
	# tied on penalty *and* weight, which fall through to dimension order in both
	# directions. The miss survives and the match is dropped: the collision only
	# ever happens with a non-zero penalty, since `has_largest_miss` already
	# requires one, so there is a real error to report and calling it a match
	# would be the misleading half.
	if has_strongest_match and has_largest_miss and strongest_match == largest_miss:
		has_strongest_match = false
		strongest_match = Flavor.Dimension.SAVORY

	return Result.new(
		raw_score,
		has_strongest_match,
		strongest_match,
		has_largest_miss,
		largest_miss,
		per_dimension
	)


## A dimension with target 0 and actual 0 was never engaged by the player,
## per ADR 0004 section 6 (DEC-025). It stays in `per_dimension` and its
## penalty (always 0) still contributes to the score, but it is never a
## candidate for either feedback selection.
static func _is_unengaged(entry: Evaluation.DimensionScore) -> bool:
	return entry.target == 0 and entry.actual == 0


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


## Largest miss is the weighted dimension with the highest penalty. Ties break
## by **lower** weight first — the opposite of `_is_lower_penalty` — then by the
## fixed dimension order in section 1.
##
## The opposition is the point, per DEC-028. Penalty is `weight * error`, so two
## dimensions tied on penalty with different weights have inversely different
## raw errors: the heavier one is *closer* to its target. Breaking both
## selections toward higher weight therefore made a single dimension win both,
## and naming the dimension nearest its target the "largest miss" would be
## exactly backwards. Lowest weight among equals is the largest raw error, which
## is what a miss means.
static func _is_higher_penalty(
	candidate: Evaluation.DimensionScore, current: Evaluation.DimensionScore
) -> bool:
	if candidate.penalty != current.penalty:
		return candidate.penalty > current.penalty
	return candidate.weight < current.weight
