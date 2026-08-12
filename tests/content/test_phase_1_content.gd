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

## Per ADR 0004 §1: a dish is 1 to 3 distinct ingredients.
const MAX_DISH_INGREDIENTS: int = 3

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
	# Twelve is the roster GDD section 2.3 names and section 12 requires the first
	# playtest to run on. Customers reach eight in #24's second run.
	assert_eq(repository.all_ingredients().size(), 12)
	assert_eq(repository.all_customers().size(), 8)


func test_thick_wheat_noodles_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.thick_wheat_noodles")
	assert_eq(i.flavour_values(), [1, 0, 0, 3, 0] as Array[int])
	assert_true(i.has_tag(&"gluten"))
	assert_true(i.has_tag(&"vegan"))


func test_soy_broth_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.soy_broth")
	assert_eq(i.flavour_values(), [2, 0, 0, 2, 0] as Array[int])
	# This tag is what scrap_trader's boundary matches on.
	assert_true(i.has_tag(&"soy"), "the forbidden tag must exist or the constraint is vacuous")


func test_citrus_chili_paste_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.citrus_chili_paste")
	assert_eq(i.flavour_values(), [0, 3, 1, 0, 2] as Array[int])
	assert_true(i.has_tag(&"fermented"))


func test_rooftop_lettuce_values_and_tags() -> void:
	var i: IngredientDefinition = _ingredient(&"ingredient.rooftop_lettuce")
	# The pantry's only Fresh source above 1, and it must stay Comfort 0: the
	# medic's "nothing heavy" target is what makes it the answer to that
	# request rather than a second comfort ingredient.
	assert_eq(i.flavour_values(), [0, 0, 3, 0, 0] as Array[int])
	assert_true(i.has_tag(&"raw"))
	assert_true(i.has_tag(&"vegan"))


func test_every_dimension_has_a_full_strength_source() -> void:
	# Replaces an earlier assertion that exactly two ingredients contributed
	# Comfort. That held because the pantry was small, not because the design
	# required it, and six ingredients now carry Comfort.
	#
	# A first replacement asserted no ingredient exceeds 3 — which `ContentValidator`
	# already rejects at load, so no content reaching this test could ever violate
	# it. It could not fail, which makes it not a test. Verified by injecting
	# `savory = 4`: the repository refused to load and the assertion never ran.
	#
	# This is the property nothing else enforces. Every dimension needs at least
	# one ingredient at the per-ingredient cap, or a customer targeting 4 or 5 on
	# that dimension cannot be satisfied by any dish — and §1's forced-combination
	# mechanic assumes the ceiling is reachable at all.
	var strongest: Array[int] = [0, 0, 0, 0, 0]
	for i: IngredientDefinition in repository.all_ingredients():
		var values: Array[int] = i.flavour_values()
		for d: int in range(values.size()):
			strongest[d] = maxi(strongest[d], values[d])
	for d: int in range(strongest.size()):
		assert_eq(strongest[d], 3, "no ingredient reaches 3 on %s" % Flavor.dimension_name(d))


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


func test_late_shift_medic_targets_and_weights() -> void:
	var c: CustomerDefinition = _customer(&"customer.late_shift_medic")
	# Fresh 4 is above the per-ingredient cap of 3, so it cannot be hit by any
	# single ingredient — that is what forces a combination. Comfort target 1
	# and Spicy target 0, both with non-zero weight, are "nothing heavy" and
	# "nothing fiery" as active dislikes; dropping either weight to 0 would
	# silently turn it into indifference, per §2.
	#
	# Spicy weight 2 once made this customer unable to reach DELIGHTED: the only
	# route to Fresh 4 was rooftop_lettuce(3) + citrus_chili_paste(1), and the
	# chili carries Spicy 3, so the perfect Fresh score cost exactly what the
	# Spicy weight punished. Their ceiling was 84.
	#
	# **That is no longer true.** citrus_herbs (Fresh 1, Spicy 0) gives a
	# spice-free route to Fresh 4, and the medic now reaches DELIGHTED. ADR 0004
	# §11 anticipated this for reaction lines — "the pantry may change around
	# them" — and the same applies to a claim like the one this comment used to
	# make. The targets below are unchanged; only what they imply has moved.
	assert_eq(c.targets(), [0, 0, 4, 1, 0] as Array[int])
	assert_eq(c.weights(), [0, 2, 3, 2, 0] as Array[int])
	assert_eq(c.reaction_key, &"customer.late_shift_medic.reaction", "must be a prefix, per §8a")
	assert_eq(c.constraints.size(), 0, "a flavour preference, not a boundary")


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


## Every legal dish: 1 to `MAX_DISH_INGREDIENTS` distinct ingredients, per
## ADR 0004 §1.
##
## The size cap is load-bearing, not decorative. While the pantry held three
## ingredients the full power set was coincidentally all legal, so an uncapped
## enumeration looked correct. The fourth ingredient makes 4-ingredient subsets
## reachable, and those are not dishes the game can produce — enumerating them
## would assert reachability against input the domain never receives.
func _dishes() -> Array:
	var ingredients: Array[IngredientDefinition] = repository.all_ingredients()
	var out: Array = []
	for mask: int in range(1, 1 << ingredients.size()):
		var dish: Array[IngredientDefinition] = []
		for index: int in range(ingredients.size()):
			if mask & (1 << index) != 0:
				dish.append(ingredients[index])
		if dish.size() > MAX_DISH_INGREDIENTS:
			continue
		out.append(dish)
	return out


func test_dish_enumeration_respects_the_size_cap() -> void:
	# Guards the cap above rather than trusting it. With twelve ingredients an
	# uncapped power set yields 4095 subsets against 298 legal dishes, so an
	# unenforced cap is now off by more than an order of magnitude rather than by
	# the single subset it was when the pantry held four.
	var dishes: Array = _dishes()
	assert_eq(dishes.size(), 298, "1-3 ingredient subsets of a 12-ingredient pantry")
	for dish: Array in dishes:
		assert_between(dish.size(), 1, MAX_DISH_INGREDIENTS, "illegal dish size enumerated")


func test_every_rating_band_is_reachable_across_the_set() -> void:
	# Across the SET, deliberately not per customer. ADR 0004 §11 records that
	# solvability is a session-level property: a customer may be impossible to
	# fully satisfy with the current pantry, and a reaction line authored for a
	# band they cannot reach is correct content, since the pantry may change
	# around them. Reachability needs both the content and the evaluator, so
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
		_ingredient(&"ingredient.thick_wheat_noodles"), _ingredient(&"ingredient.soy_broth")
	]
	var capped: Evaluation = Evaluator.evaluate(dish, customer)
	assert_false(capped.constraint_satisfied, "soy must be detected")
	assert_eq(capped.score, 39, "a violation caps at 39")
	assert_eq(capped.violated_constraints.size(), 1)
	assert_eq(capped.violated_constraints[0].subject, &"soy")

	# The boundary must be survivable, not merely survivable-at-a-cost. This dish
	# is soy-free and scores 100, which is the property worth pinning: respecting
	# the constraint does not put the top band out of reach.
	#
	# An earlier version asserted noodles + citrus_chili_paste at 80 and called it
	# "the intended solution". The 80 was correct arithmetic for a dish that is not
	# the best one -- a true number with a false claim attached, which is the
	# defect this file exists to catch, sitting inside it. Eight dishes tie at 100.
	var safe: Array[IngredientDefinition] = [
		_ingredient(&"ingredient.thick_wheat_noodles"), _ingredient(&"ingredient.kimchi")
	]
	var allowed: Evaluation = Evaluator.evaluate(safe, customer)
	assert_true(allowed.constraint_satisfied, "kimchi and noodles carry no soy")
	assert_eq(allowed.score, 100, "a soy-free dish still reaches the top band")
