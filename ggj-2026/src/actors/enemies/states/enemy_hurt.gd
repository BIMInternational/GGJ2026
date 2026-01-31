extends State
class_name EnemyHurtState

## État de hitstun - l'ennemi est étourdi après avoir reçu un coup

@export var hitstun_duration: float = 0.3

var _enemy: EnemyBase
var _timer: float = 0.0


func enter() -> void:
	_enemy = get_parent().get_parent() as EnemyBase
	_enemy.velocity = Vector2.ZERO
	_timer = hitstun_duration


func physics_update(delta: float) -> void:
	_timer -= delta

	if _timer <= 0:
		# Retourner en Chase si toujours vivant
		if _enemy.health_component.is_alive():
			transition_requested.emit(self, "Chase")
