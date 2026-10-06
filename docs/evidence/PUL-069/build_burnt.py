"""Mallas `*_burnt` de art/blender/{octopus,cachelos}.blend (PUL-069), con el MCP de Blender por CLI.

Se ejecuta dentro de Blender sobre el .blend del asset y lo guarda:
    ns = {}; exec(open("docs/evidence/PUL-069/build_burnt.py").read(), ns); ns["build"]("octopus")
Duplica `<asset>_cooked` como `<asset>_burnt` (hermana bajo la misma raíz, colección `export`),
encogida y arrugada (sostiene la silueta del cocido pero más baja y seca) y con los colores del
cocido sustituidos por tonos carbonizados. Mismo estilo que PUL-045/046: color plano por hex,
sin texturas; los ojos (`mat_salt`) se conservan para que el pulpo siga leyéndose como pulpo.
"""

import math

import bpy
from mathutils import Vector

# Encogido: ancho/fondo y alto (la base sigue en z = 0, el origen en el centro de la base).
SHRINK_XY = 0.9
SHRINK_Z = 0.82
# Arrugado determinista: desplazamiento radial ±WRINKLE m según la posición del vértice.
WRINKLE = 0.006

PALETTE = {
    # Carbonizado con un punto del color del cocido (rojo-morado / amarillo tostado), mate.
    "mat_octopus_burnt": ("#3B2226", 0.95),
    "mat_octopus_burnt_dark": ("#1C1012", 0.95),
    "mat_potato_burnt": ("#4A3524", 0.95),
    "mat_potato_burnt_dark": ("#1E150E", 0.95),
}

REMAP = {
    "octopus": {
        "mat_octopus_cooked": "mat_octopus_burnt",
        "mat_octopus_cooked_dark": "mat_octopus_burnt_dark",
    },
    "cachelos": {
        "mat_potato_cooked": "mat_potato_burnt",
        "mat_potato_cooked_dark": "mat_potato_burnt_dark",
    },
}


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def palette_material(name: str, hex_color: str, roughness: float) -> bpy.types.Material:
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    rgb = [srgb_to_linear(int(hex_color[i : i + 2], 16) / 255) for i in (1, 3, 5)]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = (*rgb, 1.0)
    mat.use_fake_user = True
    return mat


def build(asset: str) -> dict:
    cooked = bpy.data.objects[f"{asset}_cooked"]
    old = bpy.data.objects.get(f"{asset}_burnt")
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    mesh = cooked.data.copy()
    mesh.name = f"{asset}_burnt"
    burnt = bpy.data.objects.new(f"{asset}_burnt", mesh)
    for coll in cooked.users_collection:
        coll.objects.link(burnt)
    burnt.parent = cooked.parent
    burnt.matrix_parent_inverse = cooked.matrix_parent_inverse.copy()
    burnt.location = cooked.location.copy()

    for v in mesh.vertices:
        co = v.co
        n = math.sin(co.x * 53.0) * math.cos(co.y * 47.0) * math.sin(co.z * 61.0 + 1.3)
        radial = Vector((co.x, co.y, 0.0))
        if radial.length > 1e-6:
            radial.normalize()
        v.co = Vector((co.x * SHRINK_XY, co.y * SHRINK_XY, co.z * SHRINK_Z)) + radial * (n * WRINKLE)

    for name, (hex_color, rough) in PALETTE.items():
        palette_material(name, hex_color, rough)
    remap = REMAP[asset]
    for i, mat in enumerate(mesh.materials):
        if mat is not None and mat.name in remap:
            mesh.materials[i] = bpy.data.materials[remap[mat.name]]

    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    dims = [round(d, 3) for d in burnt.dimensions]
    bpy.ops.wm.save_mainfile()
    return {"object": burnt.name, "tris": tris, "dims": dims, "mats": [m.name for m in mesh.materials]}
