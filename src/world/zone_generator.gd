class_name ZoneGenerator
extends RefCounted
## Deterministic forest-and-burrow semantic generation. This class intentionally
## has no scene, input, camera, player-ownership, or networking dependencies.

const ZoneStateData = preload("res://src/world/zone_state.gd")
const NameGeneratorData = preload("res://src/naming/name_generator.gd")
const TERRITORY_NAMING_PROFILE = preload("res://content/naming/arachnid_proto.tres")

const FOREST_FLOOR: StringName = &"forest_floor"
const TREE_BLOCK: StringName = &"tree_block"
const BURROW_FLOOR: StringName = &"burrow_floor"
const BURROW_WALL: StringName = &"burrow_wall"
const CLIMBABLE_WALL: StringName = &"climbable_wall"
const SMALL_GAP: StringName = &"small_gap"
const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const TRAVERSABLE_TYPES: Array[StringName] = [FOREST_FLOOR, BURROW_FLOOR, CLIMBABLE_WALL, SMALL_GAP]

func generate(seed: int, width: int, height: int) -> ZoneStateData:
	var zone := ZoneStateData.new()
	zone.resize(maxi(width, 16), maxi(height, 16), FOREST_FLOOR)

	var layout_rng := _make_rng(seed, 0x45A1)
	var player_spawn := Vector2i(zone.width / 2, maxi(4, zone.height / 5))
	_generate_forest(zone, seed, player_spawn)
	var burrow_floor_cells := _generate_burrow(zone, layout_rng)
	var nest := _select_nest(burrow_floor_cells, zone, layout_rng)
	_carve_connection(zone, player_spawn, nest)
	_mark_climbable_boundaries(zone)
	_add_small_gaps(zone, layout_rng)

	zone.nest_candidates.assign([nest])
	zone.spawn_points = _select_spawn_points(zone, player_spawn, layout_rng)
	zone.territory_name = NameGeneratorData.generate(
		TERRITORY_NAMING_PROFILE,
		&"territory_descriptor",
		_make_rng(seed, 0x71C3)
	)
	return zone

func _generate_forest(zone: ZoneStateData, seed: int, player_spawn: Vector2i) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = _fold_seed(seed, 0x18B7)
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.085
	noise.fractal_octaves = 3
	var burrow_top := zone.height * 2 / 3
	for y in burrow_top:
		for x in zone.width:
			var position := Vector2i(x, y)
			var in_spawn_clearing := absi(x - player_spawn.x) <= 3 and absi(y - player_spawn.y) <= 3
			var on_open_border := x == 0 or y == 0 or x == zone.width - 1
			if not in_spawn_clearing and not on_open_border and noise.get_noise_2d(x, y) > 0.12:
				zone.set_cell(position, TREE_BLOCK)

func _generate_burrow(zone: ZoneStateData, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var top := zone.height * 2 / 3
	var bottom := zone.height - 2
	var left := 2
	var right := zone.width - 3
	var walls := {}
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var position := Vector2i(x, y)
			var boundary := x == left or x == right or y == top or y == bottom
			walls[position] = boundary or rng.randf() < 0.44

	for _step in 4:
		var next_walls := walls.duplicate()
		for y in range(top + 1, bottom):
			for x in range(left + 1, right):
				var position := Vector2i(x, y)
				next_walls[position] = _neighbor_wall_count(position, walls) >= 5
		walls = next_walls

	# A small guaranteed chamber gives every valid dimension a stable burrow core;
	# the cellular automata still determine its surrounding shape.
	var chamber_center := Vector2i(
		rng.randi_range(zone.width / 3, zone.width * 2 / 3),
		rng.randi_range(top + 4, maxi(top + 4, bottom - 4))
	)
	for y in range(chamber_center.y - 3, chamber_center.y + 4):
		for x in range(chamber_center.x - 5, chamber_center.x + 6):
			var position := Vector2i(x, y)
			if x > left and x < right and y > top and y < bottom:
				walls[position] = false

	var core := _floor_component(chamber_center, walls, left, right, top, bottom)
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var position := Vector2i(x, y)
			zone.set_cell(position, BURROW_FLOOR if core.has(position) else BURROW_WALL)
	return _sorted_positions(core.keys())

func _neighbor_wall_count(position: Vector2i, walls: Dictionary) -> int:
	var count := 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if walls.get(position + Vector2i(offset_x, offset_y), true):
				count += 1
	return count

func _floor_component(start: Vector2i, walls: Dictionary, left: int, right: int, top: int, bottom: int) -> Dictionary:
	var visited := {start: true}
	var frontier: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		for direction in CARDINAL_DIRECTIONS:
			var next := current + direction
			if next.x <= left or next.x >= right or next.y <= top or next.y >= bottom:
				continue
			if not visited.has(next) and not walls.get(next, true):
				visited[next] = true
				frontier.append(next)
	return visited

func _select_nest(floor_cells: Array[Vector2i], zone: ZoneStateData, rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for position in floor_cells:
		var open_neighbors := 0
		for direction in CARDINAL_DIRECTIONS:
			if floor_cells.has(position + direction):
				open_neighbors += 1
		if open_neighbors == 4 and position.y >= zone.height * 3 / 4:
			candidates.append(position)
	if candidates.is_empty():
		candidates = floor_cells.duplicate()
	candidates.sort_custom(_position_less)
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _carve_connection(zone: ZoneStateData, start: Vector2i, goal: Vector2i) -> void:
	var current := start
	while current.y < goal.y:
		_set_corridor_cell(zone, current)
		current.y += 1
	while current.x != goal.x:
		_set_corridor_cell(zone, current)
		current.x += 1 if current.x < goal.x else -1
	while current.y != goal.y:
		_set_corridor_cell(zone, current)
		current.y += 1 if current.y < goal.y else -1
	_set_corridor_cell(zone, goal)

func _set_corridor_cell(zone: ZoneStateData, position: Vector2i) -> void:
	zone.set_cell(position, BURROW_FLOOR if position.y >= zone.height * 2 / 3 else FOREST_FLOOR)

func _mark_climbable_boundaries(zone: ZoneStateData) -> void:
	var climbable: Array[Vector2i] = []
	for y in zone.height:
		for x in zone.width:
			var position := Vector2i(x, y)
			if zone.cell_at(position) != BURROW_WALL:
				continue
			for direction in CARDINAL_DIRECTIONS:
				if zone.cell_at(position + direction) == BURROW_FLOOR:
					climbable.append(position)
					break
	for position in climbable:
		zone.set_cell(position, CLIMBABLE_WALL)

func _add_small_gaps(zone: ZoneStateData, rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = []
	for y in range(zone.height * 2 / 3, zone.height):
		for x in range(1, zone.width - 1):
			var position := Vector2i(x, y)
			if zone.cell_at(position) != CLIMBABLE_WALL:
				continue
			var horizontal_shortcut := _is_open(zone.cell_at(position + Vector2i.LEFT)) and _is_open(zone.cell_at(position + Vector2i.RIGHT))
			var vertical_shortcut := _is_open(zone.cell_at(position + Vector2i.UP)) and _is_open(zone.cell_at(position + Vector2i.DOWN))
			if horizontal_shortcut or vertical_shortcut:
				candidates.append(position)
	_shuffle_positions(candidates, rng)
	var gap_count := rng.randi_range(2, 4)
	for index in mini(gap_count, candidates.size()):
		zone.set_cell(candidates[index], SMALL_GAP)
	# Cellular boundaries can occasionally have no one-cell shortcuts. Place
	# deterministic marked gaps on remaining climbable boundary cells as fallback.
	if candidates.size() < 2:
		var fallback: Array[Vector2i] = []
		for y in range(zone.height * 2 / 3, zone.height):
			for x in zone.width:
				var position := Vector2i(x, y)
				if zone.cell_at(position) == CLIMBABLE_WALL:
					fallback.append(position)
		_shuffle_positions(fallback, rng)
		for index in mini(2 - candidates.size(), fallback.size()):
			zone.set_cell(fallback[index], SMALL_GAP)

func _select_spawn_points(zone: ZoneStateData, player: Vector2i, rng: RandomNumberGenerator) -> Dictionary:
	var reachable := _reachable_cells(zone, player)
	var candidates: Array[Vector2i] = []
	for position: Vector2i in reachable:
		if zone.cell_at(position) == FOREST_FLOOR and _manhattan(position, player) >= 8:
			candidates.append(position)
	_shuffle_positions(candidates, rng)
	var used := {player: true}
	var food := _take_spawns(candidates, player, 8, 3, used)
	var predator := _take_spawns(candidates, player, 18, 1, used)
	var social_group := _take_spawns(candidates, player, 12, 3, used)
	return {
		&"player": player,
		&"food": food,
		&"predator": predator,
		&"social_group": social_group,
	}

func _take_spawns(candidates: Array[Vector2i], player: Vector2i, minimum_distance: int, count: int, used: Dictionary) -> Array[Vector2i]:
	var selected: Array[Vector2i] = []
	for position in candidates:
		if selected.size() >= count:
			break
		if not used.has(position) and _manhattan(position, player) >= minimum_distance:
			selected.append(position)
			used[position] = true
	return selected

func _reachable_cells(zone: ZoneStateData, start: Vector2i) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var visited := {start: true}
	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		for direction in CARDINAL_DIRECTIONS:
			var next := current + direction
			if zone.contains(next) and not visited.has(next) and _is_open(zone.cell_at(next)):
				visited[next] = true
				frontier.append(next)
	return frontier

func _is_open(cell_type: StringName) -> bool:
	return TRAVERSABLE_TYPES.has(cell_type)

func _shuffle_positions(values: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := values[index]
		values[index] = values[swap_index]
		values[swap_index] = held

func _sorted_positions(values: Array) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for value: Variant in values:
		positions.append(value)
	positions.sort_custom(_position_less)
	return positions

func _position_less(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _make_rng(seed: int, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _fold_seed(seed, salt)
	return rng

func _fold_seed(seed: int, salt: int) -> int:
	return int((seed * 1103515245 + salt * 12345) & 0x7fffffff)
