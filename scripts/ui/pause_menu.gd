class_name PauseMenu
extends Control

## In-Game Frosted Pause Menu for The Grand Eggsposition.
## Pauses tree execution, releases mouse capture, and embeds settings.

@onready var btn_resume: Button = %BtnResume
@onready var btn_settings: Button = %BtnSettings
@onready var btn_main_menu: Button = %BtnMainMenu
@onready var btn_quit: Button = %BtnQuit
@onready var settings_menu: Control = %SettingsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_connect_signals()

func _connect_signals() -> void:
	if btn_resume:
		btn_resume.pressed.connect(resume_game)
		btn_resume.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_settings:
		btn_settings.pressed.connect(_on_settings_pressed)
		btn_settings.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
		btn_main_menu.mouse_entered.connect(AudioManager.play_ui_hover)

	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)
		btn_quit.mouse_entered.connect(AudioManager.play_ui_hover)

	if settings_menu:
		settings_menu.closed.connect(_on_settings_closed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			if settings_menu and settings_menu.visible:
				settings_menu.visible = false
				_on_settings_closed()
			else:
				resume_game()
			get_viewport().set_input_as_handled()
		else:
			# Not currently paused, pause!
			pause_game()
			get_viewport().set_input_as_handled()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_ui_click()

func resume_game() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.play_ui_click()

func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	if settings_menu:
		settings_menu.visible = true

func _on_settings_closed() -> void:
	pass

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit(0)
