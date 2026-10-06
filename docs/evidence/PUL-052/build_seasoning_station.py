"""Geometría de art/blender/seasoning_station.blend (PUL-052), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-052/build_seasoning_station.py").read(), ns); ns["build_all"]()

Tres raíces, una por colección (cada una se exporta a su `.glb` hermano en
godot/assets/models/stations/seasoning_station/, ver `export_seasoning_station.sh`):
- `export` → `seasoning_station`: mostrador de pase de 4,0 × 1,1 × 1,1 (cuerpo `wood_mid`, tablero
  `wood_light`, zócalo y listones `wood_dark`), con la bandeja (`tray`) en su sitio. Lado de pase
  (frente, −Z de Godot, hacia la cocina) con banda `canvas_stripe`; lado de condimentar (+Z, hacia
  los puestos y la cámara) con una placa del color de cada recipiente debajo de cada uno.
- `export_dispenser` → `seasoning_dispenser`: los cuatro recipientes fijos, superpuestos en el origen
  (variantes de la misma pieza, art-bible §2.4): `paprika_sweet` y `paprika_hot` (latas de pimentón,
  faja crema / faja `iron_black`), `salt` (cuenco de madera con sal gorda) y `oil` (aceitera con pico y asa).
- `export_bowl` → `cachelos_bowl`: cuenco de madera Ø 0,5 m, hondo, para las raciones de cachelos.

La geometría jugable la fijaron PUL-063/064 y el modelo se adapta a ella: bandeja en x = +0,3,
z = −0,25 (tapa a y = 1,14, el `Anchor` del slot); dispensadores en z = +0,45, x = −1,25/−0,35/+0,95/+1,85;
cuenco en x = −1,8; tablero a y = 1,10. Todo ≤ 0,25 m de alto sobre el tablero (art-bible §3.5).
Coordenadas escritas en ejes de Godot (X derecha, Y arriba, Z hacia la cámara) y convertidas a Blender
con `P()`: el frente +Y de Blender es −Z en Godot. Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy

M = bpy.data.materials

TOP_Y = 1.10
TRAY_X, TRAY_Z, TRAY_W, TRAY_D = 0.3, -0.25, 0.7, 0.55
TRAY_TOP = 1.14
DISPENSER_Z = 0.45
DISPENSERS = (
    ("SweetPaprika", -1.25, "mat_paprika_sweet"),
    ("HotPaprika", -0.35, "mat_paprika_hot"),
    ("Salt", 0.95, "mat_salt"),
    ("Oil", 1.85, "mat_oil"),
)
BOWL_X = -1.8
SEGS = 12


def P(x, y, z):
    """Punto en ejes de Godot → Blender (Z arriba, frente +Y)."""
    return (x, -z, y)


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def collection(name):
    coll = bpy.data.collections.get(name)
    if coll is None:
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
    return coll


def mesh_object(name, mats, parent, coll, fill):
    remove_object(name)
    me = bpy.data.meshes.new(name)
    for m in mats:
        me.materials.append(M[m])
    bm = bmesh.new()
    fill(bm)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def empty(name, loc, parent, coll, size=0.08):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "PLAIN_AXES"
    ob.empty_display_size = size
    ob.location = loc
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def box(bm, x0, x1, y0, y1, z0, z1, mat):
    """Caja alineada a los ejes, en coordenadas de Godot."""
    v = [bm.verts.new(P(x, y, z)) for y in (y0, y1) for (x, z) in ((x0, z0), (x1, z0), (x1, z1), (x0, z1))]
    for idx in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
        bm.faces.new([v[i] for i in idx]).material_index = mat


def lathe(bm, cx, cz, profile, mats, segs=SEGS):
    """Sólido de revolución cerrado (eje Y de Godot). `profile` = [(r, y)], de abajo arriba; r = 0 es polo.
    `mats[i]` es el material del tramo profile[i] → profile[i + 1]."""
    rings = []
    for r, y in profile:
        if r < 1e-6:
            rings.append([bm.verts.new(P(cx, y, cz))])
        else:
            rings.append([bm.verts.new(P(cx + r * math.cos(2 * math.pi * k / segs), y,
                                         cz + r * math.sin(2 * math.pi * k / segs))) for k in range(segs)])
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(segs):
            k1 = (k + 1) % segs
            if len(a) == 1:
                f = (a[0], b[k1], b[k])
            elif len(b) == 1:
                f = (a[k], a[k1], b[0])
            else:
                f = (a[k], a[k1], b[k1], b[k])
            bm.faces.new(f).material_index = mats[i]


def prism(bm, p0, p1, half, mat):
    """Barra de sección cuadrada entre dos puntos de Godot (pico de la aceitera)."""
    from mathutils import Vector
    a, b = Vector(p0), Vector(p1)
    axis = (b - a).normalized()
    side = axis.cross(Vector((0, 0, 1))).normalized() * half
    up = side.cross(axis).normalized() * half
    corners = [side + up, -side + up, -side - up, side - up]
    va = [bm.verts.new(P(*(a + c))) for c in corners]
    vb = [bm.verts.new(P(*(b + c))) for c in corners]
    bm.faces.new(va).material_index = mat
    bm.faces.new(list(reversed(vb))).material_index = mat
    for k in range(4):
        k1 = (k + 1) % 4
        bm.faces.new((va[k], va[k1], vb[k1], vb[k])).material_index = mat


# --- Mostrador -------------------------------------------------------------------------------


def build_counter(bm):
    # 0 wood_mid, 1 wood_light, 2 wood_dark, 3 canvas_stripe, 4 canvas_cream,
    # 5 paprika_sweet, 6 paprika_hot, 7 salt, 8 oil, 9 potato_cooked
    box(bm, -1.92, 1.92, 0.0, 0.06, -0.47, 0.47, 2)  # zócalo
    box(bm, -1.96, 1.96, 0.06, 1.02, -0.50, 0.50, 0)  # cuerpo
    box(bm, -2.02, 2.02, 1.02, TOP_Y, -0.56, 0.56, 1)  # tablero con vuelo a los dos lados
    for x in (-1.96, -0.66, 0.63, 1.93):  # listones verticales en los dos lados
        box(bm, x, x + 0.03, 0.06, 1.02, 0.50, 0.515, 2)
        box(bm, x, x + 0.03, 0.06, 1.02, -0.515, -0.50, 2)
    for z0, z1 in ((0.50, 0.515), (-0.515, -0.50)):  # moldura bajo el tablero
        box(bm, -1.96, 1.96, 0.94, 0.98, z0, z1, 2)
    # Lado de pase (−Z): banda roja de feria a media altura, marca el lado de la cocina.
    box(bm, -1.93, 1.93, 0.55, 0.65, -0.52, -0.515, 3)
    # Lado de condimentar (+Z): una placa crema con el color de cada recipiente debajo de él.
    plates = [(x, 5 + i) for i, (_, x, _) in enumerate(DISPENSERS)] + [(BOWL_X, 9)]
    for x, mat in plates:
        x = max(-1.76, min(1.76, x))  # las de los extremos no se salen de la esquina
        box(bm, x - 0.18, x + 0.18, 0.62, 0.88, 0.515, 0.525, 4)
        box(bm, x - 0.13, x + 0.13, 0.67, 0.83, 0.525, 0.535, mat)


def build_tray(bm):
    # 0 wood_dark, 1 wood_light. Tablero oscuro con borde; la caja apoya a y = TRAY_TOP.
    x0, x1 = TRAY_X - TRAY_W / 2, TRAY_X + TRAY_W / 2
    z0, z1 = TRAY_Z - TRAY_D / 2, TRAY_Z + TRAY_D / 2
    box(bm, x0, x1, TOP_Y, TRAY_TOP - 0.01, z0, z1, 0)
    box(bm, x0 + 0.04, x1 - 0.04, TRAY_TOP - 0.01, TRAY_TOP, z0 + 0.04, z1 - 0.04, 1)
    rim = 0.03
    box(bm, x0, x1, TRAY_TOP - 0.01, TRAY_TOP + 0.02, z0, z0 + rim, 0)
    box(bm, x0, x1, TRAY_TOP - 0.01, TRAY_TOP + 0.02, z1 - rim, z1, 0)
    box(bm, x0, x0 + rim, TRAY_TOP - 0.01, TRAY_TOP + 0.02, z0 + rim, z1 - rim, 0)
    box(bm, x1 - rim, x1, TRAY_TOP - 0.01, TRAY_TOP + 0.02, z0 + rim, z1 - rim, 0)


# --- Recipientes (origen en la base, encima del tablero) ------------------------------------


def build_tin(band):
    def fill(bm):
        # 0 cuerpo (color del pimentón), 1 faja, 2 iron_black (aro), 3 polvo (color del pimentón)
        lathe(bm, 0.0, 0.0, [
            (0.0, 0.0), (0.12, 0.0), (0.12, 0.04), (0.124, 0.04), (0.124, 0.13), (0.12, 0.13),
            (0.12, 0.17), (0.128, 0.17), (0.128, 0.188), (0.105, 0.188), (0.06, 0.218), (0.0, 0.232),
        ], [0, 0, 1, 1, 1, 0, 2, 2, 2, 3, 3])
    return fill


def build_salt(bm):
    # 0 wood_mid, 1 wood_dark, 2 salt
    lathe(bm, 0.0, 0.0, [
        (0.0, 0.0), (0.10, 0.0), (0.14, 0.06), (0.155, 0.10), (0.162, 0.115), (0.14, 0.122),
        (0.10, 0.155), (0.0, 0.172),
    ], [0, 0, 0, 1, 1, 2, 2])
    for x, y, z in ((-0.06, 0.15, 0.03), (0.05, 0.152, 0.06), (0.02, 0.16, -0.05), (-0.02, 0.165, 0.0),
                    (0.08, 0.14, -0.01)):
        box(bm, x - 0.016, x + 0.016, y, y + 0.03, z - 0.016, z + 0.016, 2)  # granos de sal gorda


def build_oil(bm):
    # 0 oil, 1 steel_grey, 2 iron_black
    lathe(bm, 0.0, 0.0, [
        (0.0, 0.0), (0.115, 0.0), (0.122, 0.02), (0.118, 0.10), (0.07, 0.15), (0.034, 0.16),
        (0.034, 0.19), (0.046, 0.19), (0.046, 0.205), (0.0, 0.215),
    ], [0, 0, 0, 0, 1, 1, 2, 2, 2])
    prism(bm, (0.06, 0.10, 0.0), (0.19, 0.225, 0.0), 0.012, 1)  # pico
    box(bm, -0.165, -0.142, 0.04, 0.16, -0.012, 0.012, 2)  # asa
    box(bm, -0.142, -0.10, 0.04, 0.062, -0.012, 0.012, 2)
    box(bm, -0.142, -0.07, 0.138, 0.16, -0.012, 0.012, 2)


def build_bowl(bm):
    # 0 wood_light (fuera), 1 wood_dark (borde), 2 wood_mid (dentro)
    lathe(bm, 0.0, 0.0, [
        (0.0, 0.0), (0.16, 0.0), (0.172, 0.012), (0.245, 0.14), (0.25, 0.16), (0.218, 0.162),
        (0.20, 0.10), (0.13, 0.072), (0.0, 0.07),
    ], [0, 0, 0, 1, 1, 2, 2, 2], segs=16)


# --- Montaje ---------------------------------------------------------------------------------


def root_empty(name, coll):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "PLAIN_AXES"
    coll.objects.link(ob)
    return ob


def build_all():
    station_coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("seasoning_station") or bpy.data.objects["asset"]
    root.name = "seasoning_station"
    mesh_object("counter", ("mat_wood_mid", "mat_wood_light", "mat_wood_dark", "mat_canvas_stripe",
                            "mat_canvas_cream", "mat_paprika_sweet", "mat_paprika_hot", "mat_salt", "mat_oil",
                            "mat_potato_cooked"), root, station_coll, build_counter)
    mesh_object("tray", ("mat_wood_dark", "mat_wood_light"), root, station_coll, build_tray)
    front = bpy.data.objects["Anchor_Front"]
    front.location = P(0.0, 0.0, -0.56)
    empty("Anchor_Tray", P(TRAY_X, TRAY_TOP, TRAY_Z), root, station_coll)
    for name, x, _ in DISPENSERS:
        empty("Anchor_Dispenser_" + name, P(x, TOP_Y, DISPENSER_Z), root, station_coll)
    empty("Anchor_Bowl", P(BOWL_X, TOP_Y, 0.0), root, station_coll)
    empty("Anchor_PassSide", P(0.0, 0.0, -1.2), root, station_coll)
    empty("Anchor_OperatorSide", P(0.0, 0.0, 1.2), root, station_coll)

    disp_coll = collection("export_dispenser")
    disp = root_empty("seasoning_dispenser", disp_coll)
    mesh_object("paprika_sweet", ("mat_paprika_sweet", "mat_canvas_cream", "mat_iron_black", "mat_paprika_sweet"),
                disp, disp_coll, build_tin(1))
    mesh_object("paprika_hot", ("mat_paprika_hot", "mat_iron_black", "mat_iron_black", "mat_paprika_hot"),
                disp, disp_coll, build_tin(1))
    mesh_object("salt", ("mat_wood_mid", "mat_wood_dark", "mat_salt"), disp, disp_coll, build_salt)
    mesh_object("oil", ("mat_oil", "mat_steel_grey", "mat_iron_black"), disp, disp_coll, build_oil)
    empty("Anchor_Front_dispenser", P(0.0, 0.0, -0.15), disp, disp_coll)

    bowl_coll = collection("export_bowl")
    bowl = root_empty("cachelos_bowl", bowl_coll)
    mesh_object("bowl", ("mat_wood_light", "mat_wood_dark", "mat_wood_mid"), bowl, bowl_coll, build_bowl)
    empty("Anchor_Portions", P(0.0, 0.07, 0.0), bowl, bowl_coll)
    empty("Anchor_Front_bowl", P(0.0, 0.0, -0.25), bowl, bowl_coll)
    return root
