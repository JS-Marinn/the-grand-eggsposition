# Antigravity Global Memory & System Directives

## 1. Obligatory Tool Usage: Blender MCP & Godot MCP
* **Blender MCP (blender)**: You MUST ALWAYS prioritize and use the Blender MCP server (execute_blender_code, get_viewport_screenshot, get_scene_info, get_object_info, etc.) for all 3D modeling, procedural shader node networks, material creation, previewing, and baking operations.
* **Godot MCP (godot)**: You MUST ALWAYS prioritize and use the Godot MCP server (launch_editor, 
un_project, get_debug_output, stop_project, create_scene, dd_node, save_scene, get_project_info, get_godot_version, etc.) for running, inspecting, debugging, and managing Godot projects and scene trees.

## 2. Art Direction & Texturing Standards (The Grand Eggsposition & 3D Projects)
* **Zero Runtime Shaders in Game Engine**: Never run procedural shader code at runtime in Godot that alters shape or patterns dynamically with camera movement.
* **Pure Baked Physical PBR**: Build materials using Blender\'s procedural shader nodes with 3D Object coordinates (guaranteeing 0 seams and 0 polar distortion), then bake them into 4 standard PBR maps:
  - lbedo.png
  - 
ormal.png
  - 
oughness.png
  - metallic.png
* **Material Variety with Unified Art Direction**: Support diverse materials (fine porcelain, hammered copper, damascus steel, banded malachite, carved walnut, obsidian, carbon fiber, etc.) while strictly maintaining the same museum curio art direction (consistent macro proportions, refined micro-bevels, realistic cavity ambient occlusion, and tactile surface response).
