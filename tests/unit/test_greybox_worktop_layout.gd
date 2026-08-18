## The preparation view's spatial layout, per #44.
##
## Split out of `test_greybox_kitchen_screen.gd` only because that file hit the
## 20-public-method lint cap. These are layout claims rather than flow claims:
## that the worktop is a place with stations around a dominant centre, and not
## the three stacked bands it replaced.
##
## What a headless run can check is geometry, containment, and focus wiring.
## Whether it *reads* as a workspace is the five-second recall test, and only a
## person can run that.
extends GutTest

var _screen: GreyboxKitchenScreen = null


func before_each() -> void:
	_screen = GreyboxKitchenScreen.new()
	add_child_autofree(_screen)


func _find_block(ingredient_id: StringName) -> GreyboxIngredientBlock:
	for block: GreyboxIngredientBlock in _screen._ingredient_blocks:
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
	var floor_size: float = GreyboxKitchenScreen.MIN_INTERACTION_TARGET
	for block: GreyboxIngredientBlock in _screen._ingredient_blocks:
		assert_gte(
			block.custom_minimum_size.x,
			floor_size,
			(
				"%s is %d wide, under the %d floor"
				% [block.content_id, block.custom_minimum_size.x, floor_size]
			)
		)
		assert_gte(
			block.custom_minimum_size.y,
			floor_size,
			(
				"%s is %d tall, under the %d floor"
				% [block.content_id, block.custom_minimum_size.y, floor_size]
			)
		)


## Silhouettes must actually differ, or the "varied to look at" half of the
## rule is decoration. Two distinct shapes would technically satisfy "varied";
## this requires one per station, which is what the design claims.
func test_the_stations_do_not_all_share_one_silhouette() -> void:
	var shapes: Dictionary[Vector2, bool] = {}
	for block: GreyboxIngredientBlock in _screen._ingredient_blocks:
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
		var block: GreyboxIngredientBlock = _find_block(ingredient.content_id)
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
	var pass_area: float = (
		GreyboxKitchenScreen._PASS_ZONE.size.x * GreyboxKitchenScreen._PASS_ZONE.size.y
	)
	for group: StringName in IngredientDefinition.GROUPS:
		var zone: Rect2 = GreyboxKitchenScreen._STATION_ZONE[group]
		assert_gt(
			pass_area, zone.size.x * zone.size.y, "the pass is larger than the %s station" % group
		)
	for zone: Rect2 in [GreyboxKitchenScreen._TICKET_ZONE, GreyboxKitchenScreen._INSPECTION_ZONE]:
		assert_gt(
			pass_area, zone.size.x * zone.size.y, "the pass is larger than the reference column"
		)


## Explicit focus neighbours, closing into a loop through Serve, so a
## keyboard-only player can always reach the commit and Tab never dead-ends.
## Godot's automatic guess is geometric, and with four stations around a centre
## it hops in an order matching nothing on screen.
func test_the_focus_chain_is_explicit_and_closes_through_serve() -> void:
	var blocks: Array[GreyboxIngredientBlock] = _screen._ingredient_blocks
	assert_gt(blocks.size(), 0, "there are blocks to chain")
	for index: int in range(blocks.size() - 1):
		assert_eq(
			blocks[index].focus_next,
			blocks[index + 1].get_path(),
			"block %d hands focus to block %d" % [index, index + 1]
		)
	var last: GreyboxIngredientBlock = blocks[blocks.size() - 1]
	assert_eq(last.focus_next, _screen._serve_button.get_path(), "the last block reaches Serve")
	assert_eq(
		_screen._serve_button.focus_next, blocks[0].get_path(), "Serve wraps back to the pantry"
	)
	assert_eq(
		blocks[0].focus_previous, _screen._serve_button.get_path(), "and backwards from the first"
	)


## Every zone in the preparation view, in the order they are declared.
func _all_zones() -> Array[Rect2]:
	var zones: Array[Rect2] = [
		GreyboxKitchenScreen._TICKET_ZONE,
		GreyboxKitchenScreen._INSPECTION_ZONE,
		GreyboxKitchenScreen._PASS_ZONE,
	]
	for group: StringName in IngredientDefinition.GROUPS:
		zones.append(GreyboxKitchenScreen._STATION_ZONE[group])
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
