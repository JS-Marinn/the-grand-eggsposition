class_name EggActor
extends RigidBody3D

## Physical in-world collectible egg actor.
## Designed at goose egg scale (~8.5 cm tall by 6 cm diameter).

@export var egg_id: int = 1
@export var egg_data: EggData
@export var is_golden_initial: bool = false

const BASE_EGG_MESH: Mesh = preload("res://assets/models/baseegg_mesh.tres")

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready() -> void:
	add_to_group("eggs")
	if not egg_data:
		if egg_id > 0:
			egg_data = GameManager.get_egg_data(egg_id)
		if not egg_data:
			egg_data = GameManager.get_egg_data(1)
		
	_setup_visuals_and_physics()

func _setup_visuals_and_physics() -> void:
	# Enable auto-sleeping to save CPU cycles
	can_sleep = true
	linear_damp = 2.0
	angular_damp = 3.0
	mass = 4.5 # Double-scale giant ostrich egg weight (~12.0 kg)
	
	mesh_instance = get_node_or_null("MeshInstance3D")
	if egg_data and egg_data.custom_scene:
		if mesh_instance:
			mesh_instance.visible = false
		var custom_visual: Node3D = egg_data.custom_scene.instantiate() as Node3D
		custom_visual.name = "CustomVisual"
		add_child(custom_visual)
		var inner_mesh = custom_visual.find_child("SM_Egg_Standard", true, false) as MeshInstance3D
		if not inner_mesh:
			inner_mesh = custom_visual.find_child("*Mesh*", true, false) as MeshInstance3D
		if inner_mesh:
			mesh_instance = inner_mesh
	else:
		if not mesh_instance:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "MeshInstance3D"
			mesh_instance.mesh = BASE_EGG_MESH
			add_child(mesh_instance)
		else:
			mesh_instance.mesh = BASE_EGG_MESH
		
		# Apply tactile material matching the EggData specs
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if egg_data:
			mat.albedo_color = egg_data.albedo_color
			if egg_data.albedo_texture:
				mat.albedo_texture = egg_data.albedo_texture
			mat.roughness = egg_data.roughness
			mat.metallic = egg_data.metallic
		mesh_instance.material_override = mat
	
	# Reuse existing collision shape or create collision capsule
	collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var capsule: CapsuleShape3D = CapsuleShape3D.new()
		capsule.radius = 0.115
		capsule.height = 0.30
		collision_shape.shape = capsule
		add_child(collision_shape)

var is_being_suctioned: bool = false
var _resonance_tween: Tween
var _orig_emission_enabled: bool = false
var _orig_emission: Color = Color.BLACK
var _orig_emission_energy: float = 0.0

## Collect the egg into the player's basket
func pick_up() -> bool:
	if not egg_data:
		return false
	if GameManager.add_to_basket(egg_data):
		AudioManager.play_pick_tap(global_position)
		queue_free()
		return true
	return false

## Emits a golden resonance pulse and vertical beacon when scanned via Resonance Chime [Q]
func trigger_resonance_highlight(duration: float = 4.0) -> void:
	if not mesh_instance or not mesh_instance.material_override:
		return
	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		return
		
	if _resonance_tween and _resonance_tween.is_valid():
		_resonance_tween.kill()
		
	_orig_emission_enabled = mat.emission_enabled
	_orig_emission = mat.emission
	_orig_emission_energy = mat.emission_energy_multiplier
	
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.84, 0.25) # Warm golden resonance
	
	_resonance_tween = create_tween()
	# Pulse emission between 1.5 and 4.5 for the duration
	var pulses: int = clampi(int(duration * 2.0), 2, 14)
	for i in range(pulses):
		_resonance_tween.tween_property(mat, "emission_energy_multiplier", 4.5, 0.25).set_trans(Tween.TRANS_SINE)
		_resonance_tween.tween_property(mat, "emission_energy_multiplier", 1.2, 0.25).set_trans(Tween.TRANS_SINE)
		
	_resonance_tween.tween_callback(func():
		if is_instance_valid(mat):
			mat.emission_enabled = _orig_emission_enabled
			mat.emission = _orig_emission
			mat.emission_energy_multiplier = _orig_emission_energy
	)

## Smoothly glides the egg towards the player's basket during Sweep Suction
func suction_glide_to(target_pos: Vector3, duration: float = 0.35) -> void:
	if is_being_suctioned:
		return
	is_being_suctioned = true
	freeze = true
	if collision_shape:
		collision_shape.disabled = true
		
	var start_pos: Vector3 = global_position
	var tween: Tween = create_tween()
	
	# Parabolic suction arc lifting slightly then swooping into basket
	tween.tween_method(func(t: float):
		if not is_instance_valid(self):
			return
		var linear_pos: Vector3 = start_pos.lerp(target_pos, t)
		var arc_h: float = 0.45 * sin(t * PI)
		global_position = linear_pos + Vector3(0, arc_h, 0)
		scale = Vector3.ONE.lerp(Vector3(0.65, 0.65, 0.65), t)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_callback(func():
		if is_instance_valid(self):
			pick_up()
	)
