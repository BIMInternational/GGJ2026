extends Control

class_name SettingsMenu

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/AudioSection/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/AudioSection/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/AudioSection/SFXSlider
@onready var fullscreen_check: CheckButton = $MarginContainer/VBoxContainer/DisplaySection/FullscreenCheck
@onready var vsync_check: CheckButton = $MarginContainer/VBoxContainer/DisplaySection/VSyncCheck
@onready var language_option: OptionButton = $MarginContainer/VBoxContainer/LanguageSection/LanguageOption


func _ready() -> void:
	setup_language_options()
	load_settings()
	_update_texts()
	_setup_focus()
	_setup_slider_navigation()
	LocalizationManager.language_changed.connect(_on_language_changed)


func _update_texts() -> void:
	$MarginContainer/VBoxContainer/Title.text = tr("SETTINGS_TITLE")
	$MarginContainer/VBoxContainer/ControlsButton.text = tr("SETTINGS_CONTROLS")
	$MarginContainer/VBoxContainer/AudioSection/MasterLabel.text = tr("SETTINGS_MASTER_VOLUME")
	$MarginContainer/VBoxContainer/AudioSection/MusicLabel.text = tr("SETTINGS_MUSIC_VOLUME")
	$MarginContainer/VBoxContainer/AudioSection/SFXLabel.text = tr("SETTINGS_SFX_VOLUME")
	$MarginContainer/VBoxContainer/DisplaySection/FullscreenCheck.text = tr("SETTINGS_FULLSCREEN")
	$MarginContainer/VBoxContainer/DisplaySection/VSyncCheck.text = tr("SETTINGS_VSYNC")
	$MarginContainer/VBoxContainer/ResetSection/ResetLabel.text = tr("SETTINGS_DANGER_ZONE")
	$MarginContainer/VBoxContainer/ResetSection/ResetButton.text = tr("SETTINGS_RESET_DATA")
	$MarginContainer/VBoxContainer/BackButton.text = tr("BTN_BACK")


func setup_language_options() -> void:
	language_option.clear()
	var languages = LocalizationManager.get_available_languages()
	var current_locale = LocalizationManager.get_current_language()
	var index = 0
	var selected_index = 0
	
	for locale in languages:
		language_option.add_item(languages[locale])
		language_option.set_item_metadata(index, locale)
		if locale == current_locale:
			selected_index = index
		index += 1
	
	language_option.select(selected_index)


func load_settings() -> void:
	# Charger les paramètres audio
	var master_volume = SaveManager.get_setting("master_volume", 0.8) * 100
	var music_volume = SaveManager.get_setting("music_volume", 0.8) * 100
	var sfx_volume = SaveManager.get_setting("sfx_volume", 1.0) * 100
	
	master_slider.value = master_volume
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	
	# Charger les paramètres d'affichage
	fullscreen_check.button_pressed = SaveManager.get_setting("fullscreen", false)
	vsync_check.button_pressed = SaveManager.get_setting("vsync", true)
	
	# Appliquer les paramètres
	_apply_audio_settings()
	_apply_display_settings()


func _on_master_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SaveManager.save_setting("master_volume", volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MASTER), linear_to_db(volume))


func _on_music_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SaveManager.save_setting("music_volume", volume)
	AudioManager.music_volume = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MUSIC), linear_to_db(volume))


func _on_sfx_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SaveManager.save_setting("sfx_volume", volume)
	AudioManager.sfx_volume = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_SFX), linear_to_db(volume))


func _on_controls_button_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_CONTROLS_SETTINGS)


func _on_language_selected(index: int) -> void:
	var locale = language_option.get_item_metadata(index)
	LocalizationManager.set_language(locale)


func _on_language_changed(_locale: String) -> void:
	_update_texts() # Mettre à jour tous les textes quand la langue change


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SaveManager.save_setting("fullscreen", toggled_on)
	_apply_display_settings()


func _on_vsync_toggled(toggled_on: bool) -> void:
	SaveManager.save_setting("vsync", toggled_on)
	_apply_display_settings()


func _apply_audio_settings() -> void:
	var master_volume = SaveManager.get_setting("master_volume", 0.8)
	var music_volume = SaveManager.get_setting("music_volume", 0.8)
	var sfx_volume = SaveManager.get_setting("sfx_volume", 1.0)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MASTER), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MUSIC), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_SFX), linear_to_db(sfx_volume))
	AudioManager.music_volume = music_volume
	AudioManager.sfx_volume = sfx_volume


func _apply_display_settings() -> void:
	var fullscreen = SaveManager.get_setting("fullscreen", false)
	var vsync = SaveManager.get_setting("vsync", true)
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_reset_button_pressed() -> void:
	# Créer une popup de confirmation
	var dialog = AcceptDialog.new()
	dialog.dialog_text = tr("DIALOG_RESET_MESSAGE")
	dialog.title = tr("DIALOG_RESET_TITLE")
	dialog.ok_button_text = tr("DIALOG_RESET_CONFIRM")
	dialog.add_cancel_button(tr("DIALOG_RESET_CANCEL"))
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_confirm_reset)
	dialog.close_requested.connect(func(): dialog.queue_free())


func _confirm_reset() -> void:
	SaveManager.reset_all_data()
	load_settings()
	# Optionnel: message de confirmation
	var confirm = AcceptDialog.new()
	confirm.dialog_text = tr("DIALOG_RESET_SUCCESS")
	confirm.title = tr("DIALOG_SUCCESS")
	add_child(confirm)
	confirm.popup_centered()
	confirm.close_requested.connect(func(): confirm.queue_free())


func _on_back_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)


func _setup_focus() -> void:
	# Donner le focus au bouton Contrôles (premier bouton)
	$MarginContainer/VBoxContainer/ControlsButton.grab_focus()


func _setup_slider_navigation() -> void:
	# Permettre la navigation gauche/droite sur les sliders avec la manette
	for slider in [master_slider, music_slider, sfx_slider]:
		slider.focus_mode = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Gestion du retour avec la manette
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()
