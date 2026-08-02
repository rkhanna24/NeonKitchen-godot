## The in-memory repository against the shared ContentRepository contract.
extends "res://tests/contract/content_repository_contract.gd"

const INGREDIENT_DIR: String = "res://content/test_fixtures/ingredients"
const CUSTOMER_DIR: String = "res://content/test_fixtures/customers"


func _build_repository() -> ContentRepository:
	# Built from the same fixtures the .tres repository loads, so the two suites
	# compare like with like.
	#
	# The loader result is asserted rather than discarded. Without this, a
	# regression in the .tres adapter or in a fixture served nothing here, and
	# eight contract tests failed with "0 != 4" while naming the in-memory
	# repository -- the wrong component entirely.
	var loader := TresContentRepository.new()
	var problems: PackedStringArray = loader.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(
		problems.size(),
		0,
		(
			"fixture load failed, so this suite is not testing the in-memory repository: %s"
			% "\n".join(problems)
		)
	)
	return InMemoryContentRepository.new(loader.all_ingredients(), loader.all_customers())


func test_insertion_order_does_not_leak_into_iteration() -> void:
	# Deterministic half of the sorting guard: definitions are supplied in
	# reverse lexicographic order, so an implementation that forgot to sort,
	# or sorted backwards, fails here regardless of how StringName interning
	# happens to land.
	var reversed: Array[IngredientDefinition] = []
	for id: String in ["ingredient.zulu", "ingredient.mike", "ingredient.alpha"]:
		var ingredient := IngredientDefinition.new()
		ingredient.content_id = StringName(id)
		reversed.append(ingredient)

	var subject := InMemoryContentRepository.new(reversed, [] as Array[CustomerDefinition])
	var ids: Array[StringName] = []
	for ingredient: IngredientDefinition in subject.all_ingredients():
		ids.append(ingredient.content_id)

	var expected: Array[StringName] = [&"ingredient.alpha", &"ingredient.mike", &"ingredient.zulu"]
	assert_eq(ids, expected, "iteration must not reflect insertion order")
