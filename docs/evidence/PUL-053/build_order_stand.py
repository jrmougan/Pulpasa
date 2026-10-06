"""Geometría de art/blender/order_stand.blend (PUL-053), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-053/build_order_stand.py").read(), ns); ns["build_all"]()
Crea en la colección `export` la raíz `order_stand` (frente +Y = −Z de Godot, hacia el cliente y la cámara):
- `counter`: mostrador de madera de 1,84 × 1,0 × 0,5 (`wood_mid`, tablero `wood_light`, zócalo y listones
  `wood_dark`), placa crema redonda en el frente para el número de puesto (`Anchor_Number`) y cuatro postes.
- `sign`: cartel crema con marco oscuro en el centro del toldillo, fondo del `#id` de la comanda (`Anchor_Sign`).
- `awning_1..4`: toldillo inclinado hacia la cámara con rayas crema/color y faldón festoneado, uno por puesto
  (`canvas_stripe`, `bunting_blue`, `bunting_yellow`, `bunting_green`); el juego enseña solo el de su `slot_id`.
Medidas en la escena; `level_01` escala la instancia 0,78 × 0,975, así que en el nivel mide 1,4 × 1,0 (art-bible §2.1).
Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy

M = bpy.data.materials
AWNING_COLORS = ("mat_canvas_stripe", "mat_bunting_blue", "mat_bunting_yellow", "mat_bunting_green")
# Toldillo: del borde trasero alto al delantero bajo (inclinado hacia la cámara).
ROOF_BACK_Y, ROOF_FRONT_Y = -0.26, 0.42
ROOF_BACK_Z, ROOF_FRONT_Z = 1.82, 1.60
ROOF_HALF_W = 0.96
ROOF_T = 0.03
STRIPES = 7
SCALLOPS = 8
NUMBER_Z = 0.55
SIGN_HALF_W = 0.42
SIGN_T0, SIGN_T1 = 0.18, 0.86


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
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def empty(name, loc, parent, coll):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "PLAIN_AXES"
    ob.empty_display_size = 0.08
    ob.location = loc
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def hexa(bm, pts, mat):
    """Hexaedro de 8 puntos: 0-3 abajo y 4-7 arriba, en el mismo orden."""
    v = [bm.verts.new(p) for p in pts]
    for idx in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
        bm.faces.new([v[i] for i in idx]).material_index = mat


def box(bm, x0, x1, y0, y1, z0, z1, mat):
    hexa(bm, [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
              (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], mat)


def disc_y(bm, cx, cz, r, y0, y1, mat, segs=16):
    """Cilindro con eje Y (placa del número), tapas incluidas."""
    lo = [bm.verts.new((cx + r * math.cos(2 * math.pi * k / segs), y0, cz + r * math.sin(2 * math.pi * k / segs))) for k in range(segs)]
    hi = [bm.verts.new((v.co.x, y1, v.co.z)) for v in lo]
    for k in range(segs):
        bm.faces.new((lo[k], lo[(k + 1) % segs], hi[(k + 1) % segs], hi[k])).material_index = mat
    bm.faces.new(lo).material_index = mat
    bm.faces.new(list(reversed(hi))).material_index = mat


def roof_pt(x, t, dz=0.0):
    """Punto del toldillo: t = 0 borde trasero, t = 1 borde delantero."""
    return (x, ROOF_BACK_Y + (ROOF_FRONT_Y - ROOF_BACK_Y) * t, ROOF_BACK_Z + (ROOF_FRONT_Z - ROOF_BACK_Z) * t + dz)


def roof_z(y):
    t = (y - ROOF_BACK_Y) / (ROOF_FRONT_Y - ROOF_BACK_Y)
    return ROOF_BACK_Z + (ROOF_FRONT_Z - ROOF_BACK_Z) * t


def roof_patch(bm, x0, x1, t0, t1, dz0, dz1, mat):
    hexa(bm, [roof_pt(x0, t0, dz0), roof_pt(x1, t0, dz0), roof_pt(x1, t1, dz0), roof_pt(x0, t1, dz0),
              roof_pt(x0, t0, dz1), roof_pt(x1, t0, dz1), roof_pt(x1, t1, dz1), roof_pt(x0, t1, dz1)], mat)


def build_counter(bm):
    # Materiales: 0 wood_mid, 1 wood_light, 2 wood_dark, 3 canvas_cream.
    box(bm, -0.86, 0.86, -0.18, 0.18, 0.0, 0.06, 2)  # zócalo
    box(bm, -0.88, 0.88, -0.20, 0.20, 0.06, 0.94, 0)  # cuerpo
    box(bm, -0.92, 0.92, -0.24, 0.26, 0.94, 1.0, 1)  # tablero con vuelo hacia el cliente
    for x in (-0.88, -0.47, 0.44, 0.85):  # listones del frente (las esquinas, más anchos)
        box(bm, x, x + 0.03, 0.20, 0.215, 0.06, 0.94, 2)
    box(bm, -0.88, 0.88, 0.20, 0.215, 0.86, 0.90, 2)  # moldura bajo el tablero
    disc_y(bm, 0.0, NUMBER_Z, 0.24, 0.20, 0.215, 2)  # aro de la placa
    disc_y(bm, 0.0, NUMBER_Z, 0.21, 0.215, 0.225, 3)  # placa del número
    for sx in (-1, 1):  # postes del toldillo, de la encimera al toldillo
        x = sx * 0.86
        for y in (-0.20, 0.20):
            box(bm, x - 0.025, x + 0.025, y - 0.025, y + 0.025, 1.0, roof_z(y) - 0.005, 2)


def build_sign(bm):
    # Cartel crema con marco oscuro sobre el toldillo: fondo del `#id` de la comanda.
    roof_patch(bm, -SIGN_HALF_W - 0.03, SIGN_HALF_W + 0.03, SIGN_T0 - 0.05, SIGN_T1 + 0.05, ROOF_T, ROOF_T + 0.012, 0)
    roof_patch(bm, -SIGN_HALF_W, SIGN_HALF_W, SIGN_T0, SIGN_T1, ROOF_T + 0.012, ROOF_T + 0.02, 1)


def build_awning(bm):
    # Materiales: 0 color del puesto, 1 canvas_cream, 2 wood_dark.
    w = 2 * ROOF_HALF_W / STRIPES
    for i in range(STRIPES):
        x0 = -ROOF_HALF_W + i * w
        roof_patch(bm, x0, x0 + w, 0.0, 1.0, 0.0, ROOF_T, 0 if i % 2 == 0 else 1)
    # Faldón festoneado colgando del borde delantero (placa vertical, grosor 0,02).
    y0 = ROOF_FRONT_Y - 0.01
    top, band = ROOF_FRONT_Z + ROOF_T, ROOF_FRONT_Z - 0.10
    sw = 2 * ROOF_HALF_W / SCALLOPS
    outline = [(-ROOF_HALF_W, top), (ROOF_HALF_W, top)]
    for s in range(SCALLOPS):  # de derecha a izquierda, picos redondeados hacia abajo
        cx = ROOF_HALF_W - (s + 0.5) * sw
        for k in range(5):
            a = math.pi * k / 4
            outline.append((cx + 0.5 * sw * math.cos(a), band - 0.07 * math.sin(a)))
    pts = []
    for x, z in outline:
        if not pts or (abs(pts[-1][0] - x) > 1e-6 or abs(pts[-1][1] - z) > 1e-6):
            pts.append((x, z))
    front = [bm.verts.new((x, y0 + 0.01, z)) for x, z in pts]
    back = [bm.verts.new((x, y0 - 0.01, z)) for x, z in pts]
    bm.faces.new(front).material_index = 0
    bm.faces.new(list(reversed(back))).material_index = 0
    n = len(pts)
    for k in range(n):
        bm.faces.new((front[k], back[k], back[(k + 1) % n], front[(k + 1) % n])).material_index = 0


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("order_stand") or bpy.data.objects["asset"]
    root.name = "order_stand"
    mesh_object("counter", ("mat_wood_mid", "mat_wood_light", "mat_wood_dark", "mat_canvas_cream"), root, coll, build_counter)
    mesh_object("sign", ("mat_wood_dark", "mat_canvas_cream"), root, coll, build_sign)
    for i, color in enumerate(AWNING_COLORS):
        mesh_object("awning_%d" % (i + 1), (color, "mat_canvas_cream", "mat_wood_dark"), root, coll, build_awning)
    empty("Anchor_Number", (0.0, 0.226, NUMBER_Z), root, coll)
    mid = roof_pt(0.0, (SIGN_T0 + SIGN_T1) / 2, ROOF_T + 0.02)
    empty("Anchor_Sign", mid, root, coll)
    return root
