"""PUL-096 kiosks: order plate, delivery frame and exported state materials."""
import json
import math
from pathlib import Path

import bpy

exec((Path.cwd() / 'docs/evidence/PUL-094/art_helpers.py').read_text(encoding='utf8'))
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/blender/order_stand.blend'))
coll = bpy.data.collections['export']
parent = bpy.data.objects['order_stand']
for obj in list(coll.objects):
    if obj.name.startswith(('OrderPlate', 'Anchor_OrderLabel', 'delivery_zone', 'Anchor_Delivery', 'Delivery')):
        bpy.data.objects.remove(obj, do_unlink=True)
mat, image = atlas('kiosk_delivery_signs')
# Paper sign faces the kitchen camera once the kiosk is rotated by PI in the level.
plate = cube('OrderPlateFrame', (0, .20, 1.88), (1.02, .50, .024), parent, coll, mat, 'navy')
plate.rotation_euler.x = math.radians(-52)
bpy.context.view_layer.objects.active = plate
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
paper = sign('OrderPlatePaper', (0, .216, 1.893), .95, .43, parent, coll, mat, 'paper', 'flat')
paper.rotation_euler.x = math.radians(-52)
bpy.context.view_layer.objects.active = paper
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
empty('Anchor_OrderLabel', (0, .23, 1.905), parent, coll)

# Low-profile frame: Z=+3.4 avoids the canopy's projected occlusion at the game pitch.
off = bpy.data.materials.get('delivery_zone_off') or mat.copy()
off.name = 'delivery_zone_off'
on = bpy.data.materials.get('delivery_zone_on') or mat.copy()
on.name = 'delivery_zone_on'
bs = on.node_tree.nodes.get('Principled BSDF')
bs.inputs['Emission Color'].default_value = (*rgb('#D2473F'), 1)
bs.inputs['Emission Strength'].default_value = .35
zone = cube('delivery_zone', (0, -3.4, .008), (1.45, 1.05, .016), parent, coll,
            bpy.data.materials['mat_rubber'], bevel=.005)
parts = []
for side in (-1, 1):
    parts.append(cube('DeliveryEdgeX', (0, -3.4 + side * .48, .018),
                     (1.4, .07, .004), parent, coll, off, 'paper'))
    parts.append(cube('DeliveryEdgeY', (side * .68, -3.4, .018),
                     (.07, .96, .004), parent, coll, off, 'paper'))
parts.append(sign('DeliveryArrow', (0, -3.4, .020), .34, .43, parent, coll, off, 'arrow', 'flat'))
bpy.ops.object.select_all(action='DESELECT')
frame = parts[0]
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = frame
bpy.ops.object.join()
frame.name = 'DeliveryFrame'
frame.parent = zone
# Parenting preserves the world frame, bake the inverse parent transform into local geometry.
frame.location -= zone.location
frame.data.materials.append(on)  # unused slot still retains the alternate material in Blender
empty('Anchor_DeliveryZone', (0, -3.4, .020), parent, coll)

save('order_stand')
out = ROOT / 'godot/assets/models/stations/order_stand'
counts = {'order_stand': export_piece('export', 'Anchor_Front', out / 'order_stand.glb', 6000)}
# glTF drops unused material slots. Export both materials as explicit Godot resources for swapping.
for state, emission in [('off', False), ('on', True)]:
    resource = '[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n'
    resource += '[ext_resource type="Texture2D" path="res://assets/models/stations/order_stand/order_stand_kiosk_delivery_signs.png" id="1_atlas"]\n\n[resource]\n'
    resource += 'resource_name = "delivery_zone_' + state + '"\n'
    resource += 'albedo_texture = ExtResource("1_atlas")\nroughness = 0.82\n'
    if emission:
        resource += 'emission_enabled = true\nemission = Color(0.8235294, 0.2784314, 0.2470588, 1)\nemission_energy_multiplier = 0.35\n'
    (out / ('delivery_zone_' + state + '.tres')).write_text(resource, encoding='utf8')
(ROOT / 'docs/evidence/PUL-096/budget.json').write_text(json.dumps(counts, indent=2))
(ROOT / 'docs/evidence/PUL-096/integration.json').write_text(json.dumps({
    'stand_colors': ['#D2473F', '#3F7CC8', '#E8C23A', '#4FA05A'],
    'delivery_zone_center_godot': [0, .008, 3.4],
    'delivery_zone_size': [1.45, .016, 1.05],
    'delivery_frame_path': 'order_stand/delivery_zone/DeliveryFrame',
    'order_label_center_godot': [0, 1.905, -.23],
    'order_plate_dimensions': [1.02, .50, .024],
    'emission_energy': .35,
}, indent=2))
print('PUL-096 budgets', counts)
