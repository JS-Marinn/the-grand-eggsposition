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

enum EggRarity {
	COMMON = 0,
	UNCOMMON = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4
}

@export var egg_id: int = 1
@export var egg_name_key: String = "EGG_LAPIS_LAZULI"
@export var series: EggSeries = EggSeries.MINERALS_GEMS
@export var rarity: EggRarity = EggRarity.COMMON
@export var showcase_id: int = 1         ## Belongs to showcase 1 through 60
@export var dozen_group: int = 1         ## Dozen slot 1 through 5 in the showcase

@export_group("Compendium & Lore")
@export var lore_key: String = ""
@export var curator_notes_key: String = ""

@export_group("Visuals")
@export var albedo_color: Color = Color(0.2, 0.4, 0.8, 1.0)
@export var albedo_texture: Texture2D = null
@export var normal_texture: Texture2D = null        ## Tangent-space normal map (baked PBR)
@export var roughness_texture: Texture2D = null     ## Greyscale roughness map (baked PBR)
@export var metallic_texture: Texture2D = null      ## Greyscale metallic map (baked PBR)
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
@export var custom_material: Material = null

## Returns the localized display name for the HUD and Journal.
func get_display_name() -> String:
	return tr(egg_name_key)

## Returns the localized rarity label.
func get_rarity_name() -> String:
	match rarity:
		EggRarity.COMMON: return tr("RARITY_COMMON")
		EggRarity.UNCOMMON: return tr("RARITY_UNCOMMON")
		EggRarity.RARE: return tr("RARITY_RARE")
		EggRarity.EPIC: return tr("RARITY_EPIC")
		EggRarity.LEGENDARY: return tr("RARITY_LEGENDARY")
	return tr("RARITY_COMMON")

## Returns a thematic color associated with this egg's rarity.
func get_rarity_color() -> Color:
	match rarity:
		EggRarity.COMMON: return Color(0.55, 0.52, 0.48)      # Pewter / Silver
		EggRarity.UNCOMMON: return Color(0.18, 0.65, 0.32)    # Emerald Green
		EggRarity.RARE: return Color(0.18, 0.48, 0.88)        # Sapphire Blue
		EggRarity.EPIC: return Color(0.62, 0.25, 0.85)        # Royal Purple
		EggRarity.LEGENDARY: return Color(0.92, 0.72, 0.12)   # Radiant Amber Gold
	return Color(0.5, 0.5, 0.5)

## Returns the localized historical/origin lore for the Compendium.
func get_lore() -> String:
	if lore_key.is_empty():
		return tr("LORE_DEFAULT")
	return tr(lore_key)

## Returns the localized curator field notes for the Compendium.
func get_curator_notes() -> String:
	if curator_notes_key.is_empty():
		return tr("NOTES_DEFAULT")
	return tr(curator_notes_key)

## Checks whether this egg uses custom models, scenes, or PBR texture maps.
func has_custom_visuals() -> bool:
	return custom_material != null or custom_scene != null or custom_mesh != null or albedo_texture != null or normal_texture != null or roughness_texture != null or metallic_texture != null

var _cached_material: Material = null

## Creates a fully configured PBR Material based on this egg's visual properties.
func create_material(force_new: bool = false) -> Material:
	if custom_material:
		return custom_material
	if not force_new and _cached_material != null:
		return _cached_material
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if albedo_texture:
		mat.albedo_texture = albedo_texture
		mat.albedo_color = Color.WHITE
	else:
		mat.albedo_color = albedo_color
	if normal_texture:
		mat.normal_enabled = true
		mat.normal_texture = normal_texture
		mat.normal_scale   = 1.0

	# Lustrous metallic reflections matching reference photo
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.metallic_specular = 0.5
	mat.metallic = metallic
	mat.roughness = roughness
	if metallic_texture:
		mat.metallic_texture = metallic_texture
	if roughness_texture:
		mat.roughness_texture = roughness_texture
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy
	if not force_new:
		_cached_material = mat
	return mat

const BASE_EGG_MESH: Mesh = preload("res://assets/models/baseegg_mesh.tres")

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
		mi.mesh = BASE_EGG_MESH

	mi.material_override = create_material()
	node.add_child(mi)
	return node
