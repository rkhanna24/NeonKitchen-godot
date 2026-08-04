## Phase 1's one composer, per ADR 0004 sections 1 and 9.
##
## Sums each ingredient's contribution per dimension and clamps the result to
## `0..Flavor.MAX_DISH_VALUE`. Order never affects the result: summation is
## commutative, so a dish's ingredients may be selected in any order.
##
## Adding a second composer requires a superseding ADR to section 9; this file
## must not grow a parameter that switches behaviour.
class_name SumAndClampComposer
extends RefCounted


## `ingredients` is the caller's dish. Section 1 requires 1-3 distinct
## ingredients, but this function does not enforce that — it is a pure
## arithmetic step over whatever is handed to it, and dish-size validation is
## a command-level concern (ADR 0004 section 10), not this one.
static func compose(ingredients: Array[IngredientDefinition]) -> FlavorProfile:
	return FlavorProfile.new(compose_values(ingredients))


## The summed and clamped values, before they enter a `FlavorProfile`.
##
## Exposed because `FlavorProfile._init` independently resizes and clamps, so
## asserting through `compose()` cannot distinguish this function working from
## the value object covering for it. Deleting the clamp below left all 95 tests
## green — verified — which meant the clamp was untested and a comment here
## claimed otherwise.
##
## There is no size assertion: `resize()` two lines down makes the size
## unconditionally correct, so any such check is dead code. A dimension added to
## the enum without updating `IngredientDefinition` is caught by
## `tests/unit/test_flavor.gd` instead.
static func compose_values(ingredients: Array[IngredientDefinition]) -> Array[int]:
	var sums: Array[int] = []
	sums.resize(Flavor.DIMENSION_COUNT)
	sums.fill(0)

	for ingredient: IngredientDefinition in ingredients:
		for dimension: Flavor.Dimension in Flavor.all_dimensions():
			var index: int = int(dimension)
			sums[index] += ingredient.value_of(dimension)

	for index: int in range(Flavor.DIMENSION_COUNT):
		sums[index] = clampi(sums[index], 0, Flavor.MAX_DISH_VALUE)
	return sums
