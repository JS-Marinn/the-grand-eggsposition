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

var _fps_timer: float = 0.0

func _ready() -> void:
	GameManager.egg_collected.connect(_on_inventory_changed)
	GameManager.egg_placed.connect(_on_egg_placed)
	ProgressManager.wax_seals_changed.connect(_on_seals_changed)
	ProgressManager.skill_upgraded.connect(_on_skill_upgraded)
	SettingsManager.settings_applied.connect(_on_settings_applied)
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

	skills_label.text = " • ".join(active_tags)

func _on_skill_upgraded(_skill_id: String, _tier: int) -> void:
	_update_hud()

func _on_settings_applied() -> void:
	if fps_label:
		fps_label.visible = SettingsManager.show_fps

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
		basket_label.text = tr("UI_BASKET_CAPACITY") % [GameManager.player_basket.size(), GameManager.max_basket_capacity]
	if progress_label:
		var raw_text: String = tr("UI_TOTAL_PROGRESS")
		if "%s /" in raw_text or "%s/" in raw_text:
			progress_label.text = raw_text % [GameManager.total_placed_eggs]
		else:
			progress_label.text = "%d / %d" % [GameManager.total_placed_eggs, GameManager.TOTAL_EGGS]
	if seals_label:
		seals_label.text = "%s %d" % [tr("UI_SEALS_LABEL"), ProgressManager.wax_seals]
