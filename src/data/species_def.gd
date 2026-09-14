class_name SpeciesDef
extends Resource
## Reusable biological defaults for an authored or stable derived morphology,
## never a character or its mutable state. Clone base_genome at individual creation.
## Personality, knowledge, age and injury belong to separate individual systems.

const BodyPlanDefinition = preload("res://src/data/body_plan_def.gd")
const GenomeData = preload("res://src/genetics/genome.gd")

@export var id: StringName
@export var display_key: StringName
@export var body_plan: BodyPlanDefinition
@export var base_genome: GenomeData
@export var cognition_band: StringName = &"instinctive"
@export var diet_tags: Array[StringName] = []
## Semantic compatibility data only, not a universal reproduction/lifecycle algorithm.
## Empty means outside the 0.1 reproduction path, not biological sterility.
@export var reproduction_tags: Array[StringName] = []
