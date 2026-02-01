extends Node2D

@onready var player: CharacterBody2D = $Player

signal level_completed
signal player_died

func _ready() -> void:
	print("Level01 _ready()")
	
	if player:
		player.died.connect(_on_player_died)
	
	_setup_wave_system()

func _setup_wave_system() -> void:
	var camera = player.get_node_or_null("Camera2D")
	
	var g1 = $Environment/Gate1
	var g2 = $Environment/Gate2
	var g3 = $Environment/Gate3
	var gates: Array[Node2D] = [g1, g2, g3]
	
	var arrow = $ArrowIndicator
	var reward = $RewardPlaceholder
	
	WaveManager.phases = [
		preload("res://src/combat/data/waves/phase_1.tres"),
		preload("res://src/combat/data/waves/phase_2.tres"),
		preload("res://src/combat/data/waves/phase_3.tres"),
	]
	
	WaveManager.all_phases_completed.connect(_on_victory)
	
	print("Starting WaveManager...")
	WaveManager.start_waves(camera, gates, arrow, reward, self)

func _on_player_died() -> void:
	print("[Level01] Player died - emitting signal")
	player_died.emit()

	

func _on_victory() -> void:
	print("Level completed!")
	level_completed.emit()
