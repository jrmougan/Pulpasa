"""PUL-094: modify existing production source, export three validated GLBs."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

exec((Path.cwd() / 'docs/evidence/PUL-094/art_helpers.py').read_text(encoding='utf8'))
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/blender/seasoning_station.blend'))
mat, image = atlas('seasoning_signs')
coll = bpy.data.collections['export']
root = bpy.data.objects['seasoning_station']
for obj in list(coll.objects):
    if obj.name in ('tray', 'cutting_board', 'Anchor_Tray') or obj.name.startswith(('Service', 'Label_', 'CounterArrow_')):
        bpy.data.objects.remove(obj, do_unlink=True)
# Stretch the existing steel frame, retaining its UVs, details and materials.
frame = bpy.data.objects['counter']
factor = 5.2 / (max(v.co.x for v in frame.data.vertices) - min(v.co.x for v in frame.data.vertices))
for vertex in frame.data.vertices:
    vertex.co.x *= factor
centers = {'SweetPaprika': -2, 'HotPaprika': -1, 'Salt': 0, 'Oil': 1}
for key, x in centers.items():
    bpy.data.objects['Anchor_Dispenser_' + key].location = (x, -.35, 1.10)
bpy.data.objects['Anchor_Bowl'].location = (2, -.15, 1.10)
cube('ServiceFascia', (0, -.573, .875), (5.18, .025, .24), root, coll, mat, 'navy')
cube('ServiceMat', (0, -.92, .009), (5.18, .55, .018), root, coll,
     bpy.data.materials['mat_rubber'], bevel=.01)
for i, kind in enumerate(('sweet', 'hot', 'salt', 'oil', 'potato')):
    x = i - 2
    cube('Label_' + kind, (x, -.593, .87), (.36, .012, .19), root, coll, mat, kind)
    sign('ServiceArrow_' + kind, (x, -.91, .020), .28, .36, root, coll, mat, 'arrow', 'flat')
    sign('CounterArrow_' + kind, (x, -.47, 1.104), .25, .17, root, coll, mat, 'arrow', 'flat')

disp_coll = bpy.data.collections['export_dispenser']
disp_root = bpy.data.objects['seasoning_dispenser']
variants = [('paprika_sweet', 'sweet'), ('paprika_hot', 'hot'), ('salt', 'salt'), ('oil', 'oil')]
for name, kind in variants:
    variant = bpy.data.objects[name]
    variant.data = bpy.data.meshes.new(name + '_v3')
    parts = []
    if kind == 'sweet':
        parts.append(cyl('SweetWideTin', (0, 0, .08), .145, .16, variant, disp_coll, mat, kind, 24))
        parts.append(cyl('SweetLid', (0, 0, .168), .15, .015, variant, disp_coll,
                         bpy.data.materials['mat_steel_dark'], vertices=24))
    elif kind == 'hot':
        parts.append(cyl('HotFacetedTin', (0, 0, .105), .11, .21, variant, disp_coll, mat, kind, 8))
        parts.append(cube('HotTab', (0, .05, .22), (.065, .12, .025), variant, disp_coll, mat, 'navy'))
    elif kind == 'salt':
        parts.append(cyl('SaltShaker', (0, 0, .085), .135, .17, variant, disp_coll, mat, kind, 16))
        parts.append(cyl('DarkSaltCap', (0, 0, .182), .14, .025, variant, disp_coll,
                         bpy.data.materials['mat_steel_dark'], vertices=16))
        for x in (-.055, 0, .055):
            parts.append(cyl('SaltCapHole', (x, .02, .196), .013, .001, variant, disp_coll, mat, 'paper', 8))
    else:
        parts.append(cyl('OilBottle', (0, 0, .1), .09, .20, variant, disp_coll, mat, kind, 16))
        parts.append(cyl('OilNeck', (0, 0, .217), .037, .034, variant, disp_coll,
                         bpy.data.materials['mat_steel_dark'], vertices=12))
        parts.append(cube('OilSpout', (.08, 0, .24), (.17, .037, .025), variant, disp_coll,
                          bpy.data.materials['mat_steel_brushed'], bevel=.006))
    # Paper circular push face, tilted toward the service side and orthographic camera.
    button = cyl('PushButton', (0, -.20, .085), .13, .012, variant, disp_coll, mat, 'paper', 24)
    button.rotation_euler.x = math.radians(52)
    bpy.context.view_layer.objects.active = button
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    parts.append(button)
    parts.append(sign('CanonicalIcon', (0, -.212, .095), .225, .225, variant, disp_coll, mat, kind + '_icon'))
    bpy.ops.object.select_all(action='DESELECT')
    variant.select_set(True)
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = variant
    bpy.ops.object.join()

bowl_coll = bpy.data.collections['export_bowl']
bowl_root = bpy.data.objects['cachelos_bowl']
for obj in list(bowl_coll.objects):
    if obj.name.startswith('Portions'):
        bpy.data.objects.remove(obj, do_unlink=True)
for i in range(5):
    # Exclusive state meshes: the zero state is the empty clay floor, never food.
    state = cyl('Portions%d' % i, (0, 0, .07), .145, .005, bowl_root, bowl_coll,
                bpy.data.materials['mat_clay'], vertices=16)
    for j in range(i):
        angle = j * math.pi / 2 + math.pi / 4
        potato = cyl('portion', (.085 * math.cos(angle), .085 * math.sin(angle), .12),
                     .06, .08, bowl_root, bowl_coll, bpy.data.materials['mat_food_potato_cooked'], vertices=6)
        bpy.ops.object.select_all(action='DESELECT')
        state.select_set(True)
        potato.select_set(True)
        bpy.context.view_layer.objects.active = state
        bpy.ops.object.join()
    # Bake location into geometry to keep the state meshes in the same coordinate space.
    bpy.context.view_layer.objects.active = state
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

save('seasoning_station')
out = ROOT / 'godot/assets/models/stations/seasoning_station'
counts = {}
for collection, anchor, name, budget in (
    ('export', 'Anchor_Front', 'seasoning_station', 4000),
    ('export_dispenser', 'Anchor_Front_dispenser', 'seasoning_dispenser', 2000),
    ('export_bowl', 'Anchor_Front_bowl', 'cachelos_bowl', 800),
):
    counts[name] = export_piece(collection, anchor, out / (name + '.glb'), budget)
assert sum(counts.values()) <= 6000, counts
(ROOT / 'docs/evidence/PUL-094/budget.json').write_text(json.dumps(counts, indent=2))
print('PUL-094 budgets', counts)
