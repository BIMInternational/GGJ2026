extends Control

class_name CreditsMenu


func _ready() -> void:
	_setup_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_on_back_pressed()
		accept_event()


func _on_back_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)


func _setup_focus() -> void:
	# Chercher le bouton retour et lui donner le focus
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
