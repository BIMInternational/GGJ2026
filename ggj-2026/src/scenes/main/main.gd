extends Node2D

var _time_elapsed: float = 0.0
@onready var hud: HUD = $HUD
@onready var level: Node2D = $Level01

func _ready() -> void:
	print("Main scene _ready()")
	GameManager.start_game()
	hud.update_timer(0.0)
	
	if level:
		level.player_died.connect(_on_player_died)
		level.level_completed.connect(_on_victory)

func _process(delta: float) -> void:
	if GameManager.is_game_running:
		_time_elapsed += delta
		hud.update_timer(_time_elapsed)
		
		# Timer de fin de partie désactivé
		#if _time_elapsed >= GameConstants.GAME_DURATION:
		#	GameManager.end_game()

func _on_player_died() -> void:
	GameManager.end_game()

func _on_victory() -> void:
	print("VICTORY!")
