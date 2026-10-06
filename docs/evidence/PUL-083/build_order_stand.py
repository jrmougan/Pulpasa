"""Geometría v2 de art/blender/order_stand.blend (PUL-083), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre una copia de art/blender/_template.blend (materiales v2 enlazados),
desde la raíz del repo:
    ns = {}; exec(open("docs/evidence/PUL-083/build_order_stand.py").read(), ns); ns["build_all"]()

Kiosco de entrega (art-bible v2 §1.2, §6.5, §7, §8): cuerpo de acero oscuro (`mat_steel_dark`) con
tablero `mat_steel_brushed_top`, número del puesto en **disco blanco de 0,34 m** en el frente (el
texto lo pone el `Label3D` `StandNumber` de la escena sobre `Anchor_Number`), TPV con pantalla azul
clara (`mat_emissive_screen`) y teclado de colores, más pequeño que el número; bandeja de entrega de
acero con la caja de llevar blanca con faja `brand_red` y la insignia compacta de PulpaSA (más pequeña
que el número); toldillo de lona a rayas `mat_canvas_stand_k`/`mat_canvas_paper` con festón, sostenido
por dos postes traseros. El logo nunca va en la lona (§2.7).

Una sola raíz (`order_stand`) con las mallas `counter` (cuerpo, postes y disco), `tpv`, `tray` y las
cuatro variantes `awning_1..4` superpuestas (la escena enseña la de su puesto, `OrderStandModel`).
Huella de la v1 (PUL-053): mostrador 1,44 × 0,95 × 0,47 dentro de la colisión de la escena; el
`OutlineHull` de la escena queda dentro de `counter` y del toldillo.

Coordenadas escritas en ejes de Godot (X derecha, Y arriba, Z hacia la cocina) y convertidas a
Blender con `P()`: el frente +Y de Blender es −Z en Godot (lado del cliente, el que ve la cámara de
`level_01`, donde los puestos están girados 180°).
"""

import math
import os

import bmesh
import bpy

M = bpy.data.materials

# Mostrador.
HALF_W, HALF_D = 0.70, 0.21
TOP_Y, TOP_T = 0.95, 0.05
FRONT_Z = -HALF_D
# Disco del número (≥ 0,25 m, §6.5).
DISC_Y, DISC_R = 0.50, 0.17
# Toldillo: borde trasero alto, delantero bajo (vierte hacia el cliente).
AWN_HALF_W = 0.74
AWN_BACK = (0.26, 1.78)   # (z, y) cara inferior
AWN_FRONT = (-0.34, 1.58)
AWN_T = 0.03
STRIPES = 9
VAL_H, SCALLOP_H = 0.07, 0.07
POST_X, POST_Z = 0.685, 0.19
UV_M = 2.0  # 1 unidad de UV = 2 m (materials-v2.md §2)
LOGO_PNG = "godot/assets/textures/brand/pulpasa_compacta.png"

# --- Atlas propio (512², celdas de 128 px) ----------------------------------------------------

ATLAS = "order_stand_atlas"
ATLAS_PX = 512
CELL_PX = 128
CELLS = {
    "disc": (0, 0), "logo": (1, 0), "keys": (2, 0), "box_band": (3, 0),
    "paper": (0, 1), "tpv_body": (1, 1), "screw": (2, 1),
}
SOLID = {"paper", "tpv_body"}

HEX = {
    "paper": "#F4EFE6", "ring": "#1F2326", "frame": "#2B2E30", "brand_red": "#C8402F",
    "brand_navy": "#1D3557", "steel_dark": "#4E5458", "key": "#8E9494", "key_red": "#C8402F",
    "key_yellow": "#E8C23A", "key_green": "#4FA05A",
}


def rgb(hex_str):
    h = hex_str.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def _disc():
    """Disco blanco del número con aro oscuro de 8 px (el número lo pinta el Label3D)."""
    paper, ring, back = rgb(HEX["paper"]), rgb(HEX["ring"]), rgb(HEX["steel_dark"])
    c = (CELL_PX - 1) / 2.0

    def px(x, y):
        d = math.hypot(x - c, y - c)
        if d > c + 0.5:
            return back
        return ring if d > c - 8 else paper
    return px


def _keys():
    """Teclado del TPV: carcasa oscura, 3 × 3 teclas grises y fila de cancelar/corregir/aceptar."""
    frame, grey = rgb(HEX["frame"]), rgb(HEX["key"])
    last = (rgb(HEX["key_red"]), rgb(HEX["key_yellow"]), rgb(HEX["key_green"]))

    def px(x, y):
        col, row = (x - 8) // 38, (y - 8) // 28
        if 0 <= col < 3 and 0 <= row < 4 and (x - 8) % 38 < 30 and (y - 8) % 28 < 20:
            return last[col] if row == 3 else grey
        return frame
    return px


def _band():
    """Caja de llevar: papel con faja pimentón en el 30 % inferior y filete marino encima."""
    paper, red, navy = rgb(HEX["paper"]), rgb(HEX["brand_red"]), rgb(HEX["brand_navy"])

    def px(x, y):
        if y >= 90:
            return red
        if y >= 82:
            return navy
        return paper
    return px


def _screw():
    head, slot = rgb(HEX["steel_dark"]), rgb(HEX["frame"])
    return lambda x, y: slot if (abs(y - 64) < 10 and abs(x - 64) < 44) else head


def _logo():
    """Insignia compacta de PulpaSA (PUL-088) sobre papel, reducida a 112 px con filtro de caja."""
    paper = rgb(HEX["paper"])
    img = bpy.data.images.load(os.path.abspath(LOGO_PNG), check_existing=False)
    w, h = img.size
    src = list(img.pixels)
    bpy.data.images.remove(img)
    size, margin = 112, 8
    k = w / size

    def sample(x, y):
        # (x, y) en la celda desde arriba; la imagen de Blender va de abajo arriba.
        acc = [0.0, 0.0, 0.0, 0.0]
        n = 0
        for sy in range(int(y * k), int((y + 1) * k)):
            for sx in range(int(x * k), int((x + 1) * k)):
                i = ((h - 1 - sy) * w + sx) * 4
                a = src[i + 3]
                for ch in range(3):
                    acc[ch] += src[i + ch] * a
                acc[3] += a
                n += 1
        a = acc[3] / n
        return tuple(acc[ch] / n + paper[ch] * (1.0 - a) for ch in range(3))

    cache = {}

    def px(x, y):
        if not (margin <= x < margin + size and margin <= y < margin + size):
            return paper
        key = (x - margin, y - margin)
        if key not in cache:
            cache[key] = sample(*key)
        return cache[key]
    return px


def build_atlas():
    """Atlas de color (albedo sRGB) del asset, determinista, empaquetado en el .blend."""
    tiles = {
        "disc": _disc(), "logo": _logo(), "keys": _keys(), "box_band": _band(),
        "paper": lambda x, y: rgb(HEX["paper"]), "tpv_body": lambda x, y: rgb(HEX["frame"]),
        "screw": _screw(),
    }
    back = rgb(HEX["steel_dark"])
    pixels = [0.0] * (ATLAS_PX * ATLAS_PX * 4)
    for i in range(ATLAS_PX * ATLAS_PX):
        pixels[i * 4:i * 4 + 4] = (*back, 1.0)
    for name, (cx, cy) in CELLS.items():
        fn = tiles[name]
        for ty in range(CELL_PX):
            row = (cy + 1) * CELL_PX - 1 - ty
            for tx in range(CELL_PX):
                i = (row * ATLAS_PX + cx * CELL_PX + tx) * 4
                r, g, b = fn(tx, ty)
                pixels[i:i + 4] = (r, g, b, 1.0)
    img = bpy.data.images.get(ATLAS)
    if img is not None:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(ATLAS, ATLAS_PX, ATLAS_PX, alpha=False)
    img.colorspace_settings.name = "sRGB"
    img.pixels.foreach_set(pixels)
    img.filepath_raw = "//" + ATLAS + ".png"
    img.file_format = "PNG"
    img.pack()
    return img


def atlas_material(img):
    mat = M.get(ATLAS)
    if mat is not None:
        M.remove(mat)
    mat = M.new(ATLAS)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.55
    bsdf.inputs["Metallic"].default_value = 0.0
    return mat


# --- Utilidades de malla (las de PUL-082, más prismas y hexaedros) ------------------------------


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


class Builder:
    """Acumula geometría en un BMesh con material y celda del atlas por cara.

    `mat` es un nombre `mat_*` de la biblioteca o `@celda` del atlas propio."""

    def __init__(self):
        self.bm = bmesh.new()
        self.cell = self.bm.faces.layers.int.new("cell")
        self.mats = []

    def slot(self, mat):
        name = ATLAS if mat.startswith("@") else mat
        if name not in self.mats:
            self.mats.append(name)
        return self.mats.index(name)

    def tag(self, faces, mat):
        idx = self.slot(mat)
        cell = list(CELLS).index(mat[1:]) if mat.startswith("@") else -1
        for f in faces:
            f.material_index = idx
            f[self.cell] = cell

    def box(self, x0, x1, y0, y1, z0, z1, mat, bevel=0.0):
        """Caja alineada a los ejes de Godot; `bevel` chaflana todas las aristas (art-bible §1.1)."""
        self.hexa([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1),
                   (x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)], mat, bevel)

    def hexa(self, pts, mat, bevel=0.0):
        """Hexaedro: 4 puntos de abajo y 4 de arriba (Godot), en el mismo orden."""
        bm = self.bm
        before = set(bm.faces)
        v = [bm.verts.new(P(*p)) for p in pts]
        for idx in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            bm.faces.new([v[i] for i in idx])
        if bevel > 0.0:
            edges = list({e for f in set(bm.faces) - before for e in f.edges})
            bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5,
                            clamp_overlap=True)
        self.tag(set(bm.faces) - before, mat)

    def prism_z(self, outline, z0, z1, mat, front_mat=None):
        """Prisma recto a lo largo de Z de Godot con sección convexa `outline` [(x, y)]: la cara
        z0 (la del cliente, −Z) puede llevar otro material (`front_mat`)."""
        bm = self.bm
        va = [bm.verts.new(P(x, y, z0)) for x, y in outline]
        vb = [bm.verts.new(P(x, y, z1)) for x, y in outline]
        front = bm.faces.new(va)
        faces = [bm.faces.new(list(reversed(vb)))]
        n = len(outline)
        for k in range(n):
            k1 = (k + 1) % n
            faces.append(bm.faces.new((va[k], va[k1], vb[k1], vb[k])))
        self.tag(faces, mat)
        self.tag([front], front_mat or mat)

    def rod(self, p0, p1, half, mat):
        """Barra de sección cuadrada entre dos puntos de Godot."""
        from mathutils import Vector
        a, b = Vector(p0), Vector(p1)
        axis = (b - a).normalized()
        side = axis.cross(Vector((0, 1, 0))).normalized() * half
        up = side.cross(axis).normalized() * half
        corners = [side + up, -side + up, -side - up, side - up]
        va = [tuple(a + c) for c in corners]
        vb = [tuple(b + c) for c in corners]
        self.hexa([va[0], va[1], va[2], va[3], vb[0], vb[1], vb[2], vb[3]], mat)

    def finish(self, name, parent, coll, smooth_deg=0.0):
        """UV: caja a 2 m por unidad en la biblioteca; en el atlas, cada cara llena su celda
        (disco, logo, teclado, faja) o cae en el centro de la suya (colores lisos)."""
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        uv = bm.loops.layers.uv.verify()
        cell_names = list(CELLS)
        for face in bm.faces:
            n = face.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            pts = []
            for loop in face.loops:
                co = loop.vert.co
                pts.append(((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax])
            if face[self.cell] < 0:
                for loop, (u, v) in zip(face.loops, pts):
                    loop[uv].uv = (u / UV_M, v / UV_M)
                continue
            cell_name = cell_names[face[self.cell]]
            cx, cy = CELLS[cell_name]
            us, vs = [p[0] for p in pts], [p[1] for p in pts]
            du, dv = max(us) - min(us) or 1.0, max(vs) - min(vs) or 1.0
            lo, hi = (2 / CELL_PX, 1 - 2 / CELL_PX) if cell_name not in SOLID else (0.3, 0.7)
            # Caras laterales: «arriba» de la etiqueta es Z de Blender; sin espejo vista de frente.
            mirror = (ax == 0 and n[0] < 0) or (ax == 1 and n[1] > 0)
            for loop, (u, v) in zip(face.loops, pts):
                fu, fv = (u - min(us)) / du, (v - min(vs)) / dv
                if mirror:
                    fu = 1.0 - fu
                loop[uv].uv = ((cx + lo + fu * (hi - lo)) / 4, (cy + lo + fv * (hi - lo)) / 4)
        # Polígonos convexos de más de 4 lados (disco, festón) en abanico: así el exportador
        # calcula tangentes para los normal maps de la biblioteca.
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for m in self.mats:
            me.materials.append(M[m])
        if smooth_deg > 0.0:
            for p in me.polygons:
                p.use_smooth = True
            me.set_sharp_from_angle(angle=math.radians(smooth_deg))
        if me.attributes.get("cell") is not None:
            me.attributes.remove(me.attributes["cell"])
        remove_object(name)
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


# --- Piezas ----------------------------------------------------------------------------------


def build_counter(b):
    """Cuerpo de acero oscuro, tablero, marco del frente, disco del número y postes del toldillo."""
    top, front, mid, dark = "mat_steel_brushed_top", "mat_steel_brushed", "mat_steel_brushed_mid", "mat_steel_dark"
    b.box(-HALF_W, HALF_W, 0.06, TOP_Y - TOP_T, -HALF_D, HALF_D, dark, bevel=0.02)
    b.box(-0.68, 0.68, 0.0, 0.06, -0.19, 0.19, "mat_rubber")  # zócalo
    b.box(-0.72, 0.72, TOP_Y - TOP_T, TOP_Y, -0.235, 0.235, top, bevel=0.015)
    # Marco del frente (Z2): largueros de las esquinas, travesaño bajo el tablero y zócalo de acero.
    fz0, fz1 = FRONT_Z - 0.008, FRONT_Z + 0.004
    for x in (-0.665, 0.665):
        b.box(x - 0.035, x + 0.035, 0.06, TOP_Y - TOP_T, fz0, fz1, mid, bevel=0.006)
    b.box(-0.63, 0.63, 0.83, 0.88, fz0, fz1, front, bevel=0.006)
    b.box(-0.63, 0.63, 0.06, 0.15, fz0, fz1, mid, bevel=0.006)
    # Tornillos del marco (≥ 0,06 m: se leen a 1080p, §6.1-2).
    for x in (-0.665, 0.665):
        for y in (0.12, 0.85):
            b.box(x - 0.03, x + 0.03, y - 0.03, y + 0.03, fz0 - 0.004, fz0, "@screw")
    # Disco blanco del número (0,34 m), un poco saliente.
    segs = 24
    disc = [(DISC_R * math.cos(2 * math.pi * k / segs), DISC_Y + DISC_R * math.sin(2 * math.pi * k / segs))
            for k in range(segs)]
    b.prism_z(disc, fz0 - 0.012, fz0, dark, front_mat="@disc")
    # Postes traseros del toldillo y brazos bajo sus costados.
    by, fy = AWN_BACK[1], AWN_FRONT[1]
    for x in (-POST_X, POST_X):
        b.box(x - 0.02, x + 0.02, TOP_Y, by - 0.004, POST_Z - 0.02, POST_Z + 0.02, mid, bevel=0.005)
        t = (POST_Z - AWN_FRONT[0]) / (AWN_BACK[0] - AWN_FRONT[0])
        y_post = fy + (by - fy) * t
        b.rod((x, y_post - 0.02, POST_Z), (x, fy - 0.012, AWN_FRONT[0] + 0.05), 0.012, mid)


def build_tpv(b):
    """TPV pequeño en la esquina del cliente: base, teclado de colores y pantalla azul clara
    inclinada hacia la cámara (más pequeña que el número, §6.5)."""
    body = "@tpv_body"
    b.box(-0.58, -0.26, TOP_Y, TOP_Y + 0.04, -0.215, -0.02, body, bevel=0.01)
    # Teclado inclinado (cara superior con las teclas).
    x0, x1 = -0.56, -0.40
    b.hexa([(x0, TOP_Y + 0.04, -0.20), (x1, TOP_Y + 0.04, -0.20), (x1, TOP_Y + 0.04, -0.06),
            (x0, TOP_Y + 0.04, -0.06), (x0, TOP_Y + 0.05, -0.20), (x1, TOP_Y + 0.05, -0.20),
            (x1, TOP_Y + 0.075, -0.06), (x0, TOP_Y + 0.075, -0.06)], "@keys")
    # Mástil y pantalla (marco oscuro + cara emisiva), inclinada 25° hacia atrás.
    b.box(-0.34, -0.30, TOP_Y + 0.04, TOP_Y + 0.11, -0.07, -0.04, body)
    sx0, sx1 = -0.43, -0.21
    lo, hi = (TOP_Y + 0.09, -0.11), (TOP_Y + 0.22, -0.05)  # (y, z) del borde bajo y alto, cara frontal
    t = 0.025
    b.hexa([(sx0, lo[0], lo[1]), (sx1, lo[0], lo[1]), (sx1, lo[0] - 0.01, lo[1] + t),
            (sx0, lo[0] - 0.01, lo[1] + t), (sx0, hi[0], hi[1]), (sx1, hi[0], hi[1]),
            (sx1, hi[0] - 0.01, hi[1] + t), (sx0, hi[0] - 0.01, hi[1] + t)], body)
    m = 0.014
    dy, dz = hi[0] - lo[0], hi[1] - lo[1]
    ln = math.hypot(dy, dz)
    ey, ez = dy / ln * m, dz / ln * m
    ny, nz = 0.004 * dz / ln, -0.004 * dy / ln  # 4 mm hacia fuera (cliente)
    a = (lo[0] + ey + ny, lo[1] + ez + nz)
    c = (hi[0] - ey + ny, hi[1] - ez + nz)
    a0 = (lo[0] + ey, lo[1] + ez)
    c0 = (hi[0] - ey, hi[1] - ez)
    b.hexa([(sx0 + m, a0[0], a0[1]), (sx1 - m, a0[0], a0[1]), (sx1 - m, a[0], a[1]), (sx0 + m, a[0], a[1]),
            (sx0 + m, c0[0], c0[1]), (sx1 - m, c0[0], c0[1]), (sx1 - m, c[0], c[1]), (sx0 + m, c[0], c[1])],
           "mat_emissive_screen")


def build_tray(b):
    """Bandeja de entrega de acero (Z1, limpia) con la caja de llevar de la marca."""
    y0, y1 = TOP_Y, TOP_Y + 0.012
    x0, x1, z0, z1 = -0.04, 0.58, -0.20, 0.17
    b.box(x0, x1, y0, y1, z0, z1, "mat_steel_brushed", bevel=0.004)
    r, h = 0.015, y1 + 0.02
    light = "mat_steel_brushed"
    b.box(x0, x1, y1, h, z0, z0 + r, light, bevel=0.004)
    b.box(x0, x1, y1, h, z1 - r, z1, light, bevel=0.004)
    b.box(x0, x0 + r, y1, h, z0 + r, z1 - r, light, bevel=0.004)
    b.box(x1 - r, x1, y1, h, z0 + r, z1 - r, light, bevel=0.004)
    # Caja de llevar: cuerpo con faja, tapa de papel e insignia compacta en el frente.
    bx0, bx1, bz0, bz1 = 0.07, 0.47, -0.13, 0.10
    top = y1 + 0.135
    b.box(bx0, bx1, y1, top, bz0, bz1, "@box_band")
    b.box(bx0 - 0.006, bx1 + 0.006, top, top + 0.022, bz0 - 0.006, bz1 + 0.006, "@paper", bevel=0.004)
    cx, size = (bx0 + bx1) / 2, 0.095
    ly0 = y1 + 0.135 * 0.36
    b.box(cx - size / 2, cx + size / 2, ly0, ly0 + size * 0.98, bz0 - 0.002, bz0, "@logo")


def build_awning(b, k):
    """Toldillo de lona a rayas (color del puesto en los bordes) con festón: cada raya baja en una
    faja y un ondulado de su color."""
    color, paper = "mat_canvas_stand_%d" % k, "mat_canvas_paper"
    (bz, by), (fz, fy) = AWN_BACK, AWN_FRONT
    w = 2 * AWN_HALF_W / STRIPES
    for i in range(STRIPES):
        mat = color if i % 2 == 0 else paper
        x0, x1 = -AWN_HALF_W + i * w, -AWN_HALF_W + (i + 1) * w
        b.hexa([(x0, fy, fz), (x1, fy, fz), (x1, by, bz), (x0, by, bz),
                (x0, fy + AWN_T, fz), (x1, fy + AWN_T, fz), (x1, by + AWN_T, bz), (x0, by + AWN_T, bz)], mat)
        # Faldón: faja recta y medio óvalo (festón), de 1 cm de grosor, colgando del borde delantero.
        vz0, vz1 = fz - 0.006, fz + 0.006
        b.box(x0, x1, fy - VAL_H, fy + AWN_T, vz0, vz1, mat)
        cx, rx = (x0 + x1) / 2, w / 2
        segs = 8
        half = [(cx + rx * math.cos(math.pi * s / segs), fy - VAL_H - SCALLOP_H * math.sin(math.pi * s / segs))
                for s in range(segs + 1)]
        b.prism_z(list(reversed(half)), vz0, vz1, mat)


# --- Montaje ----------------------------------------------------------------------------------


def build_all():
    assert atlas_material(build_atlas()).name == ATLAS
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("order_stand") or bpy.data.objects["asset"]
    root.name = "order_stand"
    for name, fn in (("counter", build_counter), ("tpv", build_tpv), ("tray", build_tray)):
        b = Builder()
        fn(b)
        b.finish(name, root, coll)
    for k in range(1, 5):
        b = Builder()
        build_awning(b, k)
        b.finish("awning_%d" % k, root, coll)
    bpy.data.objects["Anchor_Front"].location = P(0.0, 0.0, -0.235)
    empty("Anchor_Number", P(0.0, DISC_Y, FRONT_Z - 0.02), root, coll)
    empty("Anchor_Sign", P(0.0, 1.712, -0.091), root, coll)
    src = bpy.data.texts.get("build_order_stand.py") or bpy.data.texts.new("build_order_stand.py")
    src.from_string(open("docs/evidence/PUL-083/build_order_stand.py").read())
    return root
