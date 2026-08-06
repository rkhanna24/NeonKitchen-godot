## The one entry point evaluation callers use, per ADR 0004 section 9.
##
## Orchestrates three independent concerns — composition (`SumAndClamp
## Composer`), flavour scoring (`FlavourScorer`), and constraint checking
## (`ConstraintChecker`) — into one `Evaluation`. Callers depend on this file
## only; the other rule files exist so each concern can change without
## touching the others.
##
## Touches no repository, clock, or randomness.
class_name Evaluator
extends RefCounted


## `ingredients` is the submitted dish (1-3 distinct, per ADR 0004 section 1);
## `customer` is who it is served to. Dish-size and content validity are a
## command-level concern (section 10), not this function's — it is total over
## well-formed input.
static func evaluate(
	ingredients: Array[IngredientDefinition], customer: CustomerDefinition
) -> Evaluation:
	var profile: FlavorProfile = SumAndClampComposer.compose(ingredients)
	var flavour: FlavourScorer.Result = FlavourScorer.score(profile, customer)
	var constraints: ConstraintChecker.Result = ConstraintChecker.check(ingredients, customer)

	# The flavour score is always computed and reported — per_dimension and
	# the feedback fields below come from `flavour` regardless of constraint
	# outcome — but a violation caps the final score at 39, per section 5.
	var final_score: int = flavour.score
	if not constraints.satisfied:
		final_score = mini(final_score, 39)

	return Evaluation.new(
		final_score,
		Evaluation.band_for_score(final_score),
		constraints.satisfied,
		constraints.violated_constraints,
		flavour.has_strongest_match,
		flavour.strongest_match,
		flavour.has_largest_miss,
		flavour.largest_miss,
		flavour.per_dimension
	)
