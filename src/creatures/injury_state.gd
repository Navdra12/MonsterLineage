class_name InjuryState
extends RefCounted
## Lightweight injuries keyed by semantic body-part IDs such as core, legs, mouth.

var injuries: Dictionary = {}

func set_injury(body_part_id: StringName, severity: float, effects: Array[StringName]) -> void:
	injuries[body_part_id] = {
		&"severity": clampf(severity, 0.0, 1.0),
		&"effects": effects.duplicate(),
	}

func has_injury(body_part_id: StringName) -> bool:
	return injuries.has(body_part_id)

func get_injury(body_part_id: StringName) -> Dictionary:
	return injuries.get(body_part_id, {})

func clear_injury(body_part_id: StringName) -> void:
	injuries.erase(body_part_id)
