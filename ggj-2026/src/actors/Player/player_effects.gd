extends Node2D

class_name PlayerEffects

# 💡 Ideas
# respawned: Reset camera position, play respawn animation/particles, update checkpoint UI, grant temporary invincibility
# took_damage: Update health bar UI, play hurt sound/animation, flash screen red, trigger knockback
# died: Die sound, animation, respawn, remove lives

# jumped: Jump sound, particle effects, camera bump
# wall_jumped: Different sound than regular jump, wall dust particles
# landed: Landing sound, dust particles, screen shake (heavy landing), squash animation
# dash_recharged: Flash dash UI indicator, play subtle "ready" sound, show visual feedback

# attack_started: Swing sound, weapon trail effect
# attack_ended: Cleanup effects, cooldown UI
# attack_hit: Hit sound, impact particles, screen shake, damage numbers, freeze frame


## Handles effects for the player (responds to player signals)

@onready var _particle_manager: ParticleManager = $ParticleManager

# === PARTICLE SCENE REFERENCES ===
@export_group("Particle Scenes")
@export var jump_particles: PackedScene
@export var land_particles: PackedScene
@export var dash_burst_particles: PackedScene
@export var wall_slide_particles: PackedScene
@export var wall_jump_particles: PackedScene
@export var attack_trail_particles: PackedScene
@export var hit_impact_particles: PackedScene

# === DASH TRAIL SETTINGS ===
@export_group("Dash Trail")
@export var dash_trail_enabled: bool = true
@export var dash_trail_length: int = 10
@export var dash_trail_spacing: float = 0.02
@export var dash_trail_color: Color = Color.WHITE
var _dash_trail_timer: float = 0.0
var _is_dashing: bool = false

# === WALL SLIDE SETTINGS === (DÉSACTIVÉ)
# @export_group("Wall Slide")
# @export var wall_slide_particle_rate: float = 0.05  # Spawn every 0.05 seconds


var _player: PlayerController


func _ready() -> void:
	# Get player reference
	_player = get_parent() as PlayerController
	_connect_signals()


func _process(delta: float) -> void:
	if not _player:
		return

	_update_dash_trail(delta)
	# Wall slide particles désactivés (fonctionnalité non disponible)
	# _update_wall_slide_particles(delta)


## Connect to all player signals
func _connect_signals() -> void:
	# Movement signals
	_player.died.connect(_on_player_died)
	_player.respawned.connect(_on_player_respawned)
	_player.dashed.connect(_on_player_dashed)
	
	# Note: jumped, landed, wall_jumped, wall_slide_started, dash_recharged 
	# ne sont plus disponibles dans la nouvelle version simplifiée du player

	# Combat signals
	_player.attack_started.connect(_on_attack_started)


## === MOVEMENT EFFECTS === (DÉSACTIVÉS - pas de saut/atterrissage dans cette version)
# func _on_player_jumped() -> void:
# 	var pos := _player.global_position + Vector2(0, 8)
# 	_particle_manager.spawn_particle(jump_particles, pos, Vector2.DOWN)


# func _on_player_landed() -> void:
# 	var pos := _player.global_position + Vector2(0, 8)
# 
# 	# Scale based on fall velocity (heavier landing = more particles)
# 	var fall_velocity: float = abs(_player.velocity.y)
# 	var scale_multiplier: float = clamp(fall_velocity / 500.0, 0.5, 2.0)
# 
# 	_particle_manager.spawn_particle(land_particles, pos, Vector2.DOWN, scale_multiplier)


## === WALLS EFFECTS === (DÉSACTIVÉ - fonctionnalités non disponibles dans cette version)
# func _on_player_wall_jumped() -> void:
# 	if wall_jump_particles:
# 		var spawn_pos := _player.global_position
# 		var direction := Vector2(_player.velocity.x, 0).normalized()
# 		_particle_manager.spawn_particle(wall_jump_particles, spawn_pos, direction)


# func _on_wall_slide_started() -> void:
# 	_wall_slide_timer = 0.0


## Update wall slide particles (continuous effect) - DÉSACTIVÉ
# func _update_wall_slide_particles(delta: float) -> void:
# 	if not _player._is_wall_sliding or not wall_slide_particles:
# 		return
# 
# 	_wall_slide_timer -= delta
# 
# 	if _wall_slide_timer <= 0:
# 		_wall_slide_timer = wall_slide_particle_rate
# 
# 		# Spawn particles on the wall side
# 		var wall_direction := Vector2(-sign(_player.velocity.x), 0)
# 		var spawn_pos := _player.global_position + wall_direction * 8
# 		_particle_manager.spawn_particle(wall_slide_particles, spawn_pos, wall_direction)


## === STATUS EFFECTS ===
func _on_player_died() -> void:
	_particle_manager.cleanup_all_particles()


func _on_player_respawned() -> void:
	_particle_manager.cleanup_all_particles()


## === DASH EFFECTS ===
func _on_player_dashed() -> void:
	_is_dashing = true
	_dash_trail_timer = 0.0

	# Spawn burst at dash start
	if dash_burst_particles:
		var direction: Vector2 = _player.get_facing_direction() * -1 # Opposite of dash direction
		_particle_manager.spawn_particle(dash_burst_particles, _player.global_position, direction)


# func _on_dash_recharged() -> void:
# 	# Could spawn subtle sparkle effect - Signal non disponible dans cette version
# 	pass


## Update dash trail (continuous effect during dash)
func _update_dash_trail(delta: float) -> void:
	# Check if player is dashing
	var is_currently_dashing := _player._is_dashing

	if is_currently_dashing and not _is_dashing:
		_is_dashing = true
		_dash_trail_timer = 0.0
	elif not is_currently_dashing:
		_is_dashing = false
		return

	if not dash_trail_enabled or not _is_dashing:
		return

	_dash_trail_timer -= delta

	if _dash_trail_timer <= 0:
		_dash_trail_timer = dash_trail_spacing
		_spawn_dash_trail_sprite()


## Spawns a dash trail sprite (afterimage effect)
func _spawn_dash_trail_sprite() -> void:
	if not _player.sprite:
		return

	# Get parent for trail sprite
	var parent := _get_trail_parent()
	if not parent:
		return

	# Create afterimage sprite
	var trail_sprite := Sprite2D.new()
	trail_sprite.texture = _player.sprite.texture
	trail_sprite.hframes = _player.sprite.hframes
	trail_sprite.vframes = _player.sprite.vframes
	trail_sprite.frame = _player.sprite.frame
	trail_sprite.flip_h = _player.sprite.flip_h
	trail_sprite.scale = _player.sprite.scale
	trail_sprite.modulate = dash_trail_color
	trail_sprite.modulate.a = 0.6

	parent.add_child(trail_sprite)
	trail_sprite.global_position = _player.sprite.global_position

	# Fade out and cleanup
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(trail_sprite, "scale", _player.sprite.scale * 0.8, 0.3)
	tween.finished.connect(trail_sprite.queue_free)


## Gets the best parent node for spawning trail sprites
func _get_trail_parent() -> Node:
	# Try current scene first
	var scene_tree := get_tree()
	if scene_tree and scene_tree.current_scene:
		return scene_tree.current_scene

	# Fallback to scene root
	if scene_tree and scene_tree.root:
		return scene_tree.root

	# Last resort: use this node (trails will move with player)
	return self


## === COMBAT EFFECTS ===

## Called when attack starts
func _on_attack_started() -> void:
	# Could spawn weapon trail particles
	pass

## Called when attack hits enemy (DÉSACTIVÉ - signal non disponible)
# func _on_attack_hit(target: Node2D) -> void:
# 	if hit_impact_particles and is_instance_valid(target):
# 		var hit_pos := target.global_position
# 		var direction := (_player.global_position.direction_to(hit_pos))
# 		_particle_manager.spawn_particle(hit_impact_particles, hit_pos, direction)
