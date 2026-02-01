extends State
class_name EnemyAttackState

## État d'attaque - l'ennemi attaque le joueur

@export var attack_duration: float = 0.5 # Durée de l'animation d'attaque
@export var attack_frame_duration: float = 0.2 # Durée de la frame d'attaque
@export var attack_damage: int = 10

var _enemy: EnemyBase
var _timer: float = 0.0
var _frame_timer: float = 0.0
var _has_hit: bool = false


func enter() -> void:
	_enemy = get_parent().get_parent() as EnemyBase

	_enemy.velocity = Vector2.ZERO
	_timer = attack_duration
	_frame_timer = attack_frame_duration
	_has_hit = false
	_enemy._is_attacking = true

	# Jouer l'animation d'attaque
	_enemy.play_animation("Attack")
	
	# Changer vers la frame d'attaque (frame 1) pour compatibilité
	if _enemy.sprite:
		_enemy.sprite.frame = 1
	
	# Activer la hitbox d'attaque
	_enemy.enable_attack_hitbox(true)


func exit() -> void:
	_enemy._is_attacking = false

	# Désactiver la hitbox
	_enemy.enable_attack_hitbox(false)
	
	# Remettre la frame par défaut (frame 0)
	if _enemy.sprite:
		_enemy.sprite.frame = 0
	
	# Démarrer le cooldown d'attaque
	_enemy.start_attack_cooldown()


func physics_update(delta: float) -> void:
	_timer -= delta
	_frame_timer -= delta
	
	# Revenir à la frame normale après la durée de la frame d'attaque
	if _frame_timer <= 0 and _enemy.sprite and _enemy.sprite.frame == 1:
		_enemy.sprite.frame = 0
	
	if _timer <= 0:
		# Attaque terminée, retourner en Chase
		transition_requested.emit(self , "Chase")


## Appelé quand la hitbox touche quelque chose
func on_attack_hit(body: Node2D) -> void:
	if _has_hit:
		return
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		_has_hit = true
		# Calculer la direction du knockback depuis l'ennemi vers le joueur
		var knockback_dir = (body.global_position - _enemy.global_position).normalized()
		body.take_damage(attack_damage, knockback_dir, AttackData.ElementType.NONE, true)
		print("Enemy hit player for ", attack_damage, " damage!")
