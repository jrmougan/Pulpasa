"""Geometría v2 de art/blender/counters.blend (PUL-084), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre una copia de art/blender/_template.blend (materiales v2 enlazados):
    ns = {}; exec(open("docs/evidence/PUL-084/build_counters.py").read(), ns); ns["build_all"]()

Estética v2 (art-bible v2 §1, §3, §5, §8; materials-v2.md): el kit de PUL-054 rehecho en acero
inoxidable con las mismas piezas, nombres, huellas y alturas (encimera a 1,00, pasaplatos a 1,10,
barrera a 0,60), así `kitchen_layout.tscn` no cambia de montaje:
- Tablero `mat_steel_brushed_top` limpio (Z1) con canto frontal `mat_steel_brushed` y tornillos.
- Frente (Z2) por módulos de 1 m: fila de cajones `mat_steel_brushed` con tirador `mat_steel_dark`
  y, debajo, alternando, puertas con rejilla de ventilación o balda abierta con cajas
  `mat_cardboard`; cuerpo, patas y balda `mat_steel_brushed_mid`, pies de goma.
- Pasaplatos: igual por las dos caras (la cámara del nivel ve la de servicio, +Z) y un marco fino
  `mat_steel_dark` en el tablero en el centro de cada metro: el sitio de cada `Slot`.
- Barrera del público: mueble bajo de acero (se estira en X en la escena: sin detalles que deformen).
Piezas nuevas:
- `drain_grate`: rejilla de desagüe para el suelo (Z0, relieve 1 cm sobre el suelo, la canaleta va
  enterrada). Patrón de la rejilla en el atlas.
- `counter_props_board` y `counter_props_crock`: atrezo de la franja trasera del tablero (Z1,
  ≤ 0,25 m de alto, fondo ≤ 0,25 m): tabla de corte con cuchillo y cuenco de barro; bote de
  utensilios de acero con cucharón, espumadera y pinzas, y jarra de barro. Nada que imite comida ni
  condimento (§5, regla 1). La escena los coloca solo en encimeras sin `Slot`.

Atlas propio `counters_atlas` (256², empaquetado, art-bible §3.3): mitad superior, la rejilla
(1,2 m × 0,3 m → 213 px/m en X); mitad inferior, tornillo y rejilla de ventilación.
Origen en el centro de la base; frente (−Z de Godot, +Y de Blender) = lado largo de servicio.
Coordenadas en ejes de Godot (X derecha, Y arriba, Z hacia la cámara) convertidas con `P()`.
"""

import math

import bmesh
import bpy

M = bpy.data.materials

COUNTER_TOP = 1.00
PASS_TOP = 1.10
RAIL_TOP = 0.60
UV_M = 2.0  # 1 unidad de UV = 2 m (materials-v2.md §2)
SEGS = 12

TOP, LIGHT, MID, DARK = "mat_steel_brushed_top", "mat_steel_brushed", "mat_steel_brushed_mid", "mat_steel_dark"
BOX, RUBBER, WOOD, WOOD_DARK, CLAY = "mat_cardboard", "mat_rubber", "mat_wood_used", "mat_wood_dark", "mat_clay"

# --- Atlas propio (256²) ----------------------------------------------------------------------

ATLAS = "counters_atlas"
ATLAS_PX = 256
# Celdas: rectángulo (u0, v0, u1, v1) en UV (v hacia arriba, como Blender).
CELLS = {
    "grate": (0.0, 0.5, 1.0, 1.0),
    "screw": (0.0, 0.0, 0.5, 0.5),
    "vent": (0.5, 0.0, 1.0, 0.5),
}
HEX = {
    "grate": "#45484A",
    "slot": "#1E2021",
    "frame": "#3A3D3F",
    "screw": "#8E969C",
    "screw_slot": "#2B2E30",
    "vent": "#7D868D",
    "vent_slot": "#2E3236",
}


def rgb(hex_str):
    h = hex_str.lstrip("#")
    return tuple((int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def _grate(x, y):
    """256 × 128 px para 1,2 × 0,3 m: marco de 8 px y ranuras de 10 px cada 20 px (≥ 4 px a 1080p)."""
    w, h = 256, 128
    if x < 8 or x >= w - 8 or y < 10 or y >= h - 10:
        return rgb(HEX["frame"])
    if (x - 8) % 20 >= 10:
        return rgb(HEX["slot"])
    return rgb(HEX["grate"])


def _screw(x, y):
    """Cabeza redonda con ranura sobre fondo del frente (`steel_light`)."""
    dx, dy = x - 64, y - 64
    r = math.hypot(dx, dy)
    if r > 46:
        return rgb("#B9BEC2")
    if abs(dy - dx) < 9 and r < 40:
        return rgb(HEX["screw_slot"])
    return rgb(HEX["screw"]) if r < 40 else rgb(HEX["screw_slot"])


def _vent(x, y):
    """Rejilla de ventilación de puerta: cinco lamas oscuras de 12 px sobre `steel_mid`."""
    if 10 <= x < 118 and 14 <= y < 114 and (y - 14) % 20 < 12:
        return rgb(HEX["vent_slot"])
    return rgb(HEX["vent"])


def build_atlas():
    """Atlas de color (albedo sRGB), determinista, empaquetado en el .blend. Python puro."""
    pixels = [0.0] * (ATLAS_PX * ATLAS_PX * 4)

    def put(px0, py0, w, h, fn):
        for ty in range(h):
            row = py0 + h - 1 - ty  # Blender guarda las filas de abajo arriba
            for tx in range(w):
                i = (row * ATLAS_PX + px0 + tx) * 4
                pixels[i:i + 4] = (*fn(tx, ty), 1.0)

    put(0, 128, 256, 128, _grate)
    put(0, 0, 128, 128, _screw)
    put(128, 0, 128, 128, _vent)
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

    def tag(self, faces, mat):
        name = ATLAS if mat.startswith("@") else mat
        if name not in self.mats:
            self.mats.append(name)
        idx = self.mats.index(name)
        cell = list(CELLS).index(mat[1:]) if mat.startswith("@") else -1
        for f in faces:
            f.material_index = idx
            f[self.cell] = cell

    def box(self, x0, x1, y0, y1, z0, z1, mat, bevel=0.0, bottom=False):
        """Caja alineada a los ejes de Godot, sin cara inferior salvo `bottom` (no se ve);
        `bevel` chaflana todas las aristas (art-bible §1.1)."""
        bm = self.bm
        before = set(bm.faces)
        v = [bm.verts.new(P(x, y, z)) for y in (y0, y1) for (x, z) in ((x0, z0), (x1, z0), (x1, z1), (x0, z1))]
        faces = [(4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        if bottom or bevel > 0.0:
            faces.append((0, 3, 2, 1))
        for idx in faces:
            bm.faces.new([v[i] for i in idx])
        if bevel > 0.0:
            edges = list({e for f in set(bm.faces) - before for e in f.edges})
            bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5,
                            clamp_overlap=True)
            if not bottom:  # la cara de abajo solo hacía falta para biselar; fuera
                low = [f for f in set(bm.faces) - before
                       if f.normal.z < -0.99 and all(abs(l.vert.co.z - y0) < 1e-5 for l in f.loops)]
                bmesh.ops.delete(bm, geom=low, context="FACES_ONLY")
        self.tag(set(bm.faces) - before, mat)

    def quad_front(self, x0, x1, y0, y1, z, mat):
        """Placa vertical mirando a −Z (frente) en el plano z."""
        bm = self.bm
        f = bm.faces.new([bm.verts.new(P(x, y, z)) for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))])
        self.tag([f], mat)

    def quad_up(self, x0, x1, z0, z1, y, mat):
        bm = self.bm
        f = bm.faces.new([bm.verts.new(P(x, y, z)) for x, z in ((x0, z1), (x1, z1), (x1, z0), (x0, z0))])
        self.tag([f], mat)

    def lathe(self, cx, cz, profile, mat, segs=SEGS):
        """Sólido de revolución (eje Y de Godot). `profile` = [(r, y)] de abajo arriba; r = 0 es polo."""
        bm = self.bm
        rings = []
        for r, y in profile:
            if r < 1e-6:
                rings.append([bm.verts.new(P(cx, y, cz))])
            else:
                rings.append([bm.verts.new(P(cx + r * math.cos(2 * math.pi * k / segs), y,
                                             cz + r * math.sin(2 * math.pi * k / segs))) for k in range(segs)])
        faces = []
        for i in range(len(rings) - 1):
            a, b = rings[i], rings[i + 1]
            for k in range(segs):
                k1 = (k + 1) % segs
                if len(a) == 1:
                    faces.append(bm.faces.new((a[0], b[k1], b[k])))
                elif len(b) == 1:
                    faces.append(bm.faces.new((a[k], a[k1], b[0])))
                else:
                    faces.append(bm.faces.new((a[k], a[k1], b[k1], b[k])))
        self.tag(faces, mat)

    def finish(self, name, parent, coll, smooth_deg=0.0):
        """UV: caja a 2 m por unidad en la biblioteca; en el atlas, cada cara llena su celda."""
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        uv = bm.loops.layers.uv.verify()
        names = list(CELLS)
        for face in bm.faces:
            n = face.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            pts = [((l.vert.co.y, l.vert.co.z), (l.vert.co.x, l.vert.co.z), (l.vert.co.x, l.vert.co.y))[ax]
                   for l in face.loops]
            if face[self.cell] < 0:
                for loop, (u, v) in zip(face.loops, pts):
                    loop[uv].uv = (u / UV_M, v / UV_M)
                continue
            u0, v0, u1, v1 = CELLS[names[face[self.cell]]]
            us, vs = [p[0] for p in pts], [p[1] for p in pts]
            du, dv = max(us) - min(us) or 1.0, max(vs) - min(vs) or 1.0
            mirror = (ax == 0 and n[0] < 0) or (ax == 1 and n[1] > 0)
            for loop, (u, v) in zip(face.loops, pts):
                fu, fv = (u - min(us)) / du, (v - min(vs)) / dv
                if mirror:
                    fu = 1.0 - fu
                loop[uv].uv = (u0 + (0.01 + 0.98 * fu) * (u1 - u0), v0 + (0.01 + 0.98 * fv) * (v1 - v0))
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


# --- Frentes (Z2) ----------------------------------------------------------------------------


def bays(length):
    """Tramos de frente: uno por metro (o uno de 0,5 m)."""
    h = length / 2
    n = max(1, int(round(length)))
    w = length / n
    return [(-h + k * w, -h + (k + 1) * w) for k in range(n)]


def drawer_row(b, x0, x1, y0, y1, z, side):
    """Fila de cajones sobre el plano z (side = −1 mira a −Z, +1 a +Z): frente claro y tirador oscuro."""
    n = 2 if x1 - x0 > 0.7 else 1
    w = (x1 - x0) / n
    for k in range(n):
        a, c = x0 + k * w + 0.02, x0 + (k + 1) * w - 0.02
        za, zb = sorted((z, z + side * 0.018))
        b.box(a, c, y0 + 0.015, y1 - 0.015, za, zb, LIGHT, bevel=0.006)
        m = (a + c) / 2
        zc, zd = sorted((z + side * 0.018, z + side * 0.04))
        b.box(m - 0.10, m + 0.10, (y0 + y1) / 2 - 0.012, (y0 + y1) / 2 + 0.012, zc, zd, DARK)


def door_pair(b, x0, x1, y0, y1, z, side):
    """Dos puertas con rejilla de ventilación abajo y tiradores verticales junto al centro."""
    m = (x0 + x1) / 2
    for a, c, hx in ((x0 + 0.02, m - 0.006, m - 0.06), (m + 0.006, x1 - 0.02, m + 0.045)):
        za, zb = sorted((z, z + side * 0.018))
        b.box(a, c, y0 + 0.015, y1 - 0.015, za, zb, LIGHT, bevel=0.006)
        vz = z + side * 0.0185
        if side < 0:
            b.quad_front(a + 0.06, c - 0.06, y0 + 0.06, y0 + 0.20, vz, "@vent")
        else:
            bm = b.bm
            f = bm.faces.new([bm.verts.new(P(x, y, vz)) for x, y in
                              ((c - 0.06, y0 + 0.06), (a + 0.06, y0 + 0.06), (a + 0.06, y0 + 0.20),
                               (c - 0.06, y0 + 0.20))])
            b.tag([f], "@vent")
        zc, zd = sorted((z + side * 0.018, z + side * 0.04))
        b.box(hx, hx + 0.015, (y0 + y1) / 2 - 0.09, (y0 + y1) / 2 + 0.09, zc, zd, DARK)


def open_shelf_boxes(b, x0, x1, y, z_front, z_back, seed):
    """Cajas de cartón en la balda abierta (Z2): una o dos, tamaños según `seed` (determinista)."""
    w = x1 - x0
    sizes = ((0.42, 0.30), (0.30, 0.22), (0.36, 0.34), (0.26, 0.26))
    a = sizes[seed % 4]
    zf, zb = sorted((z_front, z_back))
    if w > 0.7:
        bsz = sizes[(seed + 1) % 4]
        b.box(x0 + 0.06, x0 + 0.06 + a[0], y, y + a[1], zf + 0.03, zb - 0.02, BOX, bevel=0.01)
        b.box(x1 - 0.06 - bsz[0], x1 - 0.06, y, y + bsz[1], zf + 0.06, zb - 0.02, BOX, bevel=0.01)
    else:
        b.box(x0 + 0.05, x1 - 0.05, y, y + a[1], zf + 0.03, zb - 0.02, BOX, bevel=0.01)


def front_bays(b, length, top, z, side, recess, seed0=0, lower=None):
    """Frente completo de un lado: cajones arriba y, alternando, puertas o balda abierta.
    `recess` = z del cuerpo hundido (fondo de la balda abierta)."""
    drawer_y0 = top - 0.26
    for k, (x0, x1) in enumerate(bays(length)):
        drawer_row(b, x0, x1, drawer_y0, top - 0.10, z, side)
        kind = lower[k % len(lower)] if lower else ("doors" if (k + seed0) % 2 == 0 else "open")
        if kind == "doors":
            door_pair(b, x0, x1, 0.14, drawer_y0, z, side)
        else:
            open_shelf_boxes(b, x0, x1, 0.16, z, recess, k + seed0)


def legs(b, length, z_pairs, height):
    for x in [-length / 2 + 0.04] + [-length / 2 + k for k in range(1, int(round(length)))] + [length / 2 - 0.04]:
        for z in z_pairs:
            b.box(x - 0.025, x + 0.025, 0.03, height, z - 0.025, z + 0.025, MID)
            b.box(x - 0.03, x + 0.03, 0.0, 0.03, z - 0.03, z + 0.03, RUBBER)


def screws_front(b, length, y, z, side):
    """Tornillos del canto (≥ 0,06 m, se leen a 1080p) en los extremos de cada módulo de 1 m."""
    for x0, x1 in bays(length):
        for x in (x0 + 0.07, x1 - 0.07):
            if side < 0:
                b.quad_front(x - 0.03, x + 0.03, y - 0.03, y + 0.03, z - 0.001, "@screw")
            else:
                bm = b.bm
                zz = z + 0.001
                f = bm.faces.new([bm.verts.new(P(xx, yy, zz)) for xx, yy in
                                  ((x + 0.03, y - 0.03), (x - 0.03, y - 0.03), (x - 0.03, y + 0.03),
                                   (x + 0.03, y + 0.03))])
                b.tag([f], "@screw")


def side_panel(b, x_face, s, top, z0, z1):
    """Costado cerrado de remate (s = −1 izquierdo, +1 derecho)."""
    xa, xb = sorted((x_face, x_face + s * 0.02))
    b.box(xa, xb, 0.0, top - 0.045, z0, z1, LIGHT, bevel=0.006)


# --- Encimera perimetral (tablero a 1,00) ----------------------------------------------------


def build_counter(length, sides=False, lower=None):
    """`sides`: costados cerrados en los dos extremos (esquina y extremo)."""
    def fill(b):
        h = length / 2
        top = COUNTER_TOP
        b.box(-h + 0.004, h - 0.004, top - 0.04, top, -0.5, 0.5, TOP, bevel=0.012)  # tablero
        b.box(-h + 0.004, h - 0.004, top - 0.10, top - 0.04, -0.5, -0.47, LIGHT, bevel=0.006)  # canto
        screws_front(b, length, top - 0.07, -0.5, -1)
        b.box(-h + 0.02, h - 0.02, top - 0.26, top - 0.10, -0.46, 0.48, MID)  # bloque de cajones
        b.box(-h + 0.02, h - 0.02, 0.10, top - 0.26, -0.12, 0.48, MID)  # cuerpo hundido
        b.box(-h + 0.02, h - 0.02, 0.10, 0.16, -0.46, -0.12, MID)  # balda
        legs(b, length, (-0.44, 0.44), 0.10)
        front_bays(b, length, top, -0.46, -1, -0.12, lower=lower)
        if sides:
            for s in (-1, 1):
                side_panel(b, s * (h - 0.02), s, top, -0.47, 0.5)
    return fill


# --- Pasaplatos (mesa a dos caras, tablero a 1,10) -------------------------------------------


def build_pass(length, ends=False):
    def fill(b):
        h = length / 2
        top = PASS_TOP
        b.box(-h + 0.004, h - 0.004, top - 0.04, top, -0.56, 0.56, TOP, bevel=0.012)  # tablero, vuelo a dos caras
        for za, zb, s in ((-0.56, -0.53, -1), (0.53, 0.56, 1)):
            b.box(-h + 0.004, h - 0.004, top - 0.10, top - 0.04, za, zb, LIGHT, bevel=0.006)  # cantos
            screws_front(b, length, top - 0.07, za if s < 0 else zb, s)
        b.box(-h + 0.02, h - 0.02, top - 0.26, top - 0.10, -0.50, 0.50, MID)  # bloque de cajones
        b.box(-h + 0.02, h - 0.02, 0.10, top - 0.26, -0.03, 0.03, MID)  # tabique central
        b.box(-h + 0.02, h - 0.02, 0.10, 0.16, -0.50, 0.50, MID)  # balda
        legs(b, length, (-0.47, 0.47), 0.10)
        front_bays(b, length, top, -0.50, -1, -0.03, seed0=0)
        front_bays(b, length, top, 0.50, 1, 0.03, seed0=1)
        # Marco del sitio de cada Slot (centro de cada metro), 2 mm, sin tapar el apoyo.
        for k in range(int(round(length))):
            cx = -h + 0.5 + k
            t = 0.04
            for x0, x1, z0, z1 in ((cx - 0.30, cx + 0.30, -0.30, -0.30 + t), (cx - 0.30, cx + 0.30, 0.30 - t, 0.30),
                                   (cx - 0.30, cx - 0.30 + t, -0.30 + t, 0.30 - t),
                                   (cx + 0.30 - t, cx + 0.30, -0.30 + t, 0.30 - t)):
                b.box(x0, x1, top, top + 0.002, z0, z1, DARK)
        if ends:
            for s in (-1, 1):
                side_panel(b, s * (h - 0.02), s, top, -0.53, 0.53)
    return fill


# --- Barrera baja del público (0,6 m; se estira en X en la escena) ---------------------------


def build_rail(b):
    top = RAIL_TOP
    b.box(-0.5, 0.5, top - 0.04, top, -0.5, 0.5, TOP, bevel=0.01)
    b.box(-0.48, 0.48, 0.06, top - 0.04, -0.42, 0.42, MID)  # cuerpo
    for z in (-0.425, 0.42):
        b.box(-0.48, 0.48, 0.18, 0.22, z, z + 0.005, LIGHT)  # moldura a las dos caras
    b.box(-0.47, 0.47, 0.0, 0.06, -0.38, 0.38, DARK)  # zócalo
    for x in (-0.49, 0.45):
        b.box(x, x + 0.04, 0.0, top - 0.04, -0.47, 0.47, DARK)  # postes de las esquinas


# --- Suelo: rejilla de desagüe (Z0) ----------------------------------------------------------


def build_grate(b):
    """Canaleta enterrada de 1,2 × 0,3 m: marco a ras + 1 cm y rejilla del atlas encima."""
    b.box(-0.6, 0.6, -0.045, 0.008, -0.15, 0.15, DARK)  # 5,3 cm: el test pide ≥ 5 cm de alto
    b.quad_up(-0.585, 0.585, -0.135, 0.135, 0.0085, "@grate")


# --- Atrezo de la franja trasera (Z1) --------------------------------------------------------


def build_props_board(b):
    """Tabla de corte con cuchillo y cuenco de barro vacío. Fondo 0,24 m, alto ≤ 0,12 m."""
    b.box(-0.30, 0.16, 0.0, 0.03, -0.12, 0.12, WOOD, bevel=0.008)
    b.box(-0.22, 0.02, 0.03, 0.036, -0.03, 0.005, LIGHT)  # hoja
    b.box(0.02, 0.14, 0.03, 0.052, -0.032, 0.008, WOOD_DARK, bevel=0.005)  # mango
    b.lathe(0.30, 0.0, [(0.0, 0.0), (0.06, 0.0), (0.10, 0.06), (0.11, 0.08), (0.095, 0.08), (0.07, 0.03),
                        (0.0, 0.025)], CLAY)


def build_props_crock(b):
    """Bote de acero con cucharón, espumadera y pinzas; jarra de barro al lado. Alto ≤ 0,25 m."""
    b.lathe(-0.12, 0.0, [(0.0, 0.0), (0.08, 0.0), (0.08, 0.16), (0.072, 0.16), (0.0, 0.03)], LIGHT)
    for dx, dz, tilt, mat in ((-0.02, 0.0, -0.05, DARK), (0.02, -0.02, 0.04, LIGHT), (0.0, 0.03, 0.0, WOOD_DARK)):
        x = -0.12 + dx
        b.box(x - 0.008 + tilt, x + 0.008 + tilt, 0.10, 0.25, dz - 0.008, dz + 0.008, mat)
    b.lathe(0.12, 0.0, [(0.0, 0.0), (0.06, 0.0), (0.085, 0.08), (0.07, 0.15), (0.05, 0.18), (0.06, 0.2),
                        (0.0, 0.17)], CLAY)
    b.box(0.185, 0.205, 0.06, 0.16, -0.01, 0.01, CLAY)  # asa


# --- Montaje ----------------------------------------------------------------------------------

PIECES = (
    # nombre, relleno, z del Anchor_Front, suavizado
    ("counter_1m", build_counter(1.0), 0.5, 0.0),
    ("counter_2m", build_counter(2.0), 0.5, 0.0),
    ("counter_3m", build_counter(3.0), 0.5, 0.0),
    ("counter_half", build_counter(0.5, lower=("doors",)), 0.5, 0.0),
    ("counter_corner", build_counter(1.0, sides=True, lower=("open",)), 0.5, 0.0),
    ("counter_end", build_counter(1.0, sides=True), 0.5, 0.0),
    ("pass_1m", build_pass(1.0), 0.56, 0.0),
    ("pass_2m", build_pass(2.0), 0.56, 0.0),
    ("pass_3m", build_pass(3.0), 0.56, 0.0),
    ("pass_end", build_pass(1.0, ends=True), 0.56, 0.0),
    ("rail_1m", build_rail, 0.5, 0.0),
    ("drain_grate", build_grate, 0.15, 0.0),
    ("counter_props_board", build_props_board, 0.12, 40.0),
    ("counter_props_crock", build_props_crock, 0.1, 40.0),
)


def build_all():
    """La primera pieza usa la colección `export` de la plantilla (raíz `asset`, `Anchor_Front`);
    las demás, `export_<pieza>` con `Anchor_Front_<pieza>`. Todas las raíces en el origen."""
    atlas_material(build_atlas())
    for i, (name, fill, front_z, smooth) in enumerate(PIECES):
        if i == 0:
            coll = bpy.data.collections["export"]
            root = bpy.data.objects.get(name) or bpy.data.objects["asset"]
            root.name = name
            front = bpy.data.objects["Anchor_Front"]
            front.parent = root
            front.location = P(0.0, 0.0, -front_z)
        else:
            coll = collection("export_" + name)
            root = root_empty(name, coll)
            empty("Anchor_Front_" + name, P(0.0, 0.0, -front_z), root, coll)
        b = Builder()
        fill(b)
        b.finish(name + "_body", root, coll, smooth_deg=smooth)
    return [p[0] for p in PIECES]


def tri_counts():
    out = {}
    for name, *_ in PIECES:
        me = bpy.data.objects[name + "_body"].data
        out[name] = sum(len(p.vertices) - 2 for p in me.polygons)
    return out
