class_name FoodMemory
extends RefCounted
## Outcomes attached to semantic food IDs for later autonomous decision-making.

const STARVATION_SAVE_WEIGHT := 2.0
const POISONING_WEIGHT := 2.0

var entries: Dictionary = {}

func record_food(food_id: StringName, nutrition: float, context_tags: Array[StringName]) -> void:
	var entry: Dictionary = entries.get(food_id, {
		&"exposure": 0,
		&"positive": 0.0,
		&"negative": 0.0,
	})
	var positive_weight := maxf(nutrition, 0.0)
	var negative_weight := maxf(-nutrition, 0.0)
	if context_tags.has(&"starvation_save"):
		positive_weight *= STARVATION_SAVE_WEIGHT
	if context_tags.has(&"poisoning"):
		negative_weight += maxf(absf(nutrition), 1.0) * POISONING_WEIGHT
	entry.exposure = int(entry.exposure) + 1
	entry.positive = float(entry.positive) + positive_weight
	entry.negative = float(entry.negative) + negative_weight
	entries[food_id] = entry

func get_entry(food_id: StringName) -> Dictionary:
	return entries.get(food_id, {})

func get_preference(food_id: StringName) -> float:
	var entry := get_entry(food_id)
	return float(entry.get(&"positive", 0.0)) - float(entry.get(&"negative", 0.0))
