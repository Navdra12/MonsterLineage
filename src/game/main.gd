extends Node

const GameTimeData = preload("res://src/autoload/game_time.gd")
const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const WorldViewData = preload("res://src/world/world_view.gd")
const CreatureActorData = preload("res://src/creatures/creature_actor.gd")
const PLAYER_SPIDER = preload("res://content/species/player_spider.tres")

const CELL_SIZE := Vector2(16.0, 16.0)

@onready var game_time: GameTimeData = get_node("/root/GameTime")
@onready var world_view: WorldViewData = $WorldView
@onready var creature_actor: CreatureActorData = $CreatureActor

var zone: ZoneStateData
var starting_creature: CreatureStateData

func _ready() -> void:
	zone = ZoneGeneratorData.new().generate(424242, 64, 64)
	world_view.build_from_state(zone)
	starting_creature = create_starting_creature()
	creature_actor.bind_state(starting_creature)
	creature_actor.bind_zone(zone)
	creature_actor.position = cell_center(zone.spawn_points[&"player"])
	creature_actor.get_node("Camera2D").enabled = true

func create_starting_creature() -> CreatureStateData:
	var creature := CreatureStateData.new()
	creature.creature_id = &"creature_0001"
	creature.species_id = PLAYER_SPIDER.id
	creature.genome = PLAYER_SPIDER.base_genome.clone_genome()
	creature.age_stage = &"hatchling"
	return creature

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + CELL_SIZE * 0.5

func _process(_delta: float) -> void:
	game_time.set_slowed(Input.is_action_pressed("slow_time"))

func _exit_tree() -> void:
	if is_instance_valid(game_time):
		game_time.set_slowed(false)
