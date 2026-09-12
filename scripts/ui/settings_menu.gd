class_name SettingsMenu
extends Control

## Boutique Settings & Accessibility Menu for The Grand Eggsposition.
## Operates seamlessly from both Main Menu and In-Game Pause overlay.

signal closed()

@onready var window_mode_opt: OptionButton = %WindowModeOpt
@onready var res_opt: OptionButton = %ResolutionOpt
@onready var vsync_check: CheckBox = %VSyncCheck
@onready var show_fps_check: CheckBox = %ShowFPSCheck
@onready var fov_slider: HSlider = %FOVSlider
@onready var fov_val_label: Label = %FOVValLabel

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider

@onready var lang_opt: OptionButton = %LangOpt

@onready var mouse_sens_slider: HSlider = %SensSlider
@onready var key_look_slider: HSlider = %KeyLookSlider
@onready var invert_y_check: CheckBox = %InvertYCheck

@onready var btn_apply: Button = %BtnApply
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_options()
	_sync_from_manager()
	_connect_signals()

func _populate_options() -> void:
	if window_mode_opt:
		window_mode_opt.clear()
		window_mode_opt.add_item(tr("MODE_WINDOWED"), 0)
		window_mode_opt.add_item(tr("MODE_BORDERLESS"), 1)
		window_mode_opt.add_item(tr("MODE_FULLSCREEN"), 2)

	if res_opt:
		res_opt.clear()
		res_opt.add_item("1920 x 1080 (16:9 Full HD)", 0)
		res_opt.add_item("2560 x 1440 (16:9 QHD)", 1)
		res_opt.add_item("1280 x 720 (16:9 HD)", 2)

	if lang_opt:
		lang_opt.clear()
		lang_opt.add_item("English (Original)", 0)
		lang_opt.add_item("Español (Castellano)", 1)

func _sync_from_manager() -> void:
	if window_mode_opt:
		window_mode_opt.selected = SettingsManager.window_mode

	if res_opt:
		match SettingsManager.resolution:
			Vector2i(1920, 1080): res_opt.selected = 0
			Vector2i(2560, 1440): res_opt.selected = 1
			Vector2i(1280, 720): res_opt.selected = 2
			_: res_opt.selected = 0

	if vsync_check:
		vsync_check.button_pressed = SettingsManager.vsync_enabled

	if show_fps_check:
		show_fps_check.button_pressed = SettingsManager.show_fps

	if fov_slider:
		fov_slider.value = SettingsManager.camera_fov
		_on_fov_slider_value_changed(SettingsManager.camera_fov)

	if master_slider:
		master_slider.value = SettingsManager.master_volume * 100.0

	if sfx_slider:
		sfx_slider.value = SettingsManager.sfx_volume * 100.0

	if music_slider:
		music_slider.value = SettingsManager.music_volume * 100.0

	if lang_opt:
		lang_opt.selected = 0 if SettingsManager.current_locale == "en" else 1

	if mouse_sens_slider:
		mouse_sens_slider.value = SettingsManager.mouse_sensitivity * 1000.0

	if key_look_slider:
		key_look_slider.value = SettingsManager.key_look_speed

	if invert_y_check:
		invert_y_check.button_pressed = SettingsManager.invert_y

func _connect_signals() -> void:
	if fov_slider and not fov_slider.value_changed.is_connected(_on_fov_slider_value_changed):
		fov_slider.value_changed.connect(_on_fov_slider_value_changed)

	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
		btn_apply.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
		btn_back.mouse_entered.connect(AudioManager.play_ui_hover)

	if lang_opt and not lang_opt.item_selected.is_connected(_on_language_selected):
		lang_opt.item_selected.connect(_on_language_selected)

func _on_fov_slider_value_changed(val: float) -> void:
	if fov_val_label:
		fov_val_label.text = "%d deg" % int(val)

func _on_language_selected(index: int) -> void:
	AudioManager.play_ui_click()
	var selected_locale: String = "en" if index == 0 else "es"
	SettingsManager.set_language(selected_locale)
	_populate_options()
	_sync_from_manager()

func _on_apply_pressed() -> void:
	AudioManager.play_ui_click()

	# Save video settings
	if window_mode_opt:
		SettingsManager.window_mode = window_mode_opt.selected

	if res_opt:
		match res_opt.selected:
			0: SettingsManager.resolution = Vector2i(1920, 1080)
			1: SettingsManager.resolution = Vector2i(2560, 1440)
			2: SettingsManager.resolution = Vector2i(1280, 720)

	if vsync_check:
		SettingsManager.vsync_enabled = vsync_check.button_pressed

	if show_fps_check:
		SettingsManager.show_fps = show_fps_check.button_pressed

	if fov_slider:
		SettingsManager.camera_fov = fov_slider.value

	# Save audio settings
	if master_slider:
		SettingsManager.master_volume = master_slider.value / 100.0

	if sfx_slider:
		SettingsManager.sfx_volume = sfx_slider.value / 100.0

	if music_slider:
		SettingsManager.music_volume = music_slider.value / 100.0

	# Save control settings
	if mouse_sens_slider:
		SettingsManager.mouse_sensitivity = mouse_sens_slider.value / 1000.0

	if key_look_slider:
		SettingsManager.key_look_speed = key_look_slider.value

	if invert_y_check:
		SettingsManager.invert_y = invert_y_check.button_pressed

	SettingsManager.save_settings()
	SettingsManager.apply_all()

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	visible = false
	closed.emit()
