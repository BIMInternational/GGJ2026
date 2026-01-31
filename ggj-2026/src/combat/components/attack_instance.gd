extends Area2D

## Données de l'attaque
var attack_data: AttackData = null

## Direction de déplacement
var direction: Vector2 = Vector2.RIGHT

## Timer interne pour l'auto-destruction
var lifetime: float = 0.0

## Flag pour éviter les réactions multiples
var has_reacted: bool = false

## Rayon initial et final pour l'expansion
var initial_radius: float = 0.0
var target_radius: float = 0.0

## Owner de l'attaque (pour éviter l'auto-damage)
var owner_node: Node2D = null

## Bodies déjà touchés (pour éviter les multi-hits)
var _damaged_bodies: Array[Node2D] = []

## Trail system
var _last_trail_position: Vector2 = Vector2.ZERO
var _trail_distance_traveled: float = 0.0
var _trail_emitter: Node2D = null

func _ready() -> void:
	# Connecter le signal de détection d'aire
	area_entered.connect(_on_area_entered)
	# Connecter le signal de détection de body (pour toucher les ennemis)
	body_entered.connect(_on_body_entered)

func initialize(data: AttackData, spawn_position: Vector2, move_direction: Vector2, attack_owner: Node2D = null) -> void:
	attack_data = data
	global_position = spawn_position
	direction = move_direction.normalized()
	owner_node = attack_owner
	
	# Initialiser la position de départ de la trainée
	_last_trail_position = spawn_position
	
	# Stocker l'attack_data en metadata pour le ChemistryManager
	set_meta("attack_data", attack_data)
	
	# Configurer l'expansion si nécessaire
	if attack_data.expand_over_time:
		initial_radius = attack_data.collision_radius * 0.1  # Commence à 10% de la taille
		target_radius = attack_data.collision_radius
		scale = Vector2(0.1, 0.1)  # Commence petit
	else:
		initial_radius = attack_data.collision_radius
		target_radius = attack_data.collision_radius
	
	# Ajuster la taille de la collision si définie
	if attack_data.collision_radius > 0:
		var collision_shape = $CollisionShape2D
		if collision_shape:
			if attack_data.ignore_y_axis:
				# Créer une forme rectangulaire très haute pour toucher sur tout l'axe Y
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(attack_data.collision_radius * 2, 2000.0)  # Très haut
				collision_shape.shape = rect_shape
			elif collision_shape.shape is CircleShape2D:
				collision_shape.shape.radius = attack_data.collision_radius
	
	# Configurer l'apparence visuelle si définie
	if attack_data.visual_effect != null:
		var effect = attack_data.visual_effect.instantiate()
		add_child(effect)
	else:
		# Sprite par défaut pour visualiser l'attaque
		_create_default_visual()

	# Setup particle trail emitter if enabled
	if attack_data.use_particle_trail and attack_data.trail_particle_effect != null:
		_trail_emitter = attack_data.trail_particle_effect.instantiate()
		add_child(_trail_emitter)
		if _trail_emitter.has_method("initialize"):
			_trail_emitter.initialize(attack_data, owner_node)

func _create_default_visual() -> void:
	var sprite = Sprite2D.new()
	var size = int(attack_data.collision_radius * 2)
	
	# Créer une texture de couleur selon l'élément
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = _get_element_color()
	image.fill(color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	add_child(sprite)

func _get_element_color() -> Color:
	if attack_data == null:
		return Color.WHITE
	
	match attack_data.element_type:
		AttackData.ElementType.FIRE:
			# Si dissipation_time est courte, c'est une explosion (plus lumineuse)
			if attack_data.dissipation_time <= 2.5:
				return Color(1.0, 0.6, 0.0, 0.9)  # Orange vif (explosion)
			else:
				return Color(1.0, 0.3, 0.0, 0.7)  # Orange/Rouge (feu normal)
		AttackData.ElementType.GAS:
			return Color(0.5, 1.0, 0.5, 0.5)  # Vert semi-transparent
		AttackData.ElementType.WATER:
			return Color(0.2, 0.5, 1.0, 0.6)  # Bleu
		AttackData.ElementType.ICE:
			return Color(0.6, 0.9, 1.0, 0.8)  # Bleu clair glacé
		AttackData.ElementType.ELECTRIC:
			return Color(1.0, 1.0, 0.0, 0.8)  # Jaune
		AttackData.ElementType.WIND:
			return Color(0.8, 0.8, 0.8, 0.4)  # Gris clair
		_:
			return Color.WHITE

func _process(delta: float) -> void:
	if attack_data == null:
		return
	
	# Déplacement si speed > 0
	if attack_data.speed > 0:
		var old_position = global_position
		global_position += direction * attack_data.speed * delta
		
		# Spawn trail si configuré (legacy mode - skip if using particle trail)
		if attack_data.trail_attack_data != null and not attack_data.use_particle_trail:
			var distance_moved = old_position.distance_to(global_position)
			_trail_distance_traveled += distance_moved

			if _trail_distance_traveled >= attack_data.trail_spawn_distance:
				_spawn_trail_attack()
				_trail_distance_traveled = 0.0
	
	# Expansion progressive
	if attack_data.expand_over_time:
		var expansion_progress = min(lifetime / attack_data.dissipation_time, 1.0)
		var current_scale = lerp(0.1, 1.0, expansion_progress)
		scale = Vector2(current_scale, current_scale)
	
	# Gestion de la durée de vie
	lifetime += delta
	if lifetime >= attack_data.dissipation_time:
		queue_free()


func _spawn_trail_attack() -> void:
	if attack_data.trail_attack_data == null:
		return
	
	# Utiliser le ChemistryManager pour spawn la trainée
	ChemistryManager.spawn_attack(attack_data.trail_attack_data, global_position, Vector2.ZERO, owner_node)


func _on_area_entered(area: Area2D) -> void:
	# Ne pas réagir si cette attaque a déjà réagi
	if has_reacted:
		return

	# Vérifier si c'est une autre AttackInstance
	if area.has_meta("attack_data"):
		# Vérifier si c'est bien un attack_instance avec le flag has_reacted
		var area_has_reacted = area.has_reacted if "has_reacted" in area else false
		if area_has_reacted:
			return

		# Appeler le ChemistryManager pour résoudre l'interaction
		# Le ChemistryManager se chargera de marquer has_reacted selon les règles
		ChemistryManager.resolve(self, area)


func _on_body_entered(body: Node2D) -> void:
	# Détruire l'attaque si elle touche un mur (TileMap ou StaticBody2D)
	if body is TileMap or body is StaticBody2D:
		queue_free()
		return
	
	# Éviter de toucher le même body plusieurs fois
	if body in _damaged_bodies:
		return

	# Éviter l'auto-damage
	if body == owner_node:
		return

	# Toucher les ennemis
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		_damaged_bodies.append(body)
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(int(attack_data.damage), knockback_dir)
