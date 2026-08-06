## One served encounter, per ADR 0004 section 8 (DEC-022).
##
## A value copy of the dish and outcome, recorded so an end-of-session summary
## needs no re-evaluation. It deliberately omits `per_dimension` and
## `violated_constraints`: `DishEvaluated` already carried those at the moment
## they were computed.
##
## Not an event -- `SessionEnded` carries this as a value it accumulates, so it
## does not extend `DomainEvent` and carries no `sequence`.
class_name EncounterResult
extends RefCounted

var customer_id: StringName
var ingredient_ids: Array[StringName]
var score: int
var band: Evaluation.RatingBand
var constraint_satisfied: bool


func _init(
	p_customer_id: StringName,
	p_ingredient_ids: Array[StringName],
	p_score: int,
	p_band: Evaluation.RatingBand,
	p_constraint_satisfied: bool
) -> void:
	customer_id = p_customer_id
	ingredient_ids = p_ingredient_ids
	score = p_score
	band = p_band
	constraint_satisfied = p_constraint_satisfied

	ingredient_ids.make_read_only()
