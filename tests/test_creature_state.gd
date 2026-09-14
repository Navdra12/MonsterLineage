extends "res://tests/test_case.gd"

const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const FoodMemoryData = preload("res://src/creatures/food_memory.gd")
const InjuryStateData = preload("res://src/creatures/injury_state.gd")
const MemoryLogData = preload("res://src/creatures/memory_log.gd")
const NeedsStateData = preload("res://src/creatures/needs_state.gd")
const PersonalityStateData = preload("res://src/creatures/personality_state.gd")
const GenomeData = preload("res://src/genetics/genome.gd")

func run() -> void:
	_test_behavior_accumulation_and_thresholds()
	_test_food_preference_and_contexts()
	_test_significant_memory_retention()
	_test_needs_progression_and_clamping()
	_test_injury_lookup_and_state()
	_test_creature_state_composition_and_identity()
	_test_creature_state_excludes_controller_ownership()

func _test_behavior_accumulation_and_thresholds() -> void:
	var personality: Variant = PersonalityStateData.new()
	personality.record_behavior(&"cannibalism", 0.5)
	assert_eq(personality.get_tendency(&"cannibalism"), 0.06, "behavior uses the approved diminishing increment")
	assert_true(not personality.is_suspected(&"cannibalism"), "one small event is not suspected")
	for _event in range(3):
		personality.record_behavior(&"cannibalism", 1.0)
	assert_true(personality.is_suspected(&"cannibalism"), "repeated behavior crosses the suspected threshold")
	assert_true(not personality.is_visible(&"cannibalism"), "suspected behavior can remain below the visible threshold")
	for _event in range(5):
		personality.record_behavior(&"cannibalism", 1.0)
	assert_true(personality.is_visible(&"cannibalism"), "repeated behavior crosses the visible threshold")
	personality.record_behavior(&"cannibalism", 100.0)
	assert_eq(personality.get_tendency(&"cannibalism"), 1.0, "tendencies clamp at one")
	personality.record_behavior(&"caution", -100.0)
	assert_eq(personality.get_tendency(&"caution"), 0.0, "tendencies clamp at zero")

func _test_food_preference_and_contexts() -> void:
	var food_memory: Variant = FoodMemoryData.new()
	var ordinary_context: Array[StringName] = []
	var starvation_context: Array[StringName] = [&"starvation_save"]
	var poisoning_context: Array[StringName] = [&"poisoning"]
	food_memory.record_food(&"harpy_meat", 2.0, ordinary_context)
	food_memory.record_food(&"harpy_meat", 2.0, ordinary_context)
	food_memory.record_food(&"field_cricket", 1.0, ordinary_context)
	assert_true(food_memory.get_preference(&"harpy_meat") > food_memory.get_preference(&"field_cricket"), "repeated nutritious food ranks above a lesser food")
	assert_eq(food_memory.get_entry(&"harpy_meat").exposure, 2, "food memory tracks exposure")

	food_memory.record_food(&"ordinary_meal", 1.0, ordinary_context)
	food_memory.record_food(&"rescue_meal", 1.0, starvation_context)
	assert_true(food_memory.get_entry(&"rescue_meal").positive > food_memory.get_entry(&"ordinary_meal").positive, "preventing starvation increases positive weight")

	food_memory.record_food(&"poison_berry", 1.0, poisoning_context)
	assert_true(food_memory.get_entry(&"poison_berry").negative > 0.0, "poisoning increases negative weight")
	assert_true(food_memory.get_preference(&"poison_berry") < food_memory.get_preference(&"ordinary_meal"), "poisoned food ranks below safe food")

func _test_significant_memory_retention() -> void:
	var memory: Variant = MemoryLogData.new()
	memory.capacity = 3
	memory.remember(&"minor_rustle", 0.1, {&"place": &"fern"})
	memory.remember(&"found_nest", 0.8, {&"place": &"burrow"})
	memory.remember(&"escaped_frog", 0.9, {&"predator_id": &"frog_7"})
	memory.remember(&"raised_clutch", 1.0, {&"clutch_id": &"clutch_2"})
	assert_eq(memory.entries.size(), 3, "memory respects its capacity")
	assert_true(not memory.has_event(&"minor_rustle"), "capacity pruning removes the lowest-importance event")
	assert_true(memory.has_event(&"found_nest"), "significant memories survive pruning")
	assert_true(memory.has_event(&"escaped_frog"), "high-importance danger survives pruning")
	assert_eq(memory.get_event(&"raised_clutch").payload.clutch_id, &"clutch_2", "memory retains event payload")

func _test_needs_progression_and_clamping() -> void:
	var needs: Variant = NeedsStateData.new()
	needs.energy = 80.0
	needs.hunger = 10.0
	needs.tick(5.0, 2.0)
	assert_eq(needs.energy, 70.0, "metabolism drains energy over time")
	assert_eq(needs.hunger, 20.0, "metabolism raises hunger over time")
	needs.tick(100.0, 5.0)
	assert_eq(needs.energy, 0.0, "energy clamps at zero")
	assert_eq(needs.hunger, 100.0, "hunger clamps at one hundred")
	needs.energy = 101.0
	needs.hunger = -1.0
	needs.tick(0.0, 1.0)
	assert_eq(needs.energy, 100.0, "tick clamps externally assigned energy")
	assert_eq(needs.hunger, 0.0, "tick clamps externally assigned hunger")

func _test_injury_lookup_and_state() -> void:
	var injuries: Variant = InjuryStateData.new()
	var leg_effects: Array[StringName] = [&"impaired_movement", &"bleeding"]
	var bleeding_effect: Array[StringName] = [&"bleeding"]
	injuries.set_injury(&"legs", 0.75, leg_effects)
	assert_true(injuries.has_injury(&"legs"), "injury is addressable by semantic body-part ID")
	assert_eq(injuries.get_injury(&"legs").severity, 0.75, "injury retains severity")
	assert_true(injuries.get_injury(&"legs").effects.has(&"impaired_movement"), "injury retains semantic effects")
	assert_eq(injuries.get_injury(&"mouth"), {}, "uninjured semantic body part has no injury state")
	injuries.set_injury(&"core", 5.0, bleeding_effect)
	assert_eq(injuries.get_injury(&"core").severity, 1.0, "injury severity clamps at one")
	injuries.clear_injury(&"legs")
	assert_true(not injuries.has_injury(&"legs"), "healed injury can be cleared")

func _test_creature_state_composition_and_identity() -> void:
	var creature: Variant = CreatureStateData.new()
	creature.creature_id = &"creature_0042"
	creature.species_id = &"player_spider"
	creature.genome = GenomeData.new()
	creature.genome.body_plan_id = &"arachnid_small"
	creature.age_stage = &"juvenile"
	creature.condition = 82.5
	creature.relationships[&"creature_0007"] = {&"trust": 0.8, &"reason": &"shared_hunt"}
	assert_eq(creature.creature_id, &"creature_0042", "creature identity is stable simulation data")
	assert_eq(creature.species_id, &"player_spider", "creature stores stable species identity")
	assert_eq(creature.genome.body_plan_id, &"arachnid_small", "creature composes inherited genome data")
	assert_eq(creature.age_stage, &"juvenile", "creature stores an approved age stage")
	assert_eq(creature.condition, 82.5, "creature stores current condition")
	assert_true(creature.needs is NeedsStateData, "creature composes needs state")
	assert_true(creature.injuries is InjuryStateData, "creature composes injury state")
	assert_true(creature.personality is PersonalityStateData, "creature composes personality state")
	assert_true(creature.food_memory is FoodMemoryData, "creature composes food memory")
	assert_true(creature.memory is MemoryLogData, "creature composes significant memory")
	assert_true(creature.relationships.has(&"creature_0007"), "relationships use stable creature identity")

func _test_creature_state_excludes_controller_ownership() -> void:
	var creature: Variant = CreatureStateData.new()
	assert_true(creature is RefCounted, "CreatureState is pure reference-counted simulation data")
	assert_true(not (creature is Node), "CreatureState is not a scene node")
	var property_names: Array[StringName] = []
	for property: Dictionary in creature.get_property_list():
		property_names.append(property.name)
	for forbidden in [&"player_number", &"network_peer_id", &"input", &"camera", &"ui", &"controller", &"session_peer", &"transport"]:
		assert_true(not property_names.has(forbidden), "CreatureState excludes ownership/presentation field %s" % forbidden)
