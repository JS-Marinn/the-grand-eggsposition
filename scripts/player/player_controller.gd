class_name PlayerController
extends CharacterBody3D

## First-person tactile player controller for The Grand Eggsposition.
## Smooth boutique exploration with mouse look, arrow keys, and gamepad support.

@export var move_speed: float = 4.2
@export var sprint_speed: float = 6.8
@export var mouse_sensitivity: float = 0.003
@export var key_look_speed: float = 2.4
@export var reach_distance: float = 4.5

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
		camera.position = Vector3(0, 1.70, 0)
		var sm = get_node_or_null("/root/SettingsManager")
		camera.fov = sm.fov if (sm and "fov" in sm) else 75.0
		add_child(camera)
		
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and "fov" in sm:
		camera.fov = sm.fov
	camera.current = true
	camera_pitch = camera.rotation.x

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

	# Escape key: let PauseMenu handle it if present; fallback to mouse toggle if standalone
	if event.is_action_pressed("ui_cancel"):
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		if pause_menu:
			return # PauseMenu processes ui_cancel
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
			var sens: float = _get_sensitivity()
			rotate_y(-event.relative.x * sens)
			camera_pitch = clampf(camera_pitch - event.relative.y * sens, -deg_to_rad(85), deg_to_rad(85))
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

	var collider: Object = raycast.get_collider()
	if not collider or not is_instance_valid(collider):
		if hud:
			hud.hide_prompt()
		return

	var egg: EggActor = _resolve_egg(collider)
	if egg:
		var egg_name: String = egg.egg_data.get_display_name() if egg.egg_data else tr("EGG_LAPIS_LAZULI")
		if hud:
			hud.show_prompt(tr("UI_PROMPT_PICK") + " • " + egg_name)
		return

	var showcase: ShowcaseUnit = _resolve_showcase(collider)
	if showcase:
		var title: String = tr(showcase.showcase_title)
		if GameManager.has_matching_egg_for_showcase(showcase.showcase_id):
			if hud:
				hud.show_prompt(tr("UI_PROMPT_PLACE") + " • " + title)
		elif GameManager.player_basket.is_empty():
			if hud:
				hud.show_prompt(title + " " + tr("UI_BASKET_EMPTY"))
		else:
			if hud:
				hud.show_prompt(title)
		return

	if hud:
		hud.hide_prompt()

func _handle_interaction() -> void:
	if not raycast or not raycast.is_colliding():
		return
	var collider: Object = raycast.get_collider()
	if not collider or not is_instance_valid(collider):
		return

	var egg: EggActor = _resolve_egg(collider)
	if egg:
		egg.pick_up()
		return

	var showcase: ShowcaseUnit = _resolve_showcase(collider)
	if showcase:
		showcase.try_deposit()

## Safely resolves a ShowcaseUnit from a collider
func _resolve_showcase(collider: Object) -> ShowcaseUnit:
	if not collider or not is_instance_valid(collider):
		return null
	if collider is ShowcaseUnit:
		return collider as ShowcaseUnit
	if collider.has_meta("showcase_unit"):
		var meta_unit = collider.get_meta("showcase_unit")
		if meta_unit is ShowcaseUnit and is_instance_valid(meta_unit):
			return meta_unit as ShowcaseUnit
	if collider is Node:
		var parent: Node = (collider as Node).get_parent()
		if parent is ShowcaseUnit:
			return parent as ShowcaseUnit
		var owner_node: Node = (collider as Node).owner
		if owner_node is ShowcaseUnit:
			return owner_node as ShowcaseUnit
	return null

## Safely resolves an EggActor from a collider
func _resolve_egg(collider: Object) -> EggActor:
	if not collider or not is_instance_valid(collider):
		return null
	if collider is EggActor:
		return collider as EggActor
	if collider is Node:
		var parent: Node = (collider as Node).get_parent()
		if parent is EggActor:
			return parent as EggActor
	return null

func _trigger_resonance() -> void:
	AudioManager.play_chime(global_position)

func _get_sensitivity() -> float:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and "mouse_sensitivity" in sm:
		return sm.mouse_sensitivity
	return mouse_sensitivity
