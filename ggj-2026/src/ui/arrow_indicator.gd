extends Control

class_name ArrowIndicator

## Simple arrow pointing right to indicate player can advance

@onready var label: Label = $Label

var _bob_tween: Tween = null
var _initial_x: float = 0.0
var _display_timer: Timer = null


func _ready() -> void:
	_initial_x = label.position.x
	visible = false
	
	# Create timer for auto-hide
	_display_timer = Timer.new()
	_display_timer.name = "_display_timer"
	_display_timer.one_shot = true
	_display_timer.timeout.connect(_on_display_timeout)
	add_child(_display_timer)


## Call this to show arrow for a duration (0 = indefinite)
func display(duration: float = 3.0) -> void:
	visible = true
	_start_bob_animation()
	if duration > 0:
		_display_timer.start(duration)


## Call this to show arrow indefinitely
func show_indefinitely() -> void:
	visible = true
	_start_bob_animation()
	_display_timer.stop()


## Call this to hide immediately
func hide_arrow() -> void:
	visible = false
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
	_display_timer.stop()


func _on_display_timeout() -> void:
	hide_arrow()


func _start_bob_animation() -> void:
	if _bob_tween:
		_bob_tween.kill()
	
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(label, "position:x", _initial_x + 10, 0.5).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(label, "position:x", _initial_x, 0.5).set_ease(Tween.EASE_IN_OUT)
