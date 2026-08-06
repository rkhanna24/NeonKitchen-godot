## Begins a session with an explicit customer roster, per ADR 0004 section 7.
##
## The roster is explicit rather than read from a global default so golden
## cases can pin the exact encounter sequence.
class_name StartSession
extends RefCounted

var customer_ids: Array[StringName]


func _init(p_customer_ids: Array[StringName]) -> void:
	customer_ids = p_customer_ids
	customer_ids.make_read_only()
