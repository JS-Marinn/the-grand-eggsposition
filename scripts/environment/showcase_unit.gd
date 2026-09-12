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
var shelves_container: Node3D

func _ready() -> void:
	_setup_shelves()
	_setup_multimesh()
	_setup_interaction_area()
	_refresh_visuals()
	GameManager.egg_placed.connect(_on_egg_placed)

func _setup_shelves() -> void:
	shelves_container = get_node_or_null("Shelves")
	if not shelves_container:
		shelves_container = Node3D.new()
		shelves_container.name = "Shelves"
		add_child(shelves_container)

		var shelf_mesh: BoxMesh = BoxMesh.new()
		shelf_mesh.size = Vector3(3.30, 0.03, 0.46)

		var velvet_mat: StandardMaterial3D = StandardMaterial3D.new()
		velvet_mat.albedo_color = Color(0.12, 0.13, 0.18, 1.0) # Midnight navy velvet
		velvet_mat.roughness = 0.65
		shelf_mesh.material = velvet_mat

		for d in range(DOZENS_COUNT):
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = shelf_mesh
			mi.position = Vector3(0, 0.42 + float(d) * 0.34, 0.0)
			shelves_container.add_child(mi)

func _setup_multimesh() -> void:
	multimesh_instance = get_node_or_null("MultiMeshInstance3D")
	if not multimesh_instance:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "MultiMeshInstance3D"
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.instance_count = TOTAL_CAPACITY
		multimesh.visible_instance_count = 0

		# Maximum record ostrich egg mesh (~22 cm height, 17 cm diameter)
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.085
		sphere.height = 0.22

		var egg_mat: StandardMaterial3D = StandardMaterial3D.new()
		egg_mat.vertex_color_use_as_albedo = true
		egg_mat.roughness = 0.25
		egg_mat.metallic = 0.2
		sphere.material = egg_mat

		multimesh.mesh = sphere
		multimesh_instance.multimesh = multimesh
		add_child(multimesh_instance)

func _setup_interaction_area() -> void:
	interaction_area = get_node_or_null("InteractionArea")
	if not interaction_area:
		interaction_area = Area3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(3.8, 4.0, 1.3) # Bounding box of the maximum vitrine
		col.shape = box
		col.position = Vector3(0, 2.05, 0)
		interaction_area.add_child(col)
		add_child(interaction_area)
	interaction_area.set_meta("showcase_unit", self)

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

func _on_egg_placed(_egg_data: EggData, target_showcase: int, _dozen: int) -> void:
	if target_showcase == showcase_id:
		_refresh_visuals()

func _refresh_visuals() -> void:
	if not multimesh_instance or not multimesh_instance.multimesh:
		return
	var placed_idx: int = 0
	var mm: MultiMesh = multimesh_instance.multimesh

	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		var egg_info: EggData = GameManager.get_egg_for_showcase_dozen(showcase_id, d)
		var egg_col: Color = egg_info.albedo_color if egg_info else Color(0.15, 0.35, 0.75)

		for s in range(count):
			var shelf_y: float = 0.545 + float(d - 1) * 0.34
			var slot_x: float = -1.43 + float(s) * 0.26
			var egg_transform: Transform3D = Transform3D(Basis(), Vector3(slot_x, shelf_y, 0.02))
			mm.set_instance_transform(placed_idx, egg_transform)
			mm.set_instance_color(placed_idx, egg_col)
			placed_idx += 1

	mm.visible_instance_count = placed_idx

