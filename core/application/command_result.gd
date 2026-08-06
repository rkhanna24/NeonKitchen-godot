## The explicit result of handling one command, per ADR 0004 section 10.
##
## A rejected command "returns an explicit result" and carries no event --
## events are accepted facts, and a rejection is not one. `CommandResult` is
## the one shape both outcomes share, so a caller needs no branch just to read
## what happened: `events` is always present, empty and frozen on rejection.
##
## `has_rejection_reason` is paired with `rejection_reason` for the same
## reason `Evaluation.has_strongest_match` is paired with `strongest_match`:
## GDScript enums have no nullable form, and a sentinel `Reason` value on an
## accepted result would be easy to mistake for a real rejection.
##
## Construct through `accept()` or `reject()` only. `_init()` is intentionally
## left parameterless: `accept()` and `reject()` each need a different
## combination of defaults for the field the other one sets (a frozen empty
## `events` on rejection; `has_rejection_reason = false` on acceptance), so a
## single shared constructor would need to accept both a reason and an event
## list and trust the caller to only ever populate one -- exactly the
## ambiguity these two named factories exist to remove.
class_name CommandResult
extends RefCounted

## Eight rejection reasons, per ADR 0004 section 10. `CommandHandler` documents
## the order in which these are checked when more than one applies to the same
## command.
enum Reason {
	UNKNOWN_CUSTOMER,
	EMPTY_ROSTER,
	UNKNOWN_INGREDIENT,
	DUPLICATE_INGREDIENT,
	DISH_FULL,
	NOT_SELECTED,
	EMPTY_DISH,
	INVALID_PHASE,
}

var is_accepted: bool

## The events this command produced, in emit order. Empty and read-only when
## `is_accepted` is false: a rejected command must not be able to smuggle an
## event into a caller's replay stream.
var events: Array[DomainEvent]

var has_rejection_reason: bool

## Meaningless when `has_rejection_reason` is false. Do not read this field
## without checking that flag first.
var rejection_reason: Reason


## An accepted command's result. `p_events` must be in the exact order ADR
## 0004 section 7a specifies for the command that produced them.
static func accept(p_events: Array[DomainEvent]) -> CommandResult:
	var result := CommandResult.new()
	result.is_accepted = true
	result.events = p_events
	result.events.make_read_only()
	result.has_rejection_reason = false
	result.rejection_reason = Reason.INVALID_PHASE
	return result


## A rejected command's result. Structurally cannot carry an event.
static func reject(p_reason: Reason) -> CommandResult:
	var result := CommandResult.new()
	result.is_accepted = false
	result.events = [] as Array[DomainEvent]
	result.events.make_read_only()
	result.has_rejection_reason = true
	result.rejection_reason = p_reason
	return result
