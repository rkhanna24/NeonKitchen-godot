## The preparation view's spatial layout, per #44.
##
## Split out of `test_kitchen_screen.gd` only because that file hit the
## 20-public-method lint cap. These are layout claims rather than flow claims:
## that the worktop is a place with stations around a dominant centre, and not
## the three stacked bands it replaced.
##
## What a headless run can check is geometry, containment, and focus wiring.
## Whether it *reads* as a workspace is the five-second recall test, and only a
## person can run that.
extends GutTest

var _screen: KitchenScreen = null

## Every assertion here is about rendered geometry, so the viewport has to be a
## real size. GUT's default root is far smaller than the recorded minimum, and
## at that size every control collapses to its own minimum -- which would make
## a rendered-size assertion measure the harness rather than the layout.
var _original_window_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
	_screen = KitchenScreen.new()
	add_child_autofree(_screen)
	var window: Window = _screen.get_viewport() as Window
	if window != null:
		_original_window_size = window.size
		window.size = Vector2i(KitchenScreen.HYPOTHESIS_MIN_SIZE)


func after_each() -> void:
	var window: Window = _screen.get_viewport() as Window
	if window != null and _original_window_size != Vector2i.ZERO:
		window.size = _original_window_size


## The preparation view starts hidden, and a hidden `Control` is not laid out --
## every rendered-size assertion here read 0.0 until this existed, which would
## have made them pass or fail for reasons unrelated to the layout.
func _enter_preparation() -> void:
	_screen._confirm_button.pressed.emit()
	await wait_process_frames(2)


func _find_block(ingredient_id: StringName) -> IngredientBlock:
	for block: IngredientBlock in _screen._ingredient_blocks:
		if block.content_id == ingredient_id:
			return block
	return null


## #44's load-bearing invariant: silhouettes vary by station, interaction
## targets do not. Pekoe's don't-borrow note names "tiny unequal click targets"
## as the failure mode of a shelf of varied objects, so this is the check that
## keeps the variation on the looking side of that line.
##
## Asserts against the blocks the screen actually built rather than against the
## `_GROUP_SILHOUETTE` table, so a station whose container squeezes a block
## below the floor is caught too, not only a bad constant.
func test_every_ingredient_block_meets_the_interaction_floor() -> void:
	# Asserted against the size a block is actually **given**, not the minimum
	# it requests. `custom_minimum_size` is clamped in `_ingredient_block`, so
	# checking it would only re-read the clamp; a station container squeezing a
	# block below the floor is the failure worth catching, and only the rendered
	# rect can show it.
	await _enter_preparation()
	var floor_size: float = IngredientBlock.MIN_INTERACTION_TARGET
	for block: IngredientBlock in _screen._ingredient_blocks:
		assert_gte(
			block.size.x,
			floor_size,
			"%s renders %d wide, under the %d floor" % [block.content_id, block.size.x, floor_size]
		)
		assert_gte(
			block.size.y,
			floor_size,
			"%s renders %d tall, under the %d floor" % [block.content_id, block.size.y, floor_size]
		)


## The clamp itself, separately from the layout. An authored silhouette below
## the floor must be raised rather than trusted -- the table is data, and data
## is where a too-small target would come from.
func test_a_silhouette_below_the_floor_is_raised_to_it() -> void:
	var tiny := IngredientDefinition.new()
	tiny.content_id = &"ingredient.tiny"
	tiny.name_key = &"ingredient.tiny.name"
	var block := IngredientBlock.new()
	add_child_autofree(block)

	block.setup(tiny, Vector2(8.0, 4.0))

	var floor_size: float = IngredientBlock.MIN_INTERACTION_TARGET
	assert_eq(block.custom_minimum_size.x, floor_size, "an 8px width is raised to the floor")
	assert_eq(block.custom_minimum_size.y, floor_size, "a 4px height is raised to the floor")


## The shape survives the clamp. A floor that flattened every block to a square
## would satisfy the hit target and destroy the variation it exists to protect.
func test_the_clamp_does_not_flatten_a_legal_silhouette() -> void:
	var wide := IngredientDefinition.new()
	wide.content_id = &"ingredient.wide"
	wide.name_key = &"ingredient.wide.name"
	var block := IngredientBlock.new()
	add_child_autofree(block)

	block.setup(wide, Vector2(180.0, 56.0))

	assert_eq(block.custom_minimum_size, Vector2(180.0, 56.0), "a legal shape passes through")


## Silhouettes must actually differ, or the "varied to look at" half of the
## rule is decoration. Two distinct shapes would technically satisfy "varied";
## this requires one per station, which is what the design claims.
func test_the_stations_do_not_all_share_one_silhouette() -> void:
	var shapes: Dictionary[Vector2, bool] = {}
	for block: IngredientBlock in _screen._ingredient_blocks:
		shapes[block.custom_minimum_size] = true
	assert_eq(
		shapes.size(),
		IngredientDefinition.GROUPS.size(),
		"one distinct silhouette per station, not one shape for the whole pantry"
	)


## DEC-029's groups become places. Every group in the display contract has a
## station, and every ingredient is inside its own group's station rather than
## in a flat list that merely happens to be sorted.
func test_every_ingredient_sits_in_its_own_group_station() -> void:
	assert_eq(
		_screen._station_slots.size(),
		IngredientDefinition.GROUPS.size(),
		"one station per declared group"
	)
	for ingredient: IngredientDefinition in _screen._session.content().all_ingredients():
		var block: IngredientBlock = _find_block(ingredient.content_id)
		assert_not_null(block, "%s has a block" % ingredient.content_id)
		assert_eq(
			block.get_parent(),
			_screen._station_slots[ingredient.group],
			"%s sits in the %s station" % [ingredient.content_id, ingredient.group]
		)


## The centre has to actually be the centre. The dish surface is the record of
## every choice the player has made, and in the version this replaces it was
## the least prominent thing on screen -- three small labels reading "(empty)".
func test_the_dish_surface_is_the_largest_single_region() -> void:
	var pass_area: float = KitchenScreen._PASS_ZONE.size.x * KitchenScreen._PASS_ZONE.size.y
	for group: StringName in IngredientDefinition.GROUPS:
		var zone: Rect2 = KitchenScreen._STATION_ZONE[group]
		assert_gt(
			pass_area, zone.size.x * zone.size.y, "the pass is larger than the %s station" % group
		)
	for zone: Rect2 in [KitchenScreen._TICKET_ZONE, KitchenScreen._INSPECTION_ZONE]:
		assert_gt(
			pass_area, zone.size.x * zone.size.y, "the pass is larger than the reference column"
		)


## Explicit focus neighbours, closing into a loop through Serve, so a
## keyboard-only player can always reach the commit and Tab never dead-ends.
## Godot's automatic guess is geometric, and with four stations around a centre
## it hops in an order matching nothing on screen.
func test_the_focus_chain_is_explicit_and_closes_through_serve() -> void:
	var blocks: Array[IngredientBlock] = _screen._ingredient_blocks
	assert_gt(blocks.size(), 0, "there are blocks to chain")
	for index: int in range(blocks.size() - 1):
		assert_eq(
			blocks[index].focus_next,
			blocks[index + 1].get_path(),
			"block %d hands focus to block %d" % [index, index + 1]
		)
	var last: IngredientBlock = blocks[blocks.size() - 1]
	assert_eq(last.focus_next, _screen._serve_button.get_path(), "the last block reaches Serve")
	assert_eq(
		_screen._serve_button.focus_next,
		_screen._read_request_button.get_path(),
		"Serve hands on to the request button"
	)
	assert_eq(
		_screen._read_request_button.focus_next,
		blocks[0].get_path(),
		"which wraps back to the pantry"
	)
	assert_eq(
		blocks[0].focus_previous,
		_screen._read_request_button.get_path(),
		"and backwards from the first"
	)


## Every zone in the preparation view, in the order they are declared.
func _all_zones() -> Array[Rect2]:
	var zones: Array[Rect2] = [
		KitchenScreen._TICKET_ZONE,
		KitchenScreen._INSPECTION_ZONE,
		KitchenScreen._PASS_ZONE,
	]
	for group: StringName in IngredientDefinition.GROUPS:
		zones.append(KitchenScreen._STATION_ZONE[group])
	return zones


## Seven zones were placed by hand as anchor fractions. Two overlapping ones
## put a station on top of the pass, and the symptom in a headless run is
## nothing at all -- it only shows up as the "worktop void" kind of defect once
## somebody looks at it. `Rect2.intersects` costs nothing and does not need
## eyes.
func test_no_two_preparation_zones_overlap() -> void:
	var zones: Array[Rect2] = _all_zones()
	for i: int in range(zones.size()):
		for j: int in range(i + 1, zones.size()):
			assert_false(
				zones[i].intersects(zones[j]),
				"zone %d %s overlaps zone %d %s" % [i, zones[i], j, zones[j]]
			)


## And every zone stays inside the view. An anchor fraction above 1.0 puts a
## station off-screen, which a headless test would otherwise report as present
## and correct.
func test_every_preparation_zone_stays_within_the_view() -> void:
	var view := Rect2(0.0, 0.0, 1.0, 1.0)
	for zone: Rect2 in _all_zones():
		assert_true(view.encloses(zone), "%s is outside the view" % zone)


## Not layout, but it belongs beside the scene it names and the other file is
## at the 20-public-method cap.
##
## This screen is now the game's main scene. A `main_scene` pointing at a path
## that no longer exists fails only when somebody launches the game, and a
## `main_scene` pointing at the *old* screen fails even more quietly -- it just
## runs the wrong one. Both are caught here.
func test_the_project_launches_this_screen() -> void:
	# `get_setting` returns Variant, and `String(Variant)` is a parse error under
	# warnings-as-errors -- which took the whole file out of the run rather than
	# failing one test, so GUT reported 237 passing instead of 245.
	var setting: Variant = ProjectSettings.get_setting("application/run/main_scene")
	var main_scene: String = str(setting)
	assert_eq(
		main_scene,
		"res://adapters/godot_ui/kitchen_screen.tscn",
		"the project's main scene is this screen"
	)
	var packed: PackedScene = load(main_scene)
	assert_not_null(packed, "and that path still resolves to a scene")
	var instance: Node = packed.instantiate()
	add_child_autofree(instance)
	assert_true(instance is KitchenScreen)


## Refills the real worktop with `count` synthetic ingredients in `group`,
## through the same `_ingredient_block` path the game uses, so what is measured
## is the shipping station rather than a scratch container.
func _restock(group: StringName, count: int) -> void:
	var slot: HFlowContainer = _screen._station_slots[group]
	for child: Node in slot.get_children():
		slot.remove_child(child)
		child.queue_free()
	for index: int in range(count):
		var mock := IngredientDefinition.new()
		mock.content_id = StringName("ingredient.mock_%d" % index)
		mock.name_key = StringName("ingredient.mock_%d.name" % index)
		mock.group = group
		slot.add_child(_screen._ingredient_block(mock))


## The zones are sized for today's 2/2/3/5 split, and #24 triples the pantry
## without saying how it lands. A station given far more than it was drawn for
## must **scroll**, not clip and not push its neighbours off the worktop.
##
## 20 into `heat_and_ferment` is the worst case on purpose: it is the narrowest
## station, 0.15 of the width, so its blocks wrap one per row and the overflow
## is entirely vertical.
func test_a_station_scrolls_rather_than_clipping_when_overstocked() -> void:
	await _enter_preparation()
	_restock(&"heat_and_ferment", 20)
	await wait_process_frames(2)

	var slot: HFlowContainer = _screen._station_slots[&"heat_and_ferment"]
	var scroll: ScrollContainer = slot.get_parent() as ScrollContainer
	assert_not_null(scroll, "the station's items sit inside a ScrollContainer")
	assert_eq(slot.get_child_count(), 20, "every block is present, not dropped")
	assert_gt(
		slot.size.y,
		scroll.size.y,
		"the content is taller than its station, so there is something to scroll"
	)
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.size.y, "and it is scrollable")


## An uneven distribution, which is the shape a tripled pantry is most likely to
## arrive in: one station carrying almost everything while others hold one item.
## Every block must still be reachable and still meet the interaction floor.
func test_an_uneven_distribution_keeps_every_block_reachable() -> void:
	await _enter_preparation()
	_restock(&"staple", 1)
	_restock(&"broth_and_fat", 1)
	_restock(&"heat_and_ferment", 2)
	_restock(&"fresh_and_cured", 20)
	await wait_process_frames(2)

	var floor_size: float = IngredientBlock.MIN_INTERACTION_TARGET
	var total: int = 0
	for group: StringName in IngredientDefinition.GROUPS:
		var slot: HFlowContainer = _screen._station_slots[group]
		total += slot.get_child_count()
		for child: Node in slot.get_children():
			var block := child as IngredientBlock
			assert_not_null(block, "every child of a station is a block")
			assert_gte(block.size.x, floor_size, "%s stays hittable" % block.content_id)
			assert_gte(block.size.y, floor_size, "%s stays hittable" % block.content_id)
	assert_eq(total, 24, "1/1/2/20 all present")


## Stations must not grow to fit their contents. The zones are the layout, and a
## station that expanded would overrun the pass and its neighbours -- which is
## the failure the ScrollContainer exists to prevent, so it is worth asserting
## rather than assuming.
func test_an_overstocked_station_does_not_grow_past_its_zone() -> void:
	await _enter_preparation()
	var before: Vector2 = (
		(_screen._station_slots[&"staple"].get_parent().get_parent().get_parent() as Control).size
	)

	_restock(&"staple", 20)
	await wait_process_frames(2)

	var after: Vector2 = (
		(_screen._station_slots[&"staple"].get_parent().get_parent().get_parent() as Control).size
	)
	assert_eq(after, before, "the station kept its zone")


## Overflow is only usable if an offscreen block can be *reached*. The focus
## chain walks every block in pantry order, so on an overstocked shelf it will
## hand focus to one that is scrolled out of sight -- and `ScrollContainer`
## does not follow focus unless told to, which makes the default a silent trap
## rather than a missing nicety.
func test_focusing_an_offscreen_ingredient_scrolls_it_into_view() -> void:
	await _enter_preparation()
	_restock(&"heat_and_ferment", 20)
	await wait_process_frames(2)

	var slot: HFlowContainer = _screen._station_slots[&"heat_and_ferment"]
	var scroll: ScrollContainer = slot.get_parent() as ScrollContainer
	assert_eq(scroll.scroll_vertical, 0, "the shelf starts at the top")

	var last := slot.get_child(slot.get_child_count() - 1) as IngredientBlock
	assert_gt(
		last.position.y,
		scroll.size.y,
		"the last block really is below the fold, or this test proves nothing"
	)

	last.grab_focus()
	await wait_process_frames(2)

	assert_gt(scroll.scroll_vertical, 0, "the shelf scrolled to follow focus")
	var visible_top: float = float(scroll.scroll_vertical)
	var visible_bottom: float = visible_top + scroll.size.y
	assert_gte(last.position.y, visible_top, "the focused block is not above the fold")
	assert_lte(last.position.y + last.size.y, visible_bottom, "nor below it")
