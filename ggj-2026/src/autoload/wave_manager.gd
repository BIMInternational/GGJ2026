extends Node

## Orchestrates the wave system: spawns enemies, manages gates, handles progression

# === SIGNALS ===
signal phase_started(phase_index: int)
signal subwave_started(phase_index: int, subwave_index: int)
signal all_enemies_defeated
signal boss_spawned(boss: Node2D)
signal boss_defeated
signal phase_completed(phase_index: int)
signal all_phases_completed
signal waiting_for_player_advance

# === CONFIGURATION ===
var phases: Array[WaveData] = []

## Spawn offset from right edge of screen
var spawn_offset_x: float = 100.0

## Y range for enemy spawns
var spawn_y_min: float = -200.0
var spawn_y_max: float = 550.0

## Margin inside screen edge for boss spawn visibility check
var boss_visibility_margin: float = 100.0

# === STATE ===
var current_phase_index: int = -1
var current_subwave_index: int = -1
var enemies_alive: Array[Node2D] = []
var current_boss: Node2D = null
var is_running: bool = false
var _waiting_for_boss_area_visible: bool = false

# === REFERENCES ===
var _camera: Camera2D = null
var _gates: Array[Node2D] = []
var _arrow_indicator: Node = null
var _reward_screen: CanvasLayer = null
var _player: Node2D = null
var _level_node: Node2D = null


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	# Check if boss spawn area has become visible
	if _waiting_for_boss_area_visible:
		var phase = phases[current_phase_index]
		if _is_position_visible_on_screen(phase.boss_spawn_position):
			_on_boss_area_visible()


## Call this from level script to start the wave system
func start_waves(camera: Camera2D, gates: Array, arrow: Node, reward: CanvasLayer, level: Node2D = null) -> void:
	_camera = camera
	_gates = gates
	_arrow_indicator = arrow
	_reward_screen = reward
	_level_node = level if level != null else get_tree().current_scene
	
	# Find player reference
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	
	if _arrow_indicator:
		_arrow_indicator.hide()
	if _reward_screen:
		_reward_screen.hide()
	
	_setup_initial_gates()
	
	is_running = true
	current_phase_index = -1
	_waiting_for_boss_area_visible = false
	_start_next_phase()


## Stop all wave processes and clean up
func stop_waves() -> void:
	is_running = false
	_waiting_for_boss_area_visible = false
	
	# Clean up enemies
	for enemy in enemies_alive:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_alive.clear()
	
	# Clean up boss
	if current_boss and is_instance_valid(current_boss):
		current_boss.queue_free()
	current_boss = null
	
	print("[WaveManager] Stopped all waves")


func _setup_initial_gates() -> void:
	for i in range(_gates.size()):
		var gate = _gates[i]
		if gate.has_method("close"):
			gate.close()


## Check if a world position is currently visible on screen
func _is_position_visible_on_screen(world_pos: Vector2) -> bool:
	if _camera == null:
		return false
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_center = _camera.get_screen_center_position()
	var half_width = viewport_size.x / (2.0 * _camera.zoom.x)
	var half_height = viewport_size.y / (2.0 * _camera.zoom.y)
	
	# Screen bounds with margin
	var left = camera_center.x - half_width + boss_visibility_margin
	var right = camera_center.x + half_width - boss_visibility_margin
	var top = camera_center.y - half_height + boss_visibility_margin
	var bottom = camera_center.y + half_height - boss_visibility_margin
	
	return world_pos.x >= left and world_pos.x <= right and world_pos.y >= top and world_pos.y <= bottom


func _get_current_gate() -> Node2D:
	if current_phase_index >= 0 and current_phase_index < _gates.size():
		return _gates[current_phase_index]
	return null


func _start_next_phase() -> void:
	current_phase_index += 1
	current_subwave_index = -1
	_waiting_for_boss_area_visible = false
	
	if current_phase_index >= phases.size():
		_on_all_phases_completed()
		return
	
	print("[WaveManager] Starting Phase ", current_phase_index + 1)
	phase_started.emit(current_phase_index)
	
	_start_next_subwave()


func _start_next_subwave() -> void:
	var phase = phases[current_phase_index]
	current_subwave_index += 1
	
	if current_subwave_index >= phase.subwaves.size():
		_on_all_subwaves_cleared()
		return
	
	var subwave = phase.subwaves[current_subwave_index]
	print("[WaveManager] Starting Subwave ", current_subwave_index + 1)
	subwave_started.emit(current_phase_index, current_subwave_index)
	
	_spawn_subwave_enemies(subwave)


func _spawn_subwave_enemies(subwave: SubwaveData) -> void:
	if subwave.enemy_scene == null:
		push_warning("[WaveManager] Subwave has no enemy_scene!")
		_check_subwave_complete()
		return
	
	for i in range(subwave.enemy_count):
		if i > 0:
			await get_tree().create_timer(subwave.spawn_delay).timeout
		
		_spawn_enemy(subwave.enemy_scene)


func _spawn_enemy(enemy_scene: PackedScene) -> void:
	if _camera == null:
		push_warning("[WaveManager] No camera reference!")
		return
	
	var enemy = enemy_scene.instantiate()
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_center = _camera.get_screen_center_position()
	var half_width = viewport_size.x / (2.0 * _camera.zoom.x)
	
	var spawn_x = camera_center.x + half_width + spawn_offset_x
	var spawn_y = randf_range(spawn_y_min, spawn_y_max)
	
	enemy.global_position = Vector2(spawn_x, spawn_y)
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	
	if _level_node:
		_level_node.add_child(enemy)
	else:
		print("[WaveManager] Error: No level node to spawn enemy!")
		return
	
	enemies_alive.append(enemy)
	
	print("[WaveManager] Spawned enemy at ", enemy.global_position)


func _on_enemy_died(enemy: Node2D) -> void:
	enemies_alive.erase(enemy)
	print("[WaveManager] Enemy died. Remaining: ", enemies_alive.size())
	
	_check_subwave_complete()


func _check_subwave_complete() -> void:
	if enemies_alive.size() > 0:
		return
	
	if current_boss != null:
		return
	
	# Don't check if we're waiting for boss area to be visible
	if _waiting_for_boss_area_visible:
		return
	
	print("[WaveManager] Subwave cleared!")
	all_enemies_defeated.emit()
	
	var phase = phases[current_phase_index]
	var subwave = phase.subwaves[current_subwave_index]
	
	if subwave.delay_after_cleared > 0:
		await get_tree().create_timer(subwave.delay_after_cleared).timeout
	
	_start_next_subwave()


func _on_all_subwaves_cleared() -> void:
	var phase = phases[current_phase_index]
	
	if phase.boss_scene != null:
		# Check if boss spawn position is already visible
		if _is_position_visible_on_screen(phase.boss_spawn_position):
			# Spawn boss immediately
			_spawn_boss(phase)
		else:
			# Wait for player to advance until boss area is visible
			_start_waiting_for_boss_area()
	else:
		# No boss, just complete the phase
		_on_phase_completed()


## Start waiting for player to move until boss spawn area is visible
func _start_waiting_for_boss_area() -> void:
	print("[WaveManager] Waiting for boss spawn area to be visible...")
	_waiting_for_boss_area_visible = true
	waiting_for_player_advance.emit()
	
	# Show arrow to indicate player should move forward
	_show_arrow_indefinitely()


## Called when boss spawn area becomes visible on screen
func _on_boss_area_visible() -> void:
	print("[WaveManager] Boss spawn area is now visible!")
	_waiting_for_boss_area_visible = false
	
	# Hide arrow
	_hide_arrow()
	
	# Small delay before boss spawns (dramatic effect)
	await get_tree().create_timer(0.5).timeout
	
	# Spawn the boss
	var phase = phases[current_phase_index]
	_spawn_boss(phase)


func _show_arrow(duration: float = 3.0) -> void:
	var hud = _level_node.get_node_or_null("HUD") if _level_node else null
	
	if hud and hud.has_method("show_go_indicator"):
		hud.show_go_indicator()
	elif _arrow_indicator:
		if _arrow_indicator.has_method("display"):
			_arrow_indicator.display(duration)
		else:
			_arrow_indicator.show()
	print("[WaveManager] Arrow shown for ", duration, " seconds")


func _hide_arrow() -> void:
	var hud = _level_node.get_node_or_null("HUD") if _level_node else null
	
	if hud and hud.has_method("hide_go_indicator"):
		hud.hide_go_indicator()
	elif _arrow_indicator:
		if _arrow_indicator.has_method("hide_arrow"):
			_arrow_indicator.hide_arrow()
		else:
			_arrow_indicator.hide()

func _show_arrow_indefinitely() -> void:
	# Get HUD directly from level_node to ensure we use the correct one
	var hud = _level_node.get_node_or_null("HUD") if _level_node else null
	
	if hud and hud.has_method("show_go_indicator"):
		hud.show_go_indicator()
	elif _arrow_indicator:
		if _arrow_indicator.has_method("show_indefinitely"):
			_arrow_indicator.show_indefinitely()
		else:
			_arrow_indicator.visible = true
	print("[WaveManager] GO! shown - advance to boss area!")


func _spawn_boss(phase: WaveData) -> void:
	print("[WaveManager] Spawning boss at ", phase.boss_spawn_position)
	
	var boss = phase.boss_scene.instantiate()
	
	# Use the specific spawn position from WaveData
	boss.global_position = phase.boss_spawn_position
	
	# Scale-in animation
	var target_scale = boss.scale
	boss.scale = Vector2.ZERO
	
	if _level_node:
		_level_node.add_child(boss)
	else:
		print("[WaveManager] Error: No level node to spawn boss!")
		return
	
	# Scale-in tween
	var tween = create_tween()
	tween.tween_property(boss, "scale", target_scale, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Start entrance animation after scale-in completes
	tween.tween_callback(func():
		if boss.has_method("start_entrance"):
			boss.start_entrance(3.0)  # 3 second entrance animation
	)
	
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)
	
	current_boss = boss
	boss_spawned.emit(boss)
	get_node('/root').find_child("InGameMusic", true, false).stop()
	get_node('/root').find_child("BossMusic", true, false).play()

func _on_boss_died(_boss: Node2D) -> void:
	print("[WaveManager] Boss defeated!")
	current_boss = null
	boss_defeated.emit()
	get_node('/root').find_child("BossMusic", true, false).stop()
	get_node('/root').find_child("InGameMusic", true, false).play()
	
	# Open the gate
	if current_phase_index < _gates.size():
		var gate = _gates[current_phase_index]
		if gate.has_method("open"):
			gate.open()
	
	# Show arrow to indicate player can move to next area
	_show_arrow(3.0)
	
	var phase = phases[current_phase_index]
	
	if phase.show_reward_after_boss:
		# Small delay before showing reward
		await get_tree().create_timer(1.0).timeout
		_show_reward_screen()
	else:
		_on_phase_completed()


func _show_reward_screen() -> void:
	if _reward_screen:
		get_tree().paused = true
		_reward_screen.show()


func on_reward_continue() -> void:
	get_tree().paused = false
	if _reward_screen:
		_reward_screen.hide()
	_on_phase_completed()


func _on_phase_completed() -> void:
	print("[WaveManager] Phase ", current_phase_index + 1, " completed!")
	
	# Ensure gate is open
	if current_phase_index < _gates.size():
		var gate = _gates[current_phase_index]
		if gate.has_method("open"):
			gate.open()
	
	phase_completed.emit(current_phase_index)
	
	await get_tree().create_timer(1.0).timeout
	
	_start_next_phase()


func _on_all_phases_completed() -> void:
	print("[WaveManager] ALL PHASES COMPLETED! Victory!")
	is_running = false
	all_phases_completed.emit()
