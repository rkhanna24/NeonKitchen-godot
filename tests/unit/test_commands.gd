## The five Phase 1 commands, per ADR 0004 section 7.
##
## Every assertion below reads a field into a typed local variable rather than
## comparing `command.field` inline. A typed local is what catches a rename: it
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


func test_start_session_carries_customer_ids() -> void:
	var ids: Array[StringName] = [&"customer.probe_a", &"customer.probe_b"]
	var command := StartSession.new(ids)

	var customer_ids: Array[StringName] = command.customer_ids
	assert_eq(customer_ids, ids)
	assert_true(command.customer_ids.is_read_only(), "customer_ids must be frozen")


func test_select_ingredient_carries_ingredient_id() -> void:
	var command := SelectIngredient.new(&"ingredient.probe")

	var ingredient_id: StringName = command.ingredient_id
	assert_eq(ingredient_id, &"ingredient.probe")
	assert_eq(typeof(command.ingredient_id), TYPE_STRING_NAME)


func test_remove_ingredient_carries_ingredient_id() -> void:
	var command := RemoveIngredient.new(&"ingredient.probe")

	var ingredient_id: StringName = command.ingredient_id
	assert_eq(ingredient_id, &"ingredient.probe")
	assert_eq(typeof(command.ingredient_id), TYPE_STRING_NAME)


func test_present_customer_and_submit_dish_carry_no_fields() -> void:
	# Per ADR 0004 section 7: both advance session state the application layer
	# owns, so neither command declares a field to pin.
	assert_not_null(PresentCustomer.new())
	assert_not_null(SubmitDish.new())
