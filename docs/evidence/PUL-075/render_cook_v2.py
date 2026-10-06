"""Render de revisión de art/blender/cook.blend (PUL-075). No guarda el .blend.

    blender -b art/blender/cook.blend --python docs/evidence/PUL-075/render_cook_v2.py -- <dir> [pose]

Saca J1 y J2 de frente, de tres cuartos, de espaldas y desde la inclinación de la cámara del juego
(38°, ortográfica), con Cycles y una luz neutra suave; `pose` = nombre de un clip y fotograma
(p. ej. IdleHolding:0). Las imágenes se montan después con PIL.
"""

import math
import sys

import bpy
from mathutils import Vector

out_dir = sys.argv[sys.argv.index("--") + 1]
pose = sys.argv[sys.argv.index("--") + 2] if len(sys.argv) > sys.argv.index("--") + 2 else "Idle:0"
scene = bpy.context.scene
for o in list(bpy.data.objects):
    if o.name.startswith("review_"):
        bpy.data.objects.remove(o, do_unlink=True)
for c in bpy.data.collections:
    if c.name == "reference":
        c.hide_render = True
rig = bpy.data.objects["cook_rig"]
clip, frame = pose.split(":")
rig.animation_data.action = bpy.data.actions[clip]
scene.frame_set(int(frame))

world = scene.world or bpy.data.worlds.new("review_world")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.52, 0.48, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
sun_data = bpy.data.lights.new("review_sun", "SUN")
sun_data.energy = 3.2
sun_data.angle = math.radians(12)
sun = bpy.data.objects.new("review_sun", sun_data)
sun.rotation_euler = (math.radians(50), 0, math.radians(-35))
scene.collection.objects.link(sun)
cam_data = bpy.data.cameras.new("review_cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 2.3
cam = bpy.data.objects.new("review_cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 48
scene.render.resolution_x, scene.render.resolution_y = 600, 760
scene.render.film_transparent = False
scene.view_settings.view_transform = "AgX" if "AgX" in [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items] else "Standard"

target = Vector((0, 0, 0.98))
views = {"front": (0, 0), "threequarter": (35, 8), "back": (180, 8), "game": (0, 38)}
for variant in ("j1", "j2"):
    for o in bpy.data.objects:
        if o.type == "MESH" and o.name.startswith("cook_"):
            o.hide_render = not o.name.endswith(variant)
    for vname, (yaw, pitch) in views.items():
        yaw_r, pitch_r = math.radians(yaw), math.radians(pitch)
        d = Vector((math.sin(yaw_r) * math.cos(pitch_r), math.cos(yaw_r) * math.cos(pitch_r), math.sin(pitch_r)))
        cam.location = target + d * 6
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = f"{out_dir}/{variant}_{vname}.png"
        bpy.ops.render.render(write_still=True)
