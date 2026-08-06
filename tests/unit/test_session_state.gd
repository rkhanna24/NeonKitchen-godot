## `SessionState`'s own shape, per ADR 0004 sections 7a and 8 (DEC-022).
##
## `CommandHandler`'s tests exercise state mutation through real commands;
## this file only pins the type's starting values and the one invariant it
## owns directly -- `next_sequence()`.
extends GutTest


func test_starts_not_started_with_no_customer_presented() -> void:
	var state := SessionState.new()

	assert_eq(state.phase, SessionState.Phase.NOT_STARTED)
	assert_true(state.roster.is_empty())
	assert_eq(state.current_index, -1)
	assert_true(state.current_dish.is_empty())
	assert_true(state.encounter_results.is_empty())


func test_current_customer_id_is_empty_before_any_present() -> void:
	var state := SessionState.new()
	assert_eq(state.current_customer_id(), &"")


func test_current_customer_id_reads_the_roster_at_current_index() -> void:
	var state := SessionState.new()
	state.roster = [&"customer.a", &"customer.b"]
	state.current_index = 1

	assert_eq(state.current_customer_id(), &"customer.b")


func test_current_customer_id_is_empty_once_the_roster_is_exhausted() -> void:
	var state := SessionState.new()
	state.roster = [&"customer.a"]
	state.current_index = 1

	assert_eq(state.current_customer_id(), &"")


func test_next_sequence_starts_at_one_and_increments_by_exactly_one() -> void:
	var state := SessionState.new()

	assert_eq(state.next_sequence(), 1)
	assert_eq(state.next_sequence(), 2)
	assert_eq(state.next_sequence(), 3)


func test_next_sequence_never_repeats_a_value() -> void:
	var state := SessionState.new()
	var seen: Dictionary[int, bool] = {}

	for _i: int in range(10):
		var value: int = state.next_sequence()
		assert_false(seen.has(value), "sequence value %d was reused" % value)
		seen[value] = true
