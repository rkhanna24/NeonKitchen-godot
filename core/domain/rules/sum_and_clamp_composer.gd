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
	var sums: Array[int] = []
	sums.resize(Flavor.DIMENSION_COUNT)
	sums.fill(0)

	for ingredient: IngredientDefinition in ingredients:
		for dimension: Flavor.Dimension in Flavor.all_dimensions():
			var index: int = int(dimension)
			sums[index] += ingredient.value_of(dimension)

	var clamped: Array[int] = []
	clamped.resize(Flavor.DIMENSION_COUNT)
	for index: int in range(Flavor.DIMENSION_COUNT):
		clamped[index] = clampi(sums[index], 0, Flavor.MAX_DISH_VALUE)

	# `FlavorProfile._init` silently normalises a wrong-sized array rather than
	# failing loudly. That silent normalisation is a carried finding from issue
	# #9, deliberately left in place; this composer instead asserts its own
	# output size rather than leaning on it. A size mismatch here is a bug in
	# this function, not content the domain should tolerate.
	assert(
		clamped.size() == Flavor.DIMENSION_COUNT,
		(
			"SumAndClampComposer produced %d values, expected %d"
			% [clamped.size(), Flavor.DIMENSION_COUNT]
		)
	)
	return FlavorProfile.new(clamped)
