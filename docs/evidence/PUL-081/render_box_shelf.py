"""Render del .blend de PUL-081 (no guarda nada; adaptado de PUL-080). Desde la raíz del repo:

    blender -b art/blender/box_shelf.blend --python docs/evidence/PUL-081/render_box_shelf.py \
        -- <salida.png> [front|level|detail]

Cámara ortográfica inclinada 38° (como la de `level_01`). `front` mira el rack por su frente (+Y) con
el cocinero de referencia de 1,8 m al lado; `level` lo mira desde su costado +X, que es como lo ve la
cámara del nivel (la estantería está girada −90° en `level_01`); `detail` se acerca a las pilas.
"""

import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0]
VIEW = argv[1] if len(argv) > 1 else "game"


def linearize_for_cycles():
    """Como PUL-082/083: el Blender de Fedora no carga el OCIO 2.5 y Cycles lee las imágenes sRGB como
    lineales; se sustituyen por copias float linealizadas (solo en memoria)."""
    import numpy as np

    for block in list(bpy.data.materials) + list(bpy.data.images) + list(bpy.data.node_groups):
        if block.library is not None:
            block.make_local()
    for img in list(bpy.data.images):
        if img.colorspace_settings.name != "sRGB" or img.size[0] == 0:
            continue
        n, ch = img.size[0] * img.size[1], img.channels
        px = np.empty(n * ch, dtype=np.float32)
        img.pixels.foreach_get(px)
        px = px.reshape(-1, ch)
        rgb = px[:, :3]
        out = np.ones((n, 4), dtype=np.float32)
        out[:, :ch] = px
        out[:, :3] = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
        lin = bpy.data.images.new(img.name + "_lin", img.size[0], img.size[1], float_buffer=True)
        lin.colorspace_settings.name = "Linear"
        lin.pixels.foreach_set(out.ravel())
        img.user_remap(lin)


def main():
    scene = bpy.context.scene
    objs = bpy.data.objects
    for name in ("ref_counter_1m", "ref_materials_v2"):
        if name in objs:
            objs[name].hide_render = True
    # Cocinero de referencia (caja de 1,8 m) a la izquierda de la imagen, solo en `game`.
    if "ref_character_1_8m" in objs:
        objs["ref_character_1_8m"].location = (1.6, 0.6, 0.0)
        objs["ref_character_1_8m"].hide_render = VIEW != "front"
        bpy.data.collections["reference"].hide_render = False
    bpy.ops.mesh.primitive_plane_add(size=16, location=(0, 0, 0))
    bpy.context.active_object.data.materials.append(bpy.data.materials["mat_ground_dirt"])
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    tilt = math.radians(52)  # 38° sobre la horizontal, como level_01
    dist = 20
    yaw = math.pi
    if VIEW == "detail":
        cam_data.ortho_scale = 1.5
        target = (0.0, 0.75, 0.4)
    elif VIEW == "level":
        cam_data.ortho_scale = 3.0
        target = (0.0, 0.25, 0.5)
        yaw = math.pi / 2
    else:
        cam_data.ortho_scale = 4.2
        target = (0.35, 0.1, 0.85)
    cam = bpy.data.objects.new("cam", cam_data)
    look = (math.sin(yaw), -math.cos(yaw))  # dirección horizontal de la cámara al objetivo, invertida
    cam.location = (
        target[0] + dist * math.sin(tilt) * look[0],
        target[1] + dist * math.sin(tilt) * look[1],
        target[2] + dist * math.cos(tilt),
    )
    cam.rotation_euler = (tilt, 0, yaw)
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 3.0
    sun_data.angle = math.radians(8)
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(150))
    scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scene.world = world
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    linearize_for_cycles()
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.device = "CPU"
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("render_box_shelf: OK", OUT)


main()
