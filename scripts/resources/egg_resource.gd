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
@export var showcase_id: int = 1         ## Belongs to showcase 1 through 30
@export var dozen_group: int = 1         ## Dozen slot 1 through 10 in the showcase

@export_group("Visuals")
@export var albedo_color: Color = Color(0.2, 0.4, 0.8, 1.0)
@export var roughness: float = 0.3
@export var metallic: float = 0.0
@export var emission_color: Color = Color.BLACK
@export var emission_energy: float = 0.0

@export_group("Special Classification")
@export var is_secret_mini: bool = false   ## One of Barnaby's 144 white mini-eggs
@export var is_luxury_egg: bool = false    ## One of the 12 legendary climax eggs

## Returns the localized display name for the HUD and Journal.
func get_display_name() -> String:
	return tr(egg_name_key)
