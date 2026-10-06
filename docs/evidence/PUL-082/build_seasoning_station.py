"""Geometría v2 de art/blender/seasoning_station.blend (PUL-082), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre una copia de art/blender/_template.blend (materiales v2 enlazados):
    ns = {}; exec(open("docs/evidence/PUL-082/build_seasoning_station.py").read(), ns); ns["build_all"]()

Estética v2 (art-bible v2 §1, §3, §8; materials-v2.md): mostrador de acero inoxidable con tablero
`mat_steel_brushed_top`, frentes `mat_steel_brushed`, patas, balda y fondo `mat_steel_brushed_mid`,
cajas de cartón en la balda (Z2), etiquetas de color del condimento en el frente (§2.5, como la
referencia) y tabla de corte con cuchillo en la franja trasera del tablero (Z1, ≤ 25 % del fondo).
Los colores de condimento (§2.5) no están en la biblioteca: van en el **atlas propio** del asset
(`seasoning_station_atlas`, 512², empaquetado en el .blend, art-bible §3.3), junto con las etiquetas.

Tres raíces, una por colección (cada una se exporta a su `.glb` hermano en
godot/assets/models/stations/seasoning_station/, ver `export_seasoning_station.sh`):
- `export` → `seasoning_station`: mostrador 4,0 × 1,1 × 1,1 con la bandeja de apoyo (`tray`).
- `export_dispenser` → `seasoning_dispenser`: los cuatro recipientes fijos, superpuestos en el origen
  (variantes de la misma pieza): `paprika_sweet` (lata redonda), `paprika_hot` (lata cuadrada, más
  alta, faja negra: distinta silueta, no solo tono), `salt` (cunca de barro con sal gorda) y `oil`
  (aceitera esmaltada con pico de acero y asa de goma).
- `export_bowl` → `cachelos_bowl`: cunca de barro Ø 0,5 m para las raciones de cachelos.

Geometría jugable de PUL-063/064, sin mover: bandeja en x = +0,3, z = −0,25 (apoyo a y = 1,14, el
`Anchor` del slot); dispensadores en z = +0,45, x = −1,25/−0,35/+0,95/+1,85; cuenco en x = −1,8,
fondo interior a y = 0,07; tablero a y = 1,10. Recipientes ≤ 0,25 m sobre el tablero.
Coordenadas escritas en ejes de Godot (X derecha, Y arriba, Z hacia la cámara) y convertidas a
Blender con `P()`: el frente +Y de Blender es −Z en Godot (lado de pase).
"""

import math

import bmesh
import bpy

M = bpy.data.materials

TOP_Y = 1.10
TRAY_X, TRAY_Z, TRAY_W, TRAY_D = 0.3, -0.25, 0.7, 0.55
TRAY_TOP = 1.14
DISPENSER_Z = 0.45
DISPENSERS = (("SweetPaprika", -1.25), ("HotPaprika", -0.35), ("Salt", 0.95), ("Oil", 1.85))
BOWL_X = -1.8
SEGS = 16
UV_M = 2.0  # 1 unidad de UV = 2 m (materials-v2.md §2)

# --- Atlas propio (512², celdas de 128 px) ----------------------------------------------------

ATLAS = "seasoning_station_atlas"
ATLAS_PX = 512
CELL_PX = 128
CELLS = {
    # Pintura de los recipientes (color de §2.5, desgaste claro arriba).
    "sweet": (0, 0), "hot": (1, 0), "salt": (2, 0), "oil": (3, 0),
    # Etiquetas del frente (§2.5: exactamente los colores de la pegatina).
    "lbl_sweet": (0, 1), "lbl_hot": (1, 1), "lbl_salt": (2, 1), "lbl_oil": (3, 1),
    "lbl_cachelos": (0, 2), "powder_sweet": (1, 2), "powder_hot": (2, 2), "salt_grain": (3, 2),
    "band_sweet": (0, 3), "band_hot": (1, 3), "screw": (2, 3), "oil_cap": (3, 3),
}
SOLID = {"sweet", "hot", "salt", "oil", "powder_sweet", "powder_hot", "salt_grain", "oil_cap"}

HEX = {
    "sweet": "#D6361F", "hot": "#8F1A14", "salt": "#F7F4EC", "salt_edge": "#6E4A2B", "oil": "#F2C230",
    "cachelos": "#F2D56B", "cachelos_edge": "#8E6B47", "paper": "#F4EFE6", "frame": "#2B2E30",
    "rubber": "#24272A", "steel_dark": "#4E5458",
}


def rgb(hex_str):
    h = hex_str.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def _scale(c, k):
    return tuple(min(1.0, max(0.0, v * k)) for v in c)


def _blobs(rng, n, size):
    """Ruido de valor (rejilla de n × n cada `size` px, interpolación suave y periódica): manchas
    grandes y blandas, nada más fino de 4 px (§3.2)."""
    grid = [[math.tanh(rng.gauss(0.0, 1.0)) for _ in range(n)] for _ in range(n)]

    def at(x, y):
        fx, fy = x / size, y / size
        x0, y0 = int(fx), int(fy)
        tx, ty = fx - x0, fy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        g = lambda i, j: grid[j % n][i % n]
        top = g(x0, y0) * (1 - tx) + g(x0 + 1, y0) * tx
        bot = g(x0, y0 + 1) * (1 - tx) + g(x0 + 1, y0 + 1) * tx
        return top * (1 - ty) + bot * ty
    return at


def _paint(color, rng):
    """Pintura de lata: color liso, roce claro en el 15 % superior y manchas de 16 px a ±4 %."""
    base, noise = rgb(color), _blobs(rng, 8, 16)

    def px(x, y):
        c = _scale(base, 1.0 + 0.04 * noise(x, y))
        t = min(1.0, max(0.0, (y / (CELL_PX - 1) - 0.85) / 0.15)) * 0.10
        return tuple(v * (1.0 - t) + t for v in c)
    return px


def _powder(color, rng):
    """Polvo o sal: grumos de 8 px a ±10 %, sin grano fino (§3.2)."""
    base, noise = rgb(color), _blobs(rng, 16, 8)
    return lambda x, y: _scale(base, 1.0 + 0.10 * noise(x, y))


def _label(fill, inner_border, spark=False):
    """Etiqueta: marco oscuro de 8 px, borde interior de 12 px y relleno del condimento.
    El picante lleva tres chispas claras (como su pegatina: 1,9:1 más icono)."""
    frame, border, inner, paper = rgb(HEX["frame"]), rgb(inner_border), rgb(fill), rgb(HEX["paper"])
    h = CELL_PX

    def px(x, y):
        if spark and 44 <= y <= 84 and any(abs(x - cx) <= (y - 44) * 0.3 for cx in (40, 64, 88)):
            return paper
        if 20 <= x < h - 20 and 20 <= y < h - 20:
            return inner
        if 8 <= x < h - 8 and 8 <= y < h - 8:
            return border
        return frame
    return px


def _band(back, stripe):
    """Faja de lata: fondo con dos franjas de 16 px."""
    a, b = rgb(back), rgb(stripe)
    return lambda x, y: b if (24 <= y < 40 or 88 <= y < 104) else a


def _screw():
    head, slot = rgb(HEX["steel_dark"]), rgb(HEX["frame"])
    return lambda x, y: slot if (abs(y - 64) < 10 and abs(x - 64) < 44) else head


def build_atlas():
    """Atlas de color (albedo sRGB) del asset, determinista (semilla fija), empaquetado en el .blend.
    Python puro (el Blender del MCP no trae numpy): 512² píxeles, se genera en segundos."""
    import random

    rng = random.Random(82)
    tiles = {
        "sweet": _paint(HEX["sweet"], rng),
        "hot": _paint(HEX["hot"], rng),
        "salt": _paint(HEX["salt"], rng),
        "oil": _paint(HEX["oil"], rng),
        "lbl_sweet": _label(HEX["sweet"], HEX["paper"]),
        "lbl_hot": _label(HEX["hot"], HEX["paper"], spark=True),
        "lbl_salt": _label(HEX["salt"], HEX["salt_edge"]),
        "lbl_oil": _label(HEX["oil"], HEX["paper"]),
        "lbl_cachelos": _label(HEX["cachelos"], HEX["cachelos_edge"]),
        "powder_sweet": _powder("#C8321D", rng),
        "powder_hot": _powder("#7E1611", rng),
        "salt_grain": _powder(HEX["salt"], rng),
        "band_sweet": _band(HEX["paper"], HEX["sweet"]),
        "band_hot": _band(HEX["rubber"], HEX["hot"]),
        "screw": _screw(),
        "oil_cap": lambda x, y: rgb("#3F6B45"),
    }
    pixels = [0.0] * (ATLAS_PX * ATLAS_PX * 4)
    for name, (cx, cy) in CELLS.items():
        fn = tiles[name]
        for ty in range(CELL_PX):
            # Blender guarda las filas de abajo arriba: la fila ty de la celda (desde arriba) es
            # la fila (cy + 1) * CELL_PX - 1 - ty del atlas.
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


# --- Utilidades de malla ----------------------------------------------------------------------


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
        bm = self.bm
        before = set(bm.faces)
        v = [bm.verts.new(P(x, y, z)) for y in (y0, y1) for (x, z) in ((x0, z0), (x1, z0), (x1, z1), (x0, z1))]
        for idx in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            bm.faces.new([v[i] for i in idx])
        if bevel > 0.0:
            edges = list({e for f in set(bm.faces) - before for e in f.edges})
            bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5,
                            clamp_overlap=True)
        self.tag(set(bm.faces) - before, mat)

    def lathe(self, cx, cz, profile, mats, segs=SEGS, phase=0.0, squircle=0.0):
        """Sólido de revolución cerrado (eje Y de Godot). `profile` = [(r, y)], de abajo arriba;
        r = 0 es polo. `mats[i]` es el material del tramo profile[i] → profile[i + 1].
        `squircle` = n > 0 deforma la sección en un cuadrado redondeado (|x|ⁿ + |z|ⁿ = rⁿ)."""
        bm = self.bm
        rings = []
        for r, y in profile:
            if r < 1e-6:
                rings.append([bm.verts.new(P(cx, y, cz))])
            else:
                ring = []
                for k in range(segs):
                    a = phase + 2 * math.pi * k / segs
                    c, s_ = math.cos(a), math.sin(a)
                    f = (abs(c) ** squircle + abs(s_) ** squircle) ** (-1.0 / squircle) if squircle else 1.0
                    ring.append(bm.verts.new(P(cx + r * f * c, y, cz + r * f * s_)))
                rings.append(ring)
        for i in range(len(rings) - 1):
            a, b = rings[i], rings[i + 1]
            faces = []
            for k in range(segs):
                k1 = (k + 1) % segs
                if len(a) == 1:
                    f = (a[0], b[k1], b[k])
                elif len(b) == 1:
                    f = (a[k], a[k1], b[0])
                else:
                    f = (a[k], a[k1], b[k1], b[k])
                faces.append(bm.faces.new(f))
            self.tag(faces, mats[i])

    def prism(self, p0, p1, half, mat):
        """Barra de sección cuadrada entre dos puntos de Godot (pico de la aceitera)."""
        from mathutils import Vector
        bm = self.bm
        a, b = Vector(p0), Vector(p1)
        axis = (b - a).normalized()
        side = axis.cross(Vector((0, 0, 1))).normalized() * half
        up = side.cross(axis).normalized() * half
        corners = [side + up, -side + up, -side - up, side - up]
        va = [bm.verts.new(P(*(a + c))) for c in corners]
        vb = [bm.verts.new(P(*(b + c))) for c in corners]
        faces = [bm.faces.new(va), bm.faces.new(list(reversed(vb)))]
        for k in range(4):
            k1 = (k + 1) % 4
            faces.append(bm.faces.new((va[k], va[k1], vb[k1], vb[k])))
        self.tag(faces, mat)

    def finish(self, name, parent, coll, smooth_deg=0.0):
        """UV: caja a 2 m por unidad en la biblioteca; en el atlas, cada cara llena su celda
        (etiquetas) o cae en el centro de la suya (colores lisos)."""
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
            # Etiquetas: la cara entera en la celda (con 2 px de margen); lisos: el 40 % central.
            lo, hi = (2 / CELL_PX, 1 - 2 / CELL_PX) if cell_name not in SOLID else (0.3, 0.7)
            # Caras laterales: «arriba» de la etiqueta es Z de Blender; sin espejo vista de frente.
            mirror = (ax == 0 and n[0] < 0) or (ax == 1 and n[1] > 0)
            for loop, (u, v) in zip(face.loops, pts):
                fu, fv = (u - min(us)) / du, (v - min(vs)) / dv
                if mirror:
                    fu = 1.0 - fu
                loop[uv].uv = ((cx + lo + fu * (hi - lo)) / 4, (cy + lo + fv * (hi - lo)) / 4)
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


def root_empty(name, coll):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "PLAIN_AXES"
    coll.objects.link(ob)
    return ob


# --- Mostrador --------------------------------------------------------------------------------


def build_counter(b):
    top, front, mid = "mat_steel_brushed_top", "mat_steel_brushed", "mat_steel_brushed_mid"
    # Tablero con vuelo a los dos lados y canto chaflanado (Z1: limpio).
    b.box(-2.02, 2.02, 1.04, TOP_Y, -0.56, 0.56, top, bevel=0.02)
    # Faldón con los frentes de cajón (Z2) a los dos lados.
    b.box(-1.98, 1.98, 0.76, 1.04, 0.44, 0.50, front, bevel=0.012)
    b.box(-1.98, 1.98, 0.76, 1.04, -0.50, -0.44, mid, bevel=0.012)
    # Patas cuadradas y balda inferior.
    for x in (-1.93, -0.64, 0.64, 1.93):
        for z in (-0.46, 0.46):
            b.box(x - 0.03, x + 0.03, 0.0, 0.76, z - 0.03, z + 0.03, mid, bevel=0.008)
            b.box(x - 0.035, x + 0.035, 0.0, 0.03, z - 0.035, z + 0.035, "mat_rubber")  # pie
    b.box(-1.96, 1.96, 0.12, 0.16, -0.49, 0.49, mid, bevel=0.01)
    # Fondo central: cierra el hueco y da sombra (la cara −Z nunca se ve desde la cámara).
    b.box(-1.90, 1.90, 0.16, 0.76, -0.015, 0.015, mid)
    # Cajas de cartón en la balda, lado de condimentar (Z2; sin colisión propia).
    for x0, x1, h, z0 in ((-1.78, -1.20, 0.34, 0.06), (-1.10, -0.70, 0.24, 0.10), (0.12, 0.74, 0.38, 0.04),
                          (0.84, 1.20, 0.22, 0.12), (1.36, 1.82, 0.30, 0.08)):
        b.box(x0, x1, 0.16, 0.16 + h, z0, 0.42, "mat_cardboard", bevel=0.01)
    # Etiquetas de color bajo cada recipiente (§2.5, referencia: frente de la barra).
    labels = [(x, "lbl_" + key) for (_, x), key in zip(DISPENSERS, ("sweet", "hot", "salt", "oil"))]
    labels.append((BOWL_X, "lbl_cachelos"))
    for x, cell in labels:
        x = max(-1.75, min(1.75, x))  # las de los extremos no se salen de la esquina
        b.box(x - 0.17, x + 0.17, 0.80, 1.00, 0.50, 0.508, "@" + cell)
    # Tornillos del faldón (≥ 0,07 m: se leen a 1080p, §6.1-2).
    for x in (-1.93, -0.64, 0.64, 1.93):
        b.box(x - 0.035, x + 0.035, 0.865, 0.935, 0.50, 0.505, "@screw")


def build_tray(b):
    """Bandeja de apoyo de acero oscuro: la caja apoya a y = TRAY_TOP; reborde claro."""
    x0, x1 = TRAY_X - TRAY_W / 2, TRAY_X + TRAY_W / 2
    z0, z1 = TRAY_Z - TRAY_D / 2, TRAY_Z + TRAY_D / 2
    b.box(x0 + 0.03, x1 - 0.03, TOP_Y - 0.01, TRAY_TOP, z0 + 0.03, z1 - 0.03, "mat_steel_dark")
    rim, hi = 0.03, TRAY_TOP + 0.02
    light = "mat_steel_brushed"
    b.box(x0, x1, TOP_Y - 0.01, hi, z0, z0 + rim, light, bevel=0.008)
    b.box(x0, x1, TOP_Y - 0.01, hi, z1 - rim, z1, light, bevel=0.008)
    b.box(x0, x0 + rim, TOP_Y - 0.01, hi, z0 + rim, z1 - rim, light, bevel=0.008)
    b.box(x1 - rim, x1, TOP_Y - 0.01, hi, z0 + rim, z1 - rim, light, bevel=0.008)


def build_board(b):
    """Tabla de corte con cuchillo en la franja trasera (Z1: z ≤ −0,28, ≥ 0,15 m de las anclas)."""
    b.box(-1.12, -0.68, TOP_Y, TOP_Y + 0.03, -0.52, -0.30, "mat_wood_used", bevel=0.008)
    b.box(-1.06, -0.82, TOP_Y + 0.03, TOP_Y + 0.036, -0.43, -0.395, "mat_steel_brushed")  # hoja
    b.box(-0.82, -0.70, TOP_Y + 0.03, TOP_Y + 0.052, -0.432, -0.393, "mat_wood_dark", bevel=0.005)


# --- Recipientes (origen en la base, encima del tablero) -------------------------------------


# Perfiles sin escalones hacia fuera: el contorno de resaltado (inverted hull que crece radial desde
# el origen, `highlight_outline`) dibujaría una raya sobre el cuerpo en cada cornisa que mira abajo.
# Por eso las fajas van a ras y los recipientes se estrechan (o siguen rectos) hacia arriba.


def build_sweet(b):
    """Lata redonda de pimentón dulce, abierta, con el polvo asomando."""
    b.lathe(0.0, 0.0, [
        (0.0, 0.0), (0.12, 0.0), (0.12, 0.05), (0.12, 0.13), (0.12, 0.152), (0.12, 0.172), (0.106, 0.18),
        (0.07, 0.202), (0.0, 0.214),
    ], ["@sweet", "@sweet", "@band_sweet", "@sweet", "mat_steel_brushed", "mat_steel_brushed",
        "@powder_sweet", "@powder_sweet"])


def build_hot(b):
    """Lata de sección cuadrada redondeada y más alta, de pimentón picante, faja negra: otra
    silueta, no solo otro tono."""
    b.lathe(0.0, 0.0, [
        (0.0, 0.0), (0.105, 0.0), (0.105, 0.06), (0.105, 0.15), (0.105, 0.19), (0.105, 0.212),
        (0.09, 0.218), (0.05, 0.234), (0.0, 0.24),
    ], ["@hot", "@hot", "@band_hot", "@hot", "mat_steel_brushed", "mat_steel_brushed",
        "@powder_hot", "@powder_hot"], segs=20, squircle=4.0)


def build_salt(b):
    """Salero de barro (orza baja que se estrecha hacia la boca) con sal gorda en montón y granos
    grandes (≥ 0,03 m)."""
    b.lathe(0.0, 0.0, [
        (0.0, 0.0), (0.145, 0.0), (0.15, 0.03), (0.145, 0.08), (0.13, 0.11), (0.122, 0.118),
        (0.10, 0.15), (0.0, 0.165),
    ], ["mat_clay"] * 5 + ["@salt_grain"] * 2)
    for x, y, z in ((-0.05, 0.13, 0.03), (0.04, 0.132, 0.05), (0.03, 0.14, -0.04), (-0.02, 0.146, -0.01),
                    (0.07, 0.122, -0.01), (-0.07, 0.12, -0.04)):
        b.box(x - 0.017, x + 0.017, y, y + 0.03, z - 0.017, z + 0.017, "@salt_grain", bevel=0.005)


def build_oil(b):
    """Aceitera de lata esmaltada en amarillo aceite, hombro y pico de acero, asa de goma."""
    b.lathe(0.0, 0.0, [
        (0.0, 0.0), (0.12, 0.0), (0.12, 0.11), (0.112, 0.12), (0.07, 0.155), (0.042, 0.165),
        (0.042, 0.19), (0.042, 0.205), (0.0, 0.214),
    ], ["@oil", "@oil", "@oil", "mat_steel_brushed", "mat_steel_brushed", "mat_steel_brushed", "@oil_cap",
        "@oil_cap"])
    b.prism((0.06, 0.10, 0.0), (0.19, 0.225, 0.0), 0.012, "mat_steel_brushed")
    b.box(-0.165, -0.142, 0.03, 0.15, -0.014, 0.014, "mat_rubber", bevel=0.004)
    b.box(-0.142, -0.105, 0.03, 0.052, -0.014, 0.014, "mat_rubber")
    b.box(-0.142, -0.08, 0.128, 0.15, -0.014, 0.014, "mat_rubber")


def build_bowl(b):
    """Cunca de barro honda (mismo perfil que la v1: el `OutlineHull` de la escena sigue valiendo)."""
    b.lathe(0.0, 0.0, [
        (0.0, 0.0), (0.16, 0.0), (0.172, 0.012), (0.245, 0.14), (0.25, 0.16), (0.218, 0.162),
        (0.20, 0.10), (0.13, 0.072), (0.0, 0.07),
    ], ["mat_clay"] * 8, segs=20)


# --- Montaje ----------------------------------------------------------------------------------


def build_all():
    build_atlas_mat = atlas_material(build_atlas())
    assert build_atlas_mat.name == ATLAS
    station_coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("seasoning_station") or bpy.data.objects["asset"]
    root.name = "seasoning_station"
    b = Builder()
    build_counter(b)
    b.finish("counter", root, station_coll)
    b = Builder()
    build_tray(b)
    b.finish("tray", root, station_coll)
    b = Builder()
    build_board(b)
    b.finish("cutting_board", root, station_coll)
    front = bpy.data.objects["Anchor_Front"]
    front.location = P(0.0, 0.0, -0.56)
    empty("Anchor_Tray", P(TRAY_X, TRAY_TOP, TRAY_Z), root, station_coll)
    for name, x in DISPENSERS:
        empty("Anchor_Dispenser_" + name, P(x, TOP_Y, DISPENSER_Z), root, station_coll)
    empty("Anchor_Bowl", P(BOWL_X, TOP_Y, 0.0), root, station_coll)
    empty("Anchor_PassSide", P(0.0, 0.0, -1.2), root, station_coll)
    empty("Anchor_OperatorSide", P(0.0, 0.0, 1.2), root, station_coll)

    disp_coll = collection("export_dispenser")
    disp = root_empty("seasoning_dispenser", disp_coll)
    for name, fn in (("paprika_sweet", build_sweet), ("paprika_hot", build_hot), ("salt", build_salt),
                     ("oil", build_oil)):
        b = Builder()
        fn(b)
        b.finish(name, disp, disp_coll, smooth_deg=40.0)
    empty("Anchor_Front_dispenser", P(0.0, 0.0, -0.15), disp, disp_coll)

    bowl_coll = collection("export_bowl")
    bowl = root_empty("cachelos_bowl", bowl_coll)
    b = Builder()
    build_bowl(b)
    b.finish("bowl", bowl, bowl_coll, smooth_deg=40.0)
    empty("Anchor_Portions", P(0.0, 0.07, 0.0), bowl, bowl_coll)
    empty("Anchor_Front_bowl", P(0.0, 0.0, -0.25), bowl, bowl_coll)
    return root
