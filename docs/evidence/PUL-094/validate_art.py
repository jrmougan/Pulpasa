"""Audit exported triangle budgets, normative colors, nodes and working-tree owns."""
import json
import re
import struct
import subprocess
from pathlib import Path, PurePosixPath

ROOT = Path.cwd()


def glb(path):
    data = (ROOT / 'godot/assets/models' / path).read_bytes()
    size = struct.unpack_from('<I', data, 12)[0]
    return json.loads(data[20:20 + size])


def node_triangles(data, name):
    nodes = data['nodes']
    def triangles(index):
        obj = nodes[index]
        result = 0
        if 'mesh' in obj:
            for primitive in data['meshes'][obj['mesh']]['primitives']:
                accessor = primitive.get('indices', primitive['attributes']['POSITION'])
                result += data['accessors'][accessor]['count'] // 3
        return result + sum(triangles(child) for child in obj.get('children', []))
    return triangles(next(i for i, obj in enumerate(nodes) if obj.get('name') == name))


box = glb('items/box/box.glb')
octopus = glb('food/octopus/octopus_pieces.glb')
potato = glb('food/cachelos/cachelos_pieces.glb')
food = sum(node_triangles(octopus, 'octopus_pieces_' + key) for key in ('a', 'b', 'c'))
food += sum(node_triangles(potato, 'cachelos_pieces_' + key) for key in ('a', 'b'))
report = {'food_full': food, 'badge_and_progress_reserve': 32, 'box_full': {}}
for key in ('small', 'medium', 'large'):
    total = node_triangles(box, 'box_' + key) + node_triangles(box, 'hull_' + key) + food + 32
    report['box_full'][key] = total
    assert total <= 2000, (key, total)
station = glb('stations/seasoning_station/seasoning_station.glb')
positions = []
for name in ('SweetPaprika', 'HotPaprika', 'Salt', 'Oil'):
    node = next(o for o in station['nodes'] if o.get('name') == 'Anchor_Dispenser_' + name)
    positions.append(node['translation'][0])
positions.append(next(o for o in station['nodes'] if o.get('name') == 'Anchor_Bowl')['translation'][0])
assert positions == [-2, -1, 0, 1, 2], positions
assert all(b - a >= 1 for a, b in zip(positions, positions[1:]))
assert not any(o.get('name') in ('tray', 'Anchor_Tray') for o in station['nodes'])
bowl = glb('stations/seasoning_station/cachelos_bowl.glb')
assert all(any(o.get('name') == 'Portions%d' % i and 'mesh' in o for o in bowl['nodes']) for i in range(5))
for name, color in [('paprika', 'D6361F'), ('hot_paprika', '8F1A14'), ('cachelos', 'F2D56B')]:
    text = (ROOT / 'godot/data/seasonings' / (name + '.tres')).read_text(encoding='utf8')
    actual = [float(v.strip()) for v in re.search(r'color = Color\((.*?)\)', text)[1].split(',')]
    assert all(abs(actual[i] - int(color[i * 2:i * 2 + 2], 16) / 255) < 1e-6 for i in range(3))
    assert actual[3] == 1
report['station_centers_x'] = positions
report['native_pixels_per_metre'] = 1080 / 12.74
report['button_icon_ink_width_px'] = .225 * 1080 / 12.74 * 100 / 128 / .94
assert report['button_icon_ink_width_px'] >= 12

# Same pattern matching as tools/check_owns.py, adapted to three cards in one uncommitted tree.
changed = subprocess.check_output(['git', 'diff', '--name-only'], text=True).splitlines()
changed += subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard'], text=True).splitlines()
allowed = {}
for task in ('PUL-094', 'PUL-095', 'PUL-096'):
    card = next((ROOT / 'docs/backlog').glob(task + '-*.md'))
    text = card.read_text(encoding='utf8')
    patterns = re.search(r'^owns: \[(.*?)\]', text, re.M)[1].split(',')
    allowed[task] = [p.strip() for p in patterns]
outside = [p for p in changed if not any(PurePosixPath(p).full_match(pattern) for patterns in allowed.values() for pattern in patterns)]
assert outside == [], outside
report['ownership'] = {task: [p for p in changed if any(PurePosixPath(p).full_match(pattern) for pattern in patterns)]
                       for task, patterns in allowed.items()}
assert not any(p.endswith('.tscn') for p in changed)
(ROOT / 'docs/evidence/PUL-094/validation.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print(json.dumps({key: value for key, value in report.items() if key != 'ownership'}, indent=2))
print('OWNERSHIP OK:', len(changed), 'paths across three cards; no scenes edited')
