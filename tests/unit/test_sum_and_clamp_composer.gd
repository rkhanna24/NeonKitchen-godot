## `SumAndClampComposer` per ADR 0004 sections 1 and 9: sum each ingredient's
## contribution per dimension, clamp to `0..Flavor.MAX_DISH_VALUE`.
extends GutTest


static func _ingredient(
	savory: int = 0, spicy: int = 0, fresh: int = 0, comfort: int = 0, adventurous: int = 0
) -> IngredientDefinition:
	var ingredient := IngredientDefinition.new()
	ingredient.savory = savory
	ingredient.spicy = spicy
	ingredient.fresh = fresh
	ingredient.comfort = comfort
	ingredient.adventurous = adventurous
	return ingredient


func test_sums_contributions_per_dimension() -> void:
	var dish: Array[IngredientDefinition] = [
		_ingredient(1, 0, 0, 2, 0),
		_ingredient(0, 3, 0, 1, 1),
	]
	var profile: FlavorProfile = SumAndClampComposer.compose(dish)
	assert_eq(profile.get_value(Flavor.Dimension.SAVORY), 1)
	assert_eq(profile.get_value(Flavor.Dimension.SPICY), 3)
	assert_eq(profile.get_value(Flavor.Dimension.FRESH), 0)
	assert_eq(profile.get_value(Flavor.Dimension.COMFORT), 3)
	assert_eq(profile.get_value(Flavor.Dimension.ADVENTUROUS), 1)


func test_clamps_surplus_to_max_dish_value() -> void:
	# Three ingredients at comfort=3 sum to 9, well past MAX_DISH_VALUE (5).
	var dish: Array[IngredientDefinition] = [
		_ingredient(0, 0, 0, 3, 0),
		_ingredient(0, 0, 0, 3, 0),
		_ingredient(0, 0, 0, 3, 0),
	]
	# Asserted through compose_values, NOT through the returned FlavorProfile.
	# FlavorProfile._init clamps independently, so going through compose() left
	# this test green with the composer's clamp deleted entirely — verified.
	var values: Array[int] = SumAndClampComposer.compose_values(dish)
	assert_eq(values[int(Flavor.Dimension.COMFORT)], Flavor.MAX_DISH_VALUE)
	# And through the public API, so the wiring is covered too.
	assert_eq(
		SumAndClampComposer.compose(dish).get_value(Flavor.Dimension.COMFORT), Flavor.MAX_DISH_VALUE
	)


func test_reordering_ingredients_does_not_change_the_result() -> void:
	var a: IngredientDefinition = _ingredient(1, 2, 0, 0, 0)
	var b: IngredientDefinition = _ingredient(0, 1, 3, 0, 0)
	var c: IngredientDefinition = _ingredient(0, 0, 1, 2, 1)

	var forward: FlavorProfile = SumAndClampComposer.compose([a, b, c])
	var reversed_order: FlavorProfile = SumAndClampComposer.compose([c, b, a])

	for dimension: Flavor.Dimension in Flavor.all_dimensions():
		assert_eq(
			forward.get_value(dimension),
			reversed_order.get_value(dimension),
			"dimension %s must not depend on ingredient order" % Flavor.dimension_name(dimension)
		)


func test_empty_dish_composes_to_all_zero() -> void:
	var profile: FlavorProfile = SumAndClampComposer.compose([])
	for dimension: Flavor.Dimension in Flavor.all_dimensions():
		assert_eq(profile.get_value(dimension), 0)


func test_output_size_matches_dimension_count() -> void:
	# Asserted on the raw values. Through `compose()` this could not fail:
	# `FlavorProfile._init` resizes to DIMENSION_COUNT whatever it is given, so
	# the old version of this test would have passed with the composer returning
	# an array of any length.
	var dish: Array[IngredientDefinition] = [_ingredient(1, 1, 1, 1, 1)]
	assert_eq(SumAndClampComposer.compose_values(dish).size(), Flavor.DIMENSION_COUNT)
	assert_eq(SumAndClampComposer.compose(dish).to_array().size(), Flavor.DIMENSION_COUNT)
