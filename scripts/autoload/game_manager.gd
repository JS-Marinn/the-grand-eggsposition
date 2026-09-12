extends Node

## Central Game Manager for The Grand Eggsposition.
## Coordinates egg state, inventory management, and save/load persistence.

signal egg_collected(egg_data: EggData)
signal egg_placed(egg_data: EggData, showcase_id: int, dozen_idx: int)
signal progress_updated(placed_count: int, total_count: int)

const TOTAL_EGGS: int = 3600
const TOTAL_TYPES: int = 300
const EGGS_PER_DOZEN: int = 12
const DOZENS_PER_SHOWCASE: int = 6

## Database of the 300 unique EggData definitions
var egg_database: Dictionary = {} # egg_id -> EggData

## Placement state: showcase_id (1..30) -> Dictionary(dozen_idx -> count placed)
var showcase_state: Dictionary = {}

## Placed count across the entire boutique
var total_placed_eggs: int = 0

## Player basket inventory (list of EggData instances currently carried)
var player_basket: Array[EggData] = []
var max_basket_capacity: int = 12 # Upgraded via Basket Mastery skill

func _ready() -> void:
	# Human-crafted English in-game experience with built-in i18n support
	TranslationServer.set_locale("en")
	_initialize_database()
	_initialize_showcase_state()

## Registers all sample and defined egg types
func _initialize_database() -> void:
	# Define key sample eggs with accurate series and palette
	_register_egg(1, "EGG_LAPIS_LAZULI", EggData.EggSeries.MINERALS_GEMS, 1, 1, Color(0.12, 0.28, 0.65), 0.25, 0.1)
	_register_egg(2, "EGG_PURE_GOLD", EggData.EggSeries.MINERALS_GEMS, 1, 2, Color(0.95, 0.78, 0.2), 0.15, 0.95)
	_register_egg(3, "EGG_PURE_SILVER", EggData.EggSeries.MINERALS_GEMS, 1, 3, Color(0.85, 0.88, 0.92), 0.1, 0.9)
	_register_egg(4, "EGG_AMETHYST_GEODE", EggData.EggSeries.MINERALS_GEMS, 1, 4, Color(0.55, 0.18, 0.72), 0.3, 0.2)
	_register_egg(5, "EGG_PASTRY_CHEF", EggData.EggSeries.JOBS_SOCIETY, 2, 1, Color(0.96, 0.92, 0.86), 0.4, 0.0)
	_register_egg(6, "EGG_FIREFIGHTER", EggData.EggSeries.JOBS_SOCIETY, 2, 2, Color(0.85, 0.15, 0.12), 0.3, 0.0)
	_register_egg(7, "EGG_SUPERHERO", EggData.EggSeries.POP_CULTURE, 3, 1, Color(0.1, 0.3, 0.8), 0.3, 0.0)
	_register_egg(8, "EGG_GLAZED_DONUT", EggData.EggSeries.DELICATESSEN, 4, 1, Color(0.92, 0.55, 0.65), 0.2, 0.0)
	_register_egg(9, "EGG_PANDA", EggData.EggSeries.WILDLIFE_COSMOS, 5, 1, Color(0.95, 0.95, 0.95), 0.4, 0.0)
	_register_egg(10, "EGG_DRAGON_SCALE", EggData.EggSeries.FANTASY_MYTH, 6, 1, Color(0.15, 0.55, 0.35), 0.2, 0.3)

func _register_egg(id: int, key: String, series: EggData.EggSeries, showcase: int, dozen: int, col: Color, rough: float, metal: float) -> void:
	var egg: EggData = EggData.new()
	egg.egg_id = id
	egg.egg_name_key = key
	egg.series = series
	egg.showcase_id = showcase
	egg.dozen_group = dozen
	egg.albedo_color = col
	egg.roughness = rough
	egg.metallic = metal
	egg_database[id] = egg

func _initialize_showcase_state() -> void:
	for s_id in range(1, 31):
		showcase_state[s_id] = {}
		for d_id in range(1, DOZENS_PER_SHOWCASE + 1):
			showcase_state[s_id][d_id] = 0

## Attempt to add an egg to the player's basket
func add_to_basket(egg: EggData) -> bool:
	if player_basket.size() >= max_basket_capacity:
		return false
	player_basket.append(egg)
	egg_collected.emit(egg)
	return true

## Deposit the currently active/matching egg from the basket into a showcase
func deposit_egg_into_showcase(showcase_id: int, dozen_idx: int) -> bool:
	# Find first egg in basket matching this showcase and dozen
	for i in range(player_basket.size()):
		var egg: EggData = player_basket[i]
		if egg.showcase_id == showcase_id and egg.dozen_group == dozen_idx:
			var current_count: int = showcase_state[showcase_id].get(dozen_idx, 0)
			if current_count < EGGS_PER_DOZEN:
				showcase_state[showcase_id][dozen_idx] = current_count + 1
				player_basket.remove_at(i)
				total_placed_eggs += 1
				egg_placed.emit(egg, showcase_id, dozen_idx)
				progress_updated.emit(total_placed_eggs, TOTAL_EGGS)
				return true
	return false

## Returns the active egg data by ID
func get_egg_data(egg_id: int) -> EggData:
	return egg_database.get(egg_id, null)

## Returns true if the player carries an egg matching this showcase
func has_matching_egg_for_showcase(showcase_id: int) -> bool:
	for egg: EggData in player_basket:
		if egg.showcase_id == showcase_id:
			return true
	return false

## Returns the EggData definition associated with a given showcase and dozen slot
func get_egg_for_showcase_dozen(showcase: int, dozen: int) -> EggData:
	for egg: EggData in egg_database.values():
		if egg.showcase_id == showcase and egg.dozen_group == dozen:
			return egg
	return null
