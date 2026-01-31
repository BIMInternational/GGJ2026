extends Node
class_name HealthComponent
## Composant réutilisable pour gérer la santé

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100

var current_health: int:
	set(value):
		var old_health = current_health
		current_health = clampi(value, 0, max_health)
		if current_health != old_health:
			health_changed.emit(current_health, max_health)
			if current_health <= 0:
				died.emit()


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	current_health -= amount


func heal(amount: int) -> void:
	current_health += amount


func is_alive() -> bool:
	return current_health > 0
