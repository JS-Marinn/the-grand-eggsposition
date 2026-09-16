#!/usr/bin/env python3
"""
tools/generate_egg_textures.py
Bakes high-resolution 2048x2048 seamless 2D PBR textures for eggs in The Grand Eggsposition.
Replaces real-time fragment shader code with rock-solid, mipmapped, artifact-free textures.
"""

import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "eggs"))
os.makedirs(OUTPUT_DIR, exist_ok=True)

RES = 2048
SUPER_RES = 4096 # 2x supersampling for razor-sharp antialiasing

def create_kraft_background(width, height, base_rgb=(220, 211, 199)):
    """Generates warm clay/kraft background with subtle micro-grain texture."""
    base = np.zeros((height, width, 3), dtype=np.float32)
    base[:, :] = base_rgb
    # Add subtle organic clay noise
    np.random.seed(42)
    noise = np.random.normal(0, 3.5, (height, width, 1)).astype(np.float32)
    grain = np.clip(base + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(grain, 'RGB')

def create_porcelain_background(width, height, base_rgb=(248, 245, 238)):
    """Generates pure ivory glazed porcelain background."""
    base = np.zeros((height, width, 3), dtype=np.float32)
    base[:, :] = base_rgb
    np.random.seed(101)
    noise = np.random.normal(0, 1.2, (height, width, 1)).astype(np.float32)
    grain = np.clip(base + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(grain, 'RGB')

def generate_normal_from_height(height_map, strength=1.5):
    """Converts a greyscale height/bump map (uint8) into a tangent-space normal map (RGB)."""
    h_arr = np.array(height_map, dtype=np.float32) / 255.0
    # Sobel / central difference
    dx = np.roll(h_arr, -1, axis=1) - np.roll(h_arr, 1, axis=1)
    dy = np.roll(h_arr, -1, axis=0) - np.roll(h_arr, 1, axis=0)
    
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(nx)
    
    length = np.sqrt(nx**2 + ny**2 + nz**2)
    nx /= length
    ny /= length
    nz /= length
    
    # Map from [-1, 1] to [0, 255]
    norm_rgb = np.stack([
        (nx * 0.5 + 0.5) * 255.0,
        (ny * 0.5 + 0.5) * 255.0,
        (nz * 0.5 + 0.5) * 255.0
    ], axis=-1).astype(np.uint8)
    
    return Image.fromarray(norm_rgb, 'RGB')

# ==============================================================================
# 1. CHEVRON MAGENTA (Left egg in user reference photo)
# ==============================================================================
def bake_chevron_magenta():
    print("Baking egg_chevron_magenta...")
    W, H = SUPER_RES, SUPER_RES
    img = create_kraft_background(W, H, base_rgb=(224, 214, 203))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    # 6 chevron cycles around circumference (wraps seamlessly at edges 0 and W)
    num_cycles = 6
    cycle_w = W / num_cycles
    
    # Chevrons stacked vertically
    magenta = (228, 0, 123)
    mauve = (184, 154, 162)
    
    bands = 10
    band_h = H / bands
    thickness = band_h * 0.42
    
    for b in range(bands + 2):
        center_y = (b - 0.5) * band_h
        color = magenta if (b % 2 == 1) else mauve
        
        # Build polygon zigzag strip
        pts_top = []
        pts_bot = []
        
        for c in range(num_cycles * 2 + 1):
            x = c * (cycle_w / 2.0)
            # Peak on even, valley on odd
            y_offset = (band_h * 0.38) if (c % 2 == 1) else -(band_h * 0.38)
            y_mid = center_y + y_offset
            pts_top.append((x, y_mid - thickness * 0.5))
            pts_bot.append((x, y_mid + thickness * 0.5))
            
        poly = pts_top + pts_bot[::-1]
        draw.polygon(poly, fill=color)
        draw_bump.polygon(poly, fill=160 if b % 2 == 1 else 145)
        
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 65) # Satin glazed clay
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_chevron_magenta_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_chevron_magenta_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_chevron_magenta_roughness.png"))
    print("  Saved egg_chevron_magenta suite!")

# ==============================================================================
# 2. CHEVRON CYAN (Second egg in user reference photo)
# ==============================================================================
def bake_chevron_cyan():
    print("Baking egg_chevron_cyan...")
    W, H = SUPER_RES, SUPER_RES
    img = create_kraft_background(W, H, base_rgb=(224, 214, 203))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    num_cycles = 6
    cycle_w = W / num_cycles
    
    cyan_dark = (31, 120, 180)
    cyan_light = (78, 205, 230)
    
    bands = 10
    band_h = H / bands
    thickness = band_h * 0.42
    
    for b in range(bands + 2):
        center_y = (b - 0.5) * band_h
        color = cyan_dark if (b % 2 == 1) else cyan_light
        
        pts_top = []
        pts_bot = []
        for c in range(num_cycles * 2 + 1):
            x = c * (cycle_w / 2.0)
            y_offset = (band_h * 0.38) if (c % 2 == 1) else -(band_h * 0.38)
            y_mid = center_y + y_offset
            pts_top.append((x, y_mid - thickness * 0.5))
            pts_bot.append((x, y_mid + thickness * 0.5))
            
        poly = pts_top + pts_bot[::-1]
        draw.polygon(poly, fill=color)
        draw_bump.polygon(poly, fill=160 if b % 2 == 1 else 145)
        
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 65)
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_chevron_cyan_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_chevron_cyan_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_chevron_cyan_roughness.png"))
    print("  Saved egg_chevron_cyan suite!")

# ==============================================================================
# 3. OP-ART HEXAGONS & STARS (Center egg in user reference photo)
# ==============================================================================
def bake_opart_hexagons():
    print("Baking egg_opart_hexagons...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(246, 243, 236))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    # Hexagonal optical art grid
    # Seamless wrap across W: exactly 8 columns of hexagons
    cols = 8
    dx = W / cols
    dy = dx * math.sqrt(3) / 2.0
    rows = int(math.ceil(H / dy)) + 2
    
    line_col = (20, 20, 20)
    
    def get_hex_points(cx, cy, r):
        pts = []
        for i in range(6):
            ang = math.pi / 6.0 + i * (math.pi / 3.0)
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
        return pts

    def get_star_points(cx, cy, r_outer, r_inner):
        pts = []
        for i in range(12):
            ang = i * (math.pi / 6.0)
            r = r_outer if (i % 2 == 0) else r_inner
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
        return pts
        
    for r in range(rows):
        cy = r * dy
        offset_x = (dx * 0.5) if (r % 2 == 1) else 0.0
        for c in range(cols + 2):
            cx = c * dx + offset_x
            
            # Concentric nested hexagons
            for ring in range(1, 6):
                radius = (dx * 0.48) * (ring / 5.0)
                hex_pts = get_hex_points(cx, cy, radius)
                hex_pts.append(hex_pts[0])
                line_w = int(round(W * 0.0035))
                draw.line(hex_pts, fill=line_col, width=line_w)
                draw_bump.line(hex_pts, fill=165, width=line_w)
                
            # Central nested star
            for s_ring in range(1, 4):
                so = (dx * 0.22) * (s_ring / 3.0)
                si = so * 0.52
                star_pts = get_star_points(cx, cy, so, si)
                star_pts.append(star_pts[0])
                draw.line(star_pts, fill=line_col, width=int(round(W * 0.003)))
                draw_bump.line(star_pts, fill=175, width=int(round(W * 0.003)))
                
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.8)
    roughness = Image.new('L', (RES, RES), 30) # Glossy fine porcelain
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_opart_hexagons_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_opart_hexagons_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_opart_hexagons_roughness.png"))
    print("  Saved egg_opart_hexagons suite!")

# ==============================================================================
# 4. BOTANICAL PASTEL (Right egg in user reference photo)
# ==============================================================================
def bake_botanical_pastel():
    print("Baking egg_botanical_pastel...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(242, 237, 226))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    # 4 vertical stems spaced evenly around circumference
    stems = 4
    stem_dx = W / stems
    stem_gold = (226, 182, 38)
    
    # Pastel palette
    pastel_palette = [
        (142, 198, 63),   # Lime green
        (78, 205, 196),   # Mint turquoise
        (255, 107, 107),  # Coral pink
        (249, 211, 66),   # Mustard yellow
    ]
    
    leaf_w = W * 0.055
    leaf_h = H * 0.024
    
    for s in range(stems):
        cx = s * stem_dx + stem_dx * 0.5
        # Vertical golden stem from top to bottom
        draw.line([(cx, 0), (cx, H)], fill=stem_gold, width=int(round(W * 0.007)))
        draw_bump.line([(cx, 0), (cx, H)], fill=160, width=int(round(W * 0.007)))
        
        # Pairs of leaves along the stem
        num_pairs = 12
        pair_dh = H / num_pairs
        
        for p in range(num_pairs):
            cy = p * pair_dh + pair_dh * 0.5
            col = pastel_palette[p % len(pastel_palette)]
            
            # Left leaf angled upwards
            # Draw ellipse rotated ~32 degrees
            # Left leaf
            bbox_l = [cx - leaf_w * 1.3, cy - leaf_h, cx - leaf_w * 0.1, cy + leaf_h]
            draw.chord(bbox_l, start=140, end=360, fill=col)
            draw.chord(bbox_l, start=0, end=180, fill=col)
            draw_bump.chord(bbox_l, start=0, end=360, fill=155)
            
            # Right leaf
            bbox_r = [cx + leaf_w * 0.1, cy - leaf_h, cx + leaf_w * 1.3, cy + leaf_h]
            draw.chord(bbox_r, start=0, end=220, fill=col)
            draw.chord(bbox_r, start=180, end=360, fill=col)
            draw_bump.chord(bbox_r, start=0, end=360, fill=155)
            
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 45) # Fine satin ceramic
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_botanical_pastel_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_botanical_pastel_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_botanical_pastel_roughness.png"))
    print("  Saved egg_botanical_pastel suite!")

# ==============================================================================
# 5. DELFTWARE SUITE (5 Historic Patterns as 2048x2048 PBR Textures)
# ==============================================================================
COBALT_DEEP = (8, 32, 115)
COBALT_WASH = (24, 75, 175)

def bake_delft_spirals():
    print("Baking egg_delft_spirals...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(248, 245, 238))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    cols, rows = 8, 8
    cell_w = W / cols
    cell_h = H / rows
    
    for r in range(rows):
        offset_x = (cell_w * 0.5) if (r % 2 == 1) else 0.0
        cy = r * cell_h + cell_h * 0.5
        for c in range(cols + 2):
            cx = c * cell_w + offset_x - cell_w * 0.5
            # Draw double Archimedean spirals
            pts_1 = []
            pts_2 = []
            max_turns = 2.2
            steps = 90
            for i in range(steps):
                t = i / float(steps)
                ang = t * max_turns * 2.0 * math.pi
                rad = (cell_w * 0.42) * (t ** 0.85)
                pts_1.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
                pts_2.append((cx + rad * math.cos(ang + math.pi), cy + rad * math.sin(ang + math.pi)))
                
            line_w = int(round(W * 0.0055))
            draw.line(pts_1, fill=COBALT_DEEP, width=line_w)
            draw.line(pts_2, fill=COBALT_WASH, width=line_w)
            draw_bump.line(pts_1, fill=165, width=line_w)
            draw_bump.line(pts_2, fill=155, width=line_w)
            
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 28) # High-gloss porcelain
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_delft_spirals_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_delft_spirals_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_delft_spirals_roughness.png"))
    print("  Saved egg_delft_spirals suite!")

def bake_delft_windmill():
    print("Baking egg_delft_windmill...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(248, 245, 238))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    cols, rows = 8, 6
    cell_w = W / cols
    cell_h = H / rows
    
    for r in range(rows):
        offset_x = (cell_w * 0.5) if (r % 2 == 1) else 0.0
        cy = r * cell_h + cell_h * 0.5
        for c in range(cols + 2):
            cx = c * cell_w + offset_x - cell_w * 0.5
            rad = cell_w * 0.40
            
            # Outer decorative circle
            bbox_out = [cx - rad, cy - rad, cx + rad, cy + rad]
            draw.ellipse(bbox_out, outline=COBALT_DEEP, width=int(round(W * 0.004)))
            draw_bump.ellipse(bbox_out, outline=160, width=int(round(W * 0.004)))
            
            # 4 windmill triangular blades
            for b in range(4):
                ang = b * (math.pi / 2.0)
                b_tip = (cx + rad * 0.85 * math.cos(ang), cy + rad * 0.85 * math.sin(ang))
                b_side1 = (cx + rad * 0.35 * math.cos(ang + 0.35), cy + rad * 0.35 * math.sin(ang + 0.35))
                b_side2 = (cx + rad * 0.35 * math.cos(ang - 0.35), cy + rad * 0.35 * math.sin(ang - 0.35))
                tri = [(cx, cy), b_side1, b_tip, b_side2]
                draw.polygon(tri, fill=COBALT_DEEP)
                draw_bump.polygon(tri, fill=165)
                
            # Center hub dot
            hub_r = rad * 0.18
            draw.ellipse([cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r], fill=COBALT_WASH)
            draw_bump.ellipse([cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r], fill=175)
            
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 28)
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_delft_windmill_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_delft_windmill_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_delft_windmill_roughness.png"))
    print("  Saved egg_delft_windmill suite!")

def bake_delft_leaves():
    print("Baking egg_delft_leaves...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(248, 245, 238))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    cols, rows = 8, 6
    cell_w = W / cols
    cell_h = H / rows
    
    for r in range(rows):
        offset_x = (cell_w * 0.5) if (r % 2 == 1) else 0.0
        cy = r * cell_h + cell_h * 0.5
        for c in range(cols + 2):
            cx = c * cell_w + offset_x - cell_w * 0.5
            rad = cell_w * 0.42
            
            # Baroque leaves angled diagonally
            for ang_deg in [-45, 45, 135, 225]:
                ang = math.radians(ang_deg)
                lx = cx + rad * 0.55 * math.cos(ang)
                ly = cy + rad * 0.55 * math.sin(ang)
                lw = rad * 0.38
                lh = rad * 0.20
                bbox = [lx - lw, ly - lh, lx + lw, ly + lh]
                draw.ellipse(bbox, fill=COBALT_DEEP)
                draw_bump.ellipse(bbox, fill=165)
                
            # Connecting curly vine
            draw.arc([cx - rad * 0.6, cy - rad * 0.6, cx + rad * 0.6, cy + rad * 0.6], start=30, end=330, fill=COBALT_WASH, width=int(round(W * 0.0035)))
            draw_bump.arc([cx - rad * 0.6, cy - rad * 0.6, cx + rad * 0.6, cy + rad * 0.6], start=30, end=330, fill=155, width=int(round(W * 0.0035)))
            
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 28)
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_delft_leaves_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_delft_leaves_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_delft_leaves_roughness.png"))
    print("  Saved egg_delft_leaves suite!")

def bake_delft_meanders():
    print("Baking egg_delft_meanders...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(248, 245, 238))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    # 4 continuous horizontal bands
    bands = 4
    band_h = H / bands
    cols = 8
    cell_w = W / cols
    
    line_w = int(round(W * 0.006))
    
    for b in range(bands):
        top_y = b * band_h + band_h * 0.10
        bot_y = b * band_h + band_h * 0.90
        
        # Horizontal top and bottom border lines spanning 100% of W (seamless wrap)
        draw.line([(0, top_y), (W, top_y)], fill=COBALT_DEEP, width=line_w)
        draw.line([(0, bot_y), (W, bot_y)], fill=COBALT_DEEP, width=line_w)
        draw_bump.line([(0, top_y), (W, top_y)], fill=165, width=line_w)
        draw_bump.line([(0, bot_y), (W, bot_y)], fill=165, width=line_w)
        
        # Meander frets inside each column
        mid_y = (top_y + bot_y) * 0.5
        h1_y = top_y + (bot_y - top_y) * 0.28
        h2_y = top_y + (bot_y - top_y) * 0.72
        
        for c in range(cols):
            x0 = c * cell_w
            x1 = x0 + cell_w
            
            p_v1 = [(x0 + cell_w * 0.15, h1_y), (x0 + cell_w * 0.15, mid_y)]
            p_h_mid = [(x0 + cell_w * 0.15, mid_y), (x0 + cell_w * 0.65, mid_y)]
            p_v2 = [(x0 + cell_w * 0.65, mid_y), (x0 + cell_w * 0.65, h2_y)]
            p_h2 = [(x0 + cell_w * 0.65, h2_y), (x0 + cell_w * 0.85, h2_y)]
            p_v3 = [(x0 + cell_w * 0.85, h2_y), (x0 + cell_w * 0.85, top_y + (bot_y - top_y) * 0.15)]
            p_connect = [(x0, h1_y), (x0 + cell_w, h1_y)]
            
            for path in [p_connect, p_v1, p_h_mid, p_v2, p_h2, p_v3]:
                draw.line(path, fill=COBALT_DEEP, width=line_w)
                draw_bump.line(path, fill=165, width=line_w)
                
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 28)
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_delft_meanders_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_delft_meanders_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_delft_meanders_roughness.png"))
    print("  Saved egg_delft_meanders suite!")

def bake_delft_rosette():
    print("Baking egg_delft_rosette...")
    W, H = SUPER_RES, SUPER_RES
    img = create_porcelain_background(W, H, base_rgb=(248, 245, 238))
    bump = Image.new('L', (W, H), 128)
    draw = ImageDraw.Draw(img)
    draw_bump = ImageDraw.Draw(bump)
    
    cols, rows = 8, 6
    cell_w = W / cols
    cell_h = H / rows
    
    for r in range(rows):
        offset_x = (cell_w * 0.5) if (r % 2 == 1) else 0.0
        cy = r * cell_h + cell_h * 0.5
        for c in range(cols + 2):
            cx = c * cell_w + offset_x - cell_w * 0.5
            rad = cell_w * 0.40
            
            # 8 outer petals
            for i in range(8):
                ang = i * (math.pi / 4.0)
                px = cx + rad * 0.65 * math.cos(ang)
                py = cy + rad * 0.65 * math.sin(ang)
                pw = rad * 0.28
                draw.ellipse([px - pw, py - pw, px + pw, py + pw], fill=COBALT_WASH)
                draw_bump.ellipse([px - pw, py - pw, px + pw, py + pw], fill=155)
                
            # 8 inner petals
            for i in range(8):
                ang = (i + 0.5) * (math.pi / 4.0)
                px = cx + rad * 0.40 * math.cos(ang)
                py = cy + rad * 0.40 * math.sin(ang)
                pw = rad * 0.18
                draw.ellipse([px - pw, py - pw, px + pw, py + pw], fill=COBALT_DEEP)
                draw_bump.ellipse([px - pw, py - pw, px + pw, py + pw], fill=165)
                
            # Center seed
            draw.ellipse([cx - rad * 0.15, cy - rad * 0.15, cx + rad * 0.15, cy + rad * 0.15], fill=COBALT_DEEP)
            draw_bump.ellipse([cx - rad * 0.15, cy - rad * 0.15, cx + rad * 0.15, cy + rad * 0.15], fill=175)
            
    albedo = img.resize((RES, RES), Image.LANCZOS)
    bump_res = bump.resize((RES, RES), Image.LANCZOS)
    normal = generate_normal_from_height(bump_res, strength=2.2)
    roughness = Image.new('L', (RES, RES), 28)
    
    albedo.save(os.path.join(OUTPUT_DIR, "egg_delft_rosette_albedo.png"))
    normal.save(os.path.join(OUTPUT_DIR, "egg_delft_rosette_normal.png"))
    roughness.save(os.path.join(OUTPUT_DIR, "egg_delft_rosette_roughness.png"))
    print("  Saved egg_delft_rosette suite!")

if __name__ == "__main__":
    print(f"Baking all high-resolution 2048x2048 PBR egg textures to: {OUTPUT_DIR}")
    # 1. Reference photo styles
    bake_chevron_magenta()
    bake_chevron_cyan()
    bake_opart_hexagons()
    bake_botanical_pastel()
    
    # 2. Delftware porcelain collection
    bake_delft_spirals()
    bake_delft_windmill()
    bake_delft_leaves()
    bake_delft_meanders()
    bake_delft_rosette()
    
    print("\nALL 9 PBR EGG TEXTURE SUITES BAKED SUCCESSFULLY!")
