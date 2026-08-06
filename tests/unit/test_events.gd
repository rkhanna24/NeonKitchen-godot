## The eight Phase 1 events plus `EncounterResult`, per ADR 0004 section 8 and
## DEC-022.
##
## Every assertion below reads a field into a typed local variable rather than
## comparing `event.field` inline. A typed local is what catches a rename: it
## turns "not present on the inferred type" into a parse error, so a renamed
## field fails this test before any assertion runs. Confirmed by a reverted
## spike (see the approved proposal on issue #22).
##
## `StringName` fields get an additional `typeof()` check. GDScript implicitly
## converts a `String` into a `StringName`-typed local, so the typed-local
## check alone does not catch a scalar field retyped from `StringName` to
## `String` -- `typeof()` does, since it inspects the runtime value rather than
## the declared type.
extends GutTest


static func _profile() -> FlavorProfile:
	return FlavorProfile.new([1, 2, 0, 3, 0])


static func _evaluation() -> Evaluation:
	var violated_constraints: Array[Evaluation.ViolatedConstraint] = []
	var per_dimension: Array[Evaluation.DimensionScore] = []
	return Evaluation.new(
		81,
		Evaluation.RatingBand.SATISFIED,
		true,
		violated_constraints,
		true,
		Flavor.Dimension.COMFORT,
		true,
		Flavor.Dimension.SPICY,
		per_dimension
	)


func test_session_started_carries_customer_count() -> void:
	var event := SessionStarted.new(1, 2)

	var sequence: int = event.sequence
	var customer_count: int = event.customer_count
	assert_eq(sequence, 1)
	assert_eq(customer_count, 2)
	assert_true(event is DomainEvent)


func test_customer_presented_carries_customer_id_and_index() -> void:
	var event := CustomerPresented.new(1, &"customer.probe", 0)

	var customer_id: StringName = event.customer_id
	var index: int = event.index
	assert_eq(customer_id, &"customer.probe")
	assert_eq(index, 0)
	assert_eq(typeof(event.customer_id), TYPE_STRING_NAME)


func test_ingredient_selected_carries_ingredient_id_and_dish_profile() -> void:
	var profile: FlavorProfile = _profile()
	var event := IngredientSelected.new(1, &"ingredient.probe", profile)

	var ingredient_id: StringName = event.ingredient_id
	var dish_profile: FlavorProfile = event.dish_profile
	assert_eq(ingredient_id, &"ingredient.probe")
	assert_same(dish_profile, profile)
	assert_eq(typeof(event.ingredient_id), TYPE_STRING_NAME)


func test_ingredient_removed_carries_ingredient_id_and_dish_profile() -> void:
	var profile: FlavorProfile = _profile()
	var event := IngredientRemoved.new(1, &"ingredient.probe", profile)

	var ingredient_id: StringName = event.ingredient_id
	var dish_profile: FlavorProfile = event.dish_profile
	assert_eq(ingredient_id, &"ingredient.probe")
	assert_same(dish_profile, profile)
	assert_eq(typeof(event.ingredient_id), TYPE_STRING_NAME)


func test_dish_submitted_carries_ingredient_ids() -> void:
	var ids: Array[StringName] = [&"ingredient.a", &"ingredient.b"]
	var event := DishSubmitted.new(1, ids)

	var ingredient_ids: Array[StringName] = event.ingredient_ids
	assert_eq(ingredient_ids, ids)
	assert_true(event.ingredient_ids.is_read_only(), "ingredient_ids must be frozen")


func test_dish_evaluated_carries_evaluation() -> void:
	var evaluation: Evaluation = _evaluation()
	var event := DishEvaluated.new(1, evaluation)

	var carried: Evaluation = event.evaluation
	assert_same(carried, evaluation)


func test_customer_reacted_carries_reaction_key() -> void:
	var event := CustomerReacted.new(1, &"reaction.night_courier.satisfied")

	var reaction_key: StringName = event.reaction_key
	assert_eq(reaction_key, &"reaction.night_courier.satisfied")
	assert_eq(typeof(event.reaction_key), TYPE_STRING_NAME)


func test_session_ended_carries_results() -> void:
	var results: Array[EncounterResult] = [
		EncounterResult.new(
			&"customer.probe", [&"ingredient.a"], 81, Evaluation.RatingBand.SATISFIED, true
		)
	]
	var event := SessionEnded.new(1, results)

	var carried: Array[EncounterResult] = event.results
	assert_eq(carried, results)
	assert_true(event.results.is_read_only(), "results must be frozen")


func test_encounter_result_carries_dec_022_fields() -> void:
	var ids: Array[StringName] = [&"ingredient.a", &"ingredient.b"]
	var result := EncounterResult.new(
		&"customer.probe", ids, 81, Evaluation.RatingBand.SATISFIED, true
	)

	var customer_id: StringName = result.customer_id
	var ingredient_ids: Array[StringName] = result.ingredient_ids
	var score: int = result.score
	var band: Evaluation.RatingBand = result.band
	var constraint_satisfied: bool = result.constraint_satisfied

	assert_eq(customer_id, &"customer.probe")
	assert_eq(ingredient_ids, ids)
	assert_eq(score, 81)
	assert_eq(band, Evaluation.RatingBand.SATISFIED)
	assert_true(constraint_satisfied)
	assert_eq(typeof(result.customer_id), TYPE_STRING_NAME)
	assert_true(result.ingredient_ids.is_read_only(), "ingredient_ids must be frozen")
	# No dynamic "EncounterResult is not a DomainEvent" check here: Godot's
	# static checker rejects `is` between two statically unrelated types as a
	# parse error rather than evaluating it, so this fact is structural --
	# visible in `EncounterResult`'s own `extends RefCounted` declaration --
	# and not one a runtime assertion in this test can express.


func test_submit_dish_can_produce_a_heterogeneous_ordered_event_group() -> void:
	# Per ADR 0004 section 7: no other command produces DishSubmitted,
	# DishEvaluated, or CustomerReacted, so SubmitDish emits all three in
	# order. This is the case DomainEvent exists to let a caller return as one
	# typed collection instead of an untyped Array.
	var events: Array[DomainEvent] = [
		DishSubmitted.new(1, [&"ingredient.a"]),
		DishEvaluated.new(2, _evaluation()),
		CustomerReacted.new(3, &"reaction.probe.satisfied"),
	]

	assert_eq(events.size(), 3)
	for event: DomainEvent in events:
		assert_true(event is DomainEvent)
