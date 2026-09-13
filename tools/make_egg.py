#!/usr/bin/env python3
"""
tools/make_egg.py - The Grand Eggsposition
Automates creation and registration of new collectible Egg types.

Usage:
  python tools/make_egg.py --id 12 --key EGG_COPPER --name-en "Raw Copper Egg" --name-es "Huevo de Cobre Puro" \
      --series MINERALS_GEMS --showcase 1 --dozen 5 --color "#C87533" --metallic 0.85 --roughness 0.25
"""

import argparse
import csv
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

SERIES_DICT = {
    "MINERALS_GEMS": 0,
    "JOBS_SOCIETY": 1,
    "POP_CULTURE": 2,
    "FANTASY_MYTH": 3,
    "DELICATESSEN": 4,
    "WILDLIFE_COSMOS": 5
}

def parse_color(c_str: str):
    c_str = c_str.strip()
    if c_str.startswith("#"):
        hex_val = c_str.lstrip("#")
        if len(hex_val) == 6:
            r = int(hex_val[0:2], 16) / 255.0
            g = int(hex_val[2:4], 16) / 255.0
            b = int(hex_val[4:6], 16) / 255.0
            a = 1.0
        elif len(hex_val) == 8:
            r = int(hex_val[0:2], 16) / 255.0
            g = int(hex_val[2:4], 16) / 255.0
            b = int(hex_val[4:6], 16) / 255.0
            a = int(hex_val[6:8], 16) / 255.0
        else:
            raise ValueError(f"Invalid hex color: {c_str}")
        return r, g, b, a
    elif "," in c_str:
        parts = [float(p.strip()) for p in c_str.split(",")]
        if len(parts) == 3:
            return parts[0], parts[1], parts[2], 1.0
        elif len(parts) == 4:
            return parts[0], parts[1], parts[2], parts[3]
        else:
            raise ValueError(f"Invalid comma-separated color: {c_str}")
    else:
        raise ValueError(f"Unknown color format: {c_str}")

def update_translations(key: str, name_en: str, name_es: str) -> bool:
    csv_path = os.path.join(PROJECT_ROOT, "localization", "translations.csv")
    if not os.path.exists(csv_path):
        print(f"[WARN] Translation file not found at {csv_path}")
        return False

    with open(csv_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    key_exists = False
    for i, line in enumerate(lines):
        if line.startswith(key + ",") or line.startswith(f'"{key}",'):
            key_exists = True
            lines[i] = f'{key},"{name_en}","{name_es}"'
            print(f"[UPDATE] Updated existing translation for '{key}'")
            break

    if not key_exists:
        lines.append(f'{key},"{name_en}","{name_es}"')
        print(f"[ADD] Added new translation key '{key}' to translations.csv")

    with open(csv_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    return True

def create_tres_file(egg_id: int, key: str, series_name: str, showcase_id: int, dozen_group: int,
                     r: float, g: float, b: float, a: float, rough: float, metal: float,
                     custom_scene: str = None, custom_mesh: str = None) -> str:
    res_dir = os.path.join(PROJECT_ROOT, "resources", "eggs")
    os.makedirs(res_dir, exist_ok=True)

    clean_key = key.lower().replace("egg_", "")
    filename = f"egg_{egg_id:03d}_{clean_key}.tres"
    target_path = os.path.join(res_dir, filename)

    series_idx = SERIES_DICT.get(series_name.upper(), 0)

    load_steps = 2
    ext_resources = ['[ext_resource type="Script" path="res://scripts/resources/egg_resource.gd" id="1_script"]']
    extra_fields = []

    if custom_scene:
        load_steps += 1
        scene_id = f"{load_steps}_scene"
        ext_resources.append(f'[ext_resource type="PackedScene" path="{custom_scene}" id="{scene_id}"]')
        extra_fields.append(f'custom_scene = ExtResource("{scene_id}")')

    if custom_mesh:
        load_steps += 1
        mesh_id = f"{load_steps}_mesh"
        ext_resources.append(f'[ext_resource type="Mesh" path="{custom_mesh}" id="{mesh_id}"]')
        extra_fields.append(f'custom_mesh = ExtResource("{mesh_id}")')

    extra_str = "\n".join(extra_fields)
    if extra_str:
        extra_str = "\n" + extra_str

    content = f"""[gd_resource type="Resource" script_class="EggData" load_steps={load_steps} format=3]

{chr(10).join(ext_resources)}

[resource]
script = ExtResource("1_script")
egg_id = {egg_id}
egg_name_key = "{key}"
series = {series_idx}
showcase_id = {showcase_id}
dozen_group = {dozen_group}
albedo_color = Color({r:.4f}, {g:.4f}, {b:.4f}, {a:.4f})
roughness = {rough:.4f}
metallic = {metal:.4f}{extra_str}
"""
    with open(target_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)

    print(f"[CREATE] Saved resource: resources/eggs/{filename}")
    return target_path

def register_in_game_manager(egg_id: int, key: str, series_name: str, showcase_id: int, dozen_group: int,
                            r: float, g: float, b: float, rough: float, metal: float,
                            custom_scene: str = None) -> bool:
    gm_path = os.path.join(PROJECT_ROOT, "scripts", "autoload", "game_manager.gd")
    if not os.path.exists(gm_path):
        print(f"[WARN] GameManager not found at {gm_path}")
        return False

    with open(gm_path, "r", encoding="utf-8") as f:
        code = f.read()

    scene_arg = f', preload("{custom_scene}")' if custom_scene else ""
    line = f'\t_register_egg({egg_id}, "{key}", EggData.EggSeries.{series_name.upper()}, {showcase_id}, {dozen_group}, Color({r:.4f}, {g:.4f}, {b:.4f}), {rough:.2f}, {metal:.2f}{scene_arg})'

    pattern = re.compile(rf'^\s*_register_egg\(\s*{egg_id}\s*,.*$', re.MULTILINE)
    if pattern.search(code):
        code = pattern.sub(line, code)
        print(f"[UPDATE] Updated registration for egg_id={egg_id} in game_manager.gd")
    else:
        func_marker = "func _initialize_database() -> void:"
        idx = code.find(func_marker)
        if idx != -1:
            header_end = code.find("\n", idx) + 1
            code = code[:header_end] + line + "\n" + code[header_end:]
            print(f"[ADD] Registered egg_id={egg_id} into GameManager._initialize_database()")
        else:
            print("[WARN] Could not find _initialize_database in game_manager.gd")
            return False

    with open(gm_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(code)
    return True

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(description="Create and register a new collectible Egg for The Grand Eggsposition.")
    parser.add_argument("--id", type=int, required=True, help="Unique egg ID (e.g. 12)")
    parser.add_argument("--key", type=str, required=True, help="Egg translation key (e.g. EGG_COPPER)")
    parser.add_argument("--name-en", type=str, default="", help="English display name")
    parser.add_argument("--name-es", type=str, default="", help="Spanish display name")
    parser.add_argument("--series", type=str, default="MINERALS_GEMS", choices=list(SERIES_DICT.keys()), help="Egg series category")
    parser.add_argument("--showcase", type=int, default=1, help="Showcase ID (1-60)")
    parser.add_argument("--dozen", type=int, default=1, help="Dozen tier (1-5)")
    parser.add_argument("--color", type=str, default="#E08030", help="Albedo color (hex #RRGGBB or r,g,b)")
    parser.add_argument("--roughness", type=float, default=0.25, help="Surface roughness (0.0 - 1.0)")
    parser.add_argument("--metallic", type=float, default=0.0, help="Metallic factor (0.0 - 1.0)")
    parser.add_argument("--scene", type=str, default=None, help="Custom scene path (e.g. res://scenes/props/foo.tscn)")
    parser.add_argument("--mesh", type=str, default=None, help="Custom mesh path (e.g. res://assets/models/foo.tres)")
    parser.add_argument("--no-register", action="store_true", help="Skip registering in GameManager._initialize_database()")
    parser.add_argument("--no-tres", action="store_true", help="Skip creating the .tres file")

    args = parser.parse_args()

    r, g, b, a = parse_color(args.color)
    name_en = args.name_en if args.name_en else args.key.replace("EGG_", "").replace("_", " ").title() + " Egg"
    name_es = args.name_es if args.name_es else "Huevo de " + args.key.replace("EGG_", "").replace("_", " ").title()

    print(f"\n🥚 Creating Egg #{args.id} [{args.key}] - {name_en} / {name_es}")
    print(f"   Series: {args.series} | Showcase: {args.showcase} | Dozen: {args.dozen}")
    print(f"   Color: ({r:.2f}, {g:.2f}, {b:.2f}) | Rough: {args.roughness} | Metal: {args.metallic}")

    # 1. Update translations
    update_translations(args.key, name_en, name_es)

    # 2. Create .tres resource
    if not args.no_tres:
        create_tres_file(args.id, args.key, args.series, args.showcase, args.dozen,
                         r, g, b, a, args.roughness, args.metallic, args.scene, args.mesh)

    # 3. Register in GameManager
    if not args.no_register:
        register_in_game_manager(args.id, args.key, args.series, args.showcase, args.dozen,
                                 r, g, b, args.roughness, args.metallic, args.scene)

    print("✨ Egg creation complete!\n")

if __name__ == "__main__":
    main()
