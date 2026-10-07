"""PUL-096 additive rebuild. Run from repo root with Blender -b order_stand.blend.
Keeps the source's existing geometry, linked materials and anchors verbatim.
"""
from pathlib import Path
import math
import bpy
from mathutils import Vector

ROOT = Path.cwd()
ns = {}
exec(bpy.data.texts['build_order_stand.py'].as_string(), ns)
Builder, P = ns['Builder'], ns['P']
coll = bpy.data.collections['export']
root = bpy.data.objects['order_stand']
# Reuse the existing atlas, filling one previously unused cell; no extra texture.
ns['CELLS']['navy'] = (3, 1)
ns['SOLID'].add('navy')
img = bpy.data.images['order_stand_atlas']
pixels = list(img.pixels[:])
for y in range(128, 256):
    for x in range(384, 512):
        i = 4 * (y * 512 + x)
        pixels[i:i+4] = (29/255, 53/255, 87/255, 1)
img.pixels.foreach_set(pixels)
img.pack()
# Camera-facing rigid sign, with baked tilt (unit node scale/rotation).
# Its centre is behind the existing billboard OrderLabel, no label/anchor edit.
center = Vector((0, 1.755, -0.0878))
up = Vector((0, math.cos(math.radians(38)), math.sin(math.radians(38))))
normal = Vector((0, math.sin(math.radians(38)), -math.cos(math.radians(38))))
center += normal * .24  # Stand off the sloping canvas without changing projected label centre.
def panel(b, width, height, depth, offset, material, bevel):
    points = []
    for h in (-height/2, height/2):
        for x, d in ((-width/2, -depth/2), (width/2, -depth/2), (width/2, depth/2), (-width/2, depth/2)):
            points.append(tuple(center + Vector((x,0,0)) + up*h + normal*(d+offset)))
    b.hexa(points, material, bevel)
b = Builder()
panel(b, 1.12, .48, .032, -.027, '@navy', .016)
panel(b, 1.02, .38, .012, -.006, '@paper', .006)
b.finish('order_id_plate', root, coll)
# Coordinator approved visible marks at local +Z 2.50; PUL-100 aligns Area3D.
# Compensate level_01 station base y=-.04; 14 mm raised paint/mat: no collider. Four corners, clear centre and open entry.
b = Builder()
for sx in (-1, 1):
    x0, x1 = (0.50, .65) if sx > 0 else (-.65,-.50)
    for z0,z1 in ((.52,.90),(1.43,1.81)):
        b.box(x0,x1,.045,.057,z0,z1,'@paper')
    x0,x1 = (.30,.65) if sx > 0 else (-.65,-.30)
    for z0,z1 in ((.52,.67),(1.66,1.81)):
        b.box(x0,x1,.045,.057,z0,z1,'@paper')
border = b.finish('delivery_zone_border', root, coll)
for v in border.data.vertices:
    v.co.y -= 1.335  # local Godot +Z
b = Builder()
for sx in (-1,1):
    x0,x1=(.53,.62) if sx>0 else (-.62,-.53)
    for z0,z1 in ((.55,.87),(1.46,1.78)):
        b.box(x0,x1,.057,.059,z0,z1,'@navy')
    x0,x1=(.33,.62) if sx>0 else (-.62,-.33)
    for z0,z1 in ((.55,.64),(1.69,1.78)):
        b.box(x0,x1,.057,.059,z0,z1,'@navy')
zone = b.finish('delivery_zone', root, coll)
for v in zone.data.vertices:
    v.co.y -= 1.335
# Keep an auditable source inside the blend too.
src = bpy.data.texts.get('build_kiosks_PUL096.py') or bpy.data.texts.new('build_kiosks_PUL096.py')
src.from_string(Path(__file__).read_text())
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/order_stand.blend'))
