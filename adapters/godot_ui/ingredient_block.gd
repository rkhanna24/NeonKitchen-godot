## A reusable pantry block for the preparation view (docs/design/references/
## godot-greybox-ideas.md §3).
##
## A plain `Button` subclass built and configured in code -- not a `.tscn` --
## because a scene file is not usefully diff-reviewable and this type has
## exactly one caller.
##
## Carries the stable `content_id` the session commands need, and a
## presentation-only `set_selected()` marker. Selection is shown as a text
## prefix rather than a colour or style change: Visual Language.md rule 1
## requires selection to survive greyscale, and a text marker survives it
## trivially without any inline theme override (forbidden project-wide) and
## without a "selected" style this theme resource does not define.
class_name IngredientBlock
extends Button

## The smallest dimension any block may render at, in pixels.
##
## Enforced here rather than by the caller, because this is the thing that has
## to be hittable and a guarantee is worth more where it cannot be forgotten.
## Silhouettes vary in shape -- wide and low on the staple shelf, tall for a
## carton, squat for a jar -- but never below this: Pekoe's don't-borrow note
## names "tiny unequal click targets" as the failure mode of a shelf of varied
## objects. Varied to look at, uniform to hit.
const MIN_INTERACTION_TARGET: float = 44.0

## Prefix marking a selected block. ASCII rather than a check-glyph so the
## marker cannot silently disappear on a font with a missing glyph.
const _SELECTED_PREFIX: String = "[x] "

## Stable id `KitchenSession.select()`/`remove()` need. Never read the
## translated button text back for this -- that would break the moment two
## ingredients ever shared a display name.
var content_id: StringName = &""

var _display_name: String = ""


## Configures this block for one ingredient. `silhouette` is presentation-only
## (docs/design/references/godot-greybox-ideas.md §3): it must never be added
## to `IngredientDefinition` without a separate content-design decision, so it
## is supplied by the caller rather than read from the ingredient itself.
##
## It is the block's **minimum**, not its size, so a station's container may
## still stretch it. The shape varies by station -- wide and low on the staple
## shelf, tall for a carton, squat for a jar -- while the name stays visible on
## every one of them, which is Pekoe's don't-borrow note followed rather than
## admired: a shelf that relies on silhouette alone is not a readable pantry.
##
## `silhouette` is raised to `MIN_INTERACTION_TARGET` in both dimensions. An
## earlier version left the floor to the caller and unenforced, reasoning that a
## clamp would make the test asserting it unable to fail. That was backwards: a
## guard is falsified by removing the guard, and a guarantee nothing enforces is
## a comment.
func setup(ingredient: IngredientDefinition, silhouette: Vector2) -> void:
	content_id = ingredient.content_id
	_display_name = String(TranslationServer.translate(ingredient.name_key))
	text = _display_name
	# Keep the assistive name stable when `set_selected()` adds its visual
	# marker. The marker must stay visible in greyscale, but it is state rather
	# than part of the ingredient's name.
	accessibility_name = _display_name
	custom_minimum_size = silhouette.max(Vector2(MIN_INTERACTION_TARGET, MIN_INTERACTION_TARGET))
	clip_text = false
	focus_mode = Control.FOCUS_ALL


## The non-colour marker Visual Language.md rule 1 requires. `disabled` (set
## by the screen while the pantry is inert) already carries its own
## non-colour marker for free, from this theme's distinct `disabled` stylebox
## and `font_disabled_color` -- this method only needs to cover selection.
func set_selected(selected: bool) -> void:
	text = (_SELECTED_PREFIX + _display_name) if selected else _display_name
