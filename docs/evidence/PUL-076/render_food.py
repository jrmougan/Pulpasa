"""Render de PUL-076 (no guarda el .blend): crudo, cocido, quemado y rodajas/trozos en fila, sobre
una encimera `steel_top` y con la inclinación de la cámara del nivel (ortográfica, 38°).

    blender -b art/blender/<asset>.blend --python docs/evidence/PUL-076/render_food.py -- <out.png>
"""

import math
import sys

import bpy
import numpy as np

out = sys.argv[sys.argv.index("--") + 1]
asset = bpy.path.basename(bpy.data.filepath).rsplit(".", 1)[0]
scene = bpy.context.scene

# Las colecciones de export visibles en el render; la de referencia, no.
for coll in bpy.data.collections:
    coll.hide_render = coll.name == "reference"

step = 0.75
for i, state in enumerate(("raw", "cooked", "burnt")):
    ob = bpy.data.objects[f"{asset}_{state}"]
    ob.parent = None
    ob.location = (i * step - step, 0, 0)
pieces = bpy.data.objects[f"{asset}_pieces"]
pieces.location = (2 * step + 0.05, 0, 0)

floor = bpy.data.meshes.new("floor")
floor.from_pydata([(-1.3, -0.6, 0), (2.3, -0.6, 0), (2.3, 0.6, 0), (-1.3, 0.6, 0)], [], [(0, 1, 2, 3)])
fo = bpy.data.objects.new("floor", floor)
fo.data.materials.append(bpy.data.materials["mat_steel_brushed_top"])
scene.collection.objects.link(fo)
uv = floor.uv_layers.new()
for lp in floor.loops:
    co = floor.vertices[lp.vertex_index].co
    uv.data[lp.index].uv = (co.x / 2, co.y / 2)

cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 3.3
cam = bpy.data.objects.new("cam", cam_data)
tilt = math.radians(38)
cam.location = (0.5, -10 * math.sin(tilt), 10 * math.cos(tilt) + 0.1)
cam.rotation_euler = (tilt, 0, 0)
scene.collection.objects.link(cam)
scene.camera = cam
sun_data = bpy.data.lights.new("sun", "SUN")
sun_data.energy = 3.5
sun_data.angle = math.radians(10)
sun_data.color = (1.0, 0.92, 0.8)
sun = bpy.data.objects.new("sun", sun_data)
sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(-30))
scene.collection.objects.link(sun)
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.36, 0.38, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
scene.world = world

# El Blender de Fedora no carga el OCIO 2.5 (ver PUL-074): Cycles lee las sRGB como lineales.
for img in list(bpy.data.images):
    if img.colorspace_settings.name != "sRGB" or img.size[0] == 0:
        continue
    px = np.empty(img.size[0] * img.size[1] * img.channels, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(-1, img.channels)
    rgb = px[:, :3]
    px[:, :3] = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    lin = bpy.data.images.new(img.name + "_lin", img.size[0], img.size[1], alpha=img.channels == 4, float_buffer=True)
    lin.colorspace_settings.name = "Linear"
    o = np.ones((img.size[0] * img.size[1], 4), dtype=np.float32)
    o[:, : img.channels] = px
    lin.pixels.foreach_set(o.ravel())
    img.user_remap(lin)

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 64
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 700
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
