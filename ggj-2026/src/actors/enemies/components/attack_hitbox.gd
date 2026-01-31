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
	_active = true
	# Si le joueur est déjà dans la hitbox, le toucher immédiatement
	if _player_in_hitbox:
		var bodies = get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				_deal_damage(body)


func deactivate() -> void:
	_active = false


func is_player_in_range() -> bool:
	return _player_in_hitbox


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_hitbox = true
		player_in_range.emit(true)
		
		if _active:
			_deal_damage(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_hitbox = false
		player_in_range.emit(false)


func _deal_damage(body: Node2D) -> void:
	hit_landed.emit(body)
	
	if body.has_method("apply_knockback"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(knockback_dir, knockback_force)
