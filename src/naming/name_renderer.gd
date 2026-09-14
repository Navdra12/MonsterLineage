class_name NameRenderer
extends RefCounted

const GeneratedNameRecord = preload("res://src/naming/generated_name.gd")
const NAMING_TERMS = preload("res://content/lexemes/naming_terms.tres")
const LEXEME_DIRECTORY := "res://content/lexemes"

static func render(name: GeneratedNameRecord, locale_code: String) -> String:
	if name.kind == &"individual":
		return name.proper_form
	if name.semantic_tokens.size() < 2:
		return ""

	var lexemes := _lexeme_pack(locale_code)
	if lexemes == null:
		return ""
	var locale_forms: Dictionary = NAMING_TERMS.forms_by_locale.get(locale_code, {})
	var descriptor_forms: Array = locale_forms.get(&"descriptor_forms", [])
	if descriptor_forms.size() < 2:
		return ""

	var first: String = lexemes.form(locale_code, name.semantic_tokens[0], descriptor_forms[0])
	var second: String = lexemes.form(locale_code, name.semantic_tokens[1], descriptor_forms[1])
	if first.is_empty() or second.is_empty():
		return ""

	var template_key := StringName("name.%s" % name.kind)
	var translation := TranslationServer.get_translation_object(locale_code)
	if translation == null:
		return ""
	var template := translation.get_message(template_key)
	return String(template) % [first, second]

static func _lexeme_pack(locale_code: String) -> Resource:
	var expected_id := StringName("%s_basic" % locale_code)
	for file_name: String in DirAccess.get_files_at(LEXEME_DIRECTORY):
		if not file_name.ends_with(".tres"):
			continue
		var resource: Resource = load("%s/%s" % [LEXEME_DIRECTORY, file_name])
		if resource != null and resource.get("id") == expected_id:
			return resource
	return null
