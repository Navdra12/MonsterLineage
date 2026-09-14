class_name PersonalityState
extends RefCounted
## Learned behavioral history, separate from inherited Genome values.

const VISIBLE_THRESHOLD := 0.60
const SUSPECTED_THRESHOLD := 0.35

var tendencies: Dictionary[StringName, float] = {}

func record_behavior(tag: StringName, weight: float) -> void:
	var current := float(tendencies.get(tag, 0.0))
	tendencies[tag] = clampf(current + (1.0 - current) * 0.12 * weight, 0.0, 1.0)

func get_tendency(tag: StringName) -> float:
	return tendencies.get(tag, 0.0)

func is_visible(tag: StringName) -> bool:
	return get_tendency(tag) >= VISIBLE_THRESHOLD

func is_suspected(tag: StringName) -> bool:
	return get_tendency(tag) >= SUSPECTED_THRESHOLD
