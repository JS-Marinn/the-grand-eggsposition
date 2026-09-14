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
const SHOWCASE_EGG_SHADER: Shader = preload("res://assets/shaders/showcase_egg.gdshader")
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
var _current_holo_tier: int = -1
var _current_holo_slot: int = -1
var _holo_tween: Tween = null

func _ready() -> void:
	add_to_group("showcases")
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
	var shelf_model: Node3D = get_node_or_null("ShelfModel") as Node3D
	if not shelf_model:
		var model_scene = load("res://assets/models/showcase_shelf.glb") as PackedScene
		if model_scene:
			shelf_model = model_scene.instantiate() as Node3D
			shelf_model.name = "ShelfModel"
			shelf_model.transform = Transform3D(
				Vector3(0.2, 0, 0),
				Vector3(0, 0.21, 0),
				Vector3(0, 0, 0.2),
				Vector3(-1.0, -0.15, -0.318)
			)
			add_child(shelf_model)

	if shelf_model:
		_apply_shelf_model_materials(shelf_model)

	# Gilded 3D Category Title Label on the wooden plinth front
	category_label = get_node_or_null("CategoryLabel") as Label3D
	if not category_label:
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
		category_label.position = Vector3(0, 0.24, 0.38)
		add_child(category_label)

func _apply_shelf_model_materials(model: Node3D) -> void:
	# English oak material for cabinet structure
	var oak_mat := StandardMaterial3D.new()
	oak_mat.albedo_color = Color(0.56, 0.36, 0.19, 1.0)
	oak_mat.roughness = 0.38
	oak_mat.metallic = 0.02

	# Antique gilded brass material for egg cup holders
	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.82, 0.66, 0.26, 1.0)
	brass_mat.metallic = 0.80
	brass_mat.roughness = 0.38


	for child in model.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if "Holder" in mi.name:
				mi.material_override = brass_mat
			else:
				mi.material_override = oak_mat


func _setup_multimesh() -> void:
	multimesh_instance = get_node_or_null("MultiMeshInstance3D")
	if not multimesh_instance:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "MultiMeshInstance3D"
		multimesh_instance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.instance_count = TOTAL_CAPACITY
		multimesh.visible_instance_count = TOTAL_CAPACITY

		# PBR ShaderMaterial that reflects authentic egg roughness, metallic, specular, and emission
		var egg_mat: ShaderMaterial = ShaderMaterial.new()
		egg_mat.shader = SHOWCASE_EGG_SHADER
		multimesh_instance.material_override = egg_mat

		multimesh.mesh = BASE_EGG_MESH

		# Initialize all 60 instance transforms to scaled zero at their permanent slot positions
		for d in range(1, DOZENS_COUNT + 1):
			for s in range(EGGS_PER_DOZEN):
				var idx: int = (d - 1) * EGGS_PER_DOZEN + s
				var slot_pos: Vector3 = get_slot_local_position(d, s)
				multimesh.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3.ZERO), slot_pos))
				multimesh.set_instance_color(idx, Color.WHITE)
				multimesh.set_instance_custom_data(idx, Color(0.3, 0.0, 0.5, 0.0))

		multimesh_instance.multimesh = multimesh
		add_child(multimesh_instance)

func _setup_interaction_area() -> void:
	interaction_area = get_node_or_null("InteractionArea")
	if not interaction_area:
		interaction_area = Area3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(2.40, 2.15, 0.75)
		col.shape = box
		col.position = Vector3(0, 1.55, 0)
		interaction_area.add_child(col)
		add_child(interaction_area)
	interaction_area.set_meta("showcase_unit", self)

## 3D model holder physical X offsets for the 6 egg slots in each row (symmetrical left 3, right 3)
const HOLDER_X_OFFSETS: Array[float] = [
	-0.859, -0.573, -0.286, 0.281, 0.568, 0.854
]

## Returns local coordinate of slot index s (0..11) in dozen tier d (1..5)
func get_slot_local_position(d: int, s: int) -> Vector3:
	var tier_base_y: float = 0.48 + float(d - 1) * 0.42
	var slot_y: float = tier_base_y + 0.1675
	var x_idx: int = clampi(s if s < 6 else s - 6, 0, HOLDER_X_OFFSETS.size() - 1)
	var slot_x: float = HOLDER_X_OFFSETS[x_idx]
	var slot_z: float = -0.14 if s < 6 else +0.14

	return Vector3(slot_x, slot_y, slot_z)

## Returns global world position where player stands to approach this showcase
func get_approach_global_position() -> Vector3:
	return to_global(Vector3(0.0, 0.05, 1.35))

## Returns global world position of slot s (0..11) in tier d (1..5)
func get_slot_global_position(d: int, s: int) -> Vector3:
	return to_global(get_slot_local_position(d, s))

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

## Returns the deposit target for a specific tier aimed at by the player.
## If the player has an egg matching this showcase and this tier, is_valid is true (Green).
## If the player does not have an egg for this tier, is_valid is false (Red).
func get_target_for_tier(aimed_tier: int) -> Dictionary:
	var tier_clamped: int = clampi(aimed_tier, 1, DOZENS_COUNT)

	var matching_egg: EggData = null
	var matching_count_in_basket: int = 0
	for egg in GameManager.player_basket:
		if egg.showcase_id == showcase_id and egg.dozen_group == tier_clamped:
			if not matching_egg:
				matching_egg = egg
			matching_count_in_basket += 1

	var current_count: int = GameManager.showcase_state[showcase_id].get(tier_clamped, 0)
	var is_tier_full: bool = (current_count >= EGGS_PER_DOZEN)

	if matching_egg and not is_tier_full:
		return {
			"egg": matching_egg,
			"dozen": tier_clamped,
			"slot": current_count,
			"is_valid": true,
			"is_full": false,
			"basket_count": matching_count_in_basket
		}
	elif is_tier_full:
		var preview_egg: EggData = matching_egg
		if not preview_egg and not GameManager.player_basket.is_empty():
			preview_egg = GameManager.player_basket[0]
		return {
			"egg": preview_egg,
			"dozen": tier_clamped,
			"slot": EGGS_PER_DOZEN - 1,
			"is_valid": false,
			"is_full": true,
			"basket_count": matching_count_in_basket
		}
	else:
		var preview_egg: EggData = null
		if not GameManager.player_basket.is_empty():
			preview_egg = GameManager.player_basket[0]

		return {
			"egg": preview_egg,
			"dozen": tier_clamped,
			"slot": current_count,
			"is_valid": false,
			"is_full": false,
			"basket_count": 0
		}

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

## Shows or updates the placement hologram preview.
## Requirement 2: Teleports instantly when switching between different levels.
## Requirement 3: Smoothly animates to the next slot when advancing on the same level.
func update_placement_hologram(egg_to_preview: EggData, is_valid: bool, d: int, s: int) -> void:
	if not hologram_mesh_instance:
		_setup_hologram()

	var target_pos: Vector3 = get_slot_local_position(d, s)
	var target_color: Color = HOLO_COLOR_VALID if is_valid else HOLO_COLOR_INVALID

	if hologram_material:
		hologram_material.set_shader_parameter("hologram_color", target_color)

	if egg_to_preview and egg_to_preview.custom_mesh:
		hologram_mesh_instance.mesh = egg_to_preview.custom_mesh
	else:
		hologram_mesh_instance.mesh = BASE_EGG_MESH

	var tier_changed: bool = (d != _current_holo_tier)
	var slot_advanced_on_same_tier: bool = (not tier_changed and s != _current_holo_slot and _current_holo_slot != -1)

	if tier_changed or not hologram_mesh_instance.visible:
		# Teleport instantly when aiming at another level or first shown
		if _holo_tween and _holo_tween.is_valid():
			_holo_tween.kill()
		hologram_mesh_instance.position = target_pos
		hologram_mesh_instance.scale = Vector3.ONE
	elif slot_advanced_on_same_tier:
		# Smooth glide animation when advancing to the next slot on the same level
		if _holo_tween and _holo_tween.is_valid():
			_holo_tween.kill()
		_holo_tween = create_tween()
		_holo_tween.set_parallel(true)
		_holo_tween.tween_property(hologram_mesh_instance, "position", target_pos, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		hologram_mesh_instance.scale = Vector3(1.18, 0.82, 1.18)
		_holo_tween.tween_property(hologram_mesh_instance, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_current_holo_tier = d
	_current_holo_slot = s
	hologram_mesh_instance.visible = true

## Hides the placement preview hologram
func hide_placement_hologram() -> void:
	_current_holo_tier = -1
	_current_holo_slot = -1
	if _holo_tween and _holo_tween.is_valid():
		_holo_tween.kill()
	if hologram_mesh_instance:
		hologram_mesh_instance.visible = false

## Attempt to deposit an egg directly into the aimed tier
func try_deposit_at_tier(aimed_tier: int, from_global_pos: Vector3 = Vector3.INF, animate: bool = true) -> bool:
	var tier_clamped: int = clampi(aimed_tier, 1, DOZENS_COUNT)
	var egg_info: EggData = null
	var matching_count: int = 0
	for egg in GameManager.player_basket:
		if egg.showcase_id == showcase_id and egg.dozen_group == tier_clamped:
			if not egg_info:
				egg_info = egg
			matching_count += 1
	if not egg_info:
		return false

	var current_count: int = GameManager.showcase_state[showcase_id].get(tier_clamped, 0)
	var slots_needed: int = EGGS_PER_DOZEN - current_count
	if slots_needed <= 0:
		return false

	# Cascade Deposit R2: Harmonic Snap (deposit all matching eggs simultaneously if >= 2)
	if ProgressManager.can_use_harmonic_snap() and matching_count > 1:
		var to_deposit: int = mini(matching_count, slots_needed)
		for i in range(to_deposit):
			var slot_idx: int = current_count + i
			var slot_key: String = str(tier_clamped) + "_" + str(slot_idx)
			if animate:
				in_flight_slots[slot_key] = true
			GameManager.deposit_egg_into_showcase(showcase_id, tier_clamped)
			if not animate:
				AudioManager.play_snap(global_position)
				_refresh_visuals()
				_check_completion(tier_clamped)
			else:
				_animate_egg_flight(egg_info, tier_clamped, slot_idx, from_global_pos, float(i) * 0.035)
		return true

	# Standard single egg deposit
	var slot_idx: int = current_count
	var slot_key: String = str(tier_clamped) + "_" + str(slot_idx)

	if animate:
		in_flight_slots[slot_key] = true

	if GameManager.deposit_egg_into_showcase(showcase_id, tier_clamped):
		if not animate:
			AudioManager.play_snap(global_position)
			_refresh_visuals()
			_check_completion(tier_clamped)
		else:
			_animate_egg_flight(egg_info, tier_clamped, slot_idx, from_global_pos, 0.0)
		return true
	return false

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

## Calculates collision-free egg placement trajectory from local_start to local_target at normalized progress t (0.0 to 1.0).
## Guarantees the egg maneuvers through open air in front of the showcase (Z >= 0.48) and enters the target shelf
## strictly horizontally within its vertical opening, preventing clipping through shelves above or below.
func get_flight_trajectory_point(local_start: Vector3, local_target: Vector3, t: float) -> Vector3:
	var entry_z: float = maxf(0.48, local_start.z * 0.35 + 0.48 * 0.65)
	if local_start.z < 0.50:
		entry_z = 0.55
	var entry_y: float = local_target.y + 0.035
	var local_entry: Vector3 = Vector3(local_target.x, entry_y, entry_z)
	
	var t_split: float = 0.52
	if t < t_split:
		var u: float = t / t_split
		# Quintic smoothstep for smooth approach without velocity spikes: 6u^5 - 15u^4 + 10u^3
		var u_smooth: float = u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
		var pos: Vector3 = Vector3.ZERO
		pos.x = lerpf(local_start.x, local_entry.x, u_smooth)
		pos.y = lerpf(local_start.y, local_entry.y, u_smooth) + (0.10 * sin(u * PI))
		pos.z = lerpf(local_start.z, local_entry.z, u_smooth) + (0.08 * sin(u * PI))
		return pos
	else:
		var u: float = (t - t_split) / (1.0 - t_split)
		var u_smooth: float = u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
		var pos: Vector3 = Vector3.ZERO
		pos.x = local_target.x
		# Inside shelf: Y gently settles 3.5cm down onto the velvet cushion
		pos.y = lerpf(local_entry.y, local_target.y, u_smooth)
		# Z glides straight inward to the target slot
		pos.z = lerpf(local_entry.z, local_target.z, u_smooth)
		return pos

## Returns rotation basis during placement flight, righting the egg upright before entering the shelf opening.
func get_flight_trajectory_basis(start_quat: Quaternion, target_basis: Basis, t: float) -> Basis:
	var t_split: float = 0.52
	if t < t_split:
		var u: float = t / t_split
		var rot_u: float = u * u * (3.0 - 2.0 * u)
		return Basis(start_quat.slerp(Quaternion(target_basis), rot_u))
	else:
		return target_basis

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
		var up_axis: Vector3 = Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD
		start_basis = Basis.looking_at(dir, up_axis)
	proxy.global_basis = start_basis

	var flight_duration: float = 0.36
	var flight_tween: Tween = create_tween()
	var start_quat: Quaternion = Quaternion(start_basis)
	var local_start: Vector3 = to_local(from_global_pos)
	var local_target: Vector3 = local_slot_pos

	if delay > 0.0:
		flight_tween.tween_interval(delay)

	flight_tween.tween_method(func(t: float):
		if not is_instance_valid(proxy) or not is_inside_tree():
			return
		var local_pos: Vector3 = get_flight_trajectory_point(local_start, local_target, t)
		proxy.global_position = to_global(local_pos)
		proxy.global_basis = get_flight_trajectory_basis(start_quat, target_global_basis, t)
	, 0.0, 1.0, flight_duration)

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
	var mm: MultiMesh = multimesh_instance.multimesh

	for d in range(1, DOZENS_COUNT + 1):
		var count: int = GameManager.showcase_state[showcase_id].get(d, 0)
		var egg_info: EggData = GameManager.get_egg_for_showcase_dozen(showcase_id, d)
		var egg_col: Color = egg_info.albedo_color if egg_info else Color(0.15, 0.35, 0.75)
		var roughness: float = egg_info.roughness if egg_info else 0.3
		var metallic: float = egg_info.metallic if egg_info else 0.0
		var specular: float = 0.5
		var emission: float = egg_info.emission_energy if egg_info else 0.0
		var custom_data: Color = Color(roughness, metallic, specular, emission)
		var is_custom: bool = (egg_info != null and (egg_info.custom_scene != null or egg_info.custom_mesh != null))

		for s in range(EGGS_PER_DOZEN):
			var slot_idx: int = (d - 1) * EGGS_PER_DOZEN + s
			var slot_pos: Vector3 = get_slot_local_position(d, s)
			var slot_key: String = str(d) + "_" + str(s)
			var node_name: String = "CustomEgg_" + slot_key

			if s < count and not in_flight_slots.has(slot_key):
				if is_custom:
					mm.set_instance_transform(slot_idx, Transform3D(Basis().scaled(Vector3.ZERO), slot_pos))
					if custom_shelved_container:
						var existing_node = custom_shelved_container.get_node_or_null(node_name)
						if not existing_node:
							var model_node = egg_info.instantiate_visual_node()
							model_node.name = node_name
							model_node.position = slot_pos
							custom_shelved_container.add_child(model_node)
				else:
					mm.set_instance_transform(slot_idx, Transform3D(Basis(), slot_pos))
					mm.set_instance_color(slot_idx, egg_col)
					mm.set_instance_custom_data(slot_idx, custom_data)
			else:
				mm.set_instance_transform(slot_idx, Transform3D(Basis().scaled(Vector3.ZERO), slot_pos))
				if custom_shelved_container:
					var existing_node = custom_shelved_container.get_node_or_null(node_name)
					if existing_node:
						existing_node.queue_free()
