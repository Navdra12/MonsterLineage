class_name LocalizedLexeme
extends Resource

@export var id: StringName
@export var forms_by_locale: Dictionary = {}

func form(locale_code: String, token_id: StringName, form_id: StringName) -> String:
	var locale_forms: Dictionary = forms_by_locale.get(locale_code, {})
	var token_forms: Dictionary = locale_forms.get(token_id, {})
	return token_forms.get(form_id, "")
