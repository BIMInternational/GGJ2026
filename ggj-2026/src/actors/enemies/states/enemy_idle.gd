extends State
class_name EnemyIdleState

## État d'attente - l'ennemi attend de détecter le joueur

var _enemy: EnemyBase


func enter() -> void:
	_enemy = get_parent().get_parent() as EnemyBase
	_enemy.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if not _enemy or not _enemy.target:
		return

	var distance = _enemy.global_position.distance_to(_enemy.target.global_position)

	# Si le joueur est à portée de détection, passer en Chase
	if distance < _enemy.detection_range:
		transition_requested.emit(self, "Chase")
