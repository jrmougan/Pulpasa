"""Read-only GLB audit: budget, unchanged anchors and original mesh attributes."""
from pathlib import Path
import json
import struct
import subprocess

PATH = 'godot/assets/models/stations/order_stand/order_stand.glb'
def parse(data):
    length = struct.unpack_from('<I',data,12)[0]
    doc = json.loads(data[20:20+length])
    return doc, data[28+length:]
def geometry(doc, data, name):
    node = next(n for n in doc['nodes'] if n['name']==name)
    result=[]
    for primitive in doc['meshes'][node['mesh']]['primitives']:
        part={}
        for key in ['POSITION','NORMAL','TEXCOORD_0']:
            acc=doc['accessors'][primitive['attributes'][key]]
            view=doc['bufferViews'][acc['bufferView']]
            offset=view.get('byteOffset',0)
            part[key]=data[offset:offset+view['byteLength']]
        result.append(part)
    return result
old, ob = parse(subprocess.check_output(['git','show','HEAD:'+PATH]))
new, nb = parse(Path(PATH).read_bytes())
anchors={}
meshes={}
for node in old['nodes']:
    name=node['name']
    other=next(n for n in new['nodes'] if n['name']==name)
    if name.startswith('Anchor_'):
        assert node == other, name
        anchors[name]=node.get('translation',[0,0,0])
    if 'mesh' in node:
        assert geometry(old,ob,name)==geometry(new,nb,name), name
        meshes[name]='unchanged positions, normals, UV'
triangles=sum(new['accessors'][p['indices']]['count']//3 for m in new['meshes'] for p in m['primitives'])
assert triangles <= 6000
result={'triangles_all_four_awnings':triangles,'anchors_godot':anchors,'original_meshes':meshes,'new_meshes':['order_id_plate','delivery_zone','delivery_zone_border'],'atlas_size':[512,512],'palette_srgb':['#D2473F','#3F7CC8','#E8C23A','#4FA05A']}
print(json.dumps(result,indent=2))
