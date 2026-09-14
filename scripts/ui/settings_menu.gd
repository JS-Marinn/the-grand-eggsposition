class_name SettingsMenu
extends Control

## Boutique Settings & Accessibility Menu for The Grand Eggsposition.
## Operates seamlessly from both Main Menu and In-Game Pause overlay.

signal closed()

@onready var window_mode_opt: OptionButton = %WindowModeOpt
@onready var res_opt: OptionButton = %ResolutionOpt
@onready var fps_limit_opt: OptionButton = %FPSLimitOpt
@onready var vsync_check: CheckBox = %VSyncCheck
@onready var show_fps_check: CheckBox = %ShowFPSCheck
@onready var fov_slider: HSlider = %FOVSlider
@onready var fov_val_label: Label = %FOVValLabel
@onready var head_bob_slider: HSlider = %HeadBobSlider
@onready var head_bob_val_label: Label = %HeadBobValLabel

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider

@onready var lang_opt: OptionButton = %LangOpt

@onready var mouse_sens_slider: HSlider = %SensSlider
@onready var key_look_slider: HSlider = %KeyLookSlider
@onready var invert_y_check: CheckBox = %InvertYCheck
@onready var invert_x_check: CheckBox = %InvertXCheck

# Accessibility
@onready var colorblind_opt: OptionButton = %ColorblindOpt
@onready var high_contrast_check: CheckBox = %HighContrastCheck
@onready var crosshair_dot_check: CheckBox = %CrosshairDotCheck
@onready var toggle_suction_check: CheckBox = %ToggleSuctionCheck
@onready var toggle_sprint_check: CheckBox = %ToggleSprintCheck
@onready var assisted_pickup_check: CheckBox = %AssistedPickupCheck
@onready var visual_cues_check: CheckBox = %VisualSoundCuesCheck
@onready var subtitles_check: CheckBox = %SubtitlesCheck
@onready var soft_sfx_check: CheckBox = %SoftSFXCheck

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

	if fps_limit_opt:
		fps_limit_opt.clear()
		fps_limit_opt.add_item(tr("OPTION_FPS_UNLIMITED"), 0)
		fps_limit_opt.add_item("30 FPS", 1)
		fps_limit_opt.add_item("60 FPS", 2)
		fps_limit_opt.add_item("120 FPS", 3)
		fps_limit_opt.add_item("144 FPS", 4)
		fps_limit_opt.add_item("240 FPS", 5)

	if lang_opt:
		lang_opt.clear()
		lang_opt.add_item("English (Original)", 0)
		lang_opt.add_item("Español (Castellano)", 1)

	if colorblind_opt:
		colorblind_opt.clear()
		colorblind_opt.add_item(tr("COLORBLIND_OFF"), 0)
		colorblind_opt.add_item(tr("COLORBLIND_PROTANOPIA"), 1)
		colorblind_opt.add_item(tr("COLORBLIND_DEUTERANOPIA"), 2)
		colorblind_opt.add_item(tr("COLORBLIND_TRITANOPIA"), 3)
		colorblind_opt.add_item(tr("COLORBLIND_ACHROMATOPSIA"), 4)

func _sync_from_manager() -> void:
	if window_mode_opt:
		window_mode_opt.selected = SettingsManager.window_mode

	if res_opt:
		match SettingsManager.resolution:
			Vector2i(1920, 1080): res_opt.selected = 0
			Vector2i(2560, 1440): res_opt.selected = 1
			Vector2i(1280, 720): res_opt.selected = 2
			_: res_opt.selected = 0

	if fps_limit_opt:
		match SettingsManager.fps_limit:
			0: fps_limit_opt.selected = 0
			30: fps_limit_opt.selected = 1
			60: fps_limit_opt.selected = 2
			120: fps_limit_opt.selected = 3
			144: fps_limit_opt.selected = 4
			240: fps_limit_opt.selected = 5
			_: fps_limit_opt.selected = 0

	if vsync_check:
		vsync_check.button_pressed = SettingsManager.vsync_enabled

	if show_fps_check:
		show_fps_check.button_pressed = SettingsManager.show_fps

	if fov_slider:
		fov_slider.value = SettingsManager.camera_fov
		_on_fov_slider_value_changed(SettingsManager.camera_fov)

	if head_bob_slider:
		head_bob_slider.value = SettingsManager.head_bob_intensity * 100.0
		_on_head_bob_slider_value_changed(head_bob_slider.value)

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

	if invert_x_check:
		invert_x_check.button_pressed = SettingsManager.invert_x

	if colorblind_opt:
		colorblind_opt.selected = SettingsManager.colorblind_mode

	if high_contrast_check:
		high_contrast_check.button_pressed = SettingsManager.high_contrast_outlines

	if crosshair_dot_check:
		crosshair_dot_check.button_pressed = SettingsManager.crosshair_dot

	if toggle_suction_check:
		toggle_suction_check.button_pressed = SettingsManager.toggle_suction

	if toggle_sprint_check:
		toggle_sprint_check.button_pressed = SettingsManager.toggle_sprint

	if assisted_pickup_check:
		assisted_pickup_check.button_pressed = SettingsManager.assisted_pickup

	if visual_cues_check:
		visual_cues_check.button_pressed = SettingsManager.visual_sound_cues

	if subtitles_check:
		subtitles_check.button_pressed = SettingsManager.subtitles_enabled

	if soft_sfx_check:
		soft_sfx_check.button_pressed = SettingsManager.soft_continuous_sfx

func _connect_signals() -> void:
	if fov_slider and not fov_slider.value_changed.is_connected(_on_fov_slider_value_changed):
		fov_slider.value_changed.connect(_on_fov_slider_value_changed)

	if head_bob_slider and not head_bob_slider.value_changed.is_connected(_on_head_bob_slider_value_changed):
		head_bob_slider.value_changed.connect(_on_head_bob_slider_value_changed)

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

func _on_head_bob_slider_value_changed(val: float) -> void:
	if head_bob_val_label:
		if is_zero_approx(val):
			head_bob_val_label.text = "0% (" + tr("OPTION_OFF") + ")"
		else:
			head_bob_val_label.text = "%d%%" % int(val)

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

	if fps_limit_opt:
		match fps_limit_opt.selected:
			0: SettingsManager.fps_limit = 0
			1: SettingsManager.fps_limit = 30
			2: SettingsManager.fps_limit = 60
			3: SettingsManager.fps_limit = 120
			4: SettingsManager.fps_limit = 144
			5: SettingsManager.fps_limit = 240
			_: SettingsManager.fps_limit = 0

	if vsync_check:
		SettingsManager.vsync_enabled = vsync_check.button_pressed

	if show_fps_check:
		SettingsManager.show_fps = show_fps_check.button_pressed

	if fov_slider:
		SettingsManager.camera_fov = fov_slider.value

	if head_bob_slider:
		SettingsManager.head_bob_intensity = head_bob_slider.value / 100.0

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

	if invert_x_check:
		SettingsManager.invert_x = invert_x_check.button_pressed

	# Save accessibility settings
	if colorblind_opt:
		SettingsManager.colorblind_mode = colorblind_opt.selected

	if high_contrast_check:
		SettingsManager.high_contrast_outlines = high_contrast_check.button_pressed

	if crosshair_dot_check:
		SettingsManager.crosshair_dot = crosshair_dot_check.button_pressed

	if toggle_suction_check:
		SettingsManager.toggle_suction = toggle_suction_check.button_pressed

	if toggle_sprint_check:
		SettingsManager.toggle_sprint = toggle_sprint_check.button_pressed

	if assisted_pickup_check:
		SettingsManager.assisted_pickup = assisted_pickup_check.button_pressed

	if visual_cues_check:
		SettingsManager.visual_sound_cues = visual_cues_check.button_pressed

	if subtitles_check:
		SettingsManager.subtitles_enabled = subtitles_check.button_pressed

	if soft_sfx_check:
		SettingsManager.soft_continuous_sfx = soft_sfx_check.button_pressed

	SettingsManager.save_settings()
	SettingsManager.apply_all()

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	visible = false
	closed.emit()
