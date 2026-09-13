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
		var test_egg = gm.get_egg_for_showcase_dozen(showcase.showcase_id, 3)
		var egg_pbr_ok = test_egg != null and test_egg.metallic >= 0.85 and test_egg.roughness <= 0.15

		if mm.use_custom_data and shader_ok and lights_ok and egg_pbr_ok:
			_pass("MultiMesh uses showcase PBR shader with custom_data, soft lights (upper: %.2f, lower: %.2f), and authentic metallic PBR (metallic: %.2f, roughness: %.2f)" % [light_upper.light_energy, light_lower.light_energy, test_egg.metallic, test_egg.roughness])
		else:
			_fail("Showcase PBR or lighting validation failed: use_custom_data=%s, shader=%s, lights_ok=%s, egg_pbr_ok=%s" % [str(mm.use_custom_data), str(shader_ok), str(lights_ok), str(egg_pbr_ok)])

		gm.player_basket.clear()

	showcase.queue_free()
