"""Regression assertions on exported data, hierarchy, geometry budget and palette."""
import json, struct, re
from pathlib import Path
root=Path.cwd();folder=root/'godot/assets/models/stations/seasoning_station'
def glb(name):
    raw=(folder/(name+'.glb')).read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+length])
def tri(g,node):
    if 'mesh' not in node:return 0
    return sum(g['accessors'][p['indices']]['count']//3 for p in g['meshes'][node['mesh']]['primitives'])
report={}
for name in ['seasoning_station','seasoning_dispenser','cachelos_bowl']:
    g=glb(name);nodes={n['name']:n for n in g['nodes']};counts={n:tri(g,o) for n,o in nodes.items() if 'mesh' in o}
    report[name]=counts
    assert 'Anchor_Front' in nodes
    assert not any('camera' in n for n in g['nodes'])
    if name=='seasoning_station':
        assert not any(n in nodes for n in ['tray','cutting_board','Anchor_Tray'])
        anchors=['Anchor_Dispenser_SweetPaprika','Anchor_Dispenser_HotPaprika','Anchor_Dispenser_Salt','Anchor_Dispenser_Oil','Anchor_Bowl']
        positions=[nodes[n]['translation'] for n in anchors]
        assert all(abs(p[0]-(i-2))<1e-5 and abs(p[1]-1.1)<1e-5 and abs(p[2])<1e-5 for i,p in enumerate(positions))
        report['anchor_positions_godot']=dict(zip(anchors,positions))
    elif name=='seasoning_dispenser':
        for n in ['paprika_sweet','paprika_hot','salt','oil']:assert n in nodes and counts[n]<=800
    else:
        for i in range(5):assert 'Portions'+str(i) in nodes
        assert 'OutlineHull' in nodes and 'BowlHull' in nodes
        assert all(counts['Portions'+str(i+1)]>counts['Portions'+str(i)] for i in range(4))
        active=sum(counts.values())-sum(counts['Portions'+str(i)] for i in range(4))
        assert active<=800,active
        report['bowl_max_active_including_hull']=active
assert sum(sum(v.values()) for k,v in report.items() if k in ['seasoning_station','seasoning_dispenser','cachelos_bowl'])<=6000
for name,h in [('paprika','D6361F'),('hot_paprika','8F1A14'),('cachelos','F2D56B'),('salt','F7F4EC'),('oil','F2C230')]:
    text=(root/f'godot/data/seasonings/{name}.tres').read_text()
    rgb=[float(x) for x in re.search(r'color = Color\(([^)]+)',text)[1].split(',')][:3]
    assert all(abs(rgb[i]-int(h[i*2:i*2+2],16)/255)<1e-6 for i in range(3)),name
report['palette']='PASS: all five data colors match art bible 2.5'
(root/'docs/evidence/PUL-094/validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS: palette, all five portions, variant names, anchors, no tray, per-prop and total budgets')
