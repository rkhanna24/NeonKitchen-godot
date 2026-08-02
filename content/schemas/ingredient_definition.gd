## An authored ingredient, per ADR 0004 section 1 and DEC-010.
##
## Treat instances as immutable at runtime. Godot shares Resources by reference,
## so writing to a loaded definition mutates it for every consumer at once. If a
## mutable copy is ever needed, take an explicit `duplicate()`.
class_name IngredientDefinition
extends Resource

## Stable, namespaced, and immutable — for example `ingredient.neon_noodles`.
## Never a filename, resource path, UID, or translated name.
@export var content_id: StringName = &""

@export var schema_version: int = 1

@export_group("Localisation")
@export var name_key: StringName = &""
@export var description_key: StringName = &""

## Values are capped at 3 rather than 5 on purpose: one ingredient must not be
## able to reach a target of 4 or 5, which is what forces combination.
@export_group("Flavour")
@export_range(0, 3) var savory: int = 0
@export_range(0, 3) var spicy: int = 0
@export_range(0, 3) var fresh: int = 0
@export_range(0, 3) var comfort: int = 0
@export_range(0, 3) var adventurous: int = 0

## Culinary, dietary, and allergen tags. Constraints match against these.
## Tags carry no flavour meaning.
@export_group("Tags")
@export var tags: Array[StringName] = []


## Every contribution, in contract order.
##
## One array rather than a `match`: a match falls through to 0 for a dimension
## it does not name, so adding one to the enum would silently drop it from
## scoring and from the validator's range loop — the exact failure
## `Flavor.DIMENSION_COUNT` is documented to prevent. Tests assert this array's
## size against `DIMENSION_COUNT`, which a match cannot be checked for.
func flavour_values() -> Array[int]:
	return [savory, spicy, fresh, comfort, adventurous]


## Contribution in one dimension, read positionally so callers never depend on
## the export layout.
func value_of(dimension: Flavor.Dimension) -> int:
	var values: Array[int] = flavour_values()
	var index: int = int(dimension)
	if index < 0 or index >= values.size():
		return 0
	return values[index]


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func _to_string() -> String:
	return "IngredientDefinition(%s)" % content_id
