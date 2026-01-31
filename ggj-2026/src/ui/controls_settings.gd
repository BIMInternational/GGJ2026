extends Control

class_name ControlsSettings

@onready var inputs_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/InputsContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer

var _actions: Array[String] = ["move_left", "move_right", "move_up", "move_down", "action", "attack", "switch_mask", "defense", "validate", "cancel", "pause"]
var _actions_cache: Dictionary = {}
var _waiting_for_input: Button = null


func _ready() -> void:
	create_input_buttons()
	_update_texts()
	_setup_focus()
	_setup_scroll_indicators()
	InputRemapManager.input_remapped.connect(_on_input_remapped)
	LocalizationManager.language_changed.connect(_on_language_changed)


func _update_texts() -> void:
	$MarginContainer/VBoxContainer/Title.text = tr("CONTROLS_TITLE")
	$MarginContainer/VBoxContainer/Info.text = tr("CONTROLS_INFO")
	$MarginContainer/VBoxContainer/ButtonsContainer/ResetButton.text = tr("CONTROLS_RESET")
	$MarginContainer/VBoxContainer/ButtonsContainer/BackButton.text = tr("BTN_BACK")


func _on_language_changed(_locale: String) -> void:
	# Only update texts for labels in the cache
	for action in _actions_cache:
		_actions_cache[action].text = InputRemapManager.get_action_display_name(action)
	_update_texts()


func create_input_buttons() -> void:
	# Nettoyer les boutons existants
	for child in inputs_container.get_children():
		child.queue_free()

	_actions_cache.clear()

	# Créer un bouton pour chaque action
	for action in _actions:
		var container := HBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = InputRemapManager.get_action_display_name(action)
		label.custom_minimum_size = Vector2(200, 0)
		container.add_child(label)

		# Store the label in the cache
		_actions_cache[action] = label

		var button := Button.new()
		button.text = InputRemapManager.get_first_key_for_action(action)
		button.custom_minimum_size = Vector2(150, 0)
		button.set_meta("action", action)
		button.pressed.connect(_on_input_button_pressed.bind(button))
		container.add_child(button)

		inputs_container.add_child(container)


func _on_input_button_pressed(button: Button) -> void:
	if _waiting_for_input:
		_waiting_for_input.text = InputRemapManager.get_first_key_for_action(_waiting_for_input.get_meta("action"))
	
	_waiting_for_input = button
	button.text = tr("CONTROLS_WAITING")


func _input(event: InputEvent) -> void:
	if not _waiting_for_input:
		return
	
	if event is InputEventKey and event.pressed:
		var action = _waiting_for_input.get_meta("action")
		InputRemapManager.remap_action(action, event)
		_waiting_for_input.text = InputRemapManager.get_first_key_for_action(action)
		_waiting_for_input = null
		accept_event()
	
	elif event is InputEventMouseButton and event.pressed:
		var action = _waiting_for_input.get_meta("action")
		InputRemapManager.remap_action(action, event)
		_waiting_for_input.text = InputRemapManager.get_first_key_for_action(action)
		_waiting_for_input = null
		accept_event()
	
	elif event is InputEventJoypadButton and event.pressed:
		var action = _waiting_for_input.get_meta("action")
		InputRemapManager.remap_action(action, event)
		_waiting_for_input.text = InputRemapManager.get_first_key_for_action(action)
		_waiting_for_input = null
		accept_event()


func _on_input_remapped(_action: String) -> void:
	pass  # Déjà géré dans _input


func _on_reset_button_pressed() -> void:
	InputRemapManager.reset_to_defaults()
	create_input_buttons()
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = tr("DIALOG_CONTROLS_RESET")
	dialog.title = tr("DIALOG_SUCCESS")
	add_child(dialog)
	dialog.popup_centered()
	dialog.close_requested.connect(func(): dialog.queue_free())


func _on_back_pressed() -> void:
	SceneManager.change_scene(GameConstants.SCENE_SETTINGS_MENU)


func _setup_focus() -> void:
	# Donner le focus au premier bouton d'input
	if inputs_container.get_child_count() > 0:
		var first_container = inputs_container.get_child(0)
		if first_container.get_child_count() > 1:
			var first_button = first_container.get_child(1)
			if first_button is Button:
				first_button.grab_focus()


func _setup_scroll_indicators() -> void:
	# Activer la scrollbar verticale avec style visible
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	# S'assurer que le scroll suit le focus
	scroll_container.follow_focus = true
