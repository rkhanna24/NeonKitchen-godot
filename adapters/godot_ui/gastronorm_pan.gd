## A theme-driven, non-interactive gastronorm pan backdrop.
##
## This first proof is deliberately limited to the 152x48 `fresh_and_cured`
## silhouette from issue #52. Its flat layers establish a seam for later art:
## the layer stack can be replaced by a TextureRect without changing the
## IngredientBlock that owns input, focus, accessibility, and gameplay identity.
class_name GastronormPan
extends Control

const THEME_VARIATION: StringName = &"PrepPanButton"


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	show_behind_parent = true
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_add_layer(&"Face", &"PrepPanFace", 6.0, 13.0, -6.0, -2.0)
	_add_layer(&"Rim", &"PrepPanRim", 0.0, 2.0, 0.0, -11.0)
	_add_layer(&"Well", &"PrepPanWell", 6.0, 6.0, -6.0, -15.0)
	_add_layer(&"Specular", &"PrepPanSpecular", 20.0, 4.0, -20.0, -38.0)


func _add_layer(
	layer_name: StringName,
	theme_variation: StringName,
	left: float,
	top: float,
	right: float,
	bottom: float,
) -> void:
	var layer := Panel.new()
	layer.name = layer_name
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.focus_mode = Control.FOCUS_NONE
	layer.theme_type_variation = theme_variation
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = left
	layer.offset_top = top
	layer.offset_right = right
	layer.offset_bottom = bottom
	add_child(layer)
