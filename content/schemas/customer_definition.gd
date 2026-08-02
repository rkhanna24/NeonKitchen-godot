## An authored customer, per ADR 0004 sections 2 and 5.
##
## A weight of 0 means the dimension is IGNORED, not that the customer wants
## zero of it. Dislike is a low target with a non-zero weight.
##
## The defaults below are deliberate. Comfort is weighted at 1 with a target of
## 3 because an all-zero-weight customer is invalid content, and because a
## profile of all-weights-1 with all-targets-0 reads as "no preference" while
## actually describing someone who wants an empty plate. See ADR 0004 section 2.
##
## Note that a weight only means anything relative to another weight: when a
## single dimension is weighted, its value cancels in the normalisation.
class_name CustomerDefinition
extends Resource

## Stable, namespaced, and immutable — for example `customer.mina_afterhours`.
@export var content_id: StringName = &""

@export var schema_version: int = 1

@export_group("Localisation")
@export var name_key: StringName = &""
@export var request_key: StringName = &""
@export var reaction_key: StringName = &""

@export_group("Targets")
@export_range(0, 5) var savory_target: int = 0
@export_range(0, 5) var spicy_target: int = 0
@export_range(0, 5) var fresh_target: int = 0
@export_range(0, 5) var comfort_target: int = 3
@export_range(0, 5) var adventurous_target: int = 0

@export_group("Weights")
@export_range(0, 5) var savory_weight: int = 0
@export_range(0, 5) var spicy_weight: int = 0
@export_range(0, 5) var fresh_weight: int = 0
@export_range(0, 5) var comfort_weight: int = 1
@export_range(0, 5) var adventurous_weight: int = 0

## Zero to two hard boundaries.
@export_group("Constraints")
@export var constraints: Array[CustomerConstraint] = []


## Every target, in contract order. One array rather than a `match`, which
## would fall through to 0 for a newly added dimension and silently drop it.
## Tests assert the size against `Flavor.DIMENSION_COUNT`.
func targets() -> Array[int]:
	return [savory_target, spicy_target, fresh_target, comfort_target, adventurous_target]


## Every weight, in contract order. See `targets()`.
func weights() -> Array[int]:
	return [savory_weight, spicy_weight, fresh_weight, comfort_weight, adventurous_weight]


func target_of(dimension: Flavor.Dimension) -> int:
	var values: Array[int] = targets()
	var index: int = int(dimension)
	if index < 0 or index >= values.size():
		return 0
	return values[index]


func weight_of(dimension: Flavor.Dimension) -> int:
	var values: Array[int] = weights()
	var index: int = int(dimension)
	if index < 0 or index >= values.size():
		return 0
	return values[index]


## Dimensions this customer actually cares about, in contract order.
func weighted_dimensions() -> Array[Flavor.Dimension]:
	var out: Array[Flavor.Dimension] = []
	for dimension: Flavor.Dimension in Flavor.all_dimensions():
		if weight_of(dimension) > 0:
			out.append(dimension)
	return out


func _to_string() -> String:
	return "CustomerDefinition(%s)" % content_id
