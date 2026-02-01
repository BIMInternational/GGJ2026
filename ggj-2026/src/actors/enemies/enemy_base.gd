extends CharacterBody2D
class_name EnemyBase

## Script de base pour les ennemis (beat'em up)

signal died(enemy: EnemyBase)

# === EXPORTS ===
@export var speed: float = 80.0
@export var attack_range: float = 50.0
@export var detection_range: float = 2000.0
@export var score_value: int = 100
@export var knockback_friction: float = 0.05
@export var knockback_force: float = 800.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5

# === REFERENCES ===
@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var sprite_hairs: Sprite2D = get_node_or_null("Sprite2DHairs")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var animation_player_hairs: AnimationPlayer = get_node_or_null("AnimationPlayerHairs")
@onready var punk_hairs: Node2D = get_node_or_null("PunkHairs")
var hair: Sprite2D = null
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var immune_label: Label = get_node_or_null("Label")

# === STATE ===
var target: Node2D = null
var _knockback_velocity: Vector2 = Vector2.ZERO
var _attack_cooldown_timer: float = 0.0
var _is_attacking: bool = false
var immune_element: AttackData.ElementType = AttackData.ElementType.NONE

func _ready() -> void:
	add_to_group("enemies")
	y_sort_enabled = true
	health_component.died.connect(_on_died)

	# Cacher le label d'immunité
	if immune_label:
		immune_label.hide()

	# Randomize hair color
	_randomize_hair_color()

	# Connecter la hitbox d'attaque au state machine
	if attack_hitbox:
		attack_hitbox.deactivate()

	# Trouver le joueur dans la scène
	await get_tree().process_frame
	target = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	# Update attack cooldown
	if _attack_cooldown_timer > 0:
		_attack_cooldown_timer -= delta
	
	# Appliquer la décélération du knockback
	_knockback_velocity = lerp(_knockback_velocity, Vector2.ZERO, knockback_friction)

	# Stocker la direction AI avant d'ajouter le knockback
	var ai_movement_direction = velocity.x
	
	# Combiner le mouvement AI avec le knockback
	velocity += _knockback_velocity
	move_and_slide()

	# Mise à jour du z_index pour le tri visuel
	z_index = int(global_position.y)

	# Orienter le sprite selon la direction AI uniquement (pas le knockback)
	# Ne retourner que si c'est un mouvement volontaire, qu'il n'y a presque pas de knockback
	# et que l'ennemi n'est pas en train d'attaquer
	var is_attacking = state_machine.current_state is EnemyAttackState
	if ai_movement_direction != 0 and _knockback_velocity.length() < 1.0 and not is_attacking:
		sprite.flip_h = ai_movement_direction < 0
		# Synchroniser le flip des cheveux
		if sprite_hairs:
			sprite_hairs.flip_h = ai_movement_direction < 0
		
	_update_hitbox_position()

func _update_hitbox_position() -> void:
	if not attack_hitbox:
		return
	
	if not sprite:
		return
	
	# Flip the hitbox to match sprite direction
	attack_hitbox.scale.x = -1.0 if sprite.flip_h else 1.00

func enable_attack_hitbox(enabled: bool) -> void:
	if attack_hitbox:
		if enabled:
			attack_hitbox.activate()
		else:
			attack_hitbox.deactivate()
			
func can_attack() -> bool:
	return _attack_cooldown_timer <= 0
	
func start_attack_cooldown() -> void:
	_attack_cooldown_timer = attack_cooldown
	
func _on_attack_hit_landed(body: Node2D) -> void:
	# Propager au state machine si en état Attack
	if state_machine.current_state is EnemyAttackState:
		state_machine.current_state.on_attack_hit(body)

func apply_knockback(direction: Vector2, force: float = knockback_force) -> void:
	_knockback_velocity = direction.normalized() * force


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, element: AttackData.ElementType = AttackData.ElementType.NONE, play_sound: bool = true) -> void:
	 
	# Check immunity based on hair color
	if element != AttackData.ElementType.NONE and element == immune_element:
		# Afficher le label d'immunité pendant 2.5 secondes
		if immune_label:
			immune_label.show()
			await get_tree().create_timer(2.5).timeout
			immune_label.hide()
		return  # Immune to this element

	health_component.take_damage(amount)

	# Appliquer le knockback et l'état Hurt même si mort (pour l'animation Domage)
	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)

	if state_machine and state_machine.states.has("Hurt"):
		state_machine._on_transition_requested(state_machine.current_state, "Hurt")


func _on_died() -> void:
	print("[Enemy] _on_died appelé pour ", name)
	
	# Empêcher les multiples appels
	if is_queued_for_deletion():
		print("[Enemy] Déjà en file de suppression, abandon")
		return
	
	print("[Enemy] Score ajouté: ", score_value)
	GameManager.score += score_value
	
	# Désactiver l'IA mais garder la physique pour le knockback
	print("[Enemy] Désactivation de l'IA")
	if state_machine:
		state_machine.set_physics_process(false)
	if attack_hitbox:
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.set_deferred("monitorable", false)
	
	# Attendre que l'animation Domage se termine (durée de hitstun + un peu de marge)
	print("[Enemy] Attente de la fin de l'animation Domage")
	await get_tree().create_timer(0.4).timeout
	
	# Désactiver la physique maintenant
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# Jouer l'animation de mort si disponible
	if animation_player and animation_player.has_animation("Death"):
		print("[Enemy] Lecture de l'animation Death")
		play_animation("Death")
		# Attendre la fin de l'animation avant de détruire
		await animation_player.animation_finished
		print("[Enemy] Animation Death terminée")
	else:
		print("[Enemy] Pas d'animation Death, attente de 0.5s")
		# Si pas d'animation, attendre un peu quand même
		await get_tree().create_timer(0.5).timeout
	
	print("[Enemy] Émission du signal died et destruction")
	died.emit(self)
	queue_free()


func play_animation(anim_name: String) -> void:
	# Jouer l'animation du corps
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
	
	# Jouer l'animation des cheveux (même nom d'animation)
	if animation_player_hairs and animation_player_hairs.has_animation(anim_name):
		if animation_player_hairs.current_animation != anim_name:
			animation_player_hairs.play(anim_name)


func get_facing_direction() -> Vector2:
	return Vector2(-1, 0) if sprite.flip_h else Vector2(1, 0)


func _randomize_hair_color() -> void:
	if not punk_hairs:
		return

	var hair_options = punk_hairs.get_children()
	if hair_options.is_empty():
		return

	# Hide all hair options
	for h in hair_options:
		h.visible = false

	# Pick a random one and make it visible
	var random_index = randi() % hair_options.size()
	hair = hair_options[random_index]

	# Set immunity based on hair color and load corresponding texture
	var hair_texture_path = ""
	match hair.name:
		"Red":
			immune_element = AttackData.ElementType.FIRE
			hair_texture_path = "res://assets/sprites/Punk-Hair-FIRE.png"
		"Blue":
			immune_element = AttackData.ElementType.WATER
			hair_texture_path = "res://assets/sprites/Punk-Hair-WATER.png"
		"Green":
			immune_element = AttackData.ElementType.GAS
			hair_texture_path = "res://assets/sprites/Punk-Hair-GAS.png"
		"White":
			immune_element = AttackData.ElementType.ICE
			hair_texture_path = "res://assets/sprites/Punk-Hair-ICE.png"
		"Yellow":
			immune_element = AttackData.ElementType.ELECTRIC
			hair_texture_path = "res://assets/sprites/Punk-Hair-ELECTRIC.png"
		_:
			immune_element = AttackData.ElementType.NONE
			hair_texture_path = "res://assets/sprites/Punk.png"  # Fallback
	
	# Appliquer la texture aux cheveux sur Sprite2DHairs
	if sprite_hairs:
		sprite_hairs.texture = load(hair_texture_path)
		print("[Enemy] Texture des cheveux chargée: ", hair_texture_path)
