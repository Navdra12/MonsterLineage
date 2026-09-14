class_name NeedsState
extends RefCounted
## Per-creature survival needs. Activity-specific drains are applied by later systems.

var energy: float = 100.0
var hunger: float = 0.0

func tick(delta_seconds: float, metabolism: float) -> void:
	var progression := maxf(delta_seconds, 0.0) * maxf(metabolism, 0.0)
	energy = clampf(energy - progression, 0.0, 100.0)
	hunger = clampf(hunger + progression, 0.0, 100.0)
