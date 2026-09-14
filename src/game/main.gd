extends Node

const ZoneGeneratorData = preload("res://src/world/zone_generator.gd")

@onready var world_view: WorldView = $WorldView

func _ready() -> void:
	var zone := ZoneGeneratorData.new().generate(424242, 64, 64)
	world_view.build_from_state(zone)

func _process(_delta: float) -> void:
	GameTime.set_slowed(Input.is_action_pressed("slow_time"))

func _exit_tree() -> void:
	Engine.time_scale = 1.0
