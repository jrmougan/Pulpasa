"""Geometría v2 de art/blender/cachelos_storage.blend (PUL-080), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre una copia de art/blender/_template.blend (materiales v2 enlazados),
desde la raíz del repo:
    ns = {}; exec(open("docs/evidence/PUL-080/build_cachelos_storage.py").read(), ns); ns["build_all"]()

Cachelera (art-bible v2 §1.2, §6.5, §8): dos **sacos de arpillera** abiertos (`mat_burlap`) con la boca
enrollada hacia fuera y llenos hasta arriba de **patatas crudas** con piel: son las mallas de
`cachelos_raw` de `art/blender/cachelos.blend` (PUL-076, material `mat_food_potato_raw` + su atlas
`atlas_cachelos`), separadas en sus dos patatas y reducidas al 75 %. El saco grande va atrás a la
izquierda y el pequeño, delante a la derecha, apoyado en él; el interior de la boca es arpillera en
sombra (atlas propio) para que las patatas se lean por luminancia contra el borde claro, y cada saco
lleva una franja impresa marino apagado en el frente (Z2, sin texto).

Raíz `cachelos_storage` con las mallas `sacks` (arpillera y atlas) y `potatoes` (patatas de PUL-076).
Huella de la v1: todo cabe en la colisión de la escena (0,7 × 0,6 × 0,6 m). El `OutlineHull` de la
escena (dos cilindros dentro de los sacos) da el contorno, porque la malla es abierta (nota de PUL-049).

Coordenadas escritas en ejes de Godot (X derecha, Y arriba, Z hacia atrás) y convertidas a Blender con
`P()`: el frente +Y de Blender es −Z en Godot.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials
UV_M = 2.0  # 1 unidad de UV = 2 m (materials-v2.md §2)
POTATO_BLEND = "art/blender/cachelos.blend"
POTATO_SCALE = 0.75

# Atlas propio (64², 2 × 2 celdas lisas): interior en sombra de la boca y franja impresa.
ATLAS = "atlas_cachelos_storage"
ATLAS_PX = 64
ATLAS_CELLS = 2
CELLS = {
    "inner": ("#5E4B37", 0.95),  # arpillera por dentro, en sombra
    "stripe": ("#3D4A5C", 0.9),  # franja impresa (marino apagado, sin texto)
    "fill": ("#4A3B2C", 0.95),  # fondo bajo las patatas
}

# Sacos: (centro x, centro z, radio, alto, giro de la boca, semilla).
SACKS = [
    (-0.125, 0.075, 0.185, 0.56, 0.0, 1),
    (0.165, -0.1, 0.150, 0.42, 0.6, 2),
]
SEGS = 18


def P(x, y, z):
    """Punto en ejes de Godot → Blender (Z arriba, frente +Y)."""
    return Vector((x, -z, y))


def srgb(hex_color):
    return tuple(int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))


def cell_uv(key):
    idx = list(CELLS).index(key)
    col, row = idx % ATLAS_CELLS, idx // ATLAS_CELLS
    return ((col + 0.5) / ATLAS_CELLS, (row + 0.5) / ATLAS_CELLS)


def make_atlas():
    """Atlas del asset (albedo sRGB + ORM lineal: R = 1, G = roughness, B = 0), empaquetado."""
    cell = ATLAS_PX // ATLAS_CELLS
    keys = list(CELLS)
    imgs = {}
    for kind in ("albedo", "orm"):
        name = f"{ATLAS}_{kind}"
        old = bpy.data.images.get(name)
        if old is not None:
            bpy.data.images.remove(old)
        img = bpy.data.images.new(name, ATLAS_PX, ATLAS_PX, alpha=False)
        img.colorspace_settings.name = "sRGB" if kind == "albedo" else "Non-Color"
        px = [0.0] * (ATLAS_PX * ATLAS_PX * 4)
        for y in range(ATLAS_PX):
            for x in range(ATLAS_PX):
                idx = (y // cell) * ATLAS_CELLS + x // cell
                hex_color, rough = CELLS[keys[min(idx, len(keys) - 1)]]
                rgb = srgb(hex_color) if kind == "albedo" else (1.0, rough, 0.0)
                o = (y * ATLAS_PX + x) * 4
                px[o:o + 4] = [*rgb, 1.0]
        img.pixels[:] = px
        img.file_format = "PNG"
        img.pack()
        imgs[kind] = img
    mat = M.get(ATLAS) or M.new(ATLAS)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    alb = nt.nodes.new("ShaderNodeTexImage")
    alb.image = imgs["albedo"]
    orm = nt.nodes.new("ShaderNodeTexImage")
    orm.image = imgs["orm"]
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(alb.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(orm.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*[c ** 2.2 for c in srgb(CELLS["inner"][0])], 1.0)
    return mat


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


# --- Sacos -------------------------------------------------------------------------------------

# Perfil del saco (t de 0 a 1 en altura, factor de radio): base redondeada, panza, cuello algo
# más estrecho y la boca enrollada hacia fuera (rulo de 0,07 m) que vuelve hacia dentro.
WALL = [(0.0, 0.84), (0.035, 1.0), (0.16, 1.07), (0.42, 1.04), (0.52, 1.02), (0.62, 0.99), (0.86, 0.93)]
# Franja impresa del frente: entre estos dos anillos del perfil.
STRIPE_T = (0.52, 0.62)


def sack_rings(r, h, seed):
    """Anillos de la cara exterior (de abajo arriba) y del rulo; luego el interior hasta el relleno."""
    cuff = 0.075
    rings = []  # (y, factor de radio, celda o None, arruga del borde)
    for t, k in WALL:
        rings.append((t * (h - cuff), k, "stripe" if t == STRIPE_T[1] else None, 0.0))
    y0 = h - cuff
    rings += [
        (y0 - 0.004, 1.06, None, 0.2),   # pie del rulo, sobresale del cuello
        (y0 + 0.04, 1.13, None, 0.7),    # panza del rulo
        (h, 1.06, None, 1.0),            # labio
        (h - 0.004, 0.92, "inner", 1.0),  # vuelta hacia dentro
        (h - 0.07, 0.86, "inner", 0.3),  # pared interior
    ]
    return rings


def wobble(th, seed):
    return 1.0 + 0.035 * math.sin(3 * th + 1.7 * seed) + 0.02 * math.sin(7 * th + seed)


def build_sack(bm, cx, cz, r, h, yaw, seed, cells, uv_info):
    rings = sack_rings(r, h, seed)
    verts = []
    for y, k, _cell, crumple in rings:
        ring = []
        for s in range(SEGS):
            th = 2 * math.pi * s / SEGS + yaw
            rad = r * k * wobble(th, seed)
            # Boca arrugada: el labio sube y baja (pliegues de la arpillera).
            dy = crumple * 0.018 * math.sin(5 * th + 2.3 * seed)
            ring.append(bm.verts.new(P(cx + rad * math.cos(th), y + dy, cz + rad * math.sin(th))))
        verts.append(ring)
    # Base: cara cerrada (no se ve, pero cierra la silueta de sombra).
    bottom = bm.faces.new(list(reversed(verts[0])))
    uv_info[bottom] = ("lib", r)
    for j in range(len(rings) - 1):
        cell = rings[j + 1][2]
        for s in range(SEGS):
            s1 = (s + 1) % SEGS
            quad = (verts[j][s], verts[j][s1], verts[j + 1][s1], verts[j + 1][s])
            f = bm.faces.new(quad)
            if cell == "stripe":
                if _front(s, yaw):
                    cells[f] = cell
            elif cell is not None:
                cells[f] = cell
            # Columna de UV de cada vértice (la del último segmento cierra en SEGS, sin costura rota).
            uv_info[f] = ("cyl", r * rings[j][1], {quad[0]: s, quad[3]: s, quad[1]: s + 1, quad[2]: s + 1})
    # Fondo bajo las patatas (dentro de la boca, en sombra).
    inner = verts[-1]
    centre = bm.verts.new(P(cx, rings[-1][0] - 0.01, cz))
    for s in range(SEGS):
        f = bm.faces.new((inner[s], inner[(s + 1) % SEGS], centre))
        cells[f] = "fill"


def _front(s, yaw):
    """Segmentos del frente (−Z de Godot, hacia la cámara de juego) ±70°."""
    th = 2 * math.pi * (s + 0.5) / SEGS + yaw
    return math.sin(th) < -0.35


def finish_sacks(bm, cells, uv_info, parent, coll):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        if f in cells:
            f.material_index = 1
            c = cell_uv(cells[f])
            for lp in f.loops:
                lp[uv].uv = c
            continue
        f.material_index = 0
        info = uv_info.get(f)
        if info is None or info[0] == "lib":
            for lp in f.loops:
                lp[uv].uv = (lp.vert.co.x / UV_M, lp.vert.co.y / UV_M)
            continue
        # Cilíndrica a 2 m por unidad: u = arco, v = altura.
        _kind, rad, cols = info
        circ = 2 * math.pi * rad
        for lp in f.loops:
            lp[uv].uv = (circ * cols[lp.vert] / SEGS / UV_M, lp.vert.co.z / UV_M)
    me = bpy.data.meshes.new("sacks")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(M["mat_burlap"])
    me.materials.append(M[ATLAS])
    for p in me.polygons:
        p.use_smooth = True
    me.set_sharp_from_angle(angle=math.radians(70))
    remove_object("sacks")
    ob = bpy.data.objects.new("sacks", me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


# --- Patatas (PUL-076) -------------------------------------------------------------------------


def load_potatoes():
    """Las dos patatas crudas de `cachelos_raw` (PUL-076) como BMesh sueltos, centrados en su base."""
    with bpy.data.libraries.load(POTATO_BLEND, link=False) as (src, dst):
        dst.meshes = ["cachelos_raw"]
    me = dst.meshes[0]
    # El material de biblioteca llega enlazado a través de cachelos.blend (otra ruta de librería):
    # se cambia por el que enlaza la plantilla y se quita la librería sobrante.
    lib = next(lb for lb in bpy.data.libraries if lb.filepath == "//_materials_v2.blend")
    good = {m.name: m for m in M if m.library == lib}
    for i, m in enumerate(me.materials):
        if m is not None and m.library is not None and m.library != lib:
            me.materials[i] = good[m.name]
    for other in [lb for lb in bpy.data.libraries if lb != lib]:
        bpy.data.libraries.remove(other)
    bm = bmesh.new()
    bm.from_mesh(me)
    # Cada vértice va a la patata cuyo centro (en x) está más cerca; las islas de los ojos también.
    islands = []
    seen = set()
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, isl = [v], []
        seen.add(v.index)
        while stack:
            a = stack.pop()
            isl.append(a.index)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in seen:
                    seen.add(b.index)
                    stack.append(b)
        islands.append(isl)
    bm.verts.ensure_lookup_table()
    groups = {0: set(), 1: set()}
    for isl in islands:
        cx = sum(bm.verts[i].co.x for i in isl) / len(isl)
        groups[0 if cx < 0.0 else 1].update(isl)
    parts = []
    for g in (0, 1):
        part = bm.copy()
        part.verts.ensure_lookup_table()
        bmesh.ops.delete(part, geom=[part.verts[i] for i in range(len(part.verts)) if i not in groups[g]], context="VERTS")
        lo = min(v.co.z for v in part.verts)
        cen = sum((v.co for v in part.verts), Vector()) / len(part.verts)
        bmesh.ops.translate(part, verts=part.verts, vec=Vector((-cen.x, -cen.y, -lo)))
        bmesh.ops.scale(part, verts=part.verts, vec=Vector((POTATO_SCALE,) * 3))
        tmp = bpy.data.meshes.new("_potato_%d" % g)
        part.to_mesh(tmp)
        part.free()
        parts.append(tmp)
    bm.free()
    mats = list(me.materials)
    bpy.data.meshes.remove(me)
    return parts, mats


# (saco, x, z relativos al centro del saco, alto extra sobre el relleno, giro, pieza, inclinación)
HEAP = [
    (0, 0.0, 0.0, 0.035, 20, 0, 0),
    (0, -0.085, 0.05, 0.0, 75, 1, 10),
    (0, 0.08, 0.055, 0.0, -30, 0, -8),
    (0, -0.07, -0.075, 0.0, 130, 0, 12),
    (0, 0.085, -0.06, 0.0, 200, 1, -10),
    (1, 0.0, 0.0, 0.03, -40, 1, 0),
    (1, -0.07, 0.045, 0.0, 60, 0, 10),
    (1, 0.045, -0.04, 0.0, 150, 1, -12),
    (1, 0.06, 0.06, 0.0, -100, 0, 8),
]


def build_potatoes(parent, coll):
    parts, mats = load_potatoes()
    bm = bmesh.new()
    for sack, dx, dz, lift, yaw, piece, tilt in HEAP:
        cx, cz, r, h = SACKS[sack][:4]
        fill_y = h - 0.075
        xf = (Matrix.Translation(P(cx + dx, fill_y + lift, cz + dz))
              @ Matrix.Rotation(math.radians(tilt), 4, "X")
              @ Matrix.Rotation(math.radians(yaw), 4, "Z"))
        src = parts[piece].copy()
        src.transform(xf)
        bm.from_mesh(src)
        bpy.data.meshes.remove(src)
    for p in parts:
        bpy.data.meshes.remove(p)
    me = bpy.data.meshes.new("potatoes")
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    remove_object("potatoes")
    ob = bpy.data.objects.new("potatoes", me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


# --- Montaje -----------------------------------------------------------------------------------


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("cachelos_storage") or bpy.data.objects["asset"]
    root.name = "cachelos_storage"
    make_atlas()
    bm = bmesh.new()
    cells, uv_info = {}, {}
    for cx, cz, r, h, yaw, seed in SACKS:
        build_sack(bm, cx, cz, r, h, yaw, seed, cells, uv_info)
    finish_sacks(bm, cells, uv_info, root, coll)
    build_potatoes(root, coll)
    bpy.data.objects["Anchor_Front"].location = P(0.0, 0.0, -0.3)
    src = bpy.data.texts.get("build_cachelos_storage.py") or bpy.data.texts.new("build_cachelos_storage.py")
    src.from_string(open("docs/evidence/PUL-080/build_cachelos_storage.py").read())
    report = {}
    bpy.context.view_layer.update()
    for ob in coll.all_objects:
        if ob.type == "MESH":
            ws = [ob.matrix_world @ v.co for v in ob.data.vertices]
            report[ob.name] = {
                "tris": sum(len(p.vertices) - 2 for p in ob.data.polygons),
                "min": [round(min(w[i] for w in ws), 3) for i in range(3)],
                "max": [round(max(w[i] for w in ws), 3) for i in range(3)],
                "mats": [m.name for m in ob.data.materials],
            }
    return report
