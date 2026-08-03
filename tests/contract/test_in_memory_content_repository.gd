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


func test_a_duplicate_content_id_is_reported_not_absorbed() -> void:
	# The .tres repository refuses a set containing a duplicate. Silently
	# keeping one here made the two implementations of one port disagree, and a
	# golden case could drift by one definition with no diagnostic.
	var first := IngredientDefinition.new()
	first.content_id = &"ingredient.twin"
	var second := IngredientDefinition.new()
	second.content_id = &"ingredient.twin"
	var pair: Array[IngredientDefinition] = [first, second]

	var subject := InMemoryContentRepository.new(pair, [] as Array[CustomerDefinition])
	assert_string_contains("\n".join(subject.problems()), "duplicate content_id")
	assert_eq(subject.all_ingredients().size(), 1, "first entry wins")


func test_a_null_or_unnamed_definition_is_reported() -> void:
	var nameless := IngredientDefinition.new()
	var entries: Array[IngredientDefinition] = [null, nameless]
	var subject := InMemoryContentRepository.new(entries, [] as Array[CustomerDefinition])
	var joined: String = "\n".join(subject.problems())
	assert_string_contains(joined, "null entry")
	assert_string_contains(joined, "empty content_id")
	assert_eq(subject.all_ingredients().size(), 0)


func test_the_fixture_set_has_no_structural_problems() -> void:
	var subject := _build_repository() as InMemoryContentRepository
	assert_eq(subject.problems().size(), 0, "fixtures must be structurally clean")
