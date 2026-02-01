extends Area2D
class_name EnemyAttackHitbox

## Hitbox d'attaque pour les ennemis
## Détecte les collisions avec le joueur pendant une attaque

signal hit_landed(body: Node2D)
signal player_in_range(is_in_range: bool)

@export var damage: int = 10
@export var knockback_force: float = 150.0

var _active: bool = false  # True = peut infliger des dégâts
var _player_in_hitbox: bool = false


func _ready() -> void:
	# Toujours détecter, mais ne fait des dégâts que si _active
	monitoring = true
	monitorable = true
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func activate() -> void:
	print("[", get_parent().name, "/", name, "] activate() called, _player_in_hitbox=", _player_in_hitbox)
	_active = true
	# Si le joueur est déjà dans la hitbox, le toucher immédiatement
	if _player_in_hitbox:
		var bodies = get_overlapping_bodies()
		print("[", get_parent().name, "/", name, "] Bodies in hitbox: ", bodies)
		for body in bodies:
			if body.is_in_group("player"):
				_deal_damage(body)


func deactivate() -> void:
	_active = false


func is_player_in_range() -> bool:
	return _player_in_hitbox


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("[AttackHitbox] Joueur détecté")
		_player_in_hitbox = true
		player_in_range.emit(true)
		
		if _active:
			print("[AttackHitbox] Hitbox active, inflige dégâts")
			_deal_damage(body)
		else:
			print("[AttackHitbox] Hitbox inactive")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_hitbox = false
		player_in_range.emit(false)


func _deal_damage(body: Node2D) -> void:
	hit_landed.emit(body)
	
	# Appliquer les dégâts au joueur
	if body.has_method("take_damage"):
		# Utiliser la position du parent (l'ennemi) au lieu de la hitbox
		var enemy_position = get_parent().global_position if get_parent() else global_position
		var knockback_dir = (body.global_position - enemy_position).normalized()
		print("[AttackHitbox] Enemy pos=", enemy_position, " Player pos=", body.global_position, " Direction=", knockback_dir)
		body.take_damage(damage, knockback_dir)
	else:
		print("[AttackHitbox] Joueur touché mais pas de méthode take_damage!")
