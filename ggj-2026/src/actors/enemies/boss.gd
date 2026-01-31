extends EnemyBase
class_name Boss

## Boss enemy with special attack

@export var special_attack_cooldown: float = 5.0
@export var special_attack_range: float = 300.0

var _special_cooldown_timer: float = 0.0

# Override sprite reference to use AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Set up the sprite reference BEFORE calling super._ready()
	# This prevents the parent from failing on null sprite
	sprite = null  # Explicitly null out parent's sprite reference
	
	super._ready()
	
	# Boss-specific stats
	speed = 60.0
	attack_damage = 25
	score_value = 1000
	
	# Connect animation finished signal for special attack
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Start with idle
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	_update_timers_boss(delta)
	
	# Skip parent's _physics_process to avoid sprite.flip_h error
	# Instead, replicate needed behavior here
	
	# Update attack cooldown (from parent)
	if _attack_cooldown_timer > 0:
		_attack_cooldown_timer -= delta
	
	# Apply knockback friction (from parent)
	_knockback_velocity = lerp(_knockback_velocity, Vector2.ZERO, knockback_friction)
	
	# Store movement direction before adding knockback
	var movement_direction = velocity.x
	
	# Combine AI movement with knockback
	velocity += _knockback_velocity
	move_and_slide()
	
	# Update z_index for visual sorting
	z_index = int(global_position.y)
	
	# Flip animated sprite based on direction
	if movement_direction != 0:
		animated_sprite.flip_h = movement_direction < 0
	
	_update_hitbox_position_boss()
	_update_boss_animations()


func _update_timers_boss(delta: float) -> void:
	# Update special attack cooldown
	if _special_cooldown_timer > 0:
		_special_cooldown_timer -= delta


func _update_hitbox_position_boss() -> void:
	if not attack_hitbox:
		return
	
	# Flip the hitbox to match animated sprite direction
	attack_hitbox.scale.x = -1.0 if animated_sprite.flip_h else 1.0


func _update_boss_animations() -> void:
	# Don't interrupt special attack animation
	if animated_sprite.animation == "special_attack" and animated_sprite.is_playing():
		return
	
	if velocity.length() > 10:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func can_special_attack() -> bool:
	return _special_cooldown_timer <= 0


func perform_special_attack() -> void:
	if not can_special_attack():
		return
	
	_special_cooldown_timer = special_attack_cooldown
	velocity = Vector2.ZERO  # Stop moving during attack
	animated_sprite.play("special_attack")
	
	# Spawn gas attack (matching the smoke in your sprite)
	var attack_data = load("res://src/combat/data/gas_attack.tres")
	var attack_dir = get_facing_direction()
	ChemistryManager.spawn_attack(attack_data, global_position + attack_dir * 80, attack_dir, self)


func _on_animation_finished() -> void:
	# Return to idle after special attack finishes
	if animated_sprite.animation == "special_attack":
		animated_sprite.play("idle")


## Override to use AnimatedSprite2D for facing direction
func get_facing_direction() -> Vector2:
	return Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)


## Override take_damage to use animated_sprite for flash effect if needed
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	health_component.take_damage(amount)
	
	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)
	
	if state_machine and state_machine.states.has("Hurt"):
		state_machine._on_transition_requested(state_machine.current_state, "Hurt")
