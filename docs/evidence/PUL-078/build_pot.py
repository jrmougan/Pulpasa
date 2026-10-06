"""Geometría de art/blender/pot.blend v2 (PUL-078), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre art/blender/_template.blend (materiales v2 enlazados de
_materials_v2.blend) y guarda el resultado como art/blender/pot.blend:
    ns = {"__name__": "pul078"}; exec(open("docs/evidence/PUL-078/build_pot.py").read(), ns)
    ns["build_all"](); ns["save"]()

Crea en la colección `export` la raíz `pot` (art-bible v2 §8, PUL-078) con cuatro mallas hermanas:
- `pot_body`: cocedor cilíndrico de acero inoxidable (`mat_steel_brushed`), ABIERTO, con borde
  enrollado, dos nervios, asas laterales, bisagra y grifo de vaciado al frente (maneta `mat_plastic_red`).
  Dentro, pared `mat_steel_dark` y agua opaca `pot_water` (material propio con atlas empaquetado de
  256², art-bible §3.3) a 0,10 m bajo el borde (z = 0,90)
  con un aro claro por plaza y burbujas junto a la pared (lejos de las plazas, §5 Z1).
  Origen en su base (z = 0,30). Cuelgan de él `Anchor_Slot_0..1` (x = ∓0,15 como
  `CookingStation.SLOT_SPACING`) y `Anchor_Steam` (boca).
- `lid`: tapa levantada sobre una bisagra trasera (105°): deja la boca entera a la vista.
- `stove_base`: soporte de cuatro patas `mat_steel_dark`, quemador de gas de corona ancha (r = 0,25,
  z ≈ 0,12, donde sale en anillo el fuego de partículas, visible bajo el borde desde la cámara), mando
  con piloto ámbar al frente a un lado. De él cuelga `Anchor_Fire`.
- `gas_bottle`: bombona `mat_plastic_blue` en la esquina trasera derecha con mangueras de gas
  `mat_rubber_hose_red` (al quemador) y `mat_rubber_hose_green` (sale hacia el muro), pegadas al suelo
  por detrás (§5 regla 4).
Llamas y vapor son partículas de motor (kitchen.tscn, PUL-069), no modelo. Frente +Y (−Z en Godot);
sin caras inferiores ocultas; rotaciones horneadas en los vértices; UV de caja a 1 UV = 2 m.
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

SEGS = 32
POT_BASE_Z = 0.30
RIM_Z = 1.0
WATER_Z = 0.90
SLOT_X = 0.15  # CookingStation.SLOT_SPACING / 2 (capacidad 2, kitchen.tres)
SLOT_Z = 0.86
SLOT_RING = (0.115, 0.135)
R = 0.36  # radio del cuerpo
# Perfil exterior (radio, z) de abajo arriba: bisel inferior, nervios y borde enrollado.
OUTER = [
    (0.31, 0.30), (0.345, 0.305), (R, 0.33),
    (R, 0.44), (0.369, 0.45), (0.369, 0.47), (R, 0.48),
    (R, 0.79), (0.369, 0.80), (0.369, 0.82), (R, 0.83),
    (R, 0.955),
]
RIM = [(0.374, 0.962), (0.381, 0.98), (0.376, 0.996), (0.362, RIM_Z)]
INNER = [(0.348, 0.992), (0.346, WATER_Z)]
BURNER_R = 0.25  # corona del quemador; = emission_ring_radius de `Fire` en kitchen.tscn
BURNER_Z = 0.12
HINGE = Vector((0.0, -0.385, 1.0))
LID_R = 0.378
LID_OPEN_DEG = 105.0
BOTTLE = Vector((0.31, -0.37, 0.0))
BOTTLE_R = 0.10
BOTTLE_H = 0.40


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


def ring(bm, r, z, offset=Vector(), segs=SEGS):
    return [bm.verts.new(offset + Vector((r * math.cos(2 * math.pi * k / segs), r * math.sin(2 * math.pi * k / segs), z))) for k in range(segs)]


def bridge(bm, lo, hi, idx, smooth=True):
    n = len(lo)
    for k in range(n):
        f = bm.faces.new((lo[k], lo[(k + 1) % n], hi[(k + 1) % n], hi[k]))
        f.material_index = idx
        f.smooth = smooth


def disc(bm, r, z, idx, center=Vector(), segs=SEGS, down=False):
    rim = ring(bm, r, z, center, segs)
    c = bm.verts.new(center + Vector((0, 0, z)))
    for k in range(segs):
        vs = (c, rim[k], rim[(k + 1) % segs])
        f = bm.faces.new(tuple(reversed(vs)) if down else vs)
        f.material_index = idx
        f.smooth = False
    return rim


def cylinder(bm, center, r, z0, z1, idx, segs=12, top=True, smooth=True):
    lo = ring(bm, r, z0, center, segs)
    hi = ring(bm, r, z1, center, segs)
    bridge(bm, lo, hi, idx, smooth)
    if top:
        disc(bm, r, z1, idx, center, segs)


def cylinder_y(bm, center, r, y0, y1, idx, segs=10):
    """Cilindro tapado a lo largo de +Y (mandos que miran a la cámara)."""
    def ring_y(y):
        return [bm.verts.new(center + Vector((r * math.cos(2 * math.pi * k / segs), y, r * math.sin(2 * math.pi * k / segs)))) for k in range(segs)]

    lo, hi = ring_y(y0), ring_y(y1)
    bridge(bm, lo, hi, idx)
    f = bm.faces.new(hi)
    f.material_index = idx
    f.smooth = False


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


def tube(bm, points, radius, idx, sides=6, caps=(False, False)):
    """Tubo liso por una polilínea (mangueras, tuberías, patas)."""
    frames = []
    for i, p in enumerate(points):
        if i == 0:
            t = points[1] - points[0]
        elif i == len(points) - 1:
            t = points[-1] - points[-2]
        else:
            t = (points[i + 1] - points[i]).normalized() + (points[i] - points[i - 1]).normalized()
        t.normalize()
        up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
        u = t.cross(up).normalized()
        v = t.cross(u).normalized()
        frames.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / sides) + v * math.sin(2 * math.pi * k / sides)) * radius) for k in range(sides)])
    for a, b in zip(frames, frames[1:]):
        for k in range(sides):
            f = bm.faces.new((a[k], a[(k + 1) % sides], b[(k + 1) % sides], b[k]))
            f.material_index = idx
            f.smooth = True
    for end, cap in ((frames[0], caps[0]), (frames[-1], caps[1])):
        if cap:
            f = bm.faces.new(list(reversed(end)) if end is frames[0] else end)
            f.material_index = idx


def box(bm, center, size, idx):
    res = bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, verts=res["verts"], vec=size)
    bmesh.ops.translate(bm, verts=res["verts"], vec=center)
    for f in {f for v in res["verts"] for f in v.link_faces}:
        f.material_index = idx
        f.smooth = False


def dome(bm, center, r, idx):
    res = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=4, radius=r)
    for v in res["verts"]:
        v.co = center + Vector((v.co.x, v.co.y, max(v.co.z, 0.0) * 0.8))
    faces = {f for v in res["verts"] for f in v.link_faces}
    for f in faces:
        f.material_index = idx
        f.smooth = True
    bm.normal_update()
    bottom = [f for f in faces if f.normal.z < -0.5]
    bmesh.ops.delete(bm, geom=bottom, context="FACES")


def box_uv(bm, meters_per_unit=2.0):
    """Proyección de caja a la densidad v2 (1 UV = 2 m), como tools/blender_export.py."""
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
    bm.normal_update()
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    box_uv(bm)
    bm.to_mesh(ob.data)
    bm.free()


WATER_HEX = (0x7C, 0x8E, 0x92)  # agua de cocción: gris azulado, L ≈ 0,25 (contrastes en Evidence)
WATER_PX = 256


def srgb_to_linear(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def make_water_material():
    """Material propio del asset (art-bible v2 §3.3): agua opaca con atlas empaquetado de 256².

    Color medio `WATER_HEX`; AO horneado hacia la pared (×0,72 en el borde) y ondas anchas
    concéntricas de ±4 % (periodo 0,09 m ≈ 8 px a 1080p, sin ruido fino §3.2).
    """
    name = "pot_water"
    mat = bpy.data.materials.get(name)
    if mat is not None:
        bpy.data.materials.remove(mat)
    img = bpy.data.images.get(name)
    if img is not None:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, WATER_PX, WATER_PX, alpha=False)
    base = [srgb_to_linear(c) for c in WATER_HEX]
    px = []
    for j in range(WATER_PX):
        for i in range(WATER_PX):
            dx, dy = (i + 0.5) / WATER_PX - 0.5, (j + 0.5) / WATER_PX - 0.5
            r = min(1.0, math.hypot(dx, dy) / 0.5)  # 0 centro, 1 pared
            ao = 1.0 - 0.28 * max(0.0, (r - 0.7) / 0.3) ** 1.5
            ripple = 1.0 + 0.04 * math.sin(r * 0.35 / 0.09 * 2 * math.pi)
            k = ao * ripple * 1.03
            px.extend([min(1.0, b * k) for b in base] + [1.0])
    img.pixels.foreach_set(px)
    img.file_format = "PNG"
    img.pack()
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.3
    bsdf.inputs["Metallic"].default_value = 0.0
    return mat


def build_pot_body(root, coll):
    make_water_material()
    mats = ["mat_steel_brushed", "mat_steel_dark", "mat_steel_brushed_mid", "mat_plastic_red", "pot_water"]
    ob = new_mesh_object("pot_body", mats, root, coll, (0, 0, POT_BASE_Z))
    off = Vector((0, 0, -POT_BASE_Z))
    bm = bmesh.new()
    rings = [ring(bm, r, z, off) for r, z in OUTER + RIM + INNER]
    n_out, n_rim = len(OUTER), len(RIM)
    for i in range(len(rings) - 1):
        idx = 0 if i < n_out + n_rim - 1 else 1
        bridge(bm, rings[i], rings[i + 1], idx)
    # Fondo: abanico hasta el centro (cierra la silueta baja vista desde el frente).
    c = bm.verts.new(off + Vector((0, 0, POT_BASE_Z)))
    for k in range(SEGS):
        f = bm.faces.new((c, rings[0][(k + 1) % SEGS], rings[0][k]))
        f.material_index = 0
        f.smooth = False
    # Agua a 0,10 m del borde (opaca: la transparencia solo va en el tanque, art-bible §3.2).
    disc(bm, INNER[-1][0] + 0.002, WATER_Z + off.z, 4)
    # Plazas a la vista (D9): un aro de acero claro sobre el agua en cada Anchor_Slot.
    for x in (-SLOT_X, SLOT_X):
        lo = ring(bm, SLOT_RING[0], WATER_Z + 0.003 + off.z, Vector((x, 0, 0)), 24)
        hi = ring(bm, SLOT_RING[1], WATER_Z + 0.003 + off.z, Vector((x, 0, 0)), 24)
        bridge(bm, hi, lo, 0, smooth=False)
    # Burbujas junto a la pared, delante y detrás (≥ 0,15 m de las plazas, §5 Z1).
    for a, r in ((80, 0.30), (100, 0.29), (95, 0.315), (265, 0.30), (280, 0.31)):
        p = Vector((math.cos(math.radians(a)) * r, math.sin(math.radians(a)) * r, WATER_Z + off.z))
        dome(bm, p, 0.018, 0)
    # Asas de aro a los lados, en el plano XZ (se ven de frente desde la cámara).
    for s in (-1, 1):
        torus(bm, off + Vector((s * 0.415, 0, 0.86)), 0.05, 0.012, "Y", 2, segs=10, sides=4)
        tube(bm, [off + Vector((s * 0.355, 0, 0.885)), off + Vector((s * 0.405, 0, 0.885))], 0.016, 2, sides=4)
    # Grifo de vaciado al frente (Z2), con maneta roja.
    tube(bm, [off + Vector((0, 0.355, 0.40)), off + Vector((0, 0.43, 0.40)), off + Vector((0, 0.45, 0.37))], 0.02, 2, sides=6, caps=(False, True))
    box(bm, off + Vector((0, 0.43, 0.43)), (0.08, 0.025, 0.02), 3)
    # Bisagra trasera: dos pletinas del borde a la tapa.
    for x in (-0.12, 0.12):
        box(bm, off + Vector((x, -0.372, 0.975)), (0.035, 0.03, 0.06), 1)
    finish(bm, ob)
    # El agua usa el atlas propio entero (0..1 sobre el disco), no la caja de 2 m.
    uv = ob.data.uv_layers.active.data
    d = 2 * (INNER[-1][0] + 0.002)
    for poly in ob.data.polygons:
        if poly.material_index == 4:
            for li in poly.loop_indices:
                co = ob.data.vertices[ob.data.loops[li].vertex_index].co
                uv[li].uv = (co.x / d + 0.5, co.y / d + 0.5)
    return ob


def build_lid(root, coll):
    ob = new_mesh_object("lid", ["mat_steel_brushed", "mat_steel_dark", "mat_rubber"], root, coll, HINGE)
    bm = bmesh.new()
    # Tapa cerrada con el centro a (0, LID_R, 0) respecto a la bisagra; luego se abre girando en X.
    ctr = Vector((0, LID_R + 0.005, 0))
    top = ring(bm, LID_R - 0.03, 0.035, ctr)
    edge_hi = ring(bm, LID_R, 0.012, ctr)
    edge_lo = ring(bm, LID_R, -0.004, ctr)
    under = ring(bm, LID_R - 0.02, -0.004, ctr)
    bridge(bm, edge_hi, top, 0)
    bridge(bm, edge_lo, edge_hi, 0)
    bridge(bm, under, edge_lo, 0, smooth=False)
    disc(bm, LID_R - 0.03, 0.035, 0, ctr)
    disc(bm, LID_R - 0.02, -0.004, 0, ctr, down=True)
    # Pomo de goma y bisagras.
    cylinder(bm, ctr, 0.015, 0.035, 0.07, 1, segs=8, top=False)
    cylinder(bm, ctr, 0.04, 0.07, 0.09, 2, segs=12)
    for x in (-0.12, 0.12):
        box(bm, Vector((x, 0.03, 0.0)), (0.035, 0.07, 0.02), 1)
    rot = Matrix.Rotation(math.radians(LID_OPEN_DEG), 4, "X")
    bmesh.ops.transform(bm, matrix=rot, verts=bm.verts)
    finish(bm, ob, recalc=False)
    return ob


def build_stove_base(root, coll):
    mats = ["mat_steel_dark", "mat_steel_brushed_mid", "mat_steel_brushed", "mat_rubber", "mat_emissive_bulb"]
    ob = new_mesh_object("stove_base", mats, root, coll)
    bm = bmesh.new()
    # Soporte: aro superior bajo el cocedor, aro bajo y cuatro patas en diagonal (frente libre).
    torus(bm, Vector((0, 0, POT_BASE_Z - 0.015)), 0.315, 0.016, "Z", 0, segs=24, sides=4, tilt=math.pi / 4)
    torus(bm, Vector((0, 0, 0.07)), 0.30, 0.012, "Z", 0, segs=24, sides=4, tilt=math.pi / 4)
    for a in (45, 135, 225, 315):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        tube(bm, [d * 0.33, d * 0.315 + Vector((0, 0, POT_BASE_Z - 0.01))], 0.02, 0, sides=4, caps=(False, True))
        box(bm, d * 0.33 + Vector((0, 0, 0.006)), (0.06, 0.06, 0.012), 0)  # pie
    # Quemador de gas de corona ancha (r = 0,25, como los de pulpo): el fuego de partículas sale en
    # anillo a z ≈ 0,12 y asoma bajo el borde del cocedor desde la cámara (kitchen.tscn `Fire`).
    cylinder(bm, Vector(), 0.05, 0.05, 0.10, 0, segs=10)
    torus(bm, Vector((0, 0, BURNER_Z - 0.02)), BURNER_R, 0.022, "Z", 0, segs=28, sides=4, tilt=math.pi / 4)
    torus(bm, Vector((0, 0, BURNER_Z + 0.002)), BURNER_R, 0.011, "Z", 1, segs=28, sides=4, tilt=math.pi / 4)
    for a in (0, 90, 180, 270):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        tube(bm, [d * 0.05 + Vector((0, 0, 0.08)), d * (BURNER_R - 0.02) + Vector((0, 0, 0.08))], 0.012, 0, sides=4)
        tube(bm, [d * (BURNER_R + 0.02) + Vector((0, 0, 0.075)), d * 0.30 + Vector((0, 0, 0.07))], 0.01, 0, sides=4)
    # Mando al frente, a un lado para no tapar la llama (Z2): válvula, ruedecilla y piloto ámbar.
    vx = 0.15
    tube(bm, [Vector((vx, 0.19, 0.085)), Vector((vx, 0.30, 0.085))], 0.014, 1, sides=6)
    box(bm, Vector((vx, 0.33, 0.085)), (0.12, 0.06, 0.08), 2)
    cylinder_y(bm, Vector((vx + 0.025, 0, 0.08)), 0.024, 0.36, 0.384, 3, segs=10)
    cylinder_y(bm, Vector((vx - 0.035, 0, 0.10)), 0.011, 0.36, 0.366, 4, segs=8)
    # Tubo de entrada por detrás hasta la manguera roja.
    tube(bm, [Vector((0, -BURNER_R - 0.02, 0.08)), Vector((0, -0.34, 0.075)), Vector((0.03, -0.40, 0.04))], 0.014, 1, sides=6)
    finish(bm, ob)
    return ob


def build_gas_bottle(root, coll):
    mats = ["mat_plastic_blue", "mat_steel_brushed", "mat_rubber_hose_red", "mat_rubber_hose_green", "mat_steel_dark"]
    ob = new_mesh_object("gas_bottle", mats, root, coll)
    bm = bmesh.new()
    c = BOTTLE
    prof = [(BOTTLE_R - 0.01, 0.0), (BOTTLE_R, 0.02), (BOTTLE_R, BOTTLE_H - 0.07), (BOTTLE_R - 0.02, BOTTLE_H - 0.03), (0.05, BOTTLE_H)]
    rs = [ring(bm, r, z, c, 20) for r, z in prof]
    for a, b in zip(rs, rs[1:]):
        bridge(bm, a, b, 0)
    disc(bm, 0.05, BOTTLE_H, 0, c, 20)
    # Collarín protector y válvula.
    lo = ring(bm, 0.055, BOTTLE_H, c, 12)
    hi = ring(bm, 0.055, BOTTLE_H + 0.06, c, 12)
    bridge(bm, lo, hi, 4)
    cylinder(bm, c, 0.02, BOTTLE_H, BOTTLE_H + 0.05, 1, segs=8)
    tube(bm, [c + Vector((0, 0, BOTTLE_H + 0.035)), c + Vector((0, -0.07, BOTTLE_H + 0.035))], 0.012, 1, sides=6, caps=(False, True))
    # Manguera roja: de la válvula baja por detrás, va por el suelo y entra en el quemador.
    v0 = c + Vector((0, -0.07, BOTTLE_H + 0.035))
    red = [
        v0, v0 + Vector((0, -0.04, -0.06)), c + Vector((0, -0.125, 0.18)), c + Vector((-0.02, -0.11, 0.03)),
        Vector((0.20, -0.46, 0.015)), Vector((0.08, -0.44, 0.015)), Vector((0.03, -0.40, 0.04)),
    ]
    tube(bm, red, 0.013, 2, sides=6)
    # Manguera verde: sale de la válvula hacia el muro (suministro del puesto), pegada al suelo.
    green = [
        v0 + Vector((0.01, 0, 0)), v0 + Vector((0.06, -0.03, -0.05)), c + Vector((0.09, -0.06, 0.15)),
        c + Vector((0.08, -0.10, 0.015)), Vector((0.30, -0.52, 0.015)), Vector((0.10, -0.53, 0.015)), Vector((-0.40, -0.52, 0.015)),
    ]
    tube(bm, green, 0.013, 3, sides=6, caps=(False, True))
    finish(bm, ob)
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


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("asset") or bpy.data.objects["pot"]
    root.name = "pot"
    front = bpy.data.objects["Anchor_Front"]
    front.location = (0, 0.5, 0)
    parts = [build_pot_body(root, coll), build_lid(root, coll), build_stove_base(root, coll), build_gas_bottle(root, coll)]
    bpy.context.view_layer.update()
    body, base = parts[0], parts[2]
    for i, x in enumerate((-SLOT_X, SLOT_X)):
        empty("Anchor_Slot_%d" % i, body, coll, (x, 0, SLOT_Z))
    empty("Anchor_Steam", body, coll, (0, 0, RIM_Z))
    empty("Anchor_Fire", base, coll, (0, 0, 0.12))
    return {o.name: tris(o) for o in parts} | {"total": sum(tris(o) for o in parts)}


def save(path="art/blender/pot.blend"):
    src = Path(__file__).read_text() if "__file__" in globals() else None
    txt = bpy.data.texts.get("build_pot.py") or bpy.data.texts.new("build_pot.py")
    txt.clear()
    txt.write(src or open("docs/evidence/PUL-078/build_pot.py").read())
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(path).resolve()), relative_remap=True)
