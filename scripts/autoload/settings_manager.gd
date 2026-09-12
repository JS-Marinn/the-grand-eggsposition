extends Node

## Persistent Settings & Configuration Manager for The Grand Eggsposition.
## Saves and loads player preferences from user://settings.cfg.

signal settings_applied()

const CONFIG_PATH: String = "user://settings.cfg"

# Display & Video
var window_mode: int = 0 # 0: Windowed, 1: Borderless, 2: Fullscreen
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync_enabled: bool = true
var camera_fov: float = 80.0
var fov: float:
	get: return camera_fov
	set(v): camera_fov = v
var aa_enabled: bool = true

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

func _ready() -> void:
	_load_csv_translations()
	load_settings()
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

	# 3. Apply V-Sync
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)

	# 4. Apply Audio Busses
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Music", music_volume)

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

func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	
	# Video
	cfg.set_value("video", "window_mode", window_mode)
	cfg.set_value("video", "resolution_x", resolution.x)
	cfg.set_value("video", "resolution_y", resolution.y)
	cfg.set_value("video", "vsync", vsync_enabled)
	cfg.set_value("video", "fov", camera_fov)
	cfg.set_value("video", "aa", aa_enabled)
	
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
	
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(CONFIG_PATH)
	if err != OK:
		# First time launch, save default configuration
		save_settings()
		return
		
	# Video
	window_mode = cfg.get_value("video", "window_mode", window_mode)
	var rx: int = cfg.get_value("video", "resolution_x", resolution.x)
	var ry: int = cfg.get_value("video", "resolution_y", resolution.y)
	resolution = Vector2i(rx, ry)
	vsync_enabled = cfg.get_value("video", "vsync", vsync_enabled)
	camera_fov = cfg.get_value("video", "fov", camera_fov)
	aa_enabled = cfg.get_value("video", "aa", aa_enabled)
	
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
