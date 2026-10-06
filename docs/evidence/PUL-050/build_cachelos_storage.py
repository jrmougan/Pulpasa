"""Geometría de art/blender/cachelos_storage.blend (PUL-050), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-050/build_cachelos_storage.py").read(), ns); ns["build_all"]()
Crea en la colección `export` la raíz `cachelos_storage` con dos mallas hermanas (art-bible §2.1/§3.5):
- `sack`: saco de arpillera (`mat_burlap`) 0,56 × 0,46 m de planta, boca enrollada y cuerda `mat_wood_dark`.
- `potatoes`: montón de patatas crudas con la misma forma, material y exageración que
  `cachelos_raw` de PUL-046 (`add_potato`, SCALE 1,9 → aquí 1,6 para que quepan en la boca).
Medidas ≈ 0,6 × 0,5 × 0,5 m. Frente +Y (−Z en Godot). Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials
SCALE = 1.6


def wobble(th, phi, seed):
    return 1.0 + 0.07 * math.sin(3 * th + seed) * math.sin(phi) + 0.05 * math.cos(2 * phi + 1.7 * seed)


def add_potato(bm, center, radii, yaw, skin_idx, dark_idx, seed, segs=10, rings=6):
    """Igual que en build_cachelos.py (PUL-046): elipsoide irregular, base algo aplastada, «ojos» oscuros."""
    rot = Matrix.Rotation(yaw, 3, "Z")
    rr = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs
            w = wobble(th, phi, seed)
            ring.append(Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), radii[2] * math.cos(phi))))
        rr.append(ring)
    zmin = -radii[2] * 0.88
    flat = [[Vector((p.x, p.y, max(p.z, zmin))) for p in ring] for ring in rr]
    lift = Vector((0, 0, -zmin))
    verts = [[bm.verts.new(center + lift + rot @ p) for p in ring] for ring in flat]
    top = bm.verts.new(center + lift + Vector((0, 0, radii[2])))
    bot = bm.verts.new(center + lift + Vector((0, 0, zmin)))
    eyes = {(1, (seed * 3) % segs), (2, (seed * 7 + 4) % segs), (3, (seed * 5 + 2) % segs)}
    for k in range(segs):
        f = bm.faces.new((top, verts[0][k], verts[0][(k + 1) % segs]))
        f.material_index = skin_idx
        f.smooth = True
        f = bm.faces.new((bot, verts[-1][(k + 1) % segs], verts[-1][k]))
        f.material_index = dark_idx
        f.smooth = True
    for j in range(len(verts) - 1):
        for k in range(segs):
            f = bm.faces.new((verts[j][k], verts[j + 1][k], verts[j + 1][(k + 1) % segs], verts[j][(k + 1) % segs]))
            low = j == len(verts) - 2
            f.material_index = dark_idx if low or (j, k) in eyes else skin_idx
            f.smooth = True


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def mesh_object(name, mats, parent, coll, fill):
    remove_object(name)
    me = bpy.data.meshes.new(name)
    for m in mats:
        me.materials.append(M[m])
    bm = bmesh.new()
    fill(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def lathe(bm, profile, rx, ry, segs, mat, closed_top=False):
    """Sólido de revolución elíptico. profile = [(z, factor_radio)] de abajo arriba; base cerrada."""
    rings = []
    for z, f in profile:
        rings.append([bm.verts.new((rx * f * math.cos(2 * math.pi * k / segs), ry * f * math.sin(2 * math.pi * k / segs), z)) for k in range(segs)])
    base = bm.verts.new((0, 0, profile[0][0]))
    for k in range(segs):
        bm.faces.new((base, rings[0][(k + 1) % segs], rings[0][k])).material_index = mat
    for j in range(len(rings) - 1):
        for k in range(segs):
            f = bm.faces.new((rings[j][k], rings[j][(k + 1) % segs], rings[j + 1][(k + 1) % segs], rings[j + 1][k]))
            f.material_index = mat
            f.smooth = True
    return rings


def build_sack(bm):
    segs = 16
    # Cuerpo: base estrecha, panza a z≈0,17, cuello algo más estrecho a z≈0,30.
    prof = [(0.0, 0.78), (0.04, 0.9), (0.17, 1.0), (0.27, 0.9), (0.31, 0.82)]
    lathe(bm, prof, 0.28, 0.23, segs, 0)
    # Boca enrollada: anillo grueso (arpillera enrollada hacia fuera) con sección de 6 puntos.
    tube = 6
    cz, cr, tr = 0.335, 0.86, 0.045
    ring_pts = []
    for i in range(tube):
        a = 2 * math.pi * i / tube
        ring_pts.append((cr + tr * 1.1 * math.cos(a), cz + tr * math.sin(a)))
    rings = [[bm.verts.new((0.28 * r * math.cos(2 * math.pi * k / segs), 0.23 * r * math.sin(2 * math.pi * k / segs), z)) for k in range(segs)] for r, z in ring_pts]
    for i in range(tube):
        for k in range(segs):
            f = bm.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[(i + 1) % tube][(k + 1) % segs], rings[(i + 1) % tube][k]))
            f.material_index = 0
            f.smooth = True
    # Cuerda: aro fino bajo el rollo (mat_wood_dark).
    zr, rr, t = 0.27, 0.93, 0.012
    rope = [[bm.verts.new((0.28 * (rr + dr) * math.cos(2 * math.pi * k / segs), 0.23 * (rr + dr) * math.sin(2 * math.pi * k / segs), zr + dz)) for k in range(segs)]
            for dr, dz in ((t, t), (t, -t), (-t, -t), (-t, t))]
    for i in range(4):
        for k in range(segs):
            f = bm.faces.new((rope[i][k], rope[i][(k + 1) % segs], rope[(i + 1) % 4][(k + 1) % segs], rope[(i + 1) % 4][k]))
            f.material_index = 1


# (x, y, z, yaw°, tamaño, semilla): montón que sobresale de la boca (z de base ≈ 0,30–0,36).
POTATOES = [
    (-0.115, 0.03, 0.30, -18, 1.0, 1),
    (0.10, -0.03, 0.30, 62, 0.95, 2),
    (-0.02, -0.095, 0.30, 100, 0.9, 4),
    (0.0, 0.085, 0.31, 25, 0.9, 5),
    (-0.035, 0.0, 0.375, 80, 0.95, 7),
    (0.075, 0.07, 0.355, -50, 0.8, 8),
]


def build_potatoes(bm):
    s = SCALE
    for x, y, z, yaw, k, seed in POTATOES:
        add_potato(bm, Vector((x, y, z)), (0.068 * s * k * 0.85, 0.05 * s * k * 0.85, 0.048 * s * k * 0.85), math.radians(yaw), 0, 1, seed)


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("cachelos_storage") or bpy.data.objects["asset"]
    root.name = "cachelos_storage"
    sack = mesh_object("sack", ("mat_burlap", "mat_wood_dark"), root, coll, build_sack)
    pots = mesh_object("potatoes", ("mat_potato_raw", "mat_wood_dark"), root, coll, build_potatoes)
    return sack, pots
