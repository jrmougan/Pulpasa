"""Comida v2 (PUL-076): art/blender/{octopus,cachelos}.blend, generados con el MCP de Blender por CLI.

Se ejecuta dentro de Blender sobre una copia recién hecha de art/blender/_template.blend (materiales
v2 enlazados desde _materials_v2.blend) y la guarda:
    ns = {}; exec(open("docs/evidence/PUL-076/build_food_v2.py").read(), ns); ns["build"]("octopus")
    ns = {}; exec(open("docs/evidence/PUL-076/build_food_v2.py").read(), ns); ns["build"]("cachelos")

Crea, con los mismos nombres y jerarquía que PUL-045/046/069 (contrato de `ingredient.gd`,
`box_model.gd` y `cachelos_bowl.tscn`):
- colección `export`: raíz `<asset>` con `<asset>_raw`, `<asset>_cooked`, `<asset>_burnt` y
  `Anchor_Front` (+Y);
- colección `export_pieces`: raíz `<asset>_pieces` con las capas `<asset>_pieces_a/b/c` (relleno por
  raciones) y `Anchor_Front_pieces` (de la raíz en el pulpo, de la capa `a` en los cachelos).

Materiales (art-bible v2 §3): el cuerpo de cada estado usa el `mat_food_*` enlazado de la biblioteca
(el quemado trae su textura de grietas, UV a 1 unidad = 2 m); lo que no se repite (ventosas, ojos,
corte de las rodajas, borde y piel del cachelo cocido, brasas) va en el atlas propio del asset
(`atlas_<asset>`: albedo + ORM de 256², empaquetados en el .blend, celdas lisas sin ruido). Medidas en
las mismas unidades que PUL-045/046 (las formas se escalan al final ×1,4 el pulpo, ×1,9 / ×1,3 los
cachelos), así huellas y alturas no cambian y las colisiones y anclas de las escenas siguen valiendo.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

OCTOPUS_SCALE = 1.4
PIECES_SCALE = 1.4
PIECES_SPREAD = 1.2
POTATO_SCALE = 1.9
POTATO_PIECES_SCALE = 1.3

# ---------------------------------------------------------------------------------------------
# Atlas propio: celdas de 64 px en una rejilla 4×4 (256²). Cada cara de detalle toma el color del
# centro de su celda; con mipmaps una celda sigue siendo lisa hasta 16 px (no se mezclan vecinas).
# (hex sRGB, roughness) por celda; art-bible v2 §2.4 y §6.2/§6.3.
ATLAS_CELLS = 4
ATLAS_PX = 256
ATLAS = {
    "octopus": {
        "raw_dark": ("#9A6E7A", 0.40),  # ventosas/contorno del crudo
        "raw_sucker": ("#F2D6D4", 0.40),  # boca de ventosa (crudo)
        "cooked_dark": ("#6E1A3A", 0.50),  # cara ventral del cocido
        "cooked_sucker": ("#F0C8C2", 0.50),  # ventosas del cocido (crema rosado)
        "burnt_dark": ("#1A1412", 0.95),  # cara ventral del quemado
        "burnt_ember": ("#5A2A1E", 0.95),  # brasa en las puntas rotas
        "eye_white": ("#F4EFE6", 0.30),
        "eye_pupil": ("#15161A", 0.30),
        "piece_cut": ("#F4C6CC", 0.50),  # corte de las rodajas
        "piece_sucker": ("#F0C8C2", 0.50),
    },
    "cachelos": {
        "raw_eye": ("#5C432C", 0.85),  # ojos de la patata cruda
        "cooked_rim": ("#D8A93C", 0.60),  # borde obligatorio de 0,01 m (§6.3)
        "cooked_peel": ("#B98B47", 0.70),  # piel del cachelo cocido
        "burnt_dark": ("#1A1512", 0.95),
        "burnt_ember": ("#4A2E1E", 0.95),
    },
}


def srgb(hex_color: str) -> tuple:
    return tuple(int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))


def atlas_uv(asset: str, key: str) -> tuple:
    idx = list(ATLAS[asset]).index(key)
    col, row = idx % ATLAS_CELLS, idx // ATLAS_CELLS
    return ((col + 0.5) / ATLAS_CELLS, (row + 0.5) / ATLAS_CELLS)


def make_atlas(asset: str) -> bpy.types.Material:
    """Atlas del asset (albedo sRGB + ORM lineal: R = 1, G = roughness, B = 0), empaquetado."""
    cell = ATLAS_PX // ATLAS_CELLS
    imgs = {}
    for kind in ("albedo", "orm"):
        name = f"atlas_{asset}_{kind}"
        old = bpy.data.images.get(name)
        if old is not None:
            bpy.data.images.remove(old)
        img = bpy.data.images.new(name, ATLAS_PX, ATLAS_PX, alpha=False)
        img.colorspace_settings.name = "sRGB" if kind == "albedo" else "Non-Color"
        px = [0.0] * (ATLAS_PX * ATLAS_PX * 4)
        # Celdas vacías: el color medio del cuerpo, por si un mip lejano las alcanza.
        for y in range(ATLAS_PX):
            for x in range(ATLAS_PX):
                idx = (y // cell) * ATLAS_CELLS + x // cell
                keys = list(ATLAS[asset])
                hex_color, rough = ATLAS[asset][keys[min(idx, len(keys) - 1)]]
                rgb = srgb(hex_color) if kind == "albedo" else (1.0, rough, 0.0)
                o = (y * ATLAS_PX + x) * 4
                px[o : o + 4] = [*rgb, 1.0]
        img.pixels[:] = px
        img.file_format = "PNG"
        img.pack()
        imgs[kind] = img
    name = f"atlas_{asset}"
    mat = M.get(name) or M.new(name)
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
    mat.diffuse_color = (*[c**2.2 for c in srgb(ATLAS[asset][list(ATLAS[asset])[0]][0])], 1.0)
    return mat


# ---------------------------------------------------------------------------------------------
# Constructor de mallas: cada cara lleva un material de biblioteca (ranura) o una celda del atlas,
# y una dirección «hacia fuera» con la que se orienta su normal.
class Mesh:
    def __init__(self, asset: str, lib: list):
        self.asset = asset
        self.lib = lib
        self.bm = bmesh.new()
        self.cells = {}

    def face(self, verts, slot=0, cell=None, smooth=True, out=None):
        f = self.bm.faces.new(verts)
        f.smooth = smooth
        if cell is None:
            f.material_index = slot
        else:
            f.material_index = len(self.lib)
            self.cells[f] = cell
        if out is not None:
            f.normal_update()
            if f.normal.dot(out) < 0:
                f.normal_flip()
        return f

    def finish(self, name, parent, coll, scale=1.0):
        bm = self.bm
        if scale != 1.0:
            bmesh.ops.scale(bm, vec=Vector((scale,) * 3), verts=bm.verts)
        bm.normal_update()
        uv = bm.loops.layers.uv.verify()
        for f in bm.faces:
            if f in self.cells:
                c = atlas_uv(self.asset, self.cells[f])
                for lp in f.loops:
                    lp[uv].uv = c
                continue
            # Proyección de caja de la biblioteca v2: 1 unidad de UV = 2 m (materials-v2.md §2).
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for lp in f.loops:
                co = lp.vert.co
                u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
                lp[uv].uv = (u / 2.0, v / 2.0)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for m in self.lib:
            me.materials.append(M[m])
        me.materials.append(M[f"atlas_{self.asset}"])
        ob = bpy.data.objects.new(name, me)
        ob.parent = parent
        coll.objects.link(ob)
        return ob


def frames(pts):
    """Marcos de rotación mínima (T, N, B) a lo largo de una polilínea; N empieza «hacia arriba»."""
    n = len(pts)
    ts = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    up = Vector((0, 0, 1)) if abs(ts[0].z) < 0.9 else Vector((0, 1, 0))
    N = (up - up.dot(ts[0]) * ts[0]).normalized()
    out = []
    for T in ts:
        N = (N - N.dot(T) * T).normalized()
        out.append((T, N, T.cross(N)))
    return out


def tube(mb, pts, radii, sides, body, ventral, twists=None, tip="point", tip_cell=None, wrinkle=0.0):
    """Tentáculo: anillos de `sides` lados; las dos caras centradas en −N (girado `twists`) son la
    cara ventral (`ventral`: celda del atlas). Devuelve (centro, dirección ventral, radio) por tramo
    para colocar ventosas. `tip`: «point» (punta fina) o «broken» (corte plano con brasa)."""
    fr = frames(pts)
    rings = []
    for i, (p, (T, N, B)) in enumerate(zip(pts, fr)):
        tw = twists[i] if twists else 0.0
        ring = []
        for k in range(sides):
            th = 2 * math.pi * k / sides + math.pi / sides + tw
            r = radii[i] * (1.0 + wrinkle * math.sin(5.1 * i + 2.3 * k))
            ring.append(mb.bm.verts.new(p + r * (math.cos(th) * N + math.sin(th) * B)))
        rings.append(ring)
    vk = {sides // 2 - 1, sides // 2}  # caras centradas en th = π (−N)
    spots = []
    for i in range(len(pts) - 1):
        mid = (pts[i] + pts[i + 1]) / 2
        for k in range(sides):
            quad = (rings[i][k], rings[i][(k + 1) % sides], rings[i + 1][(k + 1) % sides], rings[i + 1][k])
            c = sum((v.co for v in quad), Vector()) / 4
            if k in vk:
                mb.face(quad, cell=ventral, out=c - mid)
            else:
                mb.face(quad, slot=body, out=c - mid)
        tw = ((twists[i] if twists else 0.0) + (twists[i + 1] if twists else 0.0)) / 2
        T, N, B = fr[i]
        d = (math.cos(math.pi + tw) * N + math.sin(math.pi + tw) * B).normalized()
        spots.append((mid, d, (radii[i] + radii[i + 1]) / 2, T))
    T = fr[-1][0]
    if tip == "point":
        tipv = mb.bm.verts.new(pts[-1] + T * radii[-1] * 1.5)
        for k in range(sides):
            mb.face((rings[-1][k], rings[-1][(k + 1) % sides], tipv), slot=body, out=T)
    else:
        tipv = mb.bm.verts.new(pts[-1] - T * radii[-1] * 0.15)
        for k in range(sides):
            mb.face((rings[-1][k], rings[-1][(k + 1) % sides], tipv), cell=tip_cell, smooth=False, out=T)
    return spots


def bump(mb, center, normal, tangent, radius, height, cell, segs=6):
    """Ventosa: disco abombado de `segs` lados apoyado en la superficie."""
    n = normal.normalized()
    t = (tangent - tangent.dot(n) * n).normalized()
    b = n.cross(t)
    ring = [mb.bm.verts.new(center + radius * (math.cos(2 * math.pi * k / segs) * t + math.sin(2 * math.pi * k / segs) * b)) for k in range(segs)]
    top = mb.bm.verts.new(center + n * height)
    for k in range(segs):
        mb.face((ring[k], ring[(k + 1) % segs], top), cell=cell, smooth=False, out=n)


def ellipsoid(mb, center, radii, segs, rings, slot, rot, pear=0.0, low_cell=None, zmin=None):
    """Elipsoide (manto del pulpo); `pear` ensancha la parte alta (saco), `low_cell` pinta la
    banda inferior (contorno oscuro) y `zmin` aplana la base para que no atraviese el apoyo."""
    pts = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs + math.pi / 2
            z = math.cos(phi)
            w = 1.0 + pear * z
            p = center + rot @ Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), radii[2] * z))
            if zmin is not None and p.z < zmin:
                p.z = zmin
            ring.append(mb.bm.verts.new(p))
        pts.append(ring)
    top = mb.bm.verts.new(center + rot @ Vector((0, 0, radii[2])))
    bp = center + rot @ Vector((0, 0, -radii[2]))
    if zmin is not None:
        bp.z = max(bp.z, zmin)
    bot = mb.bm.verts.new(bp)
    for k in range(segs):
        a, b = pts[0][k], pts[0][(k + 1) % segs]
        mb.face((top, a, b), slot=slot, out=(a.co + b.co) / 2 - center)
        a, b = pts[-1][k], pts[-1][(k + 1) % segs]
        if low_cell:
            mb.face((bot, b, a), cell=low_cell, out=(a.co + b.co) / 2 - center)
        else:
            mb.face((bot, b, a), slot=slot, out=(a.co + b.co) / 2 - center)
    for j in range(len(pts) - 1):
        for k in range(segs):
            quad = (pts[j][k], pts[j + 1][k], pts[j + 1][(k + 1) % segs], pts[j][(k + 1) % segs])
            c = sum((v.co for v in quad), Vector()) / 4
            if low_cell and j == len(pts) - 2:
                mb.face(quad, cell=low_cell, out=c - center)
            else:
                mb.face(quad, slot=slot, out=c - center)


def ellipsoid_point(radii, d, rot, pear=0.0):
    d = d.normalized()
    s = 1.0 / math.sqrt((d.x / radii[0]) ** 2 + (d.y / radii[1]) ** 2 + (d.z / radii[2]) ** 2)
    p = d * s
    w = 1.0 + pear * (p.z / radii[2])
    p = Vector((p.x * w, p.y * w, p.z))
    n = Vector((p.x / radii[0] ** 2, p.y / radii[1] ** 2, p.z / radii[2] ** 2)).normalized()
    return rot @ p, rot @ n


def eye(mb, pos, normal, r_white, r_pupil, look):
    """Ojo de caricatura: disco blanco abombado y pupila desplazada hacia `look`."""
    n = normal.normalized()
    t = n.cross(Vector((0, 0, 1)))
    t = t.normalized() if t.length > 1e-4 else Vector((1, 0, 0))
    b = n.cross(t)
    bump(mb, pos, n, t, r_white, r_white * 0.45, "eye_white", segs=8)
    off = (look - look.dot(n) * n)
    off = off.normalized() * r_white * 0.25 if off.length > 1e-4 else Vector()
    bump(mb, pos + n * (r_white * 0.4) + off, n, t, r_pupil, r_pupil * 0.35, "eye_pupil", segs=6)
    return b


# ---------------------------------------------------------------------------------------------
# Pulpo. Ojos hacia −Y (el lado que ve la cámara del nivel: −Y de Blender es +Z de Godot).
OCTO_ANGLES = [math.radians(22.5 + 45 * i) for i in range(8)]
CAMERA_SIDE = Vector((0, -1, 0.35))


def octopus_state(asset, state):
    lib = {"raw": ["mat_food_octopus_raw"], "cooked": ["mat_food_octopus_cooked"], "burnt": ["mat_food_octopus_burnt"]}[state]
    dark = {"raw": "raw_dark", "cooked": "cooked_dark", "burnt": "burnt_dark"}[state]
    sucker = {"raw": "raw_sucker", "cooked": "cooked_sucker", "burnt": "burnt_dark"}[state]
    mb = Mesh(asset, lib)
    burnt = state == "burnt"
    if state == "raw":
        # Patas lacias y extendidas; las puntas se retuercen y enseñan las ventosas.
        mc, mr, tilt, pear = Vector((0, 0.0, 0.10)), (0.11, 0.125, 0.09), math.radians(-14), 0.12
        for i, a in enumerate(OCTO_ANGLES):
            u, v = Vector((math.cos(a), math.sin(a), 0)), Vector((-math.sin(a), math.cos(a), 0))
            length = 0.17 + 0.02 * ((i * 3) % 4) / 3
            side = 1 if i % 2 else -1
            pts, radii, tw = [], [], []
            for j in range(9):
                t = j / 8
                s = 0.05 + length * t
                h = 0.034 * (1 - t) + 0.012 * t + 0.18 * max(0.0, t - 0.6) ** 2
                w = 0.025 * math.sin(t * math.pi * 1.4 + i)
                pts.append(u * s + v * w + Vector((0, 0, h)))
                radii.append(0.036 * (1 - t) + 0.011 * t)
                tw.append(side * math.radians(150) * max(0.0, t - 0.3) / 0.7)
            spots = tube(mb, pts, radii, 6, 0, dark, tw)
            for mid, d, r, T in spots[4:]:
                bump(mb, mid + d * r * 0.92, d, T, r * 0.42, r * 0.2, sucker, segs=5)
    else:
        # Cocido: cuerpo menor, patas enroscadas hacia arriba (ventosas por fuera del rizo).
        # Quemado: lo mismo más encogido y arrugado, con las puntas rotas (art-bible v2 §6.2).
        mc, mr, tilt, pear = Vector((0, 0.0, 0.135)), (0.085, 0.09, 0.11), math.radians(8), 0.08
        for i, a in enumerate(OCTO_ANGLES):
            u, v = Vector((math.cos(a), math.sin(a), 0)), Vector((-math.sin(a), math.cos(a), 0))
            r0 = 0.068 + 0.008 * (i % 2)
            start, straight = 0.045, 0.095
            pts, radii = [u * start + Vector((0, 0, 0.03))], [0.033]
            nseg = 8
            for j in range(1, nseg + 1):
                tt = (j - 1) / (nseg - 1)
                if j == 1:
                    s, h = start + straight, 0.03
                else:
                    ang = tt * 1.75 * math.pi
                    r = r0 * (1 - 0.45 * tt)
                    s = start + straight + r * math.sin(ang)
                    h = 0.03 + r0 - r * math.cos(ang)
                w = 0.012 * math.sin(tt * math.pi)
                pts.append(u * s + v * w + Vector((0, 0, h)))
                radii.append(0.031 * (1 - tt) + 0.011 * tt)
            if burnt:
                cut = 2 + (i % 2)  # puntas rotas: faltan 2–3 tramos, desiguales
                pts, radii = pts[:-cut], radii[:-cut]
                spots = tube(mb, pts, radii, 6, 0, dark, tip="broken", tip_cell="burnt_ember", wrinkle=0.14)
                for mid, d, r, T in spots[2::3]:
                    bump(mb, mid + d * r * 0.9, d, T, r * 0.4, r * 0.15, sucker, segs=5)
            else:
                spots = tube(mb, pts, radii, 6, 0, dark)
                for mid, d, r, T in spots[2:]:
                    bump(mb, mid + d * r * 0.92, d, T, r * 0.42, r * 0.2, sucker, segs=5)
    rot = Matrix.Rotation(tilt, 3, "X")
    ellipsoid(mb, mc, mr, 12, 8, 0, rot, pear=pear, low_cell=dark if state == "raw" else None, zmin=0.004)
    for sx in (-1, 1):
        p, n = ellipsoid_point(mr, Vector((0.4 * sx, -1.0, -0.15)), rot, pear)
        r_white = 0.026 if burnt else 0.03
        eye(mb, mc + p, n, r_white, r_white * 0.5, CAMERA_SIDE)
    if burnt:
        # Encogido y arrugado (más pequeño que el cocido, base en z = 0).
        for vtx in mb.bm.verts:
            co = vtx.co
            n = math.sin(co.x * 53.0) * math.cos(co.y * 47.0) * math.sin(co.z * 61.0 + 1.3)
            radial = Vector((co.x, co.y, 0.0))
            radial = radial.normalized() if radial.length > 1e-6 else radial
            vtx.co = Vector((co.x * 0.9, co.y * 0.9, co.z * 0.8)) + radial * (n * 0.005)
    return mb


def slice_piece(mb, center, radius, thick, axis, tilt, seed, sides=10):
    """Rodaja: piel lateral, corona de piel y corte claro en la cara de arriba, una ventosa."""
    rot = Matrix.Rotation(tilt, 3, axis)
    c = center + Vector((0, 0, radius * math.sin(abs(tilt)) + thick / 2))
    up = rot @ Vector((0, 0, 1))
    bot, top, inner = [], [], []
    for k in range(sides):
        ang = 2 * math.pi * k / sides
        w = 1.0 + 0.06 * math.sin(2 * ang + seed)  # rodaja algo ovalada, no un disco perfecto
        d = Vector((radius * w * math.cos(ang), radius * w * math.sin(ang), 0))
        bot.append(mb.bm.verts.new(c + rot @ (d - Vector((0, 0, thick / 2)))))
        top.append(mb.bm.verts.new(c + rot @ (d + Vector((0, 0, thick / 2)))))
        inner.append(mb.bm.verts.new(c + rot @ (d * 0.74 + Vector((0, 0, thick / 2 + 0.001)))))
    mid = mb.bm.verts.new(c + rot @ Vector((0, 0, thick / 2 + 0.004)))
    for k in range(sides):
        k2 = (k + 1) % sides
        side = (bot[k], bot[k2], top[k2], top[k])
        cc = sum((v.co for v in side), Vector()) / 4
        mb.face(side, slot=0, out=cc - c)
        mb.face((top[k], top[k2], inner[k2], inner[k]), slot=0, smooth=False, out=up)
        mb.face((inner[k], inner[k2], mid), cell="piece_cut", smooth=False, out=up)
    mb.face(list(reversed(bot)), slot=0, smooth=False, out=-up)
    k = seed % sides
    ang = 2 * math.pi * (k + 0.5) / sides
    d = rot @ Vector((math.cos(ang), math.sin(ang), 0))
    bump(mb, c + d * radius * 0.98, d, up, thick * 0.32, thick * 0.12, "piece_sucker")


OCTO_PIECE_LAYERS = {
    "a": [(0.0, 0.0), (0.075, 0.02), (-0.07, 0.035), (0.02, 0.08), (-0.03, -0.075), (0.065, -0.06), (-0.085, -0.03)],
    "b": [(0.035, 0.03), (-0.04, 0.04), (0.0, -0.04), (0.06, -0.015), (-0.055, -0.03)],
    "c": [(0.0, 0.01), (0.03, -0.035), (-0.03, -0.01)],
}
OCTO_PIECE_Z = {"a": 0.0, "b": 0.018, "c": 0.036}


def octopus_pieces(asset, coll):
    root = bpy.data.objects.new(f"{asset}_pieces", None)
    root.empty_display_size = 0.1
    coll.objects.link(root)
    i = 0
    for layer, spots in OCTO_PIECE_LAYERS.items():
        mb = Mesh(asset, ["mat_food_octopus_pieces"])
        for x, y in spots:
            axis = "X" if i % 2 else "Y"
            tilt = math.radians(8 + 7 * (i % 3)) * (1 if i % 4 < 2 else -1)
            center = Vector((x * PIECES_SPREAD, y * PIECES_SPREAD, OCTO_PIECE_Z[layer] * PIECES_SCALE))
            slice_piece(mb, center, 0.03 * PIECES_SCALE, 0.02 * PIECES_SCALE, axis, tilt, i)
            i += 1
        mb.finish(f"{asset}_pieces_{layer}", root, coll)
    front_anchor(root, coll)
    return root


# ---------------------------------------------------------------------------------------------
# Cachelos.
def wobble(th, phi, seed):
    return 1.0 + 0.07 * math.sin(3 * th + seed) * math.sin(phi) + 0.05 * math.cos(2 * phi + 1.7 * seed)


def potato(mb, center, radii, yaw, seed, segs=14, rings=8):
    """Patata entera con piel: elipsoide irregular, base aplanada y ojos hundidos (hoyuelos oscuros)."""
    rot = Matrix.Rotation(yaw, 3, "Z")
    zmin = -radii[2] * 0.85
    lift = Vector((0, 0, -zmin))
    eyes = {(2, (seed * 3) % segs), (3, (seed * 7 + 5) % segs), (4, (seed * 5 + 2) % segs), (2, (seed * 11 + 8) % segs)}
    rr = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs
            w = wobble(th, phi, seed)
            if (j, k) in eyes:
                w *= 0.93  # ojo hundido
            p = Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), radii[2] * math.cos(phi)))
            p.z = max(p.z, zmin)
            ring.append(mb.bm.verts.new(center + lift + rot @ p))
        rr.append(ring)
    c = center + lift
    top = mb.bm.verts.new(c + Vector((0, 0, radii[2])))
    bot = mb.bm.verts.new(c + Vector((0, 0, zmin)))
    for k in range(segs):
        a, b = rr[0][k], rr[0][(k + 1) % segs]
        mb.face((top, a, b), slot=0, out=(a.co + b.co) / 2 - c)
        a, b = rr[-1][k], rr[-1][(k + 1) % segs]
        mb.face((bot, b, a), slot=0, smooth=False, out=Vector((0, 0, -1)))
    for j in range(len(rr) - 1):
        for k in range(segs):
            quad = (rr[j][k], rr[j + 1][k], rr[j + 1][(k + 1) % segs], rr[j][(k + 1) % segs])
            cc = sum((v.co for v in quad), Vector()) / 4
            mb.face(quad, slot=0, out=cc - c)
    # Ojos: hoyuelo oscuro y redondo sobre el vértice hundido (no se pinta la cara entera).
    for j, k in eyes:
        v = rr[j - 1][k]
        n = (v.co - c).normalized()
        bump(mb, v.co + n * 0.001, n, Vector((0, 0, 1)).cross(n) + Vector((1e-3, 0, 0)), radii[0] * 0.13, -radii[0] * 0.03, "raw_eye", segs=6)


def chunk(mb, base, radii, yaw, tilt, seed, state, segs=12, rings=4, wrinkle=0.0, scale=POTATO_SCALE):
    """Trozo de cachelo: cúpula de piel abajo y cara de corte arriba con borde de 0,01 m (§6.3).
    La cara de corte mira hacia arriba, inclinada `tilt` hacia la cámara (−Y) y ±12° de lado."""
    peel, rim = ("cooked_peel", "cooked_rim") if state == "cooked" else ("burnt_dark", "burnt_ember")
    rr = []
    for j in range(1, rings + 1):
        phi = (math.pi / 2) * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs
            w = wobble(th, phi, seed) * (1.0 + 0.07 * math.sin(2 * th + 1.3 * seed)) * (1.0 + wrinkle * math.sin(4.3 * k + 2.1 * j + seed))
            ring.append(Vector((radii[0] * w * math.sin(phi) * math.cos(th), radii[1] * w * math.sin(phi) * math.sin(th), -radii[2] * math.cos(phi))))
        rr.append(ring)
    bottom = Vector((0, 0, -radii[2]))
    side = math.radians(28) * (1 if seed % 2 else -1)
    xf = Matrix.Rotation(tilt, 3, "X") @ Matrix.Rotation(side, 3, "Y") @ Matrix.Rotation(yaw, 3, "Z")
    pts = [[xf @ p for p in ring] for ring in rr]
    zlow = min([p.z for ring in pts for p in ring] + [(xf @ bottom).z])
    off = base - Vector((0, 0, zlow))
    verts = [[mb.bm.verts.new(off + p) for p in ring] for ring in pts]
    bv = mb.bm.verts.new(off + xf @ bottom)
    up = xf @ Vector((0, 0, 1))
    ctr = off
    for k in range(segs):
        a, b = verts[0][k], verts[0][(k + 1) % segs]
        mb.face((bv, b, a), cell=peel, out=(a.co + b.co) / 2 - ctr)
    for j in range(len(verts) - 1):
        for k in range(segs):
            quad = (verts[j][k], verts[j][(k + 1) % segs], verts[j + 1][(k + 1) % segs], verts[j + 1][k])
            cc = sum((v.co for v in quad), Vector()) / 4
            mb.face(quad, cell=peel, out=cc - ctr)
    edge = verts[-1]
    mid = sum((v.co for v in edge), Vector()) / len(edge)
    rad = sum(((v.co - mid).length for v in edge)) / len(edge)
    inner_k = max(0.6, 1.0 - (0.011 / scale) / rad)  # borde de ≈ 0,011 m una vez escalado
    inner = [mb.bm.verts.new(mid + (v.co - mid) * inner_k + up * 0.002) for v in edge]
    for k in range(segs):
        mb.face((edge[k], edge[(k + 1) % segs], inner[(k + 1) % segs], inner[k]), cell=rim, smooth=False, out=up)
    # Cara de corte algo abombada (harinosa), con el material de la biblioteca.
    top = mb.bm.verts.new(mid + up * radii[2] * 0.14)
    for k in range(segs):
        mb.face((inner[k], inner[(k + 1) % segs], top), slot=0, smooth=True, out=up)


def cachelos_state(asset, state):
    lib = {"raw": ["mat_food_potato_raw"], "cooked": ["mat_food_potato_cooked"], "burnt": ["mat_food_potato_burnt"]}[state]
    mb = Mesh(asset, lib)
    if state == "raw":
        # Dos patatas enteras con piel (§6.3: entera, ovalada), una algo girada y más pequeña.
        potato(mb, Vector((-0.045, 0.012, 0)), (0.068, 0.05, 0.048), math.radians(-18), 1)
        potato(mb, Vector((0.058, -0.02, 0)), (0.058, 0.045, 0.044), math.radians(62), 2)
    else:
        # Cocido: dos patatas partidas (4 trozos, uno encima). Quemado: los mismos, encogidos.
        k_size = 1.0 if state == "cooked" else 0.86
        k_z = 1.0 if state == "cooked" else 0.85
        wr = 0.0 if state == "cooked" else 0.08
        r = (0.058 * k_size, 0.044 * k_size, 0.06 * k_size * k_z)
        for i, (x, y, yaw, tilt, k) in enumerate(COOKED_CHUNKS):
            chunk(mb, Vector((x * k_size, y * k_size, 0)), tuple(v * k for v in r), math.radians(yaw), math.radians(tilt), i + 3, state, wrinkle=wr)
        x, y, yaw, tilt, k = COOKED_TOP
        chunk(mb, Vector((x * k_size, y * k_size, 0.038 * k_size * k_z)), tuple(v * k for v in r), math.radians(yaw), math.radians(tilt), 9, state, wrinkle=wr)
    return mb


# Inclinación de 20–30°: la cara de corte mira a la cámara y se ve la piel del canto (no «monedas»).
COOKED_CHUNKS = [(-0.058, 0.025, 30, 22, 1.0), (0.06, 0.03, -40, 26, 0.95), (0.0, -0.045, 80, 18, 1.0)]
COOKED_TOP = (0.0, 0.035, 0, 30, 0.9)

POTATO_PIECE_LAYERS = {
    "a": [(-0.075, 0.04, 30, 16), (0.075, 0.045, -30, 16), (0.0, -0.07, 90, 12)],
    "b": [(-0.04, -0.01, 60, 22), (0.045, -0.005, -60, 22)],
    "c": [(0.0, 0.035, 0, 26)],
}
POTATO_PIECE_Z = {"a": 0.0, "b": 0.035, "c": 0.07}


def cachelos_pieces(asset, coll):
    root = bpy.data.objects.new(f"{asset}_pieces", None)
    root.empty_display_size = 0.1
    coll.objects.link(root)
    s = POTATO_PIECES_SCALE
    r = (0.058 * s, 0.044 * s, 0.056 * s)
    layers = []
    seed = 20
    for layer, spots in POTATO_PIECE_LAYERS.items():
        mb = Mesh(asset, ["mat_food_potato_cooked"])
        for i, (x, y, yaw, tilt) in enumerate(spots):
            chunk(mb, Vector((x * s, y * s, POTATO_PIECE_Z[layer] * s)), r, math.radians(yaw), math.radians(tilt), seed + i, "cooked", scale=1.0)
        layers.append(mb.finish(f"{asset}_pieces_{layer}", root, coll))
        seed += 5
    # Como en PUL-046: el marcador cuelga de la capa a, así los hijos directos de la raíz son solo
    # las tres capas que alterna `cachelos_bowl`.
    front_anchor(layers[0], coll)
    return root


# ---------------------------------------------------------------------------------------------
def front_anchor(parent, coll):
    src = bpy.data.objects["Anchor_Front"]
    front = bpy.data.objects.new("Anchor_Front_pieces", None)
    front.empty_display_type = src.empty_display_type
    front.empty_display_size = src.empty_display_size
    front.location = (0.0, 0.5, 0.0)
    front.parent = parent
    coll.objects.link(front)


def build(asset: str) -> dict:
    """Construye el asset sobre la plantilla abierta y guarda el .blend; devuelve tris y medidas."""
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get(asset) or bpy.data.objects["asset"]
    root.name = asset
    pieces_coll = bpy.data.collections.get("export_pieces")
    if pieces_coll is None:
        pieces_coll = bpy.data.collections.new("export_pieces")
        bpy.context.scene.collection.children.link(pieces_coll)
    for ob in list(root.children) + list(pieces_coll.all_objects):
        if ob.name != "Anchor_Front":
            bpy.data.objects.remove(ob, do_unlink=True)
    make_atlas(asset)
    report = {}
    for state in ("raw", "cooked", "burnt"):
        if asset == "octopus":
            mb, scale = octopus_state(asset, state), OCTOPUS_SCALE
        else:
            mb, scale = cachelos_state(asset, state), POTATO_SCALE
        ob = mb.finish(f"{asset}_{state}", root, coll, scale)
    pieces = octopus_pieces(asset, pieces_coll) if asset == "octopus" else cachelos_pieces(asset, pieces_coll)
    bpy.context.view_layer.update()
    for ob in list(coll.all_objects) + list(pieces_coll.all_objects):
        if ob.type == "MESH":
            report[ob.name] = {
                "tris": sum(len(p.vertices) - 2 for p in ob.data.polygons),
                "dims": [round(d, 3) for d in ob.dimensions],
                "zmin": round(min((ob.matrix_world @ v.co).z for v in ob.data.vertices), 4),
            }
    bpy.ops.wm.save_mainfile()
    return report
