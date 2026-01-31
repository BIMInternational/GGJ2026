extends CharacterBody2D
class_name EnemyBase

## Script de base pour les ennemis (beat'em up)

signal died(enemy: EnemyBase)

# === EXPORTS ===
@export var speed: float = 80.0
@export var attack_range: float = 50.0
@export var detection_range: float = 2000.0
@export var score_value: int = 100
@export var knockback_friction: float = 1.0
@export var knockback_force: float = 20.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5

# === REFERENCES ===
@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox

# === STATE ===
var target: Node2D = null
var _knockback_velocity: Vector2 = Vector2.ZERO
var _attack_cooldown_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	y_sort_enabled = true
	health_component.died.connect(_on_died)

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

	# Combiner le mouvement AI avec le knockback
	velocity += _knockback_velocity
	move_and_slide()

	# Mise à jour du z_index pour le tri visuel
	z_index = int(global_position.y)

	# Orienter le sprite selon la direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		
	_update_hitbox_position()

func _update_hitbox_position() -> void:
	if not attack_hitbox:
		return
	
	# Flip the hitbox to match sprite direction
	attack_hitbox.scale.x = -1.0 if sprite.flip_h else 1.0

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


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	health_component.take_damage(amount)

	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)

	if state_machine and state_machine.states.has("Hurt"):
		state_machine._on_transition_requested(state_machine.current_state, "Hurt")


func _on_died() -> void:
	GameManager.score += score_value
	died.emit(self)
	queue_free()


func get_facing_direction() -> Vector2:
	return Vector2(-1, 0) if sprite.flip_h else Vector2(1, 0)
