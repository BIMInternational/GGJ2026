extends Node

## Signal émis lors d'une réaction chimique
signal reaction_occurred(reaction_type: String, position: Vector2)

## Structure d'une règle de réaction
class ReactionRule:
	var element_a: AttackData.ElementType
	var element_b: AttackData.ElementType
	var result_attack_data: Array[String] = []  # Chemins vers les .tres (peut être vide ou multiple)
	var reaction_name: String
	var destroy_a: bool = true  # Détruire element_a
	var destroy_b: bool = true  # Détruire element_b
	var mark_a_reacted: bool = true  # Marquer element_a comme ayant réagi
	var mark_b_reacted: bool = true  # Marquer element_b comme ayant réagi
	
	func _init(elem_a: AttackData.ElementType, elem_b: AttackData.ElementType, result: Variant, name: String, destroy_elem_a: bool = true, destroy_elem_b: bool = true, mark_elem_a_reacted: bool = true, mark_elem_b_reacted: bool = true):
		element_a = elem_a
		element_b = elem_b
		# Accepter soit une String, soit un Array
		if result is String:
			if result != "":
				result_attack_data.append(result)
		elif result is Array:
			for item in result:
				if item is String:
					result_attack_data.append(item)
		reaction_name = name
		destroy_a = destroy_elem_a
		destroy_b = destroy_elem_b
		mark_a_reacted = mark_elem_a_reacted
		mark_b_reacted = mark_elem_b_reacted
	
	func matches(type_a: AttackData.ElementType, type_b: AttackData.ElementType) -> bool:
		return (type_a == element_a and type_b == element_b) or \
			   (type_a == element_b and type_b == element_a)
	
	func should_destroy(attack_type: AttackData.ElementType) -> bool:
		if attack_type == element_a:
			return destroy_a
		elif attack_type == element_b:
			return destroy_b
		return false
	
	func should_mark_reacted(attack_type: AttackData.ElementType) -> bool:
		if attack_type == element_a:
			return mark_a_reacted
		elif attack_type == element_b:
			return mark_b_reacted
		return true

## Table des réactions (facile à étendre)
var reaction_rules: Array[ReactionRule] = []

## Cache des ressources
var attack_instance_scene: PackedScene = null
var cached_attack_data: Dictionary = {}

func _ready() -> void:
	# Initialiser les règles de réactions
	_setup_reaction_rules()
	
	# Précharger la scène d'attaque
	attack_instance_scene = load("res://src/combat/components/attack_instance.tscn")

## Configure toutes les règles de réactions
func _setup_reaction_rules() -> void:
	# FIRE + WATER = S'annulent (pas de résultat)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FIRE,
		AttackData.ElementType.WATER,
		"",  # Pas de résultat
		"FIRE_WATER_CANCEL",
		true,  # Détruire le feu
		true,  # Détruire l'eau
		true,  # Le feu ne réagit qu'une fois
		true   # L'eau ne réagit qu'une fois
	))
	
	# GAS + WATER = l'eau se separe en 2
	# reaction_rules.append(ReactionRule.new(
	#  	AttackData.ElementType.GAS,
	#  	AttackData.ElementType.WATER,
	#  	["res://src/combat/data/water_attack.tres", "res://src/combat/data/water_attack.tres"],  # 2 projectiles d'eau
	#  	"GAS_WATER_SPLIT",
	# 	false,  # Détruire le gaz
	#  	true,  # Détruire l'eau
	#  	true,  # Le gaz ne réagit qu'une fois
	#  	true   # L'eau ne réagit qu'une fois
	# ))
	
	# GAS + ICE = Bloc de gaz gelé (durée indéfinie)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.GAS,
		AttackData.ElementType.ICE,
		"res://src/combat/data/gas_block.tres",
		"GAS_ICE_BLOCK",
		false,  # Détruire le gaz
		false,  # Détruire la glace
		false,  # Le gaz ne réagit qu'une fois
		false   # La glace ne réagit qu'une fois
	))
	
	# WATER + ICE = Glace (l'eau gèle)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.WATER,
		AttackData.ElementType.ICE,
		"res://src/combat/data/ice_static.tres",
		"WATER_ICE_FREEZE",
		true,  # Détruire l'eau
		false,  # Détruire la glace
		true,  # L'eau ne réagit qu'une fois
		false   # La glace ne réagit qu'une fois
	))
	
	# GAS + ELECTRIC = Explosion de feu
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.GAS,
		AttackData.ElementType.ELECTRIC,
		"res://src/combat/data/fire_explosion.tres",
		"GAS_ELECTRIC_FIRE_EXPLOSION",
		true,  # Détruire le gaz
		true,  # Détruire l'électricité
		true,  # Le gaz ne réagit qu'une fois
		true   # L'électricité ne réagit qu'une fois
	))
	
	# FIRE + ELECTRIC = PLASMA (état le plus chaud de la matière)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FIRE,
		AttackData.ElementType.ELECTRIC,
		"res://src/combat/data/plasma_attack.tres",
		"FIRE_ELECTRIC_PLASMA",
		true,  # Détruire le feu
		true,  # Détruire l'électricité
		true,  # Le feu ne réagit qu'une fois
		true   # L'électricité ne réagit qu'une fois
	))
	
	# WATER + ELECTRIC = Electric static (eau électrifiée)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.WATER,
		AttackData.ElementType.ELECTRIC,
		"res://src/combat/data/lightning_static.tres",
		"WATER_ELECTRIC_STATIC",
		true,  # Détruire l'eau
		true,  # Détruire l'électricité
		true,  # L'eau ne réagit qu'une fois
		true   # L'électricité ne réagit qu'une fois
	))
	
	# ICE + ELECTRIC = Explosion de glace
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.ICE,
		AttackData.ElementType.ELECTRIC,
		"res://src/combat/data/ice_explosion.tres",
		"ICE_ELECTRIC_ICE_EXPLOSION",
		true,  # Détruire la glace
		true,  # Détruire l'électricité
		true,  # La glace ne réagit qu'une fois
		true   # L'électricité ne réagit qu'une fois
	))
	
	# FIRE + GAS = EXPLOSION (détruit seulement le gaz, pas le feu)
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FIRE,
		AttackData.ElementType.GAS,
		"res://src/combat/data/explosion_attack.tres",
		"FIRE_GAS_EXPLOSION",
		false,  # Ne pas détruire le feu
		true,   # Détruire le gaz
		false,  # Le feu peut réagir plusieurs fois
		true    # Le gaz ne réagit qu'une fois
	))
	
	# FROZEN_GAS + WATER = Glace
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FROZEN_GAS,
		AttackData.ElementType.WATER,
		"res://src/combat/data/ice_static.tres",
		"FROZEN_GAS_WATER_FREEZE",
		true,  # Détruire le gaz gelé
		true,  # Détruire l'eau
		true,  # Le gaz gelé ne réagit qu'une fois
		true   # L'eau ne réagit qu'une fois
	))
	
	# FROZEN_GAS + FIRE = Méga explosion ultra violente
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FROZEN_GAS,
		AttackData.ElementType.FIRE,
		"res://src/combat/data/mega_explosion.tres",
		"FROZEN_GAS_FIRE_EXPLOSION",
		true,  # Détruire le gaz gelé
		true,  # Détruire le feu
		true,  # Le gaz gelé ne réagit qu'une fois
		true   # Le feu ne réagit qu'une fois
	))
	
	# FROZEN_GAS + ELECTRIC = Méga explosion ultra violente
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FROZEN_GAS,
		AttackData.ElementType.ELECTRIC,
		"res://src/combat/data/mega_explosion.tres",
		"FROZEN_GAS_ELECTRIC_EXPLOSION",
		true,  # Détruire le gaz gelé
		true,  # Détruire l'électricité
		true,  # Le gaz gelé ne réagit qu'une fois
		true   # L'électricité ne réagit qu'une fois
	))
	
	# FROZEN_GAS + GAS = Gas block
	reaction_rules.append(ReactionRule.new(
		AttackData.ElementType.FROZEN_GAS,
		AttackData.ElementType.GAS,
		"res://src/combat/data/gas_block.tres",
		"FROZEN_GAS_GAS_BLOCK",
		true,  # Détruire le gaz gelé
		true,  # Détruire le gaz
		true,  # Le gaz gelé ne réagit qu'une fois
		true   # Le gaz ne réagit qu'une fois
	))
	
	# Ajouter d'autres réactions ici facilement:
	# WATER + ELECTRIC = ELECTRIFIED_WATER
	reaction_rules.append(ReactionRule.new(
		 AttackData.ElementType.WATER,
		 AttackData.ElementType.ELECTRIC,
		 "res://src/scripts/electrified_water.tres",
		 "WATER_ELECTRIC_SHOCK",
		 true,  # l'eau est detruite
		 true,   # l'etricticité est detruite
		 true,  # l'eau ne réagit qu'une fois
		 false    # L'électricité peut réagir plusieurs fois
	 ))
	
	# WIND + FIRE = FIRESTORM
	# reaction_rules.append(ReactionRule.new(
	#     AttackData.ElementType.WIND,
	#     AttackData.ElementType.FIRE,
	#     "res://src/scripts/firestorm.tres",
	#     "WIND_FIRE_STORM"
	# ))

## Résout l'interaction entre deux attaques
## Retourne true si une réaction s'est produite
func resolve(attack_a: Node2D, attack_b: Node2D) -> bool:
	# Vérifier que les deux nœuds ont une AttackData
	if not attack_a.has_meta("attack_data") or not attack_b.has_meta("attack_data"):
		return false
	
	var data_a: AttackData = attack_a.get_meta("attack_data")
	var data_b: AttackData = attack_b.get_meta("attack_data")
	
	# Chercher une règle correspondante
	for rule in reaction_rules:
		if rule.matches(data_a.element_type, data_b.element_type):
			_apply_reaction(attack_a, attack_b, rule)
			return true
	
	return false

## Applique une réaction selon la règle
func _apply_reaction(attack_a: Node2D, attack_b: Node2D, rule: ReactionRule) -> void:
	# Calculer la position de la réaction
	var reaction_position = (attack_a.global_position + attack_b.global_position) / 2.0
	
	# Obtenir les types d'éléments
	var data_a: AttackData = attack_a.get_meta("attack_data")
	var data_b: AttackData = attack_b.get_meta("attack_data")
	
	# Récupérer la direction de l'eau (l'attaque qui bouge)
	var water_direction = Vector2.ZERO
	if data_a.element_type == AttackData.ElementType.WATER and "direction" in attack_a:
		water_direction = attack_a.direction
	elif data_b.element_type == AttackData.ElementType.WATER and "direction" in attack_b:
		water_direction = attack_b.direction
	
	# Marquer comme ayant réagi si nécessaire (AVANT de détruire)
	if rule.should_mark_reacted(data_a.element_type) and "has_reacted" in attack_a:
		attack_a.has_reacted = true
	if rule.should_mark_reacted(data_b.element_type) and "has_reacted" in attack_b:
		attack_b.has_reacted = true
	
	# Détruire les attaques si nécessaire selon leur type
	if rule.should_destroy(data_a.element_type):
		attack_a.call_deferred("queue_free")
	if rule.should_destroy(data_b.element_type):
		attack_b.call_deferred("queue_free")
	
	# Créer l'attaque résultante (différé aussi)
	call_deferred("_spawn_result_attack", reaction_position, rule, water_direction)
	
	# Émettre le signal
	reaction_occurred.emit(rule.reaction_name, reaction_position)
	print("💥 Réaction: ", rule.reaction_name, " à ", reaction_position)

## Spawn l'attaque résultante d'une réaction
func _spawn_result_attack(position: Vector2, rule: ReactionRule, incoming_direction: Vector2 = Vector2.ZERO) -> void:
	# Si pas de résultat (annulation), ne rien spawner
	if rule.result_attack_data.is_empty():
		return
	
	# Spawner chaque attaque résultante
	for i in range(rule.result_attack_data.size()):
		var attack_path = rule.result_attack_data[i]
		
		# Charger l'AttackData (avec cache)
		var result_data = _load_attack_data(attack_path)
		
		if result_data == null or attack_instance_scene == null:
			continue
		
		# Calculer un offset et direction pour séparer les résultats multiples
		var offset = Vector2.ZERO
		var spawn_direction = Vector2.ZERO
		
		if rule.result_attack_data.size() > 1:
			# Si c'est la réaction GAS_WATER_SPLIT, créer 2 projectiles à 45° de la direction d'arrivée
			if rule.reaction_name == "GAS_WATER_SPLIT" and incoming_direction.length() > 0:
				var base_angle = incoming_direction.angle()
				var angle_offset = deg_to_rad(45.0) if i == 0 else deg_to_rad(-45.0)
				var final_angle = base_angle + angle_offset
				spawn_direction = Vector2(cos(final_angle), sin(final_angle))
				# Décaler perpendiculairement à la direction d'arrivée (+50 / -50 pixels)
				var perpendicular = Vector2(-incoming_direction.normalized().y, incoming_direction.normalized().x)
				offset = perpendicular * (50.0 if i == 0 else -50.0)
			else:
				# Séparer horizontalement pour les autres réactions
				var spacing = 40.0
				var total_width = (rule.result_attack_data.size() - 1) * spacing
				offset = Vector2((i * spacing) - (total_width / 2.0), 0)
		
		# Créer l'instance
		var result_attack = attack_instance_scene.instantiate()
		get_tree().root.add_child(result_attack)
		result_attack.initialize(result_data, position + offset, spawn_direction)

## Charge une AttackData avec cache
func _load_attack_data(path: String) -> AttackData:
	if not cached_attack_data.has(path):
		cached_attack_data[path] = load(path)
	return cached_attack_data[path]

## Fonction utilitaire pour obtenir le nom d'un type d'élément
func get_element_name(element_type: AttackData.ElementType) -> String:
	match element_type:
		AttackData.ElementType.NONE: return "NONE"
		AttackData.ElementType.FIRE: return "FIRE"
		AttackData.ElementType.GAS: return "GAS"
		AttackData.ElementType.WATER: return "WATER"
		AttackData.ElementType.ELECTRIC: return "ELECTRIC"
		AttackData.ElementType.WIND: return "WIND"
		AttackData.ElementType.FROZEN_GAS: return "FROZEN_GAS"
		_: return "UNKNOWN"


## Fonction publique pour spawn une attaque (utilisable par player, ennemis, etc.)
func spawn_attack(attack_data: AttackData, position: Vector2, direction: Vector2, attack_owner: Node2D = null) -> void:
	if attack_data == null or attack_instance_scene == null:
		push_warning("ChemistryManager: Cannot spawn attack - missing data or scene")
		return

	var attack = attack_instance_scene.instantiate()
	get_tree().root.call_deferred("add_child", attack)
	attack.call_deferred("initialize", attack_data, position, direction, attack_owner)
