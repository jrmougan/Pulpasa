"""Geometría de art/blender/pot.blend (PUL-048), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-048/build_pot.py").read(), ns); ns["build_all"]()

Crea en la colección `export` la raíz `pot` con dos mallas hermanas (art-bible §2.1/§3.5/§4):
- `pot_body`: caldeiro de cobre panzudo y ABIERTO (boca de 0,69 m de luz) con borde grueso
  `copper_light`, interior y caldo `copper_dark` a 0,10 m bajo el borde (z = 0,90) y dos asas de
  aro `iron_black`. Origen en su base (z = 0,40) para poder moverlo o animarlo aparte.
  Cuelgan de él `Anchor_Slot_0..1` (plazas de la capacidad D9, en x = ∓0,15 como
  `CookingStation.SLOT_SPACING`, sobre el caldo) y `Anchor_Steam` (boca).
- `stove_base`: fogón de leña: trébede de hierro (aro + tres patas, ninguna delante), tres troncos
  `wood_dark`, brasas `fire` y un círculo de piedras `ground_stone`. De él cuelga `Anchor_Fire`.
Llamas y vapor son partículas de motor (kitchen.tscn), no modelo. Frente +Y (−Z en Godot); sin
caras inferiores ni ocultas (§2.2). Se versiona como registro reproducible.
"""

import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

SEGS = 24
POT_BASE_Z = 0.40
RIM_Z = 1.0
BROTH_Z = 0.90
SLOT_X = 0.15  # CookingStation.SLOT_SPACING / 2 (capacidad 2, kitchen.tres)
SLOT_Z = 0.86
SLOT_RING = (0.115, 0.135)  # radios interior/exterior del aro de cada plaza
# Perfil exterior (radio, z) de abajo arriba hasta el borde; luego el borde y el interior.
OUTER = [(0.12, 0.42), (0.24, 0.45), (0.32, 0.52), (0.365, 0.62), (0.375, 0.71), (0.365, 0.81), (0.35, 0.90), (0.345, 0.95)]
RIM = [(0.38, 0.965), (0.385, RIM_Z)]
INNER = [(0.345, RIM_Z), (0.335, 0.965), (0.33, BROTH_Z)]


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


def ring(bm, r, z, offset=Vector()):
    return [bm.verts.new(offset + Vector((r * math.cos(2 * math.pi * k / SEGS), r * math.sin(2 * math.pi * k / SEGS), z))) for k in range(SEGS)]


def bridge(bm, lo, hi, idx, smooth=True):
    n = len(lo)
    for k in range(n):
        f = bm.faces.new((lo[k], lo[(k + 1) % n], hi[(k + 1) % n], hi[k]))
        f.material_index = idx
        f.smooth = smooth


def disc(bm, r, z, idx, center=Vector()):
    rim = ring(bm, r, z, center)
    c = bm.verts.new(center + Vector((0, 0, z)))
    for k in range(SEGS):
        f = bm.faces.new((c, rim[k], rim[(k + 1) % SEGS]))
        f.material_index = idx


def torus(bm, center, major, minor, axis, idx, segs=10, sides=4, tilt=0.0):
    """Aro de sección `sides`; `axis` = normal del plano del aro ('X', 'Y' o 'Z')."""
    rot = {"Z": Matrix.Identity(3), "Y": Matrix.Rotation(math.pi / 2, 3, "X"), "X": Matrix.Rotation(math.pi / 2, 3, "Y")}[axis]
    rings = []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        d = Vector((math.cos(a), math.sin(a), 0))
        rr = []
        for j in range(sides):
            b = 2 * math.pi * j / sides + tilt
            p = d * (major + minor * math.cos(b)) + Vector((0, 0, minor * math.sin(b)))
            rr.append(bm.verts.new(center + rot @ p))
        rings.append(rr)
    for i in range(segs):
        a, b = rings[i], rings[(i + 1) % segs]
        for j in range(sides):
            f = bm.faces.new((a[j], b[j], b[(j + 1) % sides], a[(j + 1) % sides]))
            f.material_index = idx
            f.smooth = True


def beam(bm, p0, p1, w0, w1, idx, sides=4, caps=(False, True)):
    """Prisma de `sides` lados de p0 a p1 (patas, troncos); tapa solo donde se ve."""
    axis = (p1 - p0).normalized()
    up = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    u = axis.cross(up).normalized()
    v = axis.cross(u).normalized()
    ends = []
    for p, w in ((p0, w0), (p1, w1)):
        ends.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / sides + math.pi / sides) + v * math.sin(2 * math.pi * k / sides + math.pi / sides)) * w) for k in range(sides)])
    for k in range(sides):
        f = bm.faces.new((ends[0][k], ends[0][(k + 1) % sides], ends[1][(k + 1) % sides], ends[1][k]))
        f.material_index = idx
    for end, cap in zip(ends, caps):
        if cap:
            f = bm.faces.new(end if end is ends[1] else list(reversed(end)))
            f.material_index = idx


def rock(bm, center, size, yaw, idx, seed):
    rnd = random.Random(seed)
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    rot = Matrix.Rotation(yaw, 3, "Z")
    for vert in res["verts"]:
        j = 1.0 + rnd.uniform(-0.15, 0.15)
        p = Vector((vert.co.x * size.x, vert.co.y * size.y, max(vert.co.z, -0.3) * size.z)) * j
        vert.co = center + rot @ p + Vector((0, 0, 0.3 * size.z))
    for f in {f for vert in res["verts"] for f in vert.link_faces}:
        f.material_index = idx
    # Cara inferior fuera (apoya en el suelo).
    bm.normal_update()
    bottom = [f for f in {f for vert in res["verts"] for f in vert.link_faces} if f.normal.z < -0.95]
    bmesh.ops.delete(bm, geom=bottom, context="FACES")


def build_pot_body(root, coll):
    ob = new_mesh_object("pot_body", ["mat_copper", "mat_copper_light", "mat_copper_dark", "mat_iron_black"], root, coll, (0, 0, POT_BASE_Z))
    off = Vector((0, 0, -POT_BASE_Z))
    bm = bmesh.new()
    rings = [ring(bm, r, z, off) for r, z in OUTER + RIM + INNER]
    n_out, n_rim = len(OUTER), len(RIM)
    for i in range(len(rings) - 1):
        idx = 0 if i < n_out - 1 else (1 if i < n_out + n_rim else 2)
        bridge(bm, rings[i], rings[i + 1], idx, smooth=idx == 0)
    disc(bm, INNER[-1][0] + 0.002, BROTH_Z + off.z, 2)  # caldo/interior (§3.5: #8A4220)
    # Plazas visibles (D9, §3.5): un aro de cobre sobre el caldo en cada Anchor_Slot.
    for x in (-SLOT_X, SLOT_X):
        lo = ring(bm, SLOT_RING[0], BROTH_Z + 0.002 + off.z, Vector((x, 0, 0)))
        hi = ring(bm, SLOT_RING[1], BROTH_Z + 0.002 + off.z, Vector((x, 0, 0)))
        bridge(bm, hi, lo, 1, smooth=False)
    # Fondo: abanico hasta el centro (apenas se ve, pero cierra la silueta lateral baja).
    c = bm.verts.new(off + Vector((0, 0, POT_BASE_Z)))
    for k in range(SEGS):
        f = bm.faces.new((c, rings[0][(k + 1) % SEGS], rings[0][k]))
        f.material_index = 0
    # Asas de aro a los lados, en el plano XZ (se ven de frente desde la cámara).
    for s in (-1, 1):
        torus(bm, off + Vector((s * 0.405, 0, 0.84)), 0.065, 0.014, "Y", 3, segs=10, sides=4)
        beam(bm, off + Vector((s * 0.345, 0, 0.905)), off + Vector((s * 0.405, 0, 0.905)), 0.022, 0.022, 3, sides=4, caps=(False, False))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def build_stove_base(root, coll):
    ob = new_mesh_object("stove_base", ["mat_iron_black", "mat_wood_dark", "mat_fire", "mat_ground_stone"], root, coll)
    bm = bmesh.new()
    # Trébede: aro bajo el caldeiro y tres patas abiertas (a 30°, 150° y 270°: el frente queda libre).
    torus(bm, Vector((0, 0, POT_BASE_Z - 0.02)), 0.23, 0.02, "Z", 0, segs=16, sides=4, tilt=math.pi / 4)
    for a in (30, 150, 270):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        top = d * 0.23 + Vector((0, 0, POT_BASE_Z - 0.02))
        foot = d * 0.33
        beam(bm, foot, top, 0.022, 0.018, 0, sides=4, caps=(False, False))
    # Leña: tres troncos en estrella con las puntas hacia fuera, brasas en el centro.
    # (Hacia atrás y los lados: el frente deja ver las brasas.)
    for a in (200, 270, 340):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        beam(bm, d * 0.04 + Vector((0, 0, 0.10)), d * 0.32 + Vector((0, 0, 0.045)), 0.045, 0.045, 1, sides=5, caps=(False, True))
    rock(bm, Vector((0, 0.03, 0)), Vector((0.16, 0.14, 0.09)), 0.3, 2, 7)
    # Círculo de piedras del fogón (ancho total ≈ 0,9 m).
    for i in range(10):
        a = 2 * math.pi * (i + 0.5) / 10
        center = Vector((math.cos(a), math.sin(a), 0)) * 0.37
        rock(bm, center, Vector((0.085, 0.075, 0.07)), a, 3, 11 + i)
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces:
        f.smooth = False
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
    root = bpy.data.objects.get("asset") or bpy.data.objects["pot"]
    root.name = "pot"
    body = build_pot_body(root, coll)
    base = build_stove_base(root, coll)
    bpy.context.view_layer.update()
    for i, x in enumerate((-SLOT_X, SLOT_X)):
        empty("Anchor_Slot_%d" % i, body, coll, (x, 0, SLOT_Z))
    empty("Anchor_Steam", body, coll, (0, 0, RIM_Z))
    empty("Anchor_Fire", base, coll, (0, 0, 0.12))
    tris = sum(len(p.vertices) - 2 for o in (body, base) for p in o.data.polygons)
    return {"tris": tris, "body": sum(len(p.vertices) - 2 for p in body.data.polygons)}
