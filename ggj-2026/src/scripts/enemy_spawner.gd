@tool
extends Node2D
class_name EnemySpawner

## Système de spawn d'ennemis aux bords de l'écran
## Les ennemis apparaissent à gauche ou à droite de l'écran visible

@warning_ignore("unused_signal")
signal wave_completed
@warning_ignore("unused_signal")
signal all_waves_completed

@export var enemy_scene: PackedScene
@export var max_enemies: int = 5
@export var spawn_interval: float = 2.0

## Zone de spawn verticale (la "zone bleue" jouable)
@export_group("Spawn Area")
@export var spawn_y_min: float = -200.0  ## Limite haute de spawn
@export var spawn_y_max: float = 550.0   ## Limite basse de spawn
@export var spawn_offset_x: float = 100.0  ## Distance hors écran pour le spawn

## Référence à la caméra du joueur (auto-détectée si non assignée)
@export var camera: Camera2D

## Debug options
@export_group("Debug")
@export var debug_draw: bool = true
@export var debug_key: Key = KEY_F2  ## Touche pour activer/désactiver le mode debug
@export var debug_zoom_out: float = 0.25  ## Zoom en mode debug (plus petit = plus dézoomé)

var _enemies_alive: Array[EnemyBase] = []
var _spawn_timer: float = 0.0

# Debug state
var _debug_mode_active: bool = false
var _original_zoom: Vector2 = Vector2.ONE
var _original_position_smoothing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_spawn_timer = spawn_interval
	
	# Auto-détecter la caméra si non assignée
	if camera == null:
		await get_tree().process_frame
		var player = get_tree().get_first_node_in_group("player")
		if player:
			camera = player.get_node_or_null("Camera2D")
		
		if camera == null:
			push_warning("EnemySpawner: No camera found! Spawning disabled.")


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	if camera == null:
		return
	
	_spawn_timer -= delta

	if _spawn_timer <= 0 and _can_spawn():
		_spawn_enemy_at_screen_edge()
		_spawn_timer = spawn_interval
	
	# Redraw debug visuals every frame when debug mode is active
	if _debug_mode_active:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	# Toggle debug mode with the configured key
	if event is InputEventKey and event.pressed and event.keycode == debug_key:
		_toggle_debug_mode()


func _toggle_debug_mode() -> void:
	if camera == null:
		return
	
	_debug_mode_active = not _debug_mode_active
	
	if _debug_mode_active:
		# Save original camera settings
		_original_zoom = camera.zoom
		_original_position_smoothing = camera.position_smoothing_enabled
		
		# Zoom out to see spawn areas
		camera.zoom = Vector2(debug_zoom_out, debug_zoom_out)
		camera.position_smoothing_enabled = false
		
		print("🔍 Debug mode ON - Press ", OS.get_keycode_string(debug_key), " to disable")
	else:
		# Restore original camera settings
		camera.zoom = _original_zoom
		camera.position_smoothing_enabled = _original_position_smoothing
		
		print("🔍 Debug mode OFF")
	
	queue_redraw()


func _can_spawn() -> bool:
	return _enemies_alive.size() < max_enemies and enemy_scene != null and camera != null


## Calcule les bords visibles de l'écran en coordonnées monde
func _get_screen_bounds() -> Dictionary:
	if camera == null:
		return {}
	
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = _original_zoom if _debug_mode_active else camera.zoom
	var center = camera.get_screen_center_position()
	
	# Taille visible en coordonnées monde (tenir compte du zoom)
	var half_width = viewport_size.x / (2.0 * zoom.x)
	var half_height = viewport_size.y / (2.0 * zoom.y)
	
	return {
		"left": center.x - half_width,
		"right": center.x + half_width,
		"top": center.y - half_height,
		"bottom": center.y + half_height,
		"center": center
	}


## Spawne un ennemi au bord gauche ou droit de l'écran
func _spawn_enemy_at_screen_edge() -> void:
	var bounds = _get_screen_bounds()
	if bounds.is_empty():
		return
	
	# Choisir aléatoirement gauche ou droite
	var spawn_left = randf() > 0.5
	
	# Position X: juste hors de l'écran
	var spawn_x: float
	if spawn_left:
		spawn_x = bounds["left"] - spawn_offset_x
	else:
		spawn_x = bounds["right"] + spawn_offset_x
	
	# Position Y: aléatoire dans la zone bleue (zone jouable)
	var spawn_y = randf_range(spawn_y_min, spawn_y_max)
	
	var spawn_position = Vector2(spawn_x, spawn_y)
	
	# Créer l'ennemi
	var enemy: EnemyBase = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	enemy.died.connect(_on_enemy_died)

	# Ajouter l'ennemi au parent du spawner (le niveau)
	get_parent().add_child(enemy)
	_enemies_alive.append(enemy)
	
	print("Enemy spawned at screen ", "LEFT" if spawn_left else "RIGHT", ": ", spawn_position)


func _on_enemy_died(enemy: EnemyBase) -> void:
	_enemies_alive.erase(enemy)


## Debug drawing
func _draw() -> void:
	if not debug_draw:
		return
	
	# In editor, just draw the Y bounds
	if Engine.is_editor_hint():
		_draw_editor_bounds()
		return
	
	# In game, only draw when debug mode is active
	if not _debug_mode_active or camera == null:
		return
	
	var bounds = _get_screen_bounds()
	if bounds.is_empty():
		return
	
	# Colors
	var screen_color = Color.GREEN
	var spawn_zone_color = Color(1, 0.5, 0, 0.3)  # Orange transparent
	var spawn_line_color = Color.ORANGE
	var playable_color = Color(0, 0.5, 1, 0.15)  # Blue transparent
	
	# Draw the ACTUAL visible screen area (green rectangle)
	var screen_rect = Rect2(
		bounds["left"], bounds["top"],
		bounds["right"] - bounds["left"],
		bounds["bottom"] - bounds["top"]
	)
	draw_rect(screen_rect, Color(0, 1, 0, 0.1))
	draw_rect(screen_rect, screen_color, false, 3.0)
	
	# Draw "SCREEN" label
	draw_string(ThemeDB.fallback_font, Vector2(bounds["center"].x - 40, bounds["top"] + 30), "SCREEN", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, screen_color)
	
	# Draw the playable Y zone (blue horizontal band)
	var playable_rect = Rect2(
		bounds["left"] - spawn_offset_x - 200,
		spawn_y_min,
		(bounds["right"] - bounds["left"]) + (spawn_offset_x + 200) * 2,
		spawn_y_max - spawn_y_min
	)
	draw_rect(playable_rect, playable_color)
	draw_line(Vector2(playable_rect.position.x, spawn_y_min), Vector2(playable_rect.end.x, spawn_y_min), Color.CYAN, 2.0)
	draw_line(Vector2(playable_rect.position.x, spawn_y_max), Vector2(playable_rect.end.x, spawn_y_max), Color.CYAN, 2.0)
	
	# Draw LEFT spawn zone
	var left_spawn_rect = Rect2(
		bounds["left"] - spawn_offset_x - 50,
		spawn_y_min,
		100,
		spawn_y_max - spawn_y_min
	)
	draw_rect(left_spawn_rect, spawn_zone_color)
	draw_rect(left_spawn_rect, spawn_line_color, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(left_spawn_rect.position.x + 10, spawn_y_min + 30), "SPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, spawn_line_color)
	draw_string(ThemeDB.fallback_font, Vector2(left_spawn_rect.position.x + 10, spawn_y_min + 50), "LEFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, spawn_line_color)
	
	# Draw RIGHT spawn zone
	var right_spawn_rect = Rect2(
		bounds["right"] + spawn_offset_x - 50,
		spawn_y_min,
		100,
		spawn_y_max - spawn_y_min
	)
	draw_rect(right_spawn_rect, spawn_zone_color)
	draw_rect(right_spawn_rect, spawn_line_color, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(right_spawn_rect.position.x + 10, spawn_y_min + 30), "SPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, spawn_line_color)
	draw_string(ThemeDB.fallback_font, Vector2(right_spawn_rect.position.x + 10, spawn_y_min + 50), "RIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, spawn_line_color)
	
	# Draw info text at top
	var info_text = "DEBUG MODE [%s to exit] | Enemies: %d/%d" % [OS.get_keycode_string(debug_key), _enemies_alive.size(), max_enemies]
	draw_string(ThemeDB.fallback_font, Vector2(bounds["center"].x - 200, bounds["top"] - 20), info_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.WHITE)


func _draw_editor_bounds() -> void:
	# Simple Y bounds drawing for editor
	var line_length = 3000.0
	
	# Playable zone (blue)
	var rect = Rect2(-line_length, spawn_y_min, line_length * 2, spawn_y_max - spawn_y_min)
	draw_rect(rect, Color(0, 0.5, 1, 0.1))
	draw_line(Vector2(-line_length, spawn_y_min), Vector2(line_length, spawn_y_min), Color.CYAN, 2.0)
	draw_line(Vector2(-line_length, spawn_y_max), Vector2(line_length, spawn_y_max), Color.CYAN, 2.0)
	
	# Labels
	draw_string(ThemeDB.fallback_font, Vector2(0, spawn_y_min - 10), "spawn_y_min: %.0f" % spawn_y_min, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(0, spawn_y_max + 20), "spawn_y_max: %.0f" % spawn_y_max, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.CYAN)
