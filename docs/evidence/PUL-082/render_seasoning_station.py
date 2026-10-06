"""Render del .blend de PUL-082 (no guarda nada). Desde la raíz del repo:

    blender -b art/blender/seasoning_station.blend --python docs/evidence/PUL-082/render_seasoning_station.py \
        -- <salida.png> [operator|pass|detail]

Monta la estación como en el juego (cada recipiente en su ancla, el cuenco en la suya) y la
renderiza con Cycles desde una cámara ortográfica inclinada 38° como la de `level_01`:
`operator` desde el lado de condimentar (+Z de Godot, el que ve la cámara del nivel), `pass` desde
el de la cocina y `detail` de cerca sobre los recipientes.
"""

import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0]
VIEW = argv[1] if len(argv) > 1 else "operator"

PLACES = {
    "paprika_sweet": "Anchor_Dispenser_SweetPaprika",
    "paprika_hot": "Anchor_Dispenser_HotPaprika",
    "salt": "Anchor_Dispenser_Salt",
    "oil": "Anchor_Dispenser_Oil",
    "bowl": "Anchor_Bowl",
}


def linearize_for_cycles():
    """Como build_materials_v2_blend.py: el Blender de Fedora no carga el OCIO 2.5 y Cycles lee las
    imágenes sRGB como lineales; se sustituyen por copias float linealizadas (solo en memoria)."""
    for block in list(bpy.data.materials) + list(bpy.data.images) + list(bpy.data.node_groups):
        if block.library is not None:
            block.make_local()
    for img in list(bpy.data.images):
        if img.colorspace_settings.name != "sRGB" or img.size[0] == 0:
            continue
        import numpy as np

        n, ch = img.size[0] * img.size[1], img.channels
        px = np.empty(n * ch, dtype=np.float32)
        img.pixels.foreach_get(px)
        px = px.reshape(-1, ch)
        rgb = px[:, :3]
        out = np.ones((n, 4), dtype=np.float32)
        out[:, :ch] = px
        out[:, :3] = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
        out = out.ravel()
        lin = bpy.data.images.new(img.name + "_lin", img.size[0], img.size[1], float_buffer=True)
        lin.colorspace_settings.name = "Linear"
        lin.pixels.foreach_set(out)
        img.user_remap(lin)


def main():
    scene = bpy.context.scene
    objs = bpy.data.objects
    for name in ("ref_character_1_8m", "ref_counter_1m", "ref_materials_v2"):
        if name in objs:
            objs[name].hide_render = True
    for piece, anchor in PLACES.items():
        src = objs[piece]
        dup = src.copy()
        dup.parent = None
        dup.location = objs[anchor].matrix_world.translation
        scene.collection.objects.link(dup)
        src.hide_render = True
    # Suelo de tierra neutro.
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.data.materials.append(bpy.data.materials["mat_ground_dirt"])
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    tilt = math.radians(38)
    dist = 20
    target = (0.0, 0.0, 0.7)
    if VIEW == "pass":
        cam_data.ortho_scale = 5.0
        cam = bpy.data.objects.new("cam", cam_data)
        cam.location = (target[0], target[1] + dist * math.sin(tilt), target[2] + dist * math.cos(tilt))
        cam.rotation_euler = (tilt, 0, math.pi)
    elif VIEW == "detail":
        cam_data.ortho_scale = 2.4
        cam = bpy.data.objects.new("cam", cam_data)
        tgt = (0.3, 0.0, 1.0)
        cam.location = (tgt[0], tgt[1] - dist * math.sin(tilt), tgt[2] + dist * math.cos(tilt))
        cam.rotation_euler = (tilt, 0, 0)
    else:
        cam_data.ortho_scale = 5.0
        cam = bpy.data.objects.new("cam", cam_data)
        cam.location = (target[0], target[1] - dist * math.sin(tilt), target[2] + dist * math.cos(tilt))
        cam.rotation_euler = (tilt, 0, 0)
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 3.0
    sun_data.angle = math.radians(8)
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(-30))
    scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scene.world = world
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900 if VIEW != "detail" else 900
    linearize_for_cycles()
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.device = "CPU"
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("render_seasoning_station: OK", OUT)


main()
