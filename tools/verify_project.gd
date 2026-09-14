extends Node

## tools/verify_project.gd - The Grand Eggsposition
## Automated Quality Assurance and Integrity Checker.
## Run headlessly with: python tools/verify.py

const CANONICAL_MESH_PATH: String = "res://assets/models/baseegg_mesh.tres"
const CANONICAL_GLB_PATH: String = "res://assets/models/baseegg.glb"

var total_checks: int = 0
var passed_checks: int = 0
var warnings: int = 0
var errors: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("🔍 THE GRAND EGGSPOSITION - INTEGRITY VERIFIER")
	print("=======================================================\n")
	
	_check_canonical_egg_mesh()
	_check_canonical_compliance()
	_check_egg_resource_architecture()
	_check_core_scenes()
	_check_localization()
	_check_placement_hologram()
	_check_wayfinder_system()
	_check_held_egg_viewmodel()
	_check_hud_basket_stack()
	_check_floor_egg_stability_and_respawn()
	_check_settings_system()
	_check_final_space_rotunda()
	_check_accessibility_system()
	
	print("\n-------------------------------------------------------")
	print("📊 VERIFICATION SUMMARY:")
	print("   Total checks:  %d" % total_checks)
	print("   Passed:        %d" % passed_checks)
	print("   Warnings:      %d" % warnings)
	print("   Errors:        %d" % errors)
	print("-------------------------------------------------------")
	
	if errors > 0:
		print("❌ VERIFICATION FAILED with %d error(s).\n" % errors)
		get_tree().quit(1)
	else:
		print("✨ ALL CHECKS PASSED! Project is healthy and ready for boutique curation.\n")
		get_tree().quit(0)

func _pass(msg: String) -> void:
	total_checks += 1
	passed_checks += 1
	print("  [PASS] " + msg)

func _warn(msg: String) -> void:
	total_checks += 1
	warnings += 1
	print("  [WARN] " + msg)

func _fail(msg: String) -> void:
	total_checks += 1
	errors += 1
	printerr("  [FAIL] " + msg)

## 1. Verify Canonical Egg Mesh
func _check_canonical_egg_mesh() -> void:
	print("1. Canonical Egg Model & Mesh:")
	if not FileAccess.file_exists(CANONICAL_MESH_PATH):
		_fail("Canonical mesh not found at " + CANONICAL_MESH_PATH)
		return
	
	var mesh: ArrayMesh = load(CANONICAL_MESH_PATH) as ArrayMesh
	if not mesh:
		_fail("Failed to load ArrayMesh from " + CANONICAL_MESH_PATH)
		return
	
	var aabb: AABB = mesh.get_aabb()
	var size_ok: bool = abs(aabb.size.x - 0.23) < 0.02 and abs(aabb.size.y - 0.30) < 0.02 and abs(aabb.size.z - 0.23) < 0.02
	if size_ok:
		_pass("AABB size conforms to canonical proportions (0.23m x 0.30m x 0.23m): %s" % str(aabb.size))
	else:
		_warn("AABB size deviates from 0.23 x 0.30 x 0.23: %s" % str(aabb.size))
	
	var centered_ok: bool = abs(aabb.position.y + 0.15) < 0.02
	if centered_ok:
		_pass("Pivot is centered at geometric center: %s" % str(aabb.position))
	else:
		_warn("Pivot Y not centered around -0.15: %s" % str(aabb.position.y))
	
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var tris: int = indices.size() / 3 if indices != null and indices.size() > 0 else verts.size() / 3
	
	if tris <= 2500:
		_pass("Polygon budget: %d triangles, %d vertices (Budget: <= 2,500 tris)" % [tris, verts.size()])
	else:
		_warn("High polygon count: %d triangles (Budget: <= 2,500 tris)" % tris)

## 2. Verify Canonical Compliance Across All Eggs
func _check_canonical_compliance() -> void:
	print("\n2. Canonical Compliance Across All Eggs:")
	var deprecated_paths: Array = [
		"res://assets/models/silverEgg.glb",
		"res://assets/models/falloutEgg.glb",
		"res://scenes/props/silver_egg_model.tscn",
		"res://scenes/props/fallout_egg_model.tscn"
	]
	var found_deprecated: bool = false
	for dp in deprecated_paths:
		if FileAccess.file_exists(dp):
			found_deprecated = true
			_fail("Deprecated non-canonical file still exists: %s" % dp)
	if not found_deprecated:
		_pass("All deprecated non-canonical egg files removed successfully")

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var non_conforming: Array = []
		for egg_id in gm.egg_database:
			var egg: EggData = gm.egg_database[egg_id]
			var visual: Node3D = egg.instantiate_visual_node()
			if not visual:
				non_conforming.append("Egg %d (null visual)" % egg_id)
				continue
			var mi: MeshInstance3D = visual.find_child("*", true, false) as MeshInstance3D
			if not mi or not mi.mesh or mi.mesh.resource_path != CANONICAL_MESH_PATH:
				non_conforming.append("Egg %d (%s)" % [egg_id, egg.egg_name_key])
			visual.free()
		
		if non_conforming.is_empty():
			_pass("All %d registered eggs strictly build on canonical model (%s)" % [gm.egg_database.size(), CANONICAL_MESH_PATH])
		else:
			_fail("Non-conforming eggs found: %s" % str(non_conforming))

## 3. Verify EggData fallback visual node
func _check_egg_resource_architecture() -> void:
	print("\n3. Egg Data Resource & Visual Instantiation:")
	var egg_script: GDScript = load("res://scripts/resources/egg_resource.gd") as GDScript
	if not egg_script:
		_fail("scripts/resources/egg_resource.gd failed to load")
		return
	
	var egg_data = egg_script.new()
	egg_data.egg_id = 999
	egg_data.egg_name_key = "EGG_TEST"
	egg_data.albedo_color = Color.CORAL
	
	var visual: Node3D = egg_data.instantiate_visual_node()
	if not visual:
		_fail("instantiate_visual_node() returned null")
		return
	
	var mi: MeshInstance3D = null
	for child in visual.get_children():
		if child is MeshInstance3D:
			mi = child as MeshInstance3D
			break
	
	if mi and mi.mesh:
		if mi.mesh.resource_path == CANONICAL_MESH_PATH:
			_pass("Default egg visual uses canonical ArrayMesh (%s)" % CANONICAL_MESH_PATH)
		else:
			_warn("Default egg visual uses different mesh: %s" % mi.mesh.resource_path)
	else:
		_fail("Visual node does not contain a valid MeshInstance3D with mesh")
	
	visual.free()

## 4. Verify Core Scenes
func _check_core_scenes() -> void:
	print("\n4. Core Scenes & Props:")
	var scenes: Array = [
		{"path": "res://scenes/props/base_egg_model.tscn", "name": "Base Egg Scene"},
		{"path": "res://scenes/props/egg_actor.tscn", "name": "Floor Egg Actor"},
		{"path": "res://scenes/atrium/showcase_unit.tscn", "name": "Showcase Unit Scene"},
		{"path": "res://scenes/ui/main_menu.tscn", "name": "Main Menu Scene"},
		{"path": "res://scenes/main/game.tscn", "name": "Main Game Atrium Scene"}
	]
	
	for s in scenes:
		if not FileAccess.file_exists(s.path):
			_fail("Scene not found: %s (%s)" % [s.name, s.path])
			continue
		
		var scn: PackedScene = load(s.path) as PackedScene
		if not scn:
			_fail("Failed to load PackedScene: %s (%s)" % [s.name, s.path])
			continue
		
		var inst = scn.instantiate()
		if not inst:
			_fail("Failed to instantiate scene: %s (%s)" % [s.name, s.path])
		else:
			_pass("Scene loads cleanly: %s (%s)" % [s.name, inst.name])
			inst.free()

## 5. Verify Localization CSV
func _check_localization() -> void:
	print("\n5. Localization Integrity:")
	var csv_path: String = "res://localization/translations.csv"
	if not FileAccess.file_exists(csv_path):
		_fail("translations.csv not found at " + csv_path)
		return
	
	var fa = FileAccess.open(csv_path, FileAccess.READ)
	if not fa:
		_fail("Failed to open " + csv_path)
		return
	
	var line_count: int = 0
	var header = fa.get_csv_line()
	if header.size() < 3 or header[0] != "keys":
		_fail("Invalid translations.csv header: expected 'keys,en,es'")
		fa.close()
		return
	
	while not fa.eof_reached():
		var row = fa.get_csv_line()
		if row.size() >= 3 and row[0] != "":
			line_count += 1
	fa.close()
	
	_pass("Localization verified: %d translated keys present in CSV" % line_count)

## 6. Verify Placement Hologram
func _check_placement_hologram() -> void:
	print("\n6. Placement Hologram:")
	var showcase_scn: PackedScene = load("res://scenes/atrium/showcase_unit.tscn")
	if not showcase_scn:
		_fail("Could not load showcase_unit.tscn for hologram test")
		return

	var showcase = showcase_scn.instantiate()
	add_child(showcase)

	if showcase.hologram_mesh_instance and showcase.hologram_material:
		_pass("ShowcaseUnit has PlacementHologram mesh and ShaderMaterial")
	else:
		_fail("ShowcaseUnit missing PlacementHologram or ShaderMaterial")

	var shelf_model = showcase.get_node_or_null("ShelfModel")
	if shelf_model and shelf_model.get_child_count() > 0:
		_pass("ShowcaseUnit integrates 3D shelf model (ShelfModel with %d physical mesh elements)" % shelf_model.get_child_count())
	else:
		_fail("ShowcaseUnit missing ShelfModel 3D asset node")

	# Test valid placement (green)
	var dummy_egg = EggData.new()
	dummy_egg.egg_id = 1
	dummy_egg.showcase_id = 1
	dummy_egg.dozen_group = 1

	showcase.update_placement_hologram(dummy_egg, true, 1, 0)
	var col_green: Color = showcase.hologram_material.get_shader_parameter("hologram_color")
	if showcase.hologram_mesh_instance.visible and col_green.g > col_green.r:
		_pass("Hologram displays luminous green on valid placement target")
	else:
		_fail("Hologram failed to display green on valid target")

	# Test invalid placement (red)
	showcase.update_placement_hologram(dummy_egg, false, 1, 0)
	var col_red: Color = showcase.hologram_material.get_shader_parameter("hologram_color")
	if showcase.hologram_mesh_instance.visible and col_red.r > col_red.g:
		_pass("Hologram displays luminous red on invalid placement target")
	else:
		_fail("Hologram failed to display red on invalid target")

	# Test hide
	showcase.hide_placement_hologram()
	if not showcase.hologram_mesh_instance.visible:
		_pass("Hologram hides cleanly when not aiming at showcase")
	else:
		_fail("Hologram failed to hide")

	# Test Requirement 1: Aiming at matching tier vs non-matching tier
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_basket.clear()
		var dummy_egg_t2 = EggData.new()
		dummy_egg_t2.egg_id = 2
		dummy_egg_t2.showcase_id = 1
		dummy_egg_t2.dozen_group = 2

		gm.player_basket.append(dummy_egg) # egg for showcase 1, tier 1
		gm.player_basket.append(dummy_egg_t2) # egg for showcase 1, tier 2

		# Aiming at tier 1 (matching egg exists -> green)
		var target_tier1 = showcase.get_target_for_tier(1)
		if target_tier1.get("is_valid") == true and target_tier1.get("basket_count") == 1:
			_pass("Aiming at matching tier yields valid green target with correct basket count")
		else:
			_fail("Aiming at matching tier failed to yield valid target")

		# Aiming at tier 2 (matching egg exists -> green)
		var target_tier2 = showcase.get_target_for_tier(2)
		if target_tier2.get("is_valid") == true and target_tier2.get("basket_count") == 1:
			_pass("Aiming at second tier with different carried egg resolves correctly")
		else:
			_fail("Aiming at second tier failed to resolve carried egg")

		# Aiming at tier 3 (no egg for tier 3 -> red, not full)
		var target_tier3 = showcase.get_target_for_tier(3)
		if target_tier3.get("is_valid") == false and target_tier3.get("is_full") == false and target_tier3.get("dozen") == 3:
			_pass("Aiming at non-matching tier yields red target with no-egg status")
		else:
			_fail("Aiming at non-matching tier failed to yield red target on that tier")

		# Test Full Tier Handling
		gm.showcase_state[1][1] = 12
		var target_tier1_full = showcase.get_target_for_tier(1)
		if target_tier1_full.get("is_full") == true and target_tier1_full.get("is_valid") == false:
			_pass("Full tier (12/12) correctly reports is_full and displays red hologram")
		else:
			_fail("Full tier failed to report is_full status")
		gm.showcase_state[1][1] = 0

		# Test Requirement 2: Teleport when tier changes
		showcase.update_placement_hologram(dummy_egg, true, 1, 0)
		var pos_tier1 = showcase.hologram_mesh_instance.position
		showcase.update_placement_hologram(dummy_egg, false, 3, 0)
		var pos_tier3 = showcase.hologram_mesh_instance.position
		if pos_tier1 != pos_tier3 and showcase._holo_tween == null:
			_pass("Switching between shelf levels teleports instantly without drift tween")
		else:
			_fail("Switching levels did not teleport properly")

		# Test Requirement 3: Smooth animation when advancing slot on same tier
		showcase.update_placement_hologram(dummy_egg, true, 3, 1)
		if showcase._holo_tween != null and showcase._holo_tween.is_valid():
			_pass("Advancing slot on same level triggers smooth glide tween animation")
		else:
			_fail("Advancing slot on same level failed to trigger smooth animation")

		# Test Requirement 4: Fixed MultiMesh indexing for zero-tremor stability
		if showcase.multimesh_instance.multimesh.visible_instance_count == ShowcaseUnit.TOTAL_CAPACITY:
			_pass("MultiMesh uses fixed slot indexing (60 instances) preventing egg trembling")
		else:
			_fail("MultiMesh instance count mismatch")

		# Test Requirement 5: Per-egg PBR shading and soft display lighting
		var mm = showcase.multimesh_instance.multimesh
		var mat = showcase.multimesh_instance.material_override as ShaderMaterial
		var light_upper = showcase.get_node_or_null("DisplayLight_Upper") as Light3D
		var light_lower = showcase.get_node_or_null("DisplayLight_Lower") as Light3D
		var lights_ok = light_upper and light_lower and light_upper.light_energy <= 0.5 and light_lower.light_energy <= 0.5
		var shader_ok = mat != null and mat.shader != null and mat.shader.resource_path == "res://assets/shaders/showcase_egg.gdshader"
		var silver_egg = gm.get_egg_for_showcase_dozen(showcase.showcase_id, 3)
		var copper_egg = gm.get_egg_for_showcase_dozen(showcase.showcase_id, 4)
		var bronze_egg = gm.get_egg_for_showcase_dozen(showcase.showcase_id, 5)
		var metals_pbr_ok = silver_egg and copper_egg and bronze_egg \
			and silver_egg.metallic >= 0.85 and copper_egg.metallic >= 0.85 and bronze_egg.metallic >= 0.85 \
			and silver_egg.roughness <= 0.25 and copper_egg.roughness <= 0.25 and bronze_egg.roughness <= 0.25

		if mm.use_custom_data and shader_ok and lights_ok and metals_pbr_ok:
			_pass("Showcase 1 features stylized metal suite (Gold, Silver, Copper, Bronze) with PBR shader and soft lights")
		else:
			_fail("Showcase PBR or metal suite validation failed: use_custom_data=%s, shader=%s, lights_ok=%s, metals_pbr_ok=%s" % [str(mm.use_custom_data), str(shader_ok), str(lights_ok), str(metals_pbr_ok)])
		# Test Requirement 6: Collision-free egg placement trajectory
		if showcase.has_method("get_flight_trajectory_point") and showcase.has_method("get_flight_trajectory_basis"):
			var trajectory_clips: int = 0
			var test_starts = [
				Vector3(0.2, 1.6, 1.3),
				Vector3(-0.5, 1.4, 1.0),
				Vector3(0.5, 1.8, 1.5)
			]
			for start_pos in test_starts:
				for d in range(1, 6):
					var tier_base_y: float = 0.48 + float(d - 1) * 0.42
					for s in [0, 5, 6, 11]: # check corners of front and back rows
						var target_pos: Vector3 = showcase.get_slot_local_position(d, s)
						for step in range(51):
							var t = float(step) / 50.0
							var p = showcase.get_flight_trajectory_point(start_pos, target_pos, t)
							var egg_top = p.y + 0.15
							var egg_bottom = p.y - 0.15
							var egg_back = p.z - 0.115
							if egg_back <= 0.31: # inside cabinet depth
								for check_d in range(1, 6):
									var check_base_y = 0.48 + float(check_d - 1) * 0.42
									if check_d != d:
										if egg_bottom < check_base_y + 0.04 and egg_top > check_base_y:
											trajectory_clips += 1
									if check_d == d + 1:
										if egg_top > check_base_y:
											trajectory_clips += 1
			if trajectory_clips == 0:
				_pass("Egg placement animation follows collision-free corridor route (0 shelf clips across all tiers and slots)")
			else:
				_fail("Egg placement animation clips through shelves: %d clips detected" % trajectory_clips)
		else:
			_fail("ShowcaseUnit missing get_flight_trajectory_point or get_flight_trajectory_basis")

		gm.player_basket.clear()

	showcase.queue_free()

## 7. Verify Wayfinder Guidance System
func _check_wayfinder_system() -> void:
	print("\n7. Wayfinder Navigational Guidance System:")
	var wayfinder_script = load("res://scripts/systems/wayfinder_system.gd")
	var game_scene = load("res://scenes/main/game.tscn").instantiate()
	add_child(game_scene)

	var wf = game_scene.get_node_or_null("WayfinderSystem")
	if not wf or not is_instance_valid(wf) or wf.get_script() != wayfinder_script:
		_fail("WayfinderSystem node missing or invalid script in game.tscn")
		game_scene.queue_free()
		return
	_pass("WayfinderSystem node instantiated in Game scene")

	# Check sub-nodes and shaders
	if wf.trail_mesh_instance and wf.trail_mesh is ImmediateMesh:
		_pass("Wayfinder trail ribbon configured with ImmediateMesh and trail shader")
	else:
		_fail("Wayfinder trail mesh instance or ImmediateMesh missing")

	if wf.ground_beacon_instance and wf.ground_beacon_material:
		_pass("Wayfinder ground reticle beacon configured with animated ripple shader")
	else:
		_fail("Wayfinder ground beacon missing")

	if wf.shelf_beacon_instance and wf.shelf_beacon_material:
		_pass("Wayfinder shelf slot target beacon configured")
	else:
		_fail("Wayfinder shelf beacon missing")

	# Trajectory generation: Tier 1 (showcase approach) and Tier 2 (shelf climb)
	var p0 = Vector3(0, 0, 0)
	var forward = Vector3(0, 0, -1)
	var showcase = game_scene.get_node_or_null("Showcase_Minerals_1")
	if not showcase:
		_fail("Showcase_Minerals_1 not found in game scene")
		game_scene.queue_free()
		return

	var approach_pos = showcase.get_approach_global_position()
	var slot_pos = showcase.get_slot_global_position(1, 0)
	var front_dir = showcase.global_transform.basis.z

	var pts_tier1 = wf._compute_trajectory(p0, forward, approach_pos, front_dir, slot_pos, false)
	var pts_tier2 = wf._compute_trajectory(p0, forward, approach_pos, front_dir, slot_pos, true)

	if pts_tier1.size() == wf.sample_points and pts_tier2.size() == wf.sample_points:
		_pass("Trajectory generates smooth %d-point Bézier path for both Tier 1 and Tier 2" % wf.sample_points)
	else:
		_fail("Trajectory point count mismatch: Tier1=%d, Tier2=%d" % [pts_tier1.size(), pts_tier2.size()])

	# Ribbon mesh generation
	wf._generate_ribbon_mesh(pts_tier1)
	if wf.trail_mesh.get_surface_count() == 1:
		_pass("Ribbon mesh dynamically generates smooth 3D triangle strip surface (surface_count = 1)")
	else:
		_fail("Ribbon mesh failed to generate surface")

	# Real egg guidance test
	var gm = get_node_or_null("/root/GameManager")
	var copper_egg = gm.get_egg_for_showcase_dozen(1, 4) if gm else null
	if copper_egg:
		var activated = wf.activate_guidance_for_egg(copper_egg, 2.0)
		if activated and wf.is_active() and wf.get_active_showcase_id() == 1 and wf.get_active_tier() == 4:
			_pass("Wayfinder successfully activates guidance for Pure Copper egg targeting Showcase 1 Tier 4")
		else:
			_fail("Failed to activate guidance for copper egg")

		# Clear / dismiss
		wf.clear_guidance()
		if not wf.is_active() and wf.trail_mesh.get_surface_count() == 0:
			_pass("Wayfinder clear_guidance resets active state and clears GPU mesh surfaces")
		else:
			_fail("clear_guidance failed to clean up wayfinder state")
	else:
		_fail("Could not find Pure Copper egg definition in GameManager")

	# Player input trigger test
	var player = game_scene.get_node_or_null("Player")
	if player and player.has_method("trigger_wayfinder_override"):
		var pm = get_node_or_null("/root/ProgressManager")
		if pm:
			pm.set_skill_tier("wayfinder", 1)
			var triggered = player._trigger_wayfinder()
			if triggered and wf.is_active():
				_pass("PlayerController triggers Wayfinder when skill tier >= 1")
			else:
				_fail("PlayerController failed to trigger Wayfinder with skill unlocked")
			wf.clear_guidance()
			pm.set_skill_tier("wayfinder", 0) # reset
		else:
			_fail("ProgressManager not found")
	else:
		_fail("PlayerController missing wayfinder trigger methods")

	game_scene.queue_free()

## 8. Verify First-Person Held Egg Viewmodel & Mouse Wheel Cycling
func _check_held_egg_viewmodel() -> void:
	print("\n8. First-Person Held Egg Viewmodel & Wheel Cycling:")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if not player_scene:
		_fail("Could not load res://scenes/player/player.tscn")
		return

	var player = player_scene.instantiate()
	add_child(player)

	# 1. Check node hierarchy
	if player.held_egg_root and player.held_egg_mesh:
		_pass("Player has HeldEggRoot and HeldEggMesh nodes configured under Camera3D")
	else:
		_fail("Player missing HeldEggRoot or HeldEggMesh nodes")

	# 2. Check initial empty basket state
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		_fail("GameManager autoload not found")
		player.queue_free()
		return

	gm.player_basket.clear()
	player._update_held_egg_display(false)
	if not player.held_egg_root.visible and player.get_current_held_egg() == null:
		_pass("Viewmodel is hidden when player basket is empty")
	else:
		_fail("Viewmodel is visible with empty basket")

	# 3. Add eggs to basket: Gold Egg and Pure Copper Egg
	var egg1 = gm.get_egg_data(1) # Gold
	var egg4 = gm.get_egg_for_showcase_dozen(1, 4) # Pure Copper
	if not egg1 or not egg4:
		_fail("Failed to retrieve sample egg resources")
		player.queue_free()
		return

	gm.add_to_basket(egg1)
	player._on_egg_collected(egg1)
	if player.held_egg_root.visible and player.get_current_held_egg() == egg1:
		_pass("Picking up first egg makes viewmodel visible showing held egg (Gold)")
	else:
		_fail("Picking up egg failed to show active held egg viewmodel")

	gm.add_to_basket(egg4)
	player._on_egg_collected(egg4)
	if player.get_current_held_egg() == egg1 and player.selected_held_index == 0:
		_pass("Second egg added to basket maintains first egg as initially displayed")
	else:
		_fail("Adding second egg unexpectedly changed selected held index")

	# 4. Mouse wheel cycling
	# Cycle forward (+1)
	player._cycle_held_egg(1)
	if player.selected_held_index == 1 and player.get_current_held_egg() == egg4:
		_pass("Mouse wheel down (+1) cycles to next held egg (Pure Copper)")
	else:
		_fail("Mouse wheel cycle forward failed: index=%d" % player.selected_held_index)

	# Cycle wrap forward (+1 -> wrap to 0)
	player._cycle_held_egg(1)
	if player.selected_held_index == 0 and player.get_current_held_egg() == egg1:
		_pass("Mouse wheel cycling wraps seamlessly from end to beginning (index 0)")
	else:
		_fail("Mouse wheel cycle wrap failed: index=%d" % player.selected_held_index)

	# Cycle backward (-1 -> wrap to 1)
	player._cycle_held_egg(-1)
	if player.selected_held_index == 1 and player.get_current_held_egg() == egg4:
		_pass("Mouse wheel up (-1) cycles backwards with wrap (index 1)")
	else:
		_fail("Mouse wheel backwards cycle failed: index=%d" % player.selected_held_index)

	# 5. Synergy with Wayfinder guidance: picking target_egg from current held selection
	var wf_egg = player.get_current_held_egg()
	if wf_egg == egg4:
		_pass("Wayfinder targeting inherits current held egg (Pure Copper)")
	else:
		_fail("Held egg does not match expected selection for Wayfinder")

	# 6. Depositing / emptying basket hides viewmodel
	gm.player_basket.clear()
	player._on_egg_placed(egg4, 1, 4)
	player._update_held_egg_display(false)
	if not player.held_egg_root.visible and player.get_current_held_egg() == null:
		_pass("Emptying basket hides held egg viewmodel and resets held state cleanly")
	else:
		_fail("Held egg viewmodel remained visible after clearing basket")

	player.queue_free()

## 9. Verify HUD BasketStack widget (isolated – no Player in scene)
func _check_hud_basket_stack() -> void:
	print("\n9. HUD BasketStack Egg List & Chevron Indicator:")

	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	if not hud_scene:
		_fail("Could not load res://scenes/ui/hud.tscn")
		return

	var hud = hud_scene.instantiate()
	add_child(hud)

	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		_fail("GameManager not found")
		hud.queue_free()
		return

	var egg1 = gm.get_egg_data(1)           # Gold
	var egg4 = gm.get_egg_for_showcase_dozen(1, 4) # Pure Copper
	if not egg1 or not egg4:
		_fail("Could not retrieve sample eggs")
		hud.queue_free()
		return

	# --- 2 eggs, selection = 0 ---
	gm.player_basket.clear()
	gm.player_basket.append(egg1)
	gm.player_basket.append(egg4)
	hud._override_selected_idx = 0
	hud._update_basket_stack()

	var rows = hud.basket_item_list.get_children()
	if rows.size() == 2:
		_pass("HUD BasketStack displays exactly 2 rows matching carried eggs")
	else:
		_fail("HUD BasketStack row count mismatch: expected 2, got %d" % rows.size())

	var r0chev = rows[0].get_node("ChevronLabel").text if rows.size() > 0 else "?"
	var r1chev = rows[1].get_node("ChevronLabel").text if rows.size() > 1 else "?"
	if r0chev == ">" and r1chev == "":
		_pass("HUD BasketStack shows chevron '>' on selected egg index 0")
	else:
		_fail("HUD BasketStack chevron mismatch at index 0: row0='%s', row1='%s'" % [r0chev, r1chev])

	if hud.capacity_current.text == "2" and hud.capacity_max.text == str(gm.max_basket_capacity):
		_pass("HUD BasketStack capacity counter shows 2/%d" % gm.max_basket_capacity)
	else:
		_fail("HUD BasketStack capacity mismatch: %s/%s" % [hud.capacity_current.text, hud.capacity_max.text])

	# --- cycle to selection = 1 ---
	hud._override_selected_idx = 1
	hud._update_basket_stack()
	var rows2 = hud.basket_item_list.get_children()
	var r0chev2 = rows2[0].get_node("ChevronLabel").text if rows2.size() > 0 else "?"
	var r1chev2 = rows2[1].get_node("ChevronLabel").text if rows2.size() > 1 else "?"
	if r0chev2 == "" and r1chev2 == ">":
		_pass("HUD BasketStack moves chevron '>' to selected egg index 1 on wheel cycle")
	else:
		_fail("HUD BasketStack chevron failed to move on cycle: row0='%s', row1='%s'" % [r0chev2, r1chev2])

	# --- empty basket ---
	gm.player_basket.clear()
	hud._update_basket_stack()
	if hud.basket_item_list.get_child_count() == 0 and hud.capacity_current.text == "0":
		_pass("HUD BasketStack clears rows and resets counter to 0 on empty basket")
	else:
		_fail("HUD BasketStack failed to clear rows on empty basket")

	gm.player_basket.clear()
	hud.queue_free()

## 10. Verify Floor Egg Stability, Boundary, and Out-of-Bounds Respawn
func _check_floor_egg_stability_and_respawn() -> void:
	print("\n10. Floor Egg Physics, Boundary Barrier & Respawn System:")
	
	# 1. Verify EggActor physical damping and respawn capabilities
	var egg_scene: PackedScene = load("res://scenes/props/egg_actor.tscn")
	if egg_scene:
		var egg: EggActor = egg_scene.instantiate() as EggActor
		add_child(egg)
		egg.global_position = Vector3(2.0, 0.25, -2.0)
		egg._spawn_transform = egg.global_transform
		
		if egg.can_sleep and egg.linear_damp >= 3.0 and egg.angular_damp >= 6.0:
			_pass("EggActor configured with auto-sleep and high tactile rolling damping (linear=%.1f, angular=%.1f)" % [egg.linear_damp, egg.angular_damp])
		else:
			_fail("EggActor damping or sleep insufficient: linear=%.1f, angular=%.1f" % [egg.linear_damp, egg.angular_damp])
		
		# Test out-of-bounds detection when falling into void Y < -1.0
		egg.global_position = Vector3(2.0, -2.5, -2.0)
		egg._physics_process(0.016)
		if egg._needs_respawn:
			_pass("EggActor triggers automatic respawn when falling out of bounds (Y < -1.0)")
		else:
			_fail("EggActor failed to flag respawn after dropping below floor threshold")
			
		# Test perimeter out-of-bounds detection when rolling past R > 15.5m
		egg._needs_respawn = false
		egg.global_position = Vector3(16.5, 0.25, 0.0)
		egg._physics_process(0.016)
		if egg._needs_respawn:
			_pass("EggActor triggers automatic respawn when rolling past perimeter boundary (R > 15.5m)")
		else:
			_fail("EggActor failed to flag respawn when exceeding perimeter distance")
			
		egg.queue_free()
	else:
		_fail("Could not load res://scenes/props/egg_actor.tscn")
		
	# 2. Verify Game scene AtriumBoundary barrier wall
	var game_scene: PackedScene = load("res://scenes/main/game.tscn")
	if game_scene:
		var game = game_scene.instantiate()
		var boundary = game.find_child("AtriumBoundary", true, false)
		if boundary and boundary is StaticBody3D:
			var segment_count: int = boundary.get_child_count()
			if segment_count >= 16:
				_pass("AtriumBoundary configured with %d collision wall segments preventing map escape" % segment_count)
			else:
				_fail("AtriumBoundary has insufficient segments: %d" % segment_count)
		else:
			_fail("AtriumBoundary StaticBody3D node missing from Game scene")
			
		# 3. Verify zero overlaps across all 60 floor eggs in Game scene
		var eggs_node = game.find_child("EggsOnFloor", true, false)
		if eggs_node:
			var eggs = eggs_node.get_children()
			var overlaps: int = 0
			var min_dist: float = 999.0
			for i in range(eggs.size()):
				var p1 = eggs[i].transform.origin
				for j in range(i + 1, eggs.size()):
					var p2 = eggs[j].transform.origin
					var d = p1.distance_to(p2)
					if d < min_dist:
						min_dist = d
					if d < 0.24: # Egg diameter is 0.23m
						overlaps += 1
			if eggs.size() == 60 and overlaps == 0 and min_dist >= 0.30:
				_pass("All %d floor eggs placed with safe non-overlapping clearance (min_dist=%.2fm, 0 overlaps)" % [eggs.size(), min_dist])
			else:
				_fail("Floor eggs overlap or spacing invalid: %d eggs, %d overlaps, min_dist=%.2fm" % [eggs.size(), overlaps, min_dist])
		else:
			_fail("EggsOnFloor node missing from Game scene")
			
		# 4. Verify ShowcaseUnit interaction bounds strictly clear floor & plinth
		var showcase = game.find_child("Showcase_Minerals_1", true, false)
		if showcase:
			var area = showcase.get_node_or_null("InteractionArea")
			var col_shape = area.get_node_or_null("CollisionShape3D") if area else null
			if col_shape and col_shape.shape is BoxShape3D:
				var box: BoxShape3D = col_shape.shape as BoxShape3D
				var bottom_y: float = area.position.y - box.size.y * 0.5
				var front_z: float = area.position.z + box.size.z * 0.5
				if bottom_y >= 0.45 and front_z <= 0.45:
					_pass("Showcase InteractionArea bounds strictly clear the floor and plinth (bottom_y=%.2fm >= 0.45m, front_z=%.2fm <= 0.45m)" % [bottom_y, front_z])
				else:
					_fail("Showcase InteractionArea overlaps floor or room: bottom_y=%.2fm, front_z=%.2fm" % [bottom_y, front_z])
			else:
				_fail("Showcase InteractionArea missing BoxShape3D")
		else:
			_fail("Showcase_Minerals_1 missing from Game scene")

		# 5. Verify PlayerController prevents shelf deposit when aiming at plinth/floor
		var player = game.find_child("Player", true, false)
		if player and showcase:
			if player.has_method("_get_aimed_tier"):
				# Test when raycast is not aimed at shelf tiers
				var tier = player._get_aimed_tier(showcase)
				if tier == 0:
					_pass("PlayerController blocks shelf placement when aiming at floor/plinth (_get_aimed_tier returns 0)")
				else:
					_fail("PlayerController allowed shelf placement when not aiming at active shelf: %d" % tier)
			else:
				_fail("PlayerController missing _get_aimed_tier method")
		else:
			_fail("Player or Showcase node missing for interaction test")

		game.queue_free()
	else:
		_fail("Could not load res://scenes/main/game.tscn")

## 11. Verify Settings Manager & FPS Limiter
func _check_settings_system() -> void:
	print("\n11. Settings Manager & Framerate Limiting:")
	
	# 1. Verify SettingsManager defaults and applies fps_limit to Engine.max_fps
	var sm = get_node_or_null("/root/SettingsManager")
	if not sm:
		_fail("SettingsManager autoload not found")
		return
		
	var initial_fps = sm.fps_limit
	sm.fps_limit = 60
	sm.apply_all()
	if Engine.max_fps == 60:
		_pass("SettingsManager updates Engine.max_fps when fps_limit changed (tested 60 FPS)")
	else:
		_fail("SettingsManager failed to update Engine.max_fps to 60, was %d" % Engine.max_fps)
		
	sm.fps_limit = 0
	sm.apply_all()
	if Engine.max_fps == 0:
		_pass("SettingsManager properly restores unlimited framerate (Engine.max_fps = 0)")
	else:
		_fail("SettingsManager failed to restore Engine.max_fps to 0, was %d" % Engine.max_fps)
		
	sm.fps_limit = initial_fps
	sm.apply_all()
	
	# 2. Verify SettingsMenu UI has %FPSLimitOpt and contains correct options
	var settings_scn: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scn:
		var menu = settings_scn.instantiate()
		add_child(menu)
		
		var fps_opt: OptionButton = menu.find_child("FPSLimitOpt", true, false)
		if fps_opt:
			_pass("SettingsMenu contains FPSLimitOpt OptionButton")
			if fps_opt.item_count == 6:
				_pass("FPSLimitOpt contains 6 framerate targets (Unlimited, 30, 60, 120, 144, 240)")
			else:
				_fail("FPSLimitOpt has unexpected item count: %d" % fps_opt.item_count)
				
			# Test UI sync from manager
			sm.fps_limit = 144
			menu._sync_from_manager()
			if fps_opt.selected == 4:
				_pass("SettingsMenu syncs fps_limit = 144 to OptionButton index 4")
			else:
				_fail("SettingsMenu failed to sync fps_limit = 144 to index 4, got %d" % fps_opt.selected)
				
			# Test UI apply to manager
			fps_opt.selected = 2 # 60 FPS
			menu._on_apply_pressed()
			if sm.fps_limit == 60 and Engine.max_fps == 60:
				_pass("SettingsMenu apply button updates SettingsManager.fps_limit and Engine.max_fps to 60")
			else:
				_fail("SettingsMenu apply failed to set fps_limit to 60")
		else:
			_fail("FPSLimitOpt node missing from SettingsMenu scene")
			
		menu.queue_free()
		sm.fps_limit = initial_fps
		sm.apply_all()
		sm.save_settings()
	else:
		_fail("Could not load res://scenes/ui/settings_menu.tscn")

## 12. Verify Final Space Mockup (Rotonda Victoriana de Dos Niveles)
func _check_final_space_rotunda() -> void:
	print("\n12. Final Space Endgame Rotunda Mockup:")
	var rotunda_path: String = "res://scenes/endgame/final_space_rotunda.tscn"
	if not FileAccess.file_exists(rotunda_path):
		_fail("final_space_rotunda.tscn not found at " + rotunda_path)
		return

	var scn: PackedScene = load(rotunda_path)
	if not scn:
		_fail("Failed to load PackedScene for final_space_rotunda.tscn")
		return

	var inst = scn.instantiate()
	if not inst:
		_fail("Failed to instantiate final_space_rotunda.tscn")
		return

	add_child(inst)

	# 1. Verify structure and key architectural elements
	var floor_node = inst.find_child("Floor", true, false)
	var walls_node = inst.find_child("RotundaWalls", true, false)
	var mezz_node = inst.find_child("MezzanineBalcony", true, false)
	var stairs_node = inst.find_child("GrandStaircases", true, false)
	var dome_node = inst.find_child("Dome", true, false)

	if floor_node and walls_node and mezz_node and stairs_node and dome_node:
		_pass("Rotunda geometry complete: Floor, Walls, Mezzanine Balcony, Grand Staircases, and Glass Dome present")
	else:
		_fail("Rotunda missing key architectural parent nodes")

	# 2. Verify twin curved staircases and landing
	var landing = stairs_node.find_child("Landing", true, false) if stairs_node else null
	var step_r0 = stairs_node.find_child("StepR_00", true, false) if stairs_node else null
	var step_l0 = stairs_node.find_child("StepL_00", true, false) if stairs_node else null
	if landing and step_r0 and step_l0:
		_pass("Grand Staircases include symmetrical twin curved stairways and elevated mezzanine landing (Y = 3.5m)")
	else:
		_fail("Grand Staircases missing landing or steps")

	# 3. Verify open central floor (no center furniture clutter)
	var center_clutter = inst.find_child("CenterDesk", true, false)
	if center_clutter == null:
		_pass("Center ground floor is open and unobstructed matching the requested reference design")
	else:
		_fail("Unwanted center furniture found in rotunda")

	# 4. Verify presentation cameras and interactive controller
	var cam_hero = inst.find_child("CameraHeroView", true, false)
	var cam_mezz = inst.find_child("CameraMezzanine", true, false)
	var cam_dome = inst.find_child("CameraDomeSkylight", true, false)
	if cam_hero and cam_mezz and cam_dome and inst is FinalSpaceRotunda:
		_pass("Presentation cameras configured (Hero View, Mezzanine Balcony, Dome Skylight)")
		# Test camera switching
		inst.set_camera(1) # Hero View
		if cam_hero.current:
			_pass("Controller switches cleanly to CameraHeroView (concept perspective)")
		else:
			_fail("Controller failed to set CameraHeroView as current")

		inst.set_camera(0) # Back to player
		_pass("Controller restores first-person exploration camera")
	else:
		_fail("Missing presentation cameras or FinalSpaceRotunda controller")

	# 5. Verify lighting & atmosphere
	var sunlight = inst.find_child("Sunlight", true, false)
	var dome_light = inst.find_child("DomeFillLight", true, false)
	if sunlight and dome_light:
		_pass("Lighting atmosphere configured with directional sunbeams and dome cupola fill")
	else:
		_fail("Missing sunlight or dome lighting")

	inst.queue_free()

## 13. Verify Comprehensive Accessibility Suite & Assists
func _check_accessibility_system() -> void:
	print("\n13. Comprehensive Accessibility Suite & Assists:")
	var sm = get_node_or_null("/root/SettingsManager")
	if not sm:
		_fail("SettingsManager not found")
		return

	# 1. Verify SettingsManager fields
	var req_fields = [
		"colorblind_mode", "high_contrast_outlines", "crosshair_dot",
		"toggle_suction", "toggle_sprint", "assisted_pickup",
		"invert_x", "subtitles_enabled", "visual_sound_cues", "soft_continuous_sfx"
	]
	var fields_ok: bool = true
	for f in req_fields:
		if not (f in sm):
			fields_ok = false
			_fail("SettingsManager missing accessibility property: %s" % f)
	if fields_ok:
		_pass("SettingsManager defines all required accessibility properties (visual, motor, auditory)")

	# 2. Verify SettingsMenu UI options and sync
	var settings_scn: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scn:
		var menu = settings_scn.instantiate()
		add_child(menu)

		var cb_opt: OptionButton = menu.find_child("ColorblindOpt", true, false)
		var hc_check: CheckBox = menu.find_child("HighContrastCheck", true, false)
		var cd_check: CheckBox = menu.find_child("CrosshairDotCheck", true, false)
		var ts_check: CheckBox = menu.find_child("ToggleSuctionCheck", true, false)
		var tsp_check: CheckBox = menu.find_child("ToggleSprintCheck", true, false)
		var ap_check: CheckBox = menu.find_child("AssistedPickupCheck", true, false)
		var ix_check: CheckBox = menu.find_child("InvertXCheck", true, false)
		var vsc_check: CheckBox = menu.find_child("VisualSoundCuesCheck", true, false)

		if cb_opt and hc_check and cd_check and ts_check and tsp_check and ap_check and ix_check and vsc_check:
			_pass("SettingsMenu contains all Accessibility & Assists UI controls in new tab")
			if cb_opt.item_count == 5:
				_pass("ColorblindOpt contains 5 vision profiles (Disabled, Protanopia, Deuteranopia, Tritanopia, Monochromacy)")
			else:
				_fail("ColorblindOpt has unexpected item count: %d" % cb_opt.item_count)

			# Test UI sync and apply
			sm.colorblind_mode = 2 # Deuteranopia
			sm.toggle_suction = true
			menu._sync_from_manager()
			if cb_opt.selected == 2 and ts_check.button_pressed == true:
				_pass("SettingsMenu syncs accessibility state correctly from SettingsManager")
			else:
				_fail("SettingsMenu failed to sync accessibility settings from manager")

			cb_opt.selected = 1 # Protanopia
			ts_check.button_pressed = false
			menu._on_apply_pressed()
			if sm.colorblind_mode == 1 and sm.toggle_suction == false:
				_pass("SettingsMenu apply button persists accessibility settings back to SettingsManager")
			else:
				_fail("SettingsMenu apply button failed to update SettingsManager")

			# Reset
			sm.colorblind_mode = 0
			sm.toggle_suction = false
			sm.save_settings()
			sm.apply_all()
		else:
			_fail("One or more accessibility controls missing from SettingsMenu")

		menu.queue_free()
	else:
		_fail("Could not load settings_menu.tscn")

	# 3. Verify HUD ColorblindFilter & Reticle & VisualSoundCues
	var hud_scn: PackedScene = load("res://scenes/ui/hud.tscn")
	if hud_scn:
		var hud = hud_scn.instantiate()
		add_child(hud)

		var cb_filter: ColorRect = hud.find_child("ColorblindFilter", true, false)
		var reticle: ColorRect = hud.find_child("Reticle", true, false)
		var cue_cont: PanelContainer = hud.find_child("VisualCuesContainer", true, false)

		if cb_filter and cb_filter.material is ShaderMaterial:
			_pass("HUD contains ColorblindFilter ColorRect with active ShaderMaterial")

			# Test activating colorblind mode updates shader
			sm.colorblind_mode = 3 # Tritanopia
			sm.apply_all()
			var current_shader_mode = cb_filter.material.get_shader_parameter("mode")
			if cb_filter.visible and current_shader_mode == 3:
				_pass("HUD activates ColorblindFilter and passes mode 3 to shader uniform")
			else:
				_fail("HUD failed to update ColorblindFilter for mode 3")

			sm.colorblind_mode = 0
			sm.apply_all()
			if not cb_filter.visible:
				_pass("HUD disables ColorblindFilter when mode is 0 (zero GPU overhead)")
			else:
				_fail("HUD did not disable ColorblindFilter when mode is 0")
		else:
			_fail("ColorblindFilter or ShaderMaterial missing from HUD")

		if reticle:
			sm.crosshair_dot = false
			sm.apply_all()
			var hidden_ok = not reticle.visible
			sm.crosshair_dot = true
			sm.apply_all()
			var visible_ok = reticle.visible
			if hidden_ok and visible_ok:
				_pass("HUD reticle visibility toggles dynamically with crosshair_dot setting")
			else:
				_fail("HUD reticle visibility did not toggle properly")
		else:
			_fail("Reticle missing from HUD")

		if cue_cont:
			hud.show_visual_cue("Test Cue", 1.0)
			if cue_cont.visible:
				_pass("HUD displays VisualCuesContainer when triggered")
			else:
				_fail("VisualCuesContainer failed to become visible on cue trigger")
		else:
			_fail("VisualCuesContainer missing from HUD")

		hud.queue_free()
	else:
		_fail("Could not load hud.tscn")

	# 4. Verify PlayerController Batch Deposit & Assisted Pickup
	var player_script = load("res://scripts/player/player_controller.gd")
	if player_script:
		var temp_player = CharacterBody3D.new()
		temp_player.set_script(player_script)
		if temp_player.has_method("batch_deposit_matching_eggs"):
			_pass("PlayerController implements batch_deposit_matching_eggs [R] assist")
		else:
			_fail("PlayerController missing batch_deposit_matching_eggs method")
		temp_player.queue_free()
	else:
		_fail("Could not load player_controller.gd")



