"""Geometría de art/blender/box_shelf.blend (PUL-051), generada por el agente con el MCP de Blender.

Se ejecuta dentro de Blender sobre la copia de art/blender/_template.blend:
    ns = {}; exec(open("docs/evidence/PUL-051/build_box_shelf.py").read(), ns); ns["build_all"]()
Crea en la colección `export` la raíz `box_shelf` con cuatro mallas hermanas (art-bible §2.1/§3.4/§3.5):
- `rack`: mueble de madera (`mat_wood_mid` y `mat_wood_dark`): estantes altos con laterales y fondo, y
  una balda baja (z = 0,31) con dos patas delanteras donde se apoyan los montones.
- `pile_small|medium|large`: tres montones de 3 platos nidificados, con las medidas y el aro de color de
  `box.blend` (PUL-047: diámetros 0,34/0,42/0,49, alto 0,10, aro azul/verde/rojo). Cada montón queda
  centrado en la posición de su spawner de `box_shelf.tscn` (x = −0,51/0/0,536 y +Y 0,78 = −Z 0,78 en Godot).
Las cajas del juego se instancian aparte; esto es solo el decorado. Se versiona como registro reproducible.
"""

import math

import bmesh
import bpy

M = bpy.data.materials
SEGS = 16
HEIGHT = 0.10
RIM = 0.022
WALL = 0.018
FLOOR_Z = 0.022
BASE_RATIO = 0.80
BAND = 0.02  # el aro de color también baja 2 cm por la pared exterior
NEST = 0.05  # separación vertical entre platos nidificados
PLATES = 3
DECK_Z = 0.31  # base de los montones (z del spawner en Godot)
PILE_Y = 0.78
PILES = {  # tamaño: (diámetro, x, material del aro)
    "small": (0.34, -0.51, "mat_bunting_blue"),
    "medium": (0.42, 0.0, "mat_bunting_green"),
    "large": (0.49, 0.536, "mat_canvas_stripe"),
}


def remove_object(name):
    ob = bpy.data.objects.get(name)
    if ob is None:
        return
    data = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if data is not None and data.users == 0 and isinstance(data, bpy.types.Mesh):
        bpy.data.meshes.remove(data)


def mesh_object(name, mats, parent, coll, fill):
    remove_object(name)
    me = bpy.data.meshes.new(name)
    for m in mats:
        me.materials.append(M[m])
    bm = bmesh.new()
    fill(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.parent = parent
    coll.objects.link(ob)
    return ob


def box(bm, x0, x1, y0, y1, z0, z1, mat):
    v = [bm.verts.new((x, y, z)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    for idx in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 2, 6, 4), (1, 5, 7, 3), (0, 4, 5, 1), (2, 3, 7, 6)):
        bm.faces.new([v[i] for i in idx]).material_index = mat


def build_rack(bm):
    W, T = 0.90, 0.04  # semiancho y grosor de tablas
    front, back, top = 1.08, -0.57, 1.60
    # Laterales (altura completa, fondo 0,5 de estantería alta) y fondo.
    for sx in (-1, 1):
        box(bm, sx * W - (T if sx > 0 else 0), sx * W + (0 if sx > 0 else T), back, back + 0.50, 0, top, 1)
    box(bm, -W, W, back, back + 0.03, 0.0, top, 1)
    # Balda baja de exposición (donde descansan los montones) y estantes altos.
    box(bm, -W, W, back, front, DECK_Z - T, DECK_Z, 0)
    for z in (0.85, 1.30):
        box(bm, -W + T, W - T, back + 0.03, back + 0.50, z, z + T, 0)
    box(bm, -W - 0.02, W + 0.02, back - 0.01, back + 0.53, top, top + T, 0)
    # Patas delanteras bajo la balda.
    for sx in (-1, 1):
        px = sx * (W - 0.04)
        box(bm, px - 0.04, px + 0.04, front - 0.08, front, 0, DECK_Z - T, 1)
    # Travesaño bajo la balda.
    box(bm, -W + 0.08, W - 0.08, front - 0.06, front - 0.02, 0.10, 0.15, 1)


def plate(bm, cx, cy, z0, R, ring_idx, floor):
    """Plato de box.blend simplificado (perfil de revolución). Material 0 madera, 1 aro, 2 oscuro."""

    def ring(r, z):
        return [bm.verts.new((cx + r * math.cos(2 * math.pi * k / SEGS), cy + r * math.sin(2 * math.pi * k / SEGS), z0 + z)) for k in range(SEGS)]

    def bridge(lo, hi, mat, smooth=True):
        for k in range(SEGS):
            f = bm.faces.new((lo[k], lo[(k + 1) % SEGS], hi[(k + 1) % SEGS], hi[k]))
            f.material_index = mat
            f.smooth = smooth

    rb = R * BASE_RATIO
    slope = (R - rb) / HEIGHT
    r_at = lambda z: rb + slope * z
    base = ring(rb, 0.0)
    band_lo = ring(r_at(HEIGHT - BAND), HEIGHT - BAND)
    top_out = ring(R, HEIGHT)
    top_in = ring(R - RIM, HEIGHT)
    inner_lo = ring(rb - WALL, FLOOR_Z)
    bridge(base, band_lo, 0)
    bridge(band_lo, top_out, 1)
    bridge(top_out, top_in, 1, smooth=False)
    bridge(top_in, inner_lo, 0)
    if floor:
        c = bm.verts.new((cx, cy, z0 + FLOOR_Z))
        for k in range(SEGS):
            bm.faces.new((c, inner_lo[(k + 1) % SEGS], inner_lo[k])).material_index = 0


def build_pile(size):
    d, x, ring_mat = PILES[size]

    def fill(bm):
        for i in range(PLATES):
            plate(bm, x, PILE_Y, DECK_Z + i * NEST, d / 2, 1, floor=(i == PLATES - 1))

    return fill, ring_mat


def build_all():
    coll = bpy.data.collections["export"]
    root = bpy.data.objects.get("box_shelf") or bpy.data.objects["asset"]
    root.name = "box_shelf"
    mesh_object("rack", ("mat_wood_mid", "mat_wood_dark"), root, coll, build_rack)
    for size in PILES:
        fill, ring_mat = build_pile(size)
        mesh_object("pile_" + size, ("mat_wood_light", ring_mat), root, coll, fill)
    return root
