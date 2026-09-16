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
@onready var colorblind_intensity_row: HBoxContainer = %ColorblindIntensityRow
@onready var colorblind_intensity_slider: HSlider = %ColorblindIntensitySlider
@onready var colorblind_intensity_val: Label = %ColorblindIntensityVal
@onready var high_contrast_check: CheckBox = %HighContrastCheck
@onready var crosshair_dot_check: CheckBox = %CrosshairDotCheck
@onready var toggle_suction_check: CheckBox = %ToggleSuctionCheck
@onready var toggle_sprint_check: CheckBox = %ToggleSprintCheck
@onready var assisted_pickup_check: CheckBox = %AssistedPickupCheck
@onready var visual_cues_check: CheckBox = %VisualSoundCuesCheck
@onready var subtitles_check: CheckBox = %SubtitlesCheck
@onready var soft_sfx_check: CheckBox = %SoftSFXCheck

# Graphics Quality Controls
@onready var graphics_preset_opt: OptionButton = %GraphicsPresetOpt
@onready var auto_detect_btn: Button = %AutoDetectBtn
@onready var hw_detect_info_label: Label = %HWDetectInfoLabel
@onready var shadow_opt: OptionButton = %ShadowOpt
@onready var aa_opt: OptionButton = %AAOpt
@onready var ssao_check: CheckBox = %SSAOCheck
@onready var glow_check: CheckBox = %GlowCheck
@onready var res_scale_opt: OptionButton = %ResScaleOpt
@onready var mesh_lod_opt: OptionButton = %MeshLODOpt
@onready var texture_quality_opt: OptionButton = %TextureQualityOpt

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

	if graphics_preset_opt:
		graphics_preset_opt.clear()
		graphics_preset_opt.add_item(tr("PRESET_LOW"), 0)
		graphics_preset_opt.add_item(tr("PRESET_MEDIUM"), 1)
		graphics_preset_opt.add_item(tr("PRESET_HIGH"), 2)
		graphics_preset_opt.add_item(tr("PRESET_ULTRA"), 3)
		graphics_preset_opt.add_item(tr("PRESET_CUSTOM"), 4)

	if shadow_opt:
		shadow_opt.clear()
		shadow_opt.add_item(tr("SHADOW_OFF"), 0)
		shadow_opt.add_item(tr("SHADOW_LOW"), 1)
		shadow_opt.add_item(tr("SHADOW_MEDIUM"), 2)
		shadow_opt.add_item(tr("SHADOW_HIGH"), 3)

	if aa_opt:
		aa_opt.clear()
		aa_opt.add_item(tr("AA_OFF"), 0)
		aa_opt.add_item(tr("AA_FXAA"), 1)
		aa_opt.add_item(tr("AA_MSAA_2X"), 2)
		aa_opt.add_item(tr("AA_MSAA_4X"), 3)
		aa_opt.add_item(tr("AA_MSAA_8X"), 4)

	if res_scale_opt:
		res_scale_opt.clear()
		res_scale_opt.add_item(tr("SCALE_PERF"), 0)
		res_scale_opt.add_item(tr("SCALE_BALANCED"), 1)
		res_scale_opt.add_item(tr("SCALE_QUALITY"), 2)
		res_scale_opt.add_item(tr("SCALE_NATIVE"), 3)

	if mesh_lod_opt:
		mesh_lod_opt.clear()
		mesh_lod_opt.add_item(tr("LOD_LOW"), 0)
		mesh_lod_opt.add_item(tr("LOD_MEDIUM"), 1)
		mesh_lod_opt.add_item(tr("LOD_HIGH"), 2)
		mesh_lod_opt.add_item(tr("LOD_ULTRA"), 3)

	if texture_quality_opt:
		texture_quality_opt.clear()
		texture_quality_opt.add_item(tr("TEXQ_LOW"), 0)
		texture_quality_opt.add_item(tr("TEXQ_MEDIUM"), 1)
		texture_quality_opt.add_item(tr("TEXQ_HIGH"), 2)
		texture_quality_opt.add_item(tr("TEXQ_ULTRA"), 3)

func _sync_from_manager() -> void:
	if graphics_preset_opt:
		graphics_preset_opt.selected = SettingsManager.graphics_preset

	if hw_detect_info_label:
		if SettingsManager.has_auto_detected and not SettingsManager.detected_gpu_name.is_empty():
			var p_key: String = SettingsManager.get_preset_key(SettingsManager.graphics_preset)
			hw_detect_info_label.text = tr("HW_DETECTED_INFO") % [SettingsManager.detected_gpu_name, tr(p_key)]
		else:
			hw_detect_info_label.text = ""

	if shadow_opt:
		shadow_opt.selected = SettingsManager.shadow_quality

	if aa_opt:
		aa_opt.selected = SettingsManager.anti_aliasing

	if ssao_check:
		ssao_check.button_pressed = SettingsManager.ssao_enabled

	if glow_check:
		glow_check.button_pressed = SettingsManager.glow_enabled

	if res_scale_opt:
		match snappedf(SettingsManager.resolution_scale, 0.01):
			0.67: res_scale_opt.selected = 0
			0.77: res_scale_opt.selected = 1
			0.85: res_scale_opt.selected = 2
			_: res_scale_opt.selected = 3

	if mesh_lod_opt:
		mesh_lod_opt.selected = SettingsManager.mesh_lod_quality

	if texture_quality_opt:
		texture_quality_opt.selected = SettingsManager.texture_quality

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

	if colorblind_intensity_slider:
		colorblind_intensity_slider.value = SettingsManager.colorblind_intensity * 100.0
		_on_colorblind_intensity_slider_value_changed(colorblind_intensity_slider.value)

	_update_colorblind_intensity_visibility()

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

	if colorblind_intensity_slider and not colorblind_intensity_slider.value_changed.is_connected(_on_colorblind_intensity_slider_value_changed):
		colorblind_intensity_slider.value_changed.connect(_on_colorblind_intensity_slider_value_changed)

	if colorblind_opt and not colorblind_opt.item_selected.is_connected(_on_colorblind_opt_selected):
		colorblind_opt.item_selected.connect(_on_colorblind_opt_selected)

	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
		btn_apply.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
		btn_back.mouse_entered.connect(AudioManager.play_ui_hover)

	if lang_opt and not lang_opt.item_selected.is_connected(_on_language_selected):
		lang_opt.item_selected.connect(_on_language_selected)

	if graphics_preset_opt and not graphics_preset_opt.item_selected.is_connected(_on_preset_selected):
		graphics_preset_opt.item_selected.connect(_on_preset_selected)

	if auto_detect_btn and not auto_detect_btn.pressed.is_connected(_on_auto_detect_pressed):
		auto_detect_btn.pressed.connect(_on_auto_detect_pressed)
		auto_detect_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if shadow_opt and not shadow_opt.item_selected.is_connected(_on_shadow_opt_selected):
		shadow_opt.item_selected.connect(_on_shadow_opt_selected)

	if aa_opt and not aa_opt.item_selected.is_connected(_on_aa_opt_selected):
		aa_opt.item_selected.connect(_on_aa_opt_selected)

	if ssao_check and not ssao_check.toggled.is_connected(_on_ssao_toggled):
		ssao_check.toggled.connect(_on_ssao_toggled)

	if glow_check and not glow_check.toggled.is_connected(_on_glow_toggled):
		glow_check.toggled.connect(_on_glow_toggled)

	if res_scale_opt and not res_scale_opt.item_selected.is_connected(_on_res_scale_opt_selected):
		res_scale_opt.item_selected.connect(_on_res_scale_opt_selected)

	if mesh_lod_opt and not mesh_lod_opt.item_selected.is_connected(_on_mesh_lod_opt_selected):
		mesh_lod_opt.item_selected.connect(_on_mesh_lod_opt_selected)

	if texture_quality_opt and not texture_quality_opt.item_selected.is_connected(_on_texture_quality_opt_selected):
		texture_quality_opt.item_selected.connect(_on_texture_quality_opt_selected)

func _on_preset_selected(index: int) -> void:
	if index >= 0 and index < 4:
		AudioManager.play_ui_click()
		SettingsManager.apply_preset(index)
		_sync_from_manager()

func _on_custom_graphics_changed() -> void:
	if graphics_preset_opt:
		graphics_preset_opt.selected = SettingsManager.GraphicsPreset.CUSTOM
		SettingsManager.graphics_preset = SettingsManager.GraphicsPreset.CUSTOM

func _on_shadow_opt_selected(_idx: int) -> void:
	_on_custom_graphics_changed()

func _on_aa_opt_selected(_idx: int) -> void:
	_on_custom_graphics_changed()

func _on_ssao_toggled(_val: bool) -> void:
	_on_custom_graphics_changed()

func _on_glow_toggled(_val: bool) -> void:
	_on_custom_graphics_changed()

func _on_res_scale_opt_selected(_idx: int) -> void:
	_on_custom_graphics_changed()

func _on_mesh_lod_opt_selected(_idx: int) -> void:
	_on_custom_graphics_changed()

func _on_texture_quality_opt_selected(_idx: int) -> void:
	_on_custom_graphics_changed()

func _on_auto_detect_pressed() -> void:
	AudioManager.play_ui_click()
	var info: Dictionary = SettingsManager.detect_hardware_and_recommend()
	if hw_detect_info_label:
		var p_name: String = tr(info.get("preset_key", "PRESET_HIGH"))
		hw_detect_info_label.text = tr("HW_DETECTED_INFO") % [info.get("gpu_name", "GPU"), p_name]
	_sync_from_manager()

func _on_colorblind_intensity_slider_value_changed(val: float) -> void:
	if colorblind_intensity_val:
		colorblind_intensity_val.text = "%d%%" % int(val)

func _on_colorblind_opt_selected(_idx: int) -> void:
	_update_colorblind_intensity_visibility()

func _update_colorblind_intensity_visibility() -> void:
	if colorblind_intensity_row and colorblind_opt:
		colorblind_intensity_row.visible = (colorblind_opt.selected > 0)

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

	if colorblind_intensity_slider:
		SettingsManager.colorblind_intensity = colorblind_intensity_slider.value / 100.0

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

	# Save graphics settings
	if graphics_preset_opt:
		SettingsManager.graphics_preset = graphics_preset_opt.selected
	if shadow_opt:
		SettingsManager.shadow_quality = shadow_opt.selected
	if aa_opt:
		SettingsManager.anti_aliasing = aa_opt.selected
	if ssao_check:
		SettingsManager.ssao_enabled = ssao_check.button_pressed
	if glow_check:
		SettingsManager.glow_enabled = glow_check.button_pressed
	if res_scale_opt:
		match res_scale_opt.selected:
			0: SettingsManager.resolution_scale = 0.67
			1: SettingsManager.resolution_scale = 0.77
			2: SettingsManager.resolution_scale = 0.85
			3: SettingsManager.resolution_scale = 1.0
	if mesh_lod_opt:
		SettingsManager.mesh_lod_quality = mesh_lod_opt.selected
	if texture_quality_opt:
		SettingsManager.texture_quality = texture_quality_opt.selected

	SettingsManager.save_settings()
	SettingsManager.apply_all()

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	visible = false
	closed.emit()
