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

# === CONFIGURATION ===
var phases: Array[WaveData] = []

## Spawn offset from right edge of screen
var spawn_offset_x: float = 100.0

## Y range for enemy spawns
var spawn_y_min: float = -200.0
var spawn_y_max: float = 550.0

# === STATE ===
var current_phase_index: int = -1
var current_subwave_index: int = -1
var enemies_alive: Array[Node2D] = []
var current_boss: Node2D = null
var is_running: bool = false

# === REFERENCES ===
var _camera: Camera2D = null
var _gates: Array[Node2D] = []
var _arrow_indicator: Control = null
var _reward_screen: CanvasLayer  = null


func _ready() -> void:
	pass
	
## Call this from main.gd to start the wave system
func start_waves(camera: Camera2D, gates: Array, arrow: Control, reward: CanvasLayer) -> void:
	_camera = camera
	_gates = gates
	_arrow_indicator = arrow
	_reward_screen = reward
	
	if _arrow_indicator:
		_arrow_indicator.hide()
	if _reward_screen:
		_reward_screen.hide()
	
	_setup_initial_gates()
	
	is_running = true
	current_phase_index = -1
	_start_next_phase()


func _setup_initial_gates() -> void:
	for i in range(_gates.size()):
		var gate = _gates[i]
		if gate.has_method("close"):
			gate.close()


func _start_next_phase() -> void:
	current_phase_index += 1
	current_subwave_index = -1
	
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
	
	get_tree().current_scene.add_child(enemy)
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
		# Spawn boss directly, no arrow here
		_spawn_boss(phase)
	else:
		# No boss, just complete the phase
		_on_phase_completed()
		
func _show_arrow() -> void:
	if _arrow_indicator:
		_arrow_indicator.show()
	print("[WaveManager] Arrow shown - advance!")


func _hide_arrow() -> void:
	if _arrow_indicator:
		_arrow_indicator.hide()

func _spawn_boss(phase: WaveData) -> void:
	print("[WaveManager] Spawning boss!")
	
	var boss = phase.boss_scene.instantiate()
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_center = _camera.get_screen_center_position()
	var half_width = viewport_size.x / (2.0 * _camera.zoom.x)
	
	boss.global_position = Vector2(camera_center.x + half_width + 150, 100)
	
	var target_scale = boss.scale
	boss.scale = Vector2.ZERO
	
	get_tree().current_scene.add_child(boss)
	
	var tween = create_tween()
	tween.tween_property(boss, "scale", target_scale, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)
	
	current_boss = boss
	boss_spawned.emit(boss)


func _on_boss_died(_boss: Node2D) -> void:
	print("[WaveManager] Boss defeated!")
	current_boss = null
	boss_defeated.emit()
	
	# Open the gate first
	if current_phase_index < _gates.size():
		var gate = _gates[current_phase_index]
		if gate.has_method("open"):
			gate.open()
	
	# Show arrow to indicate player can move
	if _arrow_indicator and _arrow_indicator.has_method("display"):
		_arrow_indicator.display(3.0)  # Show for 3 seconds
	
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
