extends Node2D
## Gas trail emitter using GPUParticles2D for visuals
## Spawns sparse collision zones for chemistry reactions

const GAS_COLLISION_ZONE = preload("res://src/combat/components/gas_collision_zone.tscn")

var attack_data: AttackData = null
var owner_node: Node2D = null

@onready var _particles: GPUParticles2D = $GPUParticles2D

## Distance between collision zone spawns (4x original trail_spawn_distance)
var _collision_spawn_distance: float = 80.0
var _distance_traveled: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _zone_lifetime: float = 8.0
var _is_emitting: bool = true

func _ready() -> void:
	_last_position = global_position
	if _particles:
		_particles.emitting = true

func initialize(data: AttackData, attack_owner: Node2D = null) -> void:
	attack_data = data
	owner_node = attack_owner

	# Use trail attack data's dissipation time for collision zones
	if data.trail_attack_data:
		_zone_lifetime = data.trail_attack_data.dissipation_time

	# Collision zones spawn every 80px (4x less frequent than original 20px)
	_collision_spawn_distance = data.trail_spawn_distance * 4.0

func _process(_delta: float) -> void:
	if not _is_emitting or attack_data == null:
		return

	var current_pos = global_position
	var distance = current_pos.distance_to(_last_position)
	_distance_traveled += distance
	_last_position = current_pos

	# Spawn collision zone at intervals
	if _distance_traveled >= _collision_spawn_distance:
		_spawn_collision_zone()
		_distance_traveled = 0.0

func _spawn_collision_zone() -> void:
	if attack_data == null or attack_data.trail_attack_data == null:
		return

	var zone = GAS_COLLISION_ZONE.instantiate()
	get_tree().root.add_child(zone)
	zone.initialize(attack_data.trail_attack_data, global_position, _zone_lifetime, owner_node)

func stop_emitting() -> void:
	_is_emitting = false
	if _particles:
		_particles.emitting = false
