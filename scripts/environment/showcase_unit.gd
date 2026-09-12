class_name ShowcaseUnit
extends Node3D

## Reusable Modular Showcase Unit.
## Holds 10 dozens (120 eggs total) structured in indented velvet trays.
## Uses MultiMeshInstance3D for high-performance GPU batch rendering (1 draw call).

signal dozen_finished(dozen_idx: int)
signal showcase_finished()

@export var showcase_id: int = 1
@export var showcase_title: String = "SHOWCASE_MINERALS_1"

const DOZENS_COUNT: int = 10
const EGGS_PER_DOZEN: int = 12
const TOTAL_CAPACITY: int = 120

var multimesh_instance: MultiMeshInstance3D
var interaction_area: Area3D

func _ready() -> void:
	_setup_multimesh()
	_setup_interaction_area()
	GameManager.egg_placed.connect(_on_egg_placed)

func _setup_multimesh() -> void:
	multimesh_instance = MultiMeshInstance3D.new()
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = TOTAL_CAPACITY
	multimesh.visible_instance_count = 0 # Initially empty until eggs are placed
	
	# Goose egg mesh (~8.5 cm height)
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.085
	multimesh.mesh = sphere
	
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)

func _setup_interaction_area() -> void:
	interaction_area = Area3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.4, 2.8, 0.8) # Bounding box of the showcase
	col.shape = box
	col.position = Vector3(0, 1.4, 0)
	interaction_area.add_child(col)
	add_child(interaction_area)

## Try to deposit an egg from the player's basket into this showcase
func try_deposit() -> bool:
	for d in range(1, DOZENS_COUNT + 1):
		if GameManager.deposit_egg_into_showcase(showcase_id, d):
			AudioManager.play_snap(global_position)
			_refresh_visuals()
			
			# Check if that dozen just hit 12/12
			var count: int = GameManager.showcase_state[showcase_id][d]
			if count == EGGS_PER_DOZEN:
				AudioManager.play_dozen_harp(global_position)
				ProgressManager.add_wax_seals(1) # +1 Wax Seal per completed dozen
				dozen_finished.emit(d)
			return true
	return false

func _on_egg_placed(egg_data: EggData, target_showcase: int, _dozen: int) -> void:
	if target_showcase == showcase_id:
		_refresh_visuals()

func _refresh_visuals() -> void:
	var placed_idx: int = 0
	var mm: MultiMesh = multimesh_instance.multimesh
	
	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		for s in range(count):
			var shelf_y: float = 0.3 + (float(d - 1) * 0.22)
			var slot_x: float = -0.9 + (float(s) * 0.16)
			var egg_transform: Transform3D = Transform3D(Basis(), Vector3(slot_x, shelf_y, 0))
			mm.set_instance_transform(placed_idx, egg_transform)
			placed_idx += 1
			
	mm.visible_instance_count = placed_idx
