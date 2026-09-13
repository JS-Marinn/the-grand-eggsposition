class_name PlayerController
extends CharacterBody3D

## First-person tactile player controller for The Grand Eggsposition.
## Smooth boutique exploration with mouse look, arrow keys, and gamepad support.

@export var move_speed: float = 4.2
@export var sprint_speed: float = 6.8
@export var mouse_sensitivity: float = 0.003
@export var key_look_speed: float = 2.4
@export var reach_distance: float = 3.5

var camera: Camera3D
var raycast: RayCast3D
var camera_pitch: float = 0.0
var interact_hold_timer: float = 0.0
const INTERACT_REPEAT_DELAY: float = 0.28
const INTERACT_REPEAT_RATE: float = 0.12

var space_double_tap_timer: float = 0.0
var velvet_dash_cooldown: float = 0.0
var resonance_cooldown: float = 0.0
var is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
const DASH_DURATION: float = 0.22
const DASH_SPEED: float = 4.0 / 0.22 # ~18.18 m/s

# Fluid kinematics & camera smoothing
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _base_cam_y: float = 1.70
var _bob_phase: float = 0.0
const ACCELERATION: float = 14.0
const DECELERATION: float = 11.0

func _ready() -> void:
	_setup_camera_and_raycast()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_target_yaw = rotation.y
	_target_pitch = camera.rotation.x if camera else 0.0
	if camera:
		_base_cam_y = camera.position.y

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
		camera.add_child(raycast)
	raycast.target_position = Vector3(0, 0, -reach_distance)
	raycast.collision_mask = 7
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true

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
			_target_yaw -= event.relative.x * sens
			_target_pitch = clampf(_target_pitch - event.relative.y * sens, -deg_to_rad(85), deg_to_rad(85))

	if event.is_action_pressed("open_journal"):
		var journal = get_tree().root.find_child("JournalMenu", true, false)
		if journal and journal.has_method("toggle_journal"):
			journal.toggle_journal()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("resonance_chime"):
		_trigger_resonance()

	# Velvet Dash: Double-tap Space or dedicated V key
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			if space_double_tap_timer > 0.0:
				space_double_tap_timer = 0.0
				_perform_velvet_dash()
			else:
				space_double_tap_timer = 0.30
		elif event.physical_keycode == KEY_V:
			_perform_velvet_dash()

		# Dev Cheats / Test Hotkeys: F1 to F8 to upgrade skills on the fly
		match event.physical_keycode:
			KEY_F1: ProgressManager.upgrade_skill("basket_mastery")
			KEY_F2: ProgressManager.upgrade_skill("sweep_suction")
			KEY_F3: ProgressManager.upgrade_skill("swift_stride")
			KEY_F4: ProgressManager.upgrade_skill("velvet_dash")
			KEY_F5: ProgressManager.upgrade_skill("resonance_chime")
			KEY_F6: ProgressManager.upgrade_skill("wayfinder")
			KEY_F7: ProgressManager.upgrade_skill("cascade_deposit")
			KEY_F8: ProgressManager.upgrade_skill("egg_toss")

	if event.is_action_pressed("interact_primary") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_interaction()

func _process(delta: float) -> void:
	_handle_smooth_look(delta)
	_handle_camera_dynamics(delta)

## High-frequency, sub-pixel camera rotation running at full display refresh rate (144Hz+)
func _handle_smooth_look(delta: float) -> void:
	var look_input: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		look_input.x += 1.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		look_input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
		look_input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
		look_input.y += 1.0

	var stick_x: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var stick_y: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(stick_x) > 0.15:
		look_input.x += stick_x
	if absf(stick_y) > 0.15:
		look_input.y += stick_y

	if look_input != Vector2.ZERO:
		_target_yaw -= look_input.x * key_look_speed * delta
		_target_pitch = clampf(_target_pitch - look_input.y * key_look_speed * delta, -deg_to_rad(85), deg_to_rad(85))

	var rot_speed: float = clampf(delta * 42.0, 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, _target_yaw, rot_speed)
	camera_pitch = lerpf(camera_pitch, _target_pitch, rot_speed)
	if camera:
		camera.rotation.x = camera_pitch

## Subtle, organic camera kinematics: ultra-light strafe lean, dynamic FOV, and configurable walking float
func _handle_camera_dynamics(delta: float) -> void:
	if not camera:
		return

	var sm = get_node_or_null("/root/SettingsManager")
	var bob_intensity: float = sm.head_bob_intensity if (sm and "head_bob_intensity" in sm) else 0.20

	# 1. Very subtle strafe lean (scaled by bob_intensity, default 20% -> ~0.08 deg)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_roll: float = -input_dir.x * deg_to_rad(0.4) * bob_intensity
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * 6.0)

	# 2. Dynamic FOV based on movement speed
	var base_fov: float = sm.fov if (sm and "fov" in sm) else 75.0
	var target_fov: float = base_fov
	if is_dashing:
		target_fov += 6.0
	elif Input.is_action_pressed("sprint") and input_dir != Vector2.ZERO:
		target_fov += 2.5
	camera.fov = lerpf(camera.fov, target_fov, delta * 6.0)

	# 3. Ultra-light, whisper-soft walking float (at default 20%: ~1.0mm vertical, ~0.4mm horizontal)
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var is_moving: bool = is_on_floor() and horizontal_speed > 0.3 and bob_intensity > 0.001
	if is_moving:
		var bob_rate: float = 8.5 if Input.is_action_pressed("sprint") else 6.0
		_bob_phase += delta * bob_rate
		var bob_y: float = sin(_bob_phase) * (0.005 * bob_intensity)
		var bob_x: float = cos(_bob_phase * 0.5) * (0.002 * bob_intensity)
		camera.position.y = lerpf(camera.position.y, _base_cam_y + bob_y, delta * 8.0)
		camera.position.x = lerpf(camera.position.x, bob_x, delta * 8.0)
	else:
		camera.position.y = lerpf(camera.position.y, _base_cam_y, delta * 8.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 8.0)

func _physics_process(delta: float) -> void:
	if space_double_tap_timer > 0.0:
		space_double_tap_timer = maxf(0.0, space_double_tap_timer - delta)
	if velvet_dash_cooldown > 0.0:
		velvet_dash_cooldown = maxf(0.0, velvet_dash_cooldown - delta)
	if resonance_cooldown > 0.0:
		resonance_cooldown = maxf(0.0, resonance_cooldown - delta)
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			is_dashing = false

	_handle_movement(delta)
	_update_raycast_hover()
	_handle_hold_interaction(delta)

func _handle_hold_interaction(delta: float) -> void:
	if Input.is_action_pressed("interact_primary") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		interact_hold_timer += delta
		var repeat_rate: float = ProgressManager.get_cascade_repeat_rate()
		if interact_hold_timer >= INTERACT_REPEAT_DELAY:
			if not _try_sweep_suction():
				_handle_interaction()
			interact_hold_timer -= repeat_rate
	else:
		interact_hold_timer = 0.0

func _handle_movement(delta: float) -> void:
	if is_dashing:
		velocity.x = _dash_dir.x * DASH_SPEED
		velocity.z = _dash_dir.z * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var speed: float = sprint_speed if is_sprinting else move_speed
	speed *= ProgressManager.get_swift_stride_multiplier()
	
	# Smooth acceleration and deceleration for tactile weight
	var target_vel: Vector3 = direction * speed
	var accel: float = ACCELERATION if direction != Vector3.ZERO else DECELERATION
	velocity.x = lerpf(velocity.x, target_vel.x, accel * delta)
	velocity.z = lerpf(velocity.z, target_vel.z, accel * delta)
		
	# Apply simple gravity if not on floor
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

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
		var spawn_pos: Vector3 = Vector3.INF
		if camera:
			spawn_pos = camera.global_position + camera.global_basis * Vector3(0.2, -0.25, -0.45)
		showcase.try_deposit(spawn_pos)

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

## Velvet Dash: 4-meter smooth carpet slide forward with camera FOV punch
func _perform_velvet_dash() -> void:
	if not ProgressManager.is_skill_unlocked("velvet_dash"):
		return
	if velvet_dash_cooldown > 0.0 or is_dashing:
		return

	velvet_dash_cooldown = ProgressManager.get_velvet_dash_cooldown()
	is_dashing = true

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir != Vector2.ZERO:
		_dash_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		_dash_dir = -transform.basis.z.normalized()
	_dash_dir.y = 0.0
	_dash_dir = _dash_dir.normalized()
	_dash_timer = DASH_DURATION

	AudioManager.play_velvet_slide(global_position)

	# Subtle camera FOV expansion punch
	if camera:
		var orig_fov: float = camera.fov
		var fov_tween: Tween = create_tween()
		fov_tween.tween_property(camera, "fov", orig_fov + 4.5, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fov_tween.tween_property(camera, "fov", orig_fov, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Resonance Chime: Scans matching loose eggs within 20m and illuminates them
func _trigger_resonance() -> void:
	if not ProgressManager.is_skill_unlocked("resonance_chime"):
		return
	if resonance_cooldown > 0.0:
		return

	resonance_cooldown = ProgressManager.get_resonance_chime_cooldown()
	AudioManager.play_chime(global_position)

	var radius: float = ProgressManager.get_resonance_chime_radius()
	var duration: float = ProgressManager.get_resonance_chime_duration()

	# Determine targeted egg IDs from basket
	var target_ids: Array[int] = []
	for carried in GameManager.player_basket:
		if carried and not target_ids.has(carried.egg_id):
			target_ids.append(carried.egg_id)

	# If basket is empty, check targeted egg from raycast
	if target_ids.is_empty() and raycast and raycast.is_colliding():
		var targeted_egg: EggActor = _resolve_egg(raycast.get_collider())
		if targeted_egg and targeted_egg.egg_data:
			target_ids.append(targeted_egg.egg_data.egg_id)

	var eggs = get_tree().get_nodes_in_group("eggs")
	for egg in eggs:
		if not is_instance_valid(egg) or not egg is EggActor or not egg.egg_data:
			continue
		var egg_actor: EggActor = egg as EggActor
		if egg_actor.global_position.distance_to(global_position) <= radius:
			if target_ids.is_empty() or target_ids.has(egg_actor.egg_data.egg_id):
				egg_actor.trigger_resonance_highlight(duration)

## Sweep Suction: Draws in all loose eggs of the same type within suction radius
func _try_sweep_suction(target_override: EggActor = null) -> bool:
	var radius: float = ProgressManager.get_sweep_suction_radius()
	if radius <= 0.0:
		return false

	var target_egg: EggActor = target_override
	if not target_egg:
		if not raycast or not raycast.is_colliding():
			return false
		target_egg = _resolve_egg(raycast.get_collider())

	if not target_egg or not target_egg.egg_data or target_egg.is_being_suctioned:
		return false

	var target_id: int = target_egg.egg_data.egg_id
	var origin: Vector3 = target_egg.global_position
	var duration: float = ProgressManager.get_sweep_suction_duration()
	var basket_pos: Vector3 = camera.global_position + camera.global_basis * Vector3(0.2, -0.25, -0.45) if camera else global_position + Vector3(0, 1.2, 0)

	var eggs = get_tree().get_nodes_in_group("eggs")
	var candidates: Array[EggActor] = []

	# Always include the targeted egg first
	candidates.append(target_egg)

	for egg in eggs:
		if not is_instance_valid(egg) or not egg is EggActor or egg == target_egg:
			continue
		var egg_actor: EggActor = egg as EggActor
		if egg_actor.is_being_suctioned or not egg_actor.egg_data:
			continue
		if egg_actor.egg_data.egg_id == target_id:
			if egg_actor.global_position.distance_to(origin) <= radius:
				candidates.append(egg_actor)

	if candidates.is_empty():
		return false

	AudioManager.play_suction_swirl(origin)

	# Calculate how many eggs basket can accept
	var remaining_cap: int = GameManager.max_basket_capacity - GameManager.player_basket.size()
	var to_take: int = mini(candidates.size(), remaining_cap)

	for i in range(to_take):
		var egg_to_pull: EggActor = candidates[i]
		var stagger: float = float(i) * 0.04
		if stagger > 0.0:
			get_tree().create_timer(stagger).timeout.connect(func():
				if is_instance_valid(egg_to_pull):
					egg_to_pull.suction_glide_to(basket_pos, duration)
			)
		else:
			egg_to_pull.suction_glide_to(basket_pos, duration)

	return true

func _get_sensitivity() -> float:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and "mouse_sensitivity" in sm:
		return sm.mouse_sensitivity
	return mouse_sensitivity
