extends StaticBody2D

class_name ProgressGate

## Invisible wall that blocks player progress until opened

var _is_open: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	pass


func open() -> void:
	_is_open = true
	collision_shape.set_deferred("disabled", true)
	print("[ProgressGate] Opened at x=", global_position.x)


func close() -> void:
	_is_open = false
	collision_shape.set_deferred("disabled", false)
	print("[ProgressGate] Closed at x=", global_position.x)


func is_open() -> bool:
	return _is_open
