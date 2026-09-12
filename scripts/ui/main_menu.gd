class_name MainMenu
extends Control

## Title & Boutique Entry Menu for The Grand Eggsposition.
## Provides tactile access to gameplay, settings, credits, and language options.

@onready var btn_play: Button = %BtnPlay
@onready var btn_settings: Button = %BtnSettings
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit

@onready var settings_menu: Control = %SettingsMenu
@onready var credits_modal: PanelContainer = %CreditsModal
@onready var btn_close_credits: Button = %BtnCloseCredits

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_connect_signals()

func _connect_signals() -> void:
	if btn_play:
		btn_play.pressed.connect(_on_play_pressed)
		btn_play.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
		btn_settings.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_credits:
		btn_credits.pressed.connect(_on_credits_pressed)
		btn_credits.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)
		btn_quit.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_close_credits:
		btn_close_credits.pressed.connect(_on_close_credits_pressed)
		btn_close_credits.mouse_entered.connect(AudioManager.play_ui_hover)

	if settings_menu:
		settings_menu.closed.connect(_on_settings_closed)

func _on_play_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	if settings_menu:
		settings_menu.visible = true

func _on_settings_closed() -> void:
	pass

func _on_credits_pressed() -> void:
	AudioManager.play_ui_click()
	if credits_modal:
		credits_modal.visible = true

func _on_close_credits_pressed() -> void:
	AudioManager.play_ui_click()
	if credits_modal:
		credits_modal.visible = false

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit(0)
