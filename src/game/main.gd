extends Node

const GameTimeData = preload("res://src/autoload/game_time.gd")
const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const WorldViewData = preload("res://src/world/world_view.gd")
const CreatureActorData = preload("res://src/creatures/creature_actor.gd")
const WebSystemData = preload("res://src/gameplay/web/web_system.gd")
const PLAYER_SPIDER = preload("res://content/species/player_spider.tres")
const FIELD_CRICKET = preload("res://content/species/field_cricket.tres")

const CELL_SIZE := Vector2(16.0, 16.0)

@onready var game_time: GameTimeData = get_node("/root/GameTime")
@onready var world_view: WorldViewData = $WorldView
@onready var creature_actor: CreatureActorData = $CreatureActor
@onready var web_system: WebSystemData = $WebSystem
@onready var web_test_cricket: CreatureActorData = $WebTestCricket

var zone: ZoneStateData
var starting_creature: CreatureStateData
var web_test_target: CreatureStateData
var _cricket_anchor := Vector2.ZERO
var _cricket_drift := -1.0
var _vibration_cue_remaining := 0.0

func _ready() -> void:
	zone = ZoneGeneratorData.new().generate(424242, 64, 64)
	world_view.build_from_state(zone)
	starting_creature = create_starting_creature()
	creature_actor.bind_state(starting_creature)
	creature_actor.bind_zone(zone)
	creature_actor.position = cell_center(zone.spawn_points[&"player"])
	creature_actor.get_node("Camera2D").enabled = true
	web_system.bind_zone(zone)
	web_system.register_creature(starting_creature, creature_actor)
	web_test_target = create_web_test_target()
	web_test_cricket.bind_state(web_test_target)
	web_test_cricket.bind_zone(zone)
	web_test_cricket.local_input_enabled = false
	web_test_cricket.position = cell_center(_web_test_target_cell(zone.spawn_points[&"player"]))
	web_test_cricket.get_node("Body").color = Color(0.45, 0.75, 0.25, 1.0)
	web_test_cricket.scale = Vector2(0.75, 0.75)
	_cricket_anchor = web_test_cricket.position
	web_system.register_creature(web_test_target, web_test_cricket)
	web_system.web_triggered.connect(_on_web_triggered)

func create_starting_creature() -> CreatureStateData:
	var creature := CreatureStateData.new()
	creature.creature_id = &"creature_0001"
	creature.species_id = PLAYER_SPIDER.id
	creature.genome = PLAYER_SPIDER.base_genome.clone_genome()
	creature.age_stage = &"hatchling"
	return creature

func create_web_test_target() -> CreatureStateData:
	var creature := CreatureStateData.new()
	creature.creature_id = &"web_test_cricket_0001"
	creature.species_id = FIELD_CRICKET.id
	creature.genome = FIELD_CRICKET.base_genome.clone_genome()
	creature.age_stage = &"adult"
	return creature

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + CELL_SIZE * 0.5

func _process(delta: float) -> void:
	game_time.set_slowed(Input.is_action_pressed("slow_time"))
	if starting_creature != null:
		web_system.advance_silk(starting_creature, delta)
	if _vibration_cue_remaining > 0.0:
		_vibration_cue_remaining -= delta
		if _vibration_cue_remaining <= 0.0:
			creature_actor.get_node("Body").modulate = Color.WHITE

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(web_test_cricket):
		return
	if web_test_cricket.position.x <= _cricket_anchor.x - 48.0:
		_cricket_drift = 1.0
	elif web_test_cricket.position.x >= _cricket_anchor.x + 16.0:
		_cricket_drift = -1.0
	var preferred_direction := Vector2(_cricket_drift, 0.0)
	for candidate: Vector2 in [preferred_direction, -preferred_direction, Vector2.DOWN, Vector2.UP]:
		if _web_test_direction_is_traversable(candidate):
			if not is_zero_approx(candidate.x):
				_cricket_drift = candidate.x
			web_test_cricket.set_move_direction(candidate)
			return
	web_test_cricket.set_move_direction(Vector2.ZERO)

func _web_test_direction_is_traversable(direction: Vector2) -> bool:
	if zone == null or not is_instance_valid(web_test_cricket) or direction.is_zero_approx():
		return false
	var current_cell := Vector2i(
		floori(web_test_cricket.position.x / CELL_SIZE.x),
		floori(web_test_cricket.position.y / CELL_SIZE.y)
	)
	var cell_offset := Vector2i(int(signf(direction.x)), int(signf(direction.y)))
	return web_test_cricket.can_enter_cell(zone.cell_at(current_cell + cell_offset))

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("place_web") or starting_creature == null:
		return
	var aim := creature_actor.get_global_mouse_position() - creature_actor.global_position
	if aim.is_zero_approx():
		aim = Vector2.RIGHT
	var placement_position := creature_actor.global_position + aim.limit_length(WebSystemData.MAX_PLACEMENT_DISTANCE)
	web_system.place_web(starting_creature, placement_position, aim.normalized())

func _web_test_target_cell(player_cell: Vector2i) -> Vector2i:
	for offset: Vector2i in [Vector2i(3, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		var candidate := player_cell + offset
		if zone.cell_at(candidate) == &"forest_floor" or zone.cell_at(candidate) == &"burrow_floor":
			return candidate
	return player_cell

func _on_web_triggered(owner_id: StringName, _intruder_id: StringName, _world_position: Vector2) -> void:
	if starting_creature == null or owner_id != starting_creature.creature_id:
		return
	creature_actor.get_node("Body").modulate = Color(1.4, 1.4, 1.8, 1.0)
	_vibration_cue_remaining = 0.35

func _exit_tree() -> void:
	if is_instance_valid(game_time):
		game_time.set_slowed(false)
