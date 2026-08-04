## Constraint checking per ADR 0004 section 5.
##
## Evaluates a dish's ingredients against a customer's hard boundaries —
## ingredient identity and tags only, never flavour values. Kept separate from
## `FlavourScorer` per the section 9 correction: a change to constraint rules
## must not touch flavour scoring, following the same rationale that keeps
## composition separate from scoring.
##
## Touches no repository, clock, or randomness.
class_name ConstraintChecker
extends RefCounted


## The constraint-only result of checking one dish against one customer.
class Result:
	extends RefCounted

	var satisfied: bool

	## The `subject` of each violated constraint. `CustomerConstraint` carries
	## no separate stable id of its own, so `subject` — an ingredient
	## `content_id` or a tag, both already namespaced content identity — is
	## what identifies which boundary was crossed.
	var violated_constraint_ids: Array[StringName]

	func _init(p_satisfied: bool, p_violated_constraint_ids: Array[StringName]) -> void:
		satisfied = p_satisfied
		violated_constraint_ids = p_violated_constraint_ids


## Checks `ingredients` against every constraint `customer` carries (0-2, per
## section 5). `satisfied` is true only when none is violated.
static func check(ingredients: Array[IngredientDefinition], customer: CustomerDefinition) -> Result:
	var violated: Array[StringName] = []
	for constraint: CustomerConstraint in customer.constraints:
		if _is_violated(constraint, ingredients):
			violated.append(constraint.subject)
	return Result.new(violated.is_empty(), violated)


static func _is_violated(
	constraint: CustomerConstraint, ingredients: Array[IngredientDefinition]
) -> bool:
	var present: bool = _dish_carries(constraint, ingredients)
	# FORBID_* is violated when the subject is present; REQUIRE_* is violated
	# when it is absent. See `CustomerConstraint.is_forbidding()`.
	if constraint.is_forbidding():
		return present
	return not present


## Whether any ingredient in the dish carries the constraint's subject — its
## `content_id` for the INGREDIENT kinds, or one of its tags for the TAG kinds.
static func _dish_carries(
	constraint: CustomerConstraint, ingredients: Array[IngredientDefinition]
) -> bool:
	for ingredient: IngredientDefinition in ingredients:
		if constraint.is_ingredient_kind():
			if ingredient.content_id == constraint.subject:
				return true
		elif ingredient.has_tag(constraint.subject):
			return true
	return false
