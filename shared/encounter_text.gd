## Wording that every interface needs and none of them owns.
##
## Created for #34 (DEC-031). `adapters/terminal` and `adapters/godot_ui` had
## independently grown their own copies of three things -- band labels, rejection
## wording, and the summary line -- within a day of the second adapter existing.
## They had already diverged in two ways that no test could see, because each
## adapter only ever compared against itself:
##
## - the terminal labels an unrecognised band `"Unknown"`; the UI copy fell
##   through to `"Dissatisfied"`, reporting a real band for an unreadable one;
## - the terminal capitalises a dimension (`"Savory"`); the UI copy printed the
##   raw `StringName` (`"savory"`).
##
## Neither was a typo. Both are what happens when the same sentence is written
## twice from memory, which is the argument for this file rather than for being
## more careful next time.
##
## `shared/` is not a new idea: ADR 0002 §6 already lists it among the deferred
## folders, "created when their first real file exists". This is that file.
##
## **Presentation, not domain.** Nothing here decides an outcome; it only names
## one that the domain already decided. It takes a `ContentRepository` where it
## needs a display name, and never a `SessionState` -- reading session state
## would make it a second opinion about what happened.
class_name EncounterText
extends RefCounted


## `tr()` is an `Object` instance method and every function here is `static`, so
## localisation resolves through `TranslationServer` -- the same constraint, and
## the same workaround, as `TerminalPresenter`.
static func translate(key: StringName) -> String:
	return String(TranslationServer.translate(key))


static func band_label(band: Evaluation.RatingBand) -> String:
	match band:
		Evaluation.RatingBand.DELIGHTED:
			return "Delighted"
		Evaluation.RatingBand.SATISFIED:
			return "Satisfied"
		Evaluation.RatingBand.MIXED:
			return "Mixed"
		Evaluation.RatingBand.DISSATISFIED:
			return "Dissatisfied"
		_:
			return "Unknown"


## Capitalised for display. `Flavor.dimension_name` returns the contract's own
## lowercase identifier, which is correct as data and wrong on a panel.
static func dimension_label(dimension: Flavor.Dimension) -> String:
	return String(Flavor.dimension_name(dimension)).capitalize()


static func ingredient_name(ingredient_id: StringName, content: ContentRepository) -> String:
	var ingredient: IngredientDefinition = content.find_ingredient(ingredient_id)
	if ingredient == null:
		return String(ingredient_id)
	return translate(ingredient.name_key)


static func rejection_text(reason: CommandResult.Reason) -> String:
	match reason:
		CommandResult.Reason.UNKNOWN_CUSTOMER:
			return "Unknown customer id."
		CommandResult.Reason.EMPTY_ROSTER:
			return "The roster is empty; there is nothing to start."
		CommandResult.Reason.UNKNOWN_INGREDIENT:
			return "Unknown ingredient id."
		CommandResult.Reason.DUPLICATE_INGREDIENT:
			return "That ingredient is already in the dish."
		CommandResult.Reason.DISH_FULL:
			return "The dish already holds three ingredients."
		CommandResult.Reason.NOT_SELECTED:
			return "That ingredient is not in the dish."
		CommandResult.Reason.EMPTY_DISH:
			return "Add at least one ingredient before serving."
		CommandResult.Reason.INVALID_PHASE:
			return "That command is not valid right now."
		_:
			return "Rejected."


## One line of the end-of-session summary. Reads only the `EncounterResult` it is
## given: ADR 0004 §8 records the dish and outcome by value precisely so a
## summary needs no re-evaluation, and re-deriving anything here would be a
## second scoring path.
static func summary_line(result: EncounterResult, content: ContentRepository) -> String:
	var customer: CustomerDefinition = content.find_customer(result.customer_id)
	var customer_name: String = (
		translate(customer.name_key) if customer != null else String(result.customer_id)
	)
	var names: Array[String] = []
	for ingredient_id: StringName in result.ingredient_ids:
		names.append(ingredient_name(ingredient_id, content))
	var constraint_word: String = "met" if result.constraint_satisfied else "violated"
	return (
		"%s -- %s %d -- %s -- constraint %s"
		% [
			customer_name,
			band_label(result.band),
			result.score,
			", ".join(names),
			constraint_word,
		]
	)
