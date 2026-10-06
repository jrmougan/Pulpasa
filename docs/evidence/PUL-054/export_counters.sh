#!/usr/bin/env bash
# Exporta las raíces de art/blender/counters.blend (PUL-054) con tools/blender_export.py, una por .glb.
# El exportador lee la colección `export` y el marcador `Anchor_Front`: para cada pieza se renombran
# en memoria (sin guardar el .blend) antes de exportar. Uso, desde la raíz del repo:
#   docs/evidence/PUL-054/export_counters.sh
set -euo pipefail
BLEND=art/blender/counters.blend
OUT=godot/assets/models/furniture/counters
FIRST=counter_1m
PIECES=(counter_1m counter_2m counter_3m counter_half counter_corner counter_end
        pass_1m pass_2m pass_3m pass_end rail_1m)

for piece in "${PIECES[@]}"; do
  swap="import bpy
c = bpy.data.collections; o = bpy.data.objects
if '$piece' != '$FIRST':
    c['export'].name = 'export_$FIRST'; c['export_$piece'].name = 'export'
    o['Anchor_Front'].name = 'Anchor_Front_$FIRST'; o['Anchor_Front_$piece'].name = 'Anchor_Front'"
  blender -b "$BLEND" --python-expr "$swap" --python tools/blender_export.py -- \
    --out "$OUT/$piece.glb" --max-tris 300 2>&1 | grep -E 'blender_export|Traceback' || true
  test -f "$OUT/$piece.glb"
done
