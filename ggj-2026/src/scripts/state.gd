extends Node
class_name State
## Classe de base pour les états

signal transition_requested(from_state: State, to_state_name: String)

@onready var parent = get_parent()


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
