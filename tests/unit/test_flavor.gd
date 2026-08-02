## Guards the three independent declarations of "how many dimensions there are".
##
## `Dimension`, `DIMENSION_COUNT` and `DIMENSION_NAMES` must agree. An enum's
## size is not a constant expression in GDScript, so the count cannot be derived
## and this test is what keeps them in step. Adding a dimension without updating
## all three would silently drop it from every scoring and validation loop.
extends GutTest


func test_dimension_count_matches_the_enum() -> void:
	assert_eq(Flavor.DIMENSION_COUNT, Flavor.Dimension.size())


func test_dimension_names_matches_the_count() -> void:
	assert_eq(Flavor.DIMENSION_NAMES.size(), Flavor.DIMENSION_COUNT)


func test_all_dimensions_yields_every_dimension_once() -> void:
	assert_eq(Flavor.all_dimensions().size(), Flavor.DIMENSION_COUNT)


func test_dimension_name_is_guarded_against_out_of_range() -> void:
	# Reachable: an int can be cast into the enum from authored content, and
	# crashing here would break the code used to diagnose that.
	assert_eq(Flavor.dimension_name(99 as Flavor.Dimension), &"unknown")


func test_flavor_profile_clamps_out_of_range_values() -> void:
	var profile := FlavorProfile.new([9, -3, 0, 0, 0] as Array[int])
	assert_eq(profile.get_value(Flavor.Dimension.SAVORY), Flavor.MAX_DISH_VALUE)
	assert_eq(profile.get_value(Flavor.Dimension.SPICY), 0)


func test_flavor_profile_normalises_a_wrong_sized_array() -> void:
	var profile := FlavorProfile.new([1, 2] as Array[int])
	assert_eq(profile.to_array().size(), Flavor.DIMENSION_COUNT)
	assert_eq(profile.get_value(Flavor.Dimension.ADVENTUROUS), 0)
	assert_string_contains(str(profile), "adventurous=0")


func test_flavour_value_array_covers_every_dimension() -> void:
	# The accessors are array-driven precisely so this is checkable. A `match`
	# would fall through to 0 for a newly added dimension and nothing would
	# notice; here the array size disagrees with DIMENSION_COUNT and this fails.
	var ingredient := IngredientDefinition.new()
	assert_eq(ingredient.flavour_values().size(), Flavor.DIMENSION_COUNT)


func test_target_and_weight_arrays_cover_every_dimension() -> void:
	var customer := CustomerDefinition.new()
	assert_eq(customer.targets().size(), Flavor.DIMENSION_COUNT)
	assert_eq(customer.weights().size(), Flavor.DIMENSION_COUNT)


func test_accessors_are_guarded_against_out_of_range_dimensions() -> void:
	var ingredient := IngredientDefinition.new()
	var customer := CustomerDefinition.new()
	var profile := FlavorProfile.new([1, 1, 1, 1, 1] as Array[int])
	assert_eq(ingredient.value_of(99 as Flavor.Dimension), 0)
	assert_eq(customer.target_of(99 as Flavor.Dimension), 0)
	assert_eq(customer.weight_of(99 as Flavor.Dimension), 0)
	assert_eq(profile.get_value(99 as Flavor.Dimension), 0)


func test_every_named_export_is_reachable_through_the_ordered_array() -> void:
	# Distinct values per dimension, so a mis-ordered array is caught too.
	var ingredient := IngredientDefinition.new()
	ingredient.savory = 1
	ingredient.spicy = 2
	ingredient.fresh = 3
	ingredient.comfort = 1
	ingredient.adventurous = 2
	assert_eq(ingredient.value_of(Flavor.Dimension.SAVORY), 1)
	assert_eq(ingredient.value_of(Flavor.Dimension.SPICY), 2)
	assert_eq(ingredient.value_of(Flavor.Dimension.FRESH), 3)
	assert_eq(ingredient.value_of(Flavor.Dimension.COMFORT), 1)
	assert_eq(ingredient.value_of(Flavor.Dimension.ADVENTUROUS), 2)
