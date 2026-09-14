class_name FinalSpaceRotunda
extends Node3D

## Controller for the Final Space Mockup (Rotonda Victoriana de Dos Niveles).
## Features multiple cinematic presentation cameras matching the reference concept,
## first-person exploration of ground and mezzanine floors, and interactive camera switching.

@onready var player: CharacterBody3D = get_node_or_null("Player")
@onready var cam_hero: Camera3D = get_node_or_null("PresentationCameras/CameraHeroView")
@onready var cam_mezzanine: Camera3D = get_node_or_null("PresentationCameras/CameraMezzanine")
@onready var cam_dome: Camera3D = get_node_or_null("PresentationCameras/CameraDomeSkylight")
@onready var help_label: Label = get_node_or_null("HUD/Margin/HelpLabel")

var current_camera_idx: int = 0 # 0: Player, 1: Hero View (Concept), 2: Mezzanine, 3: Dome

const CAMERA_NAMES: Array[String] = [
	"1. Primera Persona (Explorar)",
	"2. Vista Principal (Concept Art)",
	"3. Balcon Mezzanine (Vista Alta)",
	"4. Cupula Solar y Claraboya"
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_camera(0)
	_update_help_text()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: set_camera(0)
			KEY_2: set_camera(1)
			KEY_3: set_camera(2)
			KEY_4: set_camera(3)
			KEY_C: set_camera((current_camera_idx + 1) % 4)

func set_camera(idx: int) -> void:
	current_camera_idx = posmod(idx, 4)
	var player_cam: Camera3D = null
	if player:
		player_cam = player.find_child("Camera3D", true, false) as Camera3D

	if player_cam: player_cam.current = false
	if cam_hero: cam_hero.current = false
	if cam_mezzanine: cam_mezzanine.current = false
	if cam_dome: cam_dome.current = false

	match current_camera_idx:
		0:
			if player_cam: player_cam.current = true
			if player: player.set_physics_process(true)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		1:
			if cam_hero: cam_hero.current = true
			if player: player.set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		2:
			if cam_mezzanine: cam_mezzanine.current = true
			if player: player.set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		3:
			if cam_dome: cam_dome.current = true
			if player: player.set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_update_help_text()

func _update_help_text() -> void:
	if help_label:
		help_label.text = "[WASD] Moverse  |  [Espacio] Saltar  |  [1-4 / C] Camara: %s" % CAMERA_NAMES[current_camera_idx]
