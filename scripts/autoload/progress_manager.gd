extends Node

## Progress and Skill Manager for The Grand Eggsposition.
## Tracks Curator's Wax Seals currency and unlocks for the 8 core abilities.

signal wax_seals_changed(new_amount: int)
signal skill_upgraded(skill_name: String, new_tier: int)

## Curator's Wax Seals (Moneda de Progresión)
var wax_seals: int = 0

## The 8 Exact Abilities and their current Tier
var skill_tiers: Dictionary = {
	"basket_mastery": 1,   # 1 (12 eggs), 2 (24 eggs), 3 (48 eggs), 4 (96 eggs)
	"sweep_suction": 0,    # 0 (locked), 1 (1.5m radius), 2 (3.5m radius instant)
	"swift_stride": 0,     # 0 (locked), 1 (+15% speed), 2 (+30%), 3 (+45% & stairs)
	"velvet_dash": 0,      # 0 (locked), 1 (4m dash, 4s cd), 2 (2s cd with cart)
	"resonance_chime": 0,  # 0 (locked), 1 (20m aura 4s), 2 (7s & showcase beacon), 3 (White Mini-Egg radar)
	"wayfinder": 0,        # 0 (locked), 1 (golden floor trail to showcase), 2 (exact slot highlight)
	"cascade_deposit": 0,  # 0 (locked), 1 (rapid ASMR burst), 2 (instant dozen snap)
	"egg_toss": 0          # 0 (locked), 1 (soft toss to partner / table 6m), 2 (tray toss 12m)
}

## Skill costs in Curator's Wax Seals
const SKILL_COSTS: Dictionary = {
	"basket_mastery": [0, 5, 15, 35],
	"sweep_suction": [8, 20],
	"swift_stride": [4, 12, 25],
	"velvet_dash": [10, 20],
	"resonance_chime": [6, 18, 30],
	"wayfinder": [8, 15],
	"cascade_deposit": [10, 25],
	"egg_toss": [12, 22]
}

## Add wax seals earned by completing dozens or showcases
func add_wax_seals(amount: int) -> void:
	wax_seals += amount
	wax_seals_changed.emit(wax_seals)

## Attempt to upgrade a skill tier
func upgrade_skill(skill_id: String) -> bool:
	if not skill_tiers.has(skill_id) or not SKILL_COSTS.has(skill_id):
		return false
		
	var current_tier: int = skill_tiers[skill_id]
	var costs_array: Array = SKILL_COSTS[skill_id]
	
	# Check if already maxed
	if current_tier >= costs_array.size():
		return false
		
	var cost: int = costs_array[current_tier]
	if wax_seals >= cost:
		wax_seals -= cost
		current_tier += 1
		skill_tiers[skill_id] = current_tier
		_apply_skill_effects(skill_id, current_tier)
		wax_seals_changed.emit(wax_seals)
		skill_upgraded.emit(skill_id, current_tier)
		return true
		
	return false

## Applies immediate game balance changes when a skill is leveled
func _apply_skill_effects(skill_id: String, tier: int) -> void:
	match skill_id:
		"basket_mastery":
			match tier:
				1: GameManager.max_basket_capacity = 12
				2: GameManager.max_basket_capacity = 24
				3: GameManager.max_basket_capacity = 48
				4: GameManager.max_basket_capacity = 96
