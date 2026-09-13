class_name EggData
extends Resource

## Data container representing a unique collectible egg type.
## Each egg belongs to one of the 300 unique types across 30 showcases.

enum EggSeries {
	MINERALS_GEMS = 0,
	JOBS_SOCIETY = 1,
	POP_CULTURE = 2,
	FANTASY_MYTH = 3,
	DELICATESSEN = 4,
	WILDLIFE_COSMOS = 5
}

@export var egg_id: int = 1
@export var egg_name_key: String = "EGG_LAPIS_LAZULI"
@export var series: EggSeries = EggSeries.MINERALS_GEMS
@export var showcase_id: int = 1         ## Belongs to showcase 1 through 60
@export var dozen_group: int = 1         ## Dozen slot 1 through 5 in the showcase

@export_group("Visuals")
@export var albedo_color: Color = Color(0.2, 0.4, 0.8, 1.0)
@export var roughness: float = 0.3
@export var metallic: float = 0.0
@export var emission_color: Color = Color.BLACK
@export var emission_energy: float = 0.0

@export_group("Special Classification")
@export var is_secret_mini: bool = false   ## One of Barnaby's 144 white mini-eggs
@export var is_luxury_egg: bool = false    ## One of the 12 legendary climax eggs

@export_group("Model Overrides")
@export var custom_mesh: Mesh = null
@export var custom_scene: PackedScene = null

## Returns the localized display name for the HUD and Journal.
func get_display_name() -> String:
	return tr(egg_name_key)

## Instantiates a model-agnostic visual Node3D representation of this egg.
## Supports any future custom scene, custom mesh, or procedural default.
func instantiate_visual_node() -> Node3D:
	if custom_scene:
		var scene_instance = custom_scene.instantiate()
		if scene_instance is Node3D:
			return scene_instance as Node3D
			
	var node: Node3D = Node3D.new()
	var mi: MeshInstance3D = MeshInstance3D.new()
	
	if custom_mesh:
		mi.mesh = custom_mesh
	else:
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.115
		sphere.height = 0.30
		mi.mesh = sphere

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = albedo_color
	mat.roughness = roughness
	mat.metallic = metallic
	if metallic > 0.5:
		mat.metallic_specular = 0.9
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy

	mi.material_override = mat
	node.add_child(mi)
	return node
