## `CommandResult`'s two constructors, per ADR 0004 section 10.
##
## `CommandHandler`'s tests exercise which reason each rejection carries;
## this file only pins the shape both outcomes share.
extends GutTest


func test_accept_carries_the_given_events_and_no_rejection() -> void:
	var event := SessionStarted.new(1, 2)
	var result := CommandResult.accept([event] as Array[DomainEvent])

	assert_true(result.is_accepted)
	assert_eq(result.events.size(), 1)
	assert_same(result.events[0], event)
	assert_false(result.has_rejection_reason)


func test_accept_freezes_its_events() -> void:
	var event := SessionStarted.new(1, 2)
	var result := CommandResult.accept([event] as Array[DomainEvent])

	assert_true(result.events.is_read_only(), "events must be frozen")


func test_reject_carries_no_event_and_the_given_reason() -> void:
	var result := CommandResult.reject(CommandResult.Reason.EMPTY_ROSTER)

	assert_false(result.is_accepted)
	assert_true(result.events.is_empty(), "a rejection must carry no event")
	assert_true(result.events.is_read_only(), "events must be frozen")
	assert_true(result.has_rejection_reason)
	assert_eq(result.rejection_reason, CommandResult.Reason.EMPTY_ROSTER)


func test_reject_reports_each_of_the_eight_reasons() -> void:
	var reasons: Array[CommandResult.Reason] = [
		CommandResult.Reason.UNKNOWN_CUSTOMER,
		CommandResult.Reason.EMPTY_ROSTER,
		CommandResult.Reason.UNKNOWN_INGREDIENT,
		CommandResult.Reason.DUPLICATE_INGREDIENT,
		CommandResult.Reason.DISH_FULL,
		CommandResult.Reason.NOT_SELECTED,
		CommandResult.Reason.EMPTY_DISH,
		CommandResult.Reason.INVALID_PHASE,
	]
	for reason: CommandResult.Reason in reasons:
		var result := CommandResult.reject(reason)
		assert_eq(result.rejection_reason, reason)
