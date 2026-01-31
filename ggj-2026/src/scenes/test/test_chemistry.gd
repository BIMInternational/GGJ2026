extends Node2D

@export var fire_attack: AttackData
@export var gas_attack: AttackData
@export var gas_static: AttackData
@export var attack_scene: PackedScene

func _ready() -> void:
	# Charger les ressources si non définies
	if fire_attack == null:
		fire_attack = load("res://src/combat/data/fire_attack.tres")
	if gas_attack == null:
		gas_attack = load("res://src/combat/data/gas_attack.tres")
	if gas_static == null:
		gas_static = load("res://src/combat/data/gas_static.tres")
	if attack_scene == null:
		attack_scene = load("res://src/combat/components/attack_instance.tscn")
	
	# Attendre un peu avant de spawner
	await get_tree().create_timer(0.5).timeout
	
	spawn_static_gas()
	await get_tree().create_timer(0.5).timeout
	spawn_test_attacks()
	
	# Connecter au signal du ChemistryManager
	ChemistryManager.reaction_occurred.connect(_on_reaction_occurred)

func spawn_static_gas() -> void:
	print("=== Création de nuages de gaz immobiles ===")
	
	# Créer plusieurs nuages de gaz statiques entre les deux attaques mobiles
	var gas_positions = [
		Vector2(500, 360),
		Vector2(640, 360),
		Vector2(780, 360),
		Vector2(570, 280),
		Vector2(710, 280),
		Vector2(570, 440),
		Vector2(710, 440),
	]
	
	for pos in gas_positions:
		var gas = attack_scene.instantiate()
		add_child(gas)
		gas.initialize(gas_static, pos, Vector2.ZERO)
	
	print("→ ", gas_positions.size(), " nuages de gaz immobiles placés")

func spawn_test_attacks() -> void:
	print("=== Test de Chimie: FEU + GAZ ===")
	
	# Créer attaque de FEU (gauche, va vers la droite)
	var fire = attack_scene.instantiate()
	add_child(fire)
	fire.initialize(fire_attack, Vector2(300, 360), Vector2.RIGHT)
	print("Attaque FEU spawné à ", fire.global_position)
	
	# Créer attaque de GAZ (droite, va vers la gauche)
	var gas = attack_scene.instantiate()
	add_child(gas)
	gas.initialize(gas_attack, Vector2(980, 360), Vector2.LEFT)
	print("Attaque GAZ spawné à ", gas.global_position)
	
	print("Les attaques vont se rencontrer, créer une explosion qui va toucher les gaz...")

func _on_reaction_occurred(reaction_type: String, reaction_position: Vector2) -> void:
	print("🔥💥 RÉACTION: ", reaction_type, " à la position ", reaction_position)
	
	# Créer un effet visuel simple pour l'explosion
	var explosion_visual = ColorRect.new()
	explosion_visual.color = Color(1.0, 0.5, 0.0, 0.8)
	explosion_visual.size = Vector2(100, 100)
	explosion_visual.position = reaction_position - Vector2(50, 50)
	add_child(explosion_visual)
	
	# Animer et détruire l'explosion
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion_visual, "scale", Vector2(2, 2), 0.5)
	tween.tween_property(explosion_visual, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(explosion_visual.queue_free)

func _input(event: InputEvent) -> void:
	# Appuyer sur ESPACE pour respawn le test
	if event.is_action_pressed("ui_accept"):
		# Nettoyer les anciennes attaques
		for child in get_children():
			if child is Area2D or child is ColorRect:
				child.queue_free()
		
		await get_tree().create_timer(0.1).timeout
		spawn_static_gas()
		await get_tree().create_timer(0.5).timeout
		spawn_test_attacks()
