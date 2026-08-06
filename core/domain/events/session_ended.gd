## Emitted when the session transitions into ENDED, per ADR 0004 sections 7a
## and 8.
class_name SessionEnded
extends DomainEvent

var results: Array[EncounterResult]


func _init(p_sequence: int, p_results: Array[EncounterResult]) -> void:
	super._init(p_sequence)
	results = p_results
	results.make_read_only()
