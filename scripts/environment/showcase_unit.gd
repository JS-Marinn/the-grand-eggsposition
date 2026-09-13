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
const BASE_EGG_MESH: Mesh = preload("res://assets/models/baseegg_mesh.tres")
const HOLOGRAM_SHADER: Shader = preload("res://assets/shaders/egg_hologram.gdshader")
const HOLO_COLOR_VALID: Color = Color(0.18, 1.0, 0.42, 0.85)   # Luminous green
const HOLO_COLOR_INVALID: Color = Color(1.0, 0.22, 0.25, 0.85) # Luminous red

var multimesh_instance: MultiMeshInstance3D
var interaction_area: Area3D
var shelves_container: Node3D
var category_label: Label3D
var in_flight_container: Node3D
var in_flight_slots: Dictionary = {}
var custom_shelved_container: Node3D
var hologram_mesh_instance: MeshInstance3D
var hologram_material: ShaderMaterial

func _ready() -> void:
	in_flight_container = get_node_or_null("EggsInFlight")
	if not in_flight_container:
		in_flight_container = Node3D.new()
		in_flight_container.name = "EggsInFlight"
		add_child(in_flight_container)

	custom_shelved_container = get_node_or_null("CustomShelvedEggs")
	if not custom_shelved_container:
		custom_shelved_container = Node3D.new()
		custom_shelved_container.name = "CustomShelvedEggs"
		add_child(custom_shelved_container)

	_setup_shelves()
	_setup_multimesh()
	_setup_interaction_area()
	_setup_hologram()
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

		# 30cm height, 23cm diameter canonical egg mesh
		var egg_mat: StandardMaterial3D = StandardMaterial3D.new()
		egg_mat.vertex_color_use_as_albedo = true
		egg_mat.roughness = 0.25
		egg_mat.metallic = 0.2
		multimesh_instance.material_override = egg_mat

		multimesh.mesh = BASE_EGG_MESH
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

## Returns local coordinate of slot index s (0..11) in dozen tier d (1..5)
func get_slot_local_position(d: int, s: int) -> Vector3:
	var tier_base_y: float = 0.48 + float(d - 1) * 0.42
	var slot_y: float = tier_base_y + 0.1675
	var slot_x: float
	var slot_z: float

	if s < 6:
		# 6 huevos al fondo (al mismo nivel plano a Z = -0.14)
		slot_x = -0.85 + float(s) * 0.34
		slot_z = -0.14
	else:
		# 6 huevos de frente (al mismo nivel plano a Z = +0.14)
		slot_x = -0.85 + float(s - 6) * 0.34
		slot_z = +0.14

	return Vector3(slot_x, slot_y, slot_z)

## Sets up the translucent placement preview hologram
func _setup_hologram() -> void:
	if hologram_mesh_instance:
		return
	hologram_mesh_instance = MeshInstance3D.new()
	hologram_mesh_instance.name = "PlacementHologram"
	hologram_mesh_instance.mesh = BASE_EGG_MESH
	hologram_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	hologram_material = ShaderMaterial.new()
	hologram_material.shader = HOLOGRAM_SHADER
	hologram_material.set_shader_parameter("hologram_color", HOLO_COLOR_VALID)
	hologram_mesh_instance.material_override = hologram_material

	hologram_mesh_instance.visible = false
	add_child(hologram_mesh_instance)

## Evaluates what egg and slot would be targeted next by try_deposit
func get_next_deposit_target() -> Dictionary:
	# 1. Check if the player carries an egg matching a tier with open slots
	for d in range(1, DOZENS_COUNT + 1):
		var egg_info: EggData = null
		for egg in GameManager.player_basket:
			if egg.showcase_id == showcase_id and egg.dozen_group == d:
				egg_info = egg
				break
		if not egg_info:
			continue

		var current_count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		if current_count < EGGS_PER_DOZEN:
			return {
				"egg": egg_info,
				"dozen": d,
				"slot": current_count,
				"is_valid": true
			}

	# 2. If no matching egg with open slots, find the first available slot in this showcase
	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		if count < EGGS_PER_DOZEN:
			var carried_egg: EggData = GameManager.player_basket[0] if not GameManager.player_basket.is_empty() else null
			return {
				"egg": carried_egg,
				"dozen": d,
				"slot": count,
				"is_valid": false
			}

	# Showcase is 100% full
	return {}

## Shows or updates the placement hologram preview
func update_placement_hologram(egg_to_preview: EggData, is_valid: bool, d: int, s: int) -> void:
	if not hologram_mesh_instance:
		_setup_hologram()

	if egg_to_preview and egg_to_preview.custom_mesh:
		hologram_mesh_instance.mesh = egg_to_preview.custom_mesh
	else:
		hologram_mesh_instance.mesh = BASE_EGG_MESH

	var target_color: Color = HOLO_COLOR_VALID if is_valid else HOLO_COLOR_INVALID
	if hologram_material:
		hologram_material.set_shader_parameter("hologram_color", target_color)

	var slot_pos: Vector3 = get_slot_local_position(d, s)
	hologram_mesh_instance.position = slot_pos
	hologram_mesh_instance.visible = true

## Hides the placement preview hologram
func hide_placement_hologram() -> void:
	if hologram_mesh_instance:
		hologram_mesh_instance.visible = false

## Try to deposit an egg from the player's basket into this showcase
func try_deposit(from_global_pos: Vector3 = Vector3.INF, animate: bool = true) -> bool:
	for d in range(1, DOZENS_COUNT + 1):
		# Find first egg in basket matching this showcase and dozen
		var egg_info: EggData = null
		var matching_count: int = 0
		for egg in GameManager.player_basket:
			if egg.showcase_id == showcase_id and egg.dozen_group == d:
				if not egg_info:
					egg_info = egg
				matching_count += 1
		if not egg_info:
			continue

		var current_count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		var slots_needed: int = EGGS_PER_DOZEN - current_count
		if slots_needed <= 0:
			continue

		# Cascade Deposit R2: Harmonic Snap (deposit all matching eggs simultaneously if >= 2)
		if ProgressManager.can_use_harmonic_snap() and matching_count > 1:
			var to_deposit: int = mini(matching_count, slots_needed)
			for i in range(to_deposit):
				var slot_idx: int = current_count + i
				var slot_key: String = str(d) + "_" + str(slot_idx)
				if animate:
					in_flight_slots[slot_key] = true
				GameManager.deposit_egg_into_showcase(showcase_id, d)
				if not animate:
					AudioManager.play_snap(global_position)
					_refresh_visuals()
					_check_completion(d)
				else:
					_animate_egg_flight(egg_info, d, slot_idx, from_global_pos, float(i) * 0.035)
			return true

		# Standard single egg deposit
		var slot_idx: int = current_count
		var slot_key: String = str(d) + "_" + str(slot_idx)

		if animate:
			in_flight_slots[slot_key] = true

		if GameManager.deposit_egg_into_showcase(showcase_id, d):
			if not animate:
				AudioManager.play_snap(global_position)
				_refresh_visuals()
				_check_completion(d)
			else:
				_animate_egg_flight(egg_info, d, slot_idx, from_global_pos, 0.0)
			return true
	return false

func _animate_egg_flight(egg_info: EggData, d: int, slot_idx: int, from_global_pos: Vector3, delay: float = 0.0) -> void:
	var slot_key: String = str(d) + "_" + str(slot_idx)
	var local_slot_pos: Vector3 = get_slot_local_position(d, slot_idx)
	var target_global_pos: Vector3 = to_global(local_slot_pos)
	var target_global_basis: Basis = global_transform.basis

	# Default from_global_pos if not provided
	if from_global_pos == Vector3.INF:
		var player = get_tree().root.find_child("Player", true, false)
		if player and "camera" in player and player.camera:
			from_global_pos = player.camera.global_position + player.camera.global_basis * Vector3(0.2, -0.25, -0.45)
		else:
			from_global_pos = to_global(Vector3(0, 1.2, 1.4))

	# Refresh visuals so MultiMesh knows this slot is in-flight (scaled to zero)
	_refresh_visuals()

	# Create model-agnostic visual proxy
	var proxy: Node3D = egg_info.instantiate_visual_node()
	if not in_flight_container:
		in_flight_container = get_node_or_null("EggsInFlight")
		if not in_flight_container:
			in_flight_container = Node3D.new()
			in_flight_container.name = "EggsInFlight"
			add_child(in_flight_container)

	in_flight_container.add_child(proxy)
	proxy.global_position = from_global_pos

	var start_basis: Basis = target_global_basis
	var dir: Vector3 = (target_global_pos - from_global_pos).normalized()
	if dir.length_squared() > 0.001:
		start_basis = Basis.looking_at(dir, Vector3.UP)
	proxy.global_basis = start_basis

	var flight_duration: float = 0.32
	var flight_tween: Tween = create_tween()
	var start_pos: Vector3 = from_global_pos
	var start_quat: Quaternion = Quaternion(start_basis)
	var target_quat: Quaternion = Quaternion(target_global_basis)
	var arc_height: float = maxf(0.24, absf(target_global_pos.y - start_pos.y) * 0.35 + 0.20)

	if delay > 0.0:
		flight_tween.tween_interval(delay)

	flight_tween.tween_method(func(t: float):
		if not is_instance_valid(proxy):
			return
		var cur_pos: Vector3 = start_pos.lerp(target_global_pos, t)
		cur_pos.y += 4.0 * arc_height * t * (1.0 - t)
		proxy.global_position = cur_pos
		proxy.global_basis = Basis(start_quat.slerp(target_quat, t))
	, 0.0, 1.0, flight_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	flight_tween.tween_callback(func():
		if not is_instance_valid(proxy):
			in_flight_slots.erase(slot_key)
			_refresh_visuals()
			return

		proxy.global_position = target_global_pos
		proxy.global_basis = target_global_basis
		AudioManager.play_snap(target_global_pos)

		# Tactile velvet cushion squash and rebound
		var bounce_tween: Tween = create_tween()
		bounce_tween.tween_property(proxy, "scale", Vector3(1.10, 0.80, 1.10), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bounce_tween.tween_property(proxy, "scale", Vector3(1.0, 1.0, 1.0), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bounce_tween.tween_callback(func():
			in_flight_slots.erase(slot_key)
			_refresh_visuals()
			if is_instance_valid(proxy):
				proxy.queue_free()
			_check_completion(d)
		)
	)

func _check_completion(d: int) -> void:
	var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
	if count == EGGS_PER_DOZEN:
		AudioManager.play_dozen_harp(global_position)
		ProgressManager.add_wax_seals(1) # +1 Wax Seal per completed dozen
		dozen_finished.emit(d)

		# Check if the entire showcase is now complete (all 5 tiers full)
		var all_tiers_full: bool = true
		for check_d in range(1, DOZENS_COUNT + 1):
			if GameManager.showcase_state[showcase_id].get(check_d, 0) < EGGS_PER_DOZEN:
				all_tiers_full = false
				break
		if all_tiers_full:
			AudioManager.play_chime(global_position)
			ProgressManager.add_wax_seals(5) # Bonus 5 Wax Seals for completing the full vitrine
			showcase_finished.emit()

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

	# Clear previously shelved custom models before rebuilding
	if custom_shelved_container:
		for child in custom_shelved_container.get_children():
			custom_shelved_container.remove_child(child)
			child.queue_free()

	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		var egg_info: EggData = GameManager.get_egg_for_showcase_dozen(showcase_id, d)
		var egg_col: Color = egg_info.albedo_color if egg_info else Color(0.15, 0.35, 0.75)
		var is_custom: bool = (egg_info != null and (egg_info.custom_scene != null or egg_info.custom_mesh != null))

		for s in range(count):
			var slot_pos: Vector3 = get_slot_local_position(d, s)
			var slot_key: String = str(d) + "_" + str(s)
			var egg_transform: Transform3D

			if in_flight_slots.has(slot_key):
				# While in flight, scale to zero in MultiMesh so the flying proxy is visible
				egg_transform = Transform3D(Basis().scaled(Vector3.ZERO), slot_pos)
			elif is_custom:
				# Hide MultiMesh instance and spawn actual 3D custom model
				egg_transform = Transform3D(Basis().scaled(Vector3.ZERO), slot_pos)
				if custom_shelved_container:
					var model_node = egg_info.instantiate_visual_node()
					model_node.position = slot_pos
					custom_shelved_container.add_child(model_node)
			else:
				egg_transform = Transform3D(Basis(), slot_pos)

			mm.set_instance_transform(placed_idx, egg_transform)
			mm.set_instance_color(placed_idx, egg_col)
			placed_idx += 1

	mm.visible_instance_count = placed_idx
