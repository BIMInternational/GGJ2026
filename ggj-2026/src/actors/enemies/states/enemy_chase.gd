extends State
class_name EnemyChaseState

var _enemy: EnemyBase

func enter() -> void:
	_enemy = get_parent().get_parent() as EnemyBase
	_enemy.play_animation("Walk")

func physics_update(_delta: float) -> void:
	if not _enemy or not _enemy.target:
		transition_requested.emit(self, "Idle")
		return
	
	var distance = _enemy.global_position.distance_to(_enemy.target.global_position)
	
	# Lost the player - return to Idle
	if distance > _enemy.detection_range:
		transition_requested.emit(self, "Idle")
		return

	if _enemy is Boss:
		var boss := _enemy as Boss
		if boss.can_special_attack():
			boss.perform_special_attack()
			return

	# Check if player is in attack range
	var player_in_range = _enemy.attack_hitbox.is_player_in_range()
	
	if player_in_range:
		# Stop moving when in range
		_enemy.velocity = Vector2.ZERO
		
		# Attack if cooldown is ready
		if _enemy.can_attack():
			transition_requested.emit(self, "Attack")
	else:
		# Chase the player
		var direction = (_enemy.target.global_position - _enemy.global_position).normalized()
		_enemy.velocity = direction * _enemy.speed
