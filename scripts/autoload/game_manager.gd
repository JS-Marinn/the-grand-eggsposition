extends Node

## Central Game Manager for The Grand Eggsposition.
## Coordinates egg state, inventory management, and save/load persistence.

signal egg_collected(egg_data: EggData)
signal egg_placed(egg_data: EggData, showcase_id: int, dozen_idx: int)
signal egg_discovered(egg_data: EggData)
signal progress_updated(placed_count: int, total_count: int)

const TOTAL_SHOWCASES: int = 60
const DOZENS_PER_SHOWCASE: int = 5
const TOTAL_TYPES: int = 300
const EGGS_PER_DOZEN: int = 12
const TOTAL_EGGS: int = 3600

## Database of the 300 unique EggData definitions
var egg_database: Dictionary = {} # egg_id -> EggData

## Discovered eggs catalog tracker (egg_id -> bool)
var discovered_eggs: Dictionary = {}

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
	_scan_and_apply_pbr_textures()
	_initialize_showcase_state()
	# All active boutique showcase suites start discovered
	for id in [1, 2, 3, 4, 11, 21, 22, 23, 24, 25, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45]:
		discover_egg(id)

## Registers all sample and defined egg types
func _initialize_database() -> void:
	# Showcase 1: Minerals & Gemstones I (5 tiers) - Precious Mineral & Metal Suite
	_register_egg(1, "EGG_LAPIS_LAZULI", EggData.EggSeries.MINERALS_GEMS, 1, 1, Color(0.12, 0.28, 0.65), 0.25, 0.1, EggData.EggRarity.RARE)
	_register_egg(2, "EGG_PURE_GOLD", EggData.EggSeries.MINERALS_GEMS, 1, 2, Color(0.96, 0.78, 0.18), 0.20, 0.92, EggData.EggRarity.EPIC)
	_register_egg(3, "EGG_PURE_SILVER", EggData.EggSeries.MINERALS_GEMS, 1, 3, Color(0.86, 0.89, 0.94), 0.18, 0.92, EggData.EggRarity.RARE)
	_register_egg(4, "EGG_PURE_COPPER", EggData.EggSeries.MINERALS_GEMS, 1, 4, Color(0.93, 0.50, 0.32), 0.22, 0.92, EggData.EggRarity.UNCOMMON)
	_register_egg(11, "EGG_PURE_BRONZE", EggData.EggSeries.MINERALS_GEMS, 1, 5, Color(0.78, 0.50, 0.24), 0.24, 0.90, EggData.EggRarity.COMMON)

	# Showcase 2: Minerals & Gemstones II (5 tiers)
	_register_egg(13, "EGG_SAPPHIRE", EggData.EggSeries.MINERALS_GEMS, 2, 2, Color(0.06, 0.18, 0.62), 0.15, 0.4, EggData.EggRarity.RARE)
	_register_egg(14, "EGG_ROSE_QUARTZ", EggData.EggSeries.MINERALS_GEMS, 2, 3, Color(0.94, 0.68, 0.76), 0.28, 0.05, EggData.EggRarity.UNCOMMON)
	_register_egg(15, "EGG_OBSIDIAN", EggData.EggSeries.MINERALS_GEMS, 2, 4, Color(0.12, 0.12, 0.14), 0.12, 0.8, EggData.EggRarity.RARE)
	_register_egg(16, "EGG_DIAMOND", EggData.EggSeries.MINERALS_GEMS, 2, 5, Color(0.88, 0.95, 1.0), 0.08, 0.6, EggData.EggRarity.LEGENDARY)

	# Other Series Samples
	_register_egg(5, "EGG_PASTRY_CHEF", EggData.EggSeries.JOBS_SOCIETY, 11, 1, Color(0.96, 0.92, 0.86), 0.4, 0.0, EggData.EggRarity.UNCOMMON)
	_register_egg(6, "EGG_FIREFIGHTER", EggData.EggSeries.JOBS_SOCIETY, 12, 1, Color(0.85, 0.15, 0.12), 0.3, 0.0, EggData.EggRarity.COMMON)
	_register_egg(7, "EGG_SUPERHERO", EggData.EggSeries.POP_CULTURE, 21, 1, Color(0.1, 0.3, 0.8), 0.3, 0.0, EggData.EggRarity.RARE)
	_register_egg(8, "EGG_GLAZED_DONUT", EggData.EggSeries.DELICATESSEN, 41, 1, Color(0.92, 0.55, 0.65), 0.2, 0.0, EggData.EggRarity.COMMON)
	_register_egg(9, "EGG_PANDA", EggData.EggSeries.WILDLIFE_COSMOS, 51, 1, Color(0.95, 0.95, 0.95), 0.4, 0.0, EggData.EggRarity.RARE)
	_register_egg(10, "EGG_DRAGON_SCALE", EggData.EggSeries.FANTASY_MYTH, 31, 1, Color(0.15, 0.55, 0.35), 0.2, 0.3, EggData.EggRarity.LEGENDARY)

	# Galería 1 - Vitrina 1: Delftware Holandés (Porcelana esmaltada con texturas PBR horneadas 2048x2048)
	_register_egg(21, "EGG_DELFT_SPIRALS", EggData.EggSeries.MINERALS_GEMS, 3, 1, Color(0.965, 0.955, 0.935), 0.08, 0.0, EggData.EggRarity.UNCOMMON, "LORE_EGG_DELFT_SPIRALS", "NOTES_EGG_DELFT_SPIRALS")
	_register_egg(22, "EGG_DELFT_TENDRILS", EggData.EggSeries.MINERALS_GEMS, 3, 2, Color(0.965, 0.955, 0.935), 0.08, 0.0, EggData.EggRarity.RARE, "LORE_EGG_DELFT_TENDRILS", "NOTES_EGG_DELFT_TENDRILS")
	_register_egg(23, "EGG_DELFT_LEAVES", EggData.EggSeries.MINERALS_GEMS, 3, 3, Color(0.965, 0.955, 0.935), 0.08, 0.0, EggData.EggRarity.RARE, "LORE_EGG_DELFT_LEAVES", "NOTES_EGG_DELFT_LEAVES")
	_register_egg(24, "EGG_DELFT_TIDES", EggData.EggSeries.MINERALS_GEMS, 3, 4, Color(0.965, 0.955, 0.935), 0.08, 0.0, EggData.EggRarity.UNCOMMON, "LORE_EGG_DELFT_TIDES", "NOTES_EGG_DELFT_TIDES")
	_register_egg(25, "EGG_DELFT_GUILLOCHE", EggData.EggSeries.MINERALS_GEMS, 3, 5, Color(0.965, 0.955, 0.935), 0.08, 0.0, EggData.EggRarity.EPIC, "LORE_EGG_DELFT_GUILLOCHE", "NOTES_EGG_DELFT_GUILLOCHE")

	# Galería 1 - Vitrina 2: Seigaiha / Olas Niponas (Patrón tradicional japonés con PBR horneado 2K)
	_register_egg(31, "EGG_SEIGAIHA_OCEAN", EggData.EggSeries.MINERALS_GEMS, 4, 1, Color(0.965, 0.955, 0.935), 0.07, 0.0, EggData.EggRarity.UNCOMMON, "LORE_EGG_SEIGAIHA_OCEAN", "NOTES_EGG_SEIGAIHA_OCEAN")
	_register_egg(32, "EGG_SEIGAIHA_INDIGO", EggData.EggSeries.MINERALS_GEMS, 4, 2, Color(0.06, 0.11, 0.25), 0.06, 0.0, EggData.EggRarity.RARE, "LORE_EGG_SEIGAIHA_INDIGO", "NOTES_EGG_SEIGAIHA_INDIGO")
	_register_egg(33, "EGG_SEIGAIHA_JADE", EggData.EggSeries.MINERALS_GEMS, 4, 3, Color(0.83, 0.90, 0.86), 0.06, 0.0, EggData.EggRarity.RARE, "LORE_EGG_SEIGAIHA_JADE", "NOTES_EGG_SEIGAIHA_JADE")
	_register_egg(34, "EGG_SEIGAIHA_CORAL", EggData.EggSeries.MINERALS_GEMS, 4, 4, Color(0.88, 0.46, 0.38), 0.08, 0.8, EggData.EggRarity.EPIC, "LORE_EGG_SEIGAIHA_CORAL", "NOTES_EGG_SEIGAIHA_CORAL")
	_register_egg(35, "EGG_SEIGAIHA_URUSHI", EggData.EggSeries.MINERALS_GEMS, 4, 5, Color(0.05, 0.05, 0.06), 0.04, 0.8, EggData.EggRarity.LEGENDARY, "LORE_EGG_SEIGAIHA_URUSHI", "NOTES_EGG_SEIGAIHA_URUSHI")

	# Galería 1 - Vitrina 3: Dinastía Carmesí y Laca China (Ming / Qing)
	_register_egg(36, "EGG_CRIMSON_MEIHUA", EggData.EggSeries.MINERALS_GEMS, 5, 1, Color(0.66, 0.08, 0.08), 0.05, 0.0, EggData.EggRarity.UNCOMMON, "LORE_EGG_CRIMSON_MEIHUA", "NOTES_EGG_CRIMSON_MEIHUA")
	_register_egg(37, "EGG_CRIMSON_XIANGYUN", EggData.EggSeries.MINERALS_GEMS, 5, 2, Color(0.48, 0.05, 0.05), 0.06, 0.0, EggData.EggRarity.RARE, "LORE_EGG_CRIMSON_XIANGYUN", "NOTES_EGG_CRIMSON_XIANGYUN")
	_register_egg(38, "EGG_CRIMSON_LEIWEN", EggData.EggSeries.MINERALS_GEMS, 5, 3, Color(0.56, 0.06, 0.06), 0.04, 0.8, EggData.EggRarity.RARE, "LORE_EGG_CRIMSON_LEIWEN", "NOTES_EGG_CRIMSON_LEIWEN")
	_register_egg(39, "EGG_CRIMSON_CHRYSANTHEMUM", EggData.EggSeries.MINERALS_GEMS, 5, 4, Color(0.59, 0.07, 0.07), 0.05, 0.6, EggData.EggRarity.EPIC, "LORE_EGG_CRIMSON_CHRYSANTHEMUM", "NOTES_EGG_CRIMSON_CHRYSANTHEMUM")
	_register_egg(40, "EGG_CRIMSON_RUYI", EggData.EggSeries.MINERALS_GEMS, 5, 5, Color(0.47, 0.04, 0.04), 0.05, 0.8, EggData.EggRarity.LEGENDARY, "LORE_EGG_CRIMSON_RUYI", "NOTES_EGG_CRIMSON_RUYI")

	# Galería 1 - Vitrina 4: Celadón Craquelado y Hornos Ge-Ware (Song Dynasty)
	_register_egg(41, "EGG_CELADON_BINGLIE", EggData.EggSeries.MINERALS_GEMS, 6, 1, Color(0.65, 0.79, 0.72), 0.06, 0.0, EggData.EggRarity.UNCOMMON, "LORE_EGG_CELADON_BINGLIE", "NOTES_EGG_CELADON_BINGLIE")
	_register_egg(42, "EGG_CELADON_TIEXIAN", EggData.EggSeries.MINERALS_GEMS, 6, 2, Color(0.60, 0.63, 0.54), 0.08, 0.0, EggData.EggRarity.RARE, "LORE_EGG_CELADON_TIEXIAN", "NOTES_EGG_CELADON_TIEXIAN")
	_register_egg(43, "EGG_CELADON_KINTSUGI", EggData.EggSeries.MINERALS_GEMS, 6, 3, Color(0.68, 0.81, 0.75), 0.07, 0.8, EggData.EggRarity.LEGENDARY, "LORE_EGG_CELADON_KINTSUGI", "NOTES_EGG_CELADON_KINTSUGI")
	_register_egg(44, "EGG_CELADON_JUNWARE", EggData.EggSeries.MINERALS_GEMS, 6, 4, Color(0.48, 0.58, 0.67), 0.06, 0.0, EggData.EggRarity.RARE, "LORE_EGG_CELADON_JUNWARE", "NOTES_EGG_CELADON_JUNWARE")
	_register_egg(45, "EGG_CELADON_EMERALD", EggData.EggSeries.MINERALS_GEMS, 6, 5, Color(0.24, 0.46, 0.35), 0.06, 0.6, EggData.EggRarity.EPIC, "LORE_EGG_CELADON_EMERALD", "NOTES_EGG_CELADON_EMERALD")

## Automatically scans assets/textures/eggs/ and binds baked PBR textures (albedo, normal, roughness, metallic)
## to any matching eggs in the database (supports e.g. egg_gold, egg_silver, egg_obsidian, egg_2, etc.).
func _apply_gold_egg_pbr_textures() -> void:
	_scan_and_apply_pbr_textures()

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res != null:
			return res
	if FileAccess.file_exists(path):
		var global_p := ProjectSettings.globalize_path(path)
		var img := Image.load_from_file(global_p)
		if img != null:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	return null

func _scan_and_apply_pbr_textures() -> void:
	for egg_id in egg_database:
		var egg: EggData = egg_database[egg_id]
		var raw_name: String = egg.egg_name_key.to_lower().trim_prefix("egg_")
		var candidates: Array[String] = [
			raw_name,
			egg.egg_name_key.to_lower(),
			"egg_%d" % egg_id,
		]
		if raw_name.begins_with("pure_"):
			candidates.append(raw_name.trim_prefix("pure_"))

		for cand in candidates:
			var prefix := "res://assets/textures/eggs/egg_" + cand + "_"
			var alb_path := prefix + "albedo.png"
			if FileAccess.file_exists(alb_path):
				egg.albedo_texture = _load_texture(alb_path)
				var norm_path := prefix + "normal.png"
				if FileAccess.file_exists(norm_path):
					egg.normal_texture = _load_texture(norm_path)
				var rough_path := prefix + "roughness.png"
				if FileAccess.file_exists(rough_path):
					egg.roughness_texture = _load_texture(rough_path)
				var metal_path := prefix + "metallic.png"
				if FileAccess.file_exists(metal_path):
					egg.metallic_texture = _load_texture(metal_path)
				break

func _register_egg(id: int, key: String, series: EggData.EggSeries, showcase: int, dozen: int, col: Color, rough: float, metal: float, rarity: EggData.EggRarity = EggData.EggRarity.COMMON, lore_key: String = "", notes_key: String = "", scene: PackedScene = null) -> EggData:
	var egg: EggData = EggData.new()
	egg.egg_id = id
	egg.egg_name_key = key
	egg.series = series
	egg.showcase_id = showcase
	egg.dozen_group = dozen
	egg.albedo_color = col
	egg.roughness = rough
	egg.metallic = metal
	egg.rarity = rarity
	egg.lore_key = lore_key if not lore_key.is_empty() else ("LORE_" + key)
	egg.curator_notes_key = notes_key if not notes_key.is_empty() else ("NOTES_" + key)
	egg.custom_scene = scene
	egg_database[id] = egg
	return egg

func is_egg_discovered(id: int) -> bool:
	return discovered_eggs.get(id, false)

func discover_egg(id: int) -> void:
	if not discovered_eggs.get(id, false):
		discovered_eggs[id] = true
		var egg: EggData = get_egg_data(id)
		if egg:
			egg_discovered.emit(egg)

func get_discovered_count() -> int:
	var count: int = 0
	for val in discovered_eggs.values():
		if val:
			count += 1
	return count

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
	discover_egg(egg.egg_id)
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
				discover_egg(egg.egg_id)
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

## Finds a showcase unit in the scene tree matching target_showcase_id
func get_showcase_unit(target_showcase_id: int) -> ShowcaseUnit:
	var showcases = get_tree().get_nodes_in_group("showcases")
	for s in showcases:
		if is_instance_valid(s) and s is ShowcaseUnit and s.showcase_id == target_showcase_id:
			return s
	return null

