class_name BenchmarkController
extends Node

## Controller for testing performance with 3,600 eggs on the floor.
## Defaults to 3,600 eggs arranged across the atrium floor & mezzanine balcony.

enum BenchmarkMode {
	FLOOR_3600 = 0,
	SHOWCASES_3600 = 1,
	NORMAL_60 = 2
}

var current_mode: BenchmarkMode = BenchmarkMode.FLOOR_3600
var benchmark_hud: Control = null
var floor_multimesh_instance: MultiMeshInstance3D = null

var label_title: Label
var label_fps: Label
var label_mode: Label
var label_stats: Label

var _fps_update_timer: float = 0.0
var _avg_fps: float = 60.0
var _fps_samples: Array[float] = []

const PALETTE: Array[Color] = [
	Color(0.96, 0.78, 0.18), # Pure Gold
	Color(0.86, 0.89, 0.94), # Pure Silver
	Color(0.93, 0.50, 0.32), # Pure Copper
	Color(0.78, 0.50, 0.24), # Bronze
	Color(0.12, 0.28, 0.65), # Lapis Lazuli
	Color(0.08, 0.58, 0.35), # Emerald
	Color(0.85, 0.12, 0.22), # Ruby
	Color(0.06, 0.20, 0.68), # Sapphire
	Color(0.55, 0.18, 0.72), # Amethyst
	Color(0.94, 0.68, 0.76), # Rose Quartz
	Color(0.12, 0.12, 0.14), # Obsidian
	Color(0.95, 0.95, 0.98), # Diamond / Pearl
	Color(0.20, 0.75, 0.72), # Turquoise
	Color(0.96, 0.55, 0.20), # Amber
	Color(0.88, 0.42, 0.55), # Coral
]

func _ready() -> void:
	# If running automated verification test suite, do not interfere with unit tests
	if get_tree().root.find_child("IntegrityVerifier", true, false) != null:
		return

	_setup_hud()
	# Place the 3,600 eggs on the floor by default
	call_deferred("_apply_mode", BenchmarkMode.FLOOR_3600)

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
	panel.custom_minimum_size = Vector2(380, 130)

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
	label_title.text = "⚡ RENDIMIENTO: 3.600 HUEVOS EN EL SUELO"
	label_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	label_title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(label_title)

	label_fps = Label.new()
	label_fps.text = "FPS: 60 (16.6 ms)"
	label_fps.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	label_fps.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label_fps)

	label_mode = Label.new()
	label_mode.text = "Huevos en escena: 3.600 en el suelo"
	label_mode.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label_mode.add_theme_font_size_override("font_size", 13)
	vbox.add_child(label_mode)

	label_stats = Label.new()
	label_stats.text = "[F8] Alternar Vitrinas / Suelo | [F10] Ocultar HUD"
	label_stats.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	label_stats.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_stats)

func _process(delta: float) -> void:
	if not benchmark_hud or not benchmark_hud.visible:
		return

	_fps_update_timer += delta
	if _fps_update_timer >= 0.2:
		_fps_update_timer = 0.0
		var current_fps = Engine.get_frames_per_second()
		var frame_time_ms = (1.0 / maxf(float(current_fps), 1.0)) * 1000.0

		_fps_samples.append(float(current_fps))
		if _fps_samples.size() > 30:
			_fps_samples.pop_front()

		var sum = 0.0
		for s in _fps_samples:
			sum += s
		_avg_fps = sum / float(_fps_samples.size())

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
			var next_mode = (int(current_mode) + 1) % 3
			_apply_mode(next_mode as BenchmarkMode)
		elif event.physical_keycode == KEY_F10:
			if benchmark_hud:
				benchmark_hud.visible = not benchmark_hud.visible

func _apply_mode(mode: BenchmarkMode) -> void:
	current_mode = mode
	_fps_samples.clear()

	if floor_multimesh_instance and is_instance_valid(floor_multimesh_instance):
		floor_multimesh_instance.queue_free()
		floor_multimesh_instance = null

	var showcases = get_parent().find_children("", "ShowcaseUnit", true, false)

	match mode:
		BenchmarkMode.FLOOR_3600:
			if label_mode:
				label_mode.text = "Modo: 3.600 Huevos en el Suelo (Atrio + Balcón)"
			# Empty showcases to normal
			for s_id in range(1, 61):
				if GameManager.showcase_state.has(s_id):
					for d in range(1, 6):
						GameManager.showcase_state[s_id][d] = 0
			for sc in showcases:
				sc._refresh_visuals()

			# Create the 3,600 eggs on the floor
			_create_floor_multimesh(3600)

		BenchmarkMode.SHOWCASES_3600:
			if label_mode:
				label_mode.text = "Modo: 3.600 Huevos en Vitrinas (60 vitrinas llenas)"
			for s_id in range(1, 61):
				if not GameManager.showcase_state.has(s_id):
					GameManager.showcase_state[s_id] = {}
				for d in range(1, 6):
					GameManager.showcase_state[s_id][d] = 12
			for sc in showcases:
				sc._refresh_visuals()

		BenchmarkMode.NORMAL_60:
			if label_mode:
				label_mode.text = "Modo Normal (Solo 60 Huevos iniciales)"
			for s_id in range(1, 61):
				if GameManager.showcase_state.has(s_id):
					for d in range(1, 6):
						GameManager.showcase_state[s_id][d] = 0
			for sc in showcases:
				sc._refresh_visuals()

func _create_floor_multimesh(count: int) -> void:
	floor_multimesh_instance = MultiMeshInstance3D.new()
	floor_multimesh_instance.name = "BenchmarkFloorMultiMesh"
	floor_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.28
	mat.metallic = 0.20
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	floor_multimesh_instance.material_override = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count
	mm.mesh = load("res://assets/models/baseegg_mesh.tres")

	# Golden spiral / Fermat phyllotaxis distribution across ground floor & mezzanine
	# 2,400 eggs on ground floor, 1,200 on mezzanine
	var c_ground = 2400
	var c_mezz = count - c_ground # 1200

	# Ground Floor: Radius 1.6m to 14.0m, height Y = 0.25m
	var phi = 2.399963229728653 # Golden angle in radians
	for i in range(c_ground):
		var theta = float(i) * phi
		var norm_r = sqrt(float(i + 8) / float(c_ground + 8))
		var r = 1.6 + norm_r * 12.4
		var x = cos(theta) * r
		var z = sin(theta) * r
		var y = 0.25

		# Natural subtle egg roll tilt and yaw
		var yaw = fmod(float(i) * 1.618, TAU)
		var tilt = sin(float(i) * 0.7) * 0.22 # gentle 12-degree tilt like real eggs resting
		var basis = Basis().rotated(Vector3.UP, yaw).rotated(Vector3.FORWARD, tilt)

		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, y, z)))
		var col = PALETTE[i % PALETTE.size()]
		mm.set_instance_color(i, col)

	# Mezzanine Floor: Ring from Radius 12.2m to 14.2m, height Y = 3.75m
	for j in range(c_mezz):
		var idx = c_ground + j
		var theta_m = float(j) * (TAU / float(c_mezz)) * 8.0
		var r_m = 12.2 + fmod(float(j) * 0.015, 2.0)
		var x_m = cos(theta_m) * r_m
		var z_m = sin(theta_m) * r_m
		var y_m = 3.75

		var yaw_m = fmod(float(j) * 2.1, TAU)
		var tilt_m = sin(float(j) * 0.9) * 0.18
		var basis_m = Basis().rotated(Vector3.UP, yaw_m).rotated(Vector3.FORWARD, tilt_m)

		mm.set_instance_transform(idx, Transform3D(basis_m, Vector3(x_m, y_m, z_m)))
		var col_m = PALETTE[(j * 3) % PALETTE.size()]
		mm.set_instance_color(idx, col_m)

	floor_multimesh_instance.multimesh = mm
	get_parent().add_child(floor_multimesh_instance)
