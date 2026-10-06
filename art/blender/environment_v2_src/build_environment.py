"""Geometría de art/blender/environment_v2.blend (PUL-085): entorno de romería con la estética v2.

Se ejecuta dentro de Blender (MCP en modo CLI, `execute_blender_code_for_cli`) sobre una copia de
art/blender/_template.blend guardada como art/blender/environment_v2.blend:
    ns = {"__file__": "<ruta de este fichero>"}; exec(open(ns["__file__"]).read(), ns); ns["build_all"]()

Cada pieza es una colección `export_<pieza>` con su raíz y su `Anchor_Front_<pieza>`; el export
(`export_environment.sh`) las renombra en memoria a `export`/`Anchor_Front`. Todas se modelan en
**coordenadas del nivel** (Godot: x a la derecha, y arriba, z hacia la cámara) con la función `P` de
cada pieza; `environment.tscn` instancia cada `.glb` en su origen y girado 180° en Y, de modo que el
frente (+Y de Blender, `Anchor_Front`) mira a la cámara y lo modelado cae donde dicen las coordenadas.

Zonas (art-bible v2 §5) en el nivel: zona jugable x ∈ [−6,8, 9,2], z ∈ [−4,5, 6,5].
- `ground_w`/`ground_e` (Z0 + borde Z3): tierra con rodadas, charcos, manchas, hojas y rejillas como
  decals planos (≤ 2 cm), hierba fuera del perímetro. Sin objetos sueltos en Z0.
- `back_w`/`back_e` (Z3): muro de sillares de granito detrás de la cocina, suelo trasero, valla de malla,
  carballos, fentos, tanques de gas, generador con bidones y bombona, barriles, cajas, sacos y cables.
- `tent` (Z3, por encima del plano de juego): toldo a rayas `canvas_red`/`brand_paper` con faldón
  festoneado y ribete marino, placa PulpaSA con lema, cartel luminoso PulpaSA, cámaras de vigilancia,
  pizarras de menú y guirnalda de bombillas.
- `props_w`/`props_e` (Z3, laterales): mesas largas con mantel de papel y comensales estáticos con ropa
  de romería, cuncas, vasos PulpaSA, barriles, cajas, sacos, fentos, postes con guirnaldas y banderines.
Sin colisiones (Z3) y sin luces ni cámaras (las luces de bombilla son nodos de environment.tscn).
"""

import math
import random
from pathlib import Path

import bmesh
import bpy

SRC = Path(__file__).resolve().parent
TEX = "//textures/environment_v2/"
_gen = {"__file__": str(SRC / "gen_textures.py"), "__name__": "gen_textures"}
exec((SRC / "gen_textures.py").read_text(encoding="utf-8"), _gen)
swatch_uv = _gen["swatch_uv"]
FERN_UV, BOARD_UV = _gen["FERN_UV"], _gen["BOARD_UV"]
DECAL_TRACK_UV, DECAL_PUDDLE_UV = _gen["DECAL_TRACK_UV"], _gen["DECAL_PUDDLE_UV"]
DECAL_STAIN_UV, DECAL_LITTER_UV = _gen["DECAL_STAIN_UV"], _gen["DECAL_LITTER_UV"]

GROUND_Y = 0.012  # cara superior de la tierra (como la v1: por encima del suelo de KitchenLayout)
DECAL_Y = GROUND_Y + 0.003
WALL_Z0, WALL_Z1, WALL_H = -4.56, -4.86, 2.05  # muro de granito (frente, trasera, alto)


# ---------------------------------------------------------------- materiales propios (atlas, §3.3)


def _image(name, non_color=False):
    img = bpy.data.images.get(name)
    if img is None:
        img = bpy.data.images.load(name if name.startswith("//") else TEX + name, check_existing=True)
        img.name = name
    if non_color:
        img.colorspace_settings.name = "Non-Color"
    return img


def own_material(name, albedo, rough, metal=0.0, alpha=None, emission=None, emission_strength=0.0, double=False):
    """Material propio del entorno con la misma estructura de nodos que la biblioteca v2.

    alpha: None (opaco), "clip" (recorte 0,5 → glTF MASK) o "blend" (decals → glTF BLEND).
    """
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _image(albedo)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if alpha == "clip":
        cmp = nt.nodes.new("ShaderNodeMath")
        cmp.operation = "GREATER_THAN"
        cmp.inputs[1].default_value = 0.5
        nt.links.new(tex.outputs["Alpha"], cmp.inputs[0])
        nt.links.new(cmp.outputs["Value"], bsdf.inputs["Alpha"])
        mat.surface_render_method = "DITHERED"
    elif alpha == "blend":
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        mat.surface_render_method = "BLENDED"
    if emission:
        em = nt.nodes.new("ShaderNodeTexImage")
        em.image = _image(emission)
        nt.links.new(em.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    mat.use_backface_culling = not double
    return mat


def setup_materials():
    own_material("env_atlas", "atlas_albedo.png", 0.8)
    own_material("env_fern", "atlas_albedo.png", 0.85, alpha="clip", double=True)
    own_material("env_board", "atlas_albedo.png", 0.9)
    own_material("env_track", "decals_albedo.png", 0.95, alpha="blend")
    own_material("env_puddle", "decals_albedo.png", 0.1, alpha="blend")
    own_material("env_fence", "fence_albedo.png", 0.6, metal=0.6, alpha="clip", double=True)
    own_material("env_plate", "plate_albedo.png", 0.85)
    own_material("env_sign", "sign_albedo.png", 0.5, emission="sign_emission.png", emission_strength=2.5)
    # Tarjetas de hoja: la textura de mat_foliage de la biblioteca, pero con recorte alfa (glTF MASK) en
    # vez de mezcla, para que proyecten sombra y no tengan problemas de orden con el resto del fondo.
    own_material("env_foliage", "//../../godot/assets/textures/v2/foliage/foliage_albedo.png", 0.9, alpha="clip", double=True)


# ---------------------------------------------------------------- constructor de mallas


class Piece:
    """Pieza exportable: colección, raíz, `Anchor_Front` y origen en el nivel (x, z de Godot)."""

    def __init__(self, name, ox, oz):
        self.name, self.ox, self.oz = name, ox, oz
        cname = "export_" + name
        old = bpy.data.collections.get(cname)
        if old is not None:
            for ob in list(old.all_objects):
                bpy.data.objects.remove(ob, do_unlink=True)
            bpy.data.collections.remove(old)
        self.coll = bpy.data.collections.new(cname)
        bpy.context.scene.collection.children.link(self.coll)
        self.root = bpy.data.objects.new(name, None)
        self.coll.objects.link(self.root)
        anchor = bpy.data.objects.new("Anchor_Front_" + name, None)
        anchor.empty_display_type = "SPHERE"
        anchor.empty_display_size = 0.05
        anchor.location = (0.0, 0.5, 0.0)
        anchor.parent = self.root
        self.coll.objects.link(anchor)

    def P(self, x, y, z):
        """Punto del nivel (Godot) → coordenadas de Blender de la pieza (girada 180° en la escena)."""
        return (self.ox - x, z - self.oz, y)

    def D(self, dx, dy, dz):
        return (-dx, dz, dy)

    def mesh(self, name):
        return MB(self, name)


class MB:
    """Acumula caras con material y UV; `done()` crea el objeto bajo la raíz de la pieza."""

    def __init__(self, piece, name):
        self.pc, self.name = piece, piece.name + "_" + name
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.verify()
        self.mats = []

    def mi(self, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        return self.mats.index(mat)

    def face(self, pts, mat, uv=("box", 2.0), out=None, smooth=False, uvs=None):
        """Cara de puntos del nivel. `out`: dirección hacia fuera (nivel) para orientar la normal.

        uv: ("box", metros por unidad) | ("swatch", celda del atlas) | ("pts", [(u, v)...]).
        """
        verts = [self.bm.verts.new(self.pc.P(*p)) for p in pts]
        f = self.bm.faces.new(verts)
        f.material_index = self.mi(mat)
        f.smooth = smooth
        f.normal_update()
        if out is not None:
            o = self.pc.D(*out)
            if f.normal.dot(o) < 0:
                f.normal_flip()
        kind = uv[0]
        if kind == "box":
            m = uv[1]
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                co = loop.vert.co
                u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
                loop[self.uv].uv = (u / m, v / m)
        elif kind == "swatch":
            cu, cv = swatch_uv(uv[1])
            for i, loop in enumerate(f.loops):
                a = 2 * math.pi * i / len(f.loops)
                loop[self.uv].uv = (cu + 0.012 * math.cos(a), cv + 0.012 * math.sin(a))
        else:
            table = dict(zip(verts, uv[1]))
            for loop in f.loops:
                loop[self.uv].uv = table[loop.vert]
        return f

    # --- primitivas en coordenadas del nivel ---

    def box(self, x0, x1, y0, y1, z0, z1, mat, uv=("box", 2.0), skip=()):
        x0, x1 = min(x0, x1), max(x0, x1)
        z0, z1 = min(z0, z1), max(z0, z1)
        c = [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1),
             (x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)]
        faces = {
            "top": ((4, 5, 6, 7), (0, 1, 0)), "bottom": ((0, 3, 2, 1), (0, -1, 0)),
            "back": ((0, 4, 5, 1), (0, 0, -1)), "front": ((3, 2, 6, 7), (0, 0, 1)),
            "left": ((0, 3, 7, 4), (-1, 0, 0)), "right": ((1, 5, 6, 2), (1, 0, 0)),
        }
        for k, (idx, out) in faces.items():
            if k not in skip:
                self.face([c[i] for i in idx], mat, uv, out)

    def prism(self, poly, y0, y1, mat, uv=("box", 2.0), bottom=False, top=True):
        """Prisma vertical de un polígono (x, z) convexo."""
        cx = sum(p[0] for p in poly) / len(poly)
        cz = sum(p[1] for p in poly) / len(poly)
        if top:
            self.face([(x, y1, z) for x, z in poly], mat, uv, (0, 1, 0))
        if bottom:
            self.face([(x, y0, z) for x, z in poly], mat, uv, (0, -1, 0))
        n = len(poly)
        for i in range(n):
            (ax, az), (bx, bz) = poly[i], poly[(i + 1) % n]
            mx, mz = (ax + bx) / 2 - cx, (az + bz) / 2 - cz
            self.face([(ax, y0, az), (bx, y0, bz), (bx, y1, bz), (ax, y1, az)], mat, uv, (mx, 0, mz))

    def lathe(self, cx, cz, rings, n, mat, uv=("box", 2.0), top=True, bottom=False, smooth=True, rot=0.0):
        """Sólido de revolución vertical: rings = [(y, r), ...] de abajo arriba."""
        loops = [[(cx + r * math.cos(rot + 2 * math.pi * i / n), y, cz + r * math.sin(rot + 2 * math.pi * i / n))
                  for i in range(n)] for y, r in rings]
        for (ya, ra), (yb, rb), a, b in zip(rings, rings[1:], loops, loops[1:]):
            for i in range(n):
                j = (i + 1) % n
                t = rot + 2 * math.pi * (i + 0.5) / n
                if ra < 1e-4 and rb < 1e-4:
                    continue
                pts = [a[i], a[j], b[j], b[i]]
                if ra < 1e-4:
                    pts = [a[i], b[j], b[i]]
                elif rb < 1e-4:
                    pts = [a[i], a[j], b[i]]
                slope = (ra - rb) / max(abs(yb - ya), 1e-4) if yb >= ya else 0
                self.face(pts, mat, uv, (math.cos(t), slope, math.sin(t)), smooth)
        if top and rings[-1][1] > 1e-4:
            self.face(loops[-1], mat, uv, (0, 1, 0))
        if bottom and rings[0][1] > 1e-4:
            self.face(loops[0], mat, uv, (0, -1, 0))

    def sphere(self, cx, cy, cz, r, mat, uv=("box", 2.0), n=8, rings=5, sy=1.0, smooth=True):
        rs = [(cy - r * sy * math.cos(math.pi * k / rings), r * math.sin(math.pi * k / rings)) for k in range(rings + 1)]
        self.lathe(cx, cz, rs, n, mat, uv, top=False, smooth=smooth)

    def beam(self, a, b, w, mat, uv=("box", 2.0), h=None):
        """Listón de sección w × h (h = w por defecto) entre dos puntos del nivel."""
        h = h or w
        d = [b[i] - a[i] for i in range(3)]
        ln = math.sqrt(sum(c * c for c in d))
        u = [c / ln for c in d]
        ref = (0, 1, 0) if abs(u[1]) < 0.9 else (1, 0, 0)
        s = _norm(_cross(u, ref))
        t = _cross(s, u)
        corners = [(1, 1), (-1, 1), (-1, -1), (1, -1)]

        def p(o, k):
            cs, ct = corners[k]
            return tuple(o[i] + s[i] * cs * w / 2 + t[i] * ct * h / 2 for i in range(3))

        ra, rb = [p(a, k) for k in range(4)], [p(b, k) for k in range(4)]
        for k in range(4):
            j = (k + 1) % 4
            mid = [(s[i] * (corners[k][0] + corners[j][0]) + t[i] * (corners[k][1] + corners[j][1])) for i in range(3)]
            self.face([ra[k], ra[j], rb[j], rb[k]], mat, uv, mid)
        self.face(ra, mat, uv, [-c for c in u])
        self.face(rb, mat, uv, u)

    def tube(self, pts, r, mat, n=5, uv=("box", 2.0)):
        """Cable/manguera: tubo de n lados por una polilínea del nivel."""
        rings = []
        for k, p in enumerate(pts):
            a = pts[max(k - 1, 0)]
            b = pts[min(k + 1, len(pts) - 1)]
            u = _norm([b[i] - a[i] for i in range(3)])
            ref = (0, 1, 0) if abs(u[1]) < 0.9 else (1, 0, 0)
            s = _norm(_cross(u, ref))
            t = _cross(s, u)
            rings.append([tuple(p[i] + r * (math.cos(2 * math.pi * j / n) * s[i] + math.sin(2 * math.pi * j / n) * t[i])
                                for i in range(3)) for j in range(n)])
        for k in range(len(rings) - 1):
            for j in range(n):
                jj = (j + 1) % n
                c = [(rings[k][j][i] + rings[k + 1][jj][i]) / 2 - (pts[k][i] + pts[k + 1][i]) / 2 for i in range(3)]
                self.face([rings[k][j], rings[k][jj], rings[k + 1][jj], rings[k + 1][j]], mat, uv, c, smooth=True)

    def quad_uv(self, corners, mat, rect, out):
        """Cuadrilátero con la región `rect` (u0, v0, u1, v1) del atlas; corners en orden ↙ ↘ ↗ ↖."""
        u0, v0, u1, v1 = rect
        return self.face(corners, mat, ("pts", [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]), out)

    def done(self):
        me = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(bpy.data.materials[m])
        ob = bpy.data.objects.new(self.name, me)
        ob.parent = self.pc.root
        self.pc.coll.objects.link(ob)
        return ob


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _norm(v):
    ln = math.sqrt(sum(c * c for c in v)) or 1.0
    return [c / ln for c in v]


def wobble_poly(cx, cz, rx, rz, rng, n=14, jitter=0.18):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        k = 1 + rng.uniform(-jitter, jitter)
        pts.append((cx + math.cos(t) * rx * k, cz + math.sin(t) * rz * k))
    return pts


# ---------------------------------------------------------------- atrezo reutilizable


def barrel(mb, x, z, rng, h=0.85, r=0.3):
    mb.lathe(x, z, [(0, r * 0.86), (h * 0.25, r * 0.97), (h * 0.5, r), (h * 0.75, r * 0.97), (h, r * 0.86)], 10,
             "mat_wood_dark", rot=rng.uniform(0, 1))
    for yy in (0.12, h - 0.12):
        rr = r * 0.9 + 0.012
        mb.lathe(x, z, [(yy - 0.03, rr), (yy + 0.03, rr)], 10, "mat_steel_dark", top=False)


def crate(mb, x, z, y0, w, d, h, yaw=0.0, mat="mat_wood_used"):
    c, s = math.cos(yaw), math.sin(yaw)
    poly = [(x + c * px - s * pz, z + s * px + c * pz) for px, pz in ((-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2))]
    mb.prism(poly, y0, y0 + h, mat)
    # Listón oscuro en el canto superior frontal (lectura de caja de fruta).
    if mat == "mat_wood_used":
        fx, fz = -s * (d / 2 + 0.01), c * (d / 2 + 0.01)
        a = (x + c * -w / 2 + fx, y0 + h * 0.62, z + s * -w / 2 + fz)
        b = (x + c * w / 2 + fx, y0 + h * 0.62, z + s * w / 2 + fz)
        mb.beam(a, b, 0.05, "mat_wood_dark", h=0.02)


def sack(mb, x, z, rng, s=1.0):
    r = 0.24 * s
    mb.lathe(x, z, [(0, r * 0.8), (0.12 * s, r), (0.32 * s, r * 0.95), (0.46 * s, r * 0.6), (0.52 * s, r * 0.25),
                    (0.56 * s, r * 0.32)], 7, "mat_burlap", rot=rng.uniform(0, 1))


def cardboard_stack(mb, x, z, rng, n=2):
    y = 0.0
    for k in range(n):
        w, d, h = rng.uniform(0.45, 0.6), rng.uniform(0.35, 0.45), rng.uniform(0.28, 0.36)
        crate(mb, x + rng.uniform(-0.05, 0.05), z + rng.uniform(-0.05, 0.05), y, w, d, h, rng.uniform(-0.2, 0.2), "mat_cardboard")
        y += h


def fern(mb, x, z, rng, size=1.0, fronds=9):
    """Fento: frondas arqueadas (tarjetas de 3 tramos con la fronda del atlas, recorte alfa)."""
    u0, v0, u1, v1 = FERN_UV
    for k in range(fronds):
        a = 2 * math.pi * k / fronds + rng.uniform(-0.25, 0.25)
        ln = size * rng.uniform(0.75, 1.05)
        w = ln * 0.42
        lift = rng.uniform(0.5, 0.75)
        dx, dz = math.cos(a), math.sin(a)
        px, pz = -dz, dx
        prev = None
        for i in range(4):
            t = i / 3
            d = ln * t
            yv = 0.02 + ln * lift * math.sin(t * 2.2) * 0.75
            cx, cz = x + dx * d, z + dz * d
            hw = w / 2 * (1 - 0.15 * t)
            l = (cx - px * hw, yv, cz - pz * hw)
            r = (cx + px * hw, yv, cz + pz * hw)
            vv = v0 + (v1 - v0) * t
            if prev is not None:
                pl, pr, pv = prev
                mb.face([pl, pr, r, l], "env_fern", ("pts", [(u0, pv), (u1, pv), (u1, vv), (u0, vv)]), (0, 1, 0))
            prev = (l, r, vv)


def grass_tuft(mb, x, z, rng, s=1.0):
    """Mata baja de hierba/fento: cinco frondas cortas del atlas (recorte alfa), ≤ 0,3 m de alto."""
    fern(mb, x, z, rng, 0.38 * s, fronds=5)


def tree(mb, x, z, rng, trunk_h=2.4, crown_r=1.7, top=5.85):
    """Carballo estilizado: tronco con ramas, copa de bultos (atlas) y tarjetas de hoja (mat_foliage)."""
    mb.lathe(x, z, [(0, 0.34), (0.25, 0.24), (trunk_h, 0.18), (trunk_h + 0.6, 0.1)], 8, "mat_wood_dark", rot=0.3)
    for a in (0.6, 2.4, 4.3):
        mb.beam((x, trunk_h - 0.3, z), (x + math.cos(a) * 0.8, trunk_h + 0.6, z + math.sin(a) * 0.8), 0.12, "mat_wood_dark")
    cy = top - crown_r * 0.9
    blobs = [(0, 0, 0, 1.0)] + [(math.cos(a) * crown_r * 0.55, rng.uniform(-0.35, 0.3) * crown_r, math.sin(a) * crown_r * 0.55,
                                  rng.uniform(0.62, 0.78)) for a in [i * 2 * math.pi / 6 + rng.uniform(0, 0.4) for i in range(6)]]
    for i, (bx, by, bz, k) in enumerate(blobs):
        r = crown_r * 0.62 * k
        shade = "leaf_dark" if by < -0.1 else ("leaf_light" if by > 0.15 else "leaf_mid")
        mb.sphere(x + bx, min(cy + by, top - r * 0.85), z + bz, r, "env_atlas", ("swatch", shade), n=9, rings=5, sy=0.85)
    for k in range(26):
        a = rng.uniform(0, 2 * math.pi)
        e = rng.uniform(-0.3, 1.0)
        rr = crown_r * rng.uniform(0.75, 0.95)
        cx, cyy, cz = x + math.cos(a) * rr * math.cos(e * 0.8), cy + math.sin(e) * rr * 0.75, z + math.sin(a) * rr * math.cos(e * 0.8)
        cyy = min(cyy, top - 0.35)
        s = rng.uniform(0.55, 0.75)
        tx, tz = -math.sin(a) * s, math.cos(a) * s
        mb.face([(cx - tx, cyy - s * 0.7, cz - tz), (cx + tx, cyy - s * 0.7, cz + tz), (cx + tx, cyy + s * 0.7, cz + tz),
                 (cx - tx, cyy + s * 0.7, cz - tz)], "env_foliage", ("pts", [(0, 0), (1, 0), (1, 1), (0, 1)]),
                (math.cos(a), 0.3, math.sin(a)))


def bulb(mb, x, y, z):
    mb.lathe(x, z, [(y + 0.04, 0.018), (y + 0.075, 0.02)], 6, "env_atlas", ("swatch", "bulb_socket"), smooth=False)
    mb.lathe(x, z, [(y - 0.06, 0.0), (y - 0.035, 0.038), (y + 0.0, 0.045), (y + 0.04, 0.022)], 6, "mat_emissive_bulb", top=False)


def catenary(a, b, sag, n):
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t - sag * 4 * t * (1 - t), a[2] + (b[2] - a[2]) * t))
    return pts


def garland(mb, a, b, sag, spacing=0.45):
    """Cable de guirnalda con bombillas cálidas colgando (emisivo `bulb_warm`)."""
    ln = math.dist(a, b)
    n = max(2, int(ln / spacing))
    pts = catenary(a, b, sag, n * 2)
    mb.tube(pts, 0.008, "mat_rubber", n=4)
    for i in range(1, n * 2, 2):
        x, y, z = pts[i]
        bulb(mb, x, y - 0.08, z)


FLAGS = ("flag_red", "flag_ochre", "flag_teal", "flag_cream")


def bunting(mb, a, b, sag, count, offset=0):
    """Banderines apagados (Z3, −15 % de saturación): cuerda a lo largo de x, cara hacia la cámara."""
    pts = catenary(a, b, sag, count * 2)
    mb.tube(pts, 0.006, "mat_rubber", n=3)
    for i in range(count):
        p0, p1 = pts[2 * i], pts[2 * i + 2]
        mid = pts[2 * i + 1]
        tip = (mid[0], mid[1] - 0.26, mid[2] + 0.004)
        mb.face([p0, p1, tip], "env_atlas", ("swatch", FLAGS[(i + offset) % 4]), (0, 0.2, 1))
        back = [(px, py, pz - 0.006) for px, py, pz in (p0, p1, tip)]
        mb.face(back, "env_atlas", ("swatch", FLAGS[(i + offset) % 4]), (0, 0.2, -1))


def pole(mb, x, z, h, w=0.08):
    mb.box(x - w / 2, x + w / 2, 0, h, z - w / 2, z + w / 2, "mat_wood_dark", skip=("bottom",))


# ---------------------------------------------------------------- comensales estáticos (§1.4)

OUTFITS = [
    # (torso, brazos, piernas, sombrero, piel)
    ("vest", "shirt", "trousers", "beret", "mat_skin_light"),
    ("cardigan", "cardigan", "skirt", "scarf", "mat_skin_light"),
    ("mustard", "mustard", "trousers", "hair_grey", "mat_skin_dark"),
    ("plum", "plum", "skirt", "scarf", "mat_skin_light"),
    ("shirt", "shirt", "trousers", "beret", "mat_skin_dark"),
    ("vest", "cardigan", "trousers", "hair_brown", "mat_skin_light"),
    ("cardigan", "shirt", "trousers", "beret", "mat_skin_light"),
]


def diner(mb, x, z, facing, outfit, rng, seat_y=0.45):
    """Comensal sentado (≈ 300 tris), cabezón como los cocineros. `facing` = ±1 en x (hacia la mesa)."""
    torso, arms, legs, hat, skin = outfit
    f = facing
    # Muslos hacia la mesa y piernas bajo ella.
    mb.box(x, x + f * 0.36, seat_y, seat_y + 0.14, z - 0.15, z + 0.15, "env_atlas", ("swatch", legs), skip=("bottom",))
    mb.box(x + f * 0.26, x + f * 0.38, 0.0, seat_y, z - 0.14, z + 0.14, "env_atlas", ("swatch", legs), skip=("bottom",))
    # Tronco.
    mb.lathe(x, z, [(seat_y + 0.05, 0.17), (seat_y + 0.3, 0.18), (seat_y + 0.5, 0.16), (seat_y + 0.58, 0.08)], 8,
             "env_atlas", ("swatch", torso), top=True)
    # Brazos apoyados en la mesa y manos.
    for side in (-1, 1):
        sh = (x, seat_y + 0.46, z + side * 0.2)
        el = (x + f * 0.16, seat_y + 0.22, z + side * 0.22)
        hd = (x + f * 0.42, seat_y + 0.33, z + side * 0.12)
        mb.beam(sh, el, 0.09, "env_atlas", ("swatch", arms))
        mb.beam(el, hd, 0.08, "env_atlas", ("swatch", arms))
        mb.sphere(hd[0], hd[1], hd[2], 0.045, skin, n=6, rings=3)
    # Cabeza.
    hy = seat_y + 0.74
    mb.sphere(x + f * 0.02, hy, z, 0.15, skin, n=10, rings=6)
    if hat == "beret":
        mb.lathe(x + f * 0.01, z, [(hy + 0.09, 0.16), (hy + 0.13, 0.165), (hy + 0.17, 0.1), (hy + 0.18, 0.0)], 10,
                 "env_atlas", ("swatch", "beret"), top=False, bottom=True)
    elif hat == "scarf":
        mb.sphere(x - f * 0.005, hy + 0.02, z, 0.158, "env_atlas", ("swatch", "scarf" if rng.random() < 0.6 else "mustard"),
                  n=10, rings=6, sy=0.95)
        mb.sphere(x + f * 0.13, hy + 0.0, z, 0.13, skin, n=8, rings=4, sy=1.0)  # cara asomando del pañuelo
    else:
        mb.sphere(x - f * 0.02, hy + 0.04, z, 0.152, "env_atlas", ("swatch", hat), n=10, rings=6, sy=0.9)
        mb.sphere(x + f * 0.1, hy - 0.01, z, 0.12, skin, n=8, rings=4)


def table_with_diners(mb, x, z0, z1, rng, sides=(-1, 1), outfits=None, cups=True):
    """Mesa corrida a lo largo de z con mantel de papel, bancos y comensales; platos de pulpo y cuncas."""
    hw = 0.38
    top = 0.74
    # Patas y tablero.
    for zz in (z0 + 0.15, z1 - 0.15):
        for xx in (x - hw + 0.08, x + hw - 0.08):
            mb.box(xx - 0.035, xx + 0.035, 0, top - 0.04, zz - 0.035, zz + 0.035, "mat_wood_used", skip=("bottom",))
    mb.box(x - hw, x + hw, top - 0.04, top, z0, z1, "mat_wood_used", skip=("bottom",))
    # Mantel de papel con faldón corto.
    mb.box(x - hw - 0.03, x + hw + 0.03, top, top + 0.006, z0 - 0.03, z1 + 0.03, "env_atlas", ("swatch", "tablecloth"))
    for sx in (-1, 1):
        xe = x + sx * (hw + 0.03)
        mb.face([(xe, top - 0.12, z0 - 0.03), (xe, top - 0.12, z1 + 0.03), (xe, top, z1 + 0.03), (xe, top, z0 - 0.03)],
                "env_atlas", ("swatch", "tablecloth"), (sx, 0, 0))
    # Bancos.
    for s in sides:
        bx = x + s * 0.72
        mb.box(bx - 0.16, bx + 0.16, 0.41, 0.45, z0 + 0.05, z1 - 0.05, "mat_wood_used", skip=("bottom",))
        for zz in (z0 + 0.25, z1 - 0.25):
            mb.box(bx - 0.12, bx + 0.12, 0, 0.41, zz - 0.03, zz + 0.03, "mat_wood_used", skip=("bottom",))
    # Comensales, platos de madera con pulpo, cuncas y vasos PulpaSA.
    k = 0
    for s in sides:
        n = max(1, int((z1 - z0) / 0.85))
        for i in range(n):
            zz = z0 + (i + 0.5) * (z1 - z0) / n + rng.uniform(-0.08, 0.08)
            if rng.random() < 0.15 and n > 2:
                continue
            outfit = (outfits or OUTFITS)[k % len(outfits or OUTFITS)]
            k += 1
            diner(mb, x + s * 0.72, zz, -s, outfit, rng)
            px = x + s * 0.17
            mb.lathe(px, zz, [(top + 0.006, 0.14), (top + 0.025, 0.15)], 10, "mat_wood_used", smooth=False)
            for j in range(6):
                a = rng.uniform(0, 2 * math.pi)
                rr = rng.uniform(0, 0.08)
                mb.lathe(px + math.cos(a) * rr, zz + math.sin(a) * rr, [(top + 0.025, 0.028), (top + 0.045, 0.026)], 6,
                         "mat_food_octopus_pieces", smooth=False)
            cz = zz + 0.22 * (1 if i % 2 else -1)
            if cups and rng.random() < 0.5:
                mb.lathe(x + s * 0.12, cz, [(top, 0.035), (top + 0.07, 0.042)], 8, "env_atlas", ("swatch", "cup"), top=False)
                mb.lathe(x + s * 0.12, cz, [(top + 0.015, 0.037), (top + 0.04, 0.039)], 8, "env_atlas", ("swatch", "cup_band"), top=False)
                mb.lathe(x + s * 0.12, cz, [(top + 0.07, 0.045), (top + 0.085, 0.03)], 8, "env_atlas", ("swatch", "cup_lid"))
            else:
                mb.lathe(x + s * 0.12, cz, [(top, 0.03), (top + 0.04, 0.055), (top + 0.055, 0.06)], 8, "mat_clay", top=False)
                mb.lathe(x + s * 0.12, cz, [(top + 0.05, 0.05)], 8, "mat_clay")
    # Jarra de barro en el centro.
    zm = (z0 + z1) / 2
    mb.lathe(x, zm, [(top, 0.06), (top + 0.1, 0.085), (top + 0.18, 0.06), (top + 0.22, 0.05)], 8, "mat_clay")


# ---------------------------------------------------------------- piezas


def build_ground(name, ox, x0, x1, outer_sign, rng, tracks, puddles, stains, litter, grates):
    pc = Piece(name, ox, 1.1)
    z0, z1 = -4.8, 7.0
    mb = pc.mesh("dirt")
    # Losa de tierra (1 UV = 4 m); los cantos llegan a y = 0 para que la base del .glb sea el suelo.
    mb.box(x0, x1, 0.0, GROUND_Y, z0, z1, "mat_ground_dirt", ("box", 4.0), skip=("bottom",))
    # Hierba fuera del perímetro de encimeras (borde irregular), nunca en Z0.
    edge = -7.25 if outer_sign < 0 else 9.65
    far = x0 if outer_sign < 0 else x1
    zs = [z0 + (z1 - z0) * i / 16 for i in range(17)]
    border = [(edge + outer_sign * (0.25 + 0.55 * abs(math.sin(zz * 1.7 + rng.uniform(0, 0.6)))), zz) for zz in zs]
    gy = GROUND_Y + 0.004
    for (ax, az), (bx, bz) in zip(border, border[1:]):
        mb.face([(ax, gy, az), (far, gy, az), (far, gy, bz), (bx, gy, bz)], "mat_grass", ("box", 2.0), (0, 1, 0))
    for _ in range(9):
        gx = rng.uniform(edge + outer_sign * 0.5, far - outer_sign * 0.7)
        grass_tuft(mb, gx, rng.uniform(z0 + 0.5, z1 - 0.8), rng, rng.uniform(0.8, 1.3))
    mb.done()

    dec = pc.mesh("decals")
    v0, v1 = DECAL_TRACK_UV[1], DECAL_TRACK_UV[3]
    for path in tracks:
        for off in (-0.78, 0.78):  # dos ruedas de una furgoneta
            pts = []
            for k, (x, z) in enumerate(path):
                a, b = path[max(k - 1, 0)], path[min(k + 1, len(path) - 1)]
                dx, dz = b[0] - a[0], b[1] - a[1]
                ln = math.hypot(dx, dz)
                pts.append((x - dz / ln * off, z + dx / ln * off))
            dist = 0.0
            for k in range(len(pts) - 1):
                (ax, az), (bx, bz) = pts[k], pts[k + 1]
                a2, b2 = pts[max(k - 1, 0)], pts[min(k + 2, len(pts) - 1)]
                seg = math.hypot(bx - ax, bz - az)

                def side(i, p):
                    q0, q1 = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
                    dx, dz = q1[0] - q0[0], q1[1] - q0[1]
                    ln = math.hypot(dx, dz)
                    return (-dz / ln * 0.25, dx / ln * 0.25)

                sa, sb = side(k, pts[k]), side(k + 1, pts[k + 1])
                ua, ub = dist / 4.0, (dist + seg) / 4.0
                dec.face([(ax + sa[0], DECAL_Y, az + sa[1]), (ax - sa[0], DECAL_Y, az - sa[1]),
                          (bx - sb[0], DECAL_Y, bz - sb[1]), (bx + sb[0], DECAL_Y, bz + sb[1])], "env_track",
                         ("pts", [(ua, v1), (ua, v0), (ub, v0), (ub, v1)]), (0, 1, 0))
                dist += seg
    y = DECAL_Y + 0.0015
    for i, (x, z, w, d) in enumerate(stains):
        dec.quad_uv([(x - w / 2, y, z + d / 2), (x + w / 2, y, z + d / 2), (x + w / 2, y, z - d / 2), (x - w / 2, y, z - d / 2)],
                    "env_track", DECAL_STAIN_UV[i % 3], (0, 1, 0))
    y += 0.0015
    for i, (x, z, w, d) in enumerate(puddles):
        dec.quad_uv([(x - w / 2, y, z + d / 2), (x + w / 2, y, z + d / 2), (x + w / 2, y, z - d / 2), (x - w / 2, y, z - d / 2)],
                    "env_puddle", DECAL_PUDDLE_UV[i % 3], (0, 1, 0))
    for (x, z, w, d, ua) in litter:
        u0, v0l, u1, v1l = DECAL_LITTER_UV
        uw = w / 4.0
        dec.quad_uv([(x - w / 2, y, z + d / 2), (x + w / 2, y, z + d / 2), (x + w / 2, y, z - d / 2), (x - w / 2, y, z - d / 2)],
                    "env_track", (ua, v0l, ua + uw, v0l + (v1l - v0l) * d), (0, 1, 0))
    dec.done()

    if grates:
        gr = pc.mesh("grates")
        for (x0g, x1g, z0g, z1g) in grates:
            # Rejilla de desagüe: marco y barrotes de acero oscuro (relieve 1,5 cm, contraste de rejilla).
            t = 0.05
            gr.box(x0g, x1g, GROUND_Y, GROUND_Y + 0.004, z0g, z1g, "env_atlas", ("swatch", "lens"), skip=("bottom",))
            for (a0, a1, b0, b1) in ((x0g, x1g, z0g, z0g + t), (x0g, x1g, z1g - t, z1g), (x0g, x0g + t, z0g, z1g), (x1g - t, x1g, z0g, z1g)):
                gr.box(a0, a1, GROUND_Y, GROUND_Y + 0.015, b0, b1, "mat_steel_dark", skip=("bottom",))
            along_x = (x1g - x0g) >= (z1g - z0g)
            span = (x1g - x0g) if along_x else (z1g - z0g)
            n = int((span - 2 * t) / 0.085)
            for k in range(n):
                c = (x0g if along_x else z0g) + t + (k + 0.5) * (span - 2 * t) / n
                if along_x:
                    gr.box(c - 0.018, c + 0.018, GROUND_Y, GROUND_Y + 0.012, z0g + t, z1g - t, "mat_steel_dark", skip=("bottom",))
                else:
                    gr.box(x0g + t, x1g - t, GROUND_Y, GROUND_Y + 0.012, c - 0.018, c + 0.018, "mat_steel_dark", skip=("bottom",))
        gr.done()
    return pc


def build_back(name, ox, x0, x1, rng, west):
    pc = Piece(name, ox, -9.9)
    z0, z1 = -15.0, -4.8
    mb = pc.mesh("ground")
    mb.box(x0, x1, 0.0, GROUND_Y, z0, z1, "mat_ground_dirt", ("box", 4.0), skip=("bottom",))
    # Hierba detrás del patio de servicio (borde irregular a z ≈ −7).
    xs = [x0 + (x1 - x0) * i / 14 for i in range(15)]
    gy = GROUND_Y + 0.004
    border = [(xx, -6.9 - 0.5 * abs(math.sin(xx * 1.3 + rng.uniform(0, 0.5)))) for xx in xs]
    for (ax, az), (bx, bz) in zip(border, border[1:]):
        mb.face([(ax, gy, az), (bx, gy, bz), (bx, gy, z0), (ax, gy, z0)], "mat_grass", ("box", 2.0), (0, 1, 0))
    mb.done()

    # Muro de sillares de granito (§1.4) con albardilla y pilastras en los extremos.
    wall = pc.mesh("wall")
    wx0 = max(x0, -7.3)
    wx1 = min(x1, 9.7)
    wall.box(wx0, wx1, 0.0, WALL_H, WALL_Z1, WALL_Z0, "mat_granite", ("box", 2.0), skip=("bottom", "back"))
    wall.box(wx0 - (0.05 if west else 0), wx1 + (0 if west else 0.05), WALL_H, WALL_H + 0.12, WALL_Z1 - 0.04, WALL_Z0 + 0.06,
             "mat_granite", ("box", 1.0), skip=("bottom",))
    end_x = wx0 if west else wx1
    s = -1 if west else 1
    wall.box(end_x - s * 0.1, end_x + s * 0.32, 0, WALL_H + 0.3, WALL_Z1 - 0.06, WALL_Z0 + 0.1, "mat_granite", ("box", 1.0), skip=("bottom",))
    # Musgo en la base del frente (franja baja irregular).
    for k in range(int((wx1 - wx0) / 0.7)):
        mx = wx0 + 0.35 + k * 0.7 + rng.uniform(-0.2, 0.2)
        h = rng.uniform(0.06, 0.16)
        wall.face([(mx - 0.3, 0.0, WALL_Z0 + 0.004), (mx + 0.3, 0.0, WALL_Z0 + 0.004), (mx + 0.18, h, WALL_Z0 + 0.004),
                   (mx - 0.2, h * 0.8, WALL_Z0 + 0.004)], "mat_grass", ("box", 1.0), (0, 0, 1))
    wall.done()

    # Valla de malla metálica: postes de metal pintado y paños con recorte alfa.
    fz = -11.6
    fence = pc.mesh("fence")
    fh = 2.0
    posts = [x0 + 0.2 + i * 2.35 for i in range(int((x1 - x0 - 0.2) / 2.35) + 1)]
    side_x = -10.5 if west else 12.2
    for px in posts:
        fence.box(px - 0.04, px + 0.04, 0, fh + 0.06, fz - 0.04, fz + 0.04, "mat_paint_worn_grey", skip=("bottom",))
    fence.beam((x0 + 0.05, fh, fz), (x1 - 0.05, fh, fz), 0.045, "mat_paint_worn_grey")
    fence.face([(x0, 0.05, fz), (x1, 0.05, fz), (x1, fh, fz), (x0, fh, fz)], "env_fence",
               ("pts", [(0, 0), (x1 - x0, 0), (x1 - x0, fh - 0.05), (0, fh - 0.05)]), (0, 0, 1))
    # Tramo lateral de la valla hacia la cámara (fuera de la zona jugable).
    sz1 = -7.3
    for pz in (fz, (fz + sz1) / 2, sz1):
        fence.box(side_x - 0.04, side_x + 0.04, 0, fh + 0.06, pz - 0.04, pz + 0.04, "mat_paint_worn_grey", skip=("bottom",))
    fence.beam((side_x, fh, fz), (side_x, fh, sz1), 0.045, "mat_paint_worn_grey")
    fence.face([(side_x, 0.05, fz), (side_x, 0.05, sz1), (side_x, fh, sz1), (side_x, fh, fz)], "env_fence",
               ("pts", [(0, 0), (sz1 - fz, 0), (sz1 - fz, fh - 0.05), (0, fh - 0.05)]), (1 if west else -1, 0, 0))
    fence.done()

    veg = pc.mesh("vegetation")
    if west:
        tree(veg, -8.6, -9.4, rng, crown_r=1.8)
        tree(veg, -5.6, -13.4, rng, crown_r=1.6, top=5.7)
        for (fx, fz2, s2) in ((-10.0, -6.3, 0.9), (-8.6, -12.3, 0.9), (-6.8, -11.9, 0.8), (-10.3, -5.4, 0.7)):
            fern(veg, fx, fz2, rng, s2)
    else:
        tree(veg, 10.0, -9.3, rng, crown_r=1.8)
        tree(veg, 7.0, -13.6, rng, crown_r=1.5, top=5.6)
        for (fx, fz2, s2) in ((11.5, -6.2, 0.9), (9.0, -12.2, 0.85), (11.6, -10.8, 0.8), (3.3, -12.0, 0.8)):
            fern(veg, fx, fz2, rng, s2)
    for _ in range(14):
        grass_tuft(veg, rng.uniform(x0 + 0.7, x1 - 0.7), rng.uniform(-11.4, -7.4), rng, rng.uniform(0.8, 1.4))
    for _ in range(8):
        grass_tuft(veg, rng.uniform(x0 + 0.7, x1 - 0.7), rng.uniform(-11.9, -11.4), rng, rng.uniform(1.0, 1.6))
    veg.done()

    props = pc.mesh("props")
    if west:
        # Tanque de gas plateado con tapa roja, a la izquierda del cartel.
        gas_tank(props, -3.4, -7.7, 3.7)
        # Lo que queda detrás del muro a z > −7 no se ve desde la cámara: el atrezo va más atrás.
        barrel(props, -6.6, -7.6, rng)
        barrel(props, -5.95, -7.45, rng)
        barrel(props, -6.25, -8.15, rng, h=0.8)
        cardboard_stack(props, -7.6, -7.5, rng, 3)
        crate(props, -9.9, -7.4, 0, 0.6, 0.4, 0.3, 0.1)
        crate(props, -9.9, -7.4, 0.3, 0.6, 0.4, 0.3, -0.05)
        for (sx, sz) in ((-10.3, -8.3), (-9.8, -8.5), (-10.1, -8.9)):
            sack(props, sx, sz, rng)
        barrel(props, -4.6, -8.4, rng)
        gas_bottle(props, -4.1, -8.0, "mat_plastic_blue")
    else:
        gas_tank(props, 5.0, -7.8, 3.9)
        gas_tank(props, 6.3, -7.5, 3.3, r=0.45)
        generator(props, 10.7, -5.7, rng)
        drum(props, 9.9, -6.7, "drum_green")
        drum(props, 10.5, -6.9, "drum_blue")
        gas_bottle(props, 11.75, -6.3, "mat_plastic_blue", h=1.1)
        # Cables del generador al muro y a la valla (Z3, sobre el suelo).
        props.tube([(10.2, 0.03, -5.4), (9.9, 0.03, -5.15), (9.4, 0.03, -5.05), (8.6, 0.03, -5.0), (7.0, 0.03, -4.98)], 0.022, "mat_rubber")
        props.tube([(11.2, 0.03, -6.1), (11.5, 0.03, -7.0), (11.3, 0.03, -8.4), (11.9, 0.03, -10.0), (12.15, 0.03, -11.3)], 0.022, "mat_rubber")
        for (sx, sz) in ((8.4, -7.6), (8.9, -7.4)):
            sack(props, sx, sz, rng)
        barrel(props, 8.0, -8.3, rng)
        crate(props, 7.3, -7.5, 0, 0.6, 0.4, 0.3, 0.15)
        crate(props, 7.3, -7.5, 0.3, 0.6, 0.4, 0.3, -0.1)
    props.done()
    return pc


def gas_tank(mb, x, z, h, r=0.55):
    """Tanque de gas vertical de acero claro con tapa roja y patas (fondo, flanquea el cartel)."""
    for a in (0.8, 2.4, 3.9, 5.5):
        mb.box(x + math.cos(a) * r * 0.75 - 0.04, x + math.cos(a) * r * 0.75 + 0.04, 0, 0.4,
               z + math.sin(a) * r * 0.75 - 0.04, z + math.sin(a) * r * 0.75 + 0.04, "mat_paint_worn_grey", skip=("bottom",))
    body = [(0.3, r * 0.6), (0.38, r * 0.92), (0.5, r)] + [(h - 0.45, r), (h - 0.3, r * 0.9), (h - 0.2, r * 0.6)]
    mb.lathe(x, z, body, 14, "mat_steel_brushed", top=True, bottom=True)
    mb.lathe(x, z, [(h - 0.22, r * 0.42), (h - 0.05, r * 0.4), (h, r * 0.3)], 12, "mat_plastic_red")
    mb.lathe(x, z, [(0.9, r + 0.012), (0.98, r + 0.012)], 14, "mat_steel_dark", top=False)
    mb.lathe(x, z, [(h - 0.7, r + 0.012), (h - 0.62, r + 0.012)], 14, "mat_steel_dark", top=False)


def gas_bottle(mb, x, z, mat, h=0.75, r=0.16):
    mb.lathe(x, z, [(0, r * 0.9), (0.05, r), (h - 0.15, r), (h - 0.05, r * 0.55), (h, r * 0.35)], 10, mat, bottom=False)
    mb.lathe(x, z, [(h, 0.05), (h + 0.08, 0.05)], 6, "mat_steel_brushed")
    mb.lathe(x, z, [(h + 0.02, 0.12), (h + 0.14, 0.12)], 8, "mat_steel_dark", top=False)


def drum(mb, x, z, color):
    mb.lathe(x, z, [(0, 0.28), (0.9, 0.28)], 12, "env_atlas", ("swatch", color))
    for yy in (0.3, 0.6):
        mb.lathe(x, z, [(yy - 0.02, 0.29), (yy + 0.02, 0.29)], 12, "mat_steel_dark", top=False)


def generator(mb, x, z, rng):
    """Generador beige (`paint_beige`) con panel, rejilla, tubo de escape y ruedas."""
    w, d, h = 1.4, 0.8, 0.95
    mb.box(x - w / 2, x + w / 2, 0.12, h, z - d / 2, z + d / 2, "mat_paint_worn_beige", skip=("bottom",))
    mb.box(x - w / 2 - 0.04, x + w / 2 + 0.04, h, h + 0.06, z - d / 2 - 0.04, z + d / 2 + 0.04, "mat_paint_worn_beige", skip=("bottom",))
    mb.box(x - 0.55, x - 0.05, 0.35, 0.8, z + d / 2, z + d / 2 + 0.015, "env_atlas", ("swatch", "panel"))
    mb.box(x + 0.15, x + 0.55, 0.62, 0.8, z + d / 2, z + d / 2 + 0.015, "env_atlas", ("swatch", "label"))
    for k in range(5):
        yy = 0.25 + k * 0.07
        mb.box(x + 0.12, x + 0.6, yy, yy + 0.035, z + d / 2, z + d / 2 + 0.02, "mat_steel_dark")
    for sx in (-1, 1):
        mb.box(x + sx * 0.55 - 0.05, x + sx * 0.55 + 0.05, 0, 0.12, z - d / 2 + 0.05, z + d / 2 - 0.05, "mat_steel_dark", skip=("bottom",))
    mb.lathe(x + 0.45, z - 0.2, [(h + 0.06, 0.05), (h + 0.38, 0.05)], 8, "mat_steel_dark")
    mb.box(x - 0.5, x + 0.5, h + 0.06, h + 0.1, z - 0.02, z + 0.02, "mat_steel_dark", skip=("bottom",))


def build_tent(rng):
    """Toldo, placa PulpaSA, cartel luminoso, cámaras, pizarras y guirnalda (detrás de la cocina)."""
    pc = Piece("tent", 0.3, -5.8)
    xa, xb = -5.4, 6.0
    fz, fy = -4.45, 2.62  # alero delantero (por encima del plano de juego)
    bz, by = -6.6, 3.45  # alero trasero
    n = 16
    stripe_w = (xb - xa) / n
    aw = pc.mesh("awning")

    def roof(x, t):
        """Punto del toldo: t = 0 delante, 1 detrás; comba suave entre varillas."""
        sag = 0.06 * math.sin(math.pi * ((x - xa) / stripe_w % 1.0))
        return (x, fy + (by - fy) * t - sag * math.sin(math.pi * t), fz + (bz - fz) * t)

    for i in range(n):
        mat = "mat_canvas_red" if i % 2 == 0 else "mat_canvas_paper"
        for h in range(2):
            xs = [xa + stripe_w * (i + h * 0.5), xa + stripe_w * (i + h * 0.5 + 0.5)]
            for k in range(4):
                t0, t1 = k / 4, (k + 1) / 4
                aw.face([roof(xs[0], t0), roof(xs[1], t0), roof(xs[1], t1), roof(xs[0], t1)], mat, ("box", 2.0), (0, 1, 0.4))
                under = [(px, py - 0.008, pz) for px, py, pz in (roof(xs[0], t0), roof(xs[1], t0), roof(xs[1], t1), roof(xs[0], t1))]
                aw.face(under, mat, ("box", 2.0), (0, -1, -0.4))
        # Faldón festoneado bajo el alero delantero (mismo color que la raya).
        x0, x1 = xa + stripe_w * i, xa + stripe_w * (i + 1)
        top, mid, low = fy, fy - 0.2, fy - 0.36
        pts = [(x0, top, fz), (x1, top, fz), (x1, mid, fz)]
        for k in range(1, 6):
            t = k / 6
            pts.append((x1 - (x1 - x0) * t, mid - (low - mid) * -math.sin(math.pi * t), fz))
        pts.append((x0, mid, fz))
        aw.face(pts, mat, ("box", 2.0), (0, 0, 1))
        aw.face([(px, py, pz - 0.008) for px, py, pz in pts], mat, ("box", 2.0), (0, 0, -1))
    # Ribete marino en el canto del alero y laterales.
    aw.box(xa - 0.02, xb + 0.02, fy - 0.03, fy + 0.04, fz - 0.02, fz + 0.02, "mat_cloth_pants", ("box", 2.0))
    for xe in (xa, xb):
        aw.face([(xe, fy, fz), (xe, by, bz), (xe, by - 0.25, bz), (xe, fy - 0.36, fz)],
                "mat_canvas_red", ("box", 2.0), (1 if xe == xb else -1, 0, 0))
        xi = xe - 0.008 if xe == xb else xe + 0.008
        aw.face([(xi, fy, fz), (xi, by, bz), (xi, by - 0.25, bz), (xi, fy - 0.36, fz)],
                "mat_canvas_red", ("box", 2.0), (-1 if xe == xb else 1, 0, 0))
    aw.done()

    # Placa PulpaSA con lema sobre el toldo (papel con borde marino; el logo nunca sobre las rayas).
    pl = pc.mesh("plate")
    cx = 0.3
    pw, ph = 3.3, 1.13
    t0, t1 = 0.12, 0.12 + ph / math.dist((0, fy, fz), (0, by, bz))
    lift = 0.03

    def onroof(x, t):
        return (x, fy + (by - fy) * t + lift, fz + (bz - fz) * t)

    pl.quad_uv([onroof(cx - pw / 2, t0), onroof(cx + pw / 2, t0), onroof(cx + pw / 2, t1), onroof(cx - pw / 2, t1)],
               "env_plate", (0, 0, 1, 1), (0, 1, 0.4))
    pl.done()

    st = pc.mesh("structure")
    # Postes de metal pintado: delanteros salen de la albardilla del muro; traseros, del suelo.
    for x in (xa + 0.08, xb - 0.08):
        st.box(x - 0.045, x + 0.045, WALL_H, fy + 0.02, -4.75, -4.66, "mat_paint_worn_grey", skip=("bottom",))
        st.beam((x, fy, fz), (x, fy, -4.7), 0.05, "mat_paint_worn_grey")
        st.box(x - 0.045, x + 0.045, 0, by + 0.02, bz - 0.045, bz + 0.045, "mat_paint_worn_grey", skip=("bottom",))
    for k in range(1, n // 2):
        x = xa + stripe_w * 2 * k
        st.beam((x, fy + 0.02, fz), (x, by + 0.02, bz), 0.03, "mat_paint_worn_grey")
    # Cartel luminoso PulpaSA: caja noche, tubo neón (emisivo), «SA» en blanco; sobre dos postes.
    sw, sh = 4.2, 1.575
    sx0, sx1 = 0.3 - sw / 2, 0.3 + sw / 2
    sy0 = by + 0.12
    sz = -6.75
    for x in (sx0 + 0.5, sx1 - 0.5):
        st.box(x - 0.05, x + 0.05, 0, sy0 + 0.2, sz - 0.2, sz - 0.1, "mat_paint_worn_grey", skip=("bottom",))
    st.box(sx0 - 0.06, sx1 + 0.06, sy0 - 0.06, sy0 + sh + 0.06, sz - 0.12, sz + 0.0, "env_atlas", ("swatch", "frame_navy"),
           skip=("bottom",))
    st.quad_uv([(sx0, sy0, sz + 0.012), (sx1, sy0, sz + 0.012), (sx1, sy0 + sh, sz + 0.012), (sx0, sy0 + sh, sz + 0.012)],
               "env_sign", (0, 0, 1, 1), (0, 0, 1))
    # Cámaras de vigilancia en las esquinas del toldo, apuntando a los comensales (sátira, §7).
    for x, s in ((xa + 0.1, -1), (xb - 0.1, 1)):
        y = fy - 0.15
        st.beam((x, fy - 0.02, fz + 0.02), (x + s * 0.1, y, fz + 0.12), 0.04, "mat_paint_worn_grey")
        body_a, body_b = (x + s * 0.05, y, fz + 0.1), (x + s * 0.32, y - 0.1, fz + 0.32)
        st.beam(body_a, body_b, 0.13, "env_atlas", ("swatch", "camera"))
        st.beam(body_b, (body_b[0] + s * 0.03, body_b[1] - 0.012, body_b[2] + 0.03), 0.09, "env_atlas", ("swatch", "lens"))
    # Pizarras de menú colgadas del muro (logo pequeño, tiza ilegible), donde las encimeras son bajas.
    for x in (3.1, 5.2):
        bw, bh = 0.95, 0.48
        y0 = 1.42
        st.box(x - bw / 2 - 0.04, x + bw / 2 + 0.04, y0 - 0.04, y0 + bh + 0.04, WALL_Z0 + 0.0, WALL_Z0 + 0.035,
               "env_atlas", ("swatch", "frame_navy"), skip=("bottom", "back"))
        st.quad_uv([(x - bw / 2, y0, WALL_Z0 + 0.04), (x + bw / 2, y0, WALL_Z0 + 0.04), (x + bw / 2, y0 + bh, WALL_Z0 + 0.04),
                    (x - bw / 2, y0 + bh, WALL_Z0 + 0.04)], "env_board", BOARD_UV, (0, 0, 1))
    st.done()

    # Guirnalda de bombillas bajo el alero (las OmniLight3D de `Bulbs` están en environment.tscn).
    gl = pc.mesh("bulbs")
    xs = [xa + 0.1, -2.3, 0.7, 3.2, xb - 0.1]
    for a, b in zip(xs, xs[1:]):
        garland(gl, (a, fy - 0.3, fz + 0.03), (b, fy - 0.3, fz + 0.03), 0.1, 0.5)
    gl.done()
    return pc


def build_props(name, ox, west, rng):
    pc = Piece(name, ox, 1.2)
    mb = pc.mesh("tables")
    if west:
        table_with_diners(mb, -9.1, -3.3, -0.7, rng)
        table_with_diners(mb, -9.1, 1.4, 4.0, rng, outfits=OUTFITS[3:] + OUTFITS[:3])
    else:
        table_with_diners(mb, 10.95, 0.6, 3.2, rng, outfits=OUTFITS[2:] + OUTFITS[:2])
    mb.done()

    pr = pc.mesh("props")
    if west:
        barrel(pr, -10.55, -4.0, rng)
        barrel(pr, -9.95, -4.15, rng)
        barrel(pr, -10.3, -3.5, rng, h=0.8)
        crate(pr, -10.7, 5.0, 0, 0.6, 0.42, 0.32, 0.2)
        crate(pr, -10.65, 5.0, 0.32, 0.6, 0.42, 0.32, 0.05)
        crate(pr, -10.0, 5.25, 0, 0.6, 0.42, 0.32, -0.15)
        for (sx, sz) in ((-8.0, 5.6), (-8.45, 5.9), (-7.95, 6.15)):
            sack(pr, sx, sz, rng)
        barrel(pr, -10.6, 0.5, rng)
        cardboard_stack(pr, -7.75, -3.9, rng, 2)
    else:
        barrel(pr, 11.65, -3.8, rng)
        barrel(pr, 11.05, -3.95, rng, h=0.8)
        drum(pr, 11.7, -2.9, "drum_blue")
        barrel(pr, 11.6, 4.6, rng)
        barrel(pr, 11.0, 5.0, rng)
        crate(pr, 10.15, 5.7, 0, 0.6, 0.42, 0.32, 0.1)
        sack(pr, 10.2, -3.6, rng)
        sack(pr, 10.0, -3.1, rng)
        cardboard_stack(pr, 10.1, -1.3, rng, 2)
    pr.done()

    veg = pc.mesh("vegetation")
    if west:
        for (fx, fz, s) in ((-10.4, 6.3, 1.1), (-9.4, 6.6, 0.9), (-10.8, -1.6, 0.8), (-7.7, 3.7, 0.6)):
            fern(veg, fx, fz, rng, s)
    else:
        for (fx, fz, s) in ((11.6, 6.4, 1.1), (10.3, 6.7, 0.9), (11.9, -0.6, 0.8)):
            fern(veg, fx, fz, rng, s)
    veg.done()

    gl = pc.mesh("garlands")
    px = -7.3 if west else 9.65
    poles = (-4.0, 1.0, 6.0)
    for zz in poles:
        pole(gl, px, zz, 2.6)
    for a, b in zip(poles, poles[1:]):
        garland(gl, (px, 2.5, a), (px, 2.5, b), 0.32)
    far_x = -10.75 if west else 12.25
    for zz in (-1.9, 2.8):
        pole(gl, far_x, zz, 2.3)
        pole(gl, px, zz, 2.3)
        a, b = ((far_x, 2.2, zz), (px, 2.2, zz)) if west else ((px, 2.2, zz), (far_x, 2.2, zz))
        bunting(gl, a, b, 0.2, 7 if west else 5, offset=int(zz))
    gl.done()
    return pc


PIECES = {}


def build_all():
    for c in list(bpy.data.collections):
        if c.name == "export":
            for ob in list(c.all_objects):
                bpy.data.objects.remove(ob, do_unlink=True)
            bpy.data.collections.remove(c)
    setup_materials()
    rng = random.Random(85)
    PIECES["ground_w"] = build_ground(
        "ground_w", -5.2, -11.1, 0.7, -1, rng,
        tracks=[[(-10.8, 6.0), (-8.0, 5.2), (-5.0, 3.5), (-2.6, 2.6), (0.7, 2.3)],
                [(-6.8, -1.2), (-4.6, -2.4), (-2.0, -2.9), (0.7, -2.7)]],
        puddles=[(-4.6, 3.7, 1.05, 0.8), (-1.2, -2.0, 0.8, 0.62), (-9.6, 0.4, 1.1, 0.8)],
        stains=[(-3.4, 1.6, 1.3, 1.1), (-5.6, -1.6, 1.2, 1.0), (-2.2, 4.6, 1.1, 1.0)],
        litter=[(-6.1, 4.3, 1.6, 0.6, 0.0), (-2.9, -3.2, 1.8, 0.5, 0.45), (-8.6, -2.4, 2.0, 0.8, 0.2)],
        grates=[(-1.95, 0.55, -3.3, -2.95)])
    PIECES["ground_e"] = build_ground(
        "ground_e", 6.6, 0.7, 12.5, 1, rng,
        tracks=[[(0.7, 2.3), (3.4, 2.2), (6.0, 3.0), (8.6, 4.6), (12.2, 5.4)],
                [(0.7, -2.7), (3.2, -2.3), (5.6, -1.4), (8.4, -1.6)]],
        puddles=[(3.4, 2.6, 1.15, 0.85), (7.7, -2.7, 0.8, 0.6), (5.6, 4.0, 0.7, 0.5)],
        stains=[(2.2, -0.9, 1.3, 1.1), (6.8, 1.4, 1.2, 1.1), (4.0, 4.5, 1.1, 1.0)],
        litter=[(2.6, 4.2, 1.8, 0.6, 0.6), (7.9, -3.3, 1.6, 0.5, 0.1), (10.9, -1.8, 1.6, 0.9, 0.3)],
        grates=[(4.6, 7.8, 4.45, 4.75)])
    PIECES["back_w"] = build_back("back_w", -5.25, -11.2, 0.7, rng, True)
    PIECES["back_e"] = build_back("back_e", 6.65, 0.7, 12.6, rng, False)
    PIECES["tent"] = build_tent(rng)
    PIECES["props_w"] = build_props("props_w", -9.1, True, rng)
    PIECES["props_e"] = build_props("props_e", 11.0, False, rng)
    # La colección de referencia de la plantilla no se exporta; se oculta en el render.
    ref = bpy.data.collections.get("reference")
    if ref is not None:
        ref.hide_render = True
    stats = {}
    for name, pc in PIECES.items():
        tris = 0
        for ob in pc.coll.all_objects:
            if ob.type == "MESH":
                tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
        stats[name] = tris
    return stats
