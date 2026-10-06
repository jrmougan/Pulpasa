#!/usr/bin/env bash
# Exporta las piezas de art/blender/environment_v2.blend (PUL-085) con tools/blender_export.py.
# El exportador lee la colección `export` y el marcador `Anchor_Front`: para cada pieza se renombran en
# memoria (sin guardar el .blend) `export_<pieza>` → `export` y `Anchor_Front_<pieza>` → `Anchor_Front`.
# Uso, desde la raíz del repo:
#   python3 art/blender/environment_v2_src/gen_textures.py   # si cambian las texturas propias
#   art/blender/environment_v2_src/export_environment.sh
#   godot --headless --path godot --import
set -euo pipefail
BLEND=art/blender/environment_v2.blend
OUT=godot/assets/models/environment/romeria_v2

export_piece() { # <pieza> <máx. triángulos>
  local swap="import bpy
bpy.data.collections['export_$1'].name = 'export'
bpy.data.objects['Anchor_Front_$1'].name = 'Anchor_Front'"
  blender -b "$BLEND" --python-expr "$swap" --python tools/blender_export.py -- \
    --out "$OUT/$1.glb" --max-tris "$2" 2>&1 | grep -E "blender_export|Error|error" || true
  test -f "$OUT/$1.glb"
}

# Presupuesto del entorno completo: 80 000 triángulos (art-bible v2 §4.1); atrezo grande ≤ 5 000 por
# pieza de fondo (mesa con comensales, árbol, generador), así que cada .glb lleva su propio tope.
export_piece ground_w 4000
export_piece ground_e 4000
export_piece back_w 12000
export_piece back_e 12000
export_piece tent 10000
export_piece props_w 15000
export_piece props_e 12000
