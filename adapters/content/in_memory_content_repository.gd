## In-memory ContentRepository, for tests and golden cases.
##
## This is a real substitute rather than a mock: it implements the same port and
## passes the same contract suite as the `.tres` repository. That is why ADR
## 0003 could reject a mocking framework — the seams are exercised with genuine
## implementations.
class_name InMemoryContentRepository
extends ContentRepository

var _ingredients: Dictionary[StringName, IngredientDefinition] = {}
var _customers: Dictionary[StringName, CustomerDefinition] = {}
var _problems: PackedStringArray = []


func _init(
	ingredients: Array[IngredientDefinition] = [], customers: Array[CustomerDefinition] = []
) -> void:
	for ingredient: IngredientDefinition in ingredients:
		if ingredient == null:
			_problems.append("ingredient: null entry")
			continue
		if ingredient.content_id == &"":
			_problems.append("ingredient: empty content_id")
			continue
		if _ingredients.has(ingredient.content_id):
			_problems.append("ingredient '%s': duplicate content_id" % ingredient.content_id)
			continue
		_ingredients[ingredient.content_id] = ingredient
	for customer: CustomerDefinition in customers:
		if customer == null:
			_problems.append("customer: null entry")
			continue
		if customer.content_id == &"":
			_problems.append("customer: empty content_id")
			continue
		if _customers.has(customer.content_id):
			_problems.append("customer '%s': duplicate content_id" % customer.content_id)
			continue
		_customers[customer.content_id] = customer


## Structural problems in the supplied definitions: nulls, empty identifiers,
## and duplicates.
##
## Not content validation -- that belongs to ContentValidator and to whoever
## owns the source. These are the cases where silently accepting the input would
## make this implementation disagree with the `.tres` one, which refuses a set
## containing a duplicate. First entry wins rather than last, so the disagreement
## is reported rather than absorbed.
func problems() -> PackedStringArray:
	return _problems.duplicate()


func find_ingredient(content_id: StringName) -> IngredientDefinition:
	return _ingredients.get(content_id, null)


func find_customer(content_id: StringName) -> CustomerDefinition:
	return _customers.get(content_id, null)


func all_ingredients() -> Array[IngredientDefinition]:
	var out: Array[IngredientDefinition] = []
	for id: StringName in _sorted_ids(_ingredients.keys()):
		out.append(_ingredients[id])
	return out


func all_customers() -> Array[CustomerDefinition]:
	var out: Array[CustomerDefinition] = []
	for id: StringName in _sorted_ids(_customers.keys()):
		out.append(_customers[id])
	return out


## Lexicographic order.
##
## **Never use `Array[StringName].sort()` for ordering.** StringName's `<`
## compares internal pointers, not text — Godot documents this — so it is a
## consistent order with no relationship to the characters. The result depends
## on interning order, which follows content load order.
##
## Measured on Godot 4.7.1: five names interned in ascending text order sorted
## to exactly reversed text order, while the same names interned in descending
## order came out looking correct. It is not flaky; it is stably wrong, and
## whether it *looks* wrong depends on the order content happened to load in.
##
## Sort on String, as below, or `sort_custom` comparing `String(a) < String(b)`.
## Both were verified equivalent. The port promises deterministic iteration and
## golden cases depend on it.
static func _sorted_ids(keys: Array[StringName]) -> Array[StringName]:
	var texts: Array[String] = []
	for key: StringName in keys:
		texts.append(String(key))
	texts.sort()
	var out: Array[StringName] = []
	for text: String in texts:
		out.append(StringName(text))
	return out
