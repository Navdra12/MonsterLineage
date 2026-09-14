extends Node

signal locale_changed(locale_code: String)

func set_locale(locale_code: String) -> void:
	TranslationServer.set_locale(locale_code)
	locale_changed.emit(locale_code)

func current_locale() -> String:
	return TranslationServer.get_locale()
