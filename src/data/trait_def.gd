class_name TraitDef
extends Resource
## Authored numeric trait limits and generation parameters, independent of anatomy.

@export var id: StringName
@export var display_key: StringName
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var mutation_sigma: float = 0.08
@export var inheritance_weight: float = 1.0

func clamp_value(value: float) -> float:
	return clampf(value, min_value, max_value)
