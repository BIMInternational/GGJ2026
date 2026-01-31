extends Node
## Gestionnaire de localisation

signal language_changed(new_locale: String)

var available_languages = {
	"fr": "Français",
	"en": "English"
}


func _ready() -> void:
	# Charger la langue sauvegardée ou utiliser la langue système
	var saved_locale = SaveManager.get_setting("language", "")
	
	if saved_locale.is_empty():
		# Détecter la langue système
		var system_locale = OS.get_locale().substr(0, 2)
		if system_locale in available_languages:
			saved_locale = system_locale
		else:
			saved_locale = "en"  # Par défaut: anglais
	
	set_language(saved_locale)


func set_language(locale: String) -> void:
	if locale not in available_languages:
		locale = "en"
	
	TranslationServer.set_locale(locale)
	SaveManager.save_setting("language", locale)
	language_changed.emit(locale)


func get_current_language() -> String:
	return TranslationServer.get_locale()


func get_available_languages() -> Dictionary:
	return available_languages
