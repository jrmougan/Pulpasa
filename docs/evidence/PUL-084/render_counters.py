"""Render del .blend de PUL-084 (no guarda nada). Desde la raíz del repo:

    blender -b art/blender/counters.blend --python docs/evidence/PUL-084/render_counters.py -- <salida.png> [kit|detail]

Monta el kit en una mini cocina (fila de encimeras con atrezo en la franja trasera, pasaplatos
delante, rejilla en el suelo y barrera del público) y lo renderiza con Cycles desde una cámara
ortográfica inclinada 38° como la de `level_01`, mirando al frente de las piezas (−Z de Godot).
"""

import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0]
VIEW = argv[1] if len(argv) > 1 else "kit"

# pieza, x, y (Blender; +Y = frente), z, giro en Z (grados)
LAYOUT = (
    ("counter_corner", -4.0, 0.0, 0.0, 0), ("counter_3m", -2.0, 0.0, 0.0, 0), ("counter_1m", 0.0, 0.0, 0.0, 0),
    ("counter_2m", 1.5, 0.0, 0.0, 0), ("counter_half", 2.75, 0.0, 0.0, 0), ("counter_end", 3.5, 0.0, 0.0, 0),
    ("counter_props_board", -2.4, -0.37, 1.0, 0), ("counter_props_crock", 1.2, -0.37, 1.0, 0),
    ("pass_2m", -2.0, 2.3, 0.0, 0), ("pass_1m", -0.5, 2.3, 0.0, 0), ("pass_end", 0.5, 2.3, 0.0, 0),
    ("drain_grate", 2.2, 1.6, 0.0, 0), ("rail_1m", -1.0, 4.4, 0.0, 0), ("rail_1m", 0.0, 4.4, 0.0, 0),
)


def linearize_for_cycles():
    """Como build_materials_v2_blend.py: el Blender de Fedora no carga el OCIO 2.5 y Cycles lee las
    imágenes sRGB como lineales; se sustituyen por copias float linealizadas (solo en memoria)."""
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
    for ob in list(objs):
        if ob.type == "MESH":
            ob.hide_render = True
    for name, x, y, z, rot in LAYOUT:
        dup = objs[name + "_body"].copy()
        dup.parent = None
        dup.hide_render = False
        dup.location = (x, y, z)
        dup.rotation_euler = (0, 0, math.radians(rot))
        scene.collection.objects.link(dup)
    bpy.ops.mesh.primitive_plane_add(size=16, location=(0, 2, 0))
    floor = bpy.context.active_object
    floor.data.materials.append(bpy.data.materials["mat_ground_dirt"])
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    tilt, dist = math.radians(38), 20
    target = (0.0, 2.0, 0.6) if VIEW == "kit" else (-2.0, 1.2, 0.8)
    cam_data.ortho_scale = 10.0 if VIEW == "kit" else 4.0
    cam = bpy.data.objects.new("cam", cam_data)
    cam.location = (target[0], target[1] + dist * math.sin(tilt), target[2] + dist * math.cos(tilt))
    cam.rotation_euler = (tilt, 0, math.pi)
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = 3.0
    sun_data.angle = math.radians(8)
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = (math.radians(35), math.radians(25), math.radians(150))
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
    print("render_counters: OK", OUT)


main()
