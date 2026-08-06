## Emitted with the customer's resolved reaction, per ADR 0004 sections 8 and
## 8a.
##
## `reaction_key` is a resolved localisation key, never prose (ADR 0002).
class_name CustomerReacted
extends DomainEvent

var reaction_key: StringName


func _init(p_sequence: int, p_reaction_key: StringName) -> void:
	super._init(p_sequence)
	reaction_key = p_reaction_key
