extends Node
## Gestionnaire audio centralisé
## Facilite la gestion de la musique et des effets sonores

@onready var music_player := AudioStreamPlayer.new()
@onready var sfx_player := AudioStreamPlayer.new()

var _music_volume: float = 0.8
var music_volume: float:
	get: return _music_volume
	set(value): _music_volume = value

var _sfx_volume: float = 1.0
var sfx_volume: float:
	get: return _sfx_volume
	set(value): _sfx_volume = value

var _fade_tween: Tween = null


func _ready() -> void:
	add_child(music_player)
	add_child(sfx_player)
	music_player.bus = GameConstants.AUDIO_BUS_MUSIC
	sfx_player.bus = GameConstants.AUDIO_BUS_SFX
	
	# Charger les volumes sauvegardés
	load_audio_settings()


func load_audio_settings() -> void:
	var master_volume = SaveManager.get_setting("master_volume", 0.8)
	var saved_music_volume = SaveManager.get_setting("music_volume", 0.8)
	var saved_sfx_volume = SaveManager.get_setting("sfx_volume", 1.0)
	
	# Appliquer les volumes aux bus audio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MASTER), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_MUSIC), linear_to_db(saved_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(GameConstants.AUDIO_BUS_SFX), linear_to_db(saved_sfx_volume))
	
	# Sauvegarder dans les variables
	_music_volume = saved_music_volume
	_sfx_volume = saved_sfx_volume


func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	if fade_in:
		music_player.volume_db = -80
		music_player.stream = stream
		music_player.play()
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(music_player, "volume_db", linear_to_db(_music_volume), 1.0)
	else:
		music_player.stream = stream
		music_player.volume_db = linear_to_db(_music_volume)
		music_player.play()


func stop_music(fade_out: bool = true) -> void:
	if fade_out:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(music_player, "volume_db", -80, 1.0)
		_fade_tween.tween_callback(music_player.stop)
	else:
		music_player.stop()


func play_sfx(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(_sfx_volume)
	player.bus = GameConstants.AUDIO_BUS_SFX
	add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())
