import bpy,json
from pathlib import Path
result={}
for name in ['seasoning_station','box','box_shelf','counters','order_stand']:
 bpy.ops.wm.open_mainfile(filepath=str(Path('art/blender',name+'.blend').resolve()))
 result[name]=[{'name':o.name,'type':o.type,'location':list(o.location),'dimensions':list(o.dimensions)} for o in bpy.data.objects if o.type in ['MESH','EMPTY']]
Path('docs/evidence/PUL-091/source_inventory.json').write_text(json.dumps(result,indent=2))
