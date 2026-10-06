"""Geometría de art/blender/octopus_storage.blend (PUL-049), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-049/build_octopus_storage.py").read(), ns); ns["build_all"]()

Crea en la colección `export` la raíz `octopus_storage` con dos mallas hermanas (art-bible §2.1/§3.5/§4):
- `chest_body`: arcón de feria 1,6 × 0,9 × 0,8 m (más bajo que los 1,0 m de la biblia, no tapa nada),
  gris acero con banda `canvas_stripe`, asas y herrajes `iron_black`, cuatro patas, hielo `ice_blue`
  hasta casi el borde y dos tentáculos `octopus_raw` asomando (uno cae por el frente: «de aquí sale
  el pulpo crudo»). Sin cara inferior.
- `Lid`: tapa separada (ajuste de la biblia §4), ABIERTA hacia atrás (105°). El origen del objeto
  está en la bisagra (borde trasero superior del arcón) para poder animarla girando sobre X; la
  inclinación va cocida en la geometría (los objetos exportados no llevan rotación).
Frente +Y (−Z en Godot). Se versiona como registro reproducible.
"""

import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

W, D = 1.6, 0.9
BODY_Z0, BODY_Z1 = 0.06, 0.80
WALL = 0.06
ICE_Z = 0.74
LID_OPEN_DEG = 105.0
LID_T = 0.05
HINGE = Vector((0.0, -D / 2, BODY_Z1 + 0.01))


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def new_mesh_object(name, mats, parent, coll, location=(0, 0, 0)):
    remove_object(name)
    me = bpy.data.meshes.new(name)
    for m in mats:
        me.materials.append(M[m])
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    ob.parent = parent
    ob.location = location
    return ob


def quad(bm, pts, idx, smooth=False):
    f = bm.faces.new([bm.verts.new(p) for p in pts])
    f.material_index = idx
    f.smooth = smooth
    return f


def box(bm, lo, hi, idx, skip=(), inward=False, rot=None, pivot=Vector()):
    """Caja alineada a ejes de lo a hi. `skip`: caras omitidas ('-x','+x','-y','+y','-z','+z')."""
    x0, y0, z0 = lo
    x1, y1, z1 = hi
    v = {
        "-x": [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)],
        "+x": [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)],
        "-y": [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)],
        "+y": [(x0, y1, z0), (x0, y1, z1), (x1, y1, z1), (x1, y1, z0)],
        "-z": [(x0, y0, z0), (x0, y1, z0), (x1, y1, z0), (x1, y0, z0)],
        "+z": [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
    }
    for k, pts in v.items():
        if k in skip:
            continue
        pts = [Vector(p) for p in pts]
        if rot is not None:
            pts = [pivot + rot @ (p - pivot) for p in pts]
        if inward:
            pts = list(reversed(pts))
        quad(bm, pts, idx)


def catmull(pts, per=5):
    out = []
    n = len(pts)
    for i in range(n - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, n - 1)]
        for s in range(per):
            t = s / per
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t**3))
    out.append(pts[-1])
    return out


def tentacle(bm, ctrl, radii, light_idx, dark_idx, sides=8):
    """Tubo cónico por una curva de control; la franja de ventosas (cara inferior) en `dark_idx`."""
    path = catmull([Vector(p) for p in ctrl])
    n = len(path)
    # radio interpolado por tramo de control
    def rad(i):
        t = i / (n - 1) * (len(radii) - 1)
        a = min(int(t), len(radii) - 2)
        return radii[a] + (radii[a + 1] - radii[a]) * (t - a)

    rings = []
    u = None
    rings = []
    for i, p in enumerate(path):
        tan = ((path[min(i + 1, n - 1)] - path[max(i - 1, 0)])).normalized()
        if u is None:
            u = tan.cross(Vector((0, 1, 0)) if abs(tan.y) < 0.9 else Vector((1, 0, 0)))
        u = (u - tan * u.dot(tan)).normalized()  # transporte paralelo: sin torsión
        v = tan.cross(u).normalized()
        ring = []
        for k in range(sides):
            a = 2 * math.pi * k / sides
            ring.append((bm.verts.new(p + (u * math.cos(a) + v * math.sin(a)) * rad(i)), (u * math.cos(a) + v * math.sin(a))))
        rings.append(ring)
    for i in range(n - 1):
        for k in range(sides):
            a, b = rings[i], rings[i + 1]
            f = bm.faces.new((a[k][0], a[(k + 1) % sides][0], b[(k + 1) % sides][0], b[k][0]))
            nrm = a[k][1] + a[(k + 1) % sides][1]
            f.material_index = dark_idx if nrm.z < -0.6 else light_idx
            f.smooth = True
    tip = bm.verts.new(path[-1] + (path[-1] - path[-2]).normalized() * rad(n - 1))
    for k in range(sides):
        f = bm.faces.new((rings[-1][k][0], rings[-1][(k + 1) % sides][0], tip))
        f.material_index = light_idx
        f.smooth = True
    # Base dentro del hielo: no se ve, sin tapa.


def build_chest(root, coll):
    ob = new_mesh_object("chest_body", ["mat_steel_grey", "mat_iron_black", "mat_canvas_stripe", "mat_ice_blue", "mat_octopus_raw", "mat_octopus_raw_dark"], root, coll)
    bm = bmesh.new()
    hx, hy = W / 2, D / 2
    z0, z1 = BODY_Z0, BODY_Z1
    # Casco exterior sin tapa ni fondo, y casco interior hasta el hielo.
    box(bm, (-hx, -hy, z0), (hx, hy, z1), 0, skip=("-z", "+z"))
    box(bm, (-hx + WALL, -hy + WALL, ICE_Z), (hx - WALL, hy - WALL, z1), 0, skip=("+z",), inward=True)
    # Borde superior (marco entre exterior e interior).
    quad(bm, [(-hx, -hy, z1), (hx, -hy, z1), (hx - WALL, -hy + WALL, z1), (-hx + WALL, -hy + WALL, z1)], 0)
    quad(bm, [(hx, -hy, z1), (hx, hy, z1), (hx - WALL, hy - WALL, z1), (hx - WALL, -hy + WALL, z1)], 0)
    quad(bm, [(hx, hy, z1), (-hx, hy, z1), (-hx + WALL, hy - WALL, z1), (hx - WALL, hy - WALL, z1)], 0)
    quad(bm, [(-hx, hy, z1), (-hx, -hy, z1), (-hx + WALL, -hy + WALL, z1), (-hx + WALL, hy - WALL, z1)], 0)
    # Hielo: suelo del hueco y bloques que sobresalen del borde.
    quad(bm, [(-hx + WALL, -hy + WALL, ICE_Z), (hx - WALL, -hy + WALL, ICE_Z), (hx - WALL, hy - WALL, ICE_Z), (-hx + WALL, hy - WALL, ICE_Z)], 3)
    rnd = random.Random(49)
    cubes = [(-0.55, 0.05, 0.14), (-0.28, -0.12, 0.12), (0.05, -0.1, 0.13), (0.42, 0.10, 0.12), (0.58, -0.08, 0.11), (-0.05, 0.16, 0.10), (-0.5, 0.2, 0.10)]
    for cx, cy, s in cubes:
        rot = Matrix.Rotation(rnd.uniform(-0.6, 0.6), 3, "Z")
        top = ICE_Z + s * 1.0
        c = Vector((cx, cy, 0))
        box(bm, (cx - s, cy - s, ICE_Z), (cx + s, cy + s, top), 3, skip=("-z",), rot=rot, pivot=c)
    # Banda de feria alrededor del casco (ligeramente fuera).
    e = 0.004
    bz0, bz1 = 0.38, 0.50
    box(bm, (-hx - e, -hy - e, bz0), (hx + e, hy + e, bz1), 2, skip=("-z", "+z"))
    # Patas.
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(bm, (sx * (hx - 0.14) - 0.06, sy * (hy - 0.12) - 0.06, 0), (sx * (hx - 0.14) + 0.06, sy * (hy - 0.12) + 0.06, z0), 1, skip=("-z", "+z"))
    # Asas en los extremos (arco de hierro en el plano YZ).
    for s in (-1, 1):
        x = s * (hx + 0.02)
        box(bm, (x - 0.02, -0.22, 0.58), (x + 0.02, -0.18, 0.66), 1, skip=("-x" if s > 0 else "+x",))
        box(bm, (x - 0.02, 0.18, 0.58), (x + 0.02, 0.22, 0.66), 1, skip=("-x" if s > 0 else "+x",))
        box(bm, (x - 0.02, -0.22, 0.62), (x + 0.04 * s + 0.02, 0.22, 0.66), 1, skip=("-x" if s > 0 else "+x",))
    # Pestillo en el frente y bisagras atrás.
    box(bm, (-0.07, hy, 0.62), (0.07, hy + 0.03, 0.76), 1, skip=("-y",))
    for x in (-0.55, 0.55):
        box(bm, (x - 0.08, -hy - 0.03, 0.62), (x + 0.08, -hy, 0.80), 1, skip=("+y",))
    # Tentáculos: A cae por el frente derecho, B se enrosca hacia arriba a la izquierda.
    tentacle(bm, [(0.25, -0.02, 0.68), (0.27, 0.04, 0.95), (0.34, 0.20, 1.12), (0.42, 0.38, 1.04), (0.46, 0.52, 0.86), (0.44, 0.58, 0.70)], [0.075, 0.07, 0.058, 0.046, 0.035, 0.02], 4, 5)
    tentacle(bm, [(-0.32, 0.0, 0.68), (-0.34, 0.0, 0.98), (-0.27, 0.06, 1.18), (-0.16, 0.14, 1.26), (-0.10, 0.20, 1.20)], [0.07, 0.06, 0.05, 0.04, 0.02], 4, 5)
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def build_lid(root, coll):
    ob = new_mesh_object("Lid", ["mat_steel_grey", "mat_iron_black", "mat_canvas_stripe"], root, coll, HINGE)
    bm = bmesh.new()
    rot = Matrix.Rotation(math.radians(LID_OPEN_DEG), 3, "X")
    hx, hy = W / 2 + 0.02, D / 2 + 0.02
    # Tapa cerrada local: bisagra en y=0, extendida en +Y, losa de LID_T (cuelga bajo la bisagra).
    box(bm, (-hx, 0.0, -LID_T), (hx, 2 * hy, 0.0), 0, rot=rot)
    # Franja de feria en la cara exterior y tirador, ya girados.
    box(bm, (-hx + 0.1, 0.28, 0.004), (hx - 0.1, 0.46, 0.012), 2, skip=("-z",), rot=rot)
    box(bm, (-0.12, 2 * hy - 0.08, 0.004), (0.12, 2 * hy - 0.04, 0.05), 1, rot=rot)
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def empty(name, parent, coll, world_loc):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "SPHERE"
    ob.empty_display_size = 0.03
    coll.objects.link(ob)
    ob.parent = parent
    ob.location = Vector(world_loc) - parent.matrix_world.translation
    return ob


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("asset") or bpy.data.objects["octopus_storage"]
    root.name = "octopus_storage"
    body = build_chest(root, coll)
    lid = build_lid(root, coll)
    bpy.context.view_layer.update()
    tris = sum(len(p.vertices) - 2 for o in (body, lid) for p in o.data.polygons)
    return {"tris": tris}
