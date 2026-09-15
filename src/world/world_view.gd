class_name WorldView
extends Node2D
## Presentation adapter for ZoneState. Semantic generation remains entirely in
## ZoneGenerator; this node only paints cells and exposes traversal metadata.

const ZoneStateData = preload("res://src/world/zone_state.gd")
const TILE_SOURCE_PATH := "res://assets/prototype/tiles.svg"

const CELL_SIZE := Vector2i(16, 16)
const BLOCKED_TYPES: Array[StringName] = [&"tree_block", &"burrow_wall"]
const TILE_COORDS := {
	&"forest_floor": Vector2i(0, 0),
	&"tree_block": Vector2i(1, 0),
	&"burrow_floor": Vector2i(2, 0),
	&"burrow_wall": Vector2i(3, 0),
	&"climbable_wall": Vector2i(4, 0),
	&"small_gap": Vector2i(5, 0),
}

@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var blocked_cells: StaticBody2D = $BlockedCells
@onready var semantic_areas: Node2D = $SemanticAreas

func build_from_state(zone: ZoneStateData) -> void:
	_clear_generated_presentation()
	var source_id := _ensure_tile_set()
	for y in zone.height:
		for x in zone.width:
			var position := Vector2i(x, y)
			var cell_type := zone.cell_at(position)
			if TILE_COORDS.has(cell_type):
				tile_layer.set_cell(position, source_id, TILE_COORDS[cell_type])
			if BLOCKED_TYPES.has(cell_type):
				_add_blocked_collision(position, cell_type)
			elif cell_type == &"climbable_wall" or cell_type == &"small_gap":
				_add_semantic_area(position, cell_type)

func _ensure_tile_set() -> int:
	if tile_layer.tile_set != null and tile_layer.tile_set.get_source_count() > 0:
		return tile_layer.tile_set.get_source_id(0)
	var tile_set := TileSet.new()
	tile_set.tile_size = CELL_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = _load_tile_texture()
	atlas.texture_region_size = CELL_SIZE
	for x in TILE_COORDS.size():
		atlas.create_tile(Vector2i(x, 0))
	var source_id := tile_set.add_source(atlas)
	tile_layer.tile_set = tile_set
	return source_id

func _load_tile_texture() -> ImageTexture:
	var svg_source := FileAccess.get_file_as_string(TILE_SOURCE_PATH)
	var image := Image.new()
	var load_error := image.load_svg_from_string(svg_source)
	if load_error != OK:
		push_error("Unable to decode prototype tile SVG: %s" % error_string(load_error))
		return null
	return ImageTexture.create_from_image(image)

func _clear_generated_presentation() -> void:
	tile_layer.clear()
	for child in blocked_cells.get_children():
		child.queue_free()
	for child in semantic_areas.get_children():
		child.queue_free()

func _add_blocked_collision(cell_position: Vector2i, cell_type: StringName) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE)
	collision.shape = shape
	collision.position = Vector2(cell_position * CELL_SIZE) + Vector2(CELL_SIZE) * 0.5
	collision.set_meta(&"cell_position", cell_position)
	collision.set_meta(&"cell_type", cell_type)
	blocked_cells.add_child(collision)

func _add_semantic_area(cell_position: Vector2i, cell_type: StringName) -> void:
	var area := Area2D.new()
	area.position = Vector2(cell_position * CELL_SIZE) + Vector2(CELL_SIZE) * 0.5
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta(&"cell_position", cell_position)
	area.set_meta(&"cell_type", cell_type)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE)
	collision.shape = shape
	area.add_child(collision)
	semantic_areas.add_child(area)
