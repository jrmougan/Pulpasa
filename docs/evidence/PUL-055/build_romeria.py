"""Geometría de art/blender/romeria.blend (PUL-055), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-055/build_romeria.py").read(), ns); ns["build_all"]()
Tres raíces, cada una en su colección y con su `Anchor_Front` (+Y de Blender = −Z de Godot). En los tres
el lado vistoso mira a +Y: `environment.tscn` gira 180° las instancias que deben mirar a la cámara.
- `export` → `ground`: losa de tierra apisonada de 8 × 11 m (medio campo jugable) con piedras sueltas.
  El nivel la instancia dos veces lado a lado; los bordes laterales son rectos para que no se note la junta.
  Cada `.glb` está limitado a 12 m de planta (`test_assets_models.gd`), de ahí el módulo.
- `export_tent` → `tent`: carpa de la pulpeira de barra (11,9 × 3,75 m, 4,85 m de alto) que va detrás de
  la cocina: tejado a dos aguas con rayas crema/rojo, faldón festoneado, postes, suelo de losas, cartel
  «PULPO Á FEIRA» en la cumbrera, banderines hacia los mástiles de las esquinas y tres farolillos.
- `export_decor` → `decor`: franja lateral de 2,6 × 11,8 m fuera de la zona jugable: mesa corrida con
  mantel y platos, dos bancos, barriles, sacos, cajas de pescado, dos arcos de banderines, ristra de
  farolillos y matas de hierba. El nivel la instancia a izquierda y derecha (esta girada 180°).
Se versiona como registro reproducible.
"""

import math
import random

import bmesh
import bpy

M = bpy.data.materials
BUNTING = ("mat_bunting_blue", "mat_bunting_yellow", "mat_bunting_green", "mat_canvas_stripe")

# --- Carpa (coordenadas de Blender, origen en el centro de la base) ---
TENT_HW = 5.95  # medio ancho del tejado
EAVE_Y, EAVE_Z = 1.75, 2.6  # alero delantero
RIDGE_Z = 3.8
ROOF_T = 0.05
STRIPES = 23
SCALLOPS = 16
SCALLOP_H = 0.35
POST_X = (-5.75, -2.5, 2.5, 5.75)
MAST_Z = 3.3
SIGN_Z0, SIGN_Z1 = 3.95, 4.85
SIGN_HW = 2.35
PIXEL = 0.09
TEXT = "PULPO Á FEIRA"

# Fuente de 3 × 5 píxeles (filas de arriba abajo).
FONT = {
    "P": ("###", "#.#", "###", "#..", "#.."),
    "U": ("#.#", "#.#", "#.#", "#.#", "###"),
    "L": ("#..", "#..", "#..", "#..", "###"),
    "O": ("###", "#.#", "#.#", "#.#", "###"),
    "A": (".#.", "#.#", "###", "#.#", "#.#"),
    "Á": (".#.", "#.#", "###", "#.#", "#.#"),
    "F": ("###", "#..", "##.", "#..", "#.."),
    "E": ("###", "#..", "##.", "#..", "###"),
    "I": ("###", ".#.", ".#.", ".#.", "###"),
    "R": ("##.", "#.#", "##.", "#.#", "#.#"),
    " ": ("...", "...", "...", "...", "..."),
}


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
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def face(bm, pts, mat):
    f = bm.faces.new([bm.verts.new(p) for p in pts])
    f.material_index = mat
    return f


def hexa(bm, pts, mat, skip_bottom=False):
    """Hexaedro de 8 puntos: 0-3 abajo y 4-7 arriba, en el mismo orden antihorario visto desde arriba."""
    v = [bm.verts.new(p) for p in pts]
    faces = [(4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    if not skip_bottom:
        faces.append((0, 3, 2, 1))
    for idx in faces:
        bm.faces.new([v[i] for i in idx]).material_index = mat


def box(bm, x0, x1, y0, y1, z0, z1, mat, skip_bottom=False):
    hexa(bm, [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
              (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], mat, skip_bottom)


def lathe(bm, cx, cy, rings, n, mat, cap_top=True, cap_bottom=False, rot=0.0):
    """Sólido de revolución: rings = [(z, r), ...] de abajo arriba."""
    loops = []
    for z, r in rings:
        loops.append([bm.verts.new((cx + r * math.cos(rot + 2 * math.pi * i / n),
                                    cy + r * math.sin(rot + 2 * math.pi * i / n), z)) for i in range(n)])
    for a, b in zip(loops, loops[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i])).material_index = mat
    if cap_top:
        bm.faces.new(loops[-1]).material_index = mat
    if cap_bottom:
        bm.faces.new(list(reversed(loops[0]))).material_index = mat


def slab(bm, poly, z0, z1, mat, skip_bottom=False):
    """Prisma vertical de un polígono convexo antihorario (visto desde arriba)."""
    lo = [bm.verts.new((x, y, z0)) for x, y in poly]
    hi = [bm.verts.new((x, y, z1)) for x, y in poly]
    bm.faces.new(hi).material_index = mat
    if not skip_bottom:
        bm.faces.new(list(reversed(lo))).material_index = mat
    n = len(poly)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i])).material_index = mat


def thin(bm, pts, normal, t, mat):
    """Placa fina (prisma) de un polígono plano convexo; `normal` = cara vistosa."""
    nx, ny, nz = normal
    front = [bm.verts.new((x + nx * t, y + ny * t, z + nz * t)) for x, y, z in pts]
    back = [bm.verts.new((x, y, z)) for x, y, z in pts]
    f = bm.faces.new(front)
    f.material_index = mat
    f.normal_update()
    if f.normal.dot(normal) < 0:
        f.normal_flip()
        bm.faces.remove(f)
        front.reverse()
        back.reverse()
        bm.faces.new(front).material_index = mat
    bm.faces.new(list(reversed(back))).material_index = mat
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((back[i], back[j], front[j], front[i])).material_index = mat


def beam(bm, a, b, w, mat):
    """Listón de sección cuadrada `w` entre dos puntos."""
    ax, ay, az = a
    bx, by, bz = b
    d = (bx - ax, by - ay, bz - az)
    length = math.sqrt(sum(c * c for c in d))
    u = (d[0] / length, d[1] / length, d[2] / length)
    ref = (0, 0, 1) if abs(u[2]) < 0.9 else (1, 0, 0)
    s = (u[1] * ref[2] - u[2] * ref[1], u[2] * ref[0] - u[0] * ref[2], u[0] * ref[1] - u[1] * ref[0])
    sl = math.sqrt(sum(c * c for c in s))
    s = tuple(c / sl * w / 2 for c in s)
    t = (u[1] * s[2] - u[2] * s[1], u[2] * s[0] - u[0] * s[2], u[0] * s[1] - u[1] * s[0])
    corners = [(+1, +1), (-1, +1), (-1, -1), (+1, -1)]

    def p(o, i):
        cs, ct = corners[i]
        return (o[0] + s[0] * cs + t[0] * ct, o[1] + s[1] * cs + t[1] * ct, o[2] + s[2] * cs + t[2] * ct)

    hexa(bm, [p(a, i) for i in range(4)] + [p(b, i) for i in range(4)], mat)


def lerp(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def lantern(bm, cx, cy, zc, mat_body, mat_cap):
    """Farolillo de papel: huso de 6 lados de 0,34 m con tapas oscuras."""
    lathe(bm, cx, cy, [(zc - 0.17, 0.07), (zc - 0.08, 0.15), (zc + 0.08, 0.15), (zc + 0.17, 0.07)], 6,
          mat_body, cap_top=False)
    lathe(bm, cx, cy, [(zc - 0.2, 0.07), (zc - 0.17, 0.075)], 6, mat_cap, cap_top=False, cap_bottom=True)
    lathe(bm, cx, cy, [(zc + 0.17, 0.075), (zc + 0.2, 0.06)], 6, mat_cap)


def bunting_line(bm, a, b, count, facing, mats_offset=0, sag=0.0, flag_w=0.24, flag_h=0.3):
    """Cuerda de banderines triangulares entre `a` y `b` (comba `sag`), cara vistosa hacia `facing`."""
    pts = []
    for i in range(count):
        t = (i + 0.5) / count
        p = lerp(a, b, t)
        pts.append((p[0], p[1], p[2] - sag * 4 * t * (1 - t), t))
    d = (b[0] - a[0], b[1] - a[1])
    dl = math.hypot(*d)
    ux, uy = d[0] / dl, d[1] / dl
    for i, (x, y, z, _t) in enumerate(pts):
        mat = 1 + (i + mats_offset) % 4
        hw = flag_w / 2
        tri = [(x - ux * hw, y - uy * hw, z), (x + ux * hw, y + uy * hw, z), (x, y, z - flag_h)]
        thin(bm, tri, facing, 0.012, mat)
    # Cuerda: tramos rectos entre banderines.
    chain = [a] + [(x, y, z) for x, y, z, _t in pts] + [b]
    for p, q in zip(chain, chain[1:]):
        beam(bm, p, q, 0.02, 0)


# --------------------------------------------------------------------------- suelo


def fill_ground(bm):
    """0 tierra, 1 piedra. Losa de 8 × 11 m con la cara superior a 0,012 m.

    La zona jugable queda lisa: piedras sueltas o losas claras se leían como objetos tirados en el suelo
    (captura v3 de la ficha). Solo hay dos piedras de 0,055 m bajo la pared del frente (fila 10), que dan
    al módulo el alto mínimo que exige `test_assets_models.gd`.
    """
    hw, hd = 4.0, 5.5
    box(bm, -hw, hw, -hd, hd, 0.0, 0.012, 0, skip_bottom=True)
    rng = random.Random(55)
    # En las dos instancias del nivel caen en celdas de pared de la fila 10 (cols 1, 6, 9 y 14).
    spots = [(-2.5, 5.25, 0.055), (2.5, 5.25, 0.055)]
    for x, y, top in spots:
        r = 0.12
        n = 6
        rot = rng.uniform(0, math.pi)
        poly = [(x + r * math.cos(rot + 2 * math.pi * i / n) * (1.0 if i % 2 else 0.8),
                 y + r * math.sin(rot + 2 * math.pi * i / n) * (1.0 if i % 2 else 0.8)) for i in range(n)]
        slab(bm, poly, 0.0, top, 1, skip_bottom=True)


# --------------------------------------------------------------------------- carpa


def roof_point(x, y):
    """Altura del tejado (cara superior) en (x, y)."""
    return EAVE_Z + (RIDGE_Z - EAVE_Z) * (1 - abs(y) / EAVE_Y)


def fill_tent_roof(bm):
    """0 crema, 1 raya roja. Dos aguas con grosor y rayas superpuestas a 4 mm."""
    for sgn in (1, -1):
        e, r = sgn * EAVE_Y, 0.0
        hexa(bm, [(-TENT_HW, e, EAVE_Z - ROOF_T), (TENT_HW, e, EAVE_Z - ROOF_T),
                  (TENT_HW, r, RIDGE_Z - ROOF_T), (-TENT_HW, r, RIDGE_Z - ROOF_T),
                  (-TENT_HW, e, EAVE_Z), (TENT_HW, e, EAVE_Z), (TENT_HW, r, RIDGE_Z), (-TENT_HW, r, RIDGE_Z)]
             if sgn < 0 else
             [(-TENT_HW, r, RIDGE_Z - ROOF_T), (TENT_HW, r, RIDGE_Z - ROOF_T),
              (TENT_HW, e, EAVE_Z - ROOF_T), (-TENT_HW, e, EAVE_Z - ROOF_T),
              (-TENT_HW, r, RIDGE_Z), (TENT_HW, r, RIDGE_Z), (TENT_HW, e, EAVE_Z), (-TENT_HW, e, EAVE_Z)], 0)
        w = 2 * TENT_HW / STRIPES
        slope = (RIDGE_Z - EAVE_Z) / EAVE_Y
        nl = math.hypot(slope, 1.0)
        off = (0.0, sgn * 0.004 * slope / nl, 0.004 / nl)
        for i in range(1, STRIPES, 2):
            x0, x1 = -TENT_HW + i * w, -TENT_HW + (i + 1) * w
            quad = [(x0, e, EAVE_Z), (x1, e, EAVE_Z), (x1, r, RIDGE_Z), (x0, r, RIDGE_Z)]
            quad = [(p[0] + off[0], p[1] + off[1], p[2] + off[2]) for p in quad]
            face(bm, quad if sgn < 0 else list(reversed(quad)), 1)
    # Hastiales (crema) bajo el tejado.
    for sx in (-1, 1):
        x = sx * (TENT_HW - 0.02)
        tri = [(x, EAVE_Y, EAVE_Z - ROOF_T), (x, 0.0, RIDGE_Z - ROOF_T), (x, -EAVE_Y, EAVE_Z - ROOF_T)]
        thin(bm, tri, (sx, 0, 0), 0.01, 0)


def fill_tent_valance(bm):
    """0 crema, 1 raya roja. Faldón festoneado bajo el alero delantero, colores alternos."""
    w = 2 * TENT_HW / SCALLOPS
    y = EAVE_Y + 0.005
    for i in range(SCALLOPS):
        x0, x1 = -TENT_HW + i * w, -TENT_HW + (i + 1) * w
        xc = (x0 + x1) / 2
        top = EAVE_Z - ROOF_T
        bot = top - SCALLOP_H
        pts = [(x0, y, top), (x0, y, bot + 0.12)]
        for k in range(1, 4):
            a = math.pi + math.pi * k / 4
            pts.append((xc + (w / 2) * math.cos(a), y, bot + 0.12 + 0.12 * math.sin(a)))
        pts += [(x1, y, bot + 0.12), (x1, y, top)]
        thin(bm, pts, (0, 1, 0), 0.012, i % 2)


def fill_tent_frame(bm):
    """0 madera oscura. Postes, mástiles de esquina, viga del alero y patas del cartel."""
    for x in POST_X:
        top = MAST_Z if abs(x) > 5 else EAVE_Z - ROOF_T
        box(bm, x - 0.07, x + 0.07, EAVE_Y - 0.17, EAVE_Y - 0.03, 0.0, top, 0, skip_bottom=True)
        box(bm, x - 0.07, x + 0.07, -EAVE_Y + 0.03, -EAVE_Y + 0.17, 0.0, EAVE_Z - ROOF_T, 0, skip_bottom=True)
    box(bm, -TENT_HW + 0.1, TENT_HW - 0.1, EAVE_Y - 0.17, EAVE_Y - 0.03, EAVE_Z - 0.22, EAVE_Z - ROOF_T, 0)
    for x in (-SIGN_HW + 0.3, SIGN_HW - 0.3):
        box(bm, x - 0.05, x + 0.05, -0.05, 0.05, RIDGE_Z - 0.1, SIGN_Z0 + 0.1, 0, skip_bottom=True)


def fill_tent_sign(bm):
    """0 crema (tabla), 1 madera oscura (marco), 2 rojo (letras)."""
    y0, y1 = -0.03, 0.03
    box(bm, -SIGN_HW, SIGN_HW, y0, y1, SIGN_Z0, SIGN_Z1, 1)
    m = 0.06
    face(bm, [(-SIGN_HW + m, y1 + 0.003, SIGN_Z1 - m), (SIGN_HW - m, y1 + 0.003, SIGN_Z1 - m),
              (SIGN_HW - m, y1 + 0.003, SIGN_Z0 + m), (-SIGN_HW + m, y1 + 0.003, SIGN_Z0 + m)], 0)
    cols = len(TEXT) * 4 - 1
    x_start = -cols * PIXEL / 2
    z_top = (SIGN_Z0 + SIGN_Z1) / 2 + 2.5 * PIXEL - 0.04
    yl = y1 + 0.006
    for ci, ch in enumerate(TEXT):
        rows = FONT[ch]
        for ri, row in enumerate(rows):
            c = 0
            while c < 3:
                if row[c] != "#":
                    c += 1
                    continue
                c1 = c
                while c1 < 3 and row[c1] == "#":
                    c1 += 1
                x0 = -(x_start + (ci * 4 + c1) * PIXEL)
                x1 = -(x_start + (ci * 4 + c) * PIXEL)
                z1 = z_top - ri * PIXEL
                face(bm, [(x0, yl, z1), (x1, yl, z1), (x1, yl, z1 - PIXEL), (x0, yl, z1 - PIXEL)], 2)
                c = c1
        if ch == "Á":
            # Tilde inclinada hacia la derecha del lector (−X).
            x0 = -(x_start + (ci * 4 + 1) * PIXEL)
            z0 = z_top + 0.35 * PIXEL
            face(bm, [(x0 - PIXEL * 1.3, yl, z0 + PIXEL * 0.9), (x0, yl, z0 + PIXEL * 0.6),
                      (x0, yl, z0), (x0 - PIXEL * 1.3, yl, z0 + PIXEL * 0.3)], 2)


def fill_tent_floor(bm):
    """0 tierra (junta), 1 losa. Suelo bajo la carpa hasta el borde de la cocina."""
    y0, y1 = -EAVE_Y - 0.05, 2.0
    box(bm, -TENT_HW, TENT_HW, y0, y1, 0.0, 0.012, 0, skip_bottom=True)
    nx, ny = 12, 4
    gap = 0.05
    tw, td = 2 * TENT_HW / nx, (y1 - y0) / ny
    for i in range(nx):
        for j in range(ny):
            sx = (j % 2) * tw / 2
            xa = max(-TENT_HW, -TENT_HW + i * tw + gap / 2 - sx)
            xb = min(TENT_HW, -TENT_HW + (i + 1) * tw - gap / 2 - sx)
            ya, yb = y0 + j * td + gap / 2, y0 + (j + 1) * td - gap / 2
            face(bm, [(xa, ya, 0.02), (xb, ya, 0.02), (xb, yb, 0.02), (xa, yb, 0.02)], 1)
    # Pieza que falta al desplazar las filas impares (cierre por la derecha).
    for j in range(1, ny, 2):
        ya, yb = y0 + j * td + gap / 2, y0 + (j + 1) * td - gap / 2
        xa = TENT_HW - tw / 2 + gap / 2
        face(bm, [(xa, ya, 0.02), (TENT_HW, ya, 0.02), (TENT_HW, yb, 0.02), (xa, yb, 0.02)], 1)


def fill_tent_bunting(bm):
    """0 cuerda (madera oscura), 1-4 colores de banderín. Del cartel a los mástiles de las esquinas."""
    for sx in (-1, 1):
        a = (sx * (SIGN_HW - 0.05), 0.04, SIGN_Z1 - 0.05)
        b = (sx * 5.75, EAVE_Y - 0.1, MAST_Z - 0.05)
        bunting_line(bm, a, b, 9, (0, 1, 0), mats_offset=0 if sx < 0 else 2, sag=0.12)


def fill_tent_lanterns(bm):
    """0 farolillo, 1 tapa. Cuelgan del alero por delante del faldón."""
    for x in (-5.25, -0.5, 2.5):
        lantern(bm, x, EAVE_Y + 0.12, 2.1, 0, 1)
        box(bm, x - 0.01, x + 0.01, EAVE_Y + 0.11, EAVE_Y + 0.13, 2.3, EAVE_Z - 0.2, 1)


# --------------------------------------------------------------------------- decoración

DECOR_HW, DECOR_HD = 1.3, 5.9
POLES = ((-1.1, -5.5, 3.0), (1.1, -5.5, 3.0), (-1.1, 5.5, 2.8), (1.1, 5.5, 2.8))


def fill_decor_table(bm):
    """0 madera media, 1 mantel crema, 2 madera clara (platos), 3 pulpo cocido."""
    y0, y1 = -1.4, 1.4
    box(bm, -0.4, 0.4, y0, y1, 0.70, 0.75, 1)
    for x in (-0.3, 0.3):
        for y in (y0 + 0.15, y1 - 0.15):
            box(bm, x - 0.04, x + 0.04, y - 0.04, y + 0.04, 0.0, 0.70, 0, skip_bottom=True)
    for x in (-0.75, 0.75):
        box(bm, x - 0.15, x + 0.15, y0 - 0.1, y1 + 0.1, 0.40, 0.45, 0)
        for y in (y0, y1):
            box(bm, x - 0.04, x + 0.04, y - 0.04, y + 0.04, 0.0, 0.40, 0, skip_bottom=True)
    for x, y in ((-0.15, -0.8), (0.15, 0.1), (-0.12, 0.9)):
        lathe(bm, x, y, [(0.75, 0.15), (0.79, 0.18)], 8, 2, cap_top=True)
        lathe(bm, x, y, [(0.79, 0.09), (0.83, 0.07)], 6, 3, cap_top=True)


def fill_decor_barrels(bm):
    """0 madera media, 1 aros de hierro."""
    for x, y, h in ((-0.55, -4.1, 0.85), (0.25, -3.55, 0.85), (-0.6, 3.6, 0.85), (-0.1, -4.55, 0.6)):
        r = 0.28
        lathe(bm, x, y, [(0.0, r), (h * 0.5, r * 1.12), (h, r)], 8, 0, cap_top=True)
        for zh in (h * 0.18, h * 0.82):
            rr = r * (1.0 + 0.12 * (1 - abs(zh - h * 0.5) / (h * 0.5))) + 0.012
            lathe(bm, x, y, [(zh - 0.03, rr), (zh + 0.03, rr)], 8, 1, cap_top=False)


def fill_decor_crates(bm):
    """0 madera clara, 1 madera oscura (listones). Cajas de pescado apiladas."""
    for x, y, z in ((0.75, -4.7, 0.0), (0.75, -4.7, 0.25), (0.8, -4.05, 0.0), (0.7, 2.8, 0.0)):
        box(bm, x - 0.3, x + 0.3, y - 0.2, y + 0.2, z, z + 0.22, 0, skip_bottom=True)
        box(bm, x - 0.31, x + 0.31, y - 0.21, y + 0.21, z + 0.17, z + 0.2, 1)


def fill_decor_sacks(bm):
    """0 arpillera, 1 madera oscura (atadura)."""
    for i, (x, y) in enumerate(((0.55, 3.4), (0.95, 3.85), (0.3, 4.1), (-0.75, -2.6))):
        rot = i * 0.7
        lathe(bm, x, y, [(0.0, 0.2), (0.18, 0.24), (0.42, 0.2), (0.5, 0.1)], 6, 0, cap_top=False, rot=rot)
        lathe(bm, x, y, [(0.5, 0.1), (0.55, 0.11)], 6, 1, cap_top=False, rot=rot)
        lathe(bm, x, y, [(0.55, 0.11), (0.64, 0.13)], 6, 0, cap_top=True, rot=rot)


def fill_decor_poles(bm):
    """0 madera oscura, 1-4 banderines. Dos arcos de banderines (atraviesan la franja en X)."""
    for x, y, h in POLES:
        box(bm, x - 0.06, x + 0.06, y - 0.06, y + 0.06, 0.0, h, 0, skip_bottom=True)
    for y, h, off in ((-5.5, 3.0, 0), (5.5, 2.8, 1)):
        bunting_line(bm, (-1.05, y, h - 0.05), (1.05, y, h - 0.05), 6, (0, 1, 0), mats_offset=off, sag=0.15)


def fill_decor_lanterns(bm):
    """0 farolillo, 1 tapa y cuerda. Ristra a lo largo de la franja entre los postes de x = −1,1."""
    a = (-1.1, -5.44, 2.85)
    b = (-1.1, 5.44, 2.65)
    count = 7
    pts = [a]
    for i in range(count):
        t = (i + 0.5) / count
        p = lerp(a, b, t)
        z = p[2] - 0.45 * 4 * t * (1 - t)
        pts.append((p[0], p[1], z))
        lantern(bm, p[0], p[1], z - 0.25, 0, 1)
    pts.append(b)
    for p, q in zip(pts, pts[1:]):
        beam(bm, p, q, 0.02, 1)


def fill_decor_grass(bm):
    """0 hierba. Matas de tres hojas repartidas por la franja."""
    rng = random.Random(550)
    spots = ((-1.0, -2.9), (1.0, -2.0), (-1.1, 2.0), (1.05, 1.6), (0.0, 5.0), (-0.9, 4.6), (0.4, -5.1),
             (-0.2, -3.2), (1.15, 4.4), (-1.15, -0.3), (1.15, 0.2), (0.1, 2.3))
    for x, y in spots:
        for k in range(3):
            a = rng.uniform(0, math.pi) + k * math.pi / 3
            h = rng.uniform(0.18, 0.28)
            dx, dy = 0.07 * math.cos(a), 0.07 * math.sin(a)
            lean = (rng.uniform(-0.05, 0.05), rng.uniform(-0.05, 0.05))
            thin(bm, [(x - dx, y - dy, 0.0), (x + dx, y + dy, 0.0), (x + lean[0], y + lean[1], h)],
                 (-dy / 0.07, dx / 0.07, 0.0), 0.01, 0)


# --------------------------------------------------------------------------- montaje


def collection(name):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(c)
    return c


def root_with_anchor(coll, root_name, anchor_name):
    root = bpy.data.objects.get(root_name)
    if root is None:
        root = bpy.data.objects.new(root_name, None)
        root.empty_display_type = "PLAIN_AXES"
        coll.objects.link(root)
    anchor = bpy.data.objects.get(anchor_name)
    if anchor is None:
        anchor = bpy.data.objects.new(anchor_name, None)
        anchor.empty_display_type = "SPHERE"
        anchor.empty_display_size = 0.05
        coll.objects.link(anchor)
    anchor.parent = root
    anchor.location = (0.0, 0.5, 0.0)
    return root


def setup_lantern_material():
    """Farolillos: emisivo suave del mismo color (art-bible §2.6/§2.7)."""
    mat = M["mat_lantern_warm"]
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Emission Color"].default_value = bsdf.inputs["Base Color"].default_value
    bsdf.inputs["Emission Strength"].default_value = 0.6


def build_all():
    setup_lantern_material()
    # Suelo: reutiliza la raíz `asset` y el `Anchor_Front` de la plantilla.
    exp = bpy.data.collections["export"]
    root = bpy.data.objects.get("asset") or bpy.data.objects["ground"]
    root.name = "ground"
    bpy.data.objects["Anchor_Front"].parent = root
    mesh_object("ground_dirt", ["mat_ground_dirt", "mat_ground_stone"], root, exp, fill_ground)

    tent_c = collection("export_tent")
    tent = root_with_anchor(tent_c, "tent", "Anchor_Front_tent")
    mesh_object("tent_roof", ["mat_canvas_cream", "mat_canvas_stripe"], tent, tent_c, fill_tent_roof)
    mesh_object("tent_valance", ["mat_canvas_cream", "mat_canvas_stripe"], tent, tent_c, fill_tent_valance)
    mesh_object("tent_frame", ["mat_wood_dark"], tent, tent_c, fill_tent_frame)
    mesh_object("tent_sign", ["mat_canvas_cream", "mat_wood_dark", "mat_canvas_stripe"], tent, tent_c,
                fill_tent_sign)
    mesh_object("tent_floor", ["mat_ground_dirt", "mat_ground_stone"], tent, tent_c, fill_tent_floor)
    mesh_object("tent_bunting", ["mat_wood_dark"] + list(BUNTING), tent, tent_c, fill_tent_bunting)
    mesh_object("tent_lanterns", ["mat_lantern_warm", "mat_wood_dark"], tent, tent_c, fill_tent_lanterns)

    decor_c = collection("export_decor")
    decor = root_with_anchor(decor_c, "decor", "Anchor_Front_decor")
    mesh_object("decor_table", ["mat_wood_mid", "mat_canvas_cream", "mat_wood_light", "mat_octopus_cooked"],
                decor, decor_c, fill_decor_table)
    mesh_object("decor_barrels", ["mat_wood_mid", "mat_iron_black"], decor, decor_c, fill_decor_barrels)
    mesh_object("decor_crates", ["mat_wood_light", "mat_wood_dark"], decor, decor_c, fill_decor_crates)
    mesh_object("decor_sacks", ["mat_burlap", "mat_wood_dark"], decor, decor_c, fill_decor_sacks)
    mesh_object("decor_poles", ["mat_wood_dark"] + list(BUNTING), decor, decor_c, fill_decor_poles)
    mesh_object("decor_lanterns", ["mat_lantern_warm", "mat_wood_dark"], decor, decor_c, fill_decor_lanterns)
    mesh_object("decor_grass", ["mat_ground_grass"], decor, decor_c, fill_decor_grass)
