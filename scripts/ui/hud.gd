class_name HUD
extends Control

## Ghost HUD system for The Grand Eggsposition.
## Unobtrusive, high-contrast pills with dynamic smart reticle and i18n support.

@onready var reticle: ColorRect = $Reticle
@onready var prompt_label: Label = $PromptContainer/PromptLabel
@onready var prompt_container: PanelContainer = $PromptContainer
@onready var basket_label: Label = $TopLeft/VBox/BasketLabel
@onready var fps_label: Label = $TopLeft/VBox/FPSLabel
@onready var skills_label: Label = $TopLeft/VBox/SkillsLabel
@onready var progress_label: Label = $TopRight/ProgressLabel
@onready var seals_label: Label = $TopRight/SealsLabel

@onready var basket_stack: Control = get_node_or_null("BasketStack")
@onready var basket_item_list: VBoxContainer = get_node_or_null("BasketStack/VBox/ItemList")
@onready var capacity_current: Label = get_node_or_null("BasketStack/VBox/CapacityContainer/CapacityCurrent")
@onready var capacity_slash: Label = get_node_or_null("BasketStack/VBox/CapacityContainer/CapacitySlash")
@onready var capacity_max: Label = get_node_or_null("BasketStack/VBox/CapacityContainer/CapacityMax")

@onready var colorblind_filter: ColorRect = get_node_or_null("ColorblindFilter")
@onready var visual_cues_container: PanelContainer = get_node_or_null("VisualCuesContainer")
@onready var visual_cue_label: Label = get_node_or_null("VisualCuesContainer/VisualCueLabel")

var _fps_timer: float = 0.0
var _override_selected_idx: int = -1  ## Set by tests when no Player node is in scene
var _cue_tween: Tween = null

func _ready() -> void:
	GameManager.egg_collected.connect(_on_inventory_changed)
	GameManager.egg_placed.connect(_on_egg_placed)
	ProgressManager.wax_seals_changed.connect(_on_seals_changed)
	ProgressManager.skill_upgraded.connect(_on_skill_upgraded)
	SettingsManager.settings_applied.connect(_on_settings_applied)
	AudioManager.sound_played.connect(_on_sound_played)
	_on_settings_applied()
	_update_hud()

func _process(delta: float) -> void:
	if fps_label and fps_label.visible:
		_fps_timer += delta
		if _fps_timer >= 0.1:
			_fps_timer = 0.0
			fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	_update_skills_overlay()

func _update_skills_overlay() -> void:
	if not skills_label:
		return
	var player = get_tree().root.find_child("Player", true, false)
	if not player:
		skills_label.text = ""
		return

	var active_tags: Array[String] = []
	if ProgressManager.is_skill_unlocked("velvet_dash"):
		if "velvet_dash_cooldown" in player and player.velvet_dash_cooldown > 0.0:
			active_tags.append("Dash: %.1fs" % player.velvet_dash_cooldown)
		else:
			active_tags.append("Dash: [Space x2]")

	if ProgressManager.is_skill_unlocked("resonance_chime"):
		if "resonance_cooldown" in player and player.resonance_cooldown > 0.0:
			active_tags.append("Chime: %.1fs" % player.resonance_cooldown)
		else:
			active_tags.append("Chime: [Q]")

	if ProgressManager.is_skill_unlocked("sweep_suction"):
		active_tags.append("Suction: %.1fm" % ProgressManager.get_sweep_suction_radius())

	if ProgressManager.is_skill_unlocked("cascade_deposit"):
		var tier = ProgressManager.get_skill_tier("cascade_deposit")
		active_tags.append("Cascade R%d" % tier)

	if ProgressManager.is_skill_unlocked("wayfinder"):
		var wayfinder = get_tree().get_first_node_in_group("wayfinder")
		if wayfinder and wayfinder.has_method("is_active") and wayfinder.is_active():
			active_tags.append("Wayfinder: Active [G]")
		else:
			active_tags.append("Wayfinder: [G]")

	skills_label.text = " • ".join(active_tags)

func _on_skill_upgraded(_skill_id: String, _tier: int) -> void:
	_update_hud()

func _on_settings_applied() -> void:
	if fps_label:
		fps_label.visible = SettingsManager.show_fps

	if reticle:
		reticle.visible = SettingsManager.crosshair_dot

	if colorblind_filter:
		if SettingsManager.colorblind_mode > 0:
			colorblind_filter.visible = true
			if colorblind_filter.material is ShaderMaterial:
				colorblind_filter.material.set_shader_parameter("mode", SettingsManager.colorblind_mode)
		else:
			colorblind_filter.visible = false

	_apply_contrast_settings()

func _apply_contrast_settings() -> void:
	var outline_sz: int = 8 if SettingsManager.high_contrast_outlines else 4
	var outline_col: Color = Color(0, 0, 0, 1.0) if SettingsManager.high_contrast_outlines else Color(0, 0, 0, 0.75)
	var labels = [basket_label, fps_label, skills_label, progress_label, seals_label, prompt_label, visual_cue_label]
	for lbl in labels:
		if lbl and is_instance_valid(lbl):
			lbl.add_theme_constant_override("outline_size", outline_sz)
			lbl.add_theme_color_override("font_outline_color", outline_col)

func show_visual_cue(text: String, duration: float = 2.4) -> void:
	if not visual_cues_container or not visual_cue_label:
		return
	if not SettingsManager.visual_sound_cues:
		visual_cues_container.visible = false
		return

	visual_cue_label.text = text
	visual_cues_container.visible = true
	visual_cues_container.modulate.a = 1.0

	if _cue_tween and _cue_tween.is_valid():
		_cue_tween.kill()

	_cue_tween = create_tween()
	_cue_tween.tween_interval(duration * 0.7)
	_cue_tween.tween_property(visual_cues_container, "modulate:a", 0.0, duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_cue_tween.tween_callback(func():
		if visual_cues_container:
			visual_cues_container.visible = false
			visual_cues_container.modulate.a = 1.0
	)

func _on_sound_played(sound_name: String, _pos: Vector3) -> void:
	if not SettingsManager.visual_sound_cues:
		return
	match sound_name:
		"dozen_harp":
			show_visual_cue(tr("CUE_DOZEN_COMPLETED"))
		"wax_stamp":
			show_visual_cue(tr("CUE_WAX_SEAL"))
		"batch_deposit":
			show_visual_cue(tr("CUE_BATCH_DEPOSITED"))


func show_prompt(text: String) -> void:
	if prompt_label and prompt_container:
		prompt_label.text = text
		prompt_container.visible = true

func hide_prompt() -> void:
	if prompt_container:
		prompt_container.visible = false

func _on_inventory_changed(_egg: EggData) -> void:
	_update_hud()

func _on_egg_placed(_egg: EggData, _showcase: int, _dozen: int) -> void:
	_update_hud()

func _on_seals_changed(_new_amount: int) -> void:
	_update_hud()

func _update_hud() -> void:
	if basket_label:
		var basket_text: String = tr("UI_BASKET_CAPACITY") % [GameManager.player_basket.size(), GameManager.max_basket_capacity]
		var player = get_tree().root.find_child("Player", true, false)
		if player and player.has_method("get_current_held_egg") and not GameManager.player_basket.is_empty():
			var held: EggData = player.get_current_held_egg()
			if held:
				basket_text += " • %s (%d/%d)" % [held.get_display_name(), player.selected_held_index + 1, GameManager.player_basket.size()]
		basket_label.text = basket_text
	if progress_label:
		var raw_text: String = tr("UI_TOTAL_PROGRESS")
		if "%s /" in raw_text or "%s/" in raw_text:
			progress_label.text = raw_text % [GameManager.total_placed_eggs]
		else:
			progress_label.text = "%d / %d" % [GameManager.total_placed_eggs, GameManager.TOTAL_EGGS]
	if seals_label:
		seals_label.text = "%s %d" % [tr("UI_SEALS_LABEL"), ProgressManager.wax_seals]
	_update_basket_stack()

func _update_basket_stack() -> void:
	if not basket_stack or not basket_item_list or not capacity_current or not capacity_max:
		return

	const MAX_ROWS: int = 6  # Maximum visible rows at a time

	var basket_size: int = GameManager.player_basket.size()
	var max_cap: int = GameManager.max_basket_capacity

	capacity_current.text = str(basket_size)
	capacity_max.text = str(max_cap)

	if basket_size == 0:
		capacity_current.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
		if capacity_slash:
			capacity_slash.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.45))
		capacity_max.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.45))
	else:
		capacity_current.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		if capacity_slash:
			capacity_slash.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.85))
		capacity_max.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.75))

	# _override_selected_idx takes priority (set by tests or animation code).
	# Falls back to Player node in scene tree, then to 0.
	var selected_idx: int
	if _override_selected_idx >= 0:
		selected_idx = _override_selected_idx
	else:
		var player = get_tree().root.find_child("Player", true, false)
		selected_idx = player.selected_held_index if (player and "selected_held_index" in player) else 0

	# Compute sliding window: clamp so selected_idx stays visible
	var visible_count: int = mini(basket_size, MAX_ROWS)
	var win_start: int = clampi(selected_idx - MAX_ROWS / 2, 0, maxi(0, basket_size - MAX_ROWS))

	# Sync row count to visible_count
	while basket_item_list.get_child_count() > visible_count:
		var last_node = basket_item_list.get_child(basket_item_list.get_child_count() - 1)
		basket_item_list.remove_child(last_node)
		last_node.queue_free()

	var current_children: Array = basket_item_list.get_children()

	# Add missing rows
	while current_children.size() < visible_count:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)

		var name_lbl: Label = Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
		name_lbl.add_theme_constant_override("outline_size", 6)
		row.add_child(name_lbl)

		var chevron_lbl: Label = Label.new()
		chevron_lbl.name = "ChevronLabel"
		chevron_lbl.custom_minimum_size = Vector2(18, 0)
		chevron_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chevron_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chevron_lbl.add_theme_font_size_override("font_size", 16)
		chevron_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
		chevron_lbl.add_theme_constant_override("outline_size", 6)
		row.add_child(chevron_lbl)

		basket_item_list.add_child(row)
		current_children.append(row)

	# Update visible rows with windowed basket slice
	for row_i in range(visible_count):
		var basket_i: int = win_start + row_i
		var row: HBoxContainer = current_children[row_i] as HBoxContainer
		var egg: EggData = GameManager.player_basket[basket_i]
		var is_selected: bool = (basket_i == selected_idx)

		var name_lbl: Label = row.get_node_or_null("NameLabel") as Label
		var chevron_lbl: Label = row.get_node_or_null("ChevronLabel") as Label

		if name_lbl and egg:
			name_lbl.text = egg.get_display_name()
			if is_selected:
				name_lbl.add_theme_font_size_override("font_size", 15)
				name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			else:
				name_lbl.add_theme_font_size_override("font_size", 13)
				name_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92, 0.38))

		if chevron_lbl:
			if is_selected:
				chevron_lbl.text = ">"
				chevron_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
			else:
				chevron_lbl.text = ""



