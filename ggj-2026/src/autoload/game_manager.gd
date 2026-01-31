extends Node
## Gestionnaire global du jeu
## Utiliser pour gérer l'état du jeu, les scores, etc.

signal game_started
signal game_over
signal score_changed(new_score: int)

var _score: int = 0
var score: int:
	get: return _score
	set(value):
		_score = value
		score_changed.emit(_score)

var _is_game_running: bool = false
var is_game_running: bool:
	get: return _is_game_running
	set(value): _is_game_running = value


func start_game() -> void:
	_score = 0
	score_changed.emit(_score)
	_is_game_running = true
	game_started.emit()


func end_game() -> void:
	_is_game_running = false
	game_over.emit()


func add_score(points: int) -> void:
	_score += points
	score_changed.emit(_score)
