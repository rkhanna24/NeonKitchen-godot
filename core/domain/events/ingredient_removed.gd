## Emitted when an ingredient is removed from the dish under construction, per
## ADR 0004 section 8.
class_name IngredientRemoved
extends DomainEvent

var ingredient_id: StringName
var dish_profile: FlavorProfile


func _init(p_sequence: int, p_ingredient_id: StringName, p_dish_profile: FlavorProfile) -> void:
	super._init(p_sequence)
	ingredient_id = p_ingredient_id
	dish_profile = p_dish_profile
