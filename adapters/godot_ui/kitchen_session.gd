## One played Godot UI session (#32): turns a player's interaction with the
## screen into at most one approved command, and hands back the result.
##
## Owns no game rule, and deliberately owns no formatting either. It is the
## `TerminalSession` seam without the parsing half: the terminal must first turn
## a typed line into an intent, where a button press *is* the intent, so the
## parser has no counterpart here. What remains -- build one of the five
## commands in ADR 0004 section 7, call `CommandHandler`, return its
## `CommandResult` -- is identical in both adapters, and is the part that must
## stay identical (#33).
##
## Returns `CommandResult` rather than anything drawable. Choosing what a panel
## shows belongs to the screen; deciding what happened belongs to the domain.
## Keeping those apart is what lets this file be tested with no scene tree.
##
## `start()` takes the customer ids rather than reading them from the repository
## the way `TerminalSession._handle_start` does. That difference is deliberate
## and load-bearing: the Phase 2 slice runs one customer while the terminal runs
## all eight, and a shared code path that silently disagreed about *which*
## customers a session contains would be a real divergence. Passing them in makes
## the difference an argument at the call site instead of a hidden policy.
class_name KitchenSession
extends RefCounted

var _state: SessionState
var _content: ContentRepository


func _init(p_state: SessionState, p_content: ContentRepository) -> void:
	_state = p_state
	_content = p_content


## The session state this drives. Exposed read-only so the screen can render the
## current dish and phase without a second copy going stale; never write to it
## from the adapter, since `CommandHandler` is the only thing allowed to.
func state() -> SessionState:
	return _state


func content() -> ContentRepository:
	return _content


func start(customer_ids: Array[StringName]) -> CommandResult:
	return CommandHandler.handle_start_session(_state, _content, StartSession.new(customer_ids))


func present() -> CommandResult:
	return CommandHandler.handle_present_customer(_state, _content, PresentCustomer.new())


func select(ingredient_id: StringName) -> CommandResult:
	return CommandHandler.handle_select_ingredient(
		_state, _content, SelectIngredient.new(ingredient_id)
	)


func remove(ingredient_id: StringName) -> CommandResult:
	return CommandHandler.handle_remove_ingredient(
		_state, _content, RemoveIngredient.new(ingredient_id)
	)


func submit() -> CommandResult:
	return CommandHandler.handle_submit_dish(_state, _content, SubmitDish.new())
