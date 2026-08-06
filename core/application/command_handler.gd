## Command handling per ADR 0004 sections 7, 7a, 8, 8a, and 10.
##
## Five static functions, one per Phase 1 command, each shaped
## `(state, content, command) -> CommandResult`. Every function validates
## first and mutates nothing until every check for that command has passed;
## only then does it mutate `state` and build the events section 7a's table
## specifies, in order.
##
## Static rather than an instance holding `SessionState`: every existing rule
## under `core/domain/rules/` is static, and this keeps every phase directly
## testable by constructing a `SessionState` fixture in the phase under test
## rather than driving a full command sequence to reach it. The cost is that
## a caller -- #5's composition root -- must thread `state` and `content`
## through every call site instead of capturing them once.
##
## Calls `Evaluator.evaluate()` exactly once, inside `handle_submit_dish`.
## `DishEvaluated`, the reaction band, and the recorded `EncounterResult` all
## derive from that one return value; this file never rescores a dish.
##
## ## Validation order
##
## Three rules govern every function below, in force whenever more than one
## rejection condition would otherwise apply to the same command:
##
## 1. **Phase legality first, always.** `INVALID_PHASE` outranks every other
##    condition -- a command issued in the wrong phase is not "also" a
##    duplicate ingredient, because the state it would be checked against is
##    not the state the player is in.
## 2. **Then input validity, then state conflicts.** `UNKNOWN_INGREDIENT` is
##    checked before `DUPLICATE_INGREDIENT` and `DISH_FULL` -- an id that
##    resolves to nothing cannot meaningfully be a duplicate of anything.
## 3. **`DUPLICATE_INGREDIENT` before `DISH_FULL`.** A dish that already
##    holds three ingredients, one of which is the ingredient just
##    resubmitted, is reported as a duplicate: it names the specific
##    ingredient at fault, where `DISH_FULL` only describes the dish.
class_name CommandHandler
extends RefCounted

## Lowercase band names for reaction-key resolution, in `Evaluation.RatingBand`
## order. See `_resolve_reaction_key`.
const _BAND_NAMES: Array[StringName] = [
	&"delighted",
	&"satisfied",
	&"mixed",
	&"dissatisfied",
]


## `NOT_STARTED` + `StartSession` -> `SessionStarted` -> `AWAITING_CUSTOMER`.
static func handle_start_session(
	state: SessionState, content: ContentRepository, command: StartSession
) -> CommandResult:
	if state.phase != SessionState.Phase.NOT_STARTED:
		return CommandResult.reject(CommandResult.Reason.INVALID_PHASE)
	if command.customer_ids.is_empty():
		return CommandResult.reject(CommandResult.Reason.EMPTY_ROSTER)
	for customer_id: StringName in command.customer_ids:
		if not content.has_customer(customer_id):
			return CommandResult.reject(CommandResult.Reason.UNKNOWN_CUSTOMER)

	state.roster = command.customer_ids.duplicate()
	state.current_index = -1
	state.current_dish = [] as Array[StringName]
	state.phase = SessionState.Phase.AWAITING_CUSTOMER

	var event := SessionStarted.new(state.next_sequence(), command.customer_ids.size())
	return CommandResult.accept([event] as Array[DomainEvent])


## `AWAITING_CUSTOMER` or `SHOWING_RESULT` + `PresentCustomer` ->
## `CustomerPresented` -> `BUILDING_DISH`, or `SessionEnded` -> `ENDED` when
## the roster is exhausted. Both phases accept the same command; only
## `SHOWING_RESULT` can reach `ENDED` (ADR 0004 section 7a), because
## `AWAITING_CUSTOMER` is entered once, immediately after a `StartSession`
## that `EMPTY_ROSTER` guarantees left at least one customer to present.
## `content` and `command` are unused: which customer is next is roster
## position, not content lookup, and `PresentCustomer` carries no fields.
## Both stay in the signature for call-site symmetry across all five
## handlers, per the approved proposal.
static func handle_present_customer(
	state: SessionState, _content: ContentRepository, _command: PresentCustomer
) -> CommandResult:
	if (
		state.phase != SessionState.Phase.AWAITING_CUSTOMER
		and state.phase != SessionState.Phase.SHOWING_RESULT
	):
		return CommandResult.reject(CommandResult.Reason.INVALID_PHASE)

	# Cleared here, not on SubmitDish (section 7a), regardless of which
	# branch below runs: once ENDED, no further command reads it.
	state.current_dish = [] as Array[StringName]

	var next_index: int = state.current_index + 1
	if next_index < state.roster.size():
		state.current_index = next_index
		state.phase = SessionState.Phase.BUILDING_DISH
		var customer_id: StringName = state.roster[next_index]
		var event := CustomerPresented.new(state.next_sequence(), customer_id, next_index)
		return CommandResult.accept([event] as Array[DomainEvent])

	state.phase = SessionState.Phase.ENDED
	var results: Array[EncounterResult] = state.encounter_results.duplicate()
	var ended_event := SessionEnded.new(state.next_sequence(), results)
	return CommandResult.accept([ended_event] as Array[DomainEvent])


## `BUILDING_DISH` + `SelectIngredient` -> `IngredientSelected`, phase
## unchanged.
static func handle_select_ingredient(
	state: SessionState, content: ContentRepository, command: SelectIngredient
) -> CommandResult:
	if state.phase != SessionState.Phase.BUILDING_DISH:
		return CommandResult.reject(CommandResult.Reason.INVALID_PHASE)
	if not content.has_ingredient(command.ingredient_id):
		return CommandResult.reject(CommandResult.Reason.UNKNOWN_INGREDIENT)
	if state.current_dish.has(command.ingredient_id):
		return CommandResult.reject(CommandResult.Reason.DUPLICATE_INGREDIENT)
	if state.current_dish.size() >= Flavor.MAX_DISH_SIZE:
		return CommandResult.reject(CommandResult.Reason.DISH_FULL)

	state.current_dish.append(command.ingredient_id)
	var dish_profile: FlavorProfile = _compose_current_dish(state, content)

	var event := IngredientSelected.new(state.next_sequence(), command.ingredient_id, dish_profile)
	return CommandResult.accept([event] as Array[DomainEvent])


## `BUILDING_DISH` + `RemoveIngredient` -> `IngredientRemoved`, phase
## unchanged.
static func handle_remove_ingredient(
	state: SessionState, content: ContentRepository, command: RemoveIngredient
) -> CommandResult:
	if state.phase != SessionState.Phase.BUILDING_DISH:
		return CommandResult.reject(CommandResult.Reason.INVALID_PHASE)
	# Input validity before state conflict, the same precedence `SelectIngredient`
	# uses. `NOT_SELECTED` alone would be *correct* here -- `current_dish` only
	# ever holds ids `SelectIngredient` already validated, so an unknown id is
	# never in it -- but it would answer the wrong question. "You have not
	# selected that" and "no such ingredient exists" send a player to different
	# places, and section 10 scopes neither error to one command.
	if not content.has_ingredient(command.ingredient_id):
		return CommandResult.reject(CommandResult.Reason.UNKNOWN_INGREDIENT)
	if not state.current_dish.has(command.ingredient_id):
		return CommandResult.reject(CommandResult.Reason.NOT_SELECTED)

	state.current_dish.erase(command.ingredient_id)
	var dish_profile: FlavorProfile = _compose_current_dish(state, content)

	var event := IngredientRemoved.new(state.next_sequence(), command.ingredient_id, dish_profile)
	return CommandResult.accept([event] as Array[DomainEvent])


## `BUILDING_DISH` + `SubmitDish` -> `DishSubmitted`, `DishEvaluated`,
## `CustomerReacted`, in that order (section 7a) -> `SHOWING_RESULT`.
##
## `Evaluator.evaluate()` is called exactly once; `DishEvaluated`, the
## resolved reaction key, and the recorded `EncounterResult` all read from
## that single `Evaluation`.
##
## `command` is unused: the dish being submitted is session state, not a
## command field. It stays in the signature for call-site symmetry, per the
## approved proposal.
static func handle_submit_dish(
	state: SessionState, content: ContentRepository, _command: SubmitDish
) -> CommandResult:
	if state.phase != SessionState.Phase.BUILDING_DISH:
		return CommandResult.reject(CommandResult.Reason.INVALID_PHASE)
	if state.current_dish.is_empty():
		return CommandResult.reject(CommandResult.Reason.EMPTY_DISH)

	var dish_ids: Array[StringName] = state.current_dish.duplicate()
	var ingredients: Array[IngredientDefinition] = []
	for ingredient_id: StringName in dish_ids:
		ingredients.append(content.find_ingredient(ingredient_id))
	var customer: CustomerDefinition = content.find_customer(state.current_customer_id())

	var evaluation: Evaluation = Evaluator.evaluate(ingredients, customer)

	var events: Array[DomainEvent] = []
	events.append(DishSubmitted.new(state.next_sequence(), dish_ids))
	events.append(DishEvaluated.new(state.next_sequence(), evaluation))
	var reaction_key: StringName = _resolve_reaction_key(customer.reaction_key, evaluation.band)
	events.append(CustomerReacted.new(state.next_sequence(), reaction_key))

	state.encounter_results.append(
		EncounterResult.new(
			state.current_customer_id(),
			dish_ids,
			evaluation.score,
			evaluation.band,
			evaluation.constraint_satisfied
		)
	)
	state.phase = SessionState.Phase.SHOWING_RESULT

	return CommandResult.accept(events)


## The composed `FlavorProfile` of `state.current_dish` as it stands right
## now. Relies on every id in `current_dish` already resolving through
## `content`: `handle_select_ingredient` only ever appends an id it has
## confirmed with `content.has_ingredient()` first.
static func _compose_current_dish(state: SessionState, content: ContentRepository) -> FlavorProfile:
	var ingredients: Array[IngredientDefinition] = []
	for ingredient_id: StringName in state.current_dish:
		ingredients.append(content.find_ingredient(ingredient_id))
	return SumAndClampComposer.compose(ingredients)


## `CustomerReacted` carries one resolved key, per ADR 0004 section 8a.
## Phase 1 produces `<prefix>.<band>` unconditionally -- the qualifier and
## bare-prefix tiers both require knowing which keys are authored, which
## needs a `LocalizationPort` that does not exist yet, and section 8a
## explicitly forbids writing them as unreachable branches.
static func _resolve_reaction_key(prefix: StringName, band: Evaluation.RatingBand) -> StringName:
	var index: int = int(band)
	var band_name: StringName = &"unknown"
	if index >= 0 and index < _BAND_NAMES.size():
		band_name = _BAND_NAMES[index]
	return StringName("%s.%s" % [prefix, band_name])
