## A hard boundary a dish must respect, per ADR 0004 section 5.
##
## All four kinds are hard: violating any one caps the score at 39, forcing
## DISSATISFIED regardless of how well the flavour matched. Dietary and allergen
## rules are expressed as FORBID_TAG rather than as a separate mechanism.
##
## Constraints are evaluated against ingredient identity and tags only, never
## against flavour values. A preference about flavour is a weighted target, not
## a constraint.
class_name CustomerConstraint
extends Resource

enum Kind { REQUIRE_INGREDIENT, FORBID_INGREDIENT, REQUIRE_TAG, FORBID_TAG }

@export var kind: Kind = Kind.FORBID_TAG

## An ingredient `content_id` for the INGREDIENT kinds, or a tag for the TAG
## kinds. Never a display name.
@export var subject: StringName = &""

## Localisation key explaining the boundary in the customer's own words.
@export var explanation_key: StringName = &""


func is_ingredient_kind() -> bool:
	return kind == Kind.REQUIRE_INGREDIENT or kind == Kind.FORBID_INGREDIENT


func is_forbidding() -> bool:
	return kind == Kind.FORBID_INGREDIENT or kind == Kind.FORBID_TAG


## Guarded rather than indexing `Kind.keys()` directly. `.tres` is editable
## text and Godot does not clamp an exported enum on load, so an out-of-range
## value is reachable — and crashing while printing the object is the worst
## time to fail, since printing is how the problem gets diagnosed.
func _to_string() -> String:
	var index: int = int(kind)
	# `Kind.keys()` is an untyped Array, so `str()` rather than `String()`,
	# which rejects a Variant under the project's warning settings.
	var names: Array = Kind.keys()
	var label: String = "INVALID(%d)" % index
	if index >= 0 and index < names.size():
		label = str(names[index])
	return "CustomerConstraint(%s %s)" % [label, subject]
