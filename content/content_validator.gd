## Validates authored content before the domain is allowed to consume it.
##
## Rule 7 requires validation ahead of domain use, and the point is to fail with
## an actionable message at load rather than produce a plausible wrong score
## during play. Every message names the offending `content_id` and field.
class_name ContentValidator
extends RefCounted

const ID_PATTERN: String = "^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*$"

## Highest schema version this build understands. Content authored at a later
## version may carry fields this code ignores, so it is rejected rather than
## silently reinterpreted with today's semantics.
const MAX_SCHEMA_VERSION: int = 1

static var _cached_id_regex: RegEx = null


## Validates a whole content set and returns human-readable problems.
## An empty array means the content is safe for the domain to use.
static func validate(
	ingredients: Array[IngredientDefinition], customers: Array[CustomerDefinition]
) -> PackedStringArray:
	var problems: PackedStringArray = []
	var known_ingredients: Dictionary[StringName, bool] = {}
	var known_tags: Dictionary[StringName, bool] = {}

	problems.append_array(_validate_ingredients(ingredients, known_ingredients, known_tags))
	problems.append_array(_validate_customers(customers, known_ingredients, known_tags))
	return problems


static func _validate_ingredients(
	ingredients: Array[IngredientDefinition],
	known_ingredients: Dictionary[StringName, bool],
	known_tags: Dictionary[StringName, bool]
) -> PackedStringArray:
	var problems: PackedStringArray = []
	for ingredient: IngredientDefinition in ingredients:
		if ingredient == null:
			problems.append("ingredient: null entry in content set")
			continue
		var id: StringName = ingredient.content_id
		problems.append_array(_validate_id(id, "ingredient"))
		if known_ingredients.has(id):
			problems.append("ingredient '%s': duplicate content_id" % id)
		known_ingredients[id] = true

		if ingredient.schema_version < 1 or ingredient.schema_version > MAX_SCHEMA_VERSION:
			problems.append(
				(
					"ingredient '%s': schema_version %d is outside 1..%d"
					% [id, ingredient.schema_version, MAX_SCHEMA_VERSION]
				)
			)
		if ingredient.name_key == &"":
			problems.append("ingredient '%s': missing name_key" % id)
		if ingredient.description_key == &"":
			problems.append("ingredient '%s': missing description_key" % id)

		for dimension: Flavor.Dimension in Flavor.all_dimensions():
			var value: int = ingredient.value_of(dimension)
			if value < 0 or value > Flavor.MAX_INGREDIENT_VALUE:
				var label: StringName = Flavor.dimension_name(dimension)
				var limit: int = Flavor.MAX_INGREDIENT_VALUE
				var message: String = (
					"ingredient '%s': %s is %d, outside 0..%d" % [id, label, value, limit]
				)
				problems.append(message)

		for tag: StringName in ingredient.tags:
			if tag == &"":
				problems.append("ingredient '%s': empty tag" % id)
			known_tags[tag] = true
	return problems


static func _validate_customers(
	customers: Array[CustomerDefinition],
	known_ingredients: Dictionary[StringName, bool],
	known_tags: Dictionary[StringName, bool]
) -> PackedStringArray:
	var problems: PackedStringArray = []
	var known_customers: Dictionary[StringName, bool] = {}

	for customer: CustomerDefinition in customers:
		if customer == null:
			problems.append("customer: null entry in content set")
			continue
		var id: StringName = customer.content_id
		problems.append_array(_validate_id(id, "customer"))
		if known_customers.has(id):
			problems.append("customer '%s': duplicate content_id" % id)
		known_customers[id] = true

		if customer.schema_version < 1 or customer.schema_version > MAX_SCHEMA_VERSION:
			problems.append(
				(
					"customer '%s': schema_version %d is outside 1..%d"
					% [id, customer.schema_version, MAX_SCHEMA_VERSION]
				)
			)
		if customer.name_key == &"":
			problems.append("customer '%s': missing name_key" % id)
		if customer.request_key == &"":
			problems.append("customer '%s': missing request_key" % id)
		if customer.reaction_key == &"":
			problems.append("customer '%s': missing reaction_key" % id)

		problems.append_array(_validate_customer_weights(customer))
		problems.append_array(
			_validate_customer_constraints(customer, known_ingredients, known_tags)
		)
	return problems


static func _validate_customer_weights(customer: CustomerDefinition) -> PackedStringArray:
	var problems: PackedStringArray = []
	var id: StringName = customer.content_id
	var total_weight: int = 0
	var nonzero_weights: int = 0

	for dimension: Flavor.Dimension in Flavor.all_dimensions():
		var target: int = customer.target_of(dimension)
		var weight: int = customer.weight_of(dimension)
		var dimension_label: StringName = Flavor.dimension_name(dimension)

		# Negative weights invert the arithmetic and can drive the score
		# divisor to zero or below. See ADR 0004 section 2.
		if weight < 0 or weight > Flavor.MAX_WEIGHT:
			problems.append(
				(
					"customer '%s': %s weight is %d, outside 0..%d"
					% [id, dimension_label, weight, Flavor.MAX_WEIGHT]
				)
			)
		if target < 0 or target > Flavor.MAX_TARGET:
			problems.append(
				(
					"customer '%s': %s target is %d, outside 0..%d"
					% [id, dimension_label, target, Flavor.MAX_TARGET]
				)
			)
		if weight != 0:
			nonzero_weights += 1
		total_weight += maxi(weight, 0)

	# All-zero weights leave nothing to score against and would make the
	# scoring divisor zero. Reported only when the weights really are zero:
	# clamping a negative weight to 0 previously produced this message
	# alongside the out-of-range one, sending the author after a field they
	# never set.
	if total_weight == 0 and nonzero_weights == 0:
		problems.append("customer '%s': every weight is zero, so there is nothing to score" % id)
	return problems


static func _validate_customer_constraints(
	customer: CustomerDefinition,
	known_ingredients: Dictionary[StringName, bool],
	known_tags: Dictionary[StringName, bool]
) -> PackedStringArray:
	var problems: PackedStringArray = []
	var id: StringName = customer.content_id

	if customer.constraints.size() > 2:
		problems.append(
			"customer '%s': %d constraints, at most 2 permitted" % [id, customer.constraints.size()]
		)

	for constraint: CustomerConstraint in customer.constraints:
		if constraint == null:
			problems.append("customer '%s': null constraint" % id)
			continue
		# Godot does not clamp an exported enum on load and .tres is editable
		# text, so an out-of-range kind is reachable and would silently behave
		# as a different rule than the author wrote.
		var kind_index: int = int(constraint.kind)
		if kind_index < 0 or kind_index >= CustomerConstraint.Kind.size():
			problems.append(
				"customer '%s': constraint kind %d is not a valid kind" % [id, kind_index]
			)
			continue
		if constraint.subject == &"":
			problems.append("customer '%s': constraint with empty subject" % id)
			continue
		# This key is what tells the player why their dish was refused; an
		# unset one produces a blank explanation during play.
		if constraint.explanation_key == &"":
			problems.append(
				(
					"customer '%s': constraint on '%s' has no explanation_key"
					% [id, constraint.subject]
				)
			)
		if constraint.is_ingredient_kind():
			if not known_ingredients.has(constraint.subject):
				problems.append(
					(
						"customer '%s': constraint references unknown ingredient '%s'"
						% [id, constraint.subject]
					)
				)
		elif not known_tags.has(constraint.subject):
			problems.append(
				(
					"customer '%s': constraint references tag '%s' that no ingredient carries"
					% [id, constraint.subject]
				)
			)

	# A customer who both requires and forbids the same thing can never be
	# satisfied, and the contradiction is easy to author by accident.
	#
	# Compare each unordered pair once: walking ordered pairs reported every
	# contradiction twice. Kinds must also agree on namespace, since an
	# ingredient id and a tag are different things that may share text.
	var count: int = customer.constraints.size()
	for i: int in range(count):
		var outer: CustomerConstraint = customer.constraints[i]
		if outer == null:
			continue
		for j: int in range(i + 1, count):
			var inner: CustomerConstraint = customer.constraints[j]
			if inner == null:
				continue
			if outer.subject != inner.subject:
				continue
			if outer.is_ingredient_kind() != inner.is_ingredient_kind():
				continue
			if outer.is_forbidding() != inner.is_forbidding():
				problems.append(
					"customer '%s': both requires and forbids '%s'" % [id, outer.subject]
				)
	return problems


## The compiled id pattern, or null if it will not compile.
static func _id_regex() -> RegEx:
	if _cached_id_regex != null:
		return _cached_id_regex
	var regex := RegEx.new()
	if regex.compile(ID_PATTERN) != OK:
		return null
	_cached_id_regex = regex
	return _cached_id_regex


static func _validate_id(id: StringName, kind: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	if id == &"":
		problems.append("%s: missing content_id" % kind)
		return problems
	# Compiled once per run rather than once per identifier.
	var regex: RegEx = _id_regex()
	# Fail closed. Skipping the check when the pattern will not compile would
	# silently accept every identifier, which is the opposite of this file's job.
	if regex == null:
		problems.append("%s '%s': could not compile the content_id pattern" % [kind, id])
		return problems
	# `search` is not a full match, and PCRE `$` also matches before a trailing
	# newline, so "ingredient.ok\n" satisfied the anchors. Compare the matched
	# span against the whole identifier instead.
	var text: String = String(id)
	var found := regex.search(text)
	if found == null or found.get_string() != text:
		problems.append(
			(
				"%s '%s': content_id must be namespaced lowercase, such as '%s.example_name'"
				% [kind, id, kind]
			)
		)
	return problems
