extends CharacterBody2D

class_name PlayerController

## Script du joueur (mouvement fluide avec inertie et rotation)

# Signals
signal died
signal respawned(position: Vector2)
signal took_damage(damage: int, health_remaining: int)
signal dashed
signal attack_started
signal attack_ended
signal mask_changed(new_mask: int)

# Mask types
# FIRE = Boule de feu (cd long)
# GAS = Boule de gaz (cd court)
# WATER = Trainée en avant
# ICE = Boule de glace gèle au contact
# LIGHTNING = Zone autour de toi
enum MaskType { FIRE, GAS, WATER, ICE, LIGHTNING }

# === MOVEMENT CONSTANTS ===
@export var speed: float = 400.0
@export var speed_boost: float = 1.5  # Multiplicateur de vitesse
@export var inertia: float = 0.15  # 0.0 = lourd, 1.0 = aérien

# Dash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# Attack
@export var attack_duration: float = 0.3
@export var attack_offset: float = 30.0  # Distance de spawn de l'attaque

# Attack Data pour tests
var fire_attack_data: AttackData = preload("res://src/combat/data/fire_attack.tres")
var gas_static_data: AttackData = preload("res://src/combat/data/gas_attack.tres")
var water_attack_data: AttackData = preload("res://src/combat/data/water_attack.tres")  # Trainée en avant
var ice_attack_data: AttackData = preload("res://src/combat/data/ice_attack.tres")  # Gèle au contact
var lightning_attack_data: AttackData = preload("res://src/combat/data/lightning_attack.tres")  # Zone autour

# Mask system
var available_masks: Array[MaskType] = [MaskType.FIRE, MaskType.GAS, MaskType.WATER, MaskType.ICE, MaskType.LIGHTNING]
var current_mask_index: int = 0

# === STATE VARIABLES ===
var direction: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _is_boosted: bool = false  # Pour un boost de vitesse (dash/skill)

# Dernière direction de mouvement pour les attaques
var _last_move_direction: Vector2 = Vector2.DOWN

# Timers
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _attack_timer: float = 0.0

# State flags
var _is_attacking: bool = false
var _is_dashing: bool = false

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null


func _ready() -> void:
	# Ajouter au groupe player pour la détection par les ennemis
	add_to_group("player")

	# Activer le tri en Y pour la profondeur (beat'em all style)
	y_sort_enabled = true

	# Démarrer avec l'animation Idle
	if animation_player and animation_player.has_animation("Idle"):
		animation_player.play("Idle")


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	# Permettre de changer de masque à tout moment
	if Input.is_action_just_pressed("switch_mask"):
		_switch_mask()
	
	# Ne pas traiter les autres inputs si en train d'attaquer ou de dasher
	if not _is_attacking and not _is_dashing:
		_handle_input()
	
	# Appliquer le mouvement
	_apply_movement(delta)
	
	# Rotation du sprite selon direction horizontale uniquement (beat'em all style)
	if _velocity.x != 0:
		sprite.flip_h = _velocity.x < 0
	
	set_velocity(_velocity)
	move_and_slide()
	
	# Mettre à jour le z_index basé sur la position Y pour le tri visuel
	z_index = int(global_position.y)
	
	# Gestion des animations selon le mouvement
	_update_animations()


func _update_animations() -> void:
	if animation_player == null:
		print("AnimationPlayer n'existe pas!")
		return
	
	# Ne pas changer l'animation pendant une attaque
	if _is_attacking:
		return
	
	# Vérifier si le personnage bouge
	var is_moving = _velocity.length() > 10
	
	if is_moving:
		if animation_player.has_animation("Move"):
			if animation_player.current_animation != "Move":
				animation_player.play("Move")
		else:
			print("Animation 'Move' introuvable. Animations disponibles: ", animation_player.get_animation_list())
	else:
		if animation_player.has_animation("Idle"):
			if animation_player.current_animation != "Idle":
				animation_player.play("Idle")
		else:
			print("Animation 'Idle' introuvable. Animations disponibles: ", animation_player.get_animation_list())


func _update_timers(delta: float) -> void:
	# Attack timer
	if _is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0:
			_end_attack()
	
	# Dash timers
	if _dash_timer > 0:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_end_dash()
	
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta


func _handle_input() -> void:
	# Lecture des inputs de déplacement
	direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	# Mettre à jour la dernière direction si le joueur bouge
	if direction.length() > 0.1:
		_last_move_direction = direction
	
	# Dash
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0:
		_perform_dash()
	
	# Attack avec Espace (jump)
	if Input.is_action_just_pressed("jump"):
		_spawn_attack(_get_current_attack_data())


func _apply_movement(_delta: float) -> void:
	if _is_dashing:
		# En dash, maintenir la vitesse constante
		_velocity = _velocity
	else:
		# Calculer la vitesse cible
		var speed_multiplier = speed_boost if _is_boosted else 1.0
		var target_velocity = direction * speed * speed_multiplier
		
		# Interpolation fluide avec inertie
		_velocity = lerp(_velocity, target_velocity, inertia)


func _perform_dash() -> void:
	# Direction du dash (input ou direction actuelle)
	var dash_dir = direction if direction.length() > 0.1 else Vector2(cos(sprite.rotation + deg_to_rad(90)), sin(sprite.rotation + deg_to_rad(90)))
	
	_velocity = dash_dir.normalized() * dash_speed
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	dashed.emit()


func _end_dash() -> void:
	_is_dashing = false


func _start_attack() -> void:
	_is_attacking = true
	_attack_timer = attack_duration
	attack_started.emit()


func _end_attack() -> void:
	_is_attacking = false
	attack_ended.emit()


## Active un boost de vitesse temporaire
func set_speed_boost(enabled: bool) -> void:
	_is_boosted = enabled


## Obtient la direction du regard pour les attaques
func get_facing_direction() -> Vector2:
	# Utiliser la dernière direction de mouvement
	return _last_move_direction.normalized()


## Respawns the player at a specific position
func respawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	_velocity = Vector2.ZERO
	_is_dashing = false
	_is_attacking = false
	respawned.emit(spawn_position)


## Handles taking damage (optional health system integration)
func take_damage(damage: int) -> void:
	took_damage.emit(damage, 0)


## Triggers death
func die() -> void:
	died.emit()


## Switch entre les masques disponibles
func _switch_mask() -> void:
	if available_masks.is_empty():
		return
	
	# Cycle vers le masque suivant
	current_mask_index = (current_mask_index + 1) % available_masks.size()
	var new_mask = available_masks[current_mask_index]
	
	mask_changed.emit(new_mask)
	print("Masque changé: ", _get_mask_name(new_mask))


## Retourne l'AttackData correspondant au masque équipé
func _get_current_attack_data() -> AttackData:
	if available_masks.is_empty():
		return fire_attack_data
	
	var current_mask = available_masks[current_mask_index]
	print("Index actuel: ", current_mask_index, " | Masque: ", _get_mask_name(current_mask))
	
	match current_mask:
		MaskType.FIRE:
			return fire_attack_data
		MaskType.GAS:
			return gas_static_data
		MaskType.WATER:
			return water_attack_data
		MaskType.ICE:
			return ice_attack_data
		MaskType.LIGHTNING:
			return lightning_attack_data
		_:
			return fire_attack_data  # Fallback


## Retourne le nom du masque pour le debug
func _get_mask_name(mask: MaskType) -> String:
	match mask:
		MaskType.FIRE:
			return "FIRE"
		MaskType.GAS:
			return "GAS"
		MaskType.WATER:
			return "WATER"
		MaskType.ICE:
			return "ICE"
		MaskType.LIGHTNING:
			return "LIGHTNING"
		_:
			return "UNKNOWN"


## Spawn une attaque à partir d'AttackData
func _spawn_attack(attack_data: AttackData) -> void:
	var attack_direction = get_facing_direction()
	
	# Inverser la direction si spécifié dans les data
	if attack_data.reverse_direction:
		attack_direction = -attack_direction
	
	# Position de spawn dans la direction de l'attaque
	var spawn_position = global_position + attack_direction * attack_offset

	# Utiliser le ChemistryManager pour spawn (disponible pour tous les acteurs)
	ChemistryManager.spawn_attack(attack_data, spawn_position, attack_direction, self)

	# Démarrer l'état d'attaque
	_start_attack()
