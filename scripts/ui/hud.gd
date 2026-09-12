class_name HUD
extends Control

## Ghost HUD system for The Grand Eggsposition.
## Unobtrusive, high-contrast pills with dynamic smart reticle and i18n support.

@onready var reticle: ColorRect = $Reticle
@onready var prompt_label: Label = $PromptContainer/PromptLabel
@onready var prompt_container: PanelContainer = $PromptContainer
@onready var basket_label: Label = $TopLeft/BasketLabel
@onready var progress_label: Label = $TopRight/ProgressLabel
@onready var seals_label: Label = $TopRight/SealsLabel

func _ready() -> void:
	GameManager.egg_collected.connect(_on_inventory_changed)
	GameManager.egg_placed.connect(_on_egg_placed)
	ProgressManager.wax_seals_changed.connect(_on_seals_changed)
	_update_hud()

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
		progress_label.text = tr("UI_TOTAL_PROGRESS") % [GameManager.total_placed_eggs]
	if seals_label:
		seals_label.text = "%s %d" % [tr("UI_SEALS_LABEL"), ProgressManager.wax_seals]
