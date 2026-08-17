## One reusable pantry/tray block for the greybox
## (docs/design/references/godot-greybox-ideas.md section 3).
##
## A `Button` root so mouse press, Tab focus, and Enter/Space activation come
## free from `Control` -- this greybox adds no custom Input Map action for
## selection or inspection because the built-in behaviour already reaches
## both by keyboard.
##
## Carries a stable `content_id` separately from its label, for the same
## reason `kitchen_screen.gd` binds by id rather than reading translated text
## back off a button (see `_ingredient_button` there): the label is
## translated display text and the command needs the untranslated id.
##
## This screen never asks `GreyboxKitchenScreen` or the session what is
## selected; the parent tells it via `set_selected()`. That mirrors
## `KitchenScreen._on_ingredient_pressed`, which reads `SessionState` before
## deciding to select or remove -- the block does not duplicate that read.
class_name IngredientBlock
extends Button

## Fired on hover or focus, whichever happens first, so a mouse user and a
## keyboard user reach the same inspection information
## (godot-greybox-ideas.md section 3; GDD section 2.4 requires descriptions to
## stay available through a session, not just as a tooltip).
signal inspected(id: StringName, display_name: String, description: String)

enum SizeClass { SMALL, STANDARD, WIDE }

## Presentation-only minimum widths, one spacing unit (8px, Visual
## Language.md) apart from each other. Never derived from flavour weight --
## #35 forbids putting flavour on screen in any form, and a size that tracked
## intensity would be exactly that.
const MIN_WIDTH_BY_SIZE: Dictionary[SizeClass, int] = {
	SizeClass.SMALL: 96,
	SizeClass.STANDARD: 144,
	SizeClass.WIDE: 208,
}

var content_id: StringName = &""
var ingredient_description: String = ""


func setup(
	p_content_id: StringName, display_name: String, p_description: String, size_class: SizeClass
) -> void:
	content_id = p_content_id
	ingredient_description = p_description
	text = display_name
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	# Indexed rather than `.get()` with a fallback: `Dictionary.get()` widens to
	# Variant even on a typed dictionary, which is a warning-as-error here. The
	# fallback was unreachable anyway -- `size_class` is enum-typed and every
	# member has an entry above, so a missing key would be a compile-time
	# impossibility rather than a runtime case worth defending against.
	custom_minimum_size.x = MIN_WIDTH_BY_SIZE[size_class]
	mouse_entered.connect(_on_inspected)
	focus_entered.connect(_on_inspected)


func _on_inspected() -> void:
	inspected.emit(content_id, text, ingredient_description)


## Selected appearance, supplied by the parent. `button_pressed` is the
## engine's own toggle state -- a real state change, not a colour swap, so it
## survives desaturation (Visual Language.md rule 1). The tray is the
## guaranteed-legible marker (an ingredient's presence there *is* the
## non-colour record of selection); this is a second, redundant signal on the
## block itself.
func set_selected(is_selected: bool) -> void:
	button_pressed = is_selected
