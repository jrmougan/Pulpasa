"""Render de PUL-077 (no guarda el .blend): las tres bandejas vacías detrás y llenas delante (rodajas
de octopus.blend y cachelos de cachelos.blend, con la escala de `fill_scale` de box.tscn), con las
pegatinas de revisión, sobre una encimera `steel_top` y con la inclinación de la cámara del nivel
(ortográfica, 38°).

    blender -b art/blender/box.blend --python docs/evidence/PUL-077/render_box.py -- <out.png> [ortho]
"""

import math
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1 :]
out = args[0]
ortho = float(args[1]) if len(args) > 1 else 2.2
scene = bpy.context.scene
FILL = {"small": 0.9, "medium": 1.0, "large": 1.15}  # = fill_scale de box.tscn
CACHELOS_SCALE = 0.55
CACHELOS_LIFT = 0.04
X = {"small": -0.6, "medium": 0.0, "large": 0.65}

for coll in bpy.data.collections:
    coll.hide_render = coll.name == "reference"
bpy.data.objects["OutlineHull"].hide_render = True
for _s in ("small", "medium", "large"):
    bpy.data.objects[f"hull_{_s}"].hide_render = True
bpy.data.objects["sticker"].hide_render = True  # la exportada (oculta en juego); quedan las de revisión

root = "//"
pieces = {}
for asset in ("octopus", "cachelos"):
    with bpy.data.libraries.load(f"{root}{asset}.blend", link=False) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith(f"{asset}_pieces")]
    for ob in dst.objects:
        if ob is not None:
            pieces[ob.name] = ob

trays = {s: bpy.data.objects[f"box_{s}"] for s in X}
for size, tray in trays.items():
    tray.parent = None
    tray.location = (X[size], 0.35, 0)
    for ob in bpy.data.collections["render_only"].objects:
        if ob.name.startswith(f"review_sticker_{size}"):
            ob.location.x += X[size]
            ob.location.y += 0.35
    full = tray.copy()
    full.data = tray.data
    scene.collection.objects.link(full)
    full.location = (X[size], -0.25, 0)
    s = FILL[size]
    z = 0.024
    for name, ob in pieces.items():
        if ob.type != "MESH":
            continue
        is_cach = name.startswith("cachelos")
        if is_cach and size == "small":
            continue
        dup = ob.copy()
        dup.data = ob.data
        dup.parent = None
        k = s * (CACHELOS_SCALE if is_cach else 1.0)
        dup.scale = (k, k, k)
        lift = CACHELOS_LIFT * s if is_cach else 0.0
        dup.location = (X[size] + ob.matrix_world.translation.x * k, -0.25 + ob.matrix_world.translation.y * k, z + lift + ob.matrix_world.translation.z * k)
        scene.collection.objects.link(dup)

floor = bpy.data.meshes.new("floor")
floor.from_pydata([(-1.4, -0.9, 0), (1.4, -0.9, 0), (1.4, 0.9, 0), (-1.4, 0.9, 0)], [], [(0, 1, 2, 3)])
fo = bpy.data.objects.new("floor", floor)
fo.data.materials.append(bpy.data.materials["mat_steel_brushed_top"])
scene.collection.objects.link(fo)
uv = floor.uv_layers.new()
for lp in floor.loops:
    co = floor.vertices[lp.vertex_index].co
    uv.data[lp.index].uv = (co.x / 2, co.y / 2)

cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = ortho
cam = bpy.data.objects.new("cam", cam_data)
tilt = math.radians(38)
cam.location = (0.0, -10 * math.sin(tilt) + 0.05, 10 * math.cos(tilt) + 0.1)
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
scene.render.resolution_y = 1000
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
