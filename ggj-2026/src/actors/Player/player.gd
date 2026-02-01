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
enum MaskType {FIRE, GAS, WATER, ICE, LIGHTNING}

# === MOVEMENT CONSTANTS ===
@export var speed: float = 400.0
@export var speed_boost: float = 1.5 # Multiplicateur de vitesse
@export var inertia: float = 0.15 # 0.0 = lourd, 1.0 = aérien

# Dash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# Attack
@export var attack_duration: float = 0.3
@export var attack_offset: float = 30.0 # Distance de spawn de l'attaque

# Attack Data pour tests
var fire_attack_data: AttackData = preload("res://src/combat/data/fire_attack.tres")
var gas_static_data: AttackData = preload("res://src/combat/data/gas_attack.tres")
var water_attack_data: AttackData = preload("res://src/combat/data/water_attack.tres") # Trainée en avant
var ice_attack_data: AttackData = preload("res://src/combat/data/ice_attack.tres") # Gèle au contact
var lightning_attack_data: AttackData = preload("res://src/combat/data/lightning_attack.tres") # Zone autour

# Tumbleweed
var tumbleweed_scene: PackedScene = preload("res://src/actors/world/tumbleweed.tscn")
@export var tumbleweed_min_interval: float = 5.0
@export var tumbleweed_max_interval: float = 15.0

# Mask system
var available_masks: Array[MaskType] = [MaskType.FIRE, MaskType.WATER, MaskType.ICE, MaskType.LIGHTNING, MaskType.GAS]
var current_mask_index: int = 0

# === STATE VARIABLES ===
var direction: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _is_boosted: bool = false # Pour un boost de vitesse (dash/skill)

# Dernière direction de mouvement pour les attaques
var _last_move_direction: Vector2 = Vector2.DOWN

# Timers
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _attack_timer: float = 0.0
var _invulnerability_timer: float = 0.0
var _hurt_timer: float = 0.0
var _mask_change_timer: float = 0.0

# State flags
var _is_attacking: bool = false
var _is_dashing: bool = false
var _is_hurt: bool = false
var _is_changing_mask: bool = false
var _is_dead: bool = false

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_mask: Sprite2D = $Sprite2DMasque if has_node("Sprite2DMasque") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var animation_mask: AnimationPlayer = $AnimationMask if has_node("AnimationMask") else null
@onready var health_component: HealthComponent = $HealthComponent
@onready var tumbleweed_timer: Timer = $Tumbleweed/TimerTumbleweed if has_node("Tumbleweed/TimerTumbleweed") else null


func _ready() -> void:
	# Ajouter au groupe player pour la détection par les ennemis
	add_to_group("player")

	# Activer le tri en Y pour la profondeur (beat'em all style)
	y_sort_enabled = true
	
	# Connecter le signal died du HealthComponent
	if health_component:
		health_component.died.connect(_on_health_depleted)
		print("[Player] Points de vie: ", health_component.current_health, "/", health_component.max_health)

	# Démarrer avec l'animation Idle
	_update_animations()

	# Setup tumbleweed timer
	if tumbleweed_timer:
		tumbleweed_timer.timeout.connect(_on_tumbleweed_timer_timeout)
		_start_tumbleweed_timer()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	# Si mort, ne rien faire du tout
	if _is_dead:
		return
	
	# Permettre de changer de masque à tout moment (sauf si déjà en train de changer)
	if Input.is_action_just_pressed("switch_mask") and not _is_changing_mask:
		_switch_mask()
	
	# Ne pas traiter les autres inputs si en train d'attaquer ou de dasher ou hurt ou mask change
	if not _is_attacking and not _is_dashing and not _is_hurt and not _is_changing_mask:
		_handle_input()
	else:
		# Forcer la direction à zéro si on ne peut pas bouger
		if _is_hurt or _is_changing_mask:
			direction = Vector2.ZERO
	
	# Appliquer le mouvement
	_apply_movement(delta)
	
	# Rotation du sprite selon direction horizontale uniquement (beat'em all style)
	# Ne flip que si c'est un mouvement volontaire (pas du knockback)
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
		sprite_mask.flip_h = direction.x < 0
	
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
	
	# Ne pas changer l'animation pendant une attaque, hurt, mask change ou mort
	if _is_attacking or _is_hurt or _is_changing_mask or _is_dead:
		return
	
	# Vérifier si le personnage bouge
	var is_moving = _velocity.length() > 10
	
	if is_moving:
		if animation_player.has_animation("Move"):
			if animation_player.current_animation != "Move":
				_play_animation("Move", "Move")
		else:
			print("Animation 'Move' introuvable. Animations disponibles: ", animation_player.get_animation_list())
	else:
		# Essayer l'animation Idle spécifique au masque, sinon fallback sur "Idle"
		var idle_anim_name = _get_idle_animation_name()
		var anim_to_play = "Idle" # Par défaut
		
		if animation_player.has_animation(idle_anim_name):
			anim_to_play = idle_anim_name
		elif animation_player.has_animation("Idle"):
			anim_to_play = "Idle"
		
		if animation_player.current_animation != anim_to_play:
			_play_animation(anim_to_play, "Idle")


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
	
	# Invulnerability timer
	if _invulnerability_timer > 0:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0:
			print("[Player] Fin de l'invulnérabilité")
	
	# Hurt timer
	if _is_hurt:
		_hurt_timer -= delta
		if _hurt_timer <= 0:
			_is_hurt = false
			print("[Player] Fin de l'état hurt")
	
	# Mask change timer
	if _is_changing_mask:
		_mask_change_timer -= delta
		if _mask_change_timer <= 0:
			_is_changing_mask = false
			# Forcer la mise à jour de l'animation Idle après le changement de masque
			_update_animations()


func _handle_input() -> void:
	# Lecture des inputs de déplacement
	direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	if(direction.length() > 0):
		if(get_node('/root').find_child("ScooterSoundEffect", true, false).playing == false):
			get_node('/root').find_child("ScooterSoundEffect", true, false).play()
	else:
		get_node('/root').find_child("ScooterSoundEffect", true, false).stop()
	
	# Mettre à jour la dernière direction si le joueur bouge
	if direction.length() > 0.1:
		_last_move_direction = direction
	
	# Dash
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0:
		_perform_dash()
		get_node('/root').find_child("DashSoundEffect", true, false).play()
	
	# Attack avec Espace (jump)
	if Input.is_action_just_pressed("jump"):
		_spawn_attack(_get_current_attack_data())

func _apply_movement(_delta: float) -> void:
	if _is_dashing:
		# En dash, maintenir la vitesse constante
		_velocity = _velocity
	elif _is_hurt:
		# En état hurt, appliquer une friction très légère pour laisser le knockback agir
		_velocity *= 0.95
		
	elif _is_changing_mask:
		# En état mask change, ralentir progressivement
		_velocity = lerp(_velocity, Vector2.ZERO, 0.2)
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
	
	# Lancer l'animation Attack
	_play_animation("Attack", "Attack")


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
func take_damage(damage: int, knockback_dir: Vector2 = Vector2.ZERO, _element: AttackData.ElementType = AttackData.ElementType.NONE, _play_sound: bool = true) -> void:
	print("[Player] take_damage appelé, damage=", damage, " knockback_dir=", knockback_dir)
	# Ignorer si mort ou invulnérable
	if _is_dead or _invulnerability_timer > 0:
		print("[Player] Invulnérable ou mort, dégâts ignorés")
		return
	
	if health_component:
		health_component.take_damage(damage)
		took_damage.emit(damage, health_component.current_health)
		print("[Player] PV restants: ", health_component.current_health, "/", health_component.max_health)
		
		# Activer l'état hurt
		_is_hurt = true
		_hurt_timer = 0.5 # Ne peut rien faire pendant 0.5s
		_invulnerability_timer = 0.6 # Invulnérable pendant 0.6s
		get_node('/root').find_child("AbuelitaHurtSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
		get_node('/root').find_child("AbuelitaHurtSoundEffect", true, false).play()
		print("[Player] État hurt activé")
		
		if (health_component.current_health <= 0):
			print("[Player] PV à 0 ou moins, déclenchement de la mort")
			_on_health_depleted()
			return
		# Lancer l'animation Domage
		_play_animation("Domage", "Domage")
		
		# Appliquer le knockback
		if knockback_dir != Vector2.ZERO:
			_velocity = knockback_dir.normalized() * 800.0
			print("[Player] Knockback appliqué: ", _velocity)
		else:
			print("[Player] Pas de knockback (direction = zero)")


## Appelé quand les points de vie atteignent 0
func _on_health_depleted() -> void:
	print("[Player] Points de vie épuisés!")
	get_node('/root').find_child("AbuelitaDeadSoundEffect", true, false).play()
	die()


## Triggers death
func die() -> void:
	if _is_dead: # Déjà mort ou en train de mourir
		return
	
	print("[Player] Mort du joueur")
	
	# Activer l'état de mort
	_is_dead = true
	
	# Bloquer tous les mouvements et actions
	_is_hurt = false
	_is_attacking = false
	_is_dashing = false
	_is_changing_mask = false
	_velocity = Vector2.ZERO
	direction = Vector2.ZERO
	
	# Rendre invulnérable pendant la mort (1.5s)
	_invulnerability_timer = 1.5
	
	# Animation de mort
	_play_animation("Death", "Death")
	
	# Émettre le signal de mort
	died.emit()
	
	# Attendre la fin de l'animation de mort (1.5 secondes)
	await get_tree().create_timer(1.5).timeout
	print("[Player] Animation de mort terminée")
	
	# Le level_01.gd gère le game over via le signal died


## Switch entre les masques disponibles
func _switch_mask() -> void:
	if available_masks.is_empty():
		return
	
	# Activer l'état de changement de masque
	_is_changing_mask = true
	_mask_change_timer = 0.3
	
	# Cycle vers le masque suivant
	current_mask_index = (current_mask_index + 1) % available_masks.size()
	var new_mask = available_masks[current_mask_index]
	
	mask_changed.emit(new_mask)
	print("Masque changé: ", _get_mask_name(new_mask))

	# Lancer l'animation Mask_Change
	_play_animation("Mask_Change", "Mask_Change")


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
			return fire_attack_data # Fallback


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


## Retourne le nom de l'animation Idle correspondant au masque équipé
func _get_idle_animation_name() -> String:
	if available_masks.is_empty():
		return "Idle_FIRE" # Par défaut
	
	var current_mask = available_masks[current_mask_index]
	match current_mask:
		MaskType.FIRE:
			return "Idle_FIRE"
		MaskType.GAS:
			return "Idle_GAS"
		MaskType.WATER:
			return "Idle_WATER"
		MaskType.ICE:
			return "Idle_ICE"
		MaskType.LIGHTNING:
			return "Idle_LIGHTNING"
		_:
			return "Idle_FIRE" # Fallback


## Joue une animation sur le personnage ET le masque
func _play_animation(base_anim: String, mask_suffix: String = "") -> void:
	# Jouer l'animation de base sur le personnage
	if animation_player and animation_player.has_animation(base_anim):
		animation_player.play(base_anim)
	
	# Jouer l'animation du masque si disponible
	if animation_mask and mask_suffix != "":
		var mask_anim = mask_suffix + "_" + _get_mask_name(available_masks[current_mask_index])
		if animation_mask.has_animation(mask_anim):
			animation_mask.play(mask_anim)
			print("[Player] Animation Mask lancée: ", mask_anim)


## Spawn une attaque à partir d'AttackData
func _spawn_attack(attack_data: AttackData) -> void:
	var attack_direction = get_facing_direction()
	
	# Inverser la direction si spécifié dans les data
	if attack_data.reverse_direction:
		attack_direction = - attack_direction
	
	# Position de spawn dans la direction de l'attaque
	var spawn_position = global_position + attack_direction * attack_offset
	match available_masks[current_mask_index]: 
		MaskType.FIRE:
			get_node('/root').find_child("FireballSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
			get_node('/root').find_child("FireballSoundEffect", true, false).play()
		MaskType.GAS:
			get_node('/root').find_child("FartSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
			get_node('/root').find_child("FartSoundEffect", true, false).play()
		MaskType.WATER:
			get_node('/root').find_child("WaterballSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
			get_node('/root').find_child("WaterballSoundEffect", true, false).play()
		MaskType.ICE:
			get_node('/root').find_child("IceballSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
			get_node('/root').find_child("IceballSoundEffect", true, false).play()
		MaskType.LIGHTNING:
			get_node('/root').find_child("ElectricityballSoundEffect", true, false).pitch_scale = randf_range(0.85, 1.15)
			get_node('/root').find_child("ElectricityballSoundEffect", true, false).play()

	# Utiliser le ChemistryManager pour spawn (disponible pour tous les acteurs)
	ChemistryManager.spawn_attack(attack_data, spawn_position, attack_direction, self )

	# Démarrer l'état d'attaque
	_start_attack()


## Start the tumbleweed timer with a random interval
func _start_tumbleweed_timer() -> void:
	if tumbleweed_timer:
		var random_time = randf_range(tumbleweed_min_interval, tumbleweed_max_interval)
		tumbleweed_timer.wait_time = random_time
		tumbleweed_timer.one_shot = true
		tumbleweed_timer.start()


## Called when the tumbleweed timer times out
func _on_tumbleweed_timer_timeout() -> void:
	_spawn_tumbleweed()
	_start_tumbleweed_timer()


## Spawn a tumbleweed that rolls across the screen
func _spawn_tumbleweed() -> void:
	if tumbleweed_scene == null:
		return

	var tumbleweed = tumbleweed_scene.instantiate()

	# Get camera and viewport info
	var camera = $Camera2D as Camera2D
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom if camera else Vector2.ONE

	# Calculate visible area based on camera
	var visible_width = viewport_size.x / zoom.x

	# Random direction (left or right)
	var tumbleweed_direction = Vector2.LEFT # if randf() > 0.5 else Vector2.RIGHT

	# Spawn position: off-screen on the opposite side
	var spawn_x: float
	if tumbleweed_direction == Vector2.RIGHT:
		spawn_x = global_position.x - visible_width / 2 - 100
	else:
		spawn_x = global_position.x + visible_width / 2 + 100

	# Random Y position within the visible area (lower part of screen for ground level)
	var spawn_y = global_position.y + randf_range(-100, 200)

	tumbleweed.global_position = Vector2(spawn_x, spawn_y)

	# Travel distance: full visible width plus margins on both sides
	var travel_distance = visible_width + 400.0
	tumbleweed.setup(tumbleweed_direction, spawn_y, travel_distance)

	# Add to the scene tree (parent of player, usually the level)
	get_parent().add_child(tumbleweed)
