class_name CreatureState
extends RefCounted
## Controller-independent simulation state for one stable creature identity.

const GenomeData = preload("res://src/genetics/genome.gd")
const FoodMemoryData = preload("res://src/creatures/food_memory.gd")
const InjuryStateData = preload("res://src/creatures/injury_state.gd")
const MemoryLogData = preload("res://src/creatures/memory_log.gd")
const NeedsStateData = preload("res://src/creatures/needs_state.gd")
const PersonalityStateData = preload("res://src/creatures/personality_state.gd")

const AGE_STAGES: Array[StringName] = [&"hatchling", &"juvenile", &"adult"]

var creature_id: StringName
var species_id: StringName
var genome: GenomeData
var age_stage: StringName = &"hatchling":
	set(value):
		if AGE_STAGES.has(value):
			age_stage = value
var condition: float = 100.0
var needs: NeedsStateData = NeedsStateData.new()
var injuries: InjuryStateData = InjuryStateData.new()
var personality: PersonalityStateData = PersonalityStateData.new()
var food_memory: FoodMemoryData = FoodMemoryData.new()
var memory: MemoryLogData = MemoryLogData.new()
## Keys are other creature IDs; values preserve relationship dimensions/reasons.
var relationships: Dictionary = {}
