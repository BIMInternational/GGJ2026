extends Node
## Gestionnaire de sauvegarde simple pour les scores

const SAVE_FILE = "user://save_data.json"

var save_data: Dictionary = {
	"best_score": 0,
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"fullscreen": false
	}
}


func _ready() -> void:
	load_game()


func save_game() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			save_data = json.data


func get_best_score() -> int:
	return save_data.get("best_score", 0)


func save_best_score(score: int) -> void:
	save_data["best_score"] = score
	save_game()


func get_setting(key: String, default = null):
	return save_data.get("settings", {}).get(key, default)


func save_setting(key: String, value) -> void:
	if not save_data.has("settings"):
		save_data["settings"] = {}
	save_data["settings"][key] = value
	save_game()


func reset_all_data() -> void:
	save_data = {
		"best_score": 0,
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"fullscreen": false
		}
	}
	save_game()


func delete_save_file() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
	reset_all_data()
