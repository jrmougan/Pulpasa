"""Geometría de art/blender/octopus_storage.blend v2 (PUL-079), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre art/blender/_template.blend (materiales v2 enlazados de
_materials_v2.blend) y guarda el resultado como art/blender/octopus_storage.blend:
    ns = {"__name__": "pul079"}; exec(open("docs/evidence/PUL-079/build_tank.py").read(), ns)
    ns["build_all"](); ns["save"]()

Crea en la colección `export` la raíz `octopus_storage` (art-bible v2 §8, PUL-079), misma huella que el
arcón v1 (≈ 1,6 × 0,9 m, la de `CollisionShape3D`), con estas mallas hermanas:
- `tank_body`: tanque/acuario de plástico azul (`mat_plastic_blue`) de esquinas redondeadas y abierto
  por arriba, con labio grueso, dos nervios al frente, grifo de vaciado (maneta `mat_plastic_red`),
  etiqueta de papel con pictograma de pulpo (sin texto, §3.2) y bancada baja de acero oscuro.
  Dentro, paredes y fondo azules y lámina de agua `mat_glass_water` (transparente, alfa 0,55) a
  0,09 m del borde, con burbujas de espuma (`mat_canvas_paper`) junto a la pared trasera.
- `octopus_0..2`: tres pulpos crudos v2 (malla `octopus_raw` de art/blender/octopus.blend, PUL-076,
  con su atlas) a 0,62 de escala horneada, flotando a ras con la cabeza fuera del agua (§6.5: «de aquí sale
  el pulpo»; el agua no tapa la cabeza, §6.2).
- `tentacle`: una pata de pulpo crudo que cuelga por el labio delantero izquierdo (silueta).
- `pump`: aireador `mat_steel_dark` en la esquina trasera derecha del labio con mangueras negras
  (`mat_rubber`): una entra en el agua (de ahí las burbujas) y otra baja por detrás al suelo; un
  desagüe lateral baja también al suelo por detrás (§5 regla 4: pegadas al suelo, fuera del paso).
Frente +Y (−Z en Godot); sin caras ocultas bajo la bancada; UV de caja a 1 UV = 2 m salvo los
pulpos, que conservan las UV de su atlas.
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

HX, HY = 0.78, 0.42  # semiejes exteriores del tanque (huella de la colisión: 1,61 × 0,91)
CR = 0.10  # radio de esquina
WALL = 0.035
BASE_Z = 0.12  # fondo del tanque sobre la bancada
RIM_Z = 1.0
LIP = 0.022  # vuelo del labio
WATER_Z = 0.91
INNER_FLOOR_Z = 0.52  # fondo interior (falso fondo: lo de debajo no se ve)
OCTO_SCALE = 0.62
OCTO_SRC = "art/blender/octopus.blend"
# (x, y, giro en grados, z de la base) de cada pulpo: flotan a ras, patas a 1–2 cm bajo la lámina y
# cabeza fuera, para que el agua (alfa 0,55) no les quite el rosa (§6.2).
OCTOPI = [(-0.40, 0.04, 20.0, 0.895), (0.08, -0.10, 145.0, 0.89), (0.47, 0.08, 260.0, 0.895)]


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


def rrect_pts(hx, hy, r, segs=4):
    """Rectángulo de esquinas redondeadas (sentido antihorario), puntos 2D."""
    pts = []
    for cx, cy, a0 in ((hx - r, hy - r, 0), (-hx + r, hy - r, 90), (-hx + r, -hy + r, 180), (hx - r, -hy + r, 270)):
        for k in range(segs + 1):
            a = math.radians(a0 + 90.0 * k / segs)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rring(bm, hx, hy, r, z):
    return [bm.verts.new((x, y, z)) for x, y in rrect_pts(hx, hy, max(r, 0.005))]


def bridge(bm, lo, hi, idx, smooth=False):
    n = len(lo)
    for k in range(n):
        f = bm.faces.new((lo[k], lo[(k + 1) % n], hi[(k + 1) % n], hi[k]))
        f.material_index = idx
        f.smooth = smooth


def cap(bm, loop, idx, down=False):
    f = bm.faces.new(list(reversed(loop)) if down else loop)
    f.material_index = idx
    return f


def ring(bm, r, z, center=Vector(), segs=12):
    return [bm.verts.new(center + Vector((r * math.cos(2 * math.pi * k / segs), r * math.sin(2 * math.pi * k / segs), z))) for k in range(segs)]


def disc(bm, r, z, idx, center=Vector(), segs=12):
    rim = ring(bm, r, z, center, segs)
    c = bm.verts.new(center + Vector((0, 0, z)))
    for k in range(segs):
        f = bm.faces.new((c, rim[k], rim[(k + 1) % segs]))
        f.material_index = idx


def box(bm, center, size, idx):
    res = bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, verts=res["verts"], vec=size)
    bmesh.ops.translate(bm, verts=res["verts"], vec=center)
    for f in {f for v in res["verts"] for f in v.link_faces}:
        f.material_index = idx


def tube(bm, points, radius, idx, sides=6, caps=(False, False), taper=1.0):
    """Tubo por una polilínea (mangueras, patas); `taper` = radio final / inicial."""
    frames = []
    n = len(points)
    for i, p in enumerate(points):
        if i == 0:
            t = points[1] - points[0]
        elif i == n - 1:
            t = points[-1] - points[-2]
        else:
            t = (points[i + 1] - points[i]).normalized() + (points[i] - points[i - 1]).normalized()
        t.normalize()
        up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
        u = t.cross(up).normalized()
        v = t.cross(u).normalized()
        r = radius * (1.0 + (taper - 1.0) * i / (n - 1))
        frames.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / sides) + v * math.sin(2 * math.pi * k / sides)) * r) for k in range(sides)])
    for a, b in zip(frames, frames[1:]):
        for k in range(sides):
            f = bm.faces.new((a[k], a[(k + 1) % sides], b[(k + 1) % sides], b[k]))
            f.material_index = idx
            f.smooth = True
    for end, c in ((frames[0], caps[0]), (frames[-1], caps[1])):
        if c:
            f = bm.faces.new(list(reversed(end)) if end is frames[0] else end)
            f.material_index = idx


def dome(bm, center, r, idx):
    res = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=4, radius=r)
    for v in res["verts"]:
        v.co = center + Vector((v.co.x, v.co.y, max(v.co.z, 0.0) * 0.7))
    faces = {f for v in res["verts"] for f in v.link_faces}
    for f in faces:
        f.material_index = idx
        f.smooth = True
    bm.normal_update()
    bmesh.ops.delete(bm, geom=[f for f in faces if f.normal.z < -0.5], context="FACES")


def box_uv(bm, meters_per_unit=2.0):
    uv = bm.loops.layers.uv.verify()
    bm.normal_update()
    for face in bm.faces:
        n = face.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            co = loop.vert.co
            u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
            loop[uv].uv = (u / meters_per_unit, v / meters_per_unit)


def finish(bm, ob, recalc=True):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.normal_update()
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    box_uv(bm)
    bm.to_mesh(ob.data)
    bm.free()


def build_tank_body(root, coll):
    mats = ["mat_plastic_blue", "mat_glass_water", "mat_steel_dark", "mat_steel_brushed", "mat_plastic_red", "mat_canvas_paper", "mat_rubber"]
    # Burbujas en `mat_canvas_paper` (espuma blanca): en `mat_glass_water` no se leen desde la cámara.
    ob = new_mesh_object("tank_body", mats, root, coll)
    bm = bmesh.new()
    # Pared exterior de abajo arriba: bisel inferior, dos nervios horizontales y labio grueso.
    prof = [
        (-0.02, BASE_Z), (0.0, BASE_Z + 0.03),
        (0.0, 0.40), (0.012, 0.41), (0.012, 0.44), (0.0, 0.45),
        (0.0, 0.70), (0.012, 0.71), (0.012, 0.74), (0.0, 0.75),
        (0.0, RIM_Z - 0.07), (LIP, RIM_Z - 0.06), (LIP, RIM_Z - 0.01), (LIP - 0.01, RIM_Z),
    ]
    out = [rring(bm, HX + d, HY + d, CR + d, z) for d, z in prof]
    for a, b in zip(out, out[1:]):
        bridge(bm, a, b, 0)
    # Borde superior y pared interior hasta el falso fondo (se ve a través del agua).
    inner_top = rring(bm, HX - WALL, HY - WALL, CR - WALL, RIM_Z)
    bridge(bm, out[-1], inner_top, 0)
    inner_lo = rring(bm, HX - WALL, HY - WALL, CR - WALL, INNER_FLOOR_Z)
    bridge(bm, inner_top, inner_lo, 0)
    cap(bm, inner_lo, 0)
    # Lámina de agua transparente (mat_glass_water).
    water = rring(bm, HX - WALL - 0.002, HY - WALL - 0.002, CR - WALL, WATER_Z)
    cap(bm, water, 1)
    # Burbujas del aireador sobre el agua, junto a la pared trasera derecha (lejos del frente).
    for x, y, r in ((0.55, -0.30, 0.022), (0.60, -0.25, 0.016), (0.50, -0.26, 0.014), (0.64, -0.31, 0.012),
                    (0.46, -0.32, 0.018), (0.57, -0.19, 0.011), (-0.10, -0.31, 0.014), (-0.05, -0.29, 0.010)):
        dome(bm, Vector((x, y, WATER_Z)), r, 5)
    # Bancada baja de acero oscuro: marco perimetral y cuatro pies (sin cara inferior).
    frame_lo = rring(bm, HX - 0.03, HY - 0.03, CR, 0.02)
    frame_hi = rring(bm, HX - 0.03, HY - 0.03, CR, BASE_Z)
    bridge(bm, frame_lo, frame_hi, 2)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(bm, Vector((sx * (HX - 0.10), sy * (HY - 0.08), 0.01)), (0.10, 0.10, 0.02), 2)
    # Grifo de vaciado al frente, a la derecha (Z2), con maneta roja.
    gx = 0.52
    tube(bm, [Vector((gx, HY - 0.01, 0.22)), Vector((gx, HY + 0.07, 0.22)), Vector((gx, HY + 0.09, 0.18))], 0.022, 3, sides=8, caps=(False, True))
    box(bm, Vector((gx, HY + 0.06, 0.255)), (0.10, 0.025, 0.022), 4)
    # Etiqueta de papel con pictograma de pulpo (cabeza y patas, sin texto) en el frente.
    lx, lz = -0.40, 0.575
    box(bm, Vector((lx, HY + 0.004, lz)), (0.26, 0.008, 0.18), 5)
    py = HY + 0.009
    head = Vector((lx, py, lz + 0.035))
    rim = [bm.verts.new(head + Vector((0.035 * math.cos(2 * math.pi * k / 12), 0, 0.045 * math.sin(2 * math.pi * k / 12)))) for k in range(12)]
    c = bm.verts.new(head)
    for k in range(12):
        f = bm.faces.new((c, rim[(k + 1) % 12], rim[k]))
        f.material_index = 6
    # Seis patas que bajan y se enroscan hacia fuera (silueta de pulpo, no de insecto).
    for dx in (-0.075, -0.045, -0.015, 0.015, 0.045, 0.075):
        s_ = math.copysign(1, dx)
        p0 = head + Vector((dx * 0.35, 0, -0.03))
        p1 = head + Vector((dx * 0.8, 0, -0.07))
        p2 = head + Vector((dx * 1.05, 0, -0.095))
        p3 = head + Vector((dx * 1.05 + s_ * 0.018, 0, -0.085))
        tube(bm, [p0, p1, p2, p3], 0.007, 6, sides=4, taper=0.6)
    finish(bm, ob)
    return ob


def append_octopus_mesh():
    """Malla `octopus_raw` de PUL-076 (con su material de atlas), copiada sin enlazar."""
    path = str(Path(bpy.path.abspath("//")) / Path(OCTO_SRC).name)
    if not Path(path).exists():
        path = str(Path(OCTO_SRC).resolve())
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.meshes = ["octopus_raw"]
    return dst.meshes[0]


def build_octopi(root, coll):
    src = append_octopus_mesh()
    obs = []
    for i, (x, y, rot, z) in enumerate(OCTOPI):
        remove_object("octopus_%d" % i)
        me = src.copy()
        me.name = "octopus_%d" % i
        mat = Matrix.Translation((x, y, z)) @ Matrix.Rotation(math.radians(rot), 4, "Z") @ Matrix.Scale(OCTO_SCALE, 4)
        me.transform(mat)
        ob = bpy.data.objects.new(me.name, me)
        coll.objects.link(ob)
        ob.parent = root
        obs.append(ob)
    bpy.data.meshes.remove(src)
    return obs


def build_tentacle(root, coll):
    """Pata de pulpo crudo que asoma por el labio delantero izquierdo y cuelga por fuera."""
    ob = new_mesh_object("tentacle", ["mat_food_octopus_raw"], root, coll)
    bm = bmesh.new()
    x = -0.62
    pts = [
        Vector((x + 0.06, HY - 0.16, WATER_Z - 0.02)), Vector((x + 0.03, HY - 0.07, RIM_Z - 0.005)),
        Vector((x, HY + 0.005, RIM_Z + 0.022)), Vector((x - 0.01, HY + LIP + 0.025, RIM_Z - 0.02)),
        Vector((x - 0.01, HY + LIP + 0.03, RIM_Z - 0.12)), Vector((x + 0.01, HY + LIP + 0.04, RIM_Z - 0.20)),
        Vector((x + 0.05, HY + LIP + 0.045, RIM_Z - 0.235)),
    ]
    tube(bm, pts, 0.03, 0, sides=8, caps=(False, True), taper=0.3)
    finish(bm, ob)
    return ob


def build_pump(root, coll):
    ob = new_mesh_object("pump", ["mat_steel_dark", "mat_rubber", "mat_steel_brushed"], root, coll)
    bm = bmesh.new()
    # Aireador encajado en el labio trasero derecho.
    px, py = 0.58, -HY - 0.01
    box(bm, Vector((px, py, RIM_Z + 0.04)), (0.18, 0.10, 0.08), 0)
    box(bm, Vector((px, py + 0.03, RIM_Z + 0.082)), (0.10, 0.03, 0.006), 2)
    # Manguera de aire: del aireador al agua (sale en las burbujas).
    tube(bm, [Vector((px - 0.03, py + 0.05, RIM_Z + 0.05)), Vector((px - 0.03, -HY + 0.06, RIM_Z + 0.04)),
              Vector((px - 0.03, -HY + 0.12, WATER_Z + 0.01)), Vector((px - 0.03, -HY + 0.13, WATER_Z - 0.05))], 0.012, 1, sides=6)
    # Cable/manguera del aireador por detrás hasta el suelo y hacia la derecha (Z3).
    tube(bm, [Vector((px + 0.07, py - 0.05, RIM_Z + 0.03)), Vector((px + 0.10, -HY - 0.10, RIM_Z - 0.05)),
              Vector((px + 0.10, -HY - 0.09, 0.20)), Vector((px + 0.12, -HY - 0.10, 0.014)),
              Vector((HX + 0.02, -HY - 0.08, 0.014))], 0.014, 1, sides=6, caps=(False, True))
    # Desagüe: del lateral izquierdo por detrás al suelo.
    tube(bm, [Vector((-HX, -0.20, 0.30)), Vector((-HX - 0.06, -0.22, 0.28)), Vector((-HX - 0.07, -0.28, 0.12)),
              Vector((-HX - 0.06, -HY - 0.04, 0.016)), Vector((-HX + 0.20, -HY - 0.07, 0.016))], 0.02, 1, sides=6, caps=(False, True))
    finish(bm, ob)
    return ob


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("asset") or bpy.data.objects["octopus_storage"]
    root.name = "octopus_storage"
    bpy.data.objects["Anchor_Front"].location = (0, 0.5, 0)
    parts = [build_tank_body(root, coll), *build_octopi(root, coll), build_tentacle(root, coll), build_pump(root, coll)]
    bpy.context.view_layer.update()
    return {o.name: tris(o) for o in parts} | {"total": sum(tris(o) for o in parts)}


def save(path="art/blender/octopus_storage.blend"):
    src = Path(__file__).read_text() if "__file__" in globals() else None
    txt = bpy.data.texts.get("build_tank.py") or bpy.data.texts.new("build_tank.py")
    txt.clear()
    txt.write(src or open("docs/evidence/PUL-079/build_tank.py").read())
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(path).resolve()), relative_remap=True)
