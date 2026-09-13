extends Node

## Central Game Manager for The Grand Eggsposition.
## Coordinates egg state, inventory management, and save/load persistence.

signal egg_collected(egg_data: EggData)
signal egg_placed(egg_data: EggData, showcase_id: int, dozen_idx: int)
signal progress_updated(placed_count: int, total_count: int)

const TOTAL_SHOWCASES: int = 60
const DOZENS_PER_SHOWCASE: int = 5
const TOTAL_TYPES: int = 300
const EGGS_PER_DOZEN: int = 12
const TOTAL_EGGS: int = 3600

## Database of the 300 unique EggData definitions
var egg_database: Dictionary = {} # egg_id -> EggData

## Placement state: showcase_id (1..60) -> Dictionary(dozen_idx -> count placed)
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
	# Showcase 1: Minerals & Gemstones I (5 tiers)
	_register_egg(1, "EGG_LAPIS_LAZULI", EggData.EggSeries.MINERALS_GEMS, 1, 1, Color(0.12, 0.28, 0.65), 0.25, 0.1)
	_register_egg(2, "EGG_PURE_GOLD", EggData.EggSeries.MINERALS_GEMS, 1, 2, Color(0.95, 0.78, 0.2), 0.15, 0.95)
	_register_egg(3, "EGG_PURE_SILVER", EggData.EggSeries.MINERALS_GEMS, 1, 3, Color(0.85, 0.88, 0.92), 0.1, 0.9)
	_register_egg(4, "EGG_AMETHYST_GEODE", EggData.EggSeries.MINERALS_GEMS, 1, 4, Color(0.55, 0.18, 0.72), 0.3, 0.2)
	_register_egg(11, "EGG_EMERALD", EggData.EggSeries.MINERALS_GEMS, 1, 5, Color(0.1, 0.72, 0.35), 0.2, 0.3)

	# Showcase 2: Pop Culture & Vault Lore (5 tiers)
	_register_egg(20, "EGG_FALLOUT", EggData.EggSeries.POP_CULTURE, 2, 1, Color(0.95, 0.78, 0.22), 0.7, 0.05, preload("res://scenes/props/fallout_egg_model.tscn"))
	_register_egg(13, "EGG_SAPPHIRE", EggData.EggSeries.MINERALS_GEMS, 2, 2, Color(0.06, 0.18, 0.62), 0.15, 0.4)
	_register_egg(14, "EGG_ROSE_QUARTZ", EggData.EggSeries.MINERALS_GEMS, 2, 3, Color(0.94, 0.68, 0.76), 0.28, 0.05)
	_register_egg(15, "EGG_OBSIDIAN", EggData.EggSeries.MINERALS_GEMS, 2, 4, Color(0.12, 0.12, 0.14), 0.12, 0.8)
	_register_egg(16, "EGG_DIAMOND", EggData.EggSeries.MINERALS_GEMS, 2, 5, Color(0.88, 0.95, 1.0), 0.08, 0.6)

	# Other Series Samples
	_register_egg(5, "EGG_PASTRY_CHEF", EggData.EggSeries.JOBS_SOCIETY, 3, 1, Color(0.96, 0.92, 0.86), 0.4, 0.0)
	_register_egg(6, "EGG_FIREFIGHTER", EggData.EggSeries.JOBS_SOCIETY, 4, 1, Color(0.85, 0.15, 0.12), 0.3, 0.0)
	_register_egg(7, "EGG_SUPERHERO", EggData.EggSeries.POP_CULTURE, 5, 1, Color(0.1, 0.3, 0.8), 0.3, 0.0)
	_register_egg(8, "EGG_GLAZED_DONUT", EggData.EggSeries.DELICATESSEN, 6, 1, Color(0.92, 0.55, 0.65), 0.2, 0.0)
	_register_egg(9, "EGG_PANDA", EggData.EggSeries.WILDLIFE_COSMOS, 7, 1, Color(0.95, 0.95, 0.95), 0.4, 0.0)
	_register_egg(10, "EGG_DRAGON_SCALE", EggData.EggSeries.FANTASY_MYTH, 8, 1, Color(0.15, 0.55, 0.35), 0.2, 0.3)

func _register_egg(id: int, key: String, series: EggData.EggSeries, showcase: int, dozen: int, col: Color, rough: float, metal: float, scene: PackedScene = null) -> EggData:
	var egg: EggData = EggData.new()
	egg.egg_id = id
	egg.egg_name_key = key
	egg.series = series
	egg.showcase_id = showcase
	egg.dozen_group = dozen
	egg.albedo_color = col
	egg.roughness = rough
	egg.metallic = metal
	egg.custom_scene = scene
	egg_database[id] = egg
	return egg

func _initialize_showcase_state() -> void:
	for s_id in range(1, TOTAL_SHOWCASES + 1):
		showcase_state[s_id] = {}
		for d_id in range(1, DOZENS_PER_SHOWCASE + 1):
			showcase_state[s_id][d_id] = 0

## Returns the EggSeries enum associated with a showcase (1..60)
func get_series_for_showcase(s_id: int) -> EggData.EggSeries:
	if s_id <= 10:
		return EggData.EggSeries.MINERALS_GEMS
	elif s_id <= 20:
		return EggData.EggSeries.JOBS_SOCIETY
	elif s_id <= 30:
		return EggData.EggSeries.POP_CULTURE
	elif s_id <= 40:
		return EggData.EggSeries.FANTASY_MYTH
	elif s_id <= 50:
		return EggData.EggSeries.DELICATESSEN
	else:
		return EggData.EggSeries.WILDLIFE_COSMOS

## Returns the localized display title for any of the 60 showcases
func get_showcase_title(s_id: int) -> String:
	match s_id:
		1: return tr("SHOWCASE_MINERALS_1")
		2: return tr("SHOWCASE_FALLOUT")
		3: return tr("SHOWCASE_FABERGE")
		4: return tr("SHOWCASE_CHEFS")
		5: return tr("SHOWCASE_FIREFIGHTERS")
		_:
			var series_name: String = ""
			var series_enum: EggData.EggSeries = get_series_for_showcase(s_id)
			match series_enum:
				EggData.EggSeries.MINERALS_GEMS: series_name = tr("SERIES_MINERALS")
				EggData.EggSeries.JOBS_SOCIETY: series_name = tr("SERIES_JOBS")
				EggData.EggSeries.POP_CULTURE: series_name = tr("SERIES_POP_CULTURE")
				EggData.EggSeries.FANTASY_MYTH: series_name = tr("SERIES_FANTASY")
				EggData.EggSeries.DELICATESSEN: series_name = tr("SERIES_DELICATESSEN")
				EggData.EggSeries.WILDLIFE_COSMOS: series_name = tr("SERIES_WILDLIFE")
			var unit_in_series: int = ((s_id - 1) % 10) + 1
			return "%s (%s %d)" % [series_name, tr("UI_SHOWCASE_NUM"), unit_in_series]

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
