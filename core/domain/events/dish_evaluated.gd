## Emitted with the evaluation result of a submitted dish, per ADR 0004
## section 8.
class_name DishEvaluated
extends DomainEvent

var evaluation: Evaluation


func _init(p_sequence: int, p_evaluation: Evaluation) -> void:
	super._init(p_sequence)
	evaluation = p_evaluation
