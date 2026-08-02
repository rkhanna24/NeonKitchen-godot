## Flavour vocabulary shared by content, domain, and tests.
##
## The dimension order is part of the ADR 0004 contract, not a convenience.
## It is the final tie-break for deterministic feedback selection, so
## reordering it changes evaluation output and requires a superseding ADR.
class_name Flavor
extends RefCounted

enum Dimension { SAVORY, SPICY, FRESH, COMFORT, ADVENTUROUS }

## Highest value one ingredient may contribute to a dimension.
##
## Deliberately below MAX_DISH_VALUE: a single ingredient cannot reach a target
## of 4 or 5, which is what forces combination. See ADR 0004 section 1.
const MAX_INGREDIENT_VALUE: int = 3

## Highest value a dish may reach in a dimension. Surplus is discarded.
const MAX_DISH_VALUE: int = 5

## Highest target or weight a customer may declare.
const MAX_TARGET: int = 5
const MAX_WEIGHT: int = 5

## Distinct ingredients permitted in one dish.
const MIN_DISH_SIZE: int = 1
const MAX_DISH_SIZE: int = 3

## Must equal `Dimension.size()` and `DIMENSION_NAMES.size()`.
##
## These are three separate declarations of one fact, because an enum's size is
## not a constant expression in GDScript and cannot initialise a const. Adding a
## dimension to the enum without updating both of the others would silently drop
## it from every scoring and validation loop, so
## `tests/unit/test_flavor.gd` asserts all three agree.
const DIMENSION_COUNT: int = 5

const DIMENSION_NAMES: Array[StringName] = [
	&"savory",
	&"spicy",
	&"fresh",
	&"comfort",
	&"adventurous",
]


## Stable lowercase name for a dimension, for logs and localisation keys.
##
## Guarded rather than indexed directly: an out-of-range value reaching here
## would crash the very code being used to diagnose it. `Dimension` is not a
## closed set at runtime — an int can be cast into it from authored content.
static func dimension_name(dimension: Dimension) -> StringName:
	var index: int = int(dimension)
	if index < 0 or index >= DIMENSION_NAMES.size():
		return &"unknown"
	return DIMENSION_NAMES[index]


## Every dimension in contract order. Iterate this rather than a raw range so
## the ordering guarantee stays in one place.
static func all_dimensions() -> Array[Dimension]:
	var out: Array[Dimension] = []
	for index: int in range(DIMENSION_COUNT):
		out.append(index as Dimension)
	return out
