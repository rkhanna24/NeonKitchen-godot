## An authored ingredient, per ADR 0004 section 1 and DEC-010.
##
## Treat instances as immutable at runtime. Godot shares Resources by reference,
## so writing to a loaded definition mutates it for every consumer at once. If a
## mutable copy is ever needed, take an explicit `duplicate()`.
class_name IngredientDefinition
extends Resource

## The pantry listing's groups, in display order — so this is a contract, not
## just a set. See the `group` export below for why it is presentation only.
const GROUPS: Array[StringName] = [
	&"staple",
	&"broth_and_fat",
	&"heat_and_ferment",
	&"fresh_and_cured",
]

## Stable, namespaced, and immutable — for example `ingredient.thick_wheat_noodles`.
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

## Where this ingredient sits in the pantry listing, per DEC-029. Display order
## is this array's order, so it is a contract and not just a set.
##
## **Presentation only.** The group never enters scoring, constraints, or
## validation of any other field, and no rule rewards taking one from each. That
## restraint is the finding rather than an omission: enumerating all 220
## three-ingredient dishes against the eight shipped customers showed
## one-from-each-group is worth 1.9 points of mean score, and costs up to 30
## points of reachable best — six of eight customers are served best by a dish
## that concentrates in one group, and two of them cannot reach DELIGHTED under
## the heuristic at all. Grouping makes twelve ingredients scannable. It does not
## predict a good dish, and content must not imply that it does.
@export_group("Presentation")
@export var group: StringName = &""


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
