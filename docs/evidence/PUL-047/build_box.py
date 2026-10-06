"""Geometría de art/blender/box.blend (PUL-047), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-047/build_box.py").read(), ns); ns["build_all"](atlas_png)
`atlas_png` es la salida de build_sticker_atlas.py; la imagen se empaqueta en el .blend.

Crea en la colección `export` la raíz `box` con tres platos de madera hermanos (`box_small`,
`box_medium`, `box_large`, art-bible §2.1/§3.4), cada uno con su `Anchor_Fill_<tamaño>` (suelo del
plato, donde Godot coloca las rodajas de `octopus_pieces.glb` y los trozos de `cachelos_pieces.glb`)
y sus `Anchor_Sticker_<tamaño>_0..3` (arco en el borde frontal-superior). Además el objeto `sticker`
reutilizable: disco de 0,10 m mirando al frente (+Y) con el atlas de 5 iconos; en juego va oculto
(la fila real es %BadgeRow, PUL-059). En la colección `render_only` (no se exporta) quedan copias
giradas de la pegatina sobre los anclajes para el render de revisión. Mismo estilo y convenciones
que build_octopus.py (PUL-045) y build_cachelos.py (PUL-046). Se versiona como registro
reproducible.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

M = bpy.data.materials

# Diámetro exterior (art-bible §2.1: 0,34 / 0,42 / 0,49) y material del aro por tamaño (§3.4).
SIZES = {
    "small": (0.34, "mat_bunting_blue"),
    "medium": (0.42, "mat_bunting_green"),
    "large": (0.49, "mat_canvas_stripe"),
}
HEIGHT = 0.10
SEGS = 24
RIM = 0.022  # ancho de la corona (aro de color de 0,02 m)
WALL = 0.018  # grosor de la pared bajo la corona
FLOOR_Z = 0.022
BASE_RATIO = 0.80  # radio de la base / radio de la boca
FOOT = 0.014  # banda oscura de contacto (§3.1.3)
STICKER_D = 0.10
STICKER_SIDES = 16
STICKER_OFFSET = 0.001  # sobre la pared, contra z-fighting (§3.4)
# Celda del atlas 4×2 (build_sticker_atlas.py): 0 dulce, 1 picante, 2 sal, 3 aceite, 4 cachelos.
ATLAS_COLS, ATLAS_ROWS = 4, 2


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def ring(bm, r, z):
    return [bm.verts.new((r * math.cos(2 * math.pi * k / SEGS), r * math.sin(2 * math.pi * k / SEGS), z)) for k in range(SEGS)]


def bridge(bm, lo, hi, idx, smooth=True):
    for k in range(SEGS):
        f = bm.faces.new((lo[k], lo[(k + 1) % SEGS], hi[(k + 1) % SEGS], hi[k]))
        f.material_index = idx
        f.smooth = smooth


def plate_profile(diameter):
    """(radio, z) de fuera a dentro: pie oscuro, pared exterior, corona de color, pared interior."""
    r_top = diameter / 2
    r_base = r_top * BASE_RATIO
    r_in = r_top - RIM
    r_floor = r_in - WALL
    foot_r = r_base + (r_top - r_base) * FOOT / HEIGHT
    return r_top, r_base, r_in, r_floor, foot_r


def build_plate(name, diameter, rim_mat, parent, coll):
    """Plato hondo de madera: sin cara inferior (no se ve desde la cámara, §2.2)."""
    r_top, r_base, r_in, r_floor, foot_r = plate_profile(diameter)
    me = bpy.data.meshes.new(name)
    for m in ("mat_wood_light", "mat_wood_dark", rim_mat, "mat_wood_mid"):
        me.materials.append(M[m])
    bm = bmesh.new()
    base = ring(bm, r_base, 0.0)
    foot = ring(bm, foot_r, FOOT)
    top_out = ring(bm, r_top, HEIGHT)
    top_in = ring(bm, r_in, HEIGHT)
    floor_edge = ring(bm, r_floor, FLOOR_Z)
    bridge(bm, base, foot, 1)  # pie oscuro
    bridge(bm, foot, top_out, 0)  # pared exterior
    bridge(bm, top_out, top_in, 2, smooth=False)  # aro de color (corona plana)
    bridge(bm, top_in, floor_edge, 0)  # pared interior
    centre = bm.verts.new((0.0, 0.0, FLOOR_Z))
    for k in range(SEGS):
        f = bm.faces.new((centre, floor_edge[k], floor_edge[(k + 1) % SEGS]))
        f.material_index = 3  # fondo algo más oscuro: da hondura vista desde arriba
        f.smooth = False
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def sticker_angles(diameter):
    """Cuatro huecos en arco centrados en el frente (+Y), separados un disco y un poco."""
    r = diameter / 2
    step = (STICKER_D * 1.08) / r
    return [math.pi / 2 + (1.5 - i) * step for i in range(4)]


def wall_point(diameter, th):
    """Centro de la pegatina en la pared exterior y normal de la pared en ese ángulo."""
    r_top, r_base, _r_in, _r_floor, _foot_r = plate_profile(diameter)
    z = HEIGHT - STICKER_D / 2 - 0.004
    r = r_base + (r_top - r_base) * z / HEIGHT
    radial = Vector((math.cos(th), math.sin(th), 0.0))
    normal = Vector((radial.x * HEIGHT, radial.y * HEIGHT, -(r_top - r_base))).normalized()
    return radial * r + Vector((0, 0, z)) + normal * STICKER_OFFSET, normal


def atlas_material(image):
    mat = M.get("mat_sticker_atlas") or M.new("mat_sticker_atlas")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.get("atlas") or nt.nodes.new("ShaderNodeTexImage")
    tex.name = "atlas"
    tex.image = image
    tex.interpolation = "Linear"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.use_fake_user = True
    return mat


def sticker_mesh(name, cell, mat):
    """Disco de 0,10 m en el plano XZ mirando a +Y (frente), UV en la celda `cell` del atlas."""
    me = bpy.data.meshes.new(name)
    me.materials.append(mat)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    r = STICKER_D / 2
    cu, cv = 1.0 / ATLAS_COLS, 1.0 / ATLAS_ROWS
    u0, v0 = (cell % ATLAS_COLS) * cu, 1.0 - (cell // ATLAS_COLS + 1) * cv
    centre = bm.verts.new((0.0, 0.0, 0.0))
    rim = [bm.verts.new((r * math.cos(2 * math.pi * k / STICKER_SIDES), 0.0, r * math.sin(2 * math.pi * k / STICKER_SIDES))) for k in range(STICKER_SIDES)]
    for k in range(STICKER_SIDES):
        a, b = rim[(k + 1) % STICKER_SIDES], rim[k]
        f = bm.faces.new((centre, a, b))
        f.smooth = False
        for loop in f.loops:
            p = loop.vert.co
            loop[uv].uv = (u0 + cu * (0.5 + p.x / (2 * r)), v0 + cv * (0.5 + p.z / (2 * r)))
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    return me


def build_all(atlas_png):
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("box") or bpy.data.objects["asset"]
    root.name = "box"
    names = ["sticker"]
    for size in SIZES:
        names += [f"box_{size}", f"Anchor_Fill_{size}"] + [f"Anchor_Sticker_{size}_{i}" for i in range(4)]
    for nm in names:
        remove_object(nm)
    front = bpy.data.objects["Anchor_Front"]
    front.parent = root

    image = bpy.data.images.get("box_stickers") or bpy.data.images.load(atlas_png)
    image.name = "box_stickers"
    image.filepath = atlas_png
    image.reload()
    image.pack()
    mat = atlas_material(image)

    plates = {}
    for size, (diameter, rim_mat) in SIZES.items():
        plate = build_plate(f"box_{size}", diameter, rim_mat, root, coll)
        plates[size] = plate
        fill = bpy.data.objects.new(f"Anchor_Fill_{size}", None)
        fill.empty_display_type = "PLAIN_AXES"
        fill.empty_display_size = 0.05
        fill.location = (0.0, 0.0, FLOOR_Z)
        fill.parent = plate
        coll.objects.link(fill)
        for i, th in enumerate(sticker_angles(diameter)):
            pos, _n = wall_point(diameter, th)
            a = bpy.data.objects.new(f"Anchor_Sticker_{size}_{i}", None)
            a.empty_display_type = "SPHERE"
            a.empty_display_size = 0.01
            a.location = pos
            a.parent = plate
            coll.objects.link(a)

    # Pegatina reutilizable exportada: celda 0, delante del plato mediano, oculta en juego.
    sticker = bpy.data.objects.new("sticker", sticker_mesh("sticker", 0, mat))
    sticker.location = wall_point(SIZES["medium"][0], math.pi / 2)[0]
    sticker.parent = root
    coll.objects.link(sticker)

    # Copias de revisión (no se exportan): cuatro pegatinas por plato, giradas sobre la pared.
    rc = bpy.data.collections.get("render_only")
    if rc is None:
        rc = bpy.data.collections.new("render_only")
        bpy.context.scene.collection.children.link(rc)
    for ob in list(rc.objects):
        remove_object(ob.name)
    cells = {"small": [0, 2, 3, 4], "medium": [1, 2, 4], "large": [0, 3]}
    for size, (diameter, _rim) in SIZES.items():
        for i, cell in enumerate(cells[size]):
            th = sticker_angles(diameter)[i + (4 - len(cells[size])) // 2]
            pos, n = wall_point(diameter, th)
            ob = bpy.data.objects.new(f"review_sticker_{size}_{i}", sticker_mesh(f"review_sticker_{size}_{i}", cell, mat))
            ob.matrix_world = Matrix.Translation(pos) @ Vector((0, 1, 0)).rotation_difference(n).to_matrix().to_4x4()
            rc.objects.link(ob)
    return plates
