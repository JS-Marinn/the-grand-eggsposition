#!/usr/bin/env python3
"""
tools/bake_egg_texture.py
Automated pipeline for baking and adapting egg PBR textures into The Grand Eggsposition.

Usage Examples:
    python tools/bake_egg_texture.py --preset gold --name gold
    python tools/bake_egg_texture.py --preset silver --name silver
    python tools/bake_egg_texture.py --preset copper --name copper
    python tools/bake_egg_texture.py --preset bronze --name bronze
    python tools/bake_egg_texture.py --from-active --name my_egg
"""

import os
import sys
import argparse
import subprocess
import shutil

# Default paths for developer environment
DEFAULT_BLENDER_CANDIDATES = [
    r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
    r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
    r"C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
    r"C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
    r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
    shutil.which("blender") or ""
]

DEFAULT_GODOT_CANDIDATES = [
    r"C:\Users\MrSeb\OneDrive\Desktop\Godot.exe",
    shutil.which("godot") or "",
    shutil.which("Godot") or ""
]

DEFAULT_BLEND_FILE = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "blender_projects", "baseegg.blend"
))

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUT_TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "eggs")
BLENDER_BAKER_SCRIPT = os.path.join(PROJECT_ROOT, "tools", "blender_egg_baker.py")

def find_executable(candidates, env_var_name=None):
    if env_var_name and os.environ.get(env_var_name):
        env_path = os.environ[env_var_name]
        if os.path.exists(env_path):
            return env_path

    for path in candidates:
        if path and os.path.exists(path):
            return path
    return None

def main():
    parser = argparse.ArgumentParser(
        description="Automated PBR texture generator and importer for The Grand Eggsposition"
    )
    parser.add_argument(
        "--name",
        type=str,
        required=True,
        help="Base name for the egg (e.g. silver, obsidian, ruby, copper)"
    )
    parser.add_argument(
        "--preset",
        type=str,
        default="",
        choices=["gold", "silver", "copper", "bronze"],
        help="Built-in procedural recipe preset (gold, silver, copper, bronze)"
    )
    parser.add_argument(
        "--from-active",
        action="store_true",
        help="Bake whatever material is currently active on SM_Egg_Standard in the blend file"
    )
    parser.add_argument(
        "--res",
        type=int,
        default=2048,
        choices=[512, 1024, 2048, 4096],
        help="Texture map resolution in pixels (default: 2048)"
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=1,
        help="Cycles baking samples per pixel (default: 1)"
    )
    parser.add_argument(
        "--blend-file",
        type=str,
        default=DEFAULT_BLEND_FILE,
        help="Path to baseegg.blend"
    )
    parser.add_argument(
        "--blender-bin",
        type=str,
        default=None,
        help="Path to blender executable"
    )
    parser.add_argument(
        "--godot-bin",
        type=str,
        default=None,
        help="Path to godot executable"
    )
    parser.add_argument(
        "--no-import",
        action="store_true",
        help="Skip triggering Godot headless asset import"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Run tools/verify.py after baking and importing"
    )

    args = parser.parse_args()

    if not args.preset and not args.from_active:
        print("Error: Specify either --preset [name] or --from-active")
        sys.exit(1)

    # 1. Locate Blender
    blender_exe = args.blender_bin or find_executable(DEFAULT_BLENDER_CANDIDATES, "BLENDER_BIN")
    if not blender_exe:
        print("Error: Could not locate blender.exe. Please pass --blender-bin or set BLENDER_BIN.")
        sys.exit(1)

    # 2. Locate Godot
    godot_exe = args.godot_bin or find_executable(DEFAULT_GODOT_CANDIDATES, "GODOT_BIN")
    if not godot_exe and not args.no_import:
        print("Warning: Godot executable not found. Asset import step will be skipped.")

    # 3. Locate Blend file
    blend_path = os.path.abspath(args.blend_file)
    if not os.path.exists(blend_path):
        print(f"Error: Blend file not found at: {blend_path}")
        sys.exit(1)

    print("=======================================================")
    print(f"[EGG TEXTURE PIPELINE] {args.name.upper()}")
    print("=======================================================")
    print(f"  * Blend File:  {blend_path}")
    print(f"  * Preset:      {args.preset or '(active material)'}")
    print(f"  * Resolution:  {args.res}x{args.res}")
    print(f"  * Output Dir:  {OUTPUT_TEXTURES_DIR}")
    print(f"  * Blender:     {blender_exe}")
    print("-------------------------------------------------------")

    # 4. Run Blender Headless Baking
    blender_cmd = [
        blender_exe,
        "-b",
        blend_path,
        "-P",
        BLENDER_BAKER_SCRIPT,
        "--",
        "--name", args.name,
        "--res", str(args.res),
        "--samples", str(args.samples),
        "--out-dir", OUTPUT_TEXTURES_DIR,
    ]
    if args.preset:
        blender_cmd.extend(["--preset", args.preset])
    if args.from_active:
        blender_cmd.append("--from-active")

    print("\n[1/3] Baking PBR maps in Blender Cycles...")
    res = subprocess.run(blender_cmd, capture_output=True, text=True)
    if res.returncode != 0 and not ("Saved:" in res.stdout or "completed successfully" in res.stdout):
        print("Error executing Blender baker:")
        print(res.stdout)
        print(res.stderr)
        sys.exit(res.returncode)

    for line in res.stdout.splitlines():
        if "Baking" in line or "Saved:" in line or "completed" in line or "•" in line or "*" in line:
            print(f"  {line}")

    # 5. Run Godot Headless Import
    if godot_exe and not args.no_import:
        print("\n[2/3] Triggering Godot headless resource importer...")
        godot_cmd = [godot_exe, "--path", PROJECT_ROOT, "--headless", "--editor", "--quit"]
        res_g = subprocess.run(godot_cmd, capture_output=True, text=True)
        if res_g.returncode == 0:
            print("  Import successful! .import metadata generated.")
        else:
            print(f"  Godot import exited with code {res_g.returncode}: {res_g.stderr}")
    else:
        print("\n[2/3] Skipping Godot import (--no-import or Godot binary not available).")

    # 6. Verify Files Generated
    prefix = f"egg_{args.name.lower()}"
    expected_maps = ["albedo", "normal", "roughness", "metallic"]
    all_ok = True
    print("\n[3/3] Validating baked texture assets:")
    for m in expected_maps:
        fpath = os.path.join(OUTPUT_TEXTURES_DIR, f"{prefix}_{m}.png")
        if os.path.exists(fpath):
            size_kb = os.path.getsize(fpath) // 1024
            print(f"  [OK] {os.path.basename(fpath)} ({size_kb} KB)")
        else:
            print(f"  [X] Missing expected map: {fpath}")
            all_ok = False

    if not all_ok:
        print("\nPipeline finished with missing texture maps.")
        sys.exit(1)

    print("\n[SUCCESS] Texture suite is baked, imported, and ready in-game.")

    # 7. Optional verification
    if args.verify:
        print("\nRunning test suite verification...")
        verify_cmd = [sys.executable, os.path.join(PROJECT_ROOT, "tools", "verify.py")]
        subprocess.run(verify_cmd)

if __name__ == "__main__":
    main()
