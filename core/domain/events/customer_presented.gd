## Emitted when the next customer in the roster is presented, per ADR 0004
## section 8.
class_name CustomerPresented
extends DomainEvent

var customer_id: StringName
var index: int


func _init(p_sequence: int, p_customer_id: StringName, p_index: int) -> void:
	super._init(p_sequence)
	customer_id = p_customer_id
	index = p_index
