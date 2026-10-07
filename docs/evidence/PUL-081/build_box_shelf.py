"""Rack de bandejas v2 (PUL-081): art/blender/box_shelf.blend, generado con el MCP de Blender por CLI.

Se ejecuta dentro de Blender sobre una copia recién hecha de art/blender/_template.blend (materiales
v2 enlazados desde _materials_v2.blend) y la guarda:
    ns = {}; exec(open("docs/evidence/PUL-081/build_box_shelf.py").read(), ns); ns["build_all"]()

Estantería (art-bible v2 §1.2, §5 regla 2, §6.4, §8): **rack de acero** de cuatro baldas al fondo
(postes y largueros `mat_steel_brushed_mid`, baldas de varillas `mat_steel_dark`, cajas de cartón
`mat_cardboard` de atrezo) y, delante, un **banco bajo de acero** (tablero `mat_steel_brushed_top` a
0,31 m, la altura de los spawners) con una **pila de bandejas rojas por talla** delante de cada spawner.
Las bandejas son las mallas de PUL-077 (`box_small/medium/large` de `art/blender/box.blend`, con
`mat_plastic_red` y su atlas `atlas_box`), cuatro por pila y encajadas (paso de 0,035 m, giro de
±3° a mano); de las copias se borra lo que tapa la de encima (interior y pie), así cada pila cuesta
≈ 1 300 triángulos en vez de 2 300. En el faldón del banco, una etiqueta por talla con el color del aro
de la bandeja (azul, verde, papel; celdas `band_<talla>` de `atlas_box`), en Z2.

Contrato (el de PUL-051): raíz `box_shelf` con `Anchor_Front` (+Y de Blender = −Z de Godot), todo
dentro de la huella de la v1 (cuerpo 1,8 × 1,14 m, banco hasta y = 1,06); pilas en las posiciones de
`SmallSpawner`/`MediumSpawner`/`LargeSpawner` de `box_shelf.tscn` (Godot x = −0,51 / 0 / 0,536,
z = −0,78, y = 0,31). Bajo `OutlineHull`, un volumen cerrado invisible `hull_<talla>` por pila (alfa 0,
`mat_outline_hull` de PUL-077): la pila es abierta y el inverted hull necesita una malla cerrada
(nota de PUL-049); el `Highlightable` de cada spawner apunta a su hull.
"""

import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials
UV_M = 2.0  # 1 unidad de UV = 2 m (materials-v2.md §2)
ROOT_DIR = os.path.dirname(os.path.dirname(bpy.path.abspath("//").rstrip("/")))
BOX_BLEND = os.path.join(ROOT_DIR, "art/blender/box.blend")
BOX_SCRIPT = os.path.join(ROOT_DIR, "docs/evidence/PUL-077/build_box_v2.py")

# Huella (Blender: X derecha, Y frente, Z arriba).
HALF_W = 0.9
RACK_Y = (-0.56, -0.02)  # fondo del rack
RACK_H = 1.45
SHELVES = [0.10, 0.55, 1.00, RACK_H - 0.03]  # cara superior de cada balda
POST = 0.04
BENCH_Y = (0.02, 1.06)
BENCH_TOP = 0.31  # = y de los spawners en la escena
BENCH_THICK = 0.035

# Pilas: (talla, x, y) = posiciones de los spawners (Godot x, −z).
STACKS = [("small", -0.51, 0.78), ("medium", 0.0, 0.78), ("large", 0.536, 0.78)]
STACK_N = 4
STACK_STEP = 0.035
STACK_JITTER = (-2.5, 1.8, -1.2, 2.8)  # grados por bandeja, de abajo arriba (hechas a mano)
TRAY_HEIGHT = 0.098
HULL_GROW = 0.014  # margen para el giro de las bandejas

# Cajas de cartón del rack: (x, y, z de la balda, ancho, fondo, alto).
CARTONS = [
    (-0.52, -0.29, SHELVES[0], 0.52, 0.44, 0.36),
    (0.12, -0.30, SHELVES[0], 0.46, 0.42, 0.30),
    (0.50, -0.28, SHELVES[1], 0.48, 0.44, 0.32),
    (-0.42, -0.30, SHELVES[2], 0.56, 0.42, 0.26),
    (-0.50, -0.30, SHELVES[3], 0.50, 0.40, 0.14),
    (0.30, -0.28, SHELVES[3], 0.60, 0.44, 0.10),
]


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def box_uv(bm, uv, faces):
    """Proyección de caja a 1 UV = 2 m (materials-v2.md §2)."""
    for f in faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][ax]
        for lp in f.loops:
            co = lp.vert.co
            lp[uv].uv = (co[a] / UV_M, co[b] / UV_M)


def add_box(bm, mn, mx, mat_idx, bevel=0.0):
    """Caja (con chaflán opcional) de `mn` a `mx`; devuelve sus caras."""
    before = set(bm.faces)
    res = bmesh.ops.create_cube(bm, size=1.0)
    verts = res["verts"]
    size = Vector(mx) - Vector(mn)
    centre = (Vector(mx) + Vector(mn)) / 2
    for v in verts:
        v.co = Vector((v.co.x * size.x, v.co.y * size.y, v.co.z * size.z)) + centre
    if bevel > 0.0:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5)
    faces = [f for f in bm.faces if f not in before]
    for f in faces:
        f.material_index = mat_idx
    return faces


def new_object(name, bm, mats, parent, coll):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


# --- Rack y banco -------------------------------------------------------------------------------


def build_frame(parent, coll):
    """Rack de acero de cuatro baldas y banco bajo delante; un solo objeto `rack`."""
    mats = [M["mat_steel_brushed_mid"], M["mat_steel_dark"], M["mat_steel_brushed_top"]]
    MID, DARK, TOP = 0, 1, 2
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    faces = []
    y0, y1 = RACK_Y
    # Postes de esquina (perfil en L simplificado a cuadrado).
    for x in (-HALF_W + POST / 2, HALF_W - POST / 2):
        for y in (y0 + POST / 2, y1 - POST / 2):
            faces += add_box(bm, (x - POST / 2, y - POST / 2, 0.0), (x + POST / 2, y + POST / 2, RACK_H), MID, 0.006)
    # Baldas: larguero delantero y trasero, travesaños laterales y varillas.
    for z in SHELVES:
        for y in (y0 + POST / 2, y1 - POST / 2):
            faces += add_box(bm, (-HALF_W + POST, y - 0.012, z - 0.045), (HALF_W - POST, y + 0.012, z), MID, 0.004)
        for x in (-HALF_W + POST / 2, HALF_W - POST / 2):
            faces += add_box(bm, (x - 0.012, y0 + POST, z - 0.03), (x + 0.012, y1 - POST, z), MID)
        slats = 5
        span = (y1 - POST) - (y0 + POST)
        for k in range(slats):
            y = y0 + POST + span * (k + 0.5) / slats
            faces += add_box(bm, (-HALF_W + POST, y - 0.014, z - 0.012), (HALF_W - POST, y + 0.014, z - 0.002), DARK)
    # Banco: tablero, faldón delantero, patas y balda baja.
    b0, b1 = BENCH_Y
    faces += add_box(bm, (-HALF_W, b0, BENCH_TOP - BENCH_THICK), (HALF_W, b1, BENCH_TOP), TOP, 0.012)
    faces += add_box(bm, (-HALF_W + 0.03, b1 - 0.035, BENCH_TOP - 0.11), (HALF_W - 0.03, b1 - 0.015, BENCH_TOP - BENCH_THICK), MID, 0.004)
    for x in (-HALF_W + 0.05, HALF_W - 0.05):
        for y in (b0 + 0.05, b1 - 0.06):
            faces += add_box(bm, (x - 0.02, y - 0.02, 0.0), (x + 0.02, y + 0.02, BENCH_TOP - BENCH_THICK), MID)
    faces += add_box(bm, (-HALF_W + 0.07, b0 + 0.07, 0.07), (HALF_W - 0.07, b1 - 0.08, 0.085), DARK)
    box_uv(bm, uv, faces)
    return new_object("rack", bm, mats, parent, coll)


def build_cartons(parent, coll):
    """Cajas de cartón de atrezo en las baldas (Z2: fondo de la estación, no se cogen)."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    faces = []
    for x, y, z, w, d, h in CARTONS:
        faces += add_box(bm, (x - w / 2, y - d / 2, z), (x + w / 2, y + d / 2, z + h), 0, 0.012)
    box_uv(bm, uv, faces)
    return new_object("cartons", bm, [M["mat_cardboard"]], parent, coll)


# --- Pilas de bandejas --------------------------------------------------------------------------


def load_trays():
    """Mallas, atlas y material del hull de las bandejas de PUL-077 (anexadas, no enlazadas)."""
    want = ["box_small", "box_medium", "box_large", "hull_small"]
    before = set(bpy.data.objects)
    with bpy.data.libraries.load(BOX_BLEND, link=False) as (src, dst):
        dst.objects = [n for n in src.objects if n in want]
    meshes = {}
    hull_mat = None
    for ob in dst.objects:
        if ob.name.startswith("hull_"):
            hull_mat = ob.data.materials[0]
        else:
            meshes[ob.name.removeprefix("box_")] = ob.data
    # Se borran las bandejas anexadas y lo que arrastran (sus padres `box` y `OutlineHull`, anclas).
    for ob in [o for o in bpy.data.objects if o not in before]:
        bpy.data.objects.remove(ob, do_unlink=True)
    return meshes, hull_mat


def tray_faces_to_drop(f, level, top_level, half_x):
    """Caras que tapa la bandeja de encima (interior) o que quedan dentro de la de debajo (pie)."""
    c = f.calc_center_median()
    n = f.normal
    radial = Vector((c.x, c.y))
    inside = abs(c.x) <= half_x - 0.005
    side = Vector((n.x, n.y)).dot(radial.normalized()) if radial.length > 1e-4 else 0.0
    inward = side < -0.2
    outward = side > 0.2 and n.z < 0.5
    if level < top_level:
        if n.z > 0.5 and c.z < TRAY_HEIGHT - 0.01:
            return True  # papel y pliegue
        if inward and inside and c.z > 0.015:
            return True  # pared interior
    if level > 0 and c.z < TRAY_HEIGHT - STACK_STEP - 0.012 and outward:
        return True  # pie y pared baja, dentro de la bandeja de debajo
    return False


def build_stack(size, x, y, mesh, parent, coll):
    bm = bmesh.new()
    half_x = max(abs(v.co.x) for v in mesh.vertices)
    for level in range(STACK_N):
        tmp = bmesh.new()
        tmp.from_mesh(mesh)
        drop = [f for f in tmp.faces if tray_faces_to_drop(f, level, STACK_N - 1, half_x if size != "large" else 0.222)]
        bmesh.ops.delete(tmp, geom=drop, context="FACES")
        # 180°: el símbolo del canto mira al frente (+Y); giro a mano por bandeja.
        rot = Matrix.Rotation(math.radians(180.0 + STACK_JITTER[level]), 4, "Z")
        mat = Matrix.Translation((x, y, BENCH_TOP + level * STACK_STEP)) @ rot
        bmesh.ops.transform(tmp, matrix=mat, verts=tmp.verts[:])
        me_tmp = bpy.data.meshes.new("_tmp_tray")
        tmp.to_mesh(me_tmp)
        tmp.free()
        bm.from_mesh(me_tmp)
        bpy.data.meshes.remove(me_tmp)
    me = bpy.data.meshes.new(f"stack_{size}")
    bm.to_mesh(me)
    bm.free()
    for m in mesh.materials:
        me.materials.append(m)
    ob = bpy.data.objects.new(f"stack_{size}", me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def build_hull(box_ns, size, x, y, parent, coll, mat):
    """Volumen cerrado del contorno de la pila: pie de la de abajo → labio de la de arriba.

    El origen del objeto va en la base de la pila (solo traslación, sin giro ni escala): el shader
    `highlight_outline` crece radialmente desde el origen de la malla, así el contorno queda centrado."""
    a, b, n, handles = box_ns["SIZES"][size]
    ts = box_ns["params"](a, b, n)
    grow = box_ns["HANDLE"][0] if handles else 0.0
    foot = box_ns["PROFILE"][0][0]
    top = (STACK_N - 1) * STACK_STEP + TRAY_HEIGHT
    bm = bmesh.new()
    lo, hi = [], []
    for t in ts:
        p = box_ns["outline"](a, b, n, foot, t)
        lo.append(bm.verts.new((p.x, p.y, 0.0)))
        q = box_ns["outline"](a, b, n, 0.0, t)
        sx = (q.x * (1 + grow / a)) + math.copysign(HULL_GROW, q.x)
        sy = q.y + math.copysign(HULL_GROW, q.y)
        hi.append(bm.verts.new((sx, sy, top)))
    segs = len(ts)
    for k in range(segs):
        bm.faces.new((lo[k], lo[(k + 1) % segs], hi[(k + 1) % segs], hi[k]))
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    ob = new_object(f"hull_{size}", bm, [mat], parent, coll)
    ob.location = (x, y, BENCH_TOP)
    return ob


def build_labels(box_ns, parent, coll, atlas_mat):
    """Etiqueta de talla en el faldón (color del aro de la bandeja), delante de cada pila."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    y = BENCH_Y[1] - 0.015 + 0.002
    z0, z1 = BENCH_TOP - 0.10, BENCH_TOP - BENCH_THICK - 0.01
    widths = {"small": 0.12, "medium": 0.16, "large": 0.20}  # el ancho crece con la talla
    for size, x, _y in STACKS:
        w = widths[size] / 2
        vs = [bm.verts.new(co) for co in ((x - w, y, z0), (x + w, y, z0), (x + w, y, z1), (x - w, y, z1))]
        f = bm.faces.new(vs)
        c = box_ns["cell_uv"](f"band_{size}")
        for lp in f.loops:
            lp[uv].uv = c
    return new_object("labels", bm, [atlas_mat], parent, coll)


# --- Montaje -----------------------------------------------------------------------------------


def build_all():
    box_ns = {}
    exec(open(BOX_SCRIPT).read(), box_ns)
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("asset") or bpy.data.objects.get("box_shelf")
    root.name = "box_shelf"
    for name in ("rack", "cartons", "labels", "OutlineHull"):
        remove_object(name)
    for size, _x, _y in STACKS:
        remove_object(f"stack_{size}")
        remove_object(f"hull_{size}")
    build_frame(root, coll)
    build_cartons(root, coll)
    meshes, hull_mat = load_trays()
    atlas_mat = M["atlas_box"]
    hull_root = bpy.data.objects.new("OutlineHull", None)
    hull_root.empty_display_size = 0.05
    hull_root.parent = root
    coll.objects.link(hull_root)
    for size, x, y in STACKS:
        build_stack(size, x, y, meshes[size], root, coll)
        build_hull(box_ns, size, x, y, hull_root, coll, hull_mat)
    build_labels(box_ns, root, coll, atlas_mat)
    for me in meshes.values():
        if me.users == 0:
            bpy.data.meshes.remove(me)
    # Copia del script dentro del .blend (convención de las fichas de arte).
    txt = bpy.data.texts.get("build_box_shelf.py") or bpy.data.texts.new("build_box_shelf.py")
    txt.from_string(open(os.path.join(ROOT_DIR, "docs/evidence/PUL-081/build_box_shelf.py")).read())
    bpy.ops.wm.save_mainfile()
    tris = 0
    for ob in coll.all_objects:
        if ob.type == "MESH":
            tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
    return tris
