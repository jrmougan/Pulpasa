"""Cocinero v2 de art/blender/cook.blend (PUL-075), generado por el agente con el MCP de Blender (CLI).

Se ejecuta dentro de Blender sobre una copia de art/blender/_template.blend (materiales v2 enlazados):
    ns = {"ATLAS_PNG": "<atlas de gen_cook_atlas.py>"}
    exec(open("docs/evidence/PUL-075/build_cook_v2.py").read(), ns); ns["build_all"]()

Conserva el contrato de PUL-044 (build_cook.py): raíz `cook`, esqueleto `cook_rig` con los mismos 13
huesos, los mismos seis clips (Idle, Walk, IdleHolding, WalkWhileHolding, Pick, Cut; 30 fps),
`Anchor_Hold` en el mismo punto y las mismas mallas `cook_body_j1/j2` y `cook_hat_j1/j2` (Godot
muestra el par de la variante por `player_index`). Cambia la geometría y los materiales según la
biblia v2 (§1.2, §2.6, §2.7, §6.5, §7): uniforme de franquicia con camiseta blanca de manga corta,
pantalón marino, delantal (peto y falda) en el color del jugador con cintas marinas y bolsillo
`brand_red`, logotipo en `brand_paper` en el peto; J1 lleva **gorra de visera** (copa del color
del jugador, visera y botón `brand_red`, insignia compacta) y J2 **gorro alto** (copa abombada,
banda marina con la insignia): rasgo de forma para daltónicos (PUL-044, §6.5). Solo materiales de la
biblioteca v2 y un atlas propio de 512² (`mat_cook_atlas`, recortado por alfa) para las calcas de
marca. UV de caja a 1 unidad = 2 m (materials-v2 §2). Skin rígido: cada pieza pesa 1 en un hueso.
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

M = bpy.data.materials

# Índices de material de la malla y su material v2 por variante (art-bible v2 §2.6, §2.7, §3.1).
ACCENT, SHIRT, PANTS, SKIN, DARK, HAIR, RED, ATLAS = range(8)
VARIANT_MATS = {
    "j1": ["mat_cloth_player_1", "mat_cloth_shirt", "mat_cloth_pants", "mat_skin_light", "mat_rubber", "mat_wood_dark", "mat_canvas_red", "mat_cook_atlas"],
    "j2": ["mat_cloth_player_2", "mat_cloth_shirt", "mat_cloth_pants", "mat_skin_dark", "mat_rubber", "mat_wood_dark", "mat_canvas_red", "mat_cook_atlas"],
}
# Zonas del atlas (u0, v0, u1, v1) en UV de Blender (v hacia arriba): insignia y logo del peto.
ATLAS_BADGE = (0.0, 0.5, 0.5, 1.0)
ATLAS_APRON = (0.5, 0.5, 1.0, 1.0)
ATLAS_PNG = globals().get("ATLAS_PNG", "")

# Esqueleto en reposo (Blender: Z arriba, frente +Y). Igual que PUL-044.
SHOULDER_X, SHOULDER_Z = 0.25, 1.06
HIP_X = 0.105
BONES = {
    "root": ((0, 0, 0), (0, 0.25, 0), None),
    "hips": ((0, 0, 0.56), (0, 0, 0.74), "root"),
    "spine": ((0, 0, 0.74), (0, 0, 1.10), "hips"),
    "head": ((0, 0, 1.12), (0, 0, 1.55), "spine"),
    "upper_arm.L": ((SHOULDER_X, 0, SHOULDER_Z), (SHOULDER_X + 0.03, 0, 0.83), "spine"),
    "forearm.L": ((SHOULDER_X + 0.03, 0, 0.83), (SHOULDER_X + 0.04, 0, 0.60), "upper_arm.L"),
    "upper_arm.R": ((-SHOULDER_X, 0, SHOULDER_Z), (-SHOULDER_X - 0.03, 0, 0.83), "spine"),
    "forearm.R": ((-SHOULDER_X - 0.03, 0, 0.83), (-SHOULDER_X - 0.04, 0, 0.60), "upper_arm.R"),
    "thigh.L": ((HIP_X, 0, 0.56), (HIP_X, 0, 0.31), "hips"),
    "shin.L": ((HIP_X, 0, 0.31), (HIP_X, 0, 0.06), "thigh.L"),
    "thigh.R": ((-HIP_X, 0, 0.56), (-HIP_X, 0, 0.31), "hips"),
    "shin.R": ((-HIP_X, 0, 0.31), (-HIP_X, 0, 0.06), "thigh.R"),
}
# Mismo `%HoldPoint` que PUL-044 (centrado delante del pecho, fuera de la cápsula).
HOLD_POINT = (0.0, 0.62, 1.20)
FPS = 30
# Cabeza (centro y radios): grande, como los cocineros de la referencia.
HEAD_C = Vector((0.0, 0.0, 1.37))
HEAD_R = (0.235, 0.22, 0.23)


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if isinstance(data, (bpy.types.Mesh, bpy.types.Armature)) and data.users == 0:
        (bpy.data.meshes if isinstance(data, bpy.types.Mesh) else bpy.data.armatures).remove(data)


def atlas_material() -> bpy.types.Material:
    """Atlas propio (art-bible v2 §3.3): base del PNG empaquetado y alfa redondeada (glTF MASK)."""
    mat = M.get("mat_cook_atlas") or M.new("mat_cook_atlas")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    rnd = nt.nodes.new("ShaderNodeMath")
    rnd.operation = "ROUND"
    img = bpy.data.images.get("cook_atlas")
    if img is None:
        img = bpy.data.images.load(ATLAS_PNG)
        img.name = "cook_atlas"
    if not img.packed_file:
        img.pack()
    img.filepath = "//cook_atlas.png"
    tex.image = img
    tex.interpolation = "Linear"
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], rnd.inputs[0])
    nt.links.new(rnd.outputs["Value"], bsdf.inputs["Alpha"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.surface_render_method = "DITHERED"
    mat.use_fake_user = True
    return mat


class Builder:
    """Acumula piezas en un bmesh; cada vértice pesa 1 en el hueso de su pieza."""

    def __init__(self):
        self.bm = bmesh.new()
        self.deform = self.bm.verts.layers.deform.new()
        self.groups: list[str] = []
        self.decals: list[tuple] = []  # (caras, zona del atlas)

    def _tag(self, verts, bone):
        if bone not in self.groups:
            self.groups.append(bone)
        g = self.groups.index(bone)
        for v in verts:
            v[self.deform][g] = 1.0

    def _ring(self, c, rx, ry, sides):
        c = Vector(c)
        return [self.bm.verts.new(c + Vector((rx * math.cos(2 * math.pi * k / sides + math.pi / sides), ry * math.sin(2 * math.pi * k / sides + math.pi / sides), 0))) for k in range(sides)]

    def loft(self, sections, bone, mat, sides=12, cap_top=True, cap_bottom=True, smooth=True, mat_fn=None):
        """Sólido por secciones elípticas [(centro, rx, ry), ...] de abajo arriba (eje Z)."""
        rings = [self._ring(c, rx, ry, sides) for c, rx, ry in sections]
        faces = []
        for i in range(len(rings) - 1):
            lo, hi = rings[i], rings[i + 1]
            for k in range(sides):
                f = self.bm.faces.new((lo[k], lo[(k + 1) % sides], hi[(k + 1) % sides], hi[k]))
                f.material_index = mat_fn(i, k) if mat_fn else mat
                f.smooth = smooth
                faces.append(f)
        for ring, cap, rev in ((rings[0], cap_bottom, True), (rings[-1], cap_top, False)):
            if cap:
                # Tapa en abanico con un vértice central: sin n-gons largos, sombreado limpio.
                centre = self.bm.verts.new(sum((v.co for v in ring), Vector()) / len(ring))
                for k in range(sides):
                    tri = (ring[(k + 1) % sides], ring[k], centre) if rev else (ring[k], ring[(k + 1) % sides], centre)
                    f = self.bm.faces.new(tri)
                    f.material_index = mat
                    f.smooth = smooth
                    faces.append(f)
                self._tag([centre], bone)
        self._tag([v for r in rings for v in r], bone)
        return faces

    def tube(self, a, b, radii, bone, mat, sides=10, **kw):
        """Cilindro de `a` a `b` con radios por sección."""
        a, b = Vector(a), Vector(b)
        rot = Vector((0, 0, 1)).rotation_difference((b - a).normalized()).to_matrix().to_4x4()
        n = len(radii)
        secs = [((0, 0, (b - a).length * i / (n - 1)), r, r) for i, r in enumerate(radii)]
        faces = self.loft(secs, bone, mat, sides=sides, **kw)
        verts = list({v for f in faces for v in f.verts})
        bmesh.ops.transform(self.bm, matrix=Matrix.Translation(a) @ rot, verts=verts)
        return faces

    def blob(self, centre, radii, bone, mat, segs=12, rings=8, mat_fn=None, smooth=True, keep=None, rot=None):
        """Elipsoide; `mat_fn(cara)` elige material y `keep(cara)` False la borra."""
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=1.0)
        verts = res["verts"]
        m = Matrix.Translation(centre) @ (rot.to_4x4() if rot else Matrix()) @ Matrix.Diagonal((*radii, 1.0))
        bmesh.ops.transform(self.bm, matrix=m, verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        if keep is not None:
            drop = [f for f in faces if not keep(f)]
            bmesh.ops.delete(self.bm, geom=drop, context="FACES")
            faces -= set(drop)
            verts = [v for v in verts if v.is_valid and v.link_faces]
        for f in faces:
            f.material_index = mat_fn(f) if mat_fn else mat
            f.smooth = smooth
        self._tag(verts, bone)
        return faces

    def shell(self, z0, z1, a0, a1, profile, bone, mat, cols=8, rows=3, thick=0.018, smooth=True):
        """Panel curvo con grosor (peto, falda, bolsillo, visera…) que abraza un perfil elíptico.

        `profile(z) -> (cx, cy, rx, ry)`: elipse exterior a la altura z; el panel cubre los ángulos
        a0..a1 (grados; 90 = frente +Y) y crece `thick` hacia dentro.
        """
        outer, inner = [], []
        for r in range(rows + 1):
            z = z0 + (z1 - z0) * r / rows
            cx, cy, rx, ry = profile(z)
            ro, ri = [], []
            for c in range(cols + 1):
                a = math.radians(a0 + (a1 - a0) * c / cols)
                d = Vector((math.cos(a), math.sin(a), 0))
                ro.append(self.bm.verts.new((cx + rx * d.x, cy + ry * d.y, z)))
                ri.append(self.bm.verts.new((cx + (rx - thick) * d.x, cy + (ry - thick) * d.y, z)))
            outer.append(ro)
            inner.append(ri)
        faces = []

        def quad(vs):
            f = self.bm.faces.new(vs)
            f.material_index = mat
            f.smooth = smooth
            faces.append(f)

        for r in range(rows):
            for c in range(cols):
                quad((outer[r][c], outer[r][c + 1], outer[r + 1][c + 1], outer[r + 1][c]))
                quad((inner[r][c + 1], inner[r][c], inner[r + 1][c], inner[r + 1][c + 1]))
        for c in range(cols):  # cantos inferior y superior
            quad((inner[0][c], inner[0][c + 1], outer[0][c + 1], outer[0][c]))
            quad((outer[rows][c], outer[rows][c + 1], inner[rows][c + 1], inner[rows][c]))
        for r in range(rows):  # cantos laterales
            quad((outer[r][0], outer[r + 1][0], inner[r + 1][0], inner[r][0]))
            quad((inner[r][cols], inner[r + 1][cols], outer[r + 1][cols], outer[r][cols]))
        self._tag([v for row in outer + inner for v in row], bone)
        return faces

    def box(self, centre, size, bone, mat, rot=None, smooth=False):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        m = Matrix.Translation(centre) @ (rot.to_4x4() if rot else Matrix()) @ Matrix.Diagonal((*size, 1.0))
        bmesh.ops.transform(self.bm, matrix=m, verts=verts)
        for f in {f for v in verts for f in v.link_faces}:
            f.material_index = mat
            f.smooth = smooth
        self._tag(verts, bone)

    def decal(self, centre, normal, up, w, h, bone, zone):
        """Calca plana del atlas (insignia, logo) orientada por su normal; zona = (u0, v0, u1, v1)."""
        n = Vector(normal).normalized()
        x = Vector(up).cross(n).normalized()  # derecha vista desde delante
        y = n.cross(x).normalized()
        c = Vector(centre)
        corners = [c - x * w / 2 - y * h / 2, c + x * w / 2 - y * h / 2, c + x * w / 2 + y * h / 2, c - x * w / 2 + y * h / 2]
        vs = [self.bm.verts.new(p) for p in corners]
        f = self.bm.faces.new(vs)
        f.material_index = ATLAS
        f.smooth = False
        self._tag(vs, bone)
        self.decals.append((f, zone))

    def to_mesh(self, name):
        bm = self.bm
        bm.normal_update()
        decal_faces = {f for f, _ in self.decals}
        bmesh.ops.recalc_face_normals(bm, faces=[f for f in bm.faces if f not in decal_faces])
        # UV de caja a la densidad de la biblioteca v2: 1 unidad = 2 m (materials-v2 §2).
        uv = bm.loops.layers.uv.verify()
        for f in bm.faces:
            if f in decal_faces:
                continue
            n = f.normal
            ax = max(range(3), key=lambda i: abs(n[i]))
            for loop in f.loops:
                co = loop.vert.co
                u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
                loop[uv].uv = (u / 2.0, v / 2.0)
        for f, (u0, v0, u1, v1) in self.decals:
            for loop, (u, v) in zip(f.loops, ((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
                loop[uv].uv = (u, v)
        me = bpy.data.meshes.get(name) or bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        return me


def torso_profile(z):
    """Torso de camiseta: cintura 0,68, pecho 0,90, hombros 1,04, cuello 1,13."""
    pts = [(0.66, 0.198, 0.158), (0.80, 0.208, 0.166), (0.92, 0.218, 0.17), (1.04, 0.226, 0.166), (1.13, 0.15, 0.115)]
    for (za, rxa, rya), (zb, rxb, ryb) in zip(pts, pts[1:]):
        if z <= zb:
            t = (z - za) / (zb - za)
            return rxa + (rxb - rxa) * t, rya + (ryb - rya) * t
    return pts[-1][1], pts[-1][2]


def build_body() -> tuple:
    b = Builder()
    for side, x in (("L", HIP_X), ("R", -HIP_X)):
        d = 1 if side == "L" else -1
        # Pierna: pantalón marino algo cónico con bajo vuelto; zapato de goma redondeado.
        b.tube((x, 0, 0.62), (x, 0, 0.29), [0.102, 0.098, 0.09, 0.086], f"thigh.{side}", PANTS)
        b.tube((x, 0, 0.32), (x, 0, 0.085), [0.086, 0.08, 0.079, 0.086], f"shin.{side}", PANTS)
        b.loft([((x, 0.03, 0.0), 0.078, 0.128), ((x, 0.035, 0.03), 0.084, 0.134), ((x, 0.03, 0.075), 0.08, 0.12), ((x, 0.01, 0.115), 0.068, 0.085)], f"shin.{side}", DARK, sides=12)
        sx = SHOULDER_X * d
        # Brazo: hombro y manga corta de camiseta con ribete marino; brazo, antebrazo y mano de piel.
        b.blob((sx + 0.004 * d, 0, SHOULDER_Z - 0.012), (0.09, 0.09, 0.088), f"upper_arm.{side}", SHIRT, segs=10, rings=6)
        b.tube((sx, 0, SHOULDER_Z), (sx + 0.016 * d, 0, 0.92), [0.088, 0.088, 0.092], f"upper_arm.{side}", SHIRT, sides=10, cap_bottom=False)
        b.tube((sx + 0.016 * d, 0, 0.935), (sx + 0.019 * d, 0, 0.905), [0.094, 0.094], f"upper_arm.{side}", PANTS, sides=10)
        b.tube((sx + 0.016 * d, 0, 0.93), (sx + 0.03 * d, 0, 0.82), [0.064, 0.06], f"upper_arm.{side}", SKIN, sides=8)
        b.tube((sx + 0.03 * d, 0, 0.84), (sx + 0.04 * d, 0, 0.625), [0.06, 0.056, 0.052], f"forearm.{side}", SKIN, sides=8)
        # Mano en manopla con pulgar hacia delante.
        b.blob((sx + 0.042 * d, 0.004, 0.585), (0.058, 0.066, 0.074), f"forearm.{side}", SKIN, segs=10, rings=6)
        b.blob((sx + 0.03 * d, 0.05, 0.605), (0.026, 0.03, 0.036), f"forearm.{side}", SKIN, segs=6, rings=4)
    # Cadera de pantalón.
    b.loft([((0, 0, 0.50), 0.19, 0.15), ((0, 0, 0.58), 0.206, 0.164), ((0, 0, 0.67), 0.206, 0.164)], "hips", PANTS, sides=14)
    # Torso de camiseta (hombros 0,6 con los brazos) y cuello redondo marino.
    zs = (0.66, 0.80, 0.92, 1.04, 1.13)
    b.loft([((0, 0, z), *torso_profile(z)) for z in zs], "spine", SHIRT, sides=14, cap_bottom=False)
    b.loft([((0, 0, 1.115), 0.118, 0.098), ((0, 0, 1.145), 0.104, 0.088)], "spine", PANTS, sides=12, cap_top=False, cap_bottom=False)
    b.loft([((0, 0, 1.10), 0.06, 0.058), ((0, 0, 1.18), 0.064, 0.062)], "head", SKIN, sides=8)

    # Delantal: peto sobre el pecho y falda por delante de los muslos (color del jugador),
    # cinta de cintura marina con lazo detrás y tiras al cuello; bolsillo brand_red.
    def peto(z):
        rx, ry = torso_profile(z)
        return 0.0, 0.0, rx + 0.016, ry + 0.016

    b.shell(0.70, 1.00, 48, 132, peto, "spine", ACCENT, cols=8, rows=3, thick=0.02)

    def skirt(z):
        t = (0.69 - z) / 0.33  # 0 en la cintura, 1 abajo: se abre un poco
        return 0.0, 0.0, 0.222 + 0.03 * t, 0.182 + 0.05 * t

    b.shell(0.36, 0.69, 28, 152, skirt, "hips", ACCENT, cols=12, rows=3, thick=0.02)
    b.shell(0.68, 0.73, 0, 360, lambda z: (0.0, 0.0, 0.224, 0.184), "hips", PANTS, cols=24, rows=1, thick=0.02)

    def pocket(z):
        cx, cy, rx, ry = skirt(z)
        return cx, cy, rx + 0.012, ry + 0.012

    b.shell(0.46, 0.58, 70, 110, pocket, "hips", RED, cols=4, rows=1, thick=0.014)
    for x in (0.05, -0.05):  # lazo de la cinta, detrás
        b.blob((x, -0.2, 0.70), (0.045, 0.02, 0.03), "hips", PANTS, segs=8, rings=5)
    b.box((0.0, -0.205, 0.70), (0.03, 0.02, 0.035), "hips", PANTS)
    for x in (0.12, -0.12):  # tiras del peto al cuello
        top = Vector((x * 0.6, 0.06, 1.15))
        b.tube((x, torso_profile(1.0)[1] + 0.025, 0.995), top, [0.016, 0.016], "spine", PANTS, sides=6)
    b.tube((0.072, 0.06, 1.15), (-0.072, 0.06, 1.15), [0.016, 0.016], "spine", PANTS, sides=6)
    # Logo del peto: símbolo + logotipo en brand_paper (art-bible §7), plano sobre el frente.
    peto_y = torso_profile(0.86)[1] + 0.016 + 0.004
    b.decal((0.0, peto_y, 0.86), (0, 1, -0.02), (0, 0, 1), 0.15, 0.15, "spine", ATLAS_APRON)

    # Cabeza grande: piel, orejas, nariz, ojos, cejas, boca y pelo detrás y a los lados.
    b.blob(HEAD_C, HEAD_R, "head", SKIN, segs=16, rings=10)
    for x in (0.228, -0.228):
        b.blob((x, -0.005, 1.36), (0.03, 0.045, 0.055), "head", SKIN, segs=8, rings=5)
    b.blob((0, 0.218, 1.335), (0.042, 0.036, 0.04), "head", SKIN, segs=8, rings=5)
    for x in (0.08, -0.08):
        b.blob((x, 0.198, 1.40), (0.024, 0.016, 0.036), "head", DARK, segs=8, rings=5)
        b.box((x, 0.2, 1.46), (0.06, 0.02, 0.018), "head", HAIR, rot=Euler((0.35, 0, math.copysign(0.12, -x))).to_matrix())
    b.box((0, 0.206, 1.272), (0.06, 0.014, 0.01), "head", DARK, rot=Euler((0.45, 0, 0)).to_matrix())

    def hair_keep(f):
        c = f.calc_center_median()
        return c.z > 1.22 and (c.y < 0.04 or c.z > 1.50)

    b.blob(HEAD_C + Vector((0, -0.012, 0.025)), (0.246, 0.232, 0.228), "head", HAIR, segs=16, rings=10, keep=hair_keep)
    return b.to_mesh("cook_body"), b.groups


def head_point(theta_up_deg, r_scale=1.0, lift=0.0):
    """Punto del frente (+Y) de la cabeza a una elevación dada, para apoyar calcas."""
    t = math.radians(theta_up_deg)
    return Vector((0.0, HEAD_R[1] * math.cos(t) * r_scale, HEAD_C.z + lift + HEAD_R[2] * math.sin(t) * r_scale))


def build_hat(variant: str) -> tuple:
    b = Builder()
    if variant == "j1":
        # Gorra de visera (rasgo J1): copa redonda del color del jugador, banda, botón y visera
        # brand_red hacia delante (§2.7, §6.5) e insignia compacta en el frontal (§7).
        crown_c = Vector((0.0, -0.01, 1.47))
        b.blob(crown_c, (0.252, 0.246, 0.215), "head", ACCENT, segs=16, rings=10, keep=lambda f: f.calc_center_median().z > crown_c.z + 0.001)
        b.loft([((0, -0.01, 1.43), 0.253, 0.247), ((0, -0.01, 1.475), 0.256, 0.25)], "head", ACCENT, sides=16, cap_top=False, cap_bottom=False)
        b.blob((0, -0.01, 1.685), (0.03, 0.03, 0.016), "head", RED, segs=8, rings=4)

        # Visera: media luna de 2 cm que sale ≈ 0,15 m de la frente, inclinada 8° hacia abajo.
        visor = b.shell(1.445, 1.463, 32, 148, lambda z: (0.0, 0.05, 0.225, 0.31), "head", RED, cols=12, rows=1, thick=0.14)
        hinge = Vector((0.0, 0.2, 1.454))
        tilt = Matrix.Translation(hinge) @ Matrix.Rotation(math.radians(-8), 4, "X") @ Matrix.Translation(-hinge)
        bmesh.ops.transform(b.bm, matrix=tilt, verts=list({v for f in visor for v in f.verts}))
        a = math.radians(32)
        n = Vector((0, math.cos(a) / 0.246, math.sin(a) / 0.215)).normalized()
        p = crown_c + Vector((0, 0.246 * math.cos(a), 0.215 * math.sin(a))) + n * 0.006
        b.decal(p, n, (0, 0, 1), 0.10, 0.10, "head", ATLAS_BADGE)
    else:
        # Gorro alto (rasgo J2): banda marina con la insignia y copa abombada del color del jugador.
        b.loft([((0, -0.005, 1.43), 0.248, 0.236), ((0, -0.005, 1.545), 0.246, 0.234)], "head", PANTS, sides=16, cap_bottom=False, cap_top=False)
        b.loft([((0, -0.005, 1.54), 0.236, 0.224), ((0, -0.005, 1.62), 0.25, 0.238), ((0, -0.005, 1.74), 0.282, 0.27), ((0, -0.005, 1.83), 0.27, 0.258), ((0, -0.005, 1.89), 0.2, 0.19), ((0, -0.005, 1.915), 0.08, 0.075)], "head", ACCENT, sides=16, cap_bottom=False)
        b.decal((0.0, 0.234 - 0.005 + 0.006, 1.488), (0, 1, 0), (0, 0, 1), 0.10, 0.10, "head", ATLAS_BADGE)
    return b.to_mesh(f"cook_hat_{variant}"), b.groups


def build_rig(root, coll):
    arm = bpy.data.armatures.new("cook_rig")
    rig = bpy.data.objects.new("cook_rig", arm)
    rig.parent = root
    coll.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    for o in bpy.context.selected_objects:
        o.select_set(False)
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent) in BONES.items():
        eb = arm.edit_bones.new(name)
        eb.head, eb.tail = head, tail
        eb.roll = 0.0
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = False
        eb.use_deform = name != "root"
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
    return rig


def add_object(name, mesh, groups, variant, rig, coll):
    ob = bpy.data.objects.new(name, mesh)
    coll.objects.link(ob)
    for i, m in enumerate(VARIANT_MATS[variant]):
        if i < len(mesh.materials):
            mesh.materials[i] = M[m]
        else:
            mesh.materials.append(M[m])
    for g in groups:
        if g not in ob.vertex_groups:
            ob.vertex_groups.new(name=g)
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    ob.parent = rig
    return ob


# --- Animación: idéntica a PUL-044 (build_cook.py) ------------------------------------------------

def fwd(deg):
    return math.radians(deg)


HOLD_POSE = {
    "upper_arm.L": (fwd(76), math.radians(-8), 0.0),
    "upper_arm.R": (fwd(76), math.radians(8), 0.0),
    "forearm.L": (fwd(22), 0.0, 0.0),
    "forearm.R": (fwd(22), 0.0, 0.0),
}


def key_pose(rig, frame, pose, hips_z=0.0):
    for pb in rig.pose.bones:
        pb.rotation_euler = Euler(pose.get(pb.name, (0.0, 0.0, 0.0)), "XYZ")
        pb.keyframe_insert("rotation_euler", frame=frame)
        if pb.name == "hips":
            pb.location = (0.0, hips_z, 0.0)
            pb.keyframe_insert("location", frame=frame)


def new_action(rig, name):
    old = bpy.data.actions.get(name)
    if old is not None:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    return act


def merge(*poses):
    out = {}
    for p in poses:
        for k, v in p.items():
            base = out.get(k, (0.0, 0.0, 0.0))
            out[k] = tuple(a + b for a, b in zip(base, v))
    return out


def legs(phase):
    s = math.sin(phase)
    return {
        "thigh.L": (fwd(28 * s), 0, 0),
        "thigh.R": (fwd(-28 * s), 0, 0),
        "shin.L": (fwd(-max(0.0, 40 * math.sin(phase - 1.2))), 0, 0),
        "shin.R": (fwd(-max(0.0, -40 * math.sin(phase - 1.2))), 0, 0),
        "spine": (fwd(-5), math.radians(5 * s), 0),
    }


def build_actions(rig):
    acts = {}
    acts["Idle"] = new_action(rig, "Idle")
    for f in range(0, 37, 6):
        t = 2 * math.pi * f / 36
        key_pose(rig, f, {
            "spine": (fwd(-1.5 * math.sin(t)), 0, 0),
            "head": (fwd(2 * math.sin(t)), math.radians(3 * math.sin(t)), 0),
            "upper_arm.L": (fwd(3 * math.sin(t)), 0, 0),
            "upper_arm.R": (fwd(3 * math.sin(t)), 0, 0),
        }, hips_z=0.008 * math.sin(t))
    acts["IdleHolding"] = new_action(rig, "IdleHolding")
    for f in range(0, 37, 6):
        t = 2 * math.pi * f / 36
        key_pose(rig, f, merge(HOLD_POSE, {
            "spine": (fwd(-1.5 * math.sin(t)), 0, 0),
            "head": (fwd(2 * math.sin(t)), 0, 0),
        }), hips_z=0.008 * math.sin(t))
    acts["Walk"] = new_action(rig, "Walk")
    for f in range(0, 21, 2):
        t = 2 * math.pi * f / 20
        s = math.sin(t)
        key_pose(rig, f, merge(legs(t), {
            "upper_arm.L": (fwd(-32 * s), 0, 0),
            "upper_arm.R": (fwd(32 * s), 0, 0),
            "forearm.L": (fwd(14), 0, 0),
            "forearm.R": (fwd(14), 0, 0),
        }), hips_z=0.035 * abs(math.cos(t)))
    acts["WalkWhileHolding"] = new_action(rig, "WalkWhileHolding")
    for f in range(0, 21, 2):
        t = 2 * math.pi * f / 20
        key_pose(rig, f, merge(legs(t), HOLD_POSE), hips_z=0.035 * abs(math.cos(t)))
    acts["Pick"] = new_action(rig, "Pick")
    reach = {
        "spine": (fwd(-30), 0, 0),
        "head": (fwd(14), 0, 0),
        "upper_arm.L": (fwd(55), math.radians(-8), 0),
        "upper_arm.R": (fwd(55), math.radians(8), 0),
        "thigh.L": (fwd(35), 0, 0),
        "thigh.R": (fwd(35), 0, 0),
        "shin.L": (fwd(-60), 0, 0),
        "shin.R": (fwd(-60), 0, 0),
    }
    key_pose(rig, 0, {})
    key_pose(rig, 4, reach, hips_z=-0.065)
    key_pose(rig, 7, merge(HOLD_POSE, {"spine": (fwd(-10), 0, 0)}), hips_z=-0.02)
    key_pose(rig, 12, HOLD_POSE)
    acts["Cut"] = new_action(rig, "Cut")
    chop = merge(HOLD_POSE, {
        "spine": (fwd(-8), 0, 0),
        "head": (fwd(-6), 0, 0),
        "upper_arm.R": (fwd(40), 0, 0),
        "forearm.R": (fwd(50), 0, 0),
    })
    down = merge(HOLD_POSE, {
        "spine": (fwd(-14), 0, 0),
        "head": (fwd(-10), 0, 0),
        "upper_arm.R": (fwd(-18), 0, 0),
        "forearm.R": (fwd(4), 0, 0),
    })
    key_pose(rig, 0, HOLD_POSE)
    key_pose(rig, 2, chop, hips_z=0.01)
    key_pose(rig, 4, down, hips_z=-0.02)
    key_pose(rig, 9, HOLD_POSE)
    rig.animation_data.action = acts["Idle"]
    return acts


def build_all():
    atlas_material()
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("cook") or bpy.data.objects["asset"]
    root.name = "cook"
    for nm in ("cook_body_j1", "cook_body_j2", "cook_hat_j1", "cook_hat_j2", "cook_rig", "Anchor_Hold"):
        remove_object(nm)
    for me in ("cook_body", "cook_body_j1", "cook_body_j2", "cook_hat_j1", "cook_hat_j2"):
        if bpy.data.meshes.get(me):
            bpy.data.meshes.remove(bpy.data.meshes[me])
    bpy.data.objects["Anchor_Front"].parent = root

    rig = build_rig(root, coll)
    body, body_groups = build_body()
    for v in ("j1", "j2"):
        # El exportador glTF ignora los materiales del objeto: cada variante copia la malla.
        mesh = body if v == "j1" else body.copy()
        mesh.name = f"cook_body_{v}"
        add_object(f"cook_body_{v}", mesh, body_groups, v, rig, coll)
        hat, hat_groups = build_hat(v)
        add_object(f"cook_hat_{v}", hat, hat_groups, v, rig, coll)
    hold = bpy.data.objects.new("Anchor_Hold", None)
    hold.empty_display_type = "SPHERE"
    hold.empty_display_size = 0.03
    hold.location = HOLD_POINT
    hold.parent = root
    coll.objects.link(hold)
    acts = build_actions(rig)
    bpy.context.scene.render.fps = FPS
    return rig, acts
