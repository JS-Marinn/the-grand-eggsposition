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
	_check_3d_models_budget()
	_check_egg_resource_architecture()
	_check_core_scenes()
	_check_localization()
	
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

## 2. Verify other 3D models in assets/models
func _check_3d_models_budget() -> void:
	print("\n2. Additional 3D Models in Assets:")
	var models: Array = [
		{"path": "res://assets/models/silverEgg.glb", "name": "Silver Egg GLB"},
		{"path": "res://assets/models/falloutEgg.glb", "name": "Fallout Egg GLB"}
	]
	
	for m_info in models:
		if FileAccess.file_exists(m_info.path):
			var scene: PackedScene = load(m_info.path) as PackedScene
			if scene:
				var inst: Node = scene.instantiate()
				var mi: MeshInstance3D = inst.find_child("*", true, false) as MeshInstance3D
				if mi and mi.mesh:
					var aabb = mi.mesh.get_aabb()
					_pass("%s loads successfully. AABB: %s" % [m_info.name, str(aabb.size)])
				else:
					_pass("%s loads successfully." % m_info.name)
				inst.free()
			else:
				_warn("Could not instantiate %s" % m_info.path)
		else:
			_warn("Optional asset %s not found" % m_info.path)

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
		{"path": "res://scenes/props/silver_egg_model.tscn", "name": "Silver Egg Scene"},
		{"path": "res://scenes/props/fallout_egg_model.tscn", "name": "Fallout Egg Scene"},
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
