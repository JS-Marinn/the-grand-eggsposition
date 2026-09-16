extends Node

## Persistent Settings & Configuration Manager for The Grand Eggsposition.
## Saves and loads player preferences from user://settings.cfg.

signal settings_applied()

const CONFIG_PATH: String = "user://settings.cfg"

# Display & Video
var window_mode: int = 0 # 0: Windowed, 1: Borderless, 2: Fullscreen
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync_enabled: bool = false
var fps_limit: int = 0 # 0: Unlimited, 30, 60, 120, 144, 240
var camera_fov: float = 80.0
var fov: float:
	get: return camera_fov
	set(v): camera_fov = v
var aa_enabled: bool = true
var show_fps: bool = false
var head_bob_intensity: float = 0.20 # Linear 0.0 (off) to 1.0 (max), default 0.20 (ultra-light)

# Graphics Quality Suite
enum GraphicsPreset { LOW = 0, MEDIUM = 1, HIGH = 2, ULTRA = 3, CUSTOM = 4 }
var graphics_preset: int = GraphicsPreset.HIGH
var shadow_quality: int = 2 # 0: Off, 1: Low (1024), 2: Medium (2048), 3: High (4096)
var anti_aliasing: int = 2 # 0: Off, 1: FXAA, 2: MSAA 2x, 3: MSAA 4x, 4: MSAA 8x
var ssao_enabled: bool = true
var glow_enabled: bool = true
var resolution_scale: float = 1.0 # 0.67, 0.77, 0.85, 1.0
var mesh_lod_quality: int = 2 # 0: Low (4.0), 1: Medium (2.0), 2: High (1.0), 3: Ultra (0.0)
var texture_quality: int = 2  # 0: Low (mipmap+2), 1: Medium (mipmap+1), 2: High (0), 3: Ultra (-1)
var has_auto_detected: bool = false
var detected_gpu_name: String = ""

# Audio (Linear 0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.8
var ambient_volume: float = 0.7

# Language / Localization
var current_locale: String = "en"

# Controls & Gameplay
var mouse_sensitivity: float = 0.003
var key_look_speed: float = 2.4
var invert_y: bool = false
var invert_x: bool = false

# Accessibility - Visual
var colorblind_mode: int = 0 # 0: Off, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia, 4: Achromatopsia
var colorblind_intensity: float = 1.0 # 0.0 to 1.0 (intensity when mode > 0)
var high_contrast_outlines: bool = false
var crosshair_dot: bool = true

# Accessibility - Motor & Controls
var toggle_suction: bool = false
var toggle_sprint: bool = false
var assisted_pickup: bool = false

# Accessibility - Auditory
var subtitles_enabled: bool = false
var visual_sound_cues: bool = false
var soft_continuous_sfx: bool = false

func _ready() -> void:
	_load_csv_translations()
	load_settings()
	apply_all()

func reset_to_defaults() -> void:
	detect_hardware_and_recommend()
	colorblind_mode = 0
	colorblind_intensity = 1.0
	high_contrast_outlines = false
	crosshair_dot = true
	toggle_suction = false
	toggle_sprint = false
	assisted_pickup = false
	subtitles_enabled = false
	visual_sound_cues = false
	soft_continuous_sfx = false
	invert_x = false
	invert_y = false
	save_settings()
	apply_all()

func _load_csv_translations() -> void:
	var path: String = "res://localization/translations.csv"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var t_en: Translation = Translation.new()
	t_en.locale = "en"
	var t_es: Translation = Translation.new()
	t_es.locale = "es"
	var _header = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() >= 3 and row[0].strip_edges() != "":
			var k: String = row[0].strip_edges()
			t_en.add_message(k, row[1])
			t_es.add_message(k, row[2])
	file.close()
	TranslationServer.add_translation(t_en)
	TranslationServer.add_translation(t_es)

func apply_all() -> void:
	# 1. Apply Language
	TranslationServer.set_locale(current_locale)
	
	# 2. Apply Display Window Mode
	match window_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(resolution)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# 3. Apply V-Sync & Max FPS Limit
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = fps_limit

	# 4. Apply Audio Busses
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Music", music_volume)

	# 5. Apply Graphics Settings
	apply_graphics_settings()

	settings_applied.emit()

func _set_bus_volume(bus_name: String, linear_vol: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var db: float = linear_to_db(linear_vol) if linear_vol > 0.001 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)

func set_language(locale: String) -> void:
	current_locale = locale
	TranslationServer.set_locale(locale)
	save_settings()
	settings_applied.emit()

func apply_preset(preset_idx: int) -> void:
	graphics_preset = preset_idx
	match preset_idx:
		GraphicsPreset.LOW:
			shadow_quality = 1
			anti_aliasing = 1
			ssao_enabled = false
			glow_enabled = false
			resolution_scale = 0.77
			mesh_lod_quality = 0
			texture_quality = 0
		GraphicsPreset.MEDIUM:
			shadow_quality = 2
			anti_aliasing = 1
			ssao_enabled = false
			glow_enabled = true
			resolution_scale = 0.85
			mesh_lod_quality = 1
			texture_quality = 1
		GraphicsPreset.HIGH:
			shadow_quality = 2
			anti_aliasing = 2
			ssao_enabled = true
			glow_enabled = true
			resolution_scale = 1.0
			mesh_lod_quality = 2
			texture_quality = 2
		GraphicsPreset.ULTRA:
			shadow_quality = 3
			anti_aliasing = 3
			ssao_enabled = true
			glow_enabled = true
			resolution_scale = 1.0
			mesh_lod_quality = 3
			texture_quality = 3
		GraphicsPreset.CUSTOM:
			pass
	apply_graphics_settings()

func apply_graphics_settings() -> void:
	# 1. Shadow Quality
	match shadow_quality:
		0:
			RenderingServer.directional_shadow_atlas_set_size(512, true)
		1:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		2:
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		3:
			RenderingServer.directional_shadow_atlas_set_size(4096, true)

	# 2. Anti-Aliasing & Resolution Scale on Viewport
	var vp: Viewport = get_viewport()
	if vp:
		match anti_aliasing:
			0:
				vp.msaa_3d = Viewport.MSAA_DISABLED
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			1:
				vp.msaa_3d = Viewport.MSAA_DISABLED
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			2:
				vp.msaa_3d = Viewport.MSAA_2X
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			3:
				vp.msaa_3d = Viewport.MSAA_4X
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			4:
				vp.msaa_3d = Viewport.MSAA_8X
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		vp.scaling_3d_scale = resolution_scale
		match mesh_lod_quality:
			0:
				vp.mesh_lod_threshold = 4.0
			1:
				vp.mesh_lod_threshold = 2.0
			2:
				vp.mesh_lod_threshold = 1.0
			3:
				vp.mesh_lod_threshold = 0.0
		# Texture quality via mipmap bias:
		# Positive bias = lower resolution mips (less VRAM), negative = force higher detail
		match texture_quality:
			0: vp.texture_mipmap_bias = 2.0   # Low  (~512 effective)
			1: vp.texture_mipmap_bias = 1.0   # Medium (~1024 effective)
			2: vp.texture_mipmap_bias = 0.0   # High  (native 2048, default)
			3: vp.texture_mipmap_bias = -1.0  # Ultra (force sharper than native)

	# 3. Environment effects (SSAO, Glow) on active WorldEnvironments
	_apply_environment_settings()

func _apply_environment_settings() -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is WorldEnvironment and node.environment:
			node.environment.ssao_enabled = ssao_enabled
			node.environment.glow_enabled = glow_enabled
		for child in node.get_children():
			stack.push_back(child)

func detect_hardware_and_recommend() -> Dictionary:
	var gpu_name: String = RenderingServer.get_video_adapter_name()
	var gpu_vendor: String = RenderingServer.get_video_adapter_vendor()
	var gpu_type: int = RenderingServer.get_video_adapter_type()
	var cpu_cores: int = OS.get_processor_count()
	var cpu_name: String = OS.get_processor_name()

	if gpu_name.is_empty():
		if OS.get_name() == "Windows":
			gpu_name = "AMD Radeon RX 5500 XT"
		else:
			gpu_name = "Default 3D Graphics Adapter"

	var recommended_preset: int = GraphicsPreset.HIGH
	var upper_gpu: String = gpu_name.to_upper()
	var is_discrete: bool = (gpu_type == 1 or "RADEON" in upper_gpu or "GEFORCE" in upper_gpu or "NVIDIA" in upper_gpu or "RTX" in upper_gpu or "GTX" in upper_gpu)

	if "RTX 40" in upper_gpu or "RTX 3080" in upper_gpu or "RTX 3090" in upper_gpu or "RX 7900" in upper_gpu or "RX 6800" in upper_gpu:
		recommended_preset = GraphicsPreset.ULTRA
	elif is_discrete or "RX 5500" in upper_gpu or "GTX 16" in upper_gpu or "RTX 20" in upper_gpu or "RTX 30" in upper_gpu or cpu_cores >= 8:
		recommended_preset = GraphicsPreset.HIGH
	elif "IRIS" in upper_gpu or "VEGA" in upper_gpu or cpu_cores >= 4:
		recommended_preset = GraphicsPreset.MEDIUM
	else:
		recommended_preset = GraphicsPreset.LOW

	has_auto_detected = true
	detected_gpu_name = gpu_name
	apply_preset(recommended_preset)
	save_settings()

	var preset_keys = ["PRESET_LOW", "PRESET_MEDIUM", "PRESET_HIGH", "PRESET_ULTRA", "PRESET_CUSTOM"]
	return {
		"gpu_name": gpu_name,
		"gpu_vendor": gpu_vendor,
		"cpu_name": cpu_name,
		"cpu_cores": cpu_cores,
		"recommended_preset": recommended_preset,
		"preset_key": preset_keys[recommended_preset]
	}

func get_preset_key(preset_idx: int) -> String:
	match preset_idx:
		GraphicsPreset.LOW: return "PRESET_LOW"
		GraphicsPreset.MEDIUM: return "PRESET_MEDIUM"
		GraphicsPreset.HIGH: return "PRESET_HIGH"
		GraphicsPreset.ULTRA: return "PRESET_ULTRA"
		GraphicsPreset.CUSTOM: return "PRESET_CUSTOM"
	return "PRESET_HIGH"

func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	
	# Graphics
	cfg.set_value("graphics", "auto_detected", has_auto_detected)
	cfg.set_value("graphics", "detected_gpu", detected_gpu_name)
	cfg.set_value("graphics", "preset", graphics_preset)
	cfg.set_value("graphics", "shadow_quality", shadow_quality)
	cfg.set_value("graphics", "anti_aliasing", anti_aliasing)
	cfg.set_value("graphics", "ssao_enabled", ssao_enabled)
	cfg.set_value("graphics", "glow_enabled", glow_enabled)
	cfg.set_value("graphics", "resolution_scale", resolution_scale)
	cfg.set_value("graphics", "mesh_lod_quality", mesh_lod_quality)
	cfg.set_value("graphics", "texture_quality", texture_quality)
	
	# Video
	cfg.set_value("video", "window_mode", window_mode)
	cfg.set_value("video", "resolution_x", resolution.x)
	cfg.set_value("video", "resolution_y", resolution.y)
	cfg.set_value("video", "vsync", vsync_enabled)
	cfg.set_value("video", "fps_limit", fps_limit)
	cfg.set_value("video", "fov", camera_fov)
	cfg.set_value("video", "aa", aa_enabled)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("video", "head_bob", head_bob_intensity)
	
	# Audio
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "ambient", ambient_volume)
	
	# Language
	cfg.set_value("locale", "language", current_locale)
	
	# Controls
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "key_look_speed", key_look_speed)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("controls", "invert_x", invert_x)

	# Accessibility
	cfg.set_value("accessibility", "colorblind_mode", colorblind_mode)
	cfg.set_value("accessibility", "colorblind_intensity", colorblind_intensity)
	cfg.set_value("accessibility", "high_contrast_outlines", high_contrast_outlines)
	cfg.set_value("accessibility", "crosshair_dot", crosshair_dot)
	cfg.set_value("accessibility", "toggle_suction", toggle_suction)
	cfg.set_value("accessibility", "toggle_sprint", toggle_sprint)
	cfg.set_value("accessibility", "assisted_pickup", assisted_pickup)
	cfg.set_value("accessibility", "subtitles_enabled", subtitles_enabled)
	cfg.set_value("accessibility", "visual_sound_cues", visual_sound_cues)
	cfg.set_value("accessibility", "soft_continuous_sfx", soft_continuous_sfx)
	
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(CONFIG_PATH)
	if err != OK:
		# First time launch: automatically detect hardware components and apply recommended graphics preset
		detect_hardware_and_recommend()
		save_settings()
		return
		
	# Graphics
	has_auto_detected = cfg.get_value("graphics", "auto_detected", false)
	detected_gpu_name = cfg.get_value("graphics", "detected_gpu", "")
	var current_gpu: String = RenderingServer.get_video_adapter_name()
	var gpu_changed: bool = not current_gpu.is_empty() and not detected_gpu_name.is_empty() and detected_gpu_name != current_gpu
	if not has_auto_detected or not cfg.has_section("graphics") or (gpu_changed and graphics_preset != GraphicsPreset.CUSTOM):
		# Automatically detect hardware if not previously benchmarked or if GPU adapter changed
		detect_hardware_and_recommend()
	else:
		graphics_preset = cfg.get_value("graphics", "preset", graphics_preset)
		shadow_quality = cfg.get_value("graphics", "shadow_quality", shadow_quality)
		anti_aliasing = cfg.get_value("graphics", "anti_aliasing", anti_aliasing)
		ssao_enabled = cfg.get_value("graphics", "ssao_enabled", ssao_enabled)
		glow_enabled = cfg.get_value("graphics", "glow_enabled", glow_enabled)
		resolution_scale = cfg.get_value("graphics", "resolution_scale", resolution_scale)
		mesh_lod_quality = cfg.get_value("graphics", "mesh_lod_quality", mesh_lod_quality)
		texture_quality  = cfg.get_value("graphics", "texture_quality",  texture_quality)

	# Video
	window_mode = cfg.get_value("video", "window_mode", window_mode)
	var rx: int = cfg.get_value("video", "resolution_x", resolution.x)
	var ry: int = cfg.get_value("video", "resolution_y", resolution.y)
	resolution = Vector2i(rx, ry)
	vsync_enabled = cfg.get_value("video", "vsync", vsync_enabled)
	fps_limit = cfg.get_value("video", "fps_limit", fps_limit)
	camera_fov = cfg.get_value("video", "fov", camera_fov)
	aa_enabled = cfg.get_value("video", "aa", aa_enabled)
	show_fps = cfg.get_value("video", "show_fps", show_fps)
	head_bob_intensity = cfg.get_value("video", "head_bob", head_bob_intensity)
	
	# Audio
	master_volume = cfg.get_value("audio", "master", master_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	ambient_volume = cfg.get_value("audio", "ambient", ambient_volume)
	
	# Language
	current_locale = cfg.get_value("locale", "language", current_locale)
	
	# Controls
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	key_look_speed = cfg.get_value("controls", "key_look_speed", key_look_speed)
	invert_y = cfg.get_value("controls", "invert_y", invert_y)
	invert_x = cfg.get_value("controls", "invert_x", invert_x)

	# Accessibility
	colorblind_mode = cfg.get_value("accessibility", "colorblind_mode", colorblind_mode)
	colorblind_intensity = cfg.get_value("accessibility", "colorblind_intensity", colorblind_intensity)
	high_contrast_outlines = cfg.get_value("accessibility", "high_contrast_outlines", high_contrast_outlines)
	crosshair_dot = cfg.get_value("accessibility", "crosshair_dot", crosshair_dot)
	toggle_suction = cfg.get_value("accessibility", "toggle_suction", toggle_suction)
	toggle_sprint = cfg.get_value("accessibility", "toggle_sprint", toggle_sprint)
	assisted_pickup = cfg.get_value("accessibility", "assisted_pickup", assisted_pickup)
	subtitles_enabled = cfg.get_value("accessibility", "subtitles_enabled", subtitles_enabled)
	visual_sound_cues = cfg.get_value("accessibility", "visual_sound_cues", visual_sound_cues)
	soft_continuous_sfx = cfg.get_value("accessibility", "soft_continuous_sfx", soft_continuous_sfx)


