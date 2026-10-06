#!/usr/bin/env bash
# Exporta art/blender/order_stand.blend (PUL-083) con tools/blender_export.py. Desde la raíz del repo:
#   docs/evidence/PUL-083/export_order_stand.sh
set -euo pipefail
# Presupuesto (art-bible v2 §4.1): 6 000 por kiosco; el .glb lleva las cuatro variantes de toldillo.
blender -b art/blender/order_stand.blend --python tools/blender_export.py -- \
  --out godot/assets/models/stations/order_stand/order_stand.glb --max-tris 6000
