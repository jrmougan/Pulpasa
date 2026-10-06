"""Geometría de art/blender/cachelos.blend (PUL-046), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-046/build_cachelos.py").read(), ns); ns["build_all"]()
Crea `cachelos` (cachelos_raw + cachelos_cooked) en la colección `export` y `cachelos_pieces`
(capas a/b/c de trozos cocidos, una ración cada una) en la colección `export_pieces`. Mismo estilo y
convenciones que build_octopus.py (PUL-045). Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

# Exageración (art-bible §2.1: lo que se sostiene puede ser mayor que lo real). Una patata de
# ≈ 0,135 m pasa a ≈ 0,26 m: con ×1,4 (como el pulpo de PUL-045) el montón medía 0,30 m y se perdía
# junto al pulpo de 0,65 m desde la cámara del nivel; con ×1,9 mide ≈ 0,40 m.
SCALE = 1.9
# Trozos del cuenco/caja/olla algo menores que los del objeto en la mano (caben 6 en el cuenco
# de 0,5 m de la estación).
PIECES_SCALE = 1.3


def wobble(th: float, phi: float, seed: int) -> float:
    """Irregularidad determinista de la piel (patata no esférica)."""
    return 1.0 + 0.07 * math.sin(3 * th + seed) * math.sin(phi) + 0.05 * math.cos(2 * phi + 1.7 * seed)


def add_potato(bm, center, radii, yaw, skin_idx, dark_idx, seed, segs=10, rings=6):
    """Patata entera: elipsoide irregular apoyado en z = center.z; banda baja y «ojos» oscuros."""
    rot = Matrix.Rotation(yaw, 3, "Z")
    rr = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs
            w = wobble(th, phi, seed)
            p = Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), radii[2] * math.cos(phi)))
            ring.append(p)
        rr.append(ring)
    # Base algo aplastada (se apoya, no rueda) y elevación para que la base quede en z = 0.
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


def add_chunk(bm, base, radii, yaw, tilt, skin_idx, cut_idx, seed, segs=10, rings=3):
    """Medio cachelo: cúpula de piel y cara de corte plana. La cara de corte mira hacia arriba,
    inclinada `tilt` hacia la cámara (−Y) y ±12° de lado según `seed`; `yaw` solo gira la forma.
    `base` es el punto más bajo (apoyo)."""
    rr = []
    for j in range(1, rings + 1):
        phi = (math.pi / 2) * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs
            w = wobble(th, phi, seed)
            # Cúpula hacia −Z (la piel queda debajo, el corte arriba).
            ring.append(Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), -radii[2] * math.cos(phi))))
        rr.append(ring)
    bottom = Vector((0, 0, -radii[2]))
    side = math.radians(12) * (1 if seed % 2 else -1)
    xf = Matrix.Rotation(tilt, 3, "X") @ Matrix.Rotation(side, 3, "Y") @ Matrix.Rotation(yaw, 3, "Z")
    pts = [[xf @ p for p in ring] for ring in rr]
    zlow = min([p.z for ring in pts for p in ring] + [(xf @ bottom).z])
    off = base - Vector((0, 0, zlow))
    verts = [[bm.verts.new(off + p) for p in ring] for ring in pts]
    bv = bm.verts.new(off + xf @ bottom)
    for k in range(segs):
        f = bm.faces.new((bv, verts[0][(k + 1) % segs], verts[0][k]))
        f.material_index = skin_idx
        f.smooth = True
    for j in range(len(verts) - 1):
        for k in range(segs):
            f = bm.faces.new((verts[j][k], verts[j][(k + 1) % segs], verts[j + 1][(k + 1) % segs], verts[j + 1][k]))
            f.material_index = skin_idx
            f.smooth = True
    # Cara de corte con un borde del 20 % del radio en el tono oscuro (art-bible §3.3: borde #D8A93C):
    # separa cada trozo de sus vecinos aunque las caras claras se toquen.
    rim = verts[-1]
    mid = sum((v.co for v in rim), Vector()) / len(rim)
    inner = [bm.verts.new(mid + (v.co - mid) * 0.8) for v in rim]
    for k in range(segs):
        f = bm.faces.new((rim[k], rim[(k + 1) % segs], inner[(k + 1) % segs], inner[k]))
        f.material_index = skin_idx
        f.smooth = False
    cut = bm.faces.new(inner)
    cut.material_index = cut_idx
    cut.smooth = False


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    me = ob.data if ob.type == "MESH" else None
    bpy.data.objects.remove(ob)
    if me is not None and me.users == 0:
        bpy.data.meshes.remove(me)


def mesh_object(name, mats, parent, coll, fill):
    me = bpy.data.meshes.new(name)
    for m in mats:
        me.materials.append(M[m])
    bm = bmesh.new()
    fill(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def build_raw(bm):
    # Dos patatas enteras con piel (§3.3: 1–2 patatas), una algo girada y más pequeña.
    s = SCALE
    add_potato(bm, Vector((-0.045, 0.012, 0)) * s, (0.068 * s, 0.05 * s, 0.048 * s), math.radians(-18), 0, 1, 1)
    add_potato(bm, Vector((0.058, -0.02, 0)) * s, (0.058 * s, 0.045 * s, 0.044 * s), math.radians(62), 0, 1, 2)


# (x, y, yaw°, tilt°, tamaño) de cada medio cachelo del objeto cocido: montón de 4 (§3.3: 3–4).
COOKED_CHUNKS = [
    (-0.058, 0.025, 30, 8, 1.0),
    (0.06, 0.03, -40, 12, 0.95),
    (0.0, -0.045, 80, 4, 1.0),
]
COOKED_TOP = (0.0, 0.035, 0, 18, 0.9)


def build_cooked(bm):
    s = SCALE
    r = (0.058 * s, 0.044 * s, 0.05 * s)
    for i, (x, y, yaw, tilt, k) in enumerate(COOKED_CHUNKS):
        add_chunk(bm, Vector((x * s, y * s, 0)), tuple(v * k for v in r), math.radians(yaw), math.radians(tilt), 0, 1, i + 3)
    x, y, yaw, tilt, k = COOKED_TOP
    add_chunk(bm, Vector((x * s, y * s, 0.038 * s)), tuple(v * k for v in r), math.radians(yaw), math.radians(tilt), 0, 1, 9)


def rebuild_whole():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("cachelos") or bpy.data.objects["asset"]
    root.name = "cachelos"
    for nm in ("cachelos_raw", "cachelos_cooked"):
        remove_object(nm)
    raw = mesh_object("cachelos_raw", ("mat_potato_raw", "mat_wood_dark"), root, coll, build_raw)
    cooked = mesh_object("cachelos_cooked", ("mat_potato_cooked_dark", "mat_potato_cooked"), root, coll, build_cooked)
    return raw, cooked


# Trozos sueltos por capas (ración = una capa): el cuenco de la estación muestra a, a+b, a+b+c según
# su stock (1..3); sirven también para montones en caja u olla.
PIECE_LAYERS = {
    "a": [(-0.075, 0.04, 30, 8), (0.075, 0.045, -30, 8), (0.0, -0.07, 90, 4)],
    "b": [(-0.04, -0.01, 60, 14), (0.045, -0.005, -60, 14)],
    "c": [(0.0, 0.035, 0, 20)],
}
PIECE_BASE_Z = {"a": 0.0, "b": 0.035, "c": 0.07}


def build_pieces():
    coll = bpy.data.collections.get("export_pieces")
    if coll is None:
        coll = bpy.data.collections.new("export_pieces")
        bpy.context.scene.collection.children.link(coll)
    for nm in ("cachelos_pieces_a", "cachelos_pieces_b", "cachelos_pieces_c", "cachelos_pieces", "Anchor_Front_pieces"):
        remove_object(nm)
    root = bpy.data.objects.new("cachelos_pieces", None)
    root.empty_display_size = 0.1
    coll.objects.link(root)
    s = PIECES_SCALE
    r = (0.058 * s, 0.044 * s, 0.05 * s)
    layers = []
    seed = 20
    for layer, spots in PIECE_LAYERS.items():

        def fill(bm, spots=spots, layer=layer, seed=seed):
            for i, (x, y, yaw, tilt) in enumerate(spots):
                base = Vector((x * s, y * s, PIECE_BASE_Z[layer] * s))
                add_chunk(bm, base, r, math.radians(yaw), math.radians(tilt), 0, 1, seed + i)

        layers.append(mesh_object(f"cachelos_pieces_{layer}", ("mat_potato_cooked_dark", "mat_potato_cooked"), root, coll, fill))
        seed += 5
    # El marcador de frente cuelga de la capa a (siempre visible con stock ≥ 1): así los hijos
    # directos de la raíz son solo las tres capas que alterna `cachelos_bowl.gd`.
    front_src = bpy.data.objects["Anchor_Front"]
    front = bpy.data.objects.new("Anchor_Front_pieces", None)
    front.empty_display_type = front_src.empty_display_type
    front.empty_display_size = front_src.empty_display_size
    front.location = (0.0, 0.5, 0.0)
    front.parent = layers[0]
    coll.objects.link(front)
    return root


def build_all():
    raw, cooked = rebuild_whole()
    return raw, cooked, build_pieces()
