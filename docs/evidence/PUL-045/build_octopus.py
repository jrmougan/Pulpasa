"""Geometría de art/blender/octopus.blend (PUL-045), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-045/build_octopus.py").read(), ns); ns["build_all"]()
Crea `octopus` (octopus_raw + octopus_cooked) en la colección `export` y `octopus_pieces`
(capas a/b/c de rodajas) en la colección `export_pieces`. Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def palette_material(name: str, hex_color: str, roughness: float) -> bpy.types.Material:
    """Material de color plano con el hex exacto (art-bible §2.5), como los mat_* de la plantilla."""
    mat = M.get(name) or M.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    rgb = [srgb_to_linear(int(hex_color[i : i + 2], 16) / 255) for i in (1, 3, 5)]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = (*rgb, 1.0)
    mat.use_fake_user = True
    return mat


def add_tube(bm, pts, radii, sides, dark_idx, body_idx, twists=None):
    """Tubo de `sides` caras con marcos de rotación mínima; la cara ventral (−N) lleva ventosas."""
    n = len(pts)
    tangents = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
    N = Vector((0, 0, 1))
    N = (N - N.dot(tangents[0]) * tangents[0]).normalized()
    rings = []
    for i in range(n):
        T = tangents[i]
        N = (N - N.dot(T) * T).normalized()
        B = T.cross(N)
        tw = twists[i] if twists else 0.0
        ring = []
        for k in range(sides):
            th = math.pi - math.pi / sides + 2 * math.pi * k / sides + tw
            ring.append(bm.verts.new(pts[i] + radii[i] * (math.cos(th) * N + math.sin(th) * B)))
        rings.append(ring)
    for i in range(n - 1):
        for k in range(sides):
            f = bm.faces.new((rings[i][k], rings[i][(k + 1) % sides], rings[i + 1][(k + 1) % sides], rings[i + 1][k]))
            f.material_index = dark_idx if k == 0 else body_idx
            f.smooth = True
    tip = bm.verts.new(pts[-1] + tangents[-1] * radii[-1] * 1.5)
    for k in range(sides):
        f = bm.faces.new((rings[-1][k], rings[-1][(k + 1) % sides], tip))
        f.material_index = dark_idx if k == 0 else body_idx
        f.smooth = True


def add_ellipsoid(bm, center, radii, segs, rings, mat_idx, tilt=0.0):
    rot = Matrix.Rotation(tilt, 3, "X")
    top = bm.verts.new(center + rot @ Vector((0, 0, radii[2])))
    bot = bm.verts.new(center + rot @ Vector((0, 0, -radii[2])))
    rr = []
    for j in range(1, rings):
        phi = math.pi * j / rings
        ring = []
        for k in range(segs):
            th = 2 * math.pi * k / segs + math.pi / 2
            p = Vector((radii[0] * math.sin(phi) * math.cos(th), radii[1] * math.sin(phi) * math.sin(th), radii[2] * math.cos(phi)))
            ring.append(bm.verts.new(center + rot @ p))
        rr.append(ring)
    fs = []
    for k in range(segs):
        fs.append(bm.faces.new((top, rr[0][k], rr[0][(k + 1) % segs])))
        fs.append(bm.faces.new((bot, rr[-1][(k + 1) % segs], rr[-1][k])))
    for j in range(len(rr) - 1):
        for k in range(segs):
            fs.append(bm.faces.new((rr[j][k], rr[j + 1][k], rr[j + 1][(k + 1) % segs], rr[j][(k + 1) % segs])))
    for f in fs:
        f.material_index = mat_idx
        f.smooth = True


def add_eye(bm, pos, normal, r_white, r_pupil, white_idx, pupil_idx):
    n = normal.normalized()
    t = n.cross(Vector((0, 0, 1))).normalized()
    b = n.cross(t)

    def disk(c, r, idx, bulge):
        center = bm.verts.new(c + n * bulge)
        ring = [bm.verts.new(c + r * (math.cos(2 * math.pi * k / 6) * t + math.sin(2 * math.pi * k / 6) * b)) for k in range(6)]
        for k in range(6):
            f = bm.faces.new((center, ring[k], ring[(k + 1) % 6]))
            f.material_index = idx
            f.smooth = False

    disk(pos, r_white, white_idx, r_white * 0.45)
    disk(pos + n * (r_white * 0.42) + b * (-0.004), r_pupil, pupil_idx, r_pupil * 0.3)


def ellipsoid_point(radii, d, tilt=0.0):
    d = d.normalized()
    s = 1.0 / math.sqrt((d.x / radii[0]) ** 2 + (d.y / radii[1]) ** 2 + (d.z / radii[2]) ** 2)
    p = d * s
    n = Vector((p.x / radii[0] ** 2, p.y / radii[1] ** 2, p.z / radii[2] ** 2)).normalized()
    rot = Matrix.Rotation(tilt, 3, "X")
    return rot @ p, rot @ n


def build_whole(parent, coll, name, state):
    me = bpy.data.meshes.new(name)
    for m in (f"mat_octopus_{state}", f"mat_octopus_{state}_dark", "mat_salt", "mat_iron_black"):
        me.materials.append(M[m])
    bm = bmesh.new()
    angles = [math.radians(22.5 + 45 * i) for i in range(8)]
    if state == "raw":
        # Patas lacias y extendidas en el suelo; las puntas se doblan y enseñan las ventosas.
        mc, mr, tilt = Vector((0, -0.03, 0.10)), (0.11, 0.125, 0.09), math.radians(-12)
        for i, a in enumerate(angles):
            u = Vector((math.cos(a), math.sin(a), 0))
            v = Vector((-math.sin(a), math.cos(a), 0))
            length = 0.17 + 0.02 * ((i * 3) % 4) / 3
            side = 1 if i % 2 else -1
            pts, radii, tw = [], [], []
            for j in range(6):
                t = j / 5
                s = 0.05 + length * t
                h = 0.034 * (1 - t) + 0.012 * t + 0.03 * max(0, t - 0.6) ** 2 * 6
                w = 0.025 * math.sin(t * math.pi * 1.4 + i)
                pts.append(u * s + v * w + Vector((0, 0, h)))
                radii.append(0.036 * (1 - t) + 0.012 * t)
                tw.append(side * math.radians(150) * max(0.0, t - 0.25) / 0.75)
            add_tube(bm, pts, radii, 4, 1, 0, tw)
    else:
        # Cuerpo más pequeño, patas enroscadas hacia arriba (ventosas por fuera del rizo).
        mc, mr, tilt = Vector((0, -0.01, 0.135)), (0.085, 0.09, 0.11), math.radians(8)
        for i, a in enumerate(angles):
            u = Vector((math.cos(a), math.sin(a), 0))
            v = Vector((-math.sin(a), math.cos(a), 0))
            r0 = 0.068 + 0.008 * (i % 2)
            start, straight = 0.045, 0.095
            pts = [u * start + Vector((0, 0, 0.03))]
            radii = [0.033]
            nseg = 7
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
            add_tube(bm, pts, radii, 4, 1, 0)
    add_ellipsoid(bm, mc, mr, 8, 5, 0, tilt)
    for sx in (-1, 1):
        p, n = ellipsoid_point(mr, Vector((0.38 * sx, 1.0, 0.25)), tilt)
        add_eye(bm, mc + p, n, 0.03, 0.016, 2, 3)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    me = ob.data if ob.type == "MESH" else None
    bpy.data.objects.remove(ob)
    if me is not None and me.users == 0:
        bpy.data.meshes.remove(me)


def rebuild_whole():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("octopus") or bpy.data.objects["asset"]
    root.name = "octopus"
    M["mat_octopus_raw"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    M["mat_octopus_raw_dark"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    M["mat_octopus_cooked"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.5
    M["mat_octopus_cooked_dark"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.5
    for nm in ("octopus_raw", "octopus_cooked"):
        remove_object(nm)
    return build_whole(root, coll, "octopus_raw", "raw"), build_whole(root, coll, "octopus_cooked", "cooked")


# Rodajas «á feira» (art-bible §3.2): ≈ 0,05 m, piel #D4506A y corte #F4C6CC. Tres capas
# (a, b, c) para el relleno progresivo de la caja (PUL-047: vacía, a medias, llena).
PIECE_LAYERS = {
    "a": [(0.0, 0.0), (0.075, 0.02), (-0.07, 0.035), (0.02, 0.08), (-0.03, -0.075), (0.065, -0.06), (-0.085, -0.03)],
    "b": [(0.035, 0.03), (-0.04, 0.04), (0.0, -0.04), (0.06, -0.015), (-0.055, -0.03)],
    "c": [(0.0, 0.01), (0.03, -0.035), (-0.03, -0.01)],
}
PIECE_BASE_Z = {"a": 0.0, "b": 0.018, "c": 0.036}


def add_slice(bm, center, radius, thick, tilt_axis, tilt, skin_idx, cut_idx, sides=6):
    rot = Matrix.Rotation(tilt, 3, tilt_axis)
    lift = radius * math.sin(abs(tilt)) + thick / 2
    c = center + Vector((0, 0, lift))
    rings = []
    for z in (-thick / 2, thick / 2):
        rings.append([bm.verts.new(c + rot @ Vector((radius * math.cos(2 * math.pi * k / sides), radius * math.sin(2 * math.pi * k / sides), z))) for k in range(sides)])
    for k in range(sides):
        f = bm.faces.new((rings[0][k], rings[0][(k + 1) % sides], rings[1][(k + 1) % sides], rings[1][k]))
        f.material_index = skin_idx
        f.smooth = True
    top = bm.faces.new(rings[1])
    bot = bm.faces.new(list(reversed(rings[0])))
    for f in (top, bot):
        f.material_index = cut_idx
        f.smooth = False


def build_pieces():
    mat_skin = palette_material("mat_octopus_pieces", "#D4506A", 0.5)
    mat_cut = palette_material("mat_octopus_pieces_cut", "#F4C6CC", 0.5)
    coll = bpy.data.collections.get("export_pieces")
    if coll is None:
        coll = bpy.data.collections.new("export_pieces")
        bpy.context.scene.collection.children.link(coll)
    for nm in ("octopus_pieces_a", "octopus_pieces_b", "octopus_pieces_c", "octopus_pieces", "Anchor_Front_pieces"):
        remove_object(nm)
    root = bpy.data.objects.new("octopus_pieces", None)
    root.empty_display_size = 0.1
    coll.objects.link(root)
    front_src = bpy.data.objects["Anchor_Front"]
    front = bpy.data.objects.new("Anchor_Front_pieces", None)
    front.empty_display_type = front_src.empty_display_type
    front.empty_display_size = front_src.empty_display_size
    front.location = (0.0, 0.5, 0.0)
    front.parent = root
    coll.objects.link(front)
    i = 0
    for layer, spots in PIECE_LAYERS.items():
        me = bpy.data.meshes.new(f"octopus_pieces_{layer}")
        me.materials.append(mat_skin)
        me.materials.append(mat_cut)
        bm = bmesh.new()
        for x, y in spots:
            axis = "X" if i % 2 else "Y"
            tilt = math.radians(8 + 7 * (i % 3)) * (1 if i % 4 < 2 else -1)
            add_slice(bm, Vector((x, y, PIECE_BASE_Z[layer])), 0.03, 0.02, axis, tilt, 0, 1, sides=8)
            i += 1
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(f"octopus_pieces_{layer}", me)
        ob.parent = root
        coll.objects.link(ob)
    return root


def build_all():
    raw, cooked = rebuild_whole()
    return raw, cooked, build_pieces()
