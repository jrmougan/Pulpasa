"""Geometría, rig y clips de art/blender/cook.blend (PUL-044), generados por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-044/build_cook.py").read(), ns); ns["build_all"]()

Crea en la colección `export` la raíz `cook` con el esqueleto `cook_rig` (13 huesos, sin dedos) y
cuatro mallas con skin rígido (cada pieza pesa 1 en un hueso): `cook_body_j1` y `cook_body_j2`
salen de la misma geometría y el mismo rig y solo cambian los materiales (art-bible §2.6, J1 azul /
J2 ámbar y piel; el glTF no admite materiales por objeto, así que J2 lleva una copia de la malla); `cook_hat_j1` (gorro redondo) y `cook_hat_j2` (gorro alto de
cocinero) dan el tercer rasgo para daltónicos (§3.1.6). Godot muestra el par de la variante según
`player_index`. `Anchor_Hold` marca, entre las manos de la pose de llevar, dónde va `%HoldPoint`.
Clips (30 fps): Idle (bucle 1,2 s), Walk, IdleHolding, WalkWhileHolding, Pick y Cut (ciclo de
0,3 s, D13). Mismas convenciones que build_octopus.py (PUL-045). Se versiona como registro
reproducible.
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

M = bpy.data.materials

# (nombre, hex) de la tabla «Personajes» de art-bible §2.6; los comunes valen para J1 y J2.
PALETTE = {
    "mat_cook_j1_accent": "#2F6FB5",
    "mat_cook_j2_accent": "#E0A02E",
    "mat_cook_shirt": "#F7F4EC",
    "mat_cook_trousers": "#4A4F63",
    "mat_cook_j1_skin": "#EBC49A",
    "mat_cook_j2_skin": "#A8734D",
}
# Índices de material de la malla: 0 acento (delantal/gorro), 1 camisa, 2 pantalón, 3 piel,
# 4 zapatos y ojos (iron_black), 5 pelo (wood_dark). Total 6 colores por variante (§2.6).
ACCENT, SHIRT, TROUSERS, SKIN, DARK, HAIR = range(6)
VARIANT_MATS = {
    "j1": ["mat_cook_j1_accent", "mat_cook_shirt", "mat_cook_trousers", "mat_cook_j1_skin", "mat_iron_black", "mat_wood_dark"],
    "j2": ["mat_cook_j2_accent", "mat_cook_shirt", "mat_cook_trousers", "mat_cook_j2_skin", "mat_iron_black", "mat_wood_dark"],
}

# Esqueleto en reposo (Blender: Z arriba, frente +Y). Brazos colgando, piernas rectas.
SHOULDER_X, SHOULDER_Z = 0.25, 1.06
HIP_X = 0.105
BONES = {
    # nombre: (cabeza, cola, padre)
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
# Marcador de agarre: entre las manos de la pose de llevar (IdleHolding), a la altura de las
# manos y delante del delantal, para que pulpo ×1,4 y plato grande no entren en la cápsula.
HOLD_POINT = (0.0, 0.56, 0.86)
# El exportador glTF usa t = fotograma / fps: los clips empiezan en el fotograma 0.
FPS = 30


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def palette_material(name: str, hex_color: str) -> bpy.types.Material:
    mat = M.get(name) or M.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    rgb = [srgb_to_linear(int(hex_color[i : i + 2], 16) / 255) for i in (1, 3, 5)]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = (*rgb, 1.0)
    mat.use_fake_user = True
    return mat


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if isinstance(data, (bpy.types.Mesh, bpy.types.Armature)) and data.users == 0:
        (bpy.data.meshes if isinstance(data, bpy.types.Mesh) else bpy.data.armatures).remove(data)


class Builder:
    """Acumula piezas low-poly en un bmesh; cada vértice pesa 1 en el hueso de su pieza."""

    def __init__(self):
        self.bm = bmesh.new()
        self.deform = self.bm.verts.layers.deform.new()
        self.groups: list[str] = []

    def _group(self, bone: str) -> int:
        if bone not in self.groups:
            self.groups.append(bone)
        return self.groups.index(bone)

    def _tag(self, verts, bone):
        g = self._group(bone)
        for v in verts:
            v[self.deform][g] = 1.0

    def loft(self, sections, bone, mat, sides=8, cap_top=True, cap_bottom=True, smooth=True, mat_fn=None):
        """Sólido por secciones elípticas [(centro, rx, ry), ...] de abajo arriba (eje Z)."""
        rings = []
        for c, rx, ry in sections:
            c = Vector(c)
            rings.append([self.bm.verts.new(c + Vector((rx * math.cos(2 * math.pi * k / sides + math.pi / sides), ry * math.sin(2 * math.pi * k / sides + math.pi / sides), 0))) for k in range(sides)])
        faces = []
        for i in range(len(rings) - 1):
            lo, hi = rings[i], rings[i + 1]
            for k in range(sides):
                f = self.bm.faces.new((lo[k], lo[(k + 1) % sides], hi[(k + 1) % sides], hi[k]))
                f.material_index = mat_fn(i, k) if mat_fn else mat
                f.smooth = smooth
                faces.append(f)
        if cap_bottom:
            f = self.bm.faces.new(list(reversed(rings[0])))
            f.material_index = mat
            faces.append(f)
        if cap_top:
            f = self.bm.faces.new(rings[-1])
            f.material_index = mat_fn(len(rings) - 2, 0) if mat_fn else mat
            faces.append(f)
        self._tag([v for r in rings for v in r], bone)
        return faces

    def tube(self, a, b, radii, bone, mat, sides=6, mat_fn=None):
        """Cilindro de `a` a `b` (eje arbitrario) con radios por sección."""
        a, b = Vector(a), Vector(b)
        axis = (b - a).normalized()
        rot = Vector((0, 0, 1)).rotation_difference(axis).to_matrix().to_4x4()
        n = len(radii)
        secs = [((0, 0, (b - a).length * i / (n - 1)), r, r) for i, r in enumerate(radii)]
        faces = self.loft(secs, bone, mat, sides=sides, mat_fn=mat_fn)
        verts = {v for f in faces for v in f.verts}
        bmesh.ops.transform(self.bm, matrix=Matrix.Translation(a) @ rot, verts=list(verts))
        return faces

    def blob(self, centre, radii, bone, mat, segs=10, rings=7, mat_fn=None, smooth=True):
        """Elipsoide UV low-poly; `mat_fn(normal)` elige material por cara."""
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=1.0)
        verts = res["verts"]
        bmesh.ops.transform(self.bm, matrix=Matrix.Translation(centre) @ Matrix.Diagonal((*radii, 1.0)), verts=verts)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            f.material_index = mat_fn(f) if mat_fn else mat
            f.smooth = smooth
        self._tag(verts, bone)
        return faces

    def box(self, centre, size, bone, mat):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        bmesh.ops.transform(self.bm, matrix=Matrix.Translation(centre) @ Matrix.Diagonal((*size, 1.0)), verts=verts)
        for f in {f for v in verts for f in v.link_faces}:
            f.material_index = mat
            f.smooth = False
        self._tag(verts, bone)

    def to_mesh(self, name):
        self.bm.normal_update()
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        me = bpy.data.meshes.get(name) or bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        return me


def build_body() -> tuple:
    b = Builder()
    for side, x in (("L", HIP_X), ("R", -HIP_X)):
        # Pierna: muslo y espinilla de pantalón; zapato oscuro que asoma hacia delante.
        b.tube((x, 0, 0.60), (x, 0, 0.29), [0.1, 0.094, 0.088], f"thigh.{side}", TROUSERS)
        b.tube((x, 0, 0.32), (x, 0, 0.07), [0.088, 0.082, 0.08], f"shin.{side}", TROUSERS)
        b.loft([((x, 0.035, 0.0), 0.085, 0.13), ((x, 0.035, 0.06), 0.082, 0.125), ((x, 0.02, 0.10), 0.07, 0.09)], f"shin.{side}", DARK, sides=8, smooth=False)
        sx = SHOULDER_X if side == "L" else -SHOULDER_X
        d = 1 if side == "L" else -1
        # Brazo: manga de camisa arriba, antebrazo remangado (piel), mano redonda.
        b.blob((sx + 0.005 * d, 0, SHOULDER_Z - 0.01), (0.088, 0.088, 0.088), f"upper_arm.{side}", SHIRT, segs=8, rings=5)
        b.tube((sx, 0, SHOULDER_Z), (sx + 0.03 * d, 0, 0.82), [0.08, 0.072], f"upper_arm.{side}", SHIRT)
        b.tube((sx + 0.03 * d, 0, 0.84), (sx + 0.04 * d, 0, 0.62), [0.062, 0.056], f"forearm.{side}", SKIN)
        b.blob((sx + 0.042 * d, 0.005, 0.58), (0.07, 0.072, 0.078), f"forearm.{side}", SKIN, segs=8, rings=5)
    # Cadera (pantalón) y fajín del delantal, que se ve también de espaldas.
    b.loft([((0, 0, 0.50), 0.19, 0.15), ((0, 0, 0.60), 0.205, 0.165), ((0, 0, 0.66), 0.205, 0.165)], "hips", TROUSERS, sides=10)
    b.loft([((0, 0, 0.64), 0.212, 0.172), ((0, 0, 0.72), 0.215, 0.175)], "hips", ACCENT, sides=10, cap_top=False, cap_bottom=False)
    # Torso de camisa, ancho de hombros 0,6 con los brazos (§2.1).
    # El peto del delantal son las caras frontales (+Y) del torso por debajo del pecho.
    def bib(i, k):
        angle = 2 * math.pi * (k + 0.5) / 10 + math.pi / 10
        return ACCENT if i < 2 and math.sin(angle) > 0.45 else SHIRT

    b.loft([((0, 0, 0.68), 0.2, 0.16), ((0, 0, 0.88), 0.215, 0.17), ((0, 0, 1.04), 0.225, 0.165), ((0, 0, 1.12), 0.16, 0.12)], "spine", SHIRT, sides=10, mat_fn=bib)
    # Falda del delantal: solo por delante de los muslos, algo acampanada.
    b.loft([((0, 0.075, 0.40), 0.215, 0.115), ((0, 0.07, 0.56), 0.205, 0.105), ((0, 0.06, 0.68), 0.19, 0.11)], "hips", ACCENT, sides=10)
    # Cabeza grande (§1.1.4): esfera achatada de piel, nariz, ojos y pelo detrás.
    b.loft([((0, 0, 1.08), 0.06, 0.06), ((0, 0, 1.16), 0.065, 0.065)], "head", SKIN, sides=6)
    b.blob((0, 0.0, 1.37), (0.235, 0.22, 0.23), "head", SKIN, segs=12, rings=8)
    b.blob((0, 0.215, 1.34), (0.04, 0.04, 0.04), "head", SKIN, segs=6, rings=4)
    for x in (0.085, -0.085):
        b.box((x, 0.205, 1.41), (0.035, 0.03, 0.06), "head", DARK)

    def hair(f):
        c = f.calc_center_median()
        return HAIR if c.y < 0.06 and c.z > 1.24 else SKIN

    b.blob((0, -0.025, 1.40), (0.245, 0.22, 0.225), "head", HAIR, segs=12, rings=8, mat_fn=hair)
    return b.to_mesh("cook_body"), b.groups


def build_hat(variant: str) -> tuple:
    b = Builder()
    if variant == "j1":
        # Gorro redondo: casquete bajo con banda.
        b.loft([((0, 0, 1.50), 0.25, 0.235), ((0, 0, 1.56), 0.255, 0.24)], "head", ACCENT, sides=12, cap_top=False, cap_bottom=False)
        b.blob((0, 0, 1.55), (0.245, 0.235, 0.215), "head", ACCENT, segs=12, rings=6)
    else:
        # Gorro alto de cocinero: banda y copa abombada (≈ 1,9 m de alto total).
        b.loft([((0, 0, 1.50), 0.24, 0.225), ((0, 0, 1.60), 0.235, 0.22), ((0, 0, 1.66), 0.22, 0.21), ((0, 0, 1.80), 0.25, 0.24), ((0, 0, 1.87), 0.20, 0.19), ((0, 0, 1.90), 0.10, 0.10)], "head", ACCENT, sides=12, cap_bottom=False)
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


def skin(ob, groups, rig):
    for g in groups:
        if g not in ob.vertex_groups:
            ob.vertex_groups.new(name=g)
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    ob.parent = rig


def add_object(name, mesh, groups, variant, rig, coll):
    ob = bpy.data.objects.new(name, mesh)
    coll.objects.link(ob)
    # Se sustituyen por índice: `materials.clear()` reiniciaría el material_index de las caras.
    for i, m in enumerate(VARIANT_MATS[variant]):
        if i < len(mesh.materials):
            mesh.materials[i] = M[m]
        else:
            mesh.materials.append(M[m])
    skin(ob, groups, rig)
    return ob


# --- Animación ---------------------------------------------------------------------------------

# Ejes (roll 0): el eje X local de todos los huesos es el X del mundo. En los huesos que cuelgan
# (brazos, piernas) un giro X positivo lleva la punta hacia delante (+Y); en los que suben (spine,
# head) un giro X negativo inclina hacia delante. En un brazo levantado, Y negativo lo cierra hacia −X.
def fwd(deg):
    return math.radians(deg)


# Pose de llevar: brazos hacia delante casi horizontales, antebrazos algo arriba y hacia dentro.
HOLD_POSE = {
    "upper_arm.L": (fwd(70), math.radians(-14), 0.0),
    "upper_arm.R": (fwd(70), math.radians(14), 0.0),
    "forearm.L": (fwd(12), 0.0, 0.0),
    "forearm.R": (fwd(12), 0.0, 0.0),
}


def key_pose(rig, frame, pose, hips_z=0.0):
    for pb in rig.pose.bones:
        rot = pose.get(pb.name, (0.0, 0.0, 0.0))
        pb.rotation_euler = Euler(rot, "XYZ")
        pb.keyframe_insert("rotation_euler", frame=frame)
        if pb.name == "hips":
            pb.location = (0.0, hips_z, 0.0)  # eje Y del hueso = arriba
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
    """Zancada: muslos ±28°, la rodilla se dobla hacia atrás en la pierna que se recoge."""
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
    # Idle: bucle de 36 fotogramas (1,2 s), respiración y balanceo leve de brazos y cabeza.
    acts["Idle"] = new_action(rig, "Idle")
    for f in range(0, 37, 6):
        t = 2 * math.pi * f / 36
        key_pose(rig, f, {
            "spine": (fwd(-1.5 * math.sin(t)), 0, 0),
            "head": (fwd(2 * math.sin(t)), math.radians(3 * math.sin(t)), 0),
            "upper_arm.L": (fwd(3 * math.sin(t)), 0, 0),
            "upper_arm.R": (fwd(3 * math.sin(t)), 0, 0),
        }, hips_z=0.008 * math.sin(t))
    # IdleHolding: misma respiración con los brazos en pose de llevar.
    acts["IdleHolding"] = new_action(rig, "IdleHolding")
    for f in range(0, 37, 6):
        t = 2 * math.pi * f / 36
        key_pose(rig, f, merge(HOLD_POSE, {
            "spine": (fwd(-1.5 * math.sin(t)), 0, 0),
            "head": (fwd(2 * math.sin(t)), 0, 0),
        }), hips_z=0.008 * math.sin(t))
    # Walk: ciclo de 20 fotogramas (0,67 s; a 5 m/s ≈ 3,3 m por ciclo, dos pasos exagerados).
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
    # WalkWhileHolding: piernas del Walk, brazos fijos en la pose de llevar.
    acts["WalkWhileHolding"] = new_action(rig, "WalkWhileHolding")
    for f in range(0, 21, 2):
        t = 2 * math.pi * f / 20
        key_pose(rig, f, merge(legs(t), HOLD_POSE), hips_z=0.035 * abs(math.cos(t)))
    # Pick: 12 fotogramas (0,4 s), se agacha a coger y acaba en la pose de llevar.
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
    # Cut: 9 fotogramas (0,3 s), un golpe de cuchillo hacia abajo por pulsación (D13).
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
    for act in acts.values():
        act.use_fake_user = True
    rig.animation_data.action = acts["Idle"]
    return acts


def build_all():
    for name, hx in PALETTE.items():
        palette_material(name, hx)
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
        # El exportador glTF ignora los materiales enlazados al objeto: cada variante lleva una
        # copia idéntica de la malla (misma geometría, grupos y rig) con sus materiales.
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
