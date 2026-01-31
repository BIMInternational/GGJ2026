extends CanvasLayer

class_name HUD

@onready var score_label: Label = $MarginContainer/ScoreLabel
@onready var timer_label: Label = $MarginContainer/TimerLabel

var _last_time_displayed: int = -1


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
	# Mettre à jour le timer basé sur le score (score = temps * 100)
	var current_time: int = int(new_score / 100.0)
	if current_time != _last_time_displayed:
		_last_time_displayed = current_time
		var minutes: int = int(current_time / 60.0)
		var seconds: int = current_time % 60
		timer_label.text = "Time: %d:%02d" % [minutes, seconds]


func update_timer(time: float) -> void:
	var time_int: int = int(time)
	if time_int != _last_time_displayed:
		_last_time_displayed = time_int
		var minutes: int = int(time_int / 60.0)
		var seconds: int = time_int % 60
		timer_label.text = "Time: %d:%02d" % [minutes, seconds]
