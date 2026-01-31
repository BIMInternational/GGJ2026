extends Node

# @export var jump_sounds: Array[AudioStream]
# @export var land_sound: AudioStream
# @export var dash_sound: AudioStream

@onready var player: PlayerController = get_parent()

func _ready() -> void:
	# Connect to player signals (signaux disponibles: died, respawned, took_damage, dashed, attack_started, attack_ended)
	# player.jumped.connect(_on_jumped) # Signal supprimé - pas de saut dans ce jeu
	# player.landed.connect(_on_landed)
	player.dashed.connect(_on_dashed)
	# player.wall_jumped.connect(_on_wall_jumped)

# func _on_jumped() -> void:
# 	AudioManager.play_sfx(preload(GameConstants.PLAYER_WALK))

# func _on_landed() -> void:
# 	AudioManager.play_sfx(land_sound)

func _on_dashed() -> void:
	pass
	# AudioManager.play_sfx(dash_sound)

# func _on_wall_jumped() -> void:
# 	pass
# 	## AudioManager.play_sfx(jump_sounds.pick_random(), 1.2)  # Higher pitch
