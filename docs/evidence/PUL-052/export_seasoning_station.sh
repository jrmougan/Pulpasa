#!/usr/bin/env bash
# Exporta las tres raíces de art/blender/seasoning_station.blend (PUL-052) con tools/blender_export.py.
# El exportador lee la colección `export` y el marcador `Anchor_Front`: para cada pieza se renombran
# en memoria (sin guardar el .blend) antes de exportar. Uso, desde la raíz del repo:
#   docs/evidence/PUL-052/export_seasoning_station.sh
set -euo pipefail
BLEND=art/blender/seasoning_station.blend
OUT=godot/assets/models/stations/seasoning_station

export_piece() { # <colección> <sufijo del Anchor_Front> <glb>
  local swap="import bpy
c = bpy.data.collections; o = bpy.data.objects
if '$1' != 'export':
    c['export'].name = 'export_station'; c['$1'].name = 'export'
    o['Anchor_Front'].name = 'Anchor_Front_station'; o['Anchor_Front_$2'].name = 'Anchor_Front'"
  blender -b "$BLEND" --python-expr "$swap" --python tools/blender_export.py -- \
    --out "$OUT/$3.glb" --max-tris 1500
}

export_piece export station seasoning_station
export_piece export_dispenser dispenser seasoning_dispenser
export_piece export_bowl bowl cachelos_bowl
