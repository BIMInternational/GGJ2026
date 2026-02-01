extends Sprite2D

## A tumbleweed that rolls across the screen

@export var speed: float = 300.0
@export var vertical_wave_amplitude: float = 20.0
@export var vertical_wave_frequency: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _initial_y: float = 0.0
var _animation_player: AnimationPlayer
var _target_x: float = 0.0  # The X position where the tumbleweed should be destroyed

func _ready() -> void:
	_initial_y = global_position.y
	_animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

	# Start the rolling animation
	if _animation_player and _animation_player.has_animation("rumble"):
		_animation_player.play("rumble")


func _process(delta: float) -> void:
	_time_alive += delta

	# Move horizontally
	global_position.x += direction.x * speed * delta

	# Add a slight wave motion for realism
	global_position.y = _initial_y + sin(_time_alive * vertical_wave_frequency) * vertical_wave_amplitude

	# Rotate as it rolls
	rotation += direction.x * delta * 5.0

	# Destroy when past the target position
	if direction.x > 0 and global_position.x > _target_x:
		queue_free()
	elif direction.x < 0 and global_position.x < _target_x:
		queue_free()


## Initialize the tumbleweed with a direction and travel distance
func setup(move_direction: Vector2, start_y: float = 0.0, travel_distance: float = 3000.0) -> void:
	direction = move_direction.normalized()
	_initial_y = start_y
	global_position.y = start_y

	# Calculate target X based on direction and travel distance
	_target_x = global_position.x + (direction.x * travel_distance)

	# Flip sprite based on direction
	flip_h = direction.x < 0
