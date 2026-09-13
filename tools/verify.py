#!/usr/bin/env python3
"""
tools/verify.py - The Grand Eggsposition
Convenient launcher to execute the headless Godot project integrity checker.
"""

import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
RUNNER_SCENE = "res://tools/verify_runner.tscn"

POSSIBLE_GODOT_PATHS = [
    os.environ.get("GODOT_BIN", ""),
    r"C:\Users\MrSeb\OneDrive\Desktop\Godot.exe",
    r"C:\Program Files\Godot\Godot.exe",
    shutil.which("godot") or "",
    shutil.which("godot4") or ""
]

def find_godot():
    for p in POSSIBLE_GODOT_PATHS:
        if p and os.path.isfile(p):
            return p
    return None

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    godot_exe = find_godot()
    if not godot_exe:
        print("[ERROR] Godot executable not found.")
        print("Please set the GODOT_BIN environment variable or ensure Godot is in your PATH.")
        sys.exit(1)

    cmd = [
        godot_exe,
        "--headless",
        "--path", PROJECT_ROOT,
        RUNNER_SCENE
    ]

    print(f">> Running Godot Integrity Checker ({godot_exe})...\n")
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.stdout:
        print(proc.stdout)
    if proc.stderr:
        # Filter out harmless GPU dummy allocator notices at exit
        lines = [l for l in proc.stderr.splitlines() if "PagedAllocator" not in l and "ObjectDB" not in l]
        if lines:
            print("\n".join(lines), file=sys.stderr)
    sys.exit(proc.returncode)

if __name__ == "__main__":
    main()
