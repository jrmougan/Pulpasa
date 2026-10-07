# Render de revisión de un .blend (PUL-087). Uso:
#   blender -b art/blender/<x>.blend --python docs/evidence/PUL-087/render_blend.py -- <salida.png>
# No guarda el .blend: si no tiene cámara, crea una ortográfica temporal como la del nivel.
import sys
import math
import bpy

out = sys.argv[sys.argv.index("--") + 1]
scene = bpy.context.scene
if scene.camera is None:
    cam_data = bpy.data.cameras.new("qa_cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 22.0
    cam = bpy.data.objects.new("qa_cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (0.0, -14.0, 16.0)
    cam.rotation_euler = (math.radians(42.0), 0.0, 0.0)
    scene.camera = cam
if not any(o.type == "LIGHT" for o in scene.objects):
    sun_data = bpy.data.lights.new("qa_sun", "SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("qa_sun", sun_data)
    sun.rotation_euler = (math.radians(50.0), 0.0, math.radians(-30.0))
    scene.collection.objects.link(sun)
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [
    e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
] else "BLENDER_EEVEE"
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
