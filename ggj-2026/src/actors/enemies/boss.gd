extends EnemyBase
class_name Boss

## Boss enemy with special attack and entrance animation

@export var special_attack_cooldown: float = 5.0
@export var special_attack_range: float = 300.0

var _special_cooldown_timer: float = 0.0
var _has_entered: bool = false

var _is_laser_attacking: bool = false

# Override sprite reference to use AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var laser_hitbox: Area2D = $LaserHitbox
@onready var laser_animation_player: AnimationPlayer = $LaserAnimationPlayer
# Offset for laser animation (laser images are larger than normal 420px images)


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
	_has_entered = false


func _physics_process(delta: float) -> void:
	# Handle entrance animation
	if not _has_entered:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if _is_laser_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_hitbox_position_boss()
		return
		
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
	
	if laser_hitbox:
		laser_hitbox.scale.x = -1.0 if animated_sprite.flip_h else 1.0

func is_entering() -> bool:
	return not _has_entered

func _update_boss_animations() -> void:
	# Don't change animation during entrance or special attack
	if not _has_entered:
		return
	if _is_laser_attacking: 
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
func start_entrance(_duration: float = -1.0) -> void:
	velocity = Vector2.ZERO
	animated_sprite.flip_h = true
	animated_sprite.play("special")


func can_special_attack() -> bool:
	return _has_entered and _special_cooldown_timer <= 0 and not _is_laser_attacking


func perform_special_attack() -> void:
	if not can_special_attack():
		return
	
	_special_cooldown_timer = special_attack_cooldown
	_is_laser_attacking = true
	velocity = Vector2.ZERO
	
	get_node('/root').find_child("LaserSoundEffect", true, false).play()
	
	if target:
		animated_sprite.flip_h = target.global_position.x < global_position.x
	
	animated_sprite.play("laser")
	
	if laser_hitbox and laser_hitbox.has_method("reset_attack"):
		laser_hitbox.reset_attack()
	# Play the hitbox timing animation
	laser_animation_player.play("laser_hitbox")
	
	# Spawn gas attack (matching the smoke in your sprite)
	#var attack_data = load("res://src/combat/data/gas_attack.tres")
	#var attack_dir = get_facing_direction()
	#ChemistryManager.spawn_attack(attack_data, global_position + attack_dir * 80, attack_dir, self)


func _on_animation_finished() -> void:
	# Entrance finished
	if animated_sprite.animation == "special" and not _has_entered:
		_has_entered = true
		animated_sprite.play("idle")
		return
	
	# Laser attack finished
	if animated_sprite.animation == "laser":
		_is_laser_attacking = false
		animated_sprite.play("idle")
		return



## Override to use AnimatedSprite2D for facing direction
func get_facing_direction() -> Vector2:
	return Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)


## Override take_damage to ignore damage during entrance
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, _element: AttackData.ElementType = AttackData.ElementType.NONE, _play_sound: bool = true) -> void:
	# Optionally make boss invulnerable during entrance
	if not _has_entered:
		return

	# Boss has no element immunity, so just call parent logic directly
	health_component.take_damage(amount)

	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)

	if state_machine and state_machine.states.has("Hurt"):
		state_machine._on_transition_requested(state_machine.current_state, "Hurt")

func _on_laser_hit_landed(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var knockback_dir = get_facing_direction()
		body.take_damage(attack_damage * 2, knockback_dir)  # Maybe extra damage for laser?
