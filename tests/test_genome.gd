extends "res://tests/test_case.gd"

const TRAIT_RANGES := {
	&"body_size": [0.60, 1.40], &"move_speed": [0.60, 1.50],
	&"web_strength": [0.50, 1.60], &"web_adhesion": [0.50, 1.60],
	&"venom_potency": [0.30, 1.70], &"venom_capacity": [0.40, 1.60],
	&"chitin": [0.50, 1.60], &"metabolism": [0.60, 1.50],
	&"sensory_range": [0.60, 1.60], &"forelimb_dexterity": [0.00, 1.50],
	&"membrane_potential": [0.00, 1.50], &"regeneration": [0.00, 1.20],
}
const BODY_CAPABILITIES := {
	&"arachnid_small": [&"wall_crawl", &"small_gap"],
	&"mothling_small": [&"ground_move"],
	&"scarabkin_small": [&"ground_move"],
	&"burrow_newt_small": [&"ground_move", &"small_gap"],
	&"insect_small": [&"ground_move", &"small_gap"],
	&"amphibian_predator": [&"ground_move"],
}
const SPECIES_BODIES := {
	&"player_spider": &"arachnid_small", &"mothling": &"mothling_small",
	&"scarabkin": &"scarabkin_small", &"burrow_newt": &"burrow_newt_small",
	&"field_cricket": &"insect_small", &"frog_predator": &"amphibian_predator",
}

func run() -> void:
	_test_genome_storage_and_clone()
	_test_trait_clamping()
	_test_trait_content()
	_test_body_plan_content()
	_test_species_content()
	_test_species_composition()

func _test_genome_storage_and_clone() -> void:
	var path := "res://src/genetics/genome.gd"
	var script := _load_script(path)
	if script == null:
		return
	var genome: Variant = script.new()
	genome.body_plan_id = &"arachnid_small"
	genome.set_value(&"move_speed", 1.25)
	genome.set_value(&"membrane_potential", 0.0)
	assert_eq(genome.get_value(&"move_speed"), 1.25, "stored actual trait value")
	assert_eq(genome.get_value(&"membrane_potential"), 0.0, "explicit zero is preserved")
	assert_eq(genome.get_value(&"unexpressed_trait"), 0.0, "missing trait has zero expression")

	var copy: Variant = genome.clone_genome()
	assert_eq(copy.body_plan_id, &"arachnid_small", "clone preserves body-plan identity")
	assert_eq(copy.trait_values, genome.trait_values, "clone preserves all inherited values")
	copy.set_value(&"move_speed", 0.75)
	assert_eq(genome.get_value(&"move_speed"), 1.25, "clone must not alias source dictionary")
	genome.set_value(&"membrane_potential", 0.2)
	assert_eq(copy.get_value(&"membrane_potential"), 0.0, "source changes must not affect clone")

	# New morphologies and trait IDs need data, not another Genome subclass.
	copy.body_plan_id = &"test_non_arachnid"
	copy.set_value(&"test_buoyancy", 2.5)
	assert_eq(copy.get_value(&"test_buoyancy"), 2.5, "genome stores values without fixed trait ranges")
	assert_eq(genome.body_plan_id, &"arachnid_small", "building a new genome leaves source morphology intact")
	assert_eq(genome.get_value(&"test_buoyancy"), 0.0, "new clone traits do not enter source genome")

func _test_trait_clamping() -> void:
	var path := "res://src/data/trait_def.gd"
	var script := _load_script(path)
	if script == null:
		return
	var trait_def: Variant = script.new()
	trait_def.min_value = 0.6
	trait_def.max_value = 1.5
	for sample in [[-2.0, 0.6], [0.6, 0.6], [1.25, 1.25], [1.5, 1.5], [9.0, 1.5]]:
		assert_eq(trait_def.clamp_value(sample[0]), sample[1], "trait range clamps %s" % sample[0])
	trait_def.min_value = -5.0
	trait_def.max_value = 8.0
	assert_eq(trait_def.clamp_value(-3.0), -3.0, "clamping follows definition, not prototype limits")

func _test_trait_content() -> void:
	_assert_content_count("traits", 12)
	for trait_id in TRAIT_RANGES:
		var trait_def: Variant = _load_content("traits", trait_id)
		if trait_def == null:
			continue
		assert_eq(trait_def.get_script(), load("res://src/data/trait_def.gd"), "%s uses TraitDef" % trait_id)
		assert_eq(trait_def.min_value, TRAIT_RANGES[trait_id][0], "%s lower limit" % trait_id)
		assert_eq(trait_def.max_value, TRAIT_RANGES[trait_id][1], "%s upper limit" % trait_id)
		assert_true(trait_def.mutation_sigma > 0.0, "%s permits controlled variation" % trait_id)
		assert_true(trait_def.inheritance_weight > 0.0, "%s permits inheritance" % trait_id)

func _test_body_plan_content() -> void:
	_assert_content_count("body_plans", 6)
	for body_id in BODY_CAPABILITIES:
		var body: Variant = _load_content("body_plans", body_id)
		if body == null:
			continue
		assert_eq(body.get_script(), load("res://src/data/body_plan_def.gd"), "%s uses BodyPlanDef" % body_id)
		assert_true(not body.base_parts.is_empty(), "%s has anatomy for body-part consumers" % body_id)
		var unique_parts := {}
		for part_id in body.base_parts:
			assert_true(not part_id.is_empty(), "%s has nonempty part IDs" % body_id)
			assert_true(not unique_parts.has(part_id), "%s has uniquely addressable parts" % body_id)
			unique_parts[part_id] = true
		for capability in BODY_CAPABILITIES[body_id]:
			assert_true(body.movement_capabilities.has(capability), "%s supports %s" % [body_id, capability])
		assert_true(body.size_class > 0, "%s has a positive traversal size class" % body_id)
		if body.movement_capabilities.has(&"small_gap"):
			assert_true(body.size_class <= 1, "%s fits prototype small gaps" % body_id)

func _test_species_content() -> void:
	_assert_content_count("species", 6)
	var species_by_id := {}
	for species_id in SPECIES_BODIES:
		var species: Variant = _load_content("species", species_id)
		if species == null:
			continue
		species_by_id[species_id] = species
		assert_eq(species.display_key, StringName("species.%s" % species_id), "%s resolves through the planned locale catalog" % species_id)
		assert_eq(species.get_script(), load("res://src/data/species_def.gd"), "%s uses the shared SpeciesDef" % species_id)
		assert_true(species.body_plan != null and species.base_genome != null, "%s references body and genome" % species_id)
		if species.body_plan == null or species.base_genome == null:
			continue
		assert_eq(species.body_plan.id, SPECIES_BODIES[species_id], "%s has its intended body" % species_id)
		assert_eq(species.base_genome.body_plan_id, species.body_plan.id, "%s genome matches template anatomy" % species_id)
		assert_true([&"instinctive", &"cunning", &"sapient", &"advanced"].has(species.cognition_band), "%s has a semantic cognition band" % species_id)
		assert_true(not species.diet_tags.is_empty(), "%s has dietary data" % species_id)
		assert_true(not species.base_genome.trait_values.is_empty(), "%s has inherited values" % species_id)
		for trait_id in species.base_genome.trait_values:
			var trait_def: Variant = _load_content("traits", trait_id)
			if trait_def != null:
				var value: float = species.base_genome.get_value(trait_id)
				assert_true(value >= trait_def.min_value and value <= trait_def.max_value, "%s/%s is in its authored range" % [species_id, trait_id])
		var individual: Variant = species.base_genome.clone_genome()
		var original_speed: float = species.base_genome.get_value(&"move_speed")
		individual.set_value(&"move_speed", original_speed + 0.01)
		assert_eq(species.base_genome.get_value(&"move_speed"), original_speed, "%s template survives individual variation" % species_id)
	if species_by_id.size() != 6:
		return
	var spider: Variant = species_by_id[&"player_spider"].base_genome
	assert_eq(spider.trait_values.size(), 12, "starting spider carries all twelve prototype traits")
	assert_eq(spider.get_value(&"forelimb_dexterity"), 0.15, "starting dexterity")
	assert_eq(spider.get_value(&"membrane_potential"), 0.0, "starting membrane potential")
	assert_eq(spider.get_value(&"regeneration"), 0.10, "starting regeneration")
	for bias in [[&"mothling", &"sensory_range"], [&"mothling", &"membrane_potential"],
		[&"scarabkin", &"chitin"], [&"scarabkin", &"body_size"],
		[&"burrow_newt", &"regeneration"], [&"burrow_newt", &"forelimb_dexterity"]]:
		assert_true(species_by_id[bias[0]].base_genome.get_value(bias[1]) > spider.get_value(bias[1]), "%s favors %s" % bias)
	for species_id in [&"mothling", &"scarabkin", &"burrow_newt"]:
		assert_true([&"cunning", &"sapient"].has(species_by_id[species_id].cognition_band), "%s is a semi/intelligent group" % species_id)
	for species_id in [&"field_cricket", &"frog_predator"]:
		assert_true(species_by_id[species_id].reproduction_tags.is_empty(), "%s is outside prototype reproduction" % species_id)
	var shared_reproduction_tag := false
	for tag in species_by_id[&"player_spider"].reproduction_tags:
		if species_by_id[&"mothling"].reproduction_tags.has(tag):
			shared_reproduction_tag = true
	assert_true(shared_reproduction_tag, "spider and mothling expose a shared prototype compatibility tag")
	assert_eq(species_by_id[&"burrow_newt"].base_genome.get_value(&"web_strength"), 0.0, "non-web anatomy need not carry spider-native traits")

func _test_species_composition() -> void:
	for path in ["res://src/data/body_plan_def.gd", "res://src/data/species_def.gd"]:
		if _load_script(path) == null:
			return
	var body: Variant = load("res://src/data/body_plan_def.gd").new()
	body.id = &"test_non_arachnid"
	body.base_parts.assign([&"body_mass"])
	body.movement_capabilities.assign([&"test_flow"])
	var species: Variant = load("res://src/data/species_def.gd").new()
	species.id = &"test_stable_morphology"
	species.body_plan = body
	species.base_genome = load("res://src/genetics/genome.gd").new()
	species.base_genome.body_plan_id = body.id
	species.base_genome.set_value(&"test_buoyancy", 2.5)
	species.reproduction_tags.assign([&"test_budding"])
	var individual_genome: Variant = species.base_genome.clone_genome()
	assert_eq(individual_genome.body_plan_id, &"test_non_arachnid", "new species can entirely lack arachnid morphology")
	assert_eq(individual_genome.get_value(&"test_buoyancy"), 2.5, "new species uses the same inherited-value model")
	assert_eq(individual_genome.get_value(&"web_strength"), 0.0, "genome does not inject arachnid defaults")

func _load_content(folder: String, content_id: StringName) -> Resource:
	var path := "res://content/%s/%s.tres" % [folder, content_id]
	assert_true(ResourceLoader.exists(path), "%s must exist" % path)
	if not ResourceLoader.exists(path):
		return null
	var resource: Variant = load(path)
	assert_true(resource != null, "%s loads" % path)
	if resource != null:
		var script: Script = resource.get_script()
		assert_true(script != null and script.can_instantiate(), "%s has a usable resource script" % path)
		if script == null or not script.can_instantiate():
			return null
		assert_eq(resource.id, content_id, "%s uses a stable ID" % path)
		assert_true(not resource.display_key.is_empty(), "%s references a localization key" % path)
	return resource

func _load_script(path: String) -> Script:
	assert_true(ResourceLoader.exists(path), "%s resource class must exist" % path)
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	assert_true(script != null and script.can_instantiate(), "%s must compile without an editor cache" % path)
	if script == null or not script.can_instantiate():
		return null
	return script

func _assert_content_count(folder: String, expected: int) -> void:
	var path := "res://content/%s" % folder
	if not DirAccess.dir_exists_absolute(path):
		assert_eq(0, expected, "%s authored resource count" % folder)
		return
	var count := 0
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".tres"):
			count += 1
	assert_eq(count, expected, "%s authored resource count" % folder)
