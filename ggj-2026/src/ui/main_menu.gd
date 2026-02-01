extends Control

class_name MainMenu


func _ready() -> void:
	get_node('/root').find_child("TitleMusic", true, false).play()
	_update_texts()
	_initialize_signals()
	_setup_focus()
	
	# Cacher le bouton Quitter sur web car quit() ne fonctionne pas
	if OS.has_feature("web"):
		$VBoxContainer/QuitButton.visible = false


func _update_texts() -> void:
	$VBoxContainer/Title.text = tr("MAIN_MENU_TITLE")
	$VBoxContainer/StartButton.text = tr("BTN_START")
	$VBoxContainer/SettingsButton.text = tr("BTN_SETTINGS")
	$VBoxContainer/CreditsButton.text = tr("BTN_CREDITS")
	$VBoxContainer/QuitButton.text = tr("BTN_QUIT")


func _initialize_signals() -> void:
	LocalizationManager.language_changed.connect(_on_language_changed)
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_language_changed(_locale: String) -> void:
	_update_texts()


func _on_start_pressed() -> void:
	get_node('/root').find_child("TitleMusic", true, false).stop()
	SceneManager.change_scene(GameConstants.SCENE_MAIN_GAME)


func _on_settings_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_SETTINGS_MENU)


func _on_credits_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_CREDITS_MENU)


func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		# Sur web, on ne peut pas quitter, retourner au menu
		SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)
	else:
		get_tree().quit()


func _setup_focus() -> void:
	var start_btn = $VBoxContainer/StartButton
	var settings_btn = $VBoxContainer/SettingsButton
	var credits_btn = $VBoxContainer/CreditsButton
	var quit_btn = $VBoxContainer/QuitButton
	
	# Définir les voisins pour navigation verticale
	start_btn.focus_neighbor_top = quit_btn.get_path()
	start_btn.focus_neighbor_bottom = settings_btn.get_path()
	
	settings_btn.focus_neighbor_top = start_btn.get_path()
	settings_btn.focus_neighbor_bottom = credits_btn.get_path()
	
	credits_btn.focus_neighbor_top = settings_btn.get_path()
	credits_btn.focus_neighbor_bottom = quit_btn.get_path()
	
	quit_btn.focus_neighbor_top = credits_btn.get_path()
	quit_btn.focus_neighbor_bottom = start_btn.get_path()
	
	# Donner le focus au premier bouton
	start_btn.grab_focus()
