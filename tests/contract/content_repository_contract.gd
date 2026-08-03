## Shared contract for every ContentRepository implementation.
##
## Written once and subclassed per implementation, so the `.tres` repository
## and the in-memory test repository are held to identical behaviour. This is
## what lets ADR 0003 treat the in-memory version as a real substitute rather
## than a mock.
##
## Deliberately NOT named `test_*`: GUT collects by that prefix, and this base
## class is not a suite in its own right.
##
## Subclasses override `_build_repository()`. The fixtures under
## `content/test_fixtures/` define the expected identifiers below.
extends GutTest

## Includes `ingredient.smoked_fish`, which lives in a SUB-directory of the
## fixture tree. Loading is recursive; a non-recursive scan silently dropped
## content an author had grouped into folders, with validation still clean.
const EXPECTED_INGREDIENTS: Array[StringName] = [
	&"ingredient.chili_crisp",
	&"ingredient.citrus_herbs",
	&"ingredient.noodles",
	&"ingredient.smoked_fish",
]
const EXPECTED_CUSTOMERS: Array[StringName] = [
	&"customer.no_spice",
	&"customer.plain_appetite",
]

var repository: ContentRepository = null


## Overridden by each implementation's suite.
func _build_repository() -> ContentRepository:
	return null


func before_each() -> void:
	repository = _build_repository()


func test_finds_an_ingredient_by_content_id() -> void:
	var found: IngredientDefinition = repository.find_ingredient(&"ingredient.noodles")
	assert_not_null(found, "noodles should resolve")
	assert_eq(found.content_id, &"ingredient.noodles")


func test_finds_a_customer_by_content_id() -> void:
	var found: CustomerDefinition = repository.find_customer(&"customer.no_spice")
	assert_not_null(found, "customer should resolve")
	assert_eq(found.content_id, &"customer.no_spice")


func test_missing_ingredient_returns_null_rather_than_raising() -> void:
	assert_null(repository.find_ingredient(&"ingredient.does_not_exist"))


func test_missing_customer_returns_null_rather_than_raising() -> void:
	assert_null(repository.find_customer(&"customer.does_not_exist"))


func test_has_agrees_with_find() -> void:
	assert_true(repository.has_ingredient(&"ingredient.noodles"))
	assert_false(repository.has_ingredient(&"ingredient.does_not_exist"))
	assert_true(repository.has_customer(&"customer.no_spice"))
	assert_false(repository.has_customer(&"customer.does_not_exist"))


func test_all_ingredients_returns_every_definition() -> void:
	assert_eq(repository.all_ingredients().size(), EXPECTED_INGREDIENTS.size())


func test_all_customers_returns_every_definition() -> void:
	assert_eq(repository.all_customers().size(), EXPECTED_CUSTOMERS.size())


func test_all_ingredients_is_sorted_lexicographically() -> void:
	# Asserts the invariant golden cases depend on.
	#
	# Note what it cannot do. `Array[StringName].sort()` orders by internal
	# pointer, so whether its output happens to match text order depends on the
	# order the fixtures were interned in — which is content load order. With
	# these fixtures it coincides, so reinstating that bug left this suite
	# green. The failure would appear on a different load order, not here.
	#
	# This catches an implementation that does not sort or sorts backwards. It
	# does not catch one that sorts by pointer. The protection for that is
	# `_sorted_ids` comparing String, and the deterministic test in the
	# in-memory suite.
	var ids: Array[StringName] = []
	for ingredient: IngredientDefinition in repository.all_ingredients():
		ids.append(ingredient.content_id)
	assert_eq(ids, EXPECTED_INGREDIENTS, "ingredients must be in lexicographic order")


func test_all_customers_is_sorted_lexicographically() -> void:
	var ids: Array[StringName] = []
	for customer: CustomerDefinition in repository.all_customers():
		ids.append(customer.content_id)
	assert_eq(ids, EXPECTED_CUSTOMERS, "customers must be in lexicographic order")


func test_repeated_reads_return_the_same_order() -> void:
	var first: Array[StringName] = []
	for ingredient: IngredientDefinition in repository.all_ingredients():
		first.append(ingredient.content_id)
	var second: Array[StringName] = []
	for ingredient: IngredientDefinition in repository.all_ingredients():
		second.append(ingredient.content_id)
	assert_eq(first, second, "iteration order must be stable across calls")


func test_flavour_values_survive_the_round_trip_through_tres() -> void:
	# Godot silently ignores a .tres property that does not exist on the script,
	# so renaming an @export would load every fixture with that dimension at 0
	# while validation reported clean and every other test stayed green.
	# Nothing read a loaded field except content_id until this test.
	var chili: IngredientDefinition = repository.find_ingredient(&"ingredient.chili_crisp")
	assert_not_null(chili)
	assert_eq(chili.value_of(Flavor.Dimension.SPICY), 3, "spicy must survive the load")
	assert_eq(chili.value_of(Flavor.Dimension.SAVORY), 1)
	assert_eq(chili.value_of(Flavor.Dimension.ADVENTUROUS), 1)
	assert_eq(chili.value_of(Flavor.Dimension.COMFORT), 0)
	assert_true(chili.has_tag(&"spice"), "tags must survive the load")

	var noodles: IngredientDefinition = repository.find_ingredient(&"ingredient.noodles")
	assert_eq(noodles.value_of(Flavor.Dimension.COMFORT), 3)
	assert_eq(noodles.value_of(Flavor.Dimension.SPICY), 0)


func test_customer_targets_weights_and_constraints_survive_the_round_trip() -> void:
	var picky: CustomerDefinition = repository.find_customer(&"customer.no_spice")
	assert_not_null(picky)
	assert_eq(picky.target_of(Flavor.Dimension.COMFORT), 4)
	assert_eq(picky.weight_of(Flavor.Dimension.COMFORT), 3)
	assert_eq(picky.target_of(Flavor.Dimension.SPICY), 0)
	assert_eq(picky.weight_of(Flavor.Dimension.SPICY), 5)
	assert_eq(picky.weight_of(Flavor.Dimension.FRESH), 0, "unweighted means ignored")

	assert_eq(picky.constraints.size(), 1)
	var rule: CustomerConstraint = picky.constraints[0]
	assert_eq(rule.subject, &"spice")
	# Also pins the fixture's meaning, which otherwise rests entirely on
	# CustomerConstraint.kind's class default.
	assert_eq(rule.kind, CustomerConstraint.Kind.FORBID_TAG)
