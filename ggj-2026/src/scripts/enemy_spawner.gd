extends Node2D
class_name EnemySpawner

## Système de spawn d'ennemis pour le beat'em up

signal wave_completed
signal all_waves_completed

@export var enemy_scene: PackedScene
@export var max_enemies: int = 5
@export var spawn_interval: float = 2.0

var spawn_points: Array[Marker2D] = []
var _enemies_alive: Array[EnemyBase] = []
var _spawn_timer: float = 0.0


func _ready() -> void:
	# Trouver automatiquement les Marker2D enfants comme points de spawn
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)

	if spawn_points.is_empty():
		push_warning("EnemySpawner: No spawn points found!")

	_spawn_timer = 0.0


func _process(delta: float) -> void:
	_spawn_timer -= delta

	if _spawn_timer <= 0 and _can_spawn():
		_spawn_enemy()
		_spawn_timer = spawn_interval


func _can_spawn() -> bool:
	return _enemies_alive.size() < max_enemies and enemy_scene != null and not spawn_points.is_empty()


func _spawn_enemy() -> void:
	var spawn_point = spawn_points.pick_random()
	var enemy: EnemyBase = enemy_scene.instantiate()
	
	enemy.global_position = spawn_point.global_position
	enemy.died.connect(_on_enemy_died)

	# Ajouter l'ennemi au parent du spawner (le niveau)
	get_parent().add_child(enemy)
	_enemies_alive.append(enemy)
	print("Enemy spawned at: ", spawn_point.global_position)


func _on_enemy_died(enemy: EnemyBase) -> void:
	_enemies_alive.erase(enemy)
