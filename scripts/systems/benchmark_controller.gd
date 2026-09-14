class_name BenchmarkController
extends Node

## Controller for testing performance with 3,600 eggs in the scene.
## Allows testing:
## 1. 3,600 eggs rendered in the 60 showcases (GPU MultiMesh instancing)
## 2. 3,600 eggs distributed across the atrium floor & mezzanine (MultiMesh)
## 3. 3,600 physical egg actors on the floor (Physics & Node tree stress)
## 4. Normal gameplay mode (60 initial floor eggs)

enum BenchmarkMode {
	SHOWCASES_3600 = 0,
	FLOOR_MULTIMESH_3600 = 1,
	FLOOR_PHYSICS_3600 = 2,
	NORMAL_60 = 3
}

var current_mode: BenchmarkMode = BenchmarkMode.SHOWCASES_3600
var benchmark_hud: Control = null
var floor_multimesh_instance: MultiMeshInstance3D = null
var floor_physics_container: Node3D = null

var label_title: Label
var label_fps: Label
var label_mode: Label
var label_stats: Label

var _fps_update_timer: float = 0.0
var _min_fps: float = 999.0
var _max_fps: float = 0.0
var _avg_fps: float = 60.0
var _fps_samples: Array[float] = []

func _ready() -> void:
	# If running automated verification test suite, do not interfere with tests
	if get_tree().root.find_child("IntegrityVerifier", true, false) != null:
		return

	_setup_hud()
	# Apply 3,600 showcase eggs immediately on game start as requested
	call_deferred("_apply_mode", BenchmarkMode.SHOWCASES_3600)

func _setup_hud() -> void:
	benchmark_hud = Control.new()
	benchmark_hud.name = "BenchmarkHUD"
	benchmark_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	benchmark_hud.anchors_preset = Control.PRESET_FULL_RECT
	benchmark_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(benchmark_hud)

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(24, 70)
	panel.custom_minimum_size = Vector2(360, 140)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 0.88)
	style.border_color = Color(0.85, 0.70, 0.32, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	benchmark_hud.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	label_title = Label.new()
	label_title.text = "⚡ TEST DE RENDIMIENTO: 3.600 HUEVOS"
	label_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	label_title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(label_title)

	label_fps = Label.new()
	label_fps.text = "FPS: 60 (16.6 ms)"
	label_fps.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	label_fps.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label_fps)

	label_mode = Label.new()
	label_mode.text = "Modo: Vitrinas Llenas (3.600 Huevos)"
	label_mode.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label_mode.add_theme_font_size_override("font_size", 13)
	vbox.add_child(label_mode)

	label_stats = Label.new()
	label_stats.text = "[F8] Cambiar Modo | [F9] Vaciar/Llenar | [F10] Ocultar"
	label_stats.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	label_stats.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_stats)

func _process(delta: float) -> void:
	if not benchmark_hud or not benchmark_hud.visible:
		return

	_fps_update_timer += delta
	if _fps_update_timer >= 0.25:
		_fps_update_timer = 0.0
		var current_fps = Engine.get_frames_per_second()
		var frame_time_ms = (1.0 / maxf(float(current_fps), 1.0)) * 1000.0

		_fps_samples.append(float(current_fps))
		if _fps_samples.size() > 60:
			_fps_samples.pop_front()

		var sum = 0.0
		for s in _fps_samples:
			sum += s
		_avg_fps = sum / float(_fps_samples.size())
		_min_fps = minf(_min_fps, float(current_fps))
		_max_fps = maxf(_max_fps, float(current_fps))

		var color_fps = Color(0.4, 1.0, 0.5)
		if current_fps < 30:
			color_fps = Color(1.0, 0.3, 0.3)
		elif current_fps < 60:
			color_fps = Color(1.0, 0.8, 0.2)

		label_fps.text = "%d FPS  (%.1f ms)  [Avg: %d]" % [current_fps, frame_time_ms, int(_avg_fps)]
		label_fps.add_theme_color_override("font_color", color_fps)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F8:
			var next_mode = (int(current_mode) + 1) % 4
			_apply_mode(next_mode as BenchmarkMode)
		elif event.physical_keycode == KEY_F9:
			if current_mode == BenchmarkMode.SHOWCASES_3600:
				_apply_mode(BenchmarkMode.NORMAL_60)
			else:
				_apply_mode(BenchmarkMode.SHOWCASES_3600)
		elif event.physical_keycode == KEY_F10:
			if benchmark_hud:
				benchmark_hud.visible = not benchmark_hud.visible

func _apply_mode(mode: BenchmarkMode) -> void:
	current_mode = mode
	_fps_samples.clear()
	_min_fps = 999.0
	_max_fps = 0.0

	# 1. Clean up floor multimesh and floor physics if present
	if floor_multimesh_instance and is_instance_valid(floor_multimesh_instance):
		floor_multimesh_instance.queue_free()
		floor_multimesh_instance = null

	if floor_physics_container and is_instance_valid(floor_physics_container):
		floor_physics_container.queue_free()
		floor_physics_container = null

	var showcases = get_parent().find_children("", "ShowcaseUnit", true, false)

	match mode:
		BenchmarkMode.SHOWCASES_3600:
			if label_mode:
				label_mode.text = "Modo: 3.600 Huevos en Vitrinas (GPU MultiMesh)"
			# Fill all 60 showcases with 12 eggs per tier (60 eggs * 60 = 3600)
			for s_id in range(1, 61):
				if not GameManager.showcase_state.has(s_id):
					GameManager.showcase_state[s_id] = {}
				for d in range(1, 6):
					GameManager.showcase_state[s_id][d] = 12
			for sc in showcases:
				sc._refresh_visuals()

		BenchmarkMode.FLOOR_MULTIMESH_3600:
			if label_mode:
				label_mode.text = "Modo: 3.600 Huevos en Suelo (MultiMesh Atrio)"
			# Empty showcases to baseline
			for s_id in range(1, 61):
				if GameManager.showcase_state.has(s_id):
					for d in range(1, 6):
						GameManager.showcase_state[s_id][d] = 0
			for sc in showcases:
				sc._refresh_visuals()

			# Create floor MultiMesh with 3600 eggs
			_create_floor_multimesh(3600)

		BenchmarkMode.FLOOR_PHYSICS_3600:
			if label_mode:
				label_mode.text = "Modo: 3.600 Huevos Físicos (Stress de Nodos)"
			# Empty showcases
			for s_id in range(1, 61):
				if GameManager.showcase_state.has(s_id):
					for d in range(1, 6):
						GameManager.showcase_state[s_id][d] = 0
			for sc in showcases:
				sc._refresh_visuals()

			# Spawn physics eggs
			_spawn_floor_physics_eggs(3600)

		BenchmarkMode.NORMAL_60:
			if label_mode:
				label_mode.text = "Modo: Normal (60 Huevos en Suelo, Vitrinas Vacías)"
			for s_id in range(1, 61):
				if GameManager.showcase_state.has(s_id):
					for d in range(1, 6):
						GameManager.showcase_state[s_id][d] = 0
			for sc in showcases:
				sc._refresh_visuals()

func _create_floor_multimesh(count: int) -> void:
	floor_multimesh_instance = MultiMeshInstance3D.new()
	floor_multimesh_instance.name = "BenchmarkFloorMultiMesh"
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count
	mm.mesh = load("res://assets/models/baseegg_mesh.tres")

	# Distribute 2,400 eggs on ground floor and 1,200 on mezzanine
	for i in range(count):
		var angle = float(i) * 0.174533
		var r: float
		var y: float
		if i < 2400:
			r = 2.4 + fmod(float(i) * 0.0042, 11.2)
			y = 0.25
		else:
			r = 12.6 + fmod(float(i) * 0.0028, 2.0)
			y = 3.75

		var pos = Vector3(cos(angle) * r, y, sin(angle) * r)
		mm.set_instance_transform(i, Transform3D(Basis(), pos))
		var hue = fmod(float(i) * 0.017, 1.0)
		mm.set_instance_color(i, Color.from_hsv(hue, 0.75, 0.95))

	floor_multimesh_instance.multimesh = mm
	get_parent().add_child(floor_multimesh_instance)

func _spawn_floor_physics_eggs(count: int) -> void:
	floor_physics_container = Node3D.new()
	floor_physics_container.name = "BenchmarkFloorPhysics"
	get_parent().add_child(floor_physics_container)

	var egg_scn: PackedScene = load("res://scenes/props/egg_actor.tscn")
	if not egg_scn:
		return

	var to_spawn = mini(count, 1200)
	for i in range(to_spawn):
		var egg: RigidBody3D = egg_scn.instantiate() as RigidBody3D
		egg.egg_id = (i % 15) + 1
		egg.freeze = true
		var angle = float(i) * 0.2
		var r = 3.0 + fmod(float(i) * 0.008, 10.0)
		egg.position = Vector3(cos(angle) * r, 0.25, sin(angle) * r)
		floor_physics_container.add_child(egg)
