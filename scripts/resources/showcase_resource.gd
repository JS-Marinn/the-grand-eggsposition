class_name ShowcaseData
extends Resource

## Data definition for each of the 30 modular showcases in The Grand Atrium.
## Each showcase contains 10 dozens (120 eggs total).

@export var showcase_id: int = 1
@export var title_key: String = "SHOWCASE_MINERALS_1"
@export var series: EggData.EggSeries = EggData.EggSeries.MINERALS_GEMS
@export var unlocked_by_default: bool = false
@export var required_key_id: String = ""

## Returns the localized display name of the showcase.
func get_title() -> String:
	return tr(title_key)
