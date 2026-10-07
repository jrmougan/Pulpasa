#!/usr/bin/env bash
# Exporta art/blender/box_shelf.blend (PUL-081) con tools/blender_export.py. Desde la raíz del repo:
#   docs/evidence/PUL-081/export_box_shelf.sh
set -euo pipefail
# Presupuesto (art-bible v2 §4.1): estación ≤ 6 000 triángulos (aquí incluidas las pilas de bandejas).
blender -b art/blender/box_shelf.blend --python tools/blender_export.py -- \
  --out godot/assets/models/stations/box_shelf/box_shelf.glb --max-tris 6000
