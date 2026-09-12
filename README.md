# The Grand Eggsposition: Tidy Up Boutique

A wholesome, tactile cozy sorting and collecting game built in **Godot Engine 4.7.2 (Forward+ Vulkan)**.

## Overview

Step into **The Grand Eggsposition**, a sun-drenched, circular conservatory boutique where 3,600 unique themed collectible eggs (goose egg scale, roughly 8.5 cm) must be organized across 30 modular showcases.

* **Exact Dozen Symmetry:** 3,600 Total Eggs = 300 Distinct Themed Types × 12 Identical Units per type (1 exact dozen per type, 10 dozens per modular showcase).
* **Tactile ASMR Audio:** Calibrated 180 Hz velvet snap sounds, dry polished wood taps, and Celtic harp chords upon dozen completions.
* **Cozy Progression (Anti-Automation):** No passive auto-sort spells. Abilities enhance mobility, basket capacity, resonance detection, and cascade batch deposition while preserving the tactile joy of physical placement.
* **1 to 2 Players (Solo or Duo Co-op):** 100% playable and balanced in single-player; seamless Peer-to-Peer cooperative mode for couples and friends via Steamworks SDR and Steam Remote Play Together.
* **Multi-language Support (i18n):** Fully internationalized localization architecture with English as default.

## Project Structure

`
res://
├── localization/          # CSV & PO translation dictionaries (en, es)
├── scripts/
│   ├── autoload/          # Global managers (GameManager, AudioManager, ProgressManager)
│   ├── player/            # CharacterBody3D controller, interaction raycast, basket inventory
│   ├── environment/       # Modular showcases, MultiMeshInstance3D rendering, clockwork locks
│   └── resources/         # Strongly-typed Custom Resources (EggData, ShowcaseData)
├── scenes/
│   ├── main/              # Game entry point, world lighting, and environment
│   ├── atrium/            # Grand circular conservatory level geometry and furniture
│   ├── player/            # First-person avatar rig, camera smoothing, and hand sockets
│   └── ui/                # Ghost HUD, smart reticle, and Curator's Journal (TAB)
└── data/
    ├── eggs/              # 300 EggData .tres resources
    └── showcases/         # 30 ShowcaseData .tres resources
`

## Requirements

* **Engine:** Godot Engine 4.7.2 (or Godot 4.x Forward+ profile)
* **OS:** Windows / Linux / SteamOS (Steam Deck verified target)
* **Target FPS:** 60 FPS locked with <80 draw calls using GPU MultiMesh instancing.
