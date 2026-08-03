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
##   - returned definitions must be treated as immutable.
##
## Validation belongs to whichever implementation owns the content source. One
## that loads from disk can validate the whole set and refuse to serve any of it
## on failure; one handed definitions directly by its caller cannot promise more
## than that it reports structural problems. The port therefore does not
## guarantee validation on their behalf.
##
## This deliberately describes kinds of implementation rather than naming any:
## a port that knows its adapters has the dependency arrow backwards.
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
