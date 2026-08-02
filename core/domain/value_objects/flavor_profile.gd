## The composed flavour of a dish: one value per dimension, in contract order.
##
## This is the typed value that sits between the two evaluation stages of
## ADR 0004 section 9 — composition produces it, scoring consumes it. Keeping it
## explicit is what lets a future composer change how ingredients combine
## without touching scoring, feedback, bands, or constraints.
class_name FlavorProfile
extends RefCounted

var _values: Array[int] = []


## Input is normalised, in both size and range, rather than accepted as given.
##
## A wrong-sized array previously produced an object whose `get_value()` indexed
## out of bounds and whose `_to_string()` crashed while iterating all five
## dimensions — so printing the object to diagnose the problem failed too.
##
## Values are clamped as well as sized, so the range promised by `get_value()`
## is a property of the type rather than of its callers. This matches the
## contract: a profile is the output of composition, which clamps to
## `0..MAX_DISH_VALUE` by definition.
func _init(values: Array[int] = []) -> void:
	_values.resize(Flavor.DIMENSION_COUNT)
	_values.fill(0)
	var count: int = mini(values.size(), Flavor.DIMENSION_COUNT)
	for index: int in range(count):
		_values[index] = clampi(values[index], 0, Flavor.MAX_DISH_VALUE)


## Value in one dimension, always within 0..MAX_DISH_VALUE.
##
## Bounds-guarded for the same reason as `Flavor.dimension_name`: an int can be
## cast into the enum from authored content, so the range is not closed at
## runtime. `_init` previously fixed only the array-size half of this.
func get_value(dimension: Flavor.Dimension) -> int:
	var index: int = int(dimension)
	if index < 0 or index >= _values.size():
		return 0
	return _values[index]


## A copy of every value in contract order. Returns a duplicate so callers
## cannot mutate the profile through the array.
func to_array() -> Array[int]:
	return _values.duplicate()


func _to_string() -> String:
	var parts: PackedStringArray = []
	for dimension: Flavor.Dimension in Flavor.all_dimensions():
		parts.append("%s=%d" % [Flavor.dimension_name(dimension), get_value(dimension)])
	return "FlavorProfile(%s)" % " ".join(parts)
