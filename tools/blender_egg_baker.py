"""
Egg Texture Baker for Blender
Automates procedural material setup and PBR texture map baking (Albedo, Normal, Roughness, Metallic)
for The Grand Eggsposition egg models.
"""

import bpy
import os
import sys
import argparse
from mathutils import Vector

def get_arg_parser():
    parser = argparse.ArgumentParser(description="Bake egg PBR texture maps in Blender.")
    parser.add_argument("--name", default="custom", help="Egg texture base name (e.g. gold, silver, obsidian)")
    parser.add_argument("--preset", default="", help="Procedural material preset (gold, silver, copper, bronze)")
    parser.add_argument("--from-active", action="store_true", help="Bake the active material on SM_Egg_Standard")
    parser.add_argument("--res", type=int, default=2048, help="Texture resolution in pixels (default: 2048)")
    parser.add_argument("--out-dir", required=True, help="Target directory for baked PNG files")
    parser.add_argument("--blend-path", default="", help="Path to baseegg.blend to load if needed")
    parser.add_argument("--samples", type=int, default=1, help="Render samples per pixel for baking")
    return parser

def configure_render_device():
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.cycles.device = 'GPU'
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.get_devices()
        gpu_found = False
        for dev_type in ('HIP', 'CUDA', 'OPTIX', 'METAL'):
            for d in prefs.devices:
                if d.type == dev_type:
                    prefs.compute_device_type = dev_type
                    d.use = True
                    gpu_found = True
            if gpu_found:
                break
        if not gpu_found:
            bpy.context.scene.cycles.device = 'CPU'
    except Exception:
        bpy.context.scene.cycles.device = 'CPU'

def build_preset_material(mat_name, preset_id):
    mat = bpy.data.materials.new(name=mat_name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out_node = nodes.new('ShaderNodeOutputMaterial')
    out_node.location = (1000, 0)
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (600, 0)
    links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])

    tex_coord = nodes.new('ShaderNodeTexCoord')
    tex_coord.location = (-1200, 0)

    mapping = nodes.new('ShaderNodeMapping')
    mapping.location = (-950, 0)
    links.new(tex_coord.outputs['Generated'], mapping.inputs['Vector'])

    # Fine satin micro-stipple bump matching reference photo
    noise_tex = nodes.new('ShaderNodeTexNoise')
    noise_tex.location = (-700, -200)
    noise_tex.inputs['Scale'].default_value = 65.0
    noise_tex.inputs['Detail'].default_value = 3.0
    noise_tex.inputs['Roughness'].default_value = 0.5
    links.new(mapping.outputs['Vector'], noise_tex.inputs['Vector'])

    bump = nodes.new('ShaderNodeBump')
    bump.location = (-400, -200)
    bump.inputs['Strength'].default_value = 0.08
    bump.inputs['Distance'].default_value = 0.0012
    links.new(noise_tex.outputs['Factor'], bump.inputs['Height'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

    # 100% Metallic
    bsdf.inputs['Metallic'].default_value = 1.0

    # Satin roughness reflecting light
    if 'Specular IOR Level' in bsdf.inputs:
        bsdf.inputs['Specular IOR Level'].default_value = 0.5
    if 'Specular' in bsdf.inputs:
        bsdf.inputs['Specular'].default_value = 0.5

    p = preset_id.lower()
    if p in ("gold", "pure_gold"):
        col_trough = (0.93, 0.72, 0.24, 1.0)
        col_crest  = (0.98, 0.82, 0.35, 1.0)
        rough_val  = 0.35
    elif p in ("silver", "pure_silver"):
        col_trough = (0.88, 0.90, 0.93, 1.0)
        col_crest  = (0.96, 0.97, 0.99, 1.0)
        rough_val  = 0.34
    elif p in ("copper", "pure_copper"):
        col_trough = (0.88, 0.48, 0.32, 1.0)
        col_crest  = (0.96, 0.60, 0.44, 1.0)
        rough_val  = 0.35
    elif p in ("bronze", "pure_bronze"):
        col_trough = (0.78, 0.50, 0.24, 1.0)
        col_crest  = (0.88, 0.62, 0.32, 1.0)
        rough_val  = 0.36
    else:
        col_trough = (0.85, 0.85, 0.85, 1.0)
        col_crest  = (0.95, 0.95, 0.95, 1.0)
        rough_val  = 0.35

    bsdf.inputs['Roughness'].default_value = rough_val

    ramp_col = nodes.new('ShaderNodeValToRGB')
    ramp_col.location = (-400, 200)
    ramp_col.color_ramp.interpolation = 'EASE'
    ramp_col.color_ramp.elements[0].position = 0.0
    ramp_col.color_ramp.elements[0].color = col_trough
    ramp_col.color_ramp.elements[1].position = 1.0
    ramp_col.color_ramp.elements[1].color = col_crest
    links.new(noise_tex.outputs['Factor'], ramp_col.inputs['Fac'])
    links.new(ramp_col.outputs['Color'], bsdf.inputs['Base Color'])

    return mat

def bake_pass_emit(obj, mat, source_socket, out_path, res, colorspace='Non-Color'):
    tree = mat.node_tree
    nodes = tree.nodes
    links = tree.links

    out_node = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')
    orig_surface = out_node.inputs['Surface'].links[0].from_socket if out_node.inputs['Surface'].links else None

    emit = nodes.new('ShaderNodeEmission')
    emit.inputs['Strength'].default_value = 1.0
    links.new(source_socket, emit.inputs['Color'])
    links.new(emit.outputs['Emission'], out_node.inputs['Surface'])

    img_name = f"bake_tmp_{os.path.basename(out_path)}"
    if img_name in bpy.data.images:
        bpy.data.images.remove(bpy.data.images[img_name])
    img = bpy.data.images.new(img_name, width=res, height=res)
    img.colorspace_settings.name = colorspace

    tex_node = nodes.new('ShaderNodeTexImage')
    tex_node.image = img
    for n in nodes:
        n.select = False
    tex_node.select = True
    nodes.active = tex_node

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    bpy.context.scene.render.bake.margin = 16
    bpy.ops.object.bake(type='EMIT')

    img.filepath_raw = out_path
    img.file_format = 'PNG'
    img.save()

    if orig_surface:
        links.new(orig_surface, out_node.inputs['Surface'])
    nodes.remove(emit)
    nodes.remove(tex_node)
    bpy.data.images.remove(img)

def bake_pass_normal(obj, mat, out_path, res):
    tree = mat.node_tree
    nodes = tree.nodes

    img_name = f"bake_tmp_norm_{os.path.basename(out_path)}"
    if img_name in bpy.data.images:
        bpy.data.images.remove(bpy.data.images[img_name])
    img = bpy.data.images.new(img_name, width=res, height=res)
    img.colorspace_settings.name = 'Non-Color'

    tex_node = nodes.new('ShaderNodeTexImage')
    tex_node.image = img
    for n in nodes:
        n.select = False
    tex_node.select = True
    nodes.active = tex_node

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    bpy.context.scene.render.bake.margin = 16
    bpy.ops.object.bake(type='NORMAL')

    img.filepath_raw = out_path
    img.file_format = 'PNG'
    img.save()

    nodes.remove(tex_node)
    bpy.data.images.remove(img)

def main():
    raw_args = sys.argv
    if "--" in raw_args:
        script_args = raw_args[raw_args.index("--") + 1:]
    else:
        script_args = raw_args[1:]

    parser = get_arg_parser()
    args = parser.parse_args(script_args)

    os.makedirs(args.out_dir, exist_ok=True)

    if args.blend_path and os.path.exists(args.blend_path):
        if bpy.data.filepath != args.blend_path:
            bpy.ops.wm.open_mainfile(filepath=args.blend_path)

    obj = bpy.data.objects.get('SM_Egg_Standard')
    if not obj:
        print("Error: Could not find SM_Egg_Standard object in Blender scene.")
        sys.exit(1)

    configure_render_device()
    bpy.context.scene.cycles.samples = max(1, args.samples)
    bpy.context.scene.render.bake.use_pass_direct = False
    bpy.context.scene.render.bake.use_pass_indirect = False

    if args.preset:
        mat_name = f"M_Egg_{args.name.capitalize()}_{args.preset.capitalize()}"
        mat = build_preset_material(mat_name, args.preset)
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    elif args.from_active and obj.data.materials:
        mat = obj.data.materials[0]
    else:
        if obj.data.materials:
            mat = obj.data.materials[0]
        else:
            print("Error: No material found on SM_Egg_Standard and no preset specified.")
            sys.exit(1)

    print(f"Baking material '{mat.name}' for egg '{args.name}' at {args.res}x{args.res}...")

    nodes = mat.node_tree.nodes
    bsdf = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if not bsdf:
        print("Error: Material does not contain a Principled BSDF node.")
        sys.exit(1)

    albedo_socket = bsdf.inputs['Base Color'].links[0].from_socket if bsdf.inputs['Base Color'].links else None
    rough_socket = bsdf.inputs['Roughness'].links[0].from_socket if bsdf.inputs['Roughness'].links else None
    metal_socket = bsdf.inputs['Metallic'].links[0].from_socket if bsdf.inputs['Metallic'].links else None

    if not albedo_socket:
        col_node = nodes.new('ShaderNodeRGB')
        col_node.outputs['Color'].default_value = bsdf.inputs['Base Color'].default_value
        albedo_socket = col_node.outputs['Color']

    if not rough_socket:
        val_node = nodes.new('ShaderNodeValue')
        val_node.outputs['Value'].default_value = bsdf.inputs['Roughness'].default_value
        rough_socket = val_node.outputs['Value']

    if not metal_socket:
        val_node = nodes.new('ShaderNodeValue')
        val_node.outputs['Value'].default_value = bsdf.inputs['Metallic'].default_value
        metal_socket = val_node.outputs['Value']

    prefix = f"egg_{args.name.lower()}"
    p_albedo = os.path.join(args.out_dir, f"{prefix}_albedo.png")
    p_roughness = os.path.join(args.out_dir, f"{prefix}_roughness.png")
    p_metallic = os.path.join(args.out_dir, f"{prefix}_metallic.png")
    p_normal = os.path.join(args.out_dir, f"{prefix}_normal.png")

    print(f"1/4 Baking Albedo -> {p_albedo}")
    bake_pass_emit(obj, mat, albedo_socket, p_albedo, args.res, colorspace='sRGB')

    print(f"2/4 Baking Roughness -> {p_roughness}")
    bake_pass_emit(obj, mat, rough_socket, p_roughness, args.res, colorspace='Non-Color')

    print(f"3/4 Baking Metallic -> {p_metallic}")
    bake_pass_emit(obj, mat, metal_socket, p_metallic, args.res, colorspace='Non-Color')

    print(f"4/4 Baking Normal -> {p_normal}")
    bake_pass_normal(obj, mat, p_normal, args.res)

    print("\nTexture baking completed successfully!")
    print(f"  • {p_albedo} ({os.path.getsize(p_albedo) // 1024} KB)")
    print(f"  • {p_roughness} ({os.path.getsize(p_roughness) // 1024} KB)")
    print(f"  • {p_metallic} ({os.path.getsize(p_metallic) // 1024} KB)")
    print(f"  • {p_normal} ({os.path.getsize(p_normal) // 1024} KB)")

if __name__ == "__main__":
    main()
