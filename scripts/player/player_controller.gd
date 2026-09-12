class_name PlayerController
extends CharacterBody3D

## First-person tactile player controller for The Grand Eggsposition.
## Smooth boutique exploration with mouse look, arrow keys, and gamepad support.

@export var move_speed: float = 4.2
@export var sprint_speed: float = 6.8
@export var mouse_sensitivity: float = 0.003
@export var key_look_speed: float = 2.4
@export var reach_distance: float = 2.8

var camera: Camera3D
var raycast: RayCast3D
var camera_pitch: float = 0.0

func _ready() -> void:
	_setup_camera_and_raycast()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_camera_and_raycast() -> void:
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.position = Vector3(0, 1.65, 0)
		camera.fov = 80.0
		add_child(camera)
		
	camera.current = true
	camera_pitch = camera.rotation.x
	if camera_pitch == 0.0:
		camera_pitch = deg_to_rad(-18.0) # Cozy downward boutique perspective
		camera.rotation.x = camera_pitch

	raycast = camera.get_node_or_null("RayCast3D")
	if not raycast:
		raycast = RayCast3D.new()
		raycast.target_position = Vector3(0, 0, -reach_distance)
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		camera.add_child(raycast)

func _input(event: InputEvent) -> void:
	# Click window to capture cursor
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return

	# Escape key toggles mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	# Mouse look: active when cursor is captured OR when holding right-click
	if event is InputEventMouseMotion:
		var should_rotate: bool = (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED) or (event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0)
		if should_rotate:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(85), deg_to_rad(85))
			if camera:
				camera.rotation.x = camera_pitch

	if event.is_action_pressed("resonance_chime"):
		_trigger_resonance()

	if event.is_action_pressed("interact_primary") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_interaction()

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_keyboard_gamepad_look(delta)
	_update_raycast_hover()

func _handle_movement(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var speed: float = sprint_speed if is_sprinting else move_speed
	
	# Apply swift stride skill speed buffs
	var stride_tier: int = ProgressManager.skill_tiers.get("swift_stride", 0)
	if stride_tier == 1: speed *= 1.15
	elif stride_tier == 2: speed *= 1.30
	elif stride_tier == 3: speed *= 1.45
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# Apply simple gravity if not on floor
	if not is_on_floor():
		velocity.y -= 9.8 * _delta
	else:
		velocity.y = 0.0

	move_and_slide()

## Smooth camera rotation via Arrow keys and Gamepad Right Stick
func _handle_keyboard_gamepad_look(delta: float) -> void:
	var look_input: Vector2 = Vector2.ZERO
	
	# Arrow keys look
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		look_input.x += 1.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		look_input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
		look_input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
		look_input.y += 1.0
		
	# Gamepad right analog stick
	var stick_x: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var stick_y: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(stick_x) > 0.15:
		look_input.x += stick_x
	if absf(stick_y) > 0.15:
		look_input.y += stick_y
		
	if look_input != Vector2.ZERO:
		rotate_y(-look_input.x * key_look_speed * delta)
		camera_pitch = clampf(camera_pitch - look_input.y * key_look_speed * delta, -deg_to_rad(85), deg_to_rad(85))
		if camera:
			camera.rotation.x = camera_pitch

func _update_raycast_hover() -> void:
	if not raycast:
		return
	var hud: HUD = get_tree().root.find_child("HUD", true, false) as HUD
	if not raycast.is_colliding():
		if hud:
			hud.hide_prompt()
		return
	var collider = raycast.get_collider()
	if collider is EggActor:
		var egg: EggActor = collider as EggActor
		var egg_name: String = egg.egg_data.get_display_name() if egg.egg_data else tr("EGG_LAPIS_LAZULI")
		if hud:
			hud.show_prompt(tr("UI_PROMPT_PICK") + " • " + egg_name)
	elif collider.get_parent() is ShowcaseUnit:
		if hud:
			hud.show_prompt(tr("UI_PROMPT_PLACE"))
	else:
		if hud:
			hud.hide_prompt()

func _handle_interaction() -> void:
	if not raycast or not raycast.is_colliding():
		return
	var collider = raycast.get_collider()
	if collider is EggActor:
		collider.pick_up()
	elif collider.get_parent() is ShowcaseUnit:
		var showcase: ShowcaseUnit = collider.get_parent() as ShowcaseUnit
		showcase.try_deposit()

func _trigger_resonance() -> void:
	AudioManager.play_chime(global_position)

