class_name WayfinderSystem
extends Node3D

## Fallout V.A.T.S. / V.A.N.S. style navigational guidance system ("Wayfinder").
## Projects an ethereal, animated forward-flowing ribbon on the floor leading
## from the player directly to the showcase and specific shelf tier where an egg belongs.

const TRAIL_SHADER: Shader = preload("res://assets/shaders/wayfinder_trail.gdshader")
const BEACON_SHADER: Shader = preload("res://assets/shaders/wayfinder_beacon.gdshader")

@export var ribbon_width: float = 0.42
@export var sample_points: int = 48
@export var default_duration: float = 4.2

var trail_mesh_instance: MeshInstance3D
var trail_mesh: ImmediateMesh
var trail_material: ShaderMaterial

var ground_beacon_instance: MeshInstance3D
var ground_beacon_material: ShaderMaterial

var shelf_beacon_instance: MeshInstance3D
var shelf_beacon_material: ShaderMaterial

var _fade_tween: Tween = null
var _current_alpha: float = 0.0
var _is_active: bool = false
var _active_showcase_id: int = -1
var _active_tier: int = -1

# Cache of generated curve points for runtime inspection / testing
var current_path_points: PackedVector3Array = PackedVector3Array()

func _ready() -> void:
	add_to_group("wayfinder")
	_setup_trail_mesh()
	_setup_beacons()

func _setup_trail_mesh() -> void:
	trail_mesh_instance = MeshInstance3D.new()
	trail_mesh_instance.name = "TrailMesh"
	trail_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	trail_mesh = ImmediateMesh.new()
	trail_mesh_instance.mesh = trail_mesh

	trail_material = ShaderMaterial.new()
	trail_material.shader = TRAIL_SHADER
	trail_material.set_shader_parameter("alpha_fade", 0.0)
	trail_mesh_instance.material_override = trail_material

	add_child(trail_mesh_instance)

func _setup_beacons() -> void:
	# Ground reticle beacon at showcase approach point
	ground_beacon_instance = MeshInstance3D.new()
	ground_beacon_instance.name = "GroundBeacon"
	ground_beacon_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var quad_floor: QuadMesh = QuadMesh.new()
	quad_floor.size = Vector2(1.8, 1.8)
	quad_floor.orientation = PlaneMesh.FACE_Y
	ground_beacon_instance.mesh = quad_floor

	ground_beacon_material = ShaderMaterial.new()
	ground_beacon_material.shader = BEACON_SHADER
	ground_beacon_material.set_shader_parameter("alpha_fade", 0.0)
	ground_beacon_instance.material_override = ground_beacon_material
	ground_beacon_instance.visible = false
	add_child(ground_beacon_instance)

	# Shelf target beacon (smaller vertical billboard at target slot)
	shelf_beacon_instance = MeshInstance3D.new()
	shelf_beacon_instance.name = "ShelfBeacon"
	shelf_beacon_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var quad_shelf: QuadMesh = QuadMesh.new()
	quad_shelf.size = Vector2(0.55, 0.55)
	quad_shelf.orientation = PlaneMesh.FACE_Z
	shelf_beacon_instance.mesh = quad_shelf

	shelf_beacon_material = ShaderMaterial.new()
	shelf_beacon_material.shader = BEACON_SHADER
	shelf_beacon_material.set_shader_parameter("alpha_fade", 0.0)
	shelf_beacon_instance.material_override = shelf_beacon_material
	shelf_beacon_instance.visible = false
	add_child(shelf_beacon_instance)

## Activates navigational guidance for a specific egg
func activate_guidance_for_egg(egg: EggData, duration: float = -1.0) -> bool:
	if not egg:
		return false

	var showcase_id: int = egg.showcase_id
	var tier: int = egg.dozen_group

	var player = get_tree().get_first_node_in_group("player")
	var from_pos: Vector3
	var from_forward: Vector3

	if player and is_instance_valid(player):
		from_pos = player.global_position
		from_forward = -player.global_transform.basis.z
	else:
		from_pos = global_position
		from_forward = Vector3.FORWARD

	var dur: float = duration if duration > 0.0 else default_duration
	var egg_color: Color = egg.albedo_color if ("albedo_color" in egg) else Color.WHITE
	return activate_guidance(from_pos, from_forward, showcase_id, tier, dur, egg_color)

## Generates and activates a luminous wayfinder trail to target showcase and shelf tier
func activate_guidance(from_pos: Vector3, from_forward: Vector3, showcase_id: int, tier: int = 1, duration: float = -1.0, custom_color: Color = Color.WHITE) -> bool:
	var showcase: ShowcaseUnit = GameManager.get_showcase_unit(showcase_id)
	if not showcase:
		return false

	var dur: float = duration if duration > 0.0 else default_duration
	_active_showcase_id = showcase_id
	_active_tier = tier

	# Determine target approach position and shelf slot position
	var approach_pos: Vector3 = showcase.get_approach_global_position() if showcase.has_method("get_approach_global_position") else showcase.to_global(Vector3(0, 0.05, 1.35))

	# Determine exact target slot
	var target_slot_idx: int = 0
	var count: int = GameManager.showcase_state.get(showcase_id, {}).get(tier, 0)
	target_slot_idx = mini(count, ShowcaseUnit.EGGS_PER_DOZEN - 1)
	var slot_pos: Vector3 = showcase.to_global(showcase.get_slot_local_position(tier, target_slot_idx))

	# Check whether player has Wayfinder Tier 2 (exact slot highlight)
	var has_slot_tier: bool = ProgressManager.get_skill_tier("wayfinder") >= 2

	# Build curve points
	var points: PackedVector3Array = _compute_trajectory(from_pos, from_forward, approach_pos, showcase.global_transform.basis.z, slot_pos, has_slot_tier)
	if points.size() < 2:
		return false

	current_path_points = points

	# Build immediate mesh ribbon
	_generate_ribbon_mesh(points)

	# Configure colors: Golden guide trail with egg accent
	var trail_color: Color = Color(1.0, 0.82, 0.32, 0.95)
	if custom_color != Color.WHITE and custom_color.a > 0.01:
		trail_color = trail_color.lerp(custom_color, 0.35)

	trail_material.set_shader_parameter("line_color", trail_color)
	ground_beacon_material.set_shader_parameter("beacon_color", trail_color)
	shelf_beacon_material.set_shader_parameter("beacon_color", trail_color)

	# Position beacons
	ground_beacon_instance.global_position = approach_pos + Vector3(0, 0.02, 0)
	ground_beacon_instance.visible = true

	if has_slot_tier:
		shelf_beacon_instance.global_position = slot_pos + Vector3(0, 0.05, 0.12)
		shelf_beacon_instance.look_at(approach_pos, Vector3.UP)
		shelf_beacon_instance.visible = true
	else:
		shelf_beacon_instance.visible = false

	# Start luminous fade-in tween
	_start_fade_in(dur)
	_is_active = true
	return true

## Computes a smooth Bézier trajectory from player feet to showcase approach and shelf
func _compute_trajectory(start_pos: Vector3, start_forward: Vector3, approach_pos: Vector3, showcase_front: Vector3, slot_pos: Vector3, include_shelf_climb: bool) -> PackedVector3Array:
	var result: PackedVector3Array = PackedVector3Array()

	# Ground start: slightly above floor
	var p0: Vector3 = Vector3(start_pos.x, 0.035, start_pos.z)
	var forward_horiz: Vector3 = Vector3(start_forward.x, 0, start_forward.z).normalized()
	if forward_horiz.length_squared() < 0.001:
		forward_horiz = Vector3.FORWARD

	var p3: Vector3 = Vector3(approach_pos.x, 0.035, approach_pos.z)
	var dist: float = p0.distance_to(p3)

	var p1: Vector3 = p0 + forward_horiz * (dist * 0.38)
	var showcase_dir: Vector3 = Vector3(showcase_front.x, 0, showcase_front.z).normalized()
	var p2: Vector3 = p3 + showcase_dir * (dist * 0.32)

	var ground_samples: int = sample_points if not include_shelf_climb else int(sample_points * 0.75)
	for i in range(ground_samples):
		var t: float = float(i) / float(ground_samples - 1)
		var pt: Vector3 = _eval_cubic_bezier(p0, p1, p2, p3, t)
		result.append(pt)

	# If Tier 2 unlocked, arc upward to target shelf slot
	if include_shelf_climb:
		var climb_samples: int = sample_points - ground_samples + 1
		var c0: Vector3 = p3
		var c1: Vector3 = p3 - showcase_dir * 0.4 + Vector3(0, (slot_pos.y - p3.y) * 0.3, 0)
		var c2: Vector3 = slot_pos + showcase_dir * 0.2
		var c3: Vector3 = slot_pos

		for i in range(1, climb_samples):
			var t: float = float(i) / float(climb_samples - 1)
			var pt: Vector3 = _eval_cubic_bezier(c0, c1, c2, c3, t)
			result.append(pt)

	return result

func _eval_cubic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var omt: float = 1.0 - t
	return omt * omt * omt * p0 + 3.0 * omt * omt * t * p1 + 3.0 * omt * t * t * p2 + t * t * t * p3

## Rebuilds the ImmediateMesh triangle strip
func _generate_ribbon_mesh(points: PackedVector3Array) -> void:
	trail_mesh.clear_surfaces()
	if points.size() < 2:
		return

	trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, trail_material)

	var total_count: int = points.size()
	for i in range(total_count):
		var pt: Vector3 = points[i]
		var tangent: Vector3

		if i == 0:
			tangent = (points[1] - pt).normalized()
		elif i == total_count - 1:
			tangent = (pt - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()

		var normal: Vector3 = Vector3.UP
		var binormal: Vector3 = tangent.cross(normal).normalized()
		if binormal.length_squared() < 0.001:
			binormal = Vector3.RIGHT

		var half_w: float = ribbon_width * 0.5
		# Taper slightly at the very beginning and very end
		var t: float = float(i) / float(total_count - 1)
		var taper: float = smoothstep(0.0, 0.05, t) * smoothstep(1.0, 0.95, t)
		half_w *= (0.35 + 0.65 * taper)

		var left_v: Vector3 = pt - binormal * half_w
		var right_v: Vector3 = pt + binormal * half_w

		trail_mesh.surface_set_uv(Vector2(0.0, t))
		trail_mesh.surface_add_vertex(left_v)

		trail_mesh.surface_set_uv(Vector2(1.0, t))
		trail_mesh.surface_add_vertex(right_v)

	trail_mesh.surface_end()

func _start_fade_in(duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	# Fast punchy luminous fade in (0.24s)
	_fade_tween.tween_method(_set_alpha_fade, _current_alpha, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Sustain duration
	_fade_tween.tween_interval(duration)
	# Smooth fade out (0.45s)
	_fade_tween.tween_method(_set_alpha_fade, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(clear_guidance)

func _set_alpha_fade(val: float) -> void:
	_current_alpha = val
	if trail_material:
		trail_material.set_shader_parameter("alpha_fade", val)
	if ground_beacon_material:
		ground_beacon_material.set_shader_parameter("alpha_fade", val)
	if shelf_beacon_material:
		shelf_beacon_material.set_shader_parameter("alpha_fade", val)

## Smoothly dismisses current guidance
func dismiss_guidance() -> void:
	if not _is_active:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_alpha_fade, _current_alpha, 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(clear_guidance)

## Instantly clears current guidance
func clear_guidance() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	_set_alpha_fade(0.0)
	if trail_mesh:
		trail_mesh.clear_surfaces()
	if ground_beacon_instance:
		ground_beacon_instance.visible = false
	if shelf_beacon_instance:
		shelf_beacon_instance.visible = false
	current_path_points.clear()
	_is_active = false
	_active_showcase_id = -1
	_active_tier = -1

func is_active() -> bool:
	return _is_active

func get_active_showcase_id() -> int:
	return _active_showcase_id

func get_active_tier() -> int:
	return _active_tier
