#!/usr/bin/env bash
# Exporta las raíces de art/blender/counters.blend (PUL-084) con tools/blender_export.py, una por .glb.
# El exportador lee la colección `export` y el marcador `Anchor_Front`: para cada pieza se renombran
# en memoria (sin guardar el .blend) antes de exportar. Uso, desde la raíz del repo:
#   docs/evidence/PUL-084/export_counters.sh
# Presupuesto (art-bible v2 §4.1): 1 500 triángulos por módulo de 1 m de encimera; atrezo pequeño 800.
set -euo pipefail
BLEND=art/blender/counters.blend
OUT=godot/assets/models/furniture/counters
FIRST=counter_1m
PIECES=(counter_1m:1500 counter_2m:3000 counter_3m:4500 counter_half:1500 counter_corner:1500
        counter_end:1500 pass_1m:1500 pass_2m:3000 pass_3m:4500 pass_end:1500 rail_1m:1500
        drain_grate:800 counter_props_board:800 counter_props_crock:800)

for entry in "${PIECES[@]}"; do
  piece=${entry%%:*}
  budget=${entry##*:}
  swap="import bpy
c = bpy.data.collections; o = bpy.data.objects
if '$piece' != '$FIRST':
    c['export'].name = 'export_$FIRST'; c['export_$piece'].name = 'export'
    o['Anchor_Front'].name = 'Anchor_Front_$FIRST'; o['Anchor_Front_$piece'].name = 'Anchor_Front'"
  blender -b "$BLEND" --python-expr "$swap" --python tools/blender_export.py -- \
    --out "$OUT/$piece.glb" --max-tris "$budget" 2>&1 | grep -E 'blender_export|Traceback' || true
  test -f "$OUT/$piece.glb"
done
