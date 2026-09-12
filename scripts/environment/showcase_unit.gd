class_name ShowcaseUnit
extends Node3D

## Reusable Modular Showcase Unit scaled to cozy Librarian proportions (~2.95m tall).
## Holds 6 dozens (72 eggs of 30cm height) on stepped velvet display plinths.
## Uses MultiMeshInstance3D for high-performance GPU batch rendering (1 draw call).

signal dozen_finished(dozen_idx: int)
signal showcase_finished()

@export var showcase_id: int = 1
@export var showcase_title: String = "SHOWCASE_MINERALS_1"

const DOZENS_COUNT: int = 5
const EGGS_PER_DOZEN: int = 12
const TOTAL_CAPACITY: int = 60

var multimesh_instance: MultiMeshInstance3D
var interaction_area: Area3D
var shelves_container: Node3D
var category_label: Label3D

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

		# Materials matching Victorian boutique reference image:
		# 1. Warm honey-amber English oak
		var oak_mat: StandardMaterial3D = StandardMaterial3D.new()
		oak_mat.albedo_color = Color(0.58, 0.38, 0.20, 1.0)
		oak_mat.roughness = 0.38
		oak_mat.metallic = 0.02

		# 2. Rich royal wine / burgundy velvet with soft velvety rim sheen
		var velvet_mat: StandardMaterial3D = StandardMaterial3D.new()
		velvet_mat.albedo_color = Color(0.38, 0.06, 0.11, 1.0) # Royal burgundy velvet
		velvet_mat.roughness = 0.65
		velvet_mat.rim_enabled = true
		velvet_mat.rim = 0.35
		velvet_mat.rim_tint = 0.6

		# 3. Gilded antique brass trim
		var brass_mat: StandardMaterial3D = StandardMaterial3D.new()
		brass_mat.albedo_color = Color(0.88, 0.72, 0.28, 1.0)
		brass_mat.metallic = 0.85
		brass_mat.roughness = 0.25

		# 4. Dark recessed walnut
		var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
		dark_wood_mat.albedo_color = Color(0.24, 0.15, 0.08, 1.0)
		dark_wood_mat.roughness = 0.45

		# Shared meshes for shelves:
		var velvet_bed_mesh: BoxMesh = BoxMesh.new()
		velvet_bed_mesh.size = Vector3(2.18, 0.035, 0.58)
		velvet_bed_mesh.material = velvet_mat

		var shelf_lip_mesh: BoxMesh = BoxMesh.new()
		shelf_lip_mesh.size = Vector3(2.20, 0.045, 0.04)
		shelf_lip_mesh.material = oak_mat

		var brass_edge_mesh: BoxMesh = BoxMesh.new()
		brass_edge_mesh.size = Vector3(2.18, 0.008, 0.01)
		brass_edge_mesh.material = brass_mat

		# 5 tiers of flat display shelves starting above the 0.48m wooden base
		for d in range(DOZENS_COUNT):
			var tier_base_y: float = 0.48 + float(d) * 0.42
			
			# Burgundy velvet plush display tray
			var mi_velvet: MeshInstance3D = MeshInstance3D.new()
			mi_velvet.mesh = velvet_bed_mesh
			mi_velvet.position = Vector3(0, tier_base_y, -0.02)
			shelves_container.add_child(mi_velvet)

			# Warm honey oak front fascia lip
			var mi_lip: MeshInstance3D = MeshInstance3D.new()
			mi_lip.mesh = shelf_lip_mesh
			mi_lip.position = Vector3(0, tier_base_y, 0.29)
			shelves_container.add_child(mi_lip)

			# Elegant brass trim along shelf front edge
			var mi_brass_strip: MeshInstance3D = MeshInstance3D.new()
			mi_brass_strip.mesh = brass_edge_mesh
			mi_brass_strip.position = Vector3(0, tier_base_y + 0.02, 0.305)
			shelves_container.add_child(mi_brass_strip)

		# Pilaster base plinth blocks (left and right)
		var pilaster_plinth_mesh: BoxMesh = BoxMesh.new()
		pilaster_plinth_mesh.size = Vector3(0.14, 0.48, 0.72)
		pilaster_plinth_mesh.material = oak_mat

		var mi_pilaster_left: MeshInstance3D = MeshInstance3D.new()
		mi_pilaster_left.mesh = pilaster_plinth_mesh
		mi_pilaster_left.position = Vector3(-1.15, 0.24, 0.0)
		shelves_container.add_child(mi_pilaster_left)

		var mi_pilaster_right: MeshInstance3D = MeshInstance3D.new()
		mi_pilaster_right.mesh = pilaster_plinth_mesh
		mi_pilaster_right.position = Vector3(1.15, 0.24, 0.0)
		shelves_container.add_child(mi_pilaster_right)

		# Classical Wainscoting Base Panel on the front of PlinthBase (Y = 0.24m):
		# 1. Outer molded wooden frame of base panel
		var base_frame_mesh: BoxMesh = BoxMesh.new()
		base_frame_mesh.size = Vector3(2.08, 0.30, 0.02)
		base_frame_mesh.material = oak_mat

		var mi_base_frame: MeshInstance3D = MeshInstance3D.new()
		mi_base_frame.mesh = base_frame_mesh
		mi_base_frame.position = Vector3(0, 0.24, 0.382)
		shelves_container.add_child(mi_base_frame)

		# 2. Recessed inner panel in darker wood
		var base_recess_mesh: BoxMesh = BoxMesh.new()
		base_recess_mesh.size = Vector3(1.98, 0.22, 0.015)
		base_recess_mesh.material = dark_wood_mat

		var mi_base_recess: MeshInstance3D = MeshInstance3D.new()
		mi_base_recess.mesh = base_recess_mesh
		mi_base_recess.position = Vector3(0, 0.24, 0.388)
		shelves_container.add_child(mi_base_recess)

		# 3. Gilded brass cartouche frame
		var brass_frame_mesh: BoxMesh = BoxMesh.new()
		brass_frame_mesh.size = Vector3(1.82, 0.16, 0.012)
		brass_frame_mesh.material = brass_mat

		var mi_brass_cartouche: MeshInstance3D = MeshInstance3D.new()
		mi_brass_cartouche.mesh = brass_frame_mesh
		mi_brass_cartouche.position = Vector3(0, 0.24, 0.394)
		shelves_container.add_child(mi_brass_cartouche)

		# 4. Gilded 3D Category Title Label on the wooden base
		category_label = Label3D.new()
		category_label.name = "CategoryLabel"
		category_label.text = tr(showcase_title).to_upper()
		category_label.font_size = 28
		category_label.outline_size = 8
		category_label.outline_modulate = Color(0.08, 0.05, 0.02, 1.0)
		category_label.modulate = Color(0.98, 0.93, 0.78, 1.0)
		category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		category_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		category_label.position = Vector3(0, 0.24, 0.404)
		shelves_container.add_child(category_label)
	else:
		category_label = shelves_container.get_node_or_null("CategoryLabel") as Label3D

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

		# 30cm height, 23cm diameter egg mesh (matching Librarian book scale)
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.115
		sphere.height = 0.30

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
		box.size = Vector3(2.7, 3.1, 1.8)
		col.shape = box
		col.position = Vector3(0, 1.50, 0)
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
	if category_label:
		category_label.text = tr(showcase_title).to_upper()

	if not multimesh_instance or not multimesh_instance.multimesh:
		return
	var placed_idx: int = 0
	var mm: MultiMesh = multimesh_instance.multimesh

	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		var egg_info: EggData = GameManager.get_egg_for_showcase_dozen(showcase_id, d)
		var egg_col: Color = egg_info.albedo_color if egg_info else Color(0.15, 0.35, 0.75)

		var tier_base_y: float = 0.48 + float(d - 1) * 0.42

		for s in range(count):
			var slot_x: float
			var slot_y: float = tier_base_y + 0.1675 # Superficie plana de la balda (sin escalón)
			var slot_z: float

			if s < 6:
				# 6 huevos al fondo (al mismo nivel plano a Z = -0.14)
				slot_x = -0.85 + float(s) * 0.34
				slot_z = -0.14
			else:
				# 6 huevos de frente (al mismo nivel plano a Z = +0.14)
				slot_x = -0.85 + float(s - 6) * 0.34
				slot_z = +0.14

			var egg_transform: Transform3D = Transform3D(Basis(), Vector3(slot_x, slot_y, slot_z))
			mm.set_instance_transform(placed_idx, egg_transform)
			mm.set_instance_color(placed_idx, egg_col)
			placed_idx += 1

	mm.visible_instance_count = placed_idx
