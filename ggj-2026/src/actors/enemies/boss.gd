extends EnemyBase
class_name Boss

## Boss enemy with special attack and entrance animation

@export var special_attack_cooldown: float = 5.0
@export var special_attack_range: float = 300.0
@export var entrance_duration: float = 3.0

var _special_cooldown_timer: float = 0.0
var _is_entering: bool = false
var _entrance_timer: float = 0.0

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
	# Handle entrance animation
	if _is_entering:
		_entrance_timer -= delta
		if _entrance_timer <= 0:
			_end_entrance()
		return  # Don't process anything else during entrance
	
	_update_timers_boss(delta)
	
	# Skip parent's _physics_process to avoid sprite.flip_h error
	# Instead, replicate needed behavior here
	
	# Update attack cooldown (from parent)
	if _attack_cooldown_timer > 0:
		_attack_cooldown_timer -= delta
	
	# Apply knockback friction (from parent)
	_knockback_velocity = lerp(_knockback_velocity, Vector2.ZERO, knockback_friction)
	
	# Store AI movement direction before adding knockback
	var ai_movement_direction = velocity.x
	
	# Combine AI movement with knockback
	velocity += _knockback_velocity
	move_and_slide()
	
	# Update z_index for visual sorting
	z_index = int(global_position.y)
	
	# Flip animated sprite based on AI direction only (not knockback)
	# Only flip if AI is moving AND there is almost no knockback
	if ai_movement_direction != 0 and _knockback_velocity.length() < 1.0:
		animated_sprite.flip_h = ai_movement_direction < 0
	
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
	# Don't change animation during entrance or special attack
	if _is_entering:
		return
	if animated_sprite.animation == "special" and animated_sprite.is_playing():
		return
	
	if velocity.length() > 10:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


## Start the boss entrance animation
func start_entrance(duration: float = -1.0) -> void:
	if duration < 0:
		duration = entrance_duration
	
	print("[Boss] Starting entrance animation for ", duration, " seconds")
	_is_entering = true
	_entrance_timer = duration
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Face the player (usually left)
	animated_sprite.flip_h = true
	
	# Play the special/entrance animation
	animated_sprite.play("special")


## End the entrance and start normal behavior
func _end_entrance() -> void:
	print("[Boss] Entrance finished, starting normal behavior")
	_is_entering = false
	
	# Return to idle animation
	animated_sprite.play("idle")
	
	# State machine will take over from here


## Check if boss is currently in entrance animation
func is_entering() -> bool:
	return _is_entering


func can_special_attack() -> bool:
	return _special_cooldown_timer <= 0 and not _is_entering


func perform_special_attack() -> void:
	if not can_special_attack():
		return
	
	_special_cooldown_timer = special_attack_cooldown
	velocity = Vector2.ZERO  # Stop moving during attack
	animated_sprite.play("special")
	
	# Spawn gas attack (matching the smoke in your sprite)
	var attack_data = load("res://src/combat/data/gas_attack.tres")
	var attack_dir = get_facing_direction()
	ChemistryManager.spawn_attack(attack_data, global_position + attack_dir * 80, attack_dir, self)


func _on_animation_finished() -> void:
	# Don't auto-return to idle if we're in entrance mode (timer handles that)
	if _is_entering:
		# Loop the special animation during entrance
		animated_sprite.play("special")
		return
	
	# Return to idle after special attack finishes
	if animated_sprite.animation == "special":
		animated_sprite.play("idle")


## Override to use AnimatedSprite2D for facing direction
func get_facing_direction() -> Vector2:
	return Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)


## Override take_damage to ignore damage during entrance
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	# Optionally make boss invulnerable during entrance
	if _is_entering:
		print("[Boss] Immune during entrance!")
		return
	
	health_component.take_damage(amount)
	
	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)
	
	if state_machine and state_machine.states.has("Hurt"):
		state_machine._on_transition_requested(state_machine.current_state, "Hurt")
