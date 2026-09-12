class_name PlayerController
extends CharacterBody3D

## First-person tactile player controller for The Grand Eggsposition.
## Designed for smooth, responsive movement with zero stamina penalty.

@export var move_speed: float = 4.2
@export var sprint_speed: float = 6.8
@export var mouse_sensitivity: float = 0.002
@export var reach_distance: float = 2.8

var camera: Camera3D
var raycast: RayCast3D
var camera_pitch: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_camera_and_raycast()

func _setup_camera_and_raycast() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.65, 0) # Eye level
	camera.fov = 80.0
	add_child(camera)
	
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0, 0, -reach_distance)
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	camera.add_child(raycast)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(85), deg_to_rad(85))
		camera.rotation.x = camera_pitch

	if event.is_action_pressed("resonance_chime"):
		_trigger_resonance()

	if event.is_action_pressed("interact_primary"):
		_handle_interaction()

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
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

func _update_raycast_hover() -> void:
	if not raycast.is_colliding():
		# Clear HUD prompt
		return
	var collider = raycast.get_collider()
	if collider is EggActor:
		pass # Target is egg
	elif collider.get_parent() is ShowcaseUnit:
		pass # Target is showcase

func _handle_interaction() -> void:
	if not raycast.is_colliding():
		return
	var collider = raycast.get_collider()
	if collider is EggActor:
		collider.pick_up()
	elif collider.get_parent() is ShowcaseUnit:
		var showcase: ShowcaseUnit = collider.get_parent() as ShowcaseUnit
		showcase.try_deposit()

func _trigger_resonance() -> void:
	AudioManager.play_chime(global_position)
