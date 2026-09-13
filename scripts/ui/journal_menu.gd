class_name JournalMenu
extends Control

## Tactile leather-bound Curator's Journal for The Grand Eggsposition.
## Accessed via [TAB] to inspect the 30-showcase collection, stamp wax seals for
## skill upgrades, and track Barnaby's 144 mini-egg secrets.

signal closed()

@onready var close_btn: Button = %CloseBtn
@onready var tab_btn_catalog: Button = %TabBtnCatalog
@onready var tab_btn_skills: Button = %TabBtnSkills
@onready var tab_btn_secrets: Button = %TabBtnSecrets

@onready var panel_catalog: Control = %PanelCatalog
@onready var panel_skills: Control = %PanelSkills
@onready var panel_secrets: Control = %PanelSecrets

@onready var showcase_opt: OptionButton = %ShowcaseOpt
@onready var showcase_progress_label: Label = %ShowcaseProgressLabel
@onready var tiers_container: VBoxContainer = %TiersContainer

@onready var seals_balance_label: Label = %SealsBalanceLabel
@onready var skills_grid: GridContainer = %SkillsGrid

@onready var mini_eggs_label: Label = %MiniEggsLabel
@onready var luxury_eggs_label: Label = %LuxuryEggsLabel

var current_tab: int = 0 # 0: Catalog, 1: Skills, 2: Secrets
var selected_showcase_id: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_connect_signals()
	_populate_showcase_selector()

func _connect_signals() -> void:
	if close_btn:
		close_btn.pressed.connect(close_journal)
		close_btn.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_catalog:
		tab_btn_catalog.pressed.connect(func(): _switch_tab(0))
		tab_btn_catalog.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_skills:
		tab_btn_skills.pressed.connect(func(): _switch_tab(1))
		tab_btn_skills.mouse_entered.connect(AudioManager.play_ui_hover)

	if tab_btn_secrets:
		tab_btn_secrets.pressed.connect(func(): _switch_tab(2))
		tab_btn_secrets.mouse_entered.connect(AudioManager.play_ui_hover)

	if showcase_opt:
		showcase_opt.item_selected.connect(_on_showcase_selected)
		showcase_opt.mouse_entered.connect(AudioManager.play_ui_hover)

	ProgressManager.wax_seals_changed.connect(func(_val): _refresh_skills_tab())
	ProgressManager.skill_upgraded.connect(func(_skill, _tier): _refresh_skills_tab())
	GameManager.egg_placed.connect(func(_egg, _s, _d): _refresh_catalog_tab())

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

func _switch_tab(tab_idx: int, play_sound: bool = true) -> void:
	current_tab = tab_idx
	if play_sound:
		AudioManager.play_page_turn()

	if panel_catalog: panel_catalog.visible = (tab_idx == 0)
	if panel_skills: panel_skills.visible = (tab_idx == 1)
	if panel_secrets: panel_secrets.visible = (tab_idx == 2)

	if tab_btn_catalog: tab_btn_catalog.modulate = Color.WHITE if tab_idx == 0 else Color(0.8, 0.8, 0.8)
	if tab_btn_skills: tab_btn_skills.modulate = Color.WHITE if tab_idx == 1 else Color(0.8, 0.8, 0.8)
	if tab_btn_secrets: tab_btn_secrets.modulate = Color.WHITE if tab_idx == 2 else Color(0.8, 0.8, 0.8)

	match tab_idx:
		0: _refresh_catalog_tab()
		1: _refresh_skills_tab()
		2: _refresh_secrets_tab()

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

		row.add_child(hbox)
		tiers_container.add_child(row)

	if showcase_progress_label:
		showcase_progress_label.text = "Progreso de Vitrina: %d / 60 Huevos" % total_in_showcase

## --- 2. Curator's Mastery Skills Tree Rendering ---
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
