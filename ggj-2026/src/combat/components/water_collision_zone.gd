extends Area2D
## Water splash collision zone with visual puddle effect
## Handles collision detection for ChemistryManager + displays splash

var attack_data: AttackData = null
var has_reacted: bool = false
var lifetime: float = 0.0
var max_lifetime: float = 10.0
var owner_node: Node2D = null
var _damaged_bodies: Array[Node2D] = []
var _splash_sprite: Sprite2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_splash_sprite = $SplashSprite

func initialize(data: AttackData, pos: Vector2, duration: float, attack_owner: Node2D = null) -> void:
	attack_data = data
	global_position = pos
	max_lifetime = duration
	owner_node = attack_owner
	set_meta("attack_data", attack_data)

	# Configure larger collision radius (2x original for sparse zones)
	var shape = $CollisionShape2D.shape as CircleShape2D
	if shape:
		shape.radius = data.collision_radius * 2.0

	# Scale splash visual to match collision size
	if _splash_sprite:
		var splash_scale = data.collision_radius * 0.08
		_splash_sprite.scale = Vector2(splash_scale, splash_scale)

func _process(delta: float) -> void:
	lifetime += delta

	# Animate fade progress in shader
	if _splash_sprite and _splash_sprite.material:
		var fade = lifetime / max_lifetime
		_splash_sprite.material.set_shader_parameter("fade_progress", fade)

	if lifetime >= max_lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if has_reacted:
		return

	if area.has_meta("attack_data"):
		var area_has_reacted = area.has_reacted if "has_reacted" in area else false
		if not area_has_reacted:
			ChemistryManager.resolve(self, area)

func _on_body_entered(body: Node2D) -> void:
	# Avoid hitting the same body multiple times
	if body in _damaged_bodies:
		return

	# Avoid self-damage
	if is_instance_valid(owner_node) and body == owner_node:
		return

	# Damage enemies
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		_damaged_bodies.append(body)
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(int(attack_data.damage), knockback_dir, attack_data.element_type, attack_data.play_sound)
