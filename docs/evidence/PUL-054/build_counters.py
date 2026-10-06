"""Geometría de art/blender/counters.blend (PUL-054), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-054/build_counters.py").read(), ns); ns["build_all"]()

Kit modular en cuadrícula de 1 m (art-bible §2.1, §4; planta B de docs/design/level-layouts.md).
Una raíz por colección; cada una se exporta a su `.glb` hermano en
godot/assets/models/furniture/counters/ (ver `export_counters.sh`):

- Encimera perimetral (tablero a y = 1,00, fondo 1 m = la celda): `counter_1m`, `counter_2m`,
  `counter_3m`, `counter_half` (0,5 m, para el remate de 1,5 m junto a la nevera), `counter_corner`
  (1 × 1 con listones en el frente y los dos lados) y `counter_end` (1 m con costados oscuros en los
  dos extremos: vale de remate por cualquier lado).
- Pasaplatos (mesa a dos caras, tablero a y = 1,10, la altura del `Anchor` de los `Slot` y del
  mostrador de la estación de condimentos de PUL-052): `pass_1m`, `pass_2m`, `pass_3m` y
  `pass_end`. Mismo lenguaje que el mostrador de PUL-052 (zócalo y listones `wood_dark`, cuerpo
  `wood_mid`, tablero `wood_light` con vuelo a los dos lados, banda `canvas_stripe` en el lado de
  la cocina) y una tabla `wood_mid` embutida en el centro de cada metro: el sitio de cada `Slot`.
- Barrera baja del público (0,6 m, fondo 1 m): `rail_1m`, cuerpo `canvas_cream` con banda
  `canvas_stripe` a las dos caras; la escena la repite o la estira en X para los tramos impares.

Origen en el centro de la base; frente (−Z de Godot, +Y de Blender) = lado largo de servicio.
Coordenadas escritas en ejes de Godot (X derecha, Y arriba, Z hacia la cámara) y convertidas a
Blender con `P()`. Se versiona como registro reproducible.
"""

import bmesh
import bpy

M = bpy.data.materials

COUNTER_TOP = 1.00
PASS_TOP = 1.10
RAIL_TOP = 0.60
BATTEN = 0.03

COUNTER_MATS = ("mat_wood_mid", "mat_wood_light", "mat_wood_dark")
PASS_MATS = ("mat_wood_mid", "mat_wood_light", "mat_wood_dark", "mat_canvas_stripe")
RAIL_MATS = ("mat_canvas_cream", "mat_wood_mid", "mat_wood_dark", "mat_canvas_stripe")
WOOD_MID, WOOD_LIGHT, WOOD_DARK, STRIPE = 0, 1, 2, 3


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


def box(bm, x0, x1, y0, y1, z0, z1, mat, bottom=False):
    """Caja alineada a los ejes, en coordenadas de Godot. Sin cara inferior (no se ve), salvo `bottom`."""
    v = [bm.verts.new(P(x, y, z)) for y in (y0, y1) for (x, z) in ((x0, z0), (x1, z0), (x1, z1), (x0, z1))]
    faces = [(4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    if bottom:
        faces.append((0, 3, 2, 1))
    for idx in faces:
        bm.faces.new([v[i] for i in idx]).material_index = mat


def batten_xs(length):
    """Listones verticales: uno en cada extremo del módulo y uno por metro intermedio."""
    h = length / 2
    xs = [-h + 0.03, h - 0.03 - BATTEN]
    xs += [-h + k - BATTEN / 2 for k in range(1, int(round(length)))]
    return xs


# --- Encimera perimetral (tablero a 1,00) ---------------------------------------------------


def build_counter(length, sides=False, ends=False):
    """`sides`: listones y moldura también en los costados (esquina). `ends`: costados oscuros (extremo)."""
    h = length / 2
    top = COUNTER_TOP

    def fill(bm):
        box(bm, -h + 0.05, h - 0.05, 0.0, 0.06, -0.45, 0.47, WOOD_DARK)  # zócalo
        box(bm, -h + 0.03, h - 0.03, 0.06, top - 0.08, -0.44, 0.5, WOOD_MID)  # cuerpo
        box(bm, -h + 0.02, h - 0.02, top - 0.08, top, -0.5, 0.5, WOOD_LIGHT)  # tablero, vuelo al frente
        box(bm, -h + 0.03, h - 0.03, top - 0.16, top - 0.12, -0.455, -0.44, WOOD_DARK)  # moldura
        for x in batten_xs(length):
            box(bm, x, x + BATTEN, 0.06, top - 0.08, -0.455, -0.44, WOOD_DARK)
        for s in (-1, 1):
            xo = s * (h - 0.03)  # cara del costado
            xa, xb = (xo, xo + s * 0.015) if s > 0 else (xo + s * 0.015, xo)
            if sides:
                box(bm, xa, xb, top - 0.16, top - 0.12, -0.44, 0.5, WOOD_DARK)
                for z in (-0.44 + 0.03, 0.5 - 0.06):
                    box(bm, xa, xb, 0.06, top - 0.08, z, z + BATTEN, WOOD_DARK)
            if ends:
                box(bm, xa, xb, 0.03, top - 0.08, -0.455, 0.5, WOOD_DARK)  # costado de remate

    return fill


# --- Pasaplatos (mesa a dos caras, tablero a 1,10) ------------------------------------------


def build_pass(length, ends=False):
    h = length / 2
    top = PASS_TOP

    def fill(bm):
        box(bm, -h + 0.05, h - 0.05, 0.0, 0.06, -0.47, 0.47, WOOD_DARK)  # zócalo
        box(bm, -h + 0.03, h - 0.03, 0.06, top - 0.08, -0.5, 0.5, WOOD_MID)  # cuerpo
        box(bm, -h + 0.02, h - 0.02, top - 0.08, top, -0.56, 0.56, WOOD_LIGHT)  # tablero con vuelo a los dos lados
        for z0, z1 in ((-0.515, -0.5), (0.5, 0.515)):
            box(bm, -h + 0.03, h - 0.03, top - 0.16, top - 0.12, z0, z1, WOOD_DARK)  # moldura
            for x in batten_xs(length):
                box(bm, x, x + BATTEN, 0.06, top - 0.08, z0, z1, WOOD_DARK)
        # Lado de la cocina (frente, −Z): la banda roja de feria del mostrador de PUL-052, continua.
        box(bm, -h + 0.03, h - 0.03, 0.55, 0.65, -0.52, -0.515, STRIPE)
        # Una tabla embutida por metro: el sitio de cada Slot (la caja apoya en y = 1,10).
        for k in range(int(round(length))):
            cx = -h + 0.5 + k
            box(bm, cx - 0.27, cx + 0.27, top, top + 0.003, -0.27, 0.27, WOOD_MID)
        if ends:
            for s in (-1, 1):
                xo = s * (h - 0.03)
                xa, xb = (xo, xo + s * 0.015) if s > 0 else (xo + s * 0.015, xo)
                box(bm, xa, xb, 0.03, top - 0.08, -0.515, 0.515, WOOD_DARK)

    return fill


# --- Barrera baja del público (0,6 m) -------------------------------------------------------


def build_rail(bm):
    # 0 canvas_cream, 1 wood_mid, 2 wood_dark, 3 canvas_stripe
    top = RAIL_TOP
    box(bm, -0.47, 0.47, 0.0, 0.06, -0.42, 0.42, 2)  # zócalo
    box(bm, -0.48, 0.48, 0.06, top - 0.06, -0.44, 0.44, 0)  # faldón de lona
    box(bm, -0.5, 0.5, top - 0.06, top, -0.5, 0.5, 1)  # tablero
    for z0, z1 in ((-0.445, -0.44), (0.44, 0.445)):
        box(bm, -0.48, 0.48, 0.22, 0.34, z0, z1, 3)  # banda roja a las dos caras
    for x in (-0.48, 0.44):
        box(bm, x, x + 0.04, 0.0, top - 0.06, -0.46, 0.46, 2)  # postes de las esquinas


# --- Montaje ---------------------------------------------------------------------------------

PIECES = (
    # nombre, materiales, relleno, longitud (para el Anchor_Front)
    ("counter_1m", COUNTER_MATS, build_counter(1.0), 0.5),
    ("counter_2m", COUNTER_MATS, build_counter(2.0), 0.5),
    ("counter_3m", COUNTER_MATS, build_counter(3.0), 0.5),
    ("counter_half", COUNTER_MATS, build_counter(0.5), 0.5),
    ("counter_corner", COUNTER_MATS, build_counter(1.0, sides=True), 0.5),
    ("counter_end", COUNTER_MATS, build_counter(1.0, ends=True), 0.5),
    ("pass_1m", PASS_MATS, build_pass(1.0), 0.56),
    ("pass_2m", PASS_MATS, build_pass(2.0), 0.56),
    ("pass_3m", PASS_MATS, build_pass(3.0), 0.56),
    ("pass_end", PASS_MATS, build_pass(1.0, ends=True), 0.56),
    ("rail_1m", RAIL_MATS, build_rail, 0.5),
)


def root_empty(name, coll):
    remove_object(name)
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = "PLAIN_AXES"
    coll.objects.link(ob)
    return ob


def build_all():
    """La primera pieza usa la colección `export` de la plantilla (raíz `asset`, `Anchor_Front`);
    las demás, `export_<pieza>` con `Anchor_Front_<pieza>`. Todas las raíces quedan en el origen (el
    exportador exige transformaciones nulas); `layout_preview()` las separa solo para el render."""
    first = PIECES[0][0]
    for i, (name, mats, fill, front_z) in enumerate(PIECES):
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
        mesh_object(name + "_body", mats, root, coll, fill)
    return first


def layout_preview(spacing=1.6):
    """Solo para el render de revisión: separa las raíces en fila (no se guarda en el .blend)."""
    x = 0.0
    for name, _, _, _ in PIECES:
        ob = bpy.data.objects[name]
        length = {"counter_2m": 2, "counter_3m": 3, "pass_2m": 2, "pass_3m": 3, "counter_half": 0.5}.get(name, 1)
        ob.location = (x + length / 2, 0.0, 0.0)
        x += length + spacing - 1.0
