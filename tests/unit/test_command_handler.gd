## `CommandHandler`, per ADR 0004 sections 7, 7a, 8, 8a, and 10.
##
## Covers, in order: the full section 7a transition table (both paths out of
## `SHOWING_RESULT`, the single path out of `AWAITING_CUSTOMER`), all eight
## section 10 rejections with a positive "state unchanged" assertion, the
## approved validation order including the pinned two-conditions-at-once
## case, `sequence` continuity across a full session including across a
## rejection, and section 8a reaction-key resolution.
extends GutTest

const RICE: StringName = &"ingredient.rice"
const CHILI: StringName = &"ingredient.chili"
const GREENS: StringName = &"ingredient.greens"
const EXTRA: StringName = &"ingredient.extra"
const ALPHA: StringName = &"customer.alpha"
const BETA: StringName = &"customer.beta"


static func _ingredient(
	content_id: StringName,
	savory: int = 0,
	spicy: int = 0,
	fresh: int = 0,
	comfort: int = 0,
	adventurous: int = 0
) -> IngredientDefinition:
	var ingredient := IngredientDefinition.new()
	ingredient.content_id = content_id
	ingredient.savory = savory
	ingredient.spicy = spicy
	ingredient.fresh = fresh
	ingredient.comfort = comfort
	ingredient.adventurous = adventurous
	return ingredient


## Comfort target 3, weight 2. A dish of rice alone (comfort 3) scores 100
## -- DELIGHTED -- by ADR 0004 section 3's formula, with no tie-breaking
## ambiguity, so this fixture set pins the reaction key deterministically.
static func _alpha() -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.content_id = ALPHA
	customer.name_key = &"customer.alpha.name"
	customer.request_key = &"customer.alpha.request"
	customer.reaction_key = &"customer.alpha.reaction"
	customer.comfort_target = 3
	customer.comfort_weight = 2
	return customer


## Spicy target 3, weight 2, comfort weight explicitly zeroed. Without that
## override, `CustomerDefinition`'s own default -- comfort weight 1, target 3
## (ADR 0004 section 2) -- would leave comfort also weighted here, and a
## chili-only dish (comfort 0) would then miss on comfort and land in
## SATISFIED rather than the deterministic DELIGHTED this fixture set needs.
static func _beta() -> CustomerDefinition:
	var customer := CustomerDefinition.new()
	customer.content_id = BETA
	customer.name_key = &"customer.beta.name"
	customer.request_key = &"customer.beta.request"
	customer.reaction_key = &"customer.beta.reaction"
	customer.spicy_target = 3
	customer.spicy_weight = 2
	customer.comfort_weight = 0
	return customer


static func _content() -> ContentRepository:
	var ingredients: Array[IngredientDefinition] = [
		_ingredient(RICE, 0, 0, 0, 3, 0),
		_ingredient(CHILI, 0, 3, 0, 0, 0),
		_ingredient(GREENS, 0, 0, 2, 0, 0),
		_ingredient(EXTRA, 0, 0, 0, 0, 0),
	]
	var customers: Array[CustomerDefinition] = [_alpha(), _beta()]
	return InMemoryContentRepository.new(ingredients, customers)


## `StartSession([ALPHA, BETA])` then one accepted `PresentCustomer`, landing
## in `BUILDING_DISH` with `ALPHA` current. Shared setup for tests that do
## not themselves exercise `NOT_STARTED` or `AWAITING_CUSTOMER`.
static func _state_in_building_dish(content: ContentRepository) -> SessionState:
	var state := SessionState.new()
	CommandHandler.handle_start_session(
		state, content, StartSession.new([ALPHA, BETA] as Array[StringName])
	)
	CommandHandler.handle_present_customer(state, content, PresentCustomer.new())
	return state


# ---------------------------------------------------------------- section 7a --


func test_full_session_matches_section_7a_event_sequence() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()
	var all_events: Array[DomainEvent] = []

	# NOT_STARTED + StartSession -> SessionStarted -> AWAITING_CUSTOMER.
	var r1: CommandResult = CommandHandler.handle_start_session(
		state, content, StartSession.new([ALPHA, BETA] as Array[StringName])
	)
	assert_true(r1.is_accepted)
	assert_eq(state.phase, SessionState.Phase.AWAITING_CUSTOMER)
	all_events.append_array(r1.events)

	# AWAITING_CUSTOMER + PresentCustomer -> CustomerPresented -> BUILDING_DISH.
	# The single path out of AWAITING_CUSTOMER (ADR 0004 section 7a, amended).
	var r2: CommandResult = CommandHandler.handle_present_customer(
		state, content, PresentCustomer.new()
	)
	assert_true(r2.is_accepted)
	assert_eq(state.phase, SessionState.Phase.BUILDING_DISH)
	all_events.append_array(r2.events)

	# BUILDING_DISH + SelectIngredient -> IngredientSelected, phase unchanged.
	var r3: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(RICE)
	)
	assert_true(r3.is_accepted)
	assert_eq(state.phase, SessionState.Phase.BUILDING_DISH)
	all_events.append_array(r3.events)

	# BUILDING_DISH + SubmitDish -> DishSubmitted, DishEvaluated,
	# CustomerReacted, in that order -> SHOWING_RESULT.
	var r4: CommandResult = CommandHandler.handle_submit_dish(state, content, SubmitDish.new())
	assert_true(r4.is_accepted)
	assert_eq(state.phase, SessionState.Phase.SHOWING_RESULT)
	assert_eq(r4.events.size(), 3)
	all_events.append_array(r4.events)

	# SHOWING_RESULT + PresentCustomer, roster not exhausted ->
	# CustomerPresented -> BUILDING_DISH. First path out of SHOWING_RESULT.
	var r5: CommandResult = CommandHandler.handle_present_customer(
		state, content, PresentCustomer.new()
	)
	assert_true(r5.is_accepted)
	assert_eq(state.phase, SessionState.Phase.BUILDING_DISH)
	all_events.append_array(r5.events)

	var r6: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(CHILI)
	)
	assert_true(r6.is_accepted)
	all_events.append_array(r6.events)

	var r7: CommandResult = CommandHandler.handle_submit_dish(state, content, SubmitDish.new())
	assert_true(r7.is_accepted)
	assert_eq(state.phase, SessionState.Phase.SHOWING_RESULT)
	all_events.append_array(r7.events)

	# SHOWING_RESULT + PresentCustomer, roster exhausted -> SessionEnded ->
	# ENDED. Second path out of SHOWING_RESULT.
	var r8: CommandResult = CommandHandler.handle_present_customer(
		state, content, PresentCustomer.new()
	)
	assert_true(r8.is_accepted)
	assert_eq(state.phase, SessionState.Phase.ENDED)
	all_events.append_array(r8.events)

	# The pasted-not-described sequence required by the approval:
	#  1 SessionStarted     customer_count=2
	#  2 CustomerPresented  customer_id=ALPHA index=0
	#  3 IngredientSelected ingredient_id=RICE
	#  4 DishSubmitted      ingredient_ids=[RICE]
	#  5 DishEvaluated      score=100 band=DELIGHTED
	#  6 CustomerReacted    reaction_key=customer.alpha.reaction.delighted
	#  7 CustomerPresented  customer_id=BETA index=1
	#  8 IngredientSelected ingredient_id=CHILI
	#  9 DishSubmitted      ingredient_ids=[CHILI]
	# 10 DishEvaluated      score=100 band=DELIGHTED
	# 11 CustomerReacted    reaction_key=customer.beta.reaction.delighted
	# 12 SessionEnded       results.size()=2
	assert_eq(all_events.size(), 12)

	var expected_types: Array[Script] = [
		SessionStarted,
		CustomerPresented,
		IngredientSelected,
		DishSubmitted,
		DishEvaluated,
		CustomerReacted,
		CustomerPresented,
		IngredientSelected,
		DishSubmitted,
		DishEvaluated,
		CustomerReacted,
		SessionEnded,
	]
	for index: int in range(all_events.size()):
		var event: DomainEvent = all_events[index]
		assert_eq(event.sequence, index + 1, "event %d out of order" % index)
		assert_true(
			is_instance_of(event, expected_types[index]),
			"event %d expected %s, got %s" % [index, expected_types[index], event]
		)

	var session_started := all_events[0] as SessionStarted
	assert_eq(session_started.customer_count, 2)

	var first_presented := all_events[1] as CustomerPresented
	assert_eq(first_presented.customer_id, ALPHA)
	assert_eq(first_presented.index, 0)

	var first_selected := all_events[2] as IngredientSelected
	assert_eq(first_selected.ingredient_id, RICE)

	var first_submitted := all_events[3] as DishSubmitted
	assert_eq(first_submitted.ingredient_ids, [RICE] as Array[StringName])

	var first_evaluated := all_events[4] as DishEvaluated
	assert_eq(first_evaluated.evaluation.score, 100)
	assert_eq(first_evaluated.evaluation.band, Evaluation.RatingBand.DELIGHTED)

	var first_reacted := all_events[5] as CustomerReacted
	assert_eq(first_reacted.reaction_key, &"customer.alpha.reaction.delighted")

	var second_presented := all_events[6] as CustomerPresented
	assert_eq(second_presented.customer_id, BETA)
	assert_eq(second_presented.index, 1)

	var second_reacted := all_events[10] as CustomerReacted
	assert_eq(second_reacted.reaction_key, &"customer.beta.reaction.delighted")

	var ended := all_events[11] as SessionEnded
	assert_eq(ended.results.size(), 2)
	assert_eq(ended.results[0].customer_id, ALPHA)
	assert_eq(ended.results[0].ingredient_ids, [RICE] as Array[StringName])
	assert_eq(ended.results[1].customer_id, BETA)
	assert_eq(ended.results[1].ingredient_ids, [CHILI] as Array[StringName])


func test_dish_is_cleared_on_present_customer_not_on_submit_dish() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))

	CommandHandler.handle_submit_dish(state, content, SubmitDish.new())
	assert_eq(
		state.current_dish,
		[RICE] as Array[StringName],
		"dish must still read during SHOWING_RESULT"
	)

	CommandHandler.handle_present_customer(state, content, PresentCustomer.new())
	assert_true(
		state.current_dish.is_empty(), "dish must be cleared once the next customer is presented"
	)


# --------------------------------------------------------------- section 10 --


func test_start_session_rejects_an_empty_roster_and_leaves_state_unchanged() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()

	var result: CommandResult = CommandHandler.handle_start_session(
		state, content, StartSession.new([] as Array[StringName])
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.EMPTY_ROSTER)
	assert_true(result.events.is_empty())
	assert_eq(state.phase, SessionState.Phase.NOT_STARTED, "state must be unchanged")
	assert_true(state.roster.is_empty(), "state must be unchanged")


func test_start_session_rejects_an_unknown_customer_id() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()

	var result: CommandResult = CommandHandler.handle_start_session(
		state, content, StartSession.new([&"customer.ghost"] as Array[StringName])
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.UNKNOWN_CUSTOMER)
	assert_true(result.events.is_empty())
	assert_eq(state.phase, SessionState.Phase.NOT_STARTED)


func test_present_customer_rejects_the_wrong_phase_and_leaves_state_unchanged() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()
	# NOT_STARTED does not list PresentCustomer, per section 7a's table.

	var result: CommandResult = CommandHandler.handle_present_customer(
		state, content, PresentCustomer.new()
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.INVALID_PHASE)
	assert_true(result.events.is_empty())
	assert_eq(state.phase, SessionState.Phase.NOT_STARTED, "state must be unchanged")
	assert_eq(state.current_index, -1, "state must be unchanged")


func test_start_session_rejects_a_second_call_and_leaves_state_unchanged() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	var roster_before: Array[StringName] = state.roster.duplicate()

	var result: CommandResult = CommandHandler.handle_start_session(
		state, content, StartSession.new([ALPHA] as Array[StringName])
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.INVALID_PHASE)
	assert_eq(state.phase, SessionState.Phase.BUILDING_DISH, "state must be unchanged")
	assert_eq(state.roster, roster_before, "state must be unchanged")


func test_select_ingredient_rejects_an_unknown_ingredient_id() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)

	var result: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(&"ingredient.ghost")
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.UNKNOWN_INGREDIENT)
	assert_true(result.events.is_empty())
	assert_true(state.current_dish.is_empty(), "state must be unchanged")


func test_select_ingredient_rejects_a_duplicate_and_leaves_state_unchanged() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))

	var result: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(RICE)
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.DUPLICATE_INGREDIENT)
	assert_true(result.events.is_empty())
	assert_eq(state.current_dish, [RICE] as Array[StringName], "state must be unchanged")


func test_select_ingredient_rejects_a_fourth_distinct_ingredient() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(CHILI))
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(GREENS))

	var dish_before: Array[StringName] = state.current_dish.duplicate()
	var result: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(EXTRA)
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.DISH_FULL)
	assert_eq(state.current_dish, dish_before, "state must be unchanged")


## Validation order, per the approval: DUPLICATE_INGREDIENT outranks
## DISH_FULL when both conditions apply to the same command -- a dish
## already holding three ingredients, asked to re-add one it already holds.
func test_duplicate_ingredient_outranks_dish_full_when_both_apply() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(CHILI))
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(GREENS))
	# The dish is now full (3 distinct) AND re-adding RICE would be a
	# duplicate. Both conditions apply to this one call.

	var dish_before: Array[StringName] = state.current_dish.duplicate()
	var result: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(RICE)
	)

	assert_false(result.is_accepted)
	assert_eq(
		result.rejection_reason,
		CommandResult.Reason.DUPLICATE_INGREDIENT,
		"duplicate names the specific ingredient at fault and must outrank dish-full"
	)
	assert_eq(state.current_dish, dish_before, "state must be unchanged")


func test_remove_ingredient_rejects_an_unselected_ingredient() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))

	var result: CommandResult = CommandHandler.handle_remove_ingredient(
		state, content, RemoveIngredient.new(CHILI)
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.NOT_SELECTED)
	assert_true(result.events.is_empty())
	assert_eq(state.current_dish, [RICE] as Array[StringName], "state must be unchanged")


func test_remove_ingredient_reports_an_unknown_id_as_unknown_not_unselected() -> void:
	# An unknown id can never be in `current_dish`, so NOT_SELECTED would also
	# reject it -- correctly, but by answering the wrong question. Input validity
	# outranks state conflict, so the player is told the ingredient does not
	# exist rather than that they have not selected it.
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))

	var result: CommandResult = CommandHandler.handle_remove_ingredient(
		state, content, RemoveIngredient.new(&"ingredient.does_not_exist")
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.UNKNOWN_INGREDIENT)
	assert_true(result.events.is_empty())
	assert_eq(state.current_dish, [RICE] as Array[StringName], "state must be unchanged")


func test_submit_dish_rejects_an_empty_dish() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)

	var result: CommandResult = CommandHandler.handle_submit_dish(state, content, SubmitDish.new())

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.EMPTY_DISH)
	assert_true(result.events.is_empty())
	assert_eq(state.phase, SessionState.Phase.BUILDING_DISH, "state must be unchanged")
	assert_true(state.encounter_results.is_empty(), "state must be unchanged")


func test_submit_dish_rejects_the_wrong_phase() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()
	CommandHandler.handle_start_session(
		state, content, StartSession.new([ALPHA] as Array[StringName])
	)
	# AWAITING_CUSTOMER does not list SubmitDish.

	var result: CommandResult = CommandHandler.handle_submit_dish(state, content, SubmitDish.new())

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.INVALID_PHASE)
	assert_eq(state.phase, SessionState.Phase.AWAITING_CUSTOMER, "state must be unchanged")


func test_remove_ingredient_rejects_the_wrong_phase() -> void:
	var content: ContentRepository = _content()
	var state := SessionState.new()
	# NOT_STARTED does not list RemoveIngredient.

	var result: CommandResult = CommandHandler.handle_remove_ingredient(
		state, content, RemoveIngredient.new(RICE)
	)

	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.INVALID_PHASE)
	assert_true(state.current_dish.is_empty(), "state must be unchanged")


# -------------------------------------------------------------- sequencing --


func test_sequence_is_continuous_across_a_rejected_command() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)

	var accepted_before: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(RICE)
	)
	var sequence_before: int = accepted_before.events[0].sequence

	# Rejected: emits no event and must not consume a sequence value.
	var rejected: CommandResult = CommandHandler.handle_select_ingredient(
		state, content, SelectIngredient.new(&"ingredient.ghost")
	)
	assert_false(rejected.is_accepted)

	var accepted_after: CommandResult = CommandHandler.handle_remove_ingredient(
		state, content, RemoveIngredient.new(RICE)
	)
	var sequence_after: int = accepted_after.events[0].sequence

	assert_eq(
		sequence_after,
		sequence_before + 1,
		"a rejected command must not create a gap in the sequence"
	)


# ------------------------------------------------------------------- 8a --


func test_customer_reacted_resolves_prefix_dot_band() -> void:
	var content: ContentRepository = _content()
	var state: SessionState = _state_in_building_dish(content)
	CommandHandler.handle_select_ingredient(state, content, SelectIngredient.new(RICE))

	var result: CommandResult = CommandHandler.handle_submit_dish(state, content, SubmitDish.new())

	var reacted := result.events[2] as CustomerReacted
	assert_eq(reacted.reaction_key, &"customer.alpha.reaction.delighted")
