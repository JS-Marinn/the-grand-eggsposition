class_name EggActor
extends RigidBody3D

## Physical in-world collectible egg actor.
## Designed at goose egg scale (~8.5 cm tall by 6 cm diameter).

@export var egg_id: int = 1
@export var egg_data: EggData
@export var is_golden_initial: bool = false

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready() -> void:
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
	
	# Reuse existing mesh instance or create procedural egg-shaped mesh
	mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.115 # 34 cm diameter
		sphere.height = 0.30 # 44 cm height
		mesh_instance.mesh = sphere
		add_child(mesh_instance)
	
	# Apply tactile material matching the EggData specs
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if egg_data:
		mat.albedo_color = egg_data.albedo_color
		mat.roughness = egg_data.roughness
		mat.metallic = egg_data.metallic
		if egg_data.metallic > 0.5:
			mat.metallic_specular = 0.9
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

## Collect the egg into the player's basket
func pick_up() -> bool:
	if not egg_data:
		return false
	if GameManager.add_to_basket(egg_data):
		AudioManager.play_pick_tap(global_position)
		queue_free()
		return true
	return false
