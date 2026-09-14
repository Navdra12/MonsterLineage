class_name Genome
extends Resource
## Inherited biological data only. Clone species defaults for each individual.
## Body-plan identity is assigned at formation; adult growth/injuries belong to
## individual state. Descendant body-plan replacement is outside 0.1.

@export var body_plan_id: StringName
@export var trait_values: Dictionary[StringName, float] = {}

func get_value(trait_id: StringName) -> float:
	return trait_values.get(trait_id, 0.0)

## Generation code applies TraitDef ranges; this container does not clamp.
func set_value(trait_id: StringName, value: float) -> void:
	trait_values[trait_id] = value

func clone_genome() -> Genome:
	# Use this script directly so headless loading needs no editor class cache.
	var copy: Genome = get_script().new()
	copy.body_plan_id = body_plan_id
	copy.trait_values = trait_values.duplicate()
	return copy
