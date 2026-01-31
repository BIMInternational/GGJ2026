extends Node2D

class_name ParticleManager

## Reusable particle effects manager for any entity (Player, Enemy, Items, etc.)
## Handles particle spawning with object pooling for performance

# === PARTICLE SETTINGS ===
@export_group("Settings")
@export var enable_particles: bool = true
@export var particle_scale: float = 1.0
@export_range(0.0, 1.0) var particle_opacity: float = 1.0
@export var debug_mode: bool = false

# Particle pool for performance
var _particle_pool: Dictionary = {}
const POOL_SIZE: int = 20


func _ready() -> void:
	pass # Pool initialized on-demand


## Spawns a particle effect at a position with optional dynamic parameters
## @param scene: The PackedScene containing a GPUParticles2D node
## @param pos: World position to spawn at
## @param direction: Optional direction vector for particle rotation
## @param scale_multiplier: Additional scale multiplier (multiplies with base particle_scale)
## @param custom_modulate: Optional color tint override (use Color.WHITE for no tint)
## @param amount_multiplier: Optional particle count multiplier (1.0 = default amount)
func spawn_particle(
	scene: PackedScene,
	pos: Vector2,
	direction: Vector2 = Vector2.ZERO,
	scale_multiplier: float = 1.0,
	custom_modulate: Color = Color.WHITE,
	amount_multiplier: float = 1.0
) -> void:
	if not enable_particles or not scene:
		return

	_spawn_particles(scene, pos, direction, scale_multiplier, custom_modulate, amount_multiplier)


## Cleanup all active particles (call on scene change/reset, when player dies and respawns)
func cleanup_all_particles() -> void:
	for pool in _particle_pool.values():
		for particle in pool:
			if is_instance_valid(particle):
				particle.queue_free()
		pool.clear()


## Gets the best parent node for spawning particles
func _get_particle_parent() -> Node:
	# Try current scene first (most common)
	var scene_tree := get_tree()
	if scene_tree and scene_tree.current_scene:
		return scene_tree.current_scene

	# Fallback to scene root
	if scene_tree and scene_tree.root:
		return scene_tree.root

	# Last resort: use this node as parent (particles will move with entity)
	return self


## Spawns particles at a position (uses pooling)
func _spawn_particles(
	scene: PackedScene,
	pos: Vector2,
	direction: Vector2 = Vector2.ZERO,
	scale_multiplier: float = 1.0,
	custom_modulate: Color = Color.WHITE,
	amount_multiplier: float = 1.0
) -> void:
	if not enable_particles or not scene:
		return

	var particles: GPUParticles2D = _get_pooled_particle(scene)

	if not particles:
		particles = scene.instantiate() as GPUParticles2D

	if not particles:
		return

	# Add to scene first - IMPORTANT: Must add before setting global_position
	var parent := _get_particle_parent()
	if not parent:
		push_warning("ParticleManager: No valid parent found for particles")
		particles.queue_free()
		return

	parent.add_child(particles)

	# Configure particles AFTER adding to scene tree
	particles.global_position = pos
	particles.scale = Vector2.ONE * particle_scale * scale_multiplier

	# Apply modulate (combine with opacity)
	if custom_modulate != Color.WHITE:
		particles.modulate = custom_modulate
		particles.modulate.a = particle_opacity
	else:
		particles.modulate = Color.WHITE
		particles.modulate.a = particle_opacity

	# Apply amount multiplier if different from 1.0
	if amount_multiplier != 1.0 and particles.process_material is ParticleProcessMaterial:
		var original_amount := particles.amount
		particles.amount = int(original_amount * amount_multiplier)

	# Rotate based on direction if provided
	if direction.length() > 0:
		particles.rotation = direction.angle()

	# CRITICAL: Restart particle system to clear old cached position
	particles.restart()

	# Start emitting (must be last to ensure proper position)
	particles.emitting = true

	# Auto-cleanup when finished (check if not already connected)
	if particles.one_shot:
		if not particles.finished.is_connected(_on_particle_finished):
			particles.finished.connect(_on_particle_finished.bind(particles, scene))


## Get particle from pool or create new
func _get_pooled_particle(scene: PackedScene) -> GPUParticles2D:
	if scene not in _particle_pool:
		_particle_pool[scene] = []

	var pool: Array = _particle_pool[scene]

	# Try to reuse existing particle (particles in pool are already finished and ready)
	if pool.size() > 0:
		var particle: GPUParticles2D = pool.pop_back()
		if is_instance_valid(particle):
			if debug_mode:
				print("♻️ Reusing pooled particle (pool size: ", pool.size(), ")")
			return particle

	if debug_mode:
		print("🆕 Creating new particle (pool size: ", pool.size(), ")")
	return null


## Return particle to pool when finished
func _on_particle_finished(particle: GPUParticles2D, scene: PackedScene) -> void:
	if not is_instance_valid(particle):
		return

	# Remove from parent
	if particle.get_parent():
		particle.get_parent().remove_child(particle)

	# Reset particle state
	particle.emitting = false
	particle.restart()

	# Add to pool if not full
	if scene in _particle_pool and _particle_pool[scene].size() < POOL_SIZE:
		_particle_pool[scene].append(particle)
		if debug_mode:
			print("✅ Particle returned to pool (pool size now: ", _particle_pool[scene].size(), ")")
	else:
		particle.queue_free()
		if debug_mode:
			print("🗑️ Pool full, particle freed")
