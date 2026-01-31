extends CanvasLayer

class_name PauseMenu


func _ready() -> void:
	hide()
	_setup_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = visible
	if visible:
		_set_initial_focus()


func _on_resume_pressed() -> void:
	toggle_pause()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	SceneManager.reload_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)


func _setup_focus() -> void:
	# Cette fonction sera appelée au _ready, mais les boutons doivent être définis dans la scène
	pass


func _set_initial_focus() -> void:
	# Chercher le premier bouton disponible et lui donner le focus
	for child in get_children():
		var buttons = _find_buttons_recursive(child)
		if buttons.size() > 0:
			buttons[0].grab_focus()
			break


func _find_buttons_recursive(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node)
	for child in node.get_children():
		buttons.append_array(_find_buttons_recursive(child))
	return buttons
