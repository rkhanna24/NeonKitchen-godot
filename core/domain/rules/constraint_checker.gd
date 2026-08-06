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

	## A value copy of each violated constraint — its `kind`, `subject`, and
	## `explanation_key` — never a reference to the authored
	## `CustomerConstraint`. See `Evaluation.ViolatedConstraint`.
	var violated_constraints: Array[Evaluation.ViolatedConstraint]

	func _init(
		p_satisfied: bool, p_violated_constraints: Array[Evaluation.ViolatedConstraint]
	) -> void:
		satisfied = p_satisfied
		violated_constraints = p_violated_constraints


## Checks `ingredients` against every constraint `customer` carries (0-2, per
## section 5). `satisfied` is true only when none is violated.
static func check(ingredients: Array[IngredientDefinition], customer: CustomerDefinition) -> Result:
	var violated: Array[Evaluation.ViolatedConstraint] = []
	for constraint: CustomerConstraint in customer.constraints:
		if _is_violated(constraint, ingredients):
			violated.append(
				Evaluation.ViolatedConstraint.new(
					constraint.kind, constraint.subject, constraint.explanation_key
				)
			)
	return Result.new(violated.is_empty(), violated)


static func _is_violated(
	constraint: CustomerConstraint, ingredients: Array[IngredientDefinition]
) -> bool:
	# Fail closed. An out-of-range `kind` cannot be interpreted, and both
	# `is_forbidding()` and `is_ingredient_kind()` answer false for one, which
	# would read as REQUIRE_TAG and silently invert a FORBID_TAG boundary — a
	# soy-forbidding customer accepting a soy dish. Content validation rejects
	# such a kind at load, but this function must not depend on that having run.
	if not constraint.is_valid_kind():
		return true

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
