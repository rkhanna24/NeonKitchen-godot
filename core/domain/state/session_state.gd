## Mutable session state for one played session, per ADR 0004 sections 7a and
## 8 (DEC-022, DEC-023).
##
## Holds the phase, roster and position, the dish under construction, and the
## `EncounterResult`s a `SessionEnded` event will carry. Mutating this state is
## `CommandHandler`'s job (`core/application`); this file defines the shape
## only and enforces nothing about which transitions are legal.
##
## The sequence counter is the one field kept private. `sequence` must be
## unique, monotonic, and never reused within a session (section 7a), and
## confining its increment to `next_sequence()` keeps that invariant next to
## the thing it describes rather than scattered through every command
## handler.
class_name SessionState
extends RefCounted

## Five session phases, per ADR 0004 section 7a.
enum Phase { NOT_STARTED, AWAITING_CUSTOMER, BUILDING_DISH, SHOWING_RESULT, ENDED }

var phase: Phase = Phase.NOT_STARTED

## The customer ids given to `StartSession`, in order. A repeated id is legal
## (section 10): the same customer may visit twice in one shift.
var roster: Array[StringName] = []

## 0-based index into `roster`. -1 until the first `PresentCustomer`
## succeeds, per section 7a.
var current_index: int = -1

## The dish under construction, as ingredient ids in selection order.
## Cleared on `PresentCustomer`, not on `SubmitDish` (section 7a), so
## `SHOWING_RESULT` can still show what was just served.
var current_dish: Array[StringName] = []

## One entry per served encounter, accumulated for `SessionEnded` (DEC-022).
var encounter_results: Array[EncounterResult] = []

var _next_sequence_value: int = 1


## The id of the customer at `current_index`, or an empty `StringName` when
## no customer has been presented yet (`current_index` is -1) or the roster
## has been exhausted.
func current_customer_id() -> StringName:
	if current_index < 0 or current_index >= roster.size():
		return &""
	return roster[current_index]


## The next value for `DomainEvent.sequence`. Starts at 1, increments by
## exactly one per call, and is never reused -- section 7a. Call this once
## per event emitted, never once per command: `SubmitDish` calls it three
## times for its three events.
func next_sequence() -> int:
	var value: int = _next_sequence_value
	_next_sequence_value += 1
	return value
