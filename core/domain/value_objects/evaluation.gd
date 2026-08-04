## The outcome of evaluating a dish against a customer, per ADR 0004 section 9.
##
## Evaluation is three concerns behind one entry point: `Evaluator.evaluate()`
## orchestrates composition (`SumAndClampComposer`), flavour scoring
## (`FlavourScorer`), and constraint checking (`ConstraintChecker`) and returns
## this type. It lives beside `FlavorProfile` rather than under `rules/`
## because it is the shared output type, not an implementation of a rule.
##
## `strongest_match` and `largest_miss` are each paired with a `has_*` flag
## rather than a sentinel `Dimension` value: GDScript enums have no nullable
## form, and a cast sentinel value would be easy to mistake for a real
## dimension.
class_name Evaluation
extends RefCounted

## Rating bands, per ADR 0004 section 4. Hard edges at 40, 65, and 85.
enum RatingBand { DELIGHTED, SATISFIED, MIXED, DISSATISFIED }


## One weighted dimension's arithmetic, per section 3 and section 9's
## `per_dimension` field. Exists so tests and a future debug view can show the
## arithmetic without the evaluator formatting anything; it carries no display
## strings.
class DimensionScore:
	extends RefCounted

	var dimension: Flavor.Dimension
	var target: int
	var actual: int
	var weight: int
	var penalty: int

	func _init(
		p_dimension: Flavor.Dimension, p_target: int, p_actual: int, p_weight: int, p_penalty: int
	) -> void:
		dimension = p_dimension
		target = p_target
		actual = p_actual
		weight = p_weight
		penalty = p_penalty


var score: int
var band: RatingBand
var constraint_satisfied: bool
var violated_constraint_ids: Array[StringName]
var has_strongest_match: bool
var strongest_match: Flavor.Dimension
var has_largest_miss: bool
var largest_miss: Flavor.Dimension

## Only weighted dimensions appear here, in contract order. See section 9.
var per_dimension: Array[DimensionScore]


func _init(
	p_score: int,
	p_band: RatingBand,
	p_constraint_satisfied: bool,
	p_violated_constraint_ids: Array[StringName],
	p_has_strongest_match: bool,
	p_strongest_match: Flavor.Dimension,
	p_has_largest_miss: bool,
	p_largest_miss: Flavor.Dimension,
	p_per_dimension: Array[DimensionScore]
) -> void:
	score = p_score
	band = p_band
	constraint_satisfied = p_constraint_satisfied
	violated_constraint_ids = p_violated_constraint_ids
	has_strongest_match = p_has_strongest_match
	strongest_match = p_strongest_match
	has_largest_miss = p_has_largest_miss
	largest_miss = p_largest_miss
	per_dimension = p_per_dimension

	# Read-only so a caller cannot mutate a result after the fact. Evaluator
	# passes these arrays straight through from the two sub-results, so they are
	# shared instances and mutating one mutated the other. Verified before this
	# guard: per_dimension.clear() emptied it and violated_constraint_ids
	# accepted an appended value.
	#
	# This freezes the arrays, not the DimensionScore objects inside them and not
	# the scalar fields. Full immutability would need private backing and getters
	# for nine fields; that is a known gap, not something this line solves.
	violated_constraint_ids.make_read_only()
	per_dimension.make_read_only()


## Maps a final 0..100 score to its rating band, per ADR 0004 section 4.
static func band_for_score(final_score: int) -> RatingBand:
	if final_score >= 85:
		return RatingBand.DELIGHTED
	if final_score >= 65:
		return RatingBand.SATISFIED
	if final_score >= 40:
		return RatingBand.MIXED
	return RatingBand.DISSATISFIED


func _to_string() -> String:
	return (
		"Evaluation(score=%d band=%d constraint_satisfied=%s)" % [score, band, constraint_satisfied]
	)
