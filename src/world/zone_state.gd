class_name ZoneState
extends RefCounted
## Pure semantic state for one generated zone. Scene nodes consume this data but
## never become part of its identity or ownership.

const GeneratedNameData = preload("res://src/naming/generated_name.gd")

var width: int
var height: int
var cells: Array[StringName] = []
var spawn_points: Dictionary = {}
var nest_candidates: Array[Vector2i] = []
var territory_name: GeneratedNameData

func resize(new_width: int, new_height: int, fill_type: StringName = &"forest_floor") -> void:
	width = maxi(new_width, 0)
	height = maxi(new_height, 0)
	cells.clear()
	cells.resize(width * height)
	cells.fill(fill_type)

func contains(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < width and position.y < height

func cell_at(position: Vector2i) -> StringName:
	if not contains(position):
		return &""
	return cells[position.y * width + position.x]

func set_cell(position: Vector2i, cell_type: StringName) -> void:
	if contains(position):
		cells[position.y * width + position.x] = cell_type
