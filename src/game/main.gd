extends Node

const GameTimeData = preload("res://src/autoload/game_time.gd")
const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")
const WorldViewData = preload("res://src/world/world_view.gd")

@onready var game_time: GameTimeData = get_node("/root/GameTime")
@onready var world_view: WorldViewData = $WorldView

func _ready() -> void:
	var zone := ZoneGeneratorData.new().generate(424242, 64, 64)
	world_view.build_from_state(zone)

func _process(_delta: float) -> void:
	game_time.set_slowed(Input.is_action_pressed("slow_time"))

func _exit_tree() -> void:
	Engine.time_scale = 1.0
