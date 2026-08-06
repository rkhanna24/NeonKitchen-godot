## Removes one ingredient from the dish under construction, per ADR 0004
## section 7.
class_name RemoveIngredient
extends RefCounted

var ingredient_id: StringName


func _init(p_ingredient_id: StringName) -> void:
	ingredient_id = p_ingredient_id
