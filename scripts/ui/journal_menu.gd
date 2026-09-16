class_name JournalMenu
extends Control

## Tactile leather-bound Curator's Journal for The Grand Eggsposition.
## Accessed via [TAB] to inspect the 30-showcase collection, stamp wax seals for
## skill upgrades, and track Barnaby's 144 mini-egg secrets.

signal closed()

@onready var close_btn: Button = %CloseBtn
@onready var tab_btn_catalog: Button = %TabBtnCatalog
@onready var tab_btn_compendium: Button = %TabBtnCompendium
@onready var tab_btn_skills: Button = %TabBtnSkills
@onready var tab_btn_secrets: Button = %TabBtnSecrets

@onready var panel_catalog: Control = %PanelCatalog
@onready var panel_compendium: Control = %PanelCompendium
@onready var panel_skills: Control = %PanelSkills
@onready var panel_secrets: Control = %PanelSecrets

@onready var showcase_opt: OptionButton = %ShowcaseOpt
@onready var showcase_progress_label: Label = %ShowcaseProgressLabel
@onready var tiers_container: VBoxContainer = %TiersContainer

# Compendium UI references
@onready var compendium_count_label: Label = %CompendiumCountLabel
@onready var compendium_filter_opt: OptionButton = %CompendiumFilterOpt
@onready var compendium_egg_list: VBoxContainer = %CompendiumEggList

@onready var compendium_egg_title: Label = %CompendiumEggTitle
@onready var compendium_rarity_badge: PanelContainer = %CompendiumRarityBadge
@onready var compendium_rarity_label: Label = %CompendiumRarityLabel
@onready var compendium_series_label: Label = %CompendiumSeriesLabel
@onready var compendium_prev_btn: Button = %CompendiumPrevBtn
@onready var compendium_next_btn: Button = %CompendiumNextBtn

@onready var compendium_viewport_container: SubViewportContainer = %CompendiumViewportContainer
@onready var compendium_sub_viewport: SubViewport = %CompendiumSubViewport
@onready var compendium_camera: Camera3D = %CompendiumCamera
@onready var compendium_egg_pivot: Node3D = %CompendiumEggPivot
@onready var compendium_reset_btn: Button = %CompendiumResetBtn
@onready var compendium_hint_label: Label = %CompendiumHintLabel

@onready var compendium_lore_label: Label = %CompendiumLoreLabel
@onready var compendium_notes_label: Label = %CompendiumNotesLabel
@onready var compendium_location_label: Label = %CompendiumLocationLabel

@onready var seals_balance_label: Label = %SealsBalanceLabel
@onready var skills_grid: GridContainer = %SkillsGrid

@onready var mini_eggs_label: Label = %MiniEggsLabel
@onready var luxury_eggs_label: Label = %LuxuryEggsLabel

var current_tab: int = 0 # 0: Catalog, 1: Compendium, 2: Skills, 3: Secrets
var selected_showcase_id: int = 1
var selected_egg_id: int = 1
var selected_series_filter: int = -1 # -1: All series

# 3D interactive inspection variables
var _is_dragging_3d: bool = false
var _drag_last_pos: Vector2 = Vector2.ZERO
var _egg_pitch: float = 0.0
var _egg_yaw: float = 0.0
var _target_egg_pitch: float = 0.0
var _target_egg_yaw: float = 0.0
var _camera_default_fov: float = 38.0
var _target_camera_fov: float = 38.0

const BASE_EGG_MESH_COMPENDIUM: Mesh = preload("res://assets/models/baseegg_mesh_compendium.tres")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if compendium_sub_viewport:
		compendium_sub_viewport.msaa_3d = SubViewport.MSAA_8X
		compendium_sub_viewport.screen_space_aa = SubViewport.SCREEN_SPACE_AA_FXAA
		compendium_sub_viewport.scaling_3d_mode = SubViewport.SCALING_3D_MODE_BILINEAR
	_connect_signals()
	_populate_showcase_selector()
	_populate_compendium_filters()

func _process(delta: float) -> void:
	if not visible or current_tab != 1:
		return

	# Idle auto-rotation when user is not actively dragging
	if not _is_dragging_3d:
		_target_egg_yaw += 0.35 * delta

	# Smooth lerp towards target rotation
	_egg_pitch = lerpf(_egg_pitch, _target_egg_pitch, 14.0 * delta)
	_egg_yaw = lerpf(_egg_yaw, _target_egg_yaw, 14.0 * delta)

	if compendium_egg_pivot and is_instance_valid(compendium_egg_pivot):
		compendium_egg_pivot.rotation = Vector3(_egg_pitch, _egg_yaw, 0.0)

	if compendium_camera and is_instance_valid(compendium_camera):
		compendium_camera.fov = lerpf(compendium_camera.fov, _target_camera_fov, 10.0 * delta)

func _connect_signals() -> void:
	if close_btn:
		close_btn.pressed.connect(close_journal)
		close_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_catalog:
		tab_btn_catalog.pressed.connect(func(): _switch_tab(0))
		tab_btn_catalog.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_compendium:
		tab_btn_compendium.pressed.connect(func(): _switch_tab(1))
		tab_btn_compendium.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_skills:
		tab_btn_skills.pressed.connect(func(): _switch_tab(2))
		tab_btn_skills.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_secrets:
		tab_btn_secrets.pressed.connect(func(): _switch_tab(3))
		tab_btn_secrets.mouse_entered.connect(AudioManager.play_ui_hover)

	if showcase_opt:
		showcase_opt.item_selected.connect(_on_showcase_selected)
		showcase_opt.mouse_entered.connect(AudioManager.play_ui_hover)

	# Compendium interaction signals
	if compendium_viewport_container:
		compendium_viewport_container.gui_input.connect(_on_viewport_gui_input)

	if compendium_reset_btn:
		compendium_reset_btn.pressed.connect(_reset_3d_view)
		compendium_reset_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if compendium_prev_btn:
		compendium_prev_btn.pressed.connect(_on_compendium_prev)
		compendium_prev_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if compendium_next_btn:
		compendium_next_btn.pressed.connect(_on_compendium_next)
		compendium_next_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if compendium_filter_opt:
		compendium_filter_opt.item_selected.connect(_on_compendium_filter_selected)
		compendium_filter_opt.mouse_entered.connect(AudioManager.play_ui_hover)

	ProgressManager.wax_seals_changed.connect(func(_val): _refresh_skills_tab())
	ProgressManager.skill_upgraded.connect(func(_skill, _tier): _refresh_skills_tab())
	GameManager.egg_placed.connect(func(_egg, _s, _d): _refresh_catalog_tab())
	GameManager.egg_discovered.connect(func(_egg):
		if visible and current_tab == 1:
			_refresh_compendium_tab()
	)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_journal") or event.is_action_pressed("ui_cancel"):
		close_journal()
		get_viewport().set_input_as_handled()

func open_journal() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_page_turn()
	_switch_tab(current_tab, false)

func close_journal() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.play_page_turn()
	closed.emit()

func toggle_journal() -> void:
	if visible:
		close_journal()
	else:
		open_journal()

func open_compendium_egg(egg_id: int) -> void:
	selected_egg_id = egg_id
	open_journal()
	_switch_tab(1, false)
	_display_selected_egg()

func _switch_tab(tab_idx: int, play_sound: bool = true) -> void:
	current_tab = tab_idx
	if play_sound:
		AudioManager.play_page_turn()

	if panel_catalog: panel_catalog.visible = (tab_idx == 0)
	if panel_compendium: panel_compendium.visible = (tab_idx == 1)
	if panel_skills: panel_skills.visible = (tab_idx == 2)
	if panel_secrets: panel_secrets.visible = (tab_idx == 3)

	if tab_btn_catalog: tab_btn_catalog.modulate = Color.WHITE if tab_idx == 0 else Color(0.8, 0.8, 0.8)
	if tab_btn_compendium: tab_btn_compendium.modulate = Color.WHITE if tab_idx == 1 else Color(0.8, 0.8, 0.8)
	if tab_btn_skills: tab_btn_skills.modulate = Color.WHITE if tab_idx == 2 else Color(0.8, 0.8, 0.8)
	if tab_btn_secrets: tab_btn_secrets.modulate = Color.WHITE if tab_idx == 3 else Color(0.8, 0.8, 0.8)

	match tab_idx:
		0: _refresh_catalog_tab()
		1: _refresh_compendium_tab()
		2: _refresh_skills_tab()
		3: _refresh_secrets_tab()

func _populate_showcase_selector() -> void:
	if not showcase_opt:
		return
	showcase_opt.clear()
	for s_id in range(1, GameManager.TOTAL_SHOWCASES + 1):
		var title: String = GameManager.get_showcase_title(s_id)
		showcase_opt.add_item("%02d. %s" % [s_id, title], s_id)
	showcase_opt.selected = 0
	selected_showcase_id = 1

func _on_showcase_selected(index: int) -> void:
	selected_showcase_id = showcase_opt.get_item_id(index)
	AudioManager.play_ui_click()
	_refresh_catalog_tab()

## --- 1. Collection Catalog Rendering ---
func _refresh_catalog_tab() -> void:
	if not tiers_container:
		return

	for child in tiers_container.get_children():
		child.queue_free()

	var s_state: Dictionary = GameManager.showcase_state.get(selected_showcase_id, {})
	var total_in_showcase: int = 0

	for d in range(1, GameManager.DOZENS_PER_SHOWCASE + 1):
		var count: int = s_state.get(d, 0)
		total_in_showcase += count
		var egg_info: EggData = GameManager.get_egg_for_showcase_dozen(selected_showcase_id, d)
		var egg_name: String = egg_info.get_display_name() if egg_info else ("Tier %d Unknown Egg" % d)
		var egg_col: Color = egg_info.albedo_color if egg_info else Color(0.3, 0.3, 0.3)

		var row: PanelContainer = PanelContainer.new()
		var row_style: StyleBoxFlat = StyleBoxFlat.new()
		row_style.bg_color = Color(0.92, 0.89, 0.82, 0.9) if (count == 12) else Color(0.95, 0.93, 0.88, 0.8)
		row_style.border_width_left = 3
		row_style.border_color = Color(0.85, 0.70, 0.25) if (count == 12) else Color(0.6, 0.5, 0.4, 0.5)
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_right = 6
		row_style.corner_radius_bottom_left = 6
		row.add_theme_stylebox_override("panel", row_style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)

		# Egg color preview dot
		var color_rect: ColorRect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(24, 24)
		color_rect.color = egg_col
		hbox.add_child(color_rect)

		# Egg name label
		var name_label: Label = Label.new()
		name_label.text = "Balda %d: %s" % [d, egg_name]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
		name_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(name_label)

		# Progress counter
		var count_label: Label = Label.new()
		count_label.text = "%d / 12" % count
		count_label.custom_minimum_size = Vector2(70, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.add_theme_color_override("font_color", Color(0.70, 0.50, 0.10) if (count == 12) else Color(0.35, 0.30, 0.25))
		count_label.add_theme_font_size_override("font_size", 15)
		hbox.add_child(count_label)

		# Completed Wax Seal Stamp badge
		if count >= 12:
			var seal_badge: Label = Label.new()
			seal_badge.text = "★ COMPLETA"
			seal_badge.add_theme_color_override("font_color", Color(0.80, 0.20, 0.15))
			seal_badge.add_theme_font_size_override("font_size", 13)
			hbox.add_child(seal_badge)

		# Inspect 3D button
		if egg_info:
			var inspect_btn: Button = Button.new()
			inspect_btn.text = "🔍 3D"
			inspect_btn.custom_minimum_size = Vector2(50, 24)
			inspect_btn.add_theme_font_size_override("font_size", 11)
			inspect_btn.mouse_entered.connect(AudioManager.play_ui_hover)
			var target_egg_id: int = egg_info.egg_id
			inspect_btn.pressed.connect(func():
				open_compendium_egg(target_egg_id)
			)
			hbox.add_child(inspect_btn)

		row.add_child(hbox)
		tiers_container.add_child(row)

	if showcase_progress_label:
		showcase_progress_label.text = "Progreso de Vitrina: %d / 60 Huevos" % total_in_showcase

## --- 2. Curator's 3D Compendium Rendering ---
func _populate_compendium_filters() -> void:
	if not compendium_filter_opt:
		return
	compendium_filter_opt.clear()
	compendium_filter_opt.add_item(tr("UI_COMPENDIUM_FILTER_ALL") % GameManager.egg_database.size(), -1)
	compendium_filter_opt.add_item(tr("SERIES_MINERALS"), EggData.EggSeries.MINERALS_GEMS)
	compendium_filter_opt.add_item(tr("SERIES_JOBS"), EggData.EggSeries.JOBS_SOCIETY)
	compendium_filter_opt.add_item(tr("SERIES_POP_CULTURE"), EggData.EggSeries.POP_CULTURE)
	compendium_filter_opt.add_item(tr("SERIES_FANTASY"), EggData.EggSeries.FANTASY_MYTH)
	compendium_filter_opt.add_item(tr("SERIES_DELICATESSEN"), EggData.EggSeries.DELICATESSEN)
	compendium_filter_opt.add_item(tr("SERIES_WILDLIFE"), EggData.EggSeries.WILDLIFE_COSMOS)
	compendium_filter_opt.selected = 0
	selected_series_filter = -1

func _on_compendium_filter_selected(index: int) -> void:
	selected_series_filter = compendium_filter_opt.get_item_id(index)
	AudioManager.play_ui_click()
	_refresh_compendium_tab()

func _refresh_compendium_tab() -> void:
	if not compendium_egg_list:
		return

	if compendium_count_label:
		compendium_count_label.text = tr("UI_COMPENDIUM_DISCOVERED") % [GameManager.get_discovered_count(), GameManager.egg_database.size()]

	for child in compendium_egg_list.get_children():
		child.queue_free()

	var egg_ids: Array = GameManager.egg_database.keys()
	egg_ids.sort()

	# Ensure selected_egg_id is valid
	if not GameManager.egg_database.has(selected_egg_id):
		selected_egg_id = egg_ids[0] if not egg_ids.is_empty() else 1

	for id: int in egg_ids:
		var egg: EggData = GameManager.get_egg_data(id)
		if not egg:
			continue

		# Filter check
		if selected_series_filter >= 0 and egg.series != selected_series_filter:
			continue

		var is_discovered: bool = GameManager.is_egg_discovered(id)
		var is_selected: bool = (id == selected_egg_id)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.corner_radius_bottom_left = 6
		if is_selected:
			btn_style.bg_color = Color(0.85, 0.78, 0.65, 0.95)
			btn_style.border_width_left = 3
			btn_style.border_color = Color(0.75, 0.55, 0.20)
		else:
			btn_style.bg_color = Color(0.94, 0.91, 0.85, 0.8) if is_discovered else Color(0.88, 0.86, 0.82, 0.6)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Color dot or locked icon
		var dot: ColorRect = ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = egg.albedo_color if is_discovered else Color(0.35, 0.35, 0.35)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(dot)

		# Title
		var title_lbl: Label = Label.new()
		title_lbl.text = egg.get_display_name() if is_discovered else ("??? (" + tr("UI_SHOWCASE_NUM") + " %d)" % egg.showcase_id)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 12)
		title_lbl.add_theme_color_override("font_color", Color(0.20, 0.15, 0.10) if is_discovered else Color(0.50, 0.45, 0.40))
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(title_lbl)

		# Rarity pill
		var rarity_lbl: Label = Label.new()
		rarity_lbl.text = egg.get_rarity_name() if is_discovered else "?"
		rarity_lbl.add_theme_font_size_override("font_size", 10)
		rarity_lbl.add_theme_color_override("font_color", egg.get_rarity_color() if is_discovered else Color(0.6, 0.6, 0.6))
		rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(rarity_lbl)

		btn.add_child(hbox)

		btn.pressed.connect(func():
			selected_egg_id = id
			AudioManager.play_ui_click()
			_refresh_compendium_tab()
		)
		btn.mouse_entered.connect(AudioManager.play_ui_hover)
		compendium_egg_list.add_child(btn)

	_display_selected_egg()

func _display_selected_egg() -> void:
	var egg: EggData = GameManager.get_egg_data(selected_egg_id)
	if not egg:
		return

	var is_discovered: bool = GameManager.is_egg_discovered(selected_egg_id)

	# Update 3D visual turntable
	if compendium_egg_pivot:
		for child in compendium_egg_pivot.get_children():
			compendium_egg_pivot.remove_child(child)
			child.queue_free()

		if is_discovered:
			var visual_node: Node3D = _instantiate_compendium_visual(egg)
			compendium_egg_pivot.add_child(visual_node)
		else:
			var sil_node: Node3D = Node3D.new()
			var silhouette: MeshInstance3D = MeshInstance3D.new()
			silhouette.mesh = BASE_EGG_MESH_COMPENDIUM
			var sil_mat: StandardMaterial3D = StandardMaterial3D.new()
			sil_mat.albedo_color = Color(0.08, 0.08, 0.08)
			sil_mat.roughness = 0.95
			sil_mat.metallic = 0.0
			silhouette.material_override = sil_mat
			sil_node.add_child(silhouette)
			compendium_egg_pivot.add_child(sil_node)

	# Update text elements
	if compendium_egg_title:
		compendium_egg_title.text = egg.get_display_name() if is_discovered else tr("UI_COMPENDIUM_LOCKED_TITLE")

	if compendium_rarity_label:
		if is_discovered:
			compendium_rarity_label.text = "★ " + egg.get_rarity_name().to_upper()
			compendium_rarity_label.add_theme_color_override("font_color", egg.get_rarity_color())
		else:
			compendium_rarity_label.text = "? ? ?"
			compendium_rarity_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	if compendium_series_label:
		if is_discovered:
			compendium_series_label.text = GameManager.get_showcase_title(egg.showcase_id)
		else:
			compendium_series_label.text = "%s %d" % [tr("UI_SHOWCASE_NUM"), egg.showcase_id]

	if compendium_lore_label:
		compendium_lore_label.text = egg.get_lore() if is_discovered else tr("UI_COMPENDIUM_LOCKED_LORE")

	if compendium_notes_label:
		if is_discovered:
			compendium_notes_label.text = egg.get_curator_notes()
		else:
			compendium_notes_label.text = tr("UI_COMPENDIUM_LOCKED_NOTES")

	if compendium_location_label:
		var placed_count: int = GameManager.showcase_state.get(egg.showcase_id, {}).get(egg.dozen_group, 0)
		var showcase_title: String = GameManager.get_showcase_title(egg.showcase_id)
		compendium_location_label.text = tr("UI_COMPENDIUM_LOCATION_VAL") % [egg.showcase_id, showcase_title, egg.dozen_group, placed_count]

func _instantiate_compendium_visual(egg: EggData) -> Node3D:
	if egg.custom_scene:
		var scene_instance = egg.custom_scene.instantiate()
		if scene_instance is Node3D:
			return scene_instance as Node3D

	var node: Node3D = Node3D.new()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = egg.custom_mesh if egg.custom_mesh else BASE_EGG_MESH_COMPENDIUM
	mi.material_override = egg.create_material()
	node.add_child(mi)
	return node


func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging_3d = event.pressed
			if event.pressed:
				_drag_last_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target_camera_fov = clampf(_target_camera_fov - 3.0, 20.0, 50.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target_camera_fov = clampf(_target_camera_fov + 3.0, 20.0, 50.0)
	elif event is InputEventMouseMotion and _is_dragging_3d:
		var delta_pos: Vector2 = event.position - _drag_last_pos
		_drag_last_pos = event.position
		_target_egg_yaw += delta_pos.x * 0.012
		_target_egg_pitch = clampf(_target_egg_pitch + delta_pos.y * 0.012, -deg_to_rad(65), deg_to_rad(65))

func _reset_3d_view() -> void:
	_target_egg_pitch = 0.0
	_target_egg_yaw = 0.0
	_target_camera_fov = _camera_default_fov
	AudioManager.play_ui_click()

func _on_compendium_prev() -> void:
	var keys: Array = GameManager.egg_database.keys()
	keys.sort()
	var idx: int = keys.find(selected_egg_id)
	if idx > 0:
		selected_egg_id = keys[idx - 1]
	else:
		selected_egg_id = keys[keys.size() - 1]
	AudioManager.play_ui_click()
	_refresh_compendium_tab()

func _on_compendium_next() -> void:
	var keys: Array = GameManager.egg_database.keys()
	keys.sort()
	var idx: int = keys.find(selected_egg_id)
	if idx >= 0 and idx < keys.size() - 1:
		selected_egg_id = keys[idx + 1]
	else:
		selected_egg_id = keys[0]
	AudioManager.play_ui_click()
	_refresh_compendium_tab()

## --- 3. Curator's Mastery Skills Tree Rendering ---
func _refresh_skills_tab() -> void:
	if seals_balance_label:
		seals_balance_label.text = "Sellos de Cera Disponibles: %d" % ProgressManager.wax_seals

	if not skills_grid:
		return

	for child in skills_grid.get_children():
		child.queue_free()

	var skills_info = [
		{"id": "basket_mastery", "name": tr("SKILL_BASKET_MASTERY_NAME"), "desc": tr("SKILL_BASKET_MASTERY_DESC"), "max": 4},
		{"id": "sweep_suction", "name": tr("SKILL_SWEEP_SUCTION_NAME"), "desc": tr("SKILL_SWEEP_SUCTION_DESC"), "max": 2},
		{"id": "swift_stride", "name": tr("SKILL_SWIFT_STRIDE_NAME"), "desc": tr("SKILL_SWIFT_STRIDE_DESC"), "max": 3},
		{"id": "velvet_dash", "name": tr("SKILL_VELVET_DASH_NAME"), "desc": tr("SKILL_VELVET_DASH_DESC"), "max": 2},
		{"id": "resonance_chime", "name": tr("SKILL_RESONANCE_CHIME_NAME"), "desc": tr("SKILL_RESONANCE_CHIME_DESC"), "max": 3},
		{"id": "wayfinder", "name": tr("SKILL_WAYFINDER_NAME"), "desc": tr("SKILL_WAYFINDER_DESC"), "max": 2},
		{"id": "cascade_deposit", "name": tr("SKILL_CASCADE_DEPOSIT_NAME"), "desc": tr("SKILL_CASCADE_DEPOSIT_DESC"), "max": 2},
		{"id": "egg_toss", "name": tr("SKILL_EGG_TOSS_NAME"), "desc": tr("SKILL_EGG_TOSS_DESC"), "max": 2}
	]

	for s in skills_info:
		var skill_id: String = s["id"]
		var current_tier: int = ProgressManager.get_skill_tier(skill_id)
		var max_tier: int = s["max"]

		var card: PanelContainer = PanelContainer.new()
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.bg_color = Color(0.96, 0.94, 0.89, 0.95)
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.78, 0.68, 0.52)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", card_style)
		card.custom_minimum_size = Vector2(440, 110)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		var header_box: HBoxContainer = HBoxContainer.new()
		var title_label: Label = Label.new()
		title_label.text = s["name"]
		title_label.add_theme_color_override("font_color", Color(0.24, 0.16, 0.08))
		title_label.add_theme_font_size_override("font_size", 15)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_box.add_child(title_label)

		var tier_badge: Label = Label.new()
		tier_badge.text = "Rango %d / %d" % [current_tier, max_tier]
		tier_badge.add_theme_color_override("font_color", Color(0.55, 0.35, 0.15))
		tier_badge.add_theme_font_size_override("font_size", 13)
		header_box.add_child(tier_badge)
		vbox.add_child(header_box)

		var desc_label: Label = Label.new()
		desc_label.text = s["desc"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_color_override("font_color", Color(0.40, 0.35, 0.30))
		desc_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(desc_label)

		var action_box: HBoxContainer = HBoxContainer.new()
		action_box.alignment = BoxContainer.ALIGNMENT_END

		if current_tier >= max_tier:
			var max_label: Label = Label.new()
			max_label.text = "★ ¡MAESTRÍA MÁXIMA!"
			max_label.add_theme_color_override("font_color", Color(0.80, 0.60, 0.10))
			max_label.add_theme_font_size_override("font_size", 13)
			action_box.add_child(max_label)
		else:
			var cost_array: Array = ProgressManager.SKILL_COSTS.get(skill_id, [])
			var next_cost: int = cost_array[current_tier] if current_tier < cost_array.size() else 999

			var stamp_btn: Button = Button.new()
			stamp_btn.text = "Estampar Lacre (-%d Sellos)" % next_cost
			stamp_btn.disabled = (ProgressManager.wax_seals < next_cost)
			stamp_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.90))
			stamp_btn.add_theme_font_size_override("font_size", 12)

			var btn_style: StyleBoxFlat = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.75, 0.18, 0.18) if not stamp_btn.disabled else Color(0.55, 0.45, 0.45)
			btn_style.corner_radius_top_left = 6
			btn_style.corner_radius_top_right = 6
			btn_style.corner_radius_bottom_right = 6
			btn_style.corner_radius_bottom_left = 6
			stamp_btn.add_theme_stylebox_override("normal", btn_style)
			stamp_btn.mouse_entered.connect(AudioManager.play_ui_hover)

			stamp_btn.pressed.connect(func():
				if ProgressManager.upgrade_skill(skill_id):
					AudioManager.play_wax_stamp()
			)
			action_box.add_child(stamp_btn)

		vbox.add_child(action_box)
		card.add_child(vbox)
		skills_grid.add_child(card)

## --- 3. Barnaby's Secrets Rendering ---
func _refresh_secrets_tab() -> void:
	if mini_eggs_label:
		mini_eggs_label.text = "Huevitos Blancos Ocultos de Barnaby: 0 / 144"
	if luxury_eggs_label:
		luxury_eggs_label.text = "Huevos de Lujo en Vitrina Central: 0 / 12"
