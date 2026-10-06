"""Render de revisión de art/blender/environment_v2.blend (PUL-085) con el encuadre de la cámara de level_01.

Coloca en memoria cada raíz `export_<pieza>` donde la pone environment.tscn (girada 180°), añade cámara
ortográfica, sol y cielo, y renderiza con Cycles. No guarda el .blend. Uso, desde la raíz del repo:
    blender -b art/blender/environment_v2.blend --python art/blender/environment_v2_src/render_blend.py -- <salida.png>
"""

import math
import sys

import bpy

# (pieza, x, z) del nivel: los mismos orígenes que environment.tscn.
PLACES = {"ground_w": (-5.2, 1.1), "ground_e": (6.6, 1.1), "back_w": (-5.25, -9.9), "back_e": (6.65, -9.9),
          "tent": (0.3, -5.8), "props_w": (-9.1, 1.2), "props_e": (11.0, 1.2)}

out = sys.argv[sys.argv.index("--") + 1]
scene = bpy.context.scene
for name, (x, z) in PLACES.items():
    root = bpy.data.objects[name]
    root.location = (x, -z, 0.0)  # Godot (x, y, z) → Blender (x, −z, y)
    root.rotation_euler = (0.0, 0.0, math.pi)
cam_data = bpy.data.cameras.new("review_cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 12.74 * 16 / 9
cam = bpy.data.objects.new("review_cam", cam_data)
cam.location = (0.7, -5.86, 7.49)
cam.rotation_euler = (math.radians(52.0), 0.0, 0.0)
scene.collection.objects.link(cam)
scene.camera = cam
sun_data = bpy.data.lights.new("review_sun", "SUN")
sun_data.energy = 3.5
sun_data.angle = math.radians(8)
sun_data.color = (1.0, 0.913, 0.784)
sun = bpy.data.objects.new("review_sun", sun_data)
sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(-30))
scene.collection.objects.link(sun)
world = scene.world or bpy.data.worlds.new("review_world")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.37, 0.38, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.cycles.use_denoising = False
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("render_blend: OK", out)
