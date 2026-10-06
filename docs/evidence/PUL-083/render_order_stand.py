"""Render del .blend de PUL-083 (no guarda nada). Desde la raíz del repo:

    blender -b art/blender/order_stand.blend --python docs/evidence/PUL-083/render_order_stand.py \
        -- <salida.png> [row|detail]

`row` monta los cuatro puestos en fila (cada copia con su toldillo `awning_k`) y los renderiza con
Cycles desde una cámara ortográfica inclinada 38° por el lado del cliente, como la de `level_01`;
`detail` se acerca al puesto 2. Los números los pone el `Label3D` del juego, no el .blend.
"""

import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0]
VIEW = argv[1] if len(argv) > 1 else "row"
PIECES = ("counter", "tpv", "tray")
SPACING = 2.0


def linearize_for_cycles():
    """Como PUL-082: el Blender de Fedora no carga el OCIO 2.5 y Cycles lee las imágenes sRGB como
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
    for name in ("ref_character_1_8m", "ref_counter_1m", "ref_materials_v2"):
        if name in objs:
            objs[name].hide_render = True
    for k in range(1, 5):
        x = -(k - 2.5) * SPACING  # la cámara mira hacia −Y: puesto 1 a la izquierda
        for piece in PIECES + ("awning_%d" % k,):
            dup = objs[piece].copy()
            dup.parent = None
            dup.location = (x, 0.0, 0.0)
            scene.collection.objects.link(dup)
    for piece in PIECES + tuple("awning_%d" % k for k in range(1, 5)):
        objs[piece].hide_render = True
    bpy.ops.mesh.primitive_plane_add(size=16, location=(0, 0, 0))
    bpy.context.active_object.data.materials.append(bpy.data.materials["mat_ground_dirt"])
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    tilt = math.radians(52)  # 38° sobre la horizontal, como level_01
    dist = 20
    if VIEW == "detail":
        cam_data.ortho_scale = 2.6
        target = (0.5 * SPACING, 0.0, 1.0)
    else:
        cam_data.ortho_scale = 8.6
        target = (0.0, 0.0, 0.9)
    cam = bpy.data.objects.new("cam", cam_data)
    # Lado del cliente: +Y de Blender (−Z de Godot); la cámara mira hacia −Y.
    cam.location = (target[0], target[1] + dist * math.sin(tilt), target[2] + dist * math.cos(tilt))
    cam.rotation_euler = (tilt, 0, math.pi)
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
    print("render_order_stand: OK", OUT)


main()
