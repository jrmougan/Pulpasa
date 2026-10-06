#!/usr/bin/env bash
# Exporta las tres raíces de art/blender/romeria.blend (PUL-055) con tools/blender_export.py.
# El exportador lee la colección `export` y el marcador `Anchor_Front`: para cada pieza se renombran
# en memoria (sin guardar el .blend) antes de exportar. Uso, desde la raíz del repo:
#   docs/evidence/PUL-055/export_romeria.sh
set -euo pipefail
BLEND=art/blender/romeria.blend
OUT=godot/assets/models/environment/romeria

export_piece() { # <colección> <sufijo del Anchor_Front> <glb> <máx. triángulos>
  local swap="import bpy
c = bpy.data.collections; o = bpy.data.objects
if '$1' != 'export':
    c['export'].name = 'export_ground'; c['$1'].name = 'export'
    o['Anchor_Front'].name = 'Anchor_Front_ground'; o['Anchor_Front_$2'].name = 'Anchor_Front'"
  blender -b "$BLEND" --python-expr "$swap" --python tools/blender_export.py -- \
    --out "$OUT/$3.glb" --max-tris "$4"
}

# Presupuesto del entorno completo: 6 000 triángulos (art-bible §2.2), repartido entre las tres piezas.
export_piece export ground ground 1000
export_piece export_tent tent tent 2500
export_piece export_decor decor decor 2500
