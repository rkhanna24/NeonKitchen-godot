## Emitted when a dish is submitted for evaluation, per ADR 0004 section 8.
class_name DishSubmitted
extends DomainEvent

var ingredient_ids: Array[StringName]


func _init(p_sequence: int, p_ingredient_ids: Array[StringName]) -> void:
	super._init(p_sequence)
	ingredient_ids = p_ingredient_ids
	ingredient_ids.make_read_only()
