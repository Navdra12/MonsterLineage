extends "res://tests/test_case.gd"

const WEB_SYSTEM_PATH := "res://src/gameplay/web/web_system.gd"
const WEB_SEGMENT_PATH := "res://src/gameplay/web/web_segment.gd"
const CREATURE_ACTOR_PATH := "res://src/creatures/creature_actor.gd"
const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const PLAYER_SPIDER = preload("res://content/species/player_spider.tres")
const FIELD_CRICKET = preload("res://content/species/field_cricket.tres")
const MAIN_SCENE = preload("res://scenes/main.tscn")

var RegisteredSuitePaths: Array[String] = []
var _web_system_script: Script
var _actor_script: Script
var _nodes: Array[Node] = []

func run() -> void:
	_test_all_previous_suites_remain_registered()
	if not ResourceLoader.exists(WEB_SYSTEM_PATH) or not ResourceLoader.exists(WEB_SEGMENT_PATH):
		assert_true(false, "Task 7 requires the web system and web segment scripts")
		return
	_web_system_script = load(WEB_SYSTEM_PATH) as Script
	_actor_script = load(CREATURE_ACTOR_PATH) as Script
	if _web_system_script == null or not _web_system_script.can_instantiate():
		assert_true(false, "WebSystem must compile and instantiate")
		return
	_test_genome_traits_map_to_segment_stats()
	_test_placement_preserves_world_coordinates()
	_test_larger_targets_receive_less_restraint()
	_test_placement_range_and_semantic_terrain()
	_test_silk_cost_rejection_and_fed_regeneration()
	_test_owner_is_ignored_and_intruder_emits_stable_ids()
	_test_restraint_is_transient_and_breakage_clears_it()
	_test_struggle_reduces_durability()
	_test_vibration_memory_obeys_genome_sensory_range()
	_test_creature_state_has_no_player_or_network_ownership()
	_test_manual_composition_uses_left_mouse_and_non_ai_cricket()
	_free_nodes()

func _test_all_previous_suites_remain_registered() -> void:
	var required: Array[String] = [
		"res://tests/test_rng_service.gd",
		"res://tests/test_localization_and_naming.gd",
		"res://tests/test_genome.gd",
		"res://tests/test_creature_state.gd",
		"res://tests/test_zone_generator.gd",
		"res://tests/test_ui_models.gd",
	]
	for suite_path: String in required:
		assert_true(RegisteredSuitePaths.has(suite_path), "full runner preserves suite %s" % suite_path)

func _test_genome_traits_map_to_segment_stats() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"weaver")
	owner.genome.set_value(&"web_strength", 1.3)
	owner.genome.set_value(&"web_adhesion", 1.2)
	var context := _web_context(owner, Vector2(24, 24))
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	assert_true(segment != null, "valid placement produces a segment")
	if segment != null:
		assert_eq(segment.owner_id, &"weaver", "segment stores stable creature ownership")
		assert_eq(segment.strength, 1.3, "web_strength maps to segment strength")
		assert_eq(segment.adhesion, 1.2, "web_adhesion maps to segment adhesion")
		assert_true(is_equal_approx(segment.durability, 13.0), "initial durability derives from strength")

func _test_placement_preserves_world_coordinates() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"world_space_owner")
	var context := _web_context(owner, Vector2(24, 24))
	context.system.position = Vector2(100, 80)
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	assert_true(segment != null, "world-space placement remains valid under a transformed system")
	if segment != null:
		assert_eq(segment.global_position, Vector2(40, 24), "place_web keeps its world_position contract")

func _test_larger_targets_receive_less_restraint() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"restraint_owner")
	owner.genome.set_value(&"web_adhesion", 1.2)
	var context := _web_context(owner, Vector2(24, 24))
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	if segment == null:
		assert_true(false, "restraint comparison requires a valid web")
		return
	var small_multiplier: float = segment.restraint_multiplier(0.5)
	var large_multiplier: float = segment.restraint_multiplier(2.0)
	segment.adhesion = 0.6
	var weaker_adhesion_multiplier: float = segment.restraint_multiplier(0.5)
	assert_true(small_multiplier >= 0.0, "restraint multiplier never creates negative speed")
	assert_true(small_multiplier < large_multiplier, "larger bodies receive less restraint")
	assert_true(small_multiplier < weaker_adhesion_multiplier, "stronger adhesion increases restraint")
	assert_true(large_multiplier <= 1.0, "restraint multiplier remains bounded")

func _test_placement_range_and_semantic_terrain() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"placer")
	var context := _web_context(owner, Vector2(24, 24))
	assert_eq(context.system.place_web(owner, Vector2(73, 24), Vector2.UP), null, "placement beyond 48 pixels is rejected")
	context.zone.set_cell(Vector2i(2, 1), &"tree_block")
	assert_eq(context.system.place_web(owner, Vector2(40, 24), Vector2.UP), null, "tree blocks reject placement")
	context.zone.set_cell(Vector2i(2, 1), &"burrow_wall")
	assert_eq(context.system.place_web(owner, Vector2(40, 24), Vector2.UP), null, "burrow walls reject placement")
	context.zone.set_cell(Vector2i(2, 1), &"forest_floor")
	assert_true(context.system.place_web(owner, Vector2(40, 24), Vector2.UP) != null, "traversable floor accepts placement")

	var climb_owner: Variant = _creature(PLAYER_SPIDER, &"climb_placer")
	var climb_context := _web_context(climb_owner, Vector2(24, 24))
	climb_context.zone.set_cell(Vector2i(2, 1), &"climbable_wall")
	assert_true(climb_context.system.place_web(climb_owner, Vector2(40, 24), Vector2.RIGHT) != null, "climbable terrain accepts placement")

func _test_silk_cost_rejection_and_fed_regeneration() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"silk_owner")
	var context := _web_context(owner, Vector2(24, 24))
	var initial: float = context.system.silk_reserve(owner.creature_id)
	var placed: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	assert_true(placed != null, "available silk permits placement")
	var after_placement: float = context.system.silk_reserve(owner.creature_id)
	assert_true(after_placement < initial, "successful placement consumes silk")
	var attempts := 0
	while attempts < 20 and context.system.place_web(owner, Vector2(40, 24), Vector2.UP) != null:
		attempts += 1
	assert_true(attempts < 20, "insufficient silk eventually rejects placement")
	var depleted: float = context.system.silk_reserve(owner.creature_id)
	owner.needs.hunger = 20.0
	context.system.advance_silk(owner, 10.0)
	assert_true(context.system.silk_reserve(owner.creature_id) > depleted, "fed creatures regenerate silk")
	context.system.advance_silk(owner, 10000.0)
	assert_true(is_equal_approx(context.system.silk_reserve(owner.creature_id), context.system.silk_capacity(owner)), "silk regeneration clamps to capacity")

func _test_owner_is_ignored_and_intruder_emits_stable_ids() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"owner_creature")
	var intruder: Variant = _creature(FIELD_CRICKET, &"cricket_intruder")
	var context := _web_context(owner, Vector2(24, 24))
	var intruder_actor: Variant = _actor(intruder, Vector2(40, 24))
	context.system.register_creature(intruder, intruder_actor)
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	var observed := {&"count": 0, &"owner": StringName(), &"intruder": StringName(), &"position": Vector2.ZERO}
	context.system.web_triggered.connect(func(owner_id: StringName, intruder_id: StringName, world_position: Vector2) -> void:
		observed[&"count"] = int(observed[&"count"]) + 1
		observed[&"owner"] = owner_id
		observed[&"intruder"] = intruder_id
		observed[&"position"] = world_position
	)
	assert_true(not segment.try_trigger(context.owner_actor), "owner does not trigger its own web")
	assert_eq(observed[&"count"], 0, "owner entry emits no trigger")
	assert_true(segment.try_trigger(intruder_actor), "non-owner creature triggers an armed web")
	assert_eq(observed[&"owner"], &"owner_creature", "trigger reports stable owner creature ID")
	assert_eq(observed[&"intruder"], &"cricket_intruder", "trigger reports stable intruder creature ID")
	assert_eq(observed[&"position"], Vector2(40, 24), "trigger reports web world position")

func _test_restraint_is_transient_and_breakage_clears_it() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"break_owner")
	owner.genome.set_value(&"web_strength", 0.5)
	var intruder: Variant = _creature(FIELD_CRICKET, &"break_intruder")
	var context := _web_context(owner, Vector2(24, 24))
	var intruder_actor: Variant = _actor(intruder, Vector2(40, 24))
	context.system.register_creature(intruder, intruder_actor)
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	var base_genome_speed: float = intruder.genome.get_value(&"move_speed")
	var baseline: float = intruder_actor.movement_speed()
	segment.try_trigger(intruder_actor)
	assert_true(intruder_actor.movement_speed() < baseline, "armed web restraint lowers effective movement")
	assert_eq(intruder.genome.get_value(&"move_speed"), base_genome_speed, "restraint never mutates the genome")
	segment._on_body_exited(intruder_actor)
	assert_true(is_equal_approx(intruder_actor.movement_speed(), baseline), "leaving a web clears its transient restraint")
	segment.try_trigger(intruder_actor)
	intruder_actor.set_move_direction(Vector2.RIGHT)
	segment.advance_struggle(intruder_actor, 100.0)
	assert_true(not segment.armed, "depleted durability disarms the web")
	assert_true(is_equal_approx(intruder_actor.movement_speed(), baseline), "breaking a web clears its transient restraint")
	assert_eq(intruder.genome.get_value(&"move_speed"), base_genome_speed, "breakage leaves base movement unchanged")

func _test_struggle_reduces_durability() -> void:
	var owner: Variant = _creature(PLAYER_SPIDER, &"durability_owner")
	var intruder: Variant = _creature(FIELD_CRICKET, &"durability_intruder")
	var context := _web_context(owner, Vector2(24, 24))
	var intruder_actor: Variant = _actor(intruder, Vector2(40, 24))
	context.system.register_creature(intruder, intruder_actor)
	var segment: Variant = context.system.place_web(owner, Vector2(40, 24), Vector2.UP)
	segment.try_trigger(intruder_actor)
	intruder_actor.set_move_direction(Vector2.RIGHT)
	var before: float = segment.durability
	segment.advance_struggle(intruder_actor, 0.5)
	assert_true(segment.durability < before, "moving while restrained damages web durability")

func _test_vibration_memory_obeys_genome_sensory_range() -> void:
	var near_owner: Variant = _creature(PLAYER_SPIDER, &"near_owner")
	near_owner.genome.set_value(&"sensory_range", 1.0)
	var near_intruder: Variant = _creature(FIELD_CRICKET, &"near_intruder")
	var near_context := _web_context(near_owner, Vector2(24, 24))
	var near_actor: Variant = _actor(near_intruder, Vector2(40, 24))
	near_context.system.register_creature(near_intruder, near_actor)
	var near_segment: Variant = near_context.system.place_web(near_owner, Vector2(40, 24), Vector2.UP)
	near_segment.try_trigger(near_actor)
	var vibration: Dictionary = near_owner.memory.get_event(&"web_vibration")
	assert_true(not vibration.is_empty(), "owner remembers an in-range web vibration")
	if not vibration.is_empty():
		assert_true(float(vibration.importance) >= 0.8, "web vibration memory has high importance")
		assert_eq(vibration.payload.get(&"world_position"), Vector2(40, 24), "vibration payload includes web position")
		assert_eq(vibration.payload.get(&"intruder_id"), &"near_intruder", "vibration payload includes stable intruder ID")

	var far_owner: Variant = _creature(PLAYER_SPIDER, &"far_owner")
	far_owner.genome.set_value(&"sensory_range", 0.1)
	var far_intruder: Variant = _creature(FIELD_CRICKET, &"far_intruder")
	var far_context := _web_context(far_owner, Vector2(24, 24))
	var far_actor: Variant = _actor(far_intruder, Vector2(72, 24))
	far_context.system.register_creature(far_intruder, far_actor)
	var far_segment: Variant = far_context.system.place_web(far_owner, Vector2(72, 24), Vector2.UP)
	far_segment.try_trigger(far_actor)
	assert_true(not far_owner.memory.has_event(&"web_vibration"), "out-of-range web vibration creates no memory")

func _test_creature_state_has_no_player_or_network_ownership() -> void:
	var properties: Array[StringName] = []
	for property: Dictionary in CreatureStateData.new().get_property_list():
		properties.append(property.name)
	for forbidden: StringName in [&"player1", &"player2", &"player_number", &"peer_id", &"network_peer_id", &"network_owner", &"controller", &"input", &"camera"]:
		assert_true(not properties.has(forbidden), "CreatureState excludes ownership/controller field %s" % forbidden)

func _test_manual_composition_uses_left_mouse_and_non_ai_cricket() -> void:
	var left_mouse_found := false
	for event: InputEvent in InputMap.action_get_events(&"place_web"):
		if event is InputEventMouseButton:
			left_mouse_found = left_mouse_found or (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	assert_true(left_mouse_found, "place_web is bound to Left Mouse Button")

	var main: Node = MAIN_SCENE.instantiate()
	var cricket_actor: Variant = main.get_node_or_null("WebTestCricket")
	var cricket_state: Variant = main.create_web_test_target()
	assert_true(cricket_actor != null, "Main provides the isolated Task 7 cricket target")
	if cricket_actor != null:
		assert_true(not cricket_actor.local_input_enabled, "web-test cricket has local input disabled")
	assert_eq(cricket_state.species_id, &"field_cricket", "web-test target uses field-cricket content")
	assert_eq(cricket_state.creature_id, &"web_test_cricket_0001", "web-test target has a distinct stable creature ID")
	assert_true(main.get_node_or_null("PreyBrain") == null, "Task 7 composition adds no prey AI")
	main.free()

func _web_context(owner: Variant, owner_position: Vector2) -> Dictionary:
	var system: Node = _web_system_script.new()
	var zone := ZoneStateData.new()
	zone.resize(8, 8, &"forest_floor")
	var owner_actor: Variant = _actor(owner, owner_position)
	system.bind_zone(zone)
	system.register_creature(owner, owner_actor)
	_nodes.append(system)
	return {&"system": system, &"zone": zone, &"owner_actor": owner_actor}

func _creature(species: Resource, creature_id: StringName) -> Variant:
	var creature := CreatureStateData.new()
	creature.creature_id = creature_id
	creature.species_id = species.id
	creature.genome = species.base_genome.clone_genome()
	creature.age_stage = &"adult"
	return creature

func _actor(creature: Variant, actor_position: Vector2) -> Variant:
	var actor: Node = _actor_script.new()
	actor.bind_state(creature)
	actor.position = actor_position
	_nodes.append(actor)
	return actor

func _free_nodes() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_nodes.clear()
