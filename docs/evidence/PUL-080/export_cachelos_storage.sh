#!/usr/bin/env bash
# Exporta art/blender/cachelos_storage.blend (PUL-080) con tools/blender_export.py. Desde la raíz del repo:
#   docs/evidence/PUL-080/export_cachelos_storage.sh
set -euo pipefail
# Presupuesto (art-bible v2 §4.1): estación ≤ 6 000 triángulos.
blender -b art/blender/cachelos_storage.blend --python tools/blender_export.py -- \
  --out godot/assets/models/stations/cachelos_storage/cachelos_storage.glb --max-tris 6000
