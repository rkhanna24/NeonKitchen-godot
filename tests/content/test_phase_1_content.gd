## The shipped Phase 1 content under `content/base/`.
##
## Until this file existed, **nothing in the repository referenced
## `content/base/` at all** — no test loaded it and the gate never validated it.
## Renaming an `@export` would have silently zeroed a dimension in shipped
## content with every check still green, which is the same defect class already
## fixed once for `content/test_fixtures/`.
##
## It also pins values that the `.tres` files **cannot** express. Godot's
## serializer omits any value equal to its class default, even when set
## explicitly in code — verified. So `scrap_trader`'s `comfort_target` of 3 and
## its constraint's `FORBID_TAG` kind are absent from the files and come from
## `CustomerDefinition` and `CustomerConstraint` respectively. Changing either
## default would silently rewrite what the shipped content means; these
## assertions are the only thing that would notice.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

var repository: TresContentRepository = null


func before_each() -> void:
	repository = TresContentRepository.new()
	var problems: PackedStringArray = repository.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(problems.size(), 0, "shipped content must validate: %s" % "\n".join(problems))
	assert_true(repository.is_loaded(), "shipped content must load")


func _ingredient(id: StringName) -> IngredientDefinition:
	var found: IngredientDefinition = repository.find_ingredient(id)
	assert_not_null(found, "missing ingredient %s" % id)
	return found


func _customer(id: StringName) -> CustomerDefinition:
	var found: CustomerDefinition = repository.find_customer(id)
	assert_not_null(found, "missing customer %s" % id)
	return found


func test_the_set_is_the_approved_size() -> void:
	assert_eq(repository.all_ingredients().size(), 3)
	assert_eq(repository.all_customers().size(), 2)


func test_neon_noodles_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.neon_noodles")
	assert_eq(i.flavour_values(), [1, 0, 0, 3, 0] as Array[int])
	assert_true(i.has_tag(&"gluten"))
	assert_true(i.has_tag(&"vegan"))


func test_umami_broth_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.umami_broth")
	assert_eq(i.flavour_values(), [2, 0, 0, 2, 0] as Array[int])
	# This tag is what scrap_trader's boundary matches on.
	assert_true(i.has_tag(&"soy"), "the forbidden tag must exist or the constraint is vacuous")


func test_ember_chili_paste_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.ember_chili_paste")
	assert_eq(i.flavour_values(), [0, 3, 1, 0, 2] as Array[int])
	assert_true(i.has_tag(&"fermented"))


func test_only_two_ingredients_contribute_comfort() -> void:
	# The design depends on this: Comfort 5 is unreachable without combining
	# both, which is what exercises ADR 0004 §1's forced-combination mechanic.
	var contributors: int = 0
	for i: IngredientDefinition in repository.all_ingredients():
		if i.value_of(Flavor.Dimension.COMFORT) > 0:
			contributors += 1
	assert_eq(contributors, 2)


func test_solar_tech_targets_and_weights() -> void:
	var c: CustomerDefinition = _customer(&"customer.solar_tech")
	assert_eq(c.targets(), [3, 0, 0, 5, 0] as Array[int])
	assert_eq(c.weights(), [2, 0, 0, 3, 0] as Array[int])
	assert_eq(c.reaction_key, &"customer.solar_tech.reaction", "must be a prefix, per §8a")
	assert_eq(c.constraints.size(), 0, "the first encounter teaches preferences, no boundary")


func test_scrap_trader_targets_and_weights() -> void:
	var c: CustomerDefinition = _customer(&"customer.scrap_trader")
	# comfort_target is absent from the .tres and comes from the class default.
	# If that default changes, this fails — which is the point.
	assert_eq(c.targets(), [0, 1, 0, 3, 0] as Array[int])
	assert_eq(c.weights(), [0, 1, 0, 2, 0] as Array[int])
	assert_eq(c.reaction_key, &"customer.scrap_trader.reaction")


func test_scrap_traders_boundary_is_a_forbid_not_a_require() -> void:
	# `kind` is absent from scrap_trader.tres because FORBID_TAG is the class
	# default and Godot omits default-valued fields. Flipping that default to
	# REQUIRE_TAG would invert the soy boundary — every soy dish passing and
	# every safe dish failing — with no diff to any content file. This is the
	# only thing that would catch it.
	var c: CustomerDefinition = _customer(&"customer.scrap_trader")
	assert_eq(c.constraints.size(), 1)
	var rule: CustomerConstraint = c.constraints[0]
	assert_eq(rule.kind, CustomerConstraint.Kind.FORBID_TAG)
	assert_eq(rule.subject, &"soy")
	assert_true(rule.is_forbidding())
	assert_false(rule.is_ingredient_kind())
	assert_eq(rule.explanation_key, &"customer.scrap_trader.constraint.soy")


func _dishes() -> Array:
	var ingredients: Array[IngredientDefinition] = repository.all_ingredients()
	var out: Array = []
	for mask: int in range(1, 1 << ingredients.size()):
		var dish: Array[IngredientDefinition] = []
		for index: int in range(ingredients.size()):
			if mask & (1 << index) != 0:
				dish.append(ingredients[index])
		out.append(dish)
	return out


func test_every_rating_band_is_reachable_across_the_set() -> void:
	# ADR 0004 §11 requires this of the content, and #6's golden cases depend
	# on it. Reachability is a property of the content plus the evaluator, so
	# nothing short of running both can assert it.
	var seen: Dictionary[int, bool] = {}
	for customer: CustomerDefinition in repository.all_customers():
		for dish: Array in _dishes():
			var typed: Array[IngredientDefinition] = []
			for i: IngredientDefinition in dish:
				typed.append(i)
			seen[int(Evaluator.evaluate(typed, customer).band)] = true
	for band: Evaluation.RatingBand in [
		Evaluation.RatingBand.DELIGHTED,
		Evaluation.RatingBand.SATISFIED,
		Evaluation.RatingBand.MIXED,
		Evaluation.RatingBand.DISSATISFIED,
	]:
		assert_true(seen.has(int(band)), "band %d unreachable across the whole set" % int(band))


func test_the_soy_boundary_actually_caps_a_good_dish() -> void:
	# The tradeoff the content is built around: the broth is the best Comfort
	# partner and the only soy carrier, so obeying the boundary costs the
	# player their strongest ingredient.
	var customer: CustomerDefinition = _customer(&"customer.scrap_trader")
	var dish: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.neon_noodles"), _ingredient(&"ingredient.umami_broth")
	]
	var capped: Evaluation = Evaluator.evaluate(dish, customer)
	assert_false(capped.constraint_satisfied, "soy must be detected")
	assert_eq(capped.score, 39, "a violation caps at 39")
	assert_eq(capped.violated_constraint_ids, [&"soy"] as Array[StringName])

	var safe: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.neon_noodles"), _ingredient(&"ingredient.ember_chili_paste")
	]
	var allowed: Evaluation = Evaluator.evaluate(safe, customer)
	assert_true(allowed.constraint_satisfied)
	assert_eq(allowed.score, 80, "the soy-free alternative is the intended solution")
