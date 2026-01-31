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


func _ready() -> void:
	control.hide()
	GameManager.game_over.connect(_on_game_over)
	LocalizationManager.language_changed.connect(_update_texts)
	_update_texts()
	_setup_focus()


func _update_texts(_locale: String = "") -> void:
	title_label.text = tr("GAME_OVER_TITLE")
	restart_button.text = tr("GAME_OVER_REPLAY")
	main_menu_button.text = tr("PAUSE_MAIN_MENU")
	quit_button.text = tr("BTN_QUIT")


func _on_game_over() -> void:
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
	get_tree().paused = true
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	control.hide()
	SceneManager.reload_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	control.hide()
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _setup_focus() -> void:
	# Définir les voisins pour navigation verticale
	restart_button.focus_neighbor_top = quit_button.get_path()
	restart_button.focus_neighbor_bottom = main_menu_button.get_path()
	
	main_menu_button.focus_neighbor_top = restart_button.get_path()
	main_menu_button.focus_neighbor_bottom = quit_button.get_path()
	
	quit_button.focus_neighbor_top = main_menu_button.get_path()
	quit_button.focus_neighbor_bottom = restart_button.get_path()
