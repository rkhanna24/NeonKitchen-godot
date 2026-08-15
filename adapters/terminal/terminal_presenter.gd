## Event and rejection text for the terminal adapter (#5).
##
## Formats accepted facts already computed by `CommandHandler` /
## `Evaluator.evaluate()`. This file recomputes nothing: every number it
## prints (`score`, `band`, and which dimension is the strongest match or
## largest miss) is read straight off the `Evaluation` it is handed.
## `IngredientSelected` and `IngredientRemoved` carry a `dish_profile`, but
## this file does not print it -- only the ingredient name -- so no claim is
## made about it here.
##
## The one piece of logic here that is more than direct formatting is
## `_is_violated`, which joins a customer's authored `CustomerConstraint`
## list against `Evaluation.violated_constraints` by `(kind, subject)` so a
## constraint can be reported as met or violated by name. ADR 0004 section 5's
## duplicate-rejection rule is what makes that pair unique per customer, so
## the join never has to pick among more than one match.
##
## Customer- and content-facing strings go through `TranslationServer`, per
## ADR 0002 -- names, requests, reactions, and constraint explanations are all
## authored localisation keys. Everything else here is the adapter's own English
## prose: no localisation keys exist for rejection reasons or for this
## adapter's own labels (band names, dimension names, constraint-kind
## labels), and none should be added for them -- putting UI strings into
## `content/base/localization/` would make this a content change, which it
## is not.
class_name TerminalPresenter
extends RefCounted


static func welcome_lines() -> Array[String]:
	return (
		[
			"Neon Kitchen -- terminal prototype.",
			"Commands: start, present, list, select <id>, remove <id>, submit, quit.",
		]
		as Array[String]
	)


## The pantry and the dish under construction, for the adapter-only `list`
## query. Answers "what can I type?", which nothing else did -- ids had to be
## remembered or read out of `content/base/`.
##
## Descriptions, never flavour values. GDD section 2.4 requires ingredient
## descriptions to stay available through a session, and section 2.2 shows the
## player reasoning from them ("Noodles contribute strongly to Comfort").
## Printing the five integers instead would let a player compute the score
## rather than learn the pantry, which is the puzzle rather than a convenience.
static func present_pantry(
	ingredients: Array[IngredientDefinition], current_dish: Array[StringName]
) -> Array[String]:
	var lines: Array[String] = ["Pantry:"]
	var names_by_id: Dictionary[StringName, String] = {}

	# Grouped in `IngredientDefinition.GROUPS` order, not the order the
	# repository happened to return. Headings only: nothing here says or implies
	# that a dish wants one from each, because measuring that showed it is worth
	# almost nothing on average and actively costs the player against six of the
	# eight shipped customers (DEC-029). The groups make twelve ingredients
	# scannable; they are not a recipe.
	var by_group: Dictionary[StringName, Array] = {}
	for ingredient: IngredientDefinition in ingredients:
		if not by_group.has(ingredient.group):
			by_group[ingredient.group] = []
		by_group[ingredient.group].append(ingredient)

	# Known groups first, in contract order; then anything left over. The
	# validator rejects an unknown or missing group at load, so the tail is
	# unreachable through the game — but this function is static and takes any
	# array, and iterating only over `GROUPS` would drop such an ingredient from
	# the listing without a word. A pantry that silently omits what you own is a
	# worse failure than an ugly one, so the leftovers print under their raw
	# group value rather than disappearing.
	var ordered: Array[StringName] = []
	for group: StringName in IngredientDefinition.GROUPS:
		if by_group.has(group):
			ordered.append(group)
	for group: StringName in by_group:
		if not ordered.has(group):
			ordered.append(group)

	for group: StringName in ordered:
		lines.append("  %s" % _translate(StringName("pantry.group.%s" % group)))
		for ingredient: IngredientDefinition in by_group[group]:
			var name: String = _translate(ingredient.name_key)
			names_by_id[ingredient.content_id] = name
			lines.append("    %s -- %s" % [ingredient.content_id, name])
			lines.append("        %s" % _translate(ingredient.description_key))

	if current_dish.is_empty():
		lines.append("Dish: empty")
		return lines

	# Display names, matching every other line this file prints. The id is
	# what you type; the name is what you read.
	var names: Array[String] = []
	for ingredient_id: StringName in current_dish:
		names.append(names_by_id.get(ingredient_id, String(ingredient_id)))
	lines.append("Dish: %s" % ", ".join(names))
	return lines


static func present_session_started(event: SessionStarted) -> Array[String]:
	return ["Session started with %d customer(s)." % event.customer_count] as Array[String]


## The request and, per GDD section 2.3 ("constraints are visible before the
## player chooses"), every authored constraint in the customer's own words.
## The same `explanation_key` is reused, unmodified, by `_constraint_line`
## once a dish is served -- this file never writes a second copy of it.
static func present_customer_presented(
	event: CustomerPresented, content: ContentRepository
) -> Array[String]:
	var customer: CustomerDefinition = content.find_customer(event.customer_id)
	if customer == null:
		return ["-- unknown customer --"] as Array[String]

	var lines: Array[String] = []
	lines.append("-- %s --" % _translate(customer.name_key))
	lines.append(_translate(customer.request_key))
	for constraint: CustomerConstraint in customer.constraints:
		lines.append("Constraint: %s" % _translate(constraint.explanation_key))
	return lines


static func present_ingredient_selected(
	event: IngredientSelected, content: ContentRepository
) -> Array[String]:
	return ["Added %s." % _ingredient_name(event.ingredient_id, content)] as Array[String]


static func present_ingredient_removed(
	event: IngredientRemoved, content: ContentRepository
) -> Array[String]:
	return ["Removed %s." % _ingredient_name(event.ingredient_id, content)] as Array[String]


static func present_dish_submitted(
	event: DishSubmitted, content: ContentRepository
) -> Array[String]:
	var names: Array[String] = []
	for ingredient_id: StringName in event.ingredient_ids:
		names.append(_ingredient_name(ingredient_id, content))
	return ["Serving: %s" % ", ".join(names)] as Array[String]


## `customer` is the customer this dish was just served to -- looked up by
## `TerminalSession` from `state.current_customer_id()` before the next
## `PresentCustomer` can clear it (ADR 0004 section 7a). It is used only to
## walk the authored constraint list for the met/violated join; nothing here
## re-derives whether a boundary was crossed, which is decided entirely by
## `evaluation.violated_constraints`.
static func present_dish_evaluated(
	event: DishEvaluated, customer: CustomerDefinition
) -> Array[String]:
	var evaluation: Evaluation = event.evaluation
	var lines: Array[String] = []
	lines.append("Result: %s -- %d" % [_band_label(evaluation.band), evaluation.score])

	if evaluation.has_strongest_match:
		lines.append("Strongest match: %s" % _dimension_label(evaluation.strongest_match))
	else:
		lines.append("Strongest match: none")

	# Reported absent when every weighted penalty is zero, per section 6 --
	# not computed here, only read off `has_largest_miss`.
	if evaluation.has_largest_miss:
		lines.append("Largest miss: %s" % _dimension_label(evaluation.largest_miss))
	else:
		lines.append("Largest miss: none -- every weighted dimension matched")

	if customer != null:
		for constraint: CustomerConstraint in customer.constraints:
			lines.append(_constraint_line(constraint, evaluation.violated_constraints))

	return lines


static func present_customer_reacted(event: CustomerReacted) -> Array[String]:
	return [_translate(event.reaction_key)] as Array[String]


static func present_session_ended(event: SessionEnded, content: ContentRepository) -> Array[String]:
	var lines: Array[String] = ["== Session Summary =="]
	var position: int = 1
	for result: EncounterResult in event.results:
		lines.append("%d. %s" % [position, _summary_line(result, content)])
		position += 1
	return lines


static func rejection_text(reason: CommandResult.Reason) -> String:
	return EncounterText.rejection_text(reason)


static func _summary_line(result: EncounterResult, content: ContentRepository) -> String:
	return EncounterText.summary_line(result, content)


static func _ingredient_name(ingredient_id: StringName, content: ContentRepository) -> String:
	return EncounterText.ingredient_name(ingredient_id, content)


static func _constraint_line(
	constraint: CustomerConstraint, violated: Array[Evaluation.ViolatedConstraint]
) -> String:
	var label: String = _constraint_kind_label(constraint.kind)
	if _is_violated(constraint, violated):
		return (
			"Constraint (%s %s): VIOLATED -- %s"
			% [label, constraint.subject, _translate(constraint.explanation_key)]
		)
	return "Constraint (%s %s): met" % [label, constraint.subject]


## `(kind, subject)` is the identity ADR 0004 section 5 guarantees is unique
## within a customer -- see this file's header. This never asks whether a
## boundary *should* have been crossed; it only reads whether
## `Evaluator.evaluate()` already said it was.
static func _is_violated(
	constraint: CustomerConstraint, violated: Array[Evaluation.ViolatedConstraint]
) -> bool:
	for entry: Evaluation.ViolatedConstraint in violated:
		if entry.kind == constraint.kind and entry.subject == constraint.subject:
			return true
	return false


static func _constraint_kind_label(kind: CustomerConstraint.Kind) -> String:
	match kind:
		CustomerConstraint.Kind.REQUIRE_INGREDIENT:
			return "require ingredient"
		CustomerConstraint.Kind.FORBID_INGREDIENT:
			return "forbid ingredient"
		CustomerConstraint.Kind.REQUIRE_TAG:
			return "require tag"
		CustomerConstraint.Kind.FORBID_TAG:
			return "forbid tag"
		_:
			return "unknown constraint"


static func _band_label(band: Evaluation.RatingBand) -> String:
	return EncounterText.band_label(band)


static func _dimension_label(dimension: Flavor.Dimension) -> String:
	return EncounterText.dimension_label(dimension)


## `tr()` is an `Object` instance method (confirmed: calling it from a
## `static func` in this file is a parse error on 4.7.1) and every function
## here is `static`, so localisation keys are resolved through
## `TranslationServer.translate()` instead -- the same call
## `tests/unit/test_localization.gd` already exercises against the project's
## registered translation.
static func _translate(key: StringName) -> String:
	return String(TranslationServer.translate(key))
