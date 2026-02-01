extends CanvasLayer

class_name GameOver

@onready var control: Control = $Control
@onready var title_label: Label = $Control/VBoxContainer/Title
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var best_score_label: Label = $Control/VBoxContainer/BestScoreLabel
@onready var restart_button: Button = $Control/VBoxContainer/ButtonsContainer/RestartButton
@onready var main_menu_button: Button = $Control/VBoxContainer/ButtonsContainer/MainMenuButton
@onready var quit_button: Button = $Control/VBoxContainer/ButtonsContainer/QuitButton

var current_scene_path: String = ""
var _auto_return_timer: float = 30.0
var _timer_active: bool = false


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	LocalizationManager.language_changed.connect(_update_texts)
	_update_texts()
	_setup_focus()
	
	# Cacher l'écran par défaut
	control.hide()


func _process(delta: float) -> void:
	if _timer_active:
		_auto_return_timer -= delta
		if _auto_return_timer <= 0:
			_timer_active = false
			_return_to_main_menu()


func _update_texts(_locale: String = "") -> void:
	title_label.text = tr("GAME_OVER_TITLE")
	restart_button.text = tr("GAME_OVER_REPLAY")
	main_menu_button.text = tr("PAUSE_MAIN_MENU")
	quit_button.text = tr("BTN_QUIT")


func _on_game_over() -> void:
	get_node('/root').find_child("InGameMusic", true, false).stop()
	get_node('/root').find_child("GameOverMusic", true, false).play()
	_show_game_over()


func _show_game_over() -> void:
	if SceneManager.current_scene:
		current_scene_path = SceneManager.current_scene.scene_file_path
	score_label.text = tr("GAME_OVER_SCORE") % GameManager.score
	
	# Charger et afficher le meilleur score
	var best_score = SaveManager.get_best_score()
	if GameManager.score > best_score:
		SaveManager.save_best_score(GameManager.score)
		best_score = GameManager.score
	
	best_score_label.text = tr("GAME_OVER_BEST_SCORE") % best_score
	control.show()
	get_tree().paused = false  # Ne pas mettre en pause pour permettre le timer
	restart_button.grab_focus()
	
	# Démarrer le timer de retour automatique (30 secondes)
	_auto_return_timer = 30.0
	_timer_active = true
	print("[GameOver] Timer de 30s démarré pour retour automatique au menu principal")


## Méthode publique pour démarrer le game over depuis l'extérieur
func start_gameover() -> void:
	_show_game_over()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	control.hide()
	SceneManager.reload_scene()


func _on_main_menu_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	_timer_active = false
	get_tree().paused = false
	control.hide()
	print("[GameOver] Retour au menu principal...")
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)


func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		# Sur web, retourner au menu principal
		_return_to_main_menu()
	else:
		get_tree().quit()


func _setup_focus() -> void:
	# Définir les voisins pour navigation verticale
	restart_button.focus_neighbor_top = quit_button.get_path()
	restart_button.focus_neighbor_bottom = main_menu_button.get_path()
	
	main_menu_button.focus_neighbor_top = restart_button.get_path()
	main_menu_button.focus_neighbor_bottom = quit_button.get_path()
	
	quit_button.focus_neighbor_top = main_menu_button.get_path()
	quit_button.focus_neighbor_bottom = restart_button.get_path()
