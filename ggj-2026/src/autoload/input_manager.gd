extends Node
## Gestionnaire d'inputs pour remapping facile
## Utile pour gérer différents types de contrôles

signal input_changed(device: String)

var _using_gamepad: bool = false
var using_gamepad: bool:
	get: return _using_gamepad
	set(value): _using_gamepad = value


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not _using_gamepad:
			_using_gamepad = true
			input_changed.emit("gamepad")
	elif event is InputEventKey or event is InputEventMouseButton:
		if _using_gamepad:
			_using_gamepad = false
			input_changed.emit("keyboard")


func get_move_vector() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func is_action_just_pressed_any(actions: Array[String]) -> bool:
	for action in actions:
		if Input.is_action_just_pressed(action):
			return true
	return false
