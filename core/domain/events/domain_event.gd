## Shared base for every Phase 1 domain event, per ADR 0004 sections 7 and 8.
##
## Owns the one field every event carries: a monotonic `sequence` per session,
## satisfying ADR 0002 section 3's ordering requirement. `sequence` is declared
## here and assigned by nobody in this file -- assigning it is an application
## concern (#23), out of scope for this task.
##
## This base exists because `SubmitDish` is the only command that produces
## more than one event type, and it produces three -- `DishSubmitted`,
## `DishEvaluated`, and `CustomerReacted` (section 7) -- in order, with no other
## command able to emit any of the three. Returning that ordered group needs a
## typed element narrower than `RefCounted`, since an untyped `Array` is a
## `project.godot` warning-as-error.
##
## `EncounterResult` does not extend this: it is not an event, it is a value
## `SessionEnded` carries (DEC-022).
class_name DomainEvent
extends RefCounted

var sequence: int


func _init(p_sequence: int) -> void:
	sequence = p_sequence
