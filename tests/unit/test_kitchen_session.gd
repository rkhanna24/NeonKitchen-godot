## `KitchenSession`, the Godot UI's command seam (#32).
##
## Driven with no scene tree at all, the same way `CommandHandler` is tested.
## That is the point of the seam: if these needed a `Control` to run, the adapter
## would be holding logic that belongs in the domain.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"
const SOLAR_TECH: StringName = &"customer.solar_tech"

var _session: KitchenSession = null


func before_each() -> void:
	var content := TresContentRepository.new()
	var problems: PackedStringArray = content.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(problems.size(), 0, "shipped content must validate")
	_session = KitchenSession.new(SessionState.new(), content)


func _open() -> void:
	var roster: Array[StringName] = [SOLAR_TECH]
	assert_true(_session.start(roster).is_accepted, "session starts")
	assert_true(_session.present().is_accepted, "customer is presented")


func test_a_started_session_presents_the_customer_it_was_given() -> void:
	var roster: Array[StringName] = [SOLAR_TECH]
	_session.start(roster)
	var result: CommandResult = _session.present()

	var presented: Array[StringName] = []
	for event: DomainEvent in result.events:
		if event is CustomerPresented:
			presented.append((event as CustomerPresented).customer_id)
	assert_eq(presented, [SOLAR_TECH] as Array[StringName])


func test_selecting_then_removing_leaves_the_dish_empty() -> void:
	_open()
	assert_true(_session.select(&"ingredient.mushrooms").is_accepted)
	assert_eq(_session.state().current_dish.size(), 1)
	assert_true(_session.remove(&"ingredient.mushrooms").is_accepted)
	assert_eq(_session.state().current_dish.size(), 0)


func test_a_fourth_ingredient_is_rejected_with_a_reason() -> void:
	# Rejection carries a reason rather than being silently dropped, because the
	# screen shows it. ADR 0004 section 10.
	_open()
	_session.select(&"ingredient.mushrooms")
	_session.select(&"ingredient.chickpeas")
	_session.select(&"ingredient.coconut_milk")
	var fourth: CommandResult = _session.select(&"ingredient.kimchi")

	assert_false(fourth.is_accepted)
	assert_true(fourth.has_rejection_reason)
	assert_eq(fourth.rejection_reason, CommandResult.Reason.DISH_FULL)
	assert_eq(_session.state().current_dish.size(), Flavor.MAX_DISH_SIZE, "dish is unchanged")


func test_submitting_an_empty_dish_is_rejected() -> void:
	_open()
	var result: CommandResult = _session.submit()
	assert_false(result.is_accepted)
	assert_eq(result.rejection_reason, CommandResult.Reason.EMPTY_DISH)


func test_submitting_evaluates_and_the_evaluation_arrives_in_the_event() -> void:
	# The screen must never recompute a score. This pins that it does not have
	# to: the number is already in the event by the time any adapter sees it.
	_open()
	_session.select(&"ingredient.chickpeas")
	_session.select(&"ingredient.coconut_milk")
	_session.select(&"ingredient.mushrooms")
	var result: CommandResult = _session.submit()

	assert_true(result.is_accepted)
	var found: Evaluation = null
	for event: DomainEvent in result.events:
		if event is DishEvaluated:
			found = (event as DishEvaluated).evaluation
	assert_not_null(found, "submitting emits DishEvaluated")
	# solar_tech's best dish, per the run 01 headroom table.
	assert_eq(found.score, 100)
	assert_eq(found.band, Evaluation.RatingBand.DELIGHTED)
