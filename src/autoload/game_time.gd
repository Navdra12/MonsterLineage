extends Node

const NORMAL_SCALE := 1.0
const SLOWED_SCALE := 0.12

var slowed := false

func set_slowed(value: bool) -> void:
	slowed = value
	Engine.time_scale = SLOWED_SCALE if value else NORMAL_SCALE
