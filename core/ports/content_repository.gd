## Port: how the application obtains validated content definitions.
##
## The one port with a real Phase 1 consumer, per ADR 0002 section 5. Every
## implementation must pass the shared contract suite in
## `tests/contract/`, so a `.tres` repository and an in-memory test repository
## resolve identifiers and report missing content identically.
##
## Contract:
##   - lookups are by stable `content_id`, never by path, UID, or index;
##   - a missing identifier returns `null` rather than raising;
##   - `all_*` returns definitions sorted by `content_id`, so iteration order is
##     deterministic and golden cases stay stable;
##   - returned definitions are validated and must be treated as immutable.
@abstract class_name ContentRepository
extends RefCounted

@abstract func find_ingredient(content_id: StringName) -> IngredientDefinition

@abstract func find_customer(content_id: StringName) -> CustomerDefinition

@abstract func all_ingredients() -> Array[IngredientDefinition]

@abstract func all_customers() -> Array[CustomerDefinition]


func has_ingredient(content_id: StringName) -> bool:
	return find_ingredient(content_id) != null


func has_customer(content_id: StringName) -> bool:
	return find_customer(content_id) != null
