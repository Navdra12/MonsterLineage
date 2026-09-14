extends "res://tests/test_case.gd"

const GeneratedName = preload("res://src/naming/generated_name.gd")
const NameGenerator = preload("res://src/naming/name_generator.gd")
const NameRenderer = preload("res://src/naming/name_renderer.gd")
const ARACHNID_PROFILE = preload("res://content/naming/arachnid_proto.tres")

var LocaleService: Variant

func run() -> void:
	_test_locale_switching()
	_test_semantic_name_rendering()
	_test_seeded_generation_is_deterministic()
	_test_supported_name_kinds()

func _test_locale_switching() -> void:
	LocaleService.set_locale("uk")
	assert_eq(LocaleService.current_locale(), "uk", "locale service switches to Ukrainian")
	LocaleService.set_locale("en")
	assert_eq(LocaleService.current_locale(), "en", "locale service switches to English")

func _test_semantic_name_rendering() -> void:
	LocaleService.set_locale("en")
	var record := GeneratedName.new()
	record.kind = &"nest_descriptor"
	record.profile_id = &"arachnid_proto"
	record.semantic_tokens.assign([&"silver", &"web"])

	assert_eq(NameRenderer.render(record, "uk"), "Лігво Срібної Павутини", "Ukrainian grammar template")
	assert_eq(LocaleService.current_locale(), "en", "rendering an explicit locale does not change the active locale")
	assert_eq(NameRenderer.render(record, "en"), "Nest of the Silver Web", "English grammar template")
	assert_eq(record.semantic_tokens, [&"silver", &"web"], "rendering preserves semantic tokens")

func _test_seeded_generation_is_deterministic() -> void:
	RngService.configure(20260914)
	var first := NameGenerator.generate(ARACHNID_PROFILE, &"nest_descriptor", RngService.stream(&"names"))
	RngService.configure(20260914)
	var second := NameGenerator.generate(ARACHNID_PROFILE, &"nest_descriptor", RngService.stream(&"names"))

	assert_eq(first.kind, second.kind, "same seed reproduces name kind")
	assert_eq(first.profile_id, second.profile_id, "same seed reproduces profile ID")
	assert_eq(first.proper_form, second.proper_form, "same seed reproduces proper form")
	assert_eq(first.semantic_tokens, second.semantic_tokens, "same seed reproduces semantic tokens")

func _test_supported_name_kinds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var individual := NameGenerator.generate(ARACHNID_PROFILE, &"individual", rng)
	assert_true(not individual.proper_form.is_empty(), "individual names have a phonotactic proper form")
	assert_true(individual.semantic_tokens.is_empty(), "individual names do not store rendered descriptor text")

	for kind: StringName in [&"nest_descriptor", &"group_descriptor", &"territory_descriptor"]:
		var descriptor := NameGenerator.generate(ARACHNID_PROFILE, kind, rng)
		assert_eq(descriptor.kind, kind, "%s generation preserves semantic kind" % kind)
		assert_true(not descriptor.semantic_tokens.is_empty(), "%s generation returns semantic tokens" % kind)
		assert_true(descriptor.proper_form.is_empty(), "%s generation does not pre-render display text" % kind)
