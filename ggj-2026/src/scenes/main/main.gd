extends Node2D

var _time_elapsed: float = 0.0
@onready var hud: HUD = $HUD
@onready var level: Node2D = $Level01
@onready var game_over: GameOver = $GameOver

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
	print("[Main] Player died, stopping game")
	GameManager.is_game_running = false
	
	# Attendre 1 seconde
	await get_tree().create_timer(1).timeout
	
	# Arrêter et détruire le level
	if level:
		level.set_process(false)
		level.set_physics_process(false)
		level.queue_free()
		level = null
	
	# Détruire le HUD
	if hud:
		hud.queue_free()
		hud = null
	
	# Attendre un frame pour s'assurer que tout est nettoyé
	await get_tree().process_frame
	
	# Afficher le game over et lancer la musique
	if game_over:
		game_over._show_game_over()

func _on_victory() -> void:
	print("VICTORY!")
