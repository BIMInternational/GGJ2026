extends Node
class_name StateMachine
## State machine simple pour gérer les états d'un personnage/ennemi

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	# Récupérer tous les états enfants
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition_requested.connect(_on_transition_requested)
	
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_transition_requested(from_state: State, to_state_name: String) -> void:
	if from_state != current_state:
		return
	
	var new_state = states.get(to_state_name)
	if not new_state:
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
