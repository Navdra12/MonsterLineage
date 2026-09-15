extends "res://tests/test_case.gd"

const ACTOR_SCRIPT_PATH := "res://src/creatures/creature_actor.gd"
const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const PLAYER_SPIDER = preload("res://content/species/player_spider.tres")
const SCARABKIN = preload("res://content/species/scarabkin.tres")
const MAIN_SCENE = preload("res://scenes/main.tscn")

var RegisteredSuitePaths: Array[String] = []
var _actor_script: Script
var _actors: Array[Node] = []

func run() -> void:
	_test_existing_suites_remain_registered()
	if not ResourceLoader.exists(ACTOR_SCRIPT_PATH):
		assert_true(false, "Task 6 requires the CreatureActor controller adapter")
		return
	_actor_script = load(ACTOR_SCRIPT_PATH) as Script
	if _actor_script == null or not _actor_script.can_instantiate():
		assert_true(false, "CreatureActor must compile and instantiate")
		return
	_test_body_plan_capability_traversal()
	_test_movement_uses_semantic_target_cells_and_normalized_direction()
	_test_movement_speed_uses_genome_age_and_leg_injury()
	_test_needs_progress_and_movement_costs_extra_energy()
	_test_starvation_damages_condition()
	_test_food_consumption_updates_needs_and_memory()
	_test_starvation_food_memory_is_stronger()
	_test_death_emits_once()
	_test_creature_state_remains_controller_independent()
	_test_main_spawns_an_individual_spider_at_the_semantic_spawn()
	_test_required_input_bindings()
	_free_actors()

func _test_existing_suites_remain_registered() -> void:
	var required: Array[String] = [
		"res://tests/test_rng_service.gd",
		"res://tests/test_localization_and_naming.gd",
		"res://tests/test_genome.gd",
		"res://tests/test_creature_state.gd",
		"res://tests/test_zone_generator.gd",
	]
	for suite_path: String in required:
		assert_true(RegisteredSuitePaths.has(suite_path), "full runner preserves suite %s" % suite_path)

func _test_body_plan_capability_traversal() -> void:
	var spider: Variant = _creature_from_species(PLAYER_SPIDER, &"spider_test", &"hatchling")
	var spider_actor: Variant = _new_actor(spider)
	for floor_type: StringName in [&"forest_floor", &"burrow_floor", &"climbable_wall", &"small_gap"]:
		assert_true(spider_actor.can_enter_cell(floor_type), "hatchling spider enters %s" % floor_type)
	for blocked_type: StringName in [&"tree_block", &"burrow_wall"]:
		assert_true(not spider_actor.can_enter_cell(blocked_type), "spider cannot enter %s" % blocked_type)

	var scarabkin: Variant = _creature_from_species(SCARABKIN, &"scarab_test", &"adult")
	var scarab_actor: Variant = _new_actor(scarabkin)
	assert_true(not scarab_actor.can_enter_cell(&"small_gap"), "scarabkin lacks the small-gap capability despite size class one")

	var data_driven: Variant = _creature_from_species(PLAYER_SPIDER, &"data_driven", &"adult")
	data_driven.species_id = &"not_a_spider_species"
	var data_actor: Variant = _new_actor(data_driven)
	assert_true(data_actor.can_enter_cell(&"climbable_wall"), "traversal follows body-plan data rather than species-name branching")

func _test_movement_speed_uses_genome_age_and_leg_injury() -> void:
	var creature: Variant = _creature_from_species(PLAYER_SPIDER, &"speed_test", &"adult")
	var actor: Variant = _new_actor(creature)
	var baseline: float = actor.movement_speed()
	creature.genome.set_value(&"move_speed", 1.5)
	var fast: float = actor.movement_speed()
	assert_true(fast > baseline, "higher move_speed genome trait raises actor speed")
	creature.age_stage = &"hatchling"
	var hatchling: float = actor.movement_speed()
	assert_true(hatchling < fast, "hatchling age modifier lowers movement speed")
	creature.age_stage = &"adult"
	var movement_effects: Array[StringName] = [&"impaired_movement"]
	creature.injuries.set_injury(&"legs", 0.8, movement_effects)
	assert_true(actor.movement_speed() < fast, "leg injury lowers movement speed")

func _test_movement_uses_semantic_target_cells_and_normalized_direction() -> void:
	var creature: Variant = _creature_from_species(PLAYER_SPIDER, &"semantic_mover", &"adult")
	var actor: Variant = _new_actor(creature)
	if not actor.has_method(&"velocity_for_direction"):
		assert_true(false, "movement exposes the semantic velocity calculation used by physics")
		return
	var zone := ZoneStateData.new()
	zone.resize(2, 2, &"forest_floor")
	actor.bind_zone(zone)
	actor.position = Vector2(8, 8)
	var diagonal: Vector2 = actor.velocity_for_direction(Vector2(1, 1), 0.05)
	assert_true(is_equal_approx(diagonal.length(), actor.movement_speed()), "directional movement is normalized")
	zone.set_cell(Vector2i(1, 0), &"tree_block")
	assert_eq(actor.velocity_for_direction(Vector2.RIGHT, 0.25), Vector2.ZERO, "semantic tree target blocks movement")
	zone.set_cell(Vector2i(1, 0), &"climbable_wall")
	assert_true(actor.velocity_for_direction(Vector2.RIGHT, 0.25).x > 0.0, "wall-crawl capability permits semantic climbable-wall movement")
	zone.set_cell(Vector2i(1, 0), &"small_gap")
	assert_true(actor.velocity_for_direction(Vector2.RIGHT, 0.25).x > 0.0, "small-gap capability permits semantic gap movement")

func _test_needs_progress_and_movement_costs_extra_energy() -> void:
	var resting: Variant = _creature_from_species(PLAYER_SPIDER, &"resting", &"adult")
	var moving: Variant = _creature_from_species(PLAYER_SPIDER, &"moving", &"adult")
	var resting_actor: Variant = _new_actor(resting)
	var moving_actor: Variant = _new_actor(moving)
	resting_actor.advance_survival(2.0, false)
	moving_actor.advance_survival(2.0, true)
	assert_true(resting.needs.hunger > 0.0, "physics survival progression raises hunger")
	assert_true(resting.needs.energy < 100.0, "physics survival progression drains energy")
	assert_true(moving.needs.energy < resting.needs.energy, "movement costs additional energy")

func _test_starvation_damages_condition() -> void:
	var creature: Variant = _creature_from_species(PLAYER_SPIDER, &"starving", &"adult")
	creature.needs.hunger = 90.0
	var actor: Variant = _new_actor(creature)
	actor.advance_survival(3.0, false)
	assert_true(creature.condition < 100.0, "hunger at or above ninety gradually damages condition")

func _test_food_consumption_updates_needs_and_memory() -> void:
	var creature: Variant = _creature_from_species(PLAYER_SPIDER, &"eater", &"adult")
	creature.needs.hunger = 70.0
	creature.needs.energy = 25.0
	var actor: Variant = _new_actor(creature)
	actor.consume_food(&"field_cricket", 12.0)
	assert_eq(creature.needs.hunger, 58.0, "nutrition reduces hunger")
	assert_true(creature.needs.energy > 25.0, "nutrition restores energy")
	assert_eq(creature.food_memory.get_entry(&"field_cricket").exposure, 1, "eating records FoodMemory exposure")
	assert_true(creature.food_memory.get_preference(&"field_cricket") > 0.0, "nutritious food records positive memory")

func _test_starvation_food_memory_is_stronger() -> void:
	var ordinary: Variant = _creature_from_species(PLAYER_SPIDER, &"ordinary_eater", &"adult")
	var starving: Variant = _creature_from_species(PLAYER_SPIDER, &"starving_eater", &"adult")
	ordinary.needs.hunger = 50.0
	starving.needs.hunger = 95.0
	var ordinary_actor: Variant = _new_actor(ordinary)
	var starving_actor: Variant = _new_actor(starving)
	ordinary_actor.consume_food(&"field_cricket", 5.0)
	starving_actor.consume_food(&"field_cricket", 5.0)
	assert_true(starving.food_memory.get_preference(&"field_cricket") > ordinary.food_memory.get_preference(&"field_cricket"), "starvation-save eating produces stronger positive food memory")

func _test_death_emits_once() -> void:
	var creature: Variant = _creature_from_species(PLAYER_SPIDER, &"doomed", &"adult")
	var actor: Variant = _new_actor(creature)
	var observed: Dictionary = {&"count": 0, &"id": StringName()}
	actor.died.connect(func(creature_id: StringName) -> void:
		observed[&"count"] = int(observed[&"count"]) + 1
		observed[&"id"] = creature_id
	)
	creature.condition = 0.0
	actor.advance_survival(1.0, false)
	actor.advance_survival(1.0, false)
	assert_eq(observed[&"count"], 1, "death signal is not emitted repeatedly")
	assert_eq(observed[&"id"], &"doomed", "death signal carries stable creature identity")

func _test_creature_state_remains_controller_independent() -> void:
	var creature := CreatureStateData.new()
	var forbidden: Array[StringName] = [
		&"player_number", &"player1", &"player2", &"peer_id", &"network_peer_id",
		&"network_owner", &"input", &"camera", &"ui", &"controller", &"ownership",
	]
	var properties: Array[StringName] = []
	for property: Dictionary in creature.get_property_list():
		properties.append(property.name)
	for property_name: StringName in forbidden:
		assert_true(not properties.has(property_name), "CreatureState excludes controller/ownership field %s" % property_name)

func _test_main_spawns_an_individual_spider_at_the_semantic_spawn() -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	var actor: Variant = main.get_node_or_null("CreatureActor")
	assert_true(actor != null, "Main instantiates one CreatureActor")
	if not main.has_method(&"create_starting_creature") or not main.has_method(&"cell_center"):
		assert_true(false, "Main exposes its pure starting-creature and spawn-coordinate composition")
		main.free()
		return
	var creature: Variant = main.create_starting_creature()
	if actor != null:
		assert_eq(creature.creature_id, &"creature_0001", "spawned creature has stable controller-neutral identity")
		assert_true(not String(creature.creature_id).contains("player"), "creature identity does not encode player ownership")
		assert_eq(creature.species_id, &"player_spider", "spawned creature has stable species identity")
		assert_eq(creature.age_stage, &"hatchling", "spawned creature starts as hatchling")
		assert_true(creature.genome != PLAYER_SPIDER.base_genome, "spawn clones rather than mutating shared species genome")
		var zone: Variant = ZoneGeneratorData.new().generate(424242, 64, 64)
		var expected_position := Vector2(zone.spawn_points[&"player"] * 16) + Vector2(8, 8)
		assert_eq(main.cell_center(zone.spawn_points[&"player"]), expected_position, "Main maps semantic spawn cells to 16x16 cell centers")
	main.free()

func _test_required_input_bindings() -> void:
	_assert_action_keys(&"move_up", [KEY_W, KEY_UP])
	_assert_action_keys(&"move_down", [KEY_S, KEY_DOWN])
	_assert_action_keys(&"move_left", [KEY_A, KEY_LEFT])
	_assert_action_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_assert_action_keys(&"slow_time", [KEY_SHIFT])
	var left_shift_found := false
	for event: InputEvent in InputMap.action_get_events(&"slow_time"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			left_shift_found = left_shift_found or (key_event.physical_keycode == KEY_SHIFT and key_event.location == 1)
	assert_true(left_shift_found, "slow_time is bound specifically to Left Shift")

func _assert_action_keys(action: StringName, expected_keys: Array) -> void:
	var actual: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			actual.append((event as InputEventKey).physical_keycode)
	for expected: Key in expected_keys:
		assert_true(actual.has(expected), "%s includes physical key %s" % [action, expected])

func _creature_from_species(species: Resource, creature_id: StringName, age_stage: StringName) -> Variant:
	var creature := CreatureStateData.new()
	creature.creature_id = creature_id
	creature.species_id = species.id
	creature.genome = species.base_genome.clone_genome()
	creature.age_stage = age_stage
	return creature

func _new_actor(creature: Variant) -> Variant:
	var actor: Node = _actor_script.new()
	actor.bind_state(creature)
	_actors.append(actor)
	return actor

func _free_actors() -> void:
	for actor: Node in _actors:
		actor.free()
	_actors.clear()
