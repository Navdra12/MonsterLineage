extends "res://tests/test_case.gd"

const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const GeneratedNameData = preload("res://src/naming/generated_name.gd")
const MAIN_SCENE = preload("res://scenes/main.tscn")

const REQUIRED_CELL_TYPES: Array[StringName] = [
	&"forest_floor",
	&"tree_block",
	&"burrow_floor",
	&"burrow_wall",
	&"climbable_wall",
	&"small_gap",
]
const TRAVERSABLE_CELL_TYPES: Array[StringName] = [
	&"forest_floor",
	&"burrow_floor",
	&"climbable_wall",
	&"small_gap",
]

func run() -> void:
	_test_main_scene_loads_without_generated_class_cache()
	_test_same_seed_reproduces_zone()
	_test_different_seeds_vary_zone()
	_test_required_terrain_and_semantic_locations()
	_test_player_reaches_food_spawn()
	_test_generation_is_finite_for_seed_range()
	_test_zone_data_is_scene_independent()

func _test_main_scene_loads_without_generated_class_cache() -> void:
	assert_true(MAIN_SCENE.can_instantiate(), "main scene and world presentation load from explicit source dependencies")
	for script_path in ["res://src/game/main.gd", "res://src/world/world_view.gd"]:
		var script := load(script_path) as Script
		assert_true(script != null and script.can_instantiate(), "%s compiles without generated cache state" % script_path)

func _test_same_seed_reproduces_zone() -> void:
	var first: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)
	var second: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)

	assert_eq(first.width, 64, "generated zone preserves requested width")
	assert_eq(first.height, 64, "generated zone preserves requested height")
	assert_eq(first.cells, second.cells, "same seed and dimensions reproduce every semantic cell")
	assert_eq(first.spawn_points, second.spawn_points, "same seed and dimensions reproduce semantic spawns")
	assert_eq(first.nest_candidates, second.nest_candidates, "same seed and dimensions reproduce nest candidates")
	assert_eq(first.territory_name.kind, second.territory_name.kind, "same seed reproduces territory name kind")
	assert_eq(first.territory_name.profile_id, second.territory_name.profile_id, "same seed reproduces territory name profile")
	assert_eq(first.territory_name.semantic_tokens, second.territory_name.semantic_tokens, "same seed reproduces territory name tokens")

func _test_different_seeds_vary_zone() -> void:
	var first: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)
	var second: Variant = ZoneGeneratorData.new().generate(424243, 64, 64)
	var changed_cells := 0
	for index in first.cells.size():
		if first.cells[index] != second.cells[index]:
			changed_cells += 1
	assert_true(changed_cells >= 64, "adjacent seeds meaningfully vary at least one row worth of cells")
	assert_true(first.spawn_points != second.spawn_points or first.nest_candidates != second.nest_candidates, "different seeds vary generated locations")

func _test_required_terrain_and_semantic_locations() -> void:
	var zone: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)
	for cell_type: StringName in REQUIRED_CELL_TYPES:
		assert_true(zone.cells.has(cell_type), "64x64 zone contains semantic cell type %s" % cell_type)
	var gap_count: int = zone.cells.count(&"small_gap")
	assert_true(gap_count >= 2 and gap_count <= 4, "zone contains two to four deterministic small-gap shortcuts")
	assert_true(not zone.nest_candidates.is_empty(), "zone contains at least one safe nest candidate")
	assert_true(zone.territory_name is GeneratedNameData, "zone stores a semantic GeneratedName territory name")
	assert_eq(zone.territory_name.kind, &"territory_descriptor", "territory name uses the semantic territory kind")

	assert_true(zone.spawn_points.has(&"player"), "zone provides a player spawn")
	for spawn_kind: StringName in [&"food", &"predator", &"social_group"]:
		assert_true(zone.spawn_points.has(spawn_kind), "zone provides %s spawn collection" % spawn_kind)
		if zone.spawn_points.has(spawn_kind):
			assert_true(not zone.spawn_points[spawn_kind].is_empty(), "%s spawn collection is not empty" % spawn_kind)

	if zone.spawn_points.has(&"player"):
		var player: Vector2i = zone.spawn_points[&"player"]
		assert_true(_in_bounds(zone, player), "player spawn is inside zone")
		assert_true(TRAVERSABLE_CELL_TYPES.has(zone.cell_at(player)), "player spawn is traversable")
		for offset_y in range(-3, 4):
			for offset_x in range(-3, 4):
				var clearing_cell := player + Vector2i(offset_x, offset_y)
				assert_true(_in_bounds(zone, clearing_cell), "7x7 spawn clearing remains inside zone")
				if _in_bounds(zone, clearing_cell):
					assert_true(zone.cell_at(clearing_cell) != &"tree_block", "7x7 player clearing contains no tree blocks")

	for nest: Vector2i in zone.nest_candidates:
		assert_true(_in_bounds(zone, nest), "nest candidate is inside zone")
		assert_eq(zone.cell_at(nest), &"burrow_floor", "nest candidate is safe burrow floor")

func _test_player_reaches_food_spawn() -> void:
	var zone: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)
	if not zone.spawn_points.has(&"player") or not zone.spawn_points.has(&"food") or zone.spawn_points[&"food"].is_empty():
		assert_true(false, "connectivity test requires player and food spawns")
		return
	var player: Vector2i = zone.spawn_points[&"player"]
	var food: Vector2i = zone.spawn_points[&"food"][0]
	assert_true(_has_traversable_path(zone, player, food), "player spawn connects to at least one food/prey spawn")
	assert_true(_manhattan(player, food) >= 8, "food spawn keeps a sensible minimum distance from player")
	if zone.spawn_points.has(&"predator") and not zone.spawn_points[&"predator"].is_empty():
		assert_true(_manhattan(player, zone.spawn_points[&"predator"][0]) >= 18, "predator spawn keeps a safe minimum distance from player")
	if zone.spawn_points.has(&"social_group") and not zone.spawn_points[&"social_group"].is_empty():
		assert_true(_manhattan(player, zone.spawn_points[&"social_group"][0]) >= 12, "social group spawn keeps a sensible minimum distance from player")

func _test_generation_is_finite_for_seed_range() -> void:
	var signatures: Array[int] = []
	for seed in range(24):
		var zone: Variant = ZoneGeneratorData.new().generate(seed, 64, 64)
		assert_eq(zone.cells.size(), 64 * 64, "seed %d terminates with a complete grid" % seed)
		assert_true(not zone.nest_candidates.is_empty(), "seed %d terminates with a nest" % seed)
		signatures.append(hash(zone.cells))
	var unique_signatures := {}
	for signature in signatures:
		unique_signatures[signature] = true
	assert_true(unique_signatures.size() >= 20, "finite seed sweep produces broad deterministic variation")

func _test_zone_data_is_scene_independent() -> void:
	var zone: Variant = ZoneStateData.new()
	var generator: Variant = ZoneGeneratorData.new()
	assert_true(zone is RefCounted, "ZoneState is pure reference-counted simulation data")
	assert_true(not (zone is Node), "ZoneState is not a scene node")
	assert_true(generator is RefCounted, "ZoneGenerator is headless reference-counted logic")
	assert_true(not (generator is Node), "ZoneGenerator is not a scene node")
	var forbidden: Array[StringName] = [
		&"player_number", &"player1", &"player2", &"network_peer_id", &"network_owner",
		&"input", &"camera", &"ui", &"tile_map", &"scene_owner", &"current_zone_id",
	]
	var property_names: Array[StringName] = []
	for property: Dictionary in zone.get_property_list():
		property_names.append(property.name)
	for property_name: StringName in forbidden:
		assert_true(not property_names.has(property_name), "ZoneState excludes ownership/presentation field %s" % property_name)

func _has_traversable_path(zone: Variant, start: Vector2i, goal: Vector2i) -> bool:
	var frontier: Array[Vector2i] = [start]
	var visited := {start: true}
	var cursor := 0
	while cursor < frontier.size():
		var current: Vector2i = frontier[cursor]
		cursor += 1
		if current == goal:
			return true
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := current + direction
			if _in_bounds(zone, next) and not visited.has(next) and TRAVERSABLE_CELL_TYPES.has(zone.cell_at(next)):
				visited[next] = true
				frontier.append(next)
	return false

func _in_bounds(zone: Variant, position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < zone.width and position.y < zone.height

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
