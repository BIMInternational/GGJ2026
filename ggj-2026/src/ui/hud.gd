extends CanvasLayer

class_name HUD

@onready var score_label: Label = $MarginContainer/HBoxContainerScore/VBoxContainerScore/HBoxContainerScore/ScoreLabel
@onready var timer_label: Label = $MarginContainer/HBoxContainerScore/VBoxContainerScore/TimerLabel
@onready var health_bar: ProgressBar = $MarginContainer/HBoxContainerP1/VBoxContainerP1/HealthBarP1
@onready var name_label_p1: Label = $MarginContainer/HBoxContainerP1/VBoxContainerP1/NameLabelP1

var _last_time_displayed: int = -1
var _player: PlayerController = null
@export var countdown_time: float = 180.0  # Temps en secondes (3 minutes par défaut)
var _current_time: float = 0.0


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	
	# Initialiser le compte à rebours
	_current_time = countdown_time
	_update_timer_display()
	
	# Trouver le joueur dans la scène
	await get_tree().process_frame
	_find_player()


func _process(delta: float) -> void:
	# Décompter le temps
	if _current_time > 0:
		_current_time -= delta
		_current_time = max(_current_time, 0.0)  # Ne pas descendre en dessous de 0
		_update_timer_display()
	elif _current_time == 0:
		_on_timer_finished()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as PlayerController
		if _player and _player.health_component:
			_player.health_component.health_changed.connect(_on_player_health_changed)
			_player.took_damage.connect(_on_player_took_damage)
			# Initialiser l'affichage
			_update_health_display(_player.health_component.current_health, _player.health_component.max_health)
			_update_lives_display(3)  # Valeur par défaut, sera mis à jour par le GameManager


func _update_health_display(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
		# Transition dégressive du vert vers le rouge en passant par l'orange
		var health_percent = clamp(float(current_health) / float(max_health), 0.0, 1.0)
		var style = StyleBoxFlat.new()
		
		# Interpolation en deux phases pour passer par l'orange à 50%
		if health_percent > 0.5:
			# 100% -> 50%: Vert vers Orange
			var green_color = Color(0, 1, 0)
			var orange_color = Color(1, 0.65, 0)
			var t = (health_percent - 0.5) / 0.5  # 0 à 1 pour cette phase
			style.bg_color = orange_color.lerp(green_color, t)
		else:
			# 50% -> 0%: Orange vers Rouge
			var orange_color = Color(1, 0.65, 0)
			var red_color = Color(1, 0, 0)
			var t = health_percent / 0.5  # 0 à 1 pour cette phase
			style.bg_color = red_color.lerp(orange_color, t)
		
		health_bar.add_theme_stylebox_override("fill", style)


func _update_lives_display(_lives: int) -> void:
	# Cette fonction n'est plus utilisée car pas de label de vies
	pass


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_update_health_display(current_health, max_health)


func _on_player_took_damage(_damage: int, health_remaining: int) -> void:
	if _player and _player.health_component:
		_update_health_display(health_remaining, _player.health_component.max_health)


func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score


func _update_timer_display() -> void:
	var time_int: int = int(_current_time)
	if time_int != _last_time_displayed:
		_last_time_displayed = time_int
		var minutes: int = int(time_int / 60.0)
		var seconds: int = time_int % 60
		timer_label.text = "Time: %d:%02d" % [minutes, seconds]


func _on_timer_finished() -> void:
	print("[HUD] Temps écoulé!")
	# Vous pouvez ajouter ici ce qui se passe quand le temps est écoulé
	# Par exemple: GameManager.end_game()


func update_timer(time: float) -> void:
	_current_time = time
	_update_timer_display()
