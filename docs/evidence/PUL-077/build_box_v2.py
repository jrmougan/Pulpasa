"""Bandejas v2 (PUL-077): art/blender/box.blend, generado con el MCP de Blender por CLI.

Se ejecuta dentro de Blender sobre una copia recién hecha de art/blender/_template.blend (materiales
v2 enlazados desde _materials_v2.blend) y la guarda:
    ns = {}; exec(open("docs/evidence/PUL-077/build_box_v2.py").read(), ns)
    ns["build"](atlas_dir, sticker_png)
`atlas_dir` es la salida de build_box_atlas.py y `sticker_png` el atlas de pegatinas de PUL-047
(godot/assets/models/items/box/box_box_stickers.png copiado como `box_stickers.png`, para que Godot
lo extraiga con el mismo nombre); las imágenes se empaquetan en el .blend.

Mismo contrato que PUL-047 (`box_model.gd`, `test_box_model.gd`): en la colección `export`, la raíz
`box` con `Anchor_Front` (+Y) y tres bandejas hermanas `box_small/medium/large`, cada una con su
`Anchor_Fill_<talla>` (encima del papel: ahí van las capas de `octopus_pieces.glb` y
`cachelos_pieces.glb`) y `Anchor_Sticker_<talla>_0..3` (arco en la pared de +Y); bajo `OutlineHull`, un
volumen cerrado invisible `hull_<talla>` por talla para el contorno de resaltado; el disco `sticker`
reutilizable (oculto en juego: la fila real es %BadgeRow de PUL-059). Ancho en X = diámetro de la v1
(0,34 / 0,42 / 0,49) y alto ≈ 0,10, como pide el test; base en z = 0.

Forma (art-bible v2 §6.4): plástico rojo `mat_plastic_red` con papel salvamanteles (patrón de
símbolos al 15 %, atlas), pequeña **redonda**, mediana **ovalada**, grande **rectangular con asas**;
aro fino de talla bajo el labio (azul, verde, papel); labio enrollado con roce claro; pie oscuro de
contacto; símbolo de la marca en el canto frontal-inferior del lado de la cámara (−Y, §7), lejos del
arco de pegatinas (+Y). Sin cara inferior (no la ve la cámara, §4.1).
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

# (semieje X, semieje Y, exponente de superelipse: 2 = elipse, 5 = rectángulo redondeado, asas)
SIZES = {
    "small": (0.170, 0.170, 2.0, False),
    "medium": (0.210, 0.160, 2.0, False),
    "large": (0.220, 0.190, 5.0, True),
}
SEGS = 32
# Perfil de fuera a dentro: (retranqueo respecto al contorno nominal, z, celda o None = plástico).
# Cada par consecutivo forma una banda; la celda es la de la banda que empieza en ese anillo.
PROFILE = [
    (0.030, 0.000, "foot"),  # pie de contacto
    (0.024, 0.010, None),  # pared exterior (plástico de la biblioteca, logo encima)
    (0.009, 0.062, "band"),  # aro de talla (0,016 m)
    (0.006, 0.078, None),  # vuelo bajo el labio
    (0.000, 0.084, None),  # cara exterior del labio
    (0.000, 0.098, "rim"),  # canto superior con roce claro
    (0.016, 0.098, "inner"),  # pared interior
    (0.040, 0.022, "liner_edge"),  # pliegue del papel
    (0.044, 0.024, None),  # papel: n-gono con el patrón
]
HEIGHT = 0.098
FILL_Z = 0.024
STICKER_D = 0.10
STICKER_SIDES = 16
STICKER_Z = HEIGHT - STICKER_D / 2 - 0.006
LOGO = 0.044  # lado del símbolo del canto
LOGO_Z = (0.014, 0.058)
OFFSET = 0.0015  # decal sobre la pared, contra z-fighting (§3.2)
HANDLE = (0.028, 0.130, 0.012)  # vuelo en X, ancho en Y, grosor
HANDLE_SLOT = (0.010, 0.090)  # agujero: ancho en X, largo en Y
LINER_SPAN = 0.46  # metros que cubre la región del papel en el atlas (planar)

ATLAS_PX = 512
CELL_PX = 64
CELL_ORDER = ["foot", "rim", "inner", "band_small", "band_medium", "band_large", "liner_edge", "red"]
STICKER_COLS, STICKER_ROWS = 4, 2


def cell_uv(key):
    i = CELL_ORDER.index(key)
    x, y = (i % 8) * CELL_PX + CELL_PX / 2, 256 + (i // 8) * CELL_PX + CELL_PX / 2
    return (x / ATLAS_PX, 1.0 - y / ATLAS_PX)


def liner_uv(co):
    return ((co.x / LINER_SPAN + 0.5) * 0.5, 0.5 + (co.y / LINER_SPAN + 0.5) * 0.5)


def logo_uv(s, t):
    """(s, t) ∈ [0, 1]² dentro de la región del símbolo (256..384, 0..128 px)."""
    return ((256 + 128 * s) / ATLAS_PX, 1.0 - (128 - 128 * t) / ATLAS_PX)


def outline(a, b, n, inset, t):
    c, s = math.cos(t), math.sin(t)
    ex = 2.0 / n
    return Vector((math.copysign(abs(c) ** ex, c) * (a - inset), math.copysign(abs(s) ** ex, s) * (b - inset)))


def params(a, b, n):
    """Parámetros de SEGS puntos repartidos por longitud de arco (las esquinas no se amontonan)."""
    dense = [2 * math.pi * k / 2048 for k in range(2048)]
    pts = [outline(a, b, n, 0.0, t) for t in dense]
    acc = [0.0]
    for i in range(1, len(pts) + 1):
        acc.append(acc[-1] + (pts[i % len(pts)] - pts[i - 1]).length)
    total = acc[-1]
    out, j = [], 0
    for k in range(SEGS):
        target = total * k / SEGS  # con SEGS múltiplo de 4 hay vértice en ±X y ±Y
        while acc[j + 1] < target:
            j += 1
        out.append(dense[j])
    return out


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def load_packed(name, path, colorspace):
    old = bpy.data.images.get(name)
    if old is not None:
        bpy.data.images.remove(old)
    img = bpy.data.images.load(str(path))
    img.name = name
    img.colorspace_settings.name = colorspace
    img.pack()
    return img


def atlas_material(atlas_dir):
    alb = load_packed("box_atlas_albedo", Path(atlas_dir) / "box_atlas_albedo.png", "sRGB")
    orm = load_packed("box_atlas_orm", Path(atlas_dir) / "box_atlas_orm.png", "Non-Color")
    mat = M.get("atlas_box") or M.new("atlas_box")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    ta = nt.nodes.new("ShaderNodeTexImage")
    ta.image = alb
    to = nt.nodes.new("ShaderNodeTexImage")
    to.image = orm
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(ta.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(to.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (0.58, 0.05, 0.03, 1.0)
    return mat


def sticker_material(sticker_png):
    image = load_packed("box_stickers", sticker_png, "sRGB")
    mat = M.get("mat_sticker_atlas") or M.new("mat_sticker_atlas")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = image
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


class TrayMesh:
    """bmesh con dos ranuras: 0 = mat_plastic_red (UV de caja, 1 unidad = 2 m), 1 = atlas_box."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()

    def face(self, verts, uv=None, out=None, smooth=False):
        f = self.bm.faces.new(verts)
        f.smooth = smooth
        f.normal_update()
        if out is not None and f.normal.dot(out) < 0:
            f.normal_flip()
        if uv is None:
            f.material_index = 0
            ax = max(range(3), key=lambda i: abs(f.normal[i]))
            for lp in f.loops:
                co = lp.vert.co
                u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
                lp[self.uv].uv = (u / 2.0, v / 2.0)
        else:
            f.material_index = 1
            for lp in f.loops:
                lp[self.uv].uv = uv(lp.vert.co) if callable(uv) else uv
        return f

    def finish(self, name, parent, coll, atlas):
        me = bpy.data.meshes.new(name)
        self.bm.normal_update()
        self.bm.to_mesh(me)
        self.bm.free()
        me.materials.append(M["mat_plastic_red"])
        me.materials.append(atlas)
        ob = bpy.data.objects.new(name, me)
        ob.parent = parent
        coll.objects.link(ob)
        return ob


def build_tray(size, atlas, parent, coll):
    a, b, n, handles = SIZES[size]
    ts = params(a, b, n)
    mb = TrayMesh()
    rings = []
    for inset, z, _cell in PROFILE:
        rings.append([mb.bm.verts.new((*outline(a, b, n, inset, t), z)) for t in ts])
    for r in range(len(PROFILE) - 1):
        cell = PROFILE[r][2]
        if cell == "band":
            cell = f"band_{size}"
        inner_wall = r >= 6
        for k in range(SEGS):
            q = (rings[r][k], rings[r][(k + 1) % SEGS], rings[r + 1][(k + 1) % SEGS], rings[r + 1][k])
            mid = sum((v.co for v in q), Vector()) / 4
            radial = Vector((mid.x, mid.y, 0.0)).normalized()
            out = -radial if inner_wall else radial
            if r == 5:
                out = Vector((0, 0, 1))
            if r == 7:
                out = Vector((0, 0, 1))
            mb.face(q, uv=cell_uv(cell) if cell else None, out=out, smooth=True)
    liner = mb.face(rings[-1], uv=liner_uv, out=Vector((0, 0, 1)))
    bmesh.ops.triangulate(mb.bm, faces=[liner])  # sin n-gonos: el export calcula tangentes
    # Sombreado suave alrededor y aristas vivas entre bandas del perfil (normales partidas en el .glb).
    for ring in rings:
        for k in range(SEGS):
            edge = mb.bm.edges.get((ring[k], ring[(k + 1) % SEGS]))
            if edge is not None:
                edge.smooth = False
    if handles:
        for side in (-1, 1):
            build_handle(mb, a, b, side)
    build_logo(mb, a, b, n)
    ob = mb.finish(f"box_{size}", parent, coll, atlas)
    return ob


def build_handle(mb, a, b, side):
    """Asa de la grande: lengüeta horizontal a ras del labio con ranura para los dedos."""
    dx, wy, th = HANDLE
    sx, sy = HANDLE_SLOT
    x0, x1 = side * (a - 0.012), side * (a + dx)
    z0, z1 = HEIGHT - th, HEIGHT
    hx0, hx1 = side * (a + 0.006), side * (a + 0.006 + sx)
    outer = [(x0, -wy / 2), (x1, -wy / 2), (x1, wy / 2), (x0, wy / 2)]
    inner = [(hx0, -sy / 2), (hx1, -sy / 2), (hx1, sy / 2), (hx0, sy / 2)]
    loops = {}
    for key, pts in (("o", outer), ("i", inner)):
        for zk, z in (("b", z0), ("t", z1)):
            loops[key + zk] = [mb.bm.verts.new((x, y, z)) for x, y in pts]
    rim = cell_uv("rim")
    red = cell_uv("red")
    centre = Vector((side * (a + 0.006 + sx / 2), 0.0, 0.0))
    for k in range(4):
        k1 = (k + 1) % 4
        mb.face((loops["ot"][k], loops["ot"][k1], loops["it"][k1], loops["it"][k]), uv=rim, out=Vector((0, 0, 1)))
        mb.face((loops["ob"][k], loops["ob"][k1], loops["ib"][k1], loops["ib"][k]), uv=red, out=Vector((0, 0, -1)))
        q = (loops["ob"][k], loops["ob"][k1], loops["ot"][k1], loops["ot"][k])
        mid = sum((v.co for v in q), Vector()) / 4
        mb.face(q, uv=red, out=Vector((mid.x - centre.x, mid.y, 0)))
        q = (loops["ib"][k], loops["ib"][k1], loops["it"][k1], loops["it"][k])
        mid = sum((v.co for v in q), Vector()) / 4
        mb.face(q, uv=cell_uv("foot"), out=Vector((centre.x - mid.x, -mid.y, 0)))


def wall_point(a, b, n, t, z):
    """Punto de la pared exterior (entre los anillos 1 y 2 del perfil) a la altura z, y su normal."""
    (i0, z0, _), (i1, z1, _) = PROFILE[1], PROFILE[2]
    f = (z - z0) / (z1 - z0)
    p0 = outline(a, b, n, i0, t)
    p1 = outline(a, b, n, i1, t)
    p = p0.lerp(p1, f)
    eps = 1e-3
    tangent = (outline(a, b, n, i0, t + eps) - outline(a, b, n, i0, t - eps)).to_3d().normalized()
    up = (p1 - p0).to_3d() + Vector((0, 0, z1 - z0))
    normal = tangent.cross(up.normalized()).normalized()
    if normal.dot(Vector((p.x, p.y, 0))) < 0:
        normal = -normal
    return Vector((p.x, p.y, z)), normal


def t_at_arc(a, b, n, t0, arc, z):
    """Parámetro a una distancia `arc` (con signo) por la pared desde t0, a la altura z."""
    steps = 400
    dt = math.copysign(0.002, arc)
    t, acc = t0, 0.0
    prev = wall_point(a, b, n, t, z)[0]
    for _ in range(steps * 10):
        if acc >= abs(arc):
            break
        t += dt
        cur = wall_point(a, b, n, t, z)[0]
        acc += (cur - prev).length
        prev = cur
    return t


def build_logo(mb, a, b, n):
    """Símbolo de la marca en el canto frontal-inferior, del lado de la cámara (−Y): rejilla 4×2."""
    tc = -math.pi / 2
    zmid = sum(LOGO_Z) / 2
    t0 = t_at_arc(a, b, n, tc, -LOGO / 2, zmid)
    t1 = t_at_arc(a, b, n, tc, LOGO / 2, zmid)
    cols, rows = 4, 2
    grid = []
    for j in range(rows + 1):
        z = LOGO_Z[0] + (LOGO_Z[1] - LOGO_Z[0]) * j / rows
        row = []
        for i in range(cols + 1):
            t = t0 + (t1 - t0) * i / cols
            p, nrm = wall_point(a, b, n, t, z)
            v = mb.bm.verts.new(p + nrm * OFFSET)
            row.append((v, i / cols, j / rows))
        grid.append(row)
    for j in range(rows):
        for i in range(cols):
            q = (grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i])
            verts = [e[0] for e in q]
            f = mb.face(verts, uv=(0.0, 0.0), out=Vector((0, -1, 0)))
            uvs = {e[0]: logo_uv(e[1], e[2]) for e in q}
            for lp in f.loops:
                lp[mb.uv].uv = uvs[lp.vert]


def hull_material():
    """Invisible (alfa 0, mezcla): el hull solo existe para el contorno `material_overlay`."""
    mat = M.get("mat_outline_hull") or M.new("mat_outline_hull")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Alpha"].default_value = 0.0
    bsdf.inputs["Base Color"].default_value = (0.58, 0.05, 0.03, 1.0)
    mat.surface_render_method = "BLENDED"
    return mat


def build_hull(size, parent, coll, mat):
    """Volumen cerrado con el contorno exterior de la bandeja (pie → labio, asas incluidas en la
    grande): el inverted hull de `highlight_outline` necesita una malla cerrada (nota de PUL-049);
    la bandeja abierta rellenaría de color el interior y la comida."""
    a, b, n, handles = SIZES[size]
    ts = params(a, b, n)
    bm = bmesh.new()
    grow = HANDLE[0] if handles else 0.0
    lo = [bm.verts.new((*outline(a, b, n, PROFILE[0][0], t), 0.0)) for t in ts]
    hi = []
    for t in ts:
        p = outline(a, b, n, 0.0, t)
        # Las asas salen en ±X: el hull se estira en X para abarcarlas.
        hi.append(bm.verts.new((p.x * (1 + grow / a), p.y, HEIGHT)))
    for k in range(SEGS):
        bm.faces.new((lo[k], lo[(k + 1) % SEGS], hi[(k + 1) % SEGS], hi[k]))
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(f"hull_{size}")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(f"hull_{size}", me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def sticker_mesh(name, cell, mat):
    """Disco de 0,10 m en el plano XZ mirando a +Y (frente), UV en la celda `cell` del atlas (PUL-047)."""
    me = bpy.data.meshes.new(name)
    me.materials.append(mat)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    r = STICKER_D / 2
    cu, cv = 1.0 / STICKER_COLS, 1.0 / STICKER_ROWS
    u0, v0 = (cell % STICKER_COLS) * cu, 1.0 - (cell // STICKER_COLS + 1) * cv
    centre = bm.verts.new((0.0, 0.0, 0.0))
    rim = [bm.verts.new((r * math.cos(2 * math.pi * k / STICKER_SIDES), 0.0, r * math.sin(2 * math.pi * k / STICKER_SIDES))) for k in range(STICKER_SIDES)]
    for k in range(STICKER_SIDES):
        f = bm.faces.new((centre, rim[(k + 1) % STICKER_SIDES], rim[k]))
        for loop in f.loops:
            p = loop.vert.co
            loop[uv].uv = (u0 + cu * (0.5 + p.x / (2 * r)), v0 + cv * (0.5 + p.z / (2 * r)))
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    return me


def sticker_anchors(size):
    """Cuatro huecos en arco centrados en +Y (frente del contrato), separados un disco y un poco."""
    a, b, n, _h = SIZES[size]
    out = []
    for i in range(4):
        t = t_at_arc(a, b, n, math.pi / 2, (1.5 - i) * STICKER_D * 1.08, STICKER_Z)
        out.append(wall_point(a, b, n, t, STICKER_Z))
    return out


def build(atlas_dir, sticker_png):
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("box") or bpy.data.objects["asset"]
    root.name = "box"
    for ob in list(root.children_recursive):
        if ob.name != "Anchor_Front":
            remove_object(ob.name)
    rc = bpy.data.collections.get("render_only")
    if rc is None:
        rc = bpy.data.collections.new("render_only")
        bpy.context.scene.collection.children.link(rc)
    for ob in list(rc.objects):
        remove_object(ob.name)
    atlas = atlas_material(atlas_dir)
    smat = sticker_material(sticker_png)

    hull_root = bpy.data.objects.new("OutlineHull", None)
    hull_root.empty_display_size = 0.05
    hull_root.parent = root
    coll.objects.link(hull_root)
    hmat = hull_material()
    report = {}
    for size in SIZES:
        build_hull(size, hull_root, coll, hmat)
        tray = build_tray(size, atlas, root, coll)
        fill = bpy.data.objects.new(f"Anchor_Fill_{size}", None)
        fill.empty_display_type = "PLAIN_AXES"
        fill.empty_display_size = 0.05
        fill.location = (0.0, 0.0, FILL_Z)
        fill.parent = tray
        coll.objects.link(fill)
        for i, (pos, normal) in enumerate(sticker_anchors(size)):
            anchor = bpy.data.objects.new(f"Anchor_Sticker_{size}_{i}", None)
            anchor.empty_display_type = "SPHERE"
            anchor.empty_display_size = 0.01
            anchor.location = pos + normal * OFFSET
            anchor.parent = tray
            coll.objects.link(anchor)
            # Copias de revisión (no se exportan): pegatinas giradas sobre la pared.
            if i < {"small": 4, "medium": 3, "large": 2}[size]:
                cell = {"small": [0, 2, 3, 4], "medium": [1, 2, 4], "large": [0, 3]}[size][i]
                rev = bpy.data.objects.new(f"review_sticker_{size}_{i}", sticker_mesh(f"review_sticker_{size}_{i}", cell, smat))
                rev.matrix_world = Matrix.Translation(pos + normal * 2 * OFFSET) @ Vector((0, 1, 0)).rotation_difference(normal).to_matrix().to_4x4()
                rc.objects.link(rev)
        bpy.context.view_layer.update()
        report[f"box_{size}"] = {
            "tris": sum(len(p.vertices) - 2 for p in tray.data.polygons),
            "dims": [round(d, 3) for d in tray.dimensions],
            "zmin": round(min(v.co.z for v in tray.data.vertices), 4),
        }

    # Pegatina reutilizable exportada: celda 0, delante de la mediana, oculta en juego.
    sticker = bpy.data.objects.new("sticker", sticker_mesh("sticker", 0, smat))
    pos, _n = sticker_anchors("medium")[1]
    sticker.location = pos + Vector((0, OFFSET, 0))
    sticker.parent = root
    coll.objects.link(sticker)
    front = bpy.data.objects["Anchor_Front"]
    front.parent = root
    bpy.ops.wm.save_mainfile()
    return report
