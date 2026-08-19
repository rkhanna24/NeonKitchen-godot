## The all-combination audit named in GDD section 3's Week 3 milestone.
##
## Enumerates every legal dish against every shipped customer using the real
## `Evaluator` and writes `docs/design/Recipe Space Audit.md`. Nothing here
## reimplements the scoring formula: composition, scoring, and constraints all
## come from `Evaluator.evaluate()`, so a change to the rules changes this
## report rather than silently disagreeing with it.
##
## Run it:
##
##   godot --headless --path . -s bootstrap/audit_recipe_space.gd
##   godot --headless --path . -s bootstrap/audit_recipe_space.gd -- --check
##
## `--check` regenerates the report in memory and compares it against the
## committed file, exiting non-zero if they differ. `scripts/check.sh` runs that
## mode, which is the whole reason this file exists: every previous enumeration
## of this space was a probe written to /tmp and deleted, so its findings could
## not be re-derived and could not notice when content moved underneath them.
##
## The gate fails on **drift**, never on the verdict. A `REVISE` verdict is a
## design finding for the human to act on, not a broken build — wiring it to the
## gate would let a known balance problem block unrelated work.
##
## The report carries no timestamp and no run metadata on purpose. Byte
## stability is what makes regenerate-and-diff a usable check; a date line would
## make every run differ and the check would be discarded within a week.
extends SceneTree

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"
const REPORT_PATH: String = "res://docs/design/Recipe Space Audit.md"

## Printed on a successful --check comparison and required by scripts/check.sh.
## Changing this string breaks that step; they are a pair.
const CHECK_OK_MARKER: String = "audit: report matches the committed copy"

## Compact band labels for the appendix grid, indexed by `Evaluation.RatingBand`.
const BAND_LABELS: Array[String] = ["DEL", "SAT", "MIX", "DIS"]

## Full names, same order, for the prose sections.
const BAND_NAMES: Array[String] = ["DELIGHTED", "SATISFIED", "MIXED", "DISSATISFIED"]

## A dish "satisfies" a customer at DELIGHTED or SATISFIED. Enum values ascend
## from DELIGHTED, so the test is an upper bound on the ordinal.
const SATISFYING_BAND_LIMIT: int = 1

## GDD section 2.4: "at least three satisfying combinations, including at least
## two that do not depend on the same central ingredient."
const MIN_SATISFYING_DISHES: int = 3
const MIN_DISTINCT_CENTRALS: int = 2


func _init() -> void:
	var check_only: bool = OS.get_cmdline_user_args().has("--check")

	var content := TresContentRepository.new()
	var problems: PackedStringArray = content.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	if not problems.is_empty():
		for problem: String in problems:
			printerr("content error: %s" % problem)
		quit(1)
		return

	var report: String = _build_report(
		_sorted_ingredients(content.all_ingredients()), _sorted_customers(content.all_customers())
	)

	if check_only:
		quit(_compare_against_committed(report))
		return
	quit(_write_report(report))


# ------------------------------------------------------------------ output ----


## 0 if the committed report matches, 1 otherwise. Reports the first differing
## line rather than a bare "differs", so the cause is visible without a manual
## diff of a 300-line file.
static func _compare_against_committed(report: String) -> int:
	if not FileAccess.file_exists(REPORT_PATH):
		printerr("audit: %s does not exist; regenerate it" % REPORT_PATH)
		return 1
	var committed: String = FileAccess.get_file_as_string(REPORT_PATH)
	if committed == report:
		# Positive evidence that the comparison ran, for scripts/check.sh to
		# require. Godot exits 0 when a script fails to load, and a check that
		# infers success from an exit code cannot tell "the report matches" from
		# "nothing happened". Silence is not a result.
		print(CHECK_OK_MARKER)
		return 0

	var fresh_lines: PackedStringArray = report.split("\n")
	var old_lines: PackedStringArray = committed.split("\n")
	var limit: int = mini(fresh_lines.size(), old_lines.size())
	for i: int in range(limit):
		if fresh_lines[i] != old_lines[i]:
			printerr("audit: %s is stale, first difference at line %d" % [REPORT_PATH, i + 1])
			printerr("  committed: %s" % old_lines[i])
			printerr("  regenerated: %s" % fresh_lines[i])
			return 1
	printerr(
		(
			"audit: %s is stale, %d committed line(s) vs %d regenerated"
			% [REPORT_PATH, old_lines.size(), fresh_lines.size()]
		)
	)
	return 1


static func _write_report(report: String) -> int:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("audit: could not write %s (%d)" % [REPORT_PATH, FileAccess.get_open_error()])
		return 1
	file.store_string(report)
	file.close()
	print("audit: wrote %s" % REPORT_PATH)
	return 0


# ----------------------------------------------------------------- content ----


## Sorted by `content_id` so the report cannot vary with filesystem order.
## Combinations are then generated in ascending index order, which makes every
## dish's ingredient list content_id-ascending too — relied on by
## `_central_ingredient` for its tie-break.
static func _sorted_ingredients(
	ingredients: Array[IngredientDefinition]
) -> Array[IngredientDefinition]:
	var sorted: Array[IngredientDefinition] = ingredients.duplicate()
	sorted.sort_custom(
		func(a: IngredientDefinition, b: IngredientDefinition) -> bool:
			return String(a.content_id) < String(b.content_id)
	)
	return sorted


static func _sorted_customers(customers: Array[CustomerDefinition]) -> Array[CustomerDefinition]:
	var sorted: Array[CustomerDefinition] = customers.duplicate()
	sorted.sort_custom(
		func(a: CustomerDefinition, b: CustomerDefinition) -> bool:
			return String(a.content_id) < String(b.content_id)
	)
	return sorted


## Drops the `ingredient.` / `customer.` namespace for display only. Identity
## everywhere else in this file remains the full `content_id`.
static func _short(id: StringName) -> String:
	var text: String = String(id)
	var dot: int = text.find(".")
	if dot < 0:
		return text
	return text.substr(dot + 1)


# ----------------------------------------------------------- enumeration ----


## Every legal dish as an index list into a sorted pantry: all combinations of
## `Flavor.MIN_DISH_SIZE`..`MAX_DISH_SIZE` distinct ingredients, each in
## ascending index order. Sizes are read from `Flavor` rather than hardcoded so
## a contract change to dish size cannot leave this enumerating the old space.
static func _all_dishes(pantry_size: int) -> Array[PackedInt32Array]:
	var dishes: Array[PackedInt32Array] = []
	var prefix: PackedInt32Array = []
	_extend_dishes(pantry_size, 0, prefix, dishes)
	return dishes


static func _extend_dishes(
	pantry_size: int, start: int, prefix: PackedInt32Array, out_dishes: Array[PackedInt32Array]
) -> void:
	if prefix.size() >= Flavor.MIN_DISH_SIZE:
		out_dishes.append(prefix.duplicate())
	if prefix.size() >= Flavor.MAX_DISH_SIZE:
		return
	for i: int in range(start, pantry_size):
		prefix.append(i)
		_extend_dishes(pantry_size, i + 1, prefix, out_dishes)
		prefix.remove_at(prefix.size() - 1)


static func _dish_ingredients(
	dish: PackedInt32Array, pantry: Array[IngredientDefinition]
) -> Array[IngredientDefinition]:
	var chosen: Array[IngredientDefinition] = []
	for index: int in dish:
		chosen.append(pantry[index])
	return chosen


## The ingredient a dish most depends on *for this customer*: the one
## contributing the largest weighted flavour total, `sum(weight(d) * value(d))`
## over the customer's dimensions.
##
## GDD section 2.4 requires two satisfying dishes that "do not depend on the
## same central ingredient" but never defines central, so it was uncheckable as
## written. This is the definition the audit uses, and it is deliberately
## customer-relative: an ingredient can be the centre of a dish for one customer
## and incidental to it for another, which is exactly what the rule is about.
##
## Ties go to the lowest `content_id`, reached by first-wins over a dish that is
## already content_id-ascending. An arbitrary but stable rule; it only affects
## which of two equally central ingredients is named, never the count of
## distinct centres unless both dishes tie identically.
static func _central_ingredient(
	chosen: Array[IngredientDefinition], customer: CustomerDefinition
) -> StringName:
	var best_id: StringName = &""
	var best_total: int = -1
	for ingredient: IngredientDefinition in chosen:
		var total: int = 0
		for dimension: Flavor.Dimension in Flavor.all_dimensions():
			total += customer.weight_of(dimension) * ingredient.value_of(dimension)
		if total > best_total:
			best_total = total
			best_id = ingredient.content_id
	return best_id


# --------------------------------------------------------------- reporting ----


static func _build_report(
	pantry: Array[IngredientDefinition], roster: Array[CustomerDefinition]
) -> String:
	var dishes: Array[PackedInt32Array] = _all_dishes(pantry.size())

	# Flat row-major grids, dish-major: index is `dish_index * roster + customer`.
	var scores: PackedInt32Array = []
	var bands: PackedInt32Array = []
	var centrals: Array[StringName] = []
	scores.resize(dishes.size() * roster.size())
	bands.resize(dishes.size() * roster.size())
	centrals.resize(dishes.size() * roster.size())

	for d: int in range(dishes.size()):
		var chosen: Array[IngredientDefinition] = _dish_ingredients(dishes[d], pantry)
		for c: int in range(roster.size()):
			var evaluation: Evaluation = Evaluator.evaluate(chosen, roster[c])
			var cell: int = d * roster.size() + c
			scores[cell] = evaluation.score
			bands[cell] = int(evaluation.band)
			centrals[cell] = _central_ingredient(chosen, roster[c])

	var sections: PackedStringArray = []
	sections.append(_preamble(pantry, roster, dishes.size()))
	sections.append(_customer_section(pantry, roster, dishes, scores, bands, centrals))
	sections.append(_coverage_section(roster, bands, dishes.size()))
	sections.append(_dominance_section(pantry, roster, dishes, bands))
	sections.append(_constraint_section(pantry, roster, dishes, bands))
	sections.append(_definitions_section())
	sections.append(_appendix(pantry, roster, dishes, scores, bands))
	return "\n".join(sections)


static func _preamble(
	pantry: Array[IngredientDefinition], roster: Array[CustomerDefinition], dish_count: int
) -> String:
	var lines: PackedStringArray = []
	lines.append("# Recipe Space Audit")
	lines.append("")
	lines.append("**Generated file. Do not edit by hand.** Regenerate with:")
	lines.append("")
	lines.append("```")
	lines.append("godot --headless --path . -s bootstrap/audit_recipe_space.gd")
	lines.append("```")
	lines.append("")
	lines.append(
		(
			"`scripts/check.sh` regenerates this in memory and fails if it differs "
			+ "from the committed copy, so it cannot quietly go stale when content "
			+ "changes. The gate fails on drift only — a `REVISE` verdict below is a "
			+ "design finding for the human, not a broken build."
		)
	)
	lines.append("")
	lines.append(
		(
			"Every number comes from `Evaluator.evaluate()`, the same entry point the "
			+ "game uses. Nothing here reimplements the scoring formula."
		)
	)
	lines.append("")
	lines.append("## Scope")
	lines.append("")
	lines.append(
		(
			"%d ingredients, %d customers, %d legal dishes, %d evaluations."
			% [pantry.size(), roster.size(), dish_count, dish_count * roster.size()]
		)
	)
	lines.append("")
	lines.append("Pantry: %s" % ", ".join(_short_ids_of_ingredients(pantry)))
	lines.append("")
	lines.append("Roster: %s" % ", ".join(_short_ids_of_customers(roster)))
	lines.append("")
	return "\n".join(lines)


static func _short_ids_of_ingredients(pantry: Array[IngredientDefinition]) -> PackedStringArray:
	var out: PackedStringArray = []
	for ingredient: IngredientDefinition in pantry:
		out.append("`%s`" % _short(ingredient.content_id))
	return out


static func _short_ids_of_customers(roster: Array[CustomerDefinition]) -> PackedStringArray:
	var out: PackedStringArray = []
	for customer: CustomerDefinition in roster:
		out.append("`%s`" % _short(customer.content_id))
	return out


## Per-customer viability: satisfying dish count, distinct central ingredients,
## and the best reachable dish. This is the section GDD section 2.4 is about.
static func _customer_section(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	scores: PackedInt32Array,
	bands: PackedInt32Array,
	centrals: Array[StringName]
) -> String:
	var lines: PackedStringArray = []
	lines.append("## Viability per customer")
	lines.append("")
	lines.append(
		(
			(
				"GDD section 2.4: each customer needs at least %d satisfying dishes, "
				+ "including at least %d that do not share a central ingredient."
			)
			% [MIN_SATISFYING_DISHES, MIN_DISTINCT_CENTRALS]
		)
	)
	lines.append("")
	lines.append("| Customer | Best | Satisfying dishes | Distinct centres | Rule |")
	lines.append("| --- | --- | --- | --- | --- |")

	var failures: PackedStringArray = []
	for c: int in range(roster.size()):
		var satisfying: int = 0
		var seen: Dictionary[StringName, bool] = {}
		var best_score: int = -1
		var best_dish: int = -1
		for d: int in range(dishes.size()):
			var cell: int = d * roster.size() + c
			if scores[cell] > best_score:
				best_score = scores[cell]
				best_dish = d
			if bands[cell] <= SATISFYING_BAND_LIMIT:
				satisfying += 1
				seen[centrals[cell]] = true
		var centres: int = seen.size()
		var passes: bool = satisfying >= MIN_SATISFYING_DISHES and centres >= MIN_DISTINCT_CENTRALS
		if not passes:
			failures.append(_short(roster[c].content_id))
		(
			lines
			. append(
				(
					"| `%s` | %d %s — %s | %d | %d | %s |"
					% [
						_short(roster[c].content_id),
						best_score,
						BAND_NAMES[bands[best_dish * roster.size() + c]],
						_dish_label(dishes[best_dish], pantry),
						satisfying,
						centres,
						"PASS" if passes else "**FAIL**",
					]
				)
			)
		)

	lines.append("")
	if failures.is_empty():
		lines.append("Every customer satisfies the viability rule.")
	else:
		lines.append("**Fails the viability rule:** %s." % ", ".join(failures))
	lines.append("")
	return "\n".join(lines)


static func _dish_label(dish: PackedInt32Array, pantry: Array[IngredientDefinition]) -> String:
	var parts: PackedStringArray = []
	for index: int in dish:
		parts.append(_short(pantry[index].content_id))
	return " + ".join(parts)


static func _coverage_section(
	roster: Array[CustomerDefinition], bands: PackedInt32Array, dish_count: int
) -> String:
	var lines: PackedStringArray = []
	lines.append("## Band coverage")
	lines.append("")
	lines.append("How many dishes land in each band, per customer.")
	lines.append("")
	lines.append("| Customer | DELIGHTED | SATISFIED | MIXED | DISSATISFIED |")
	lines.append("| --- | --- | --- | --- | --- |")

	var unreachable: PackedStringArray = []
	for c: int in range(roster.size()):
		var counts: PackedInt32Array = [0, 0, 0, 0]
		for d: int in range(dish_count):
			counts[bands[d * roster.size() + c]] += 1
		lines.append(
			(
				"| `%s` | %d | %d | %d | %d |"
				% [_short(roster[c].content_id), counts[0], counts[1], counts[2], counts[3]]
			)
		)
		if counts[0] == 0:
			unreachable.append(_short(roster[c].content_id))

	lines.append("")
	if unreachable.is_empty():
		lines.append("Every customer can reach DELIGHTED.")
	else:
		lines.append(
			(
				(
					"**Cannot reach DELIGHTED:** %s. Not a defect on its own — ADR 0004 "
					+ "section 11 makes solvability a session property, not a per-customer "
					+ "one — but a customer nobody can delight is worth deciding about."
				)
				% ", ".join(unreachable)
			)
		)
	lines.append("")
	return "\n".join(lines)


## Two different concentration risks, both from GDD section 2.4's "no single
## recipe should satisfy more than half of the customer roster" and section 5's
## illusory-choice risk.
static func _dominance_section(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	bands: PackedInt32Array
) -> String:
	# Deliberate truncation: `half` is only ever used as "more than this many",
	# so for an odd roster the floor is exactly the threshold wanted.
	@warning_ignore("integer_division")
	var half: int = roster.size() / 2
	var lines: PackedStringArray = []
	lines.append("## Concentration")
	lines.append("")
	lines.append(
		(
			(
				"**Dominant dishes** — one recipe satisfying more than half the roster "
				+ "(more than %d of %d) would make the pantry a lookup table."
			)
			% [half, roster.size()]
		)
	)
	lines.append("")
	lines.append(_dominant_dishes(pantry, roster, dishes, bands, half))
	lines.append("")
	lines.append(
		(
			(
				"**Load-bearing ingredients** — an ingredient present in *every* "
				+ "satisfying dish for a customer is one that customer cannot be served "
				+ "without. More than %d of %d customers depending on the same "
				+ "ingredient is the illusory-choice risk in GDD section 5."
			)
			% [half, roster.size()]
		)
	)
	lines.append("")
	lines.append(_load_bearing(pantry, roster, dishes, bands, half))
	lines.append("")
	return "\n".join(lines)


static func _dominant_dishes(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	bands: PackedInt32Array,
	half: int
) -> String:
	var reported: PackedStringArray = []
	for d: int in range(dishes.size()):
		var satisfied_count: int = 0
		for c: int in range(roster.size()):
			if bands[d * roster.size() + c] <= SATISFYING_BAND_LIMIT:
				satisfied_count += 1
		if satisfied_count > half:
			reported.append(
				(
					"- `%s` satisfies %d of %d"
					% [_dish_label(dishes[d], pantry), satisfied_count, roster.size()]
				)
			)
	if reported.is_empty():
		return "No dish satisfies more than %d of %d customers." % [half, roster.size()]
	return "\n".join(reported)


static func _load_bearing(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	bands: PackedInt32Array,
	half: int
) -> String:
	var required: PackedInt32Array = []
	required.resize(pantry.size())

	for c: int in range(roster.size()):
		var present: PackedInt32Array = []
		present.resize(pantry.size())
		var satisfying: int = 0
		for d: int in range(dishes.size()):
			if bands[d * roster.size() + c] > SATISFYING_BAND_LIMIT:
				continue
			satisfying += 1
			for index: int in dishes[d]:
				present[index] += 1
		if satisfying == 0:
			continue
		for i: int in range(pantry.size()):
			if present[i] == satisfying:
				required[i] += 1

	var lines: PackedStringArray = []
	for i: int in range(pantry.size()):
		if required[i] > 0:
			(
				lines
				. append(
					(
						"- `%s` appears in every satisfying dish for %d of %d customer(s)%s"
						% [
							_short(pantry[i].content_id),
							required[i],
							roster.size(),
							" — **over half**" if required[i] > half else "",
						]
					)
				)
			)
	if lines.is_empty():
		return "No ingredient is required by any customer's whole satisfying set."
	return "\n".join(lines)


## Whether each authored constraint actually changes an outcome.
##
## ADR 0004 section 5 makes every constraint hard: violating one caps the score
## at 39. That says what a constraint does when it bites, not whether it ever
## bites. A constraint naming a real tag can still change nothing, and
## `ContentValidator` cannot see the difference -- the tag exists and the
## content is well-formed. What is left is flavour text wearing a mechanic's
## clothes, and the only way it shows up is by measuring.
##
## The test is behavioural on purpose, and deliberately NOT "does the subject
## contribute to a dimension this customer weights". Constraints never read
## flavour values (section 5), and `SumAndClampComposer` means an ingredient
## contributing 0 to every weighted dimension leaves the score untouched -- so
## it rides along in an otherwise satisfying dish, and forbidding its tag caps
## that dish from SATISFIED to DISSATISFIED. Reasoning from contribution calls
## that constraint inert; re-evaluating without it does not.
##
## Removal is marginal, one constraint at a time. A customer carrying two
## constraints that both bite the same dish has one of them doing no work there,
## and that is exactly what this should report.
static func _constraint_section(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	bands: PackedInt32Array
) -> String:
	var lines: PackedStringArray = []
	lines.append("## Constraint integrity")
	lines.append("")
	lines.append(
		(
			"A constraint is load-bearing when removing it changes some dish's band. "
			+ "One that changes nothing is flavour text in a mechanic's clothes: it "
			+ "reads as a boundary, and the player can never cross it."
		)
	)
	lines.append("")
	lines.append("| Customer | Constraint | Dishes engaging it | Bands changed | Rule |")
	lines.append("| --- | --- | --- | --- | --- |")

	var inert: PackedStringArray = []
	var total: int = 0
	for c: int in range(roster.size()):
		var customer: CustomerDefinition = roster[c]
		for i: int in range(customer.constraints.size()):
			total += 1
			var label: String = _constraint_label(customer.constraints[i])
			var engaged: int = 0
			var changed: int = 0
			var without: CustomerDefinition = _customer_without_constraint(customer, i)
			var only: CustomerDefinition = _customer_with_only_constraint(customer, i)
			for d: int in range(dishes.size()):
				var chosen: Array[IngredientDefinition] = _dish_ingredients(dishes[d], pantry)
				if not ConstraintChecker.check(chosen, only).satisfied:
					engaged += 1
				var relaxed: Evaluation = Evaluator.evaluate(chosen, without)
				if int(relaxed.band) != bands[d * roster.size() + c]:
					changed += 1
			if changed == 0:
				inert.append("`%s` %s" % [_short(customer.content_id), label])
			(
				lines
				. append(
					(
						"| `%s` | %s | %d | %d | %s |"
						% [
							_short(customer.content_id),
							label,
							engaged,
							changed,
							"PASS" if changed > 0 else "**INERT**",
						]
					)
				)
			)

	lines.append("")
	if total == 0:
		lines.append("No customer carries a constraint.")
	elif inert.is_empty():
		lines.append("Every constraint changes at least one outcome.")
	else:
		lines.append("**Inert constraints:** %s." % ", ".join(inert))
	lines.append("")
	return "\n".join(lines)


## `FORBID_TAG `smoked`` and friends. Guarded against an out-of-range `kind` for
## the reason `CustomerConstraint._to_string()` is: `.tres` is editable text and
## Godot does not clamp an exported enum on load.
static func _constraint_label(constraint: CustomerConstraint) -> String:
	var index: int = int(constraint.kind)
	var names: Array = CustomerConstraint.Kind.keys()
	var kind: String = "INVALID(%d)" % index
	if index >= 0 and index < names.size():
		kind = str(names[index])
	return "%s `%s`" % [kind, String(constraint.subject)]


## A copy of `customer` carrying every constraint except the one at `skip`.
static func _customer_without_constraint(
	customer: CustomerDefinition, skip: int
) -> CustomerDefinition:
	var kept: Array[CustomerConstraint] = []
	for i: int in range(customer.constraints.size()):
		if i != skip:
			kept.append(customer.constraints[i])
	return _customer_carrying(customer, kept)


## A copy of `customer` carrying only the constraint at `keep`, used to count
## how many dishes engage that constraint on its own.
static func _customer_with_only_constraint(
	customer: CustomerDefinition, keep: int
) -> CustomerDefinition:
	var kept: Array[CustomerConstraint] = [customer.constraints[keep]]
	return _customer_carrying(customer, kept)


## `duplicate()` copies the exported `constraints` array by reference, so the
## replacement is assigned wholesale rather than edited in place -- mutating it
## would corrupt the roster this audit is in the middle of measuring.
static func _customer_carrying(
	customer: CustomerDefinition, constraints: Array[CustomerConstraint]
) -> CustomerDefinition:
	var variant: CustomerDefinition = customer.duplicate() as CustomerDefinition
	variant.constraints = constraints
	return variant


static func _definitions_section() -> String:
	var lines: PackedStringArray = []
	lines.append("## Definitions")
	lines.append("")
	lines.append(
		(
			"**Satisfying** — a dish scoring in DELIGHTED or SATISFIED, so at least "
			+ "65. A constraint violation caps the score at 39, so a satisfying dish "
			+ "always also respects the customer's boundaries."
		)
	)
	lines.append("")
	lines.append(
		(
			"**Central ingredient** — the ingredient in a dish with the largest "
			+ "`sum(customer weight × ingredient value)` across the flavour "
			+ "dimensions, ties going to the lowest `content_id`. The GDD requires "
			+ "two satisfying dishes with different central ingredients but never "
			+ "defined central, so the rule was uncheckable until this audit fixed a "
			+ "definition. It is customer-relative on purpose: an ingredient can "
			+ "carry a dish for one customer and be incidental for another."
		)
	)
	lines.append("")
	return "\n".join(lines)


## The full enumeration, one row per dish. This is the "all-combination" part of
## the Week 3 deliverable: the summaries above are derived from it, and it is
## what makes the report checkable rather than asking a reader to trust a
## rollup. Cells are `score BAND`; `!` marks a constraint violation.
static func _appendix(
	pantry: Array[IngredientDefinition],
	roster: Array[CustomerDefinition],
	dishes: Array[PackedInt32Array],
	scores: PackedInt32Array,
	bands: PackedInt32Array
) -> String:
	var lines: PackedStringArray = []
	lines.append("## Appendix: every dish")
	lines.append("")
	lines.append("Cells are `score BAND`. A trailing `!` marks a constraint violation.")
	lines.append("")

	var header: PackedStringArray = ["Dish"]
	var divider: PackedStringArray = ["---"]
	for customer: CustomerDefinition in roster:
		header.append(_short(customer.content_id))
		divider.append("---")
	lines.append("| %s |" % " | ".join(header))
	lines.append("| %s |" % " | ".join(divider))

	for d: int in range(dishes.size()):
		var chosen: Array[IngredientDefinition] = _dish_ingredients(dishes[d], pantry)
		var row: PackedStringArray = [_dish_label(dishes[d], pantry)]
		for c: int in range(roster.size()):
			var cell: int = d * roster.size() + c
			# Re-checked rather than stored: only the appendix needs it, and a
			# third full-size grid to carry one bit per cell is not worth it.
			var violated: bool = not ConstraintChecker.check(chosen, roster[c]).satisfied
			row.append(
				"%d %s%s" % [scores[cell], BAND_LABELS[bands[cell]], "!" if violated else ""]
			)
		lines.append("| %s |" % " | ".join(row))
	lines.append("")
	return "\n".join(lines)
