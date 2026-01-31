extends Node2D

const RAINBOW_SPEED: float = 1200.0 # Pixels par seconde
const RAINBOW_TRIGGER_Y: float = 1050.0

@onready var rainbow: Sprite2D = $ArcEnCiel
@onready var background_color: Sprite2D = $BackgroundCouleur
@onready var background_bw: Sprite2D = $BackgroundNoirEtBlanc
@onready var intro_sound: AudioStreamPlayer = $SonIntro
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var logo: Sprite2D = $Sprite2D


func _ready() -> void:
	background_bw.visible = true
	background_color.visible = false
	
	# Précharger et jouer la musique via AudioManager
	AudioManager.play_music(preload(GameConstants.MUSIC_LOGO))
	
	# Attendre 3 secondes puis faire apparaître le logo progressivement
	await get_tree().create_timer(2.7).timeout
	
	# Fade in du logo (1 seconde) en utilisant le paramètre alpha du shader
	var tween := create_tween()
	tween.tween_property(logo.material, "shader_parameter/alpha", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	# Puis lancer l'effet shine
	animation_player.play("LogoShine")


func _process(delta: float) -> void:
	rainbow.position.y += RAINBOW_SPEED * delta
	
	if rainbow.position.y > RAINBOW_TRIGGER_Y:
		background_color.visible = true
		background_bw.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("validate"):
		intro_sound.stop()
		_go_to_menu()


func _on_son_intro_finished() -> void:
	_go_to_menu()


func _go_to_menu() -> void:
	SceneManager.change_scene(GameConstants.SCENE_MAIN_MENU)
