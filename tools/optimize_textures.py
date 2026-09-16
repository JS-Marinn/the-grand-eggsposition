import os
import glob
import re
import subprocess

PROJECT_DIR = r"C:\Users\MrSeb\.gemini\antigravity\scratch\the-grand-eggsposition"
TEXTURES_DIR = os.path.join(PROJECT_DIR, "assets", "textures", "eggs")
GODOT_BIN = r"C:\Users\MrSeb\OneDrive\Desktop\Godot.exe"

def update_import_files():
    png_files = glob.glob(os.path.join(TEXTURES_DIR, "*.png"))
    print(f"Found {len(png_files)} textures in {TEXTURES_DIR}")
    
    updated_count = 0
    for png_path in png_files:
        import_path = png_path + ".import"
        if not os.path.exists(import_path):
            continue
            
        with open(import_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        is_normal = "normal" in os.path.basename(png_path).lower()
        
        # Replace compress/mode=0 with compress/mode=2 (VRAM Compressed)
        content = re.sub(r"compress/mode=\d+", "compress/mode=2", content)
        content = re.sub(r"compress/high_quality=(true|false)", "compress/high_quality=true", content)
        content = re.sub(r"detect_3d/compress_to=\d+", "detect_3d/compress_to=0", content)
        content = re.sub(r'metadata=\{\s*"vram_texture":\s*(true|false)\s*\}', 'metadata={\n"vram_texture": true\n}', content)
        content = re.sub(r"mipmaps/generate=(true|false)", "mipmaps/generate=true", content)
        
        if is_normal:
            content = re.sub(r"compress/normal_map=\d+", "compress/normal_map=1", content)
            
        with open(import_path, "w", encoding="utf-8") as f:
            f.write(content)
        updated_count += 1
        
    print(f"Updated {updated_count} .import files to VRAM Compressed (mode 2, high_quality=true).")

def reimport_godot():
    print("Triggering Godot headless reimport...")
    cmd = [GODOT_BIN, "--path", PROJECT_DIR, "--headless", "--editor", "--quit"]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    print("Reimport completed. Returncode:", res.returncode)

if __name__ == "__main__":
    update_import_files()
    reimport_godot()
