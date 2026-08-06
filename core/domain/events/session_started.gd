## Emitted when a session begins, per ADR 0004 section 8.
class_name SessionStarted
extends DomainEvent

var customer_count: int


func _init(p_sequence: int, p_customer_count: int) -> void:
	super._init(p_sequence)
	customer_count = p_customer_count
