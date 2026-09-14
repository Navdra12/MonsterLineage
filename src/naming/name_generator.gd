class_name NameGenerator
extends RefCounted

const GeneratedNameRecord = preload("res://src/naming/generated_name.gd")
const NamingProfileData = preload("res://src/data/naming_profile.gd")

static func generate(profile: NamingProfileData, kind: StringName, rng: RandomNumberGenerator) -> GeneratedNameRecord:
	var generated := GeneratedNameRecord.new()
	generated.kind = kind
	generated.profile_id = profile.profile_id

	if kind == &"individual":
		generated.proper_form = _generate_proper_form(profile, rng)
	elif profile.name_kind_strategies.has(kind):
		generated.semantic_tokens.assign(_choose_semantic_tokens(profile.name_kind_strategies[kind], rng))

	return generated

static func _generate_proper_form(profile: NamingProfileData, rng: RandomNumberGenerator) -> String:
	if profile.onsets.is_empty() or profile.nuclei.is_empty() or profile.codas.is_empty():
		return ""

	var syllable_count := rng.randi_range(profile.min_syllables, profile.max_syllables)
	var pieces: Array[String] = []
	for _index in syllable_count:
		pieces.append(
			profile.onsets[rng.randi_range(0, profile.onsets.size() - 1)]
			+ profile.nuclei[rng.randi_range(0, profile.nuclei.size() - 1)]
			+ profile.codas[rng.randi_range(0, profile.codas.size() - 1)]
		)
	return "".join(pieces).capitalize()

static func _choose_semantic_tokens(strategies: Array, rng: RandomNumberGenerator) -> Array[StringName]:
	var total_weight := 0.0
	for strategy: Dictionary in strategies:
		total_weight += maxf(float(strategy.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return []

	var roll := rng.randf() * total_weight
	for strategy: Dictionary in strategies:
		roll -= maxf(float(strategy.get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return _as_string_names(strategy.get("tokens", []))
	return _as_string_names(strategies.back().get("tokens", []))

static func _as_string_names(tokens: Array) -> Array[StringName]:
	var semantic_tokens: Array[StringName] = []
	for token: Variant in tokens:
		semantic_tokens.append(StringName(token))
	return semantic_tokens
