"""Read-only inventory of production Blender sources, run using Blender CLI."""
import bpy
import json
from pathlib import Path

root = Path.cwd()
inventory = {}
for asset in ('seasoning_station', 'box', 'box_shelf', 'counters', 'order_stand'):
    bpy.ops.wm.open_mainfile(filepath=str(root / 'art/blender' / (asset + '.blend')))
    objects = []
    for obj in bpy.data.collections['export'].all_objects:
        objects.append(dict(name=obj.name, type=obj.type,
                            parent=obj.parent.name if obj.parent else None,
                            location=list(obj.location), dimensions=list(obj.dimensions),
                            materials=[m.name for m in obj.data.materials] if obj.type == 'MESH' else []))
    inventory[asset] = objects
(root / 'docs/evidence/PUL-094/source_inventory.json').write_text(json.dumps(inventory, indent=2))
print(json.dumps(inventory))
