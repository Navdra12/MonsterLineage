extends Node

func _process(_delta: float) -> void:
	GameTime.set_slowed(Input.is_action_pressed("slow_time"))

func _exit_tree() -> void:
	Engine.time_scale = 1.0
