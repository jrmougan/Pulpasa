"""Render de revisión de art/blender/octopus_storage.blend (PUL-079); no modifica el .blend.

    blender -b art/blender/octopus_storage.blend --python docs/evidence/PUL-079/render_tank.py -- <out.png> [game|three]

`game`: cámara ortográfica como la de level_01 (frontal, inclinada ≈ 38°); `three`: vista 3/4.
Luz neutra provisional (sol cálido + mundo gris): la luz final del nivel es de PUL-073.
"""

import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1 :]
out = argv[0]
mode = argv[1] if len(argv) > 1 else "three"

scene = bpy.context.scene
for ob in list(scene.objects):
    if ob.name.startswith("ref_"):
        ob.hide_render = True
scene.render.engine = "CYCLES"
scene.cycles.samples = 64
scene.cycles.device = "CPU"
scene.render.resolution_x = 1200
scene.render.resolution_y = 900
scene.render.film_transparent = False

world = bpy.data.worlds.new("review") if scene.world is None else scene.world
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs[0].default_value = (0.60, 0.65, 0.66, 1)
bg.inputs[1].default_value = 0.8

sun_data = bpy.data.lights.new("review_sun", "SUN")
sun_data.energy = 3.0
sun_data.color = (1.0, 0.913, 0.784)
sun_data.angle = math.radians(8)
sun = bpy.data.objects.new("review_sun", sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(35), 0, math.radians(-35))

# Suelo de tierra para el contacto.
bpy.ops.mesh.primitive_plane_add(size=5)
ground = bpy.context.active_object
ground.data.materials.append(bpy.data.materials["mat_ground_dirt"])

cam_data = bpy.data.cameras.new("review_cam")
cam = bpy.data.objects.new("review_cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
target = Vector((0, 0, 0.6))
if mode == "game":
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 2.6
    tilt = math.radians(38)
    d = Vector((0, math.cos(tilt), math.sin(tilt)))
else:
    cam_data.type = "PERSP"
    cam_data.lens = 50
    d = Vector((0.55, 1.0, 0.75)).normalized()
cam.location = target + d * 4.5
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()

scene.render.filepath = out
bpy.ops.render.render(write_still=True)
