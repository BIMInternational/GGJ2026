extends Node
## Gestionnaire de scènes avec transitions
## Facilite le changement de scènes avec effets

signal scene_changing
signal scene_changed

var current_scene: Node = null


func _ready() -> void:
	# Initialiser avec la scène actuelle
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)


func change_scene(scene_path: String, use_transition: bool = true) -> void:
	print("SceneManager: Changement vers ", scene_path)
	scene_changing.emit()
	
	if use_transition:
		await _fade_out()
	
	if current_scene:
		print("SceneManager: Libération de ", current_scene.name)
		current_scene.queue_free()
	
	print("SceneManager: Chargement de la nouvelle scène...")
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	current_scene = new_scene
	print("SceneManager: Nouvelle scène chargée: ", new_scene.name)
	
	if use_transition:
		await _fade_in()
	
	scene_changed.emit()


func reload_scene(use_transition: bool = true) -> void:
	if current_scene:
		change_scene(current_scene.scene_file_path, use_transition)


func _fade_out() -> void:
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.color.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	await tween.finished
	
	await get_tree().create_timer(0.1).timeout
	fade.queue_free()


func _fade_in() -> void:
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.3)
	await tween.finished
	
	fade.queue_free()
