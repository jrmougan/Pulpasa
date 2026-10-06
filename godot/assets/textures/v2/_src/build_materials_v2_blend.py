"""Construye art/blender/_materials_v2.blend desde el manifiesto de gen_materials_v2.py (PUL-074).

  blender -b --factory-startup --python godot/assets/textures/v2/_src/build_materials_v2_blend.py \
      [-- --render docs/evidence/PUL-074/blender_lamina.png]

Cada material `mat_*` usa nodos que el exportador glTF traduce 1:1 (materials-v2.md §3):
  Image albedo (sRGB) → Mix MULTIPLY con el factor de color → Base Color   (baseColorFactor)
  Image ORM (Non-Color) → Separate Color: G × roughness → Roughness, B × metallic → Metallic
  Image normal (Non-Color) → Normal Map → Normal
Las imágenes apuntan con ruta relativa a godot/assets/textures/v2/ (no se empaquetan). Todos los
materiales llevan fake user. La escena `lamina` tiene una esfera y un cubo por material.
"""

import json
import math
import sys
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parents[5]
SRC = ROOT / "godot" / "assets" / "textures" / "v2" / "_src"
TEX_DIR = ROOT / "godot" / "assets" / "textures" / "v2"
BLEND = ROOT / "art" / "blender" / "_materials_v2.blend"
UV_M = 2.0  # 1 unidad de UV = 2 m (512 px → 256 px/m)


def args() -> dict:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    out = {"render": None}
    if "--render" in argv:
        out["render"] = argv[argv.index("--render") + 1]
    return out


def image(rel: str, non_color: bool) -> bpy.types.Image:
    path = TEX_DIR / rel
    img = bpy.data.images.load(str(path), check_existing=True)
    img.colorspace_settings.name = "Non-Color" if non_color else "sRGB"
    return img


def build_material(m: dict, textures: dict) -> bpy.types.Material:
    mat = bpy.data.materials.new(m["name"])
    mat.use_fake_user = True
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    out = nodes.get("Material Output")
    bsdf.location, out.location = (300, 0), (600, 0)
    f = list(m["factor_lin"]) + [1.0]
    ex = m["extras"]
    tex = m["texture"]
    if tex:
        files = textures[tex]["files"]
        alb = nodes.new("ShaderNodeTexImage")
        alb.image = image(files["albedo"], False)
        alb.location = (-600, 300)
        mix = nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        mix.location = (-150, 300)
        links.new(alb.outputs["Color"], mix.inputs[6])
        mix.inputs[7].default_value = f
        links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        if textures[tex]["alpha"]:
            links.new(alb.outputs["Alpha"], bsdf.inputs["Alpha"])
        orm = nodes.new("ShaderNodeTexImage")
        orm.image = image(files["orm"], True)
        orm.location = (-600, 0)
        sep = nodes.new("ShaderNodeSeparateColor")
        sep.location = (-350, 0)
        links.new(orm.outputs["Color"], sep.inputs["Color"])
        for chan, sock, val, y in (("Green", "Roughness", m["roughness"], 40), ("Blue", "Metallic", m["metallic"], -80)):
            mul = nodes.new("ShaderNodeMath")
            mul.operation = "MULTIPLY"
            mul.location = (-150, y)
            links.new(sep.outputs[chan], mul.inputs[0])
            mul.inputs[1].default_value = val
            links.new(mul.outputs[0], bsdf.inputs[sock])
        if "normal" in files:
            nrm = nodes.new("ShaderNodeTexImage")
            nrm.image = image(files["normal"], True)
            nrm.location = (-600, -300)
            nm = nodes.new("ShaderNodeNormalMap")
            nm.location = (-150, -300)
            nm.inputs["Strength"].default_value = m["normal_strength"]
            links.new(nrm.outputs["Color"], nm.inputs["Color"])
            links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        bsdf.inputs["Base Color"].default_value = f
        bsdf.inputs["Roughness"].default_value = m["roughness"]
        bsdf.inputs["Metallic"].default_value = m["metallic"]
    if ex.get("emission"):
        bsdf.inputs["Emission Color"].default_value = f
        bsdf.inputs["Emission Strength"].default_value = ex["emission"]
    if ex.get("alpha") == "blend":
        bsdf.inputs["Alpha"].default_value = ex.get("alpha_value", 1.0)
        mat.surface_render_method = "BLENDED"
    if ex.get("alpha") == "scissor":
        mat.surface_render_method = "DITHERED"
        mat["alpha_card"] = True
    if ex.get("cull") == "disabled":
        mat.use_backface_culling = False
    else:
        mat.use_backface_culling = True
    hexc = m["hex"].lstrip("#")
    mat.diffuse_color = [((int(hexc[i : i + 2], 16) / 255.0)) ** 2.2 for i in (0, 2, 4)] + [1.0]
    return mat


def box_uv(me: bpy.types.Mesh, meters_per_unit: float) -> None:
    """Proyección de caja a la densidad de la biblioteca: 1 unidad de UV = `meters_per_unit` m."""
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    for face in bm.faces:
        n = face.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            co = loop.vert.co
            if ax == 0:
                u, v = co.y * (1 if n.x > 0 else -1), co.z
            elif ax == 1:
                u, v = co.x * (-1 if n.y > 0 else 1), co.z
            else:
                u, v = co.x, co.y * (1 if n.z > 0 else -1)
            loop[uv].uv = (u / meters_per_unit, v / meters_per_unit)
    bm.to_mesh(me)
    bm.free()


def sphere_uv(me: bpy.types.Mesh, radius: float, meters_per_unit: float) -> None:
    """UV esférica escalada a densidad real (perímetro 2πr en u)."""
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    circ = 2 * math.pi * radius
    for face in bm.faces:
        us = []
        for loop in face.loops:
            co = loop.vert.co
            us.append((math.atan2(co.y, co.x) / (2 * math.pi)) % 1.0)
        fix = max(us) - min(us) > 0.5
        for loop, u in zip(face.loops, us):
            co = loop.vert.co
            if fix and u < 0.5:
                u += 1.0
            v = (math.asin(max(-1.0, min(1.0, co.z / radius))) / math.pi) * (circ / 2)
            loop[uv].uv = (u * circ / meters_per_unit, v / meters_per_unit)
    bm.to_mesh(me)
    bm.free()


def build_lamina(mats: list) -> None:
    scene = bpy.context.scene
    scene.name = "lamina"
    coll = bpy.data.collections.new("lamina")
    scene.collection.children.link(coll)
    cols = 9
    pitch_x, pitch_y = 2.2, 2.4
    for i, mat in enumerate(mats):
        cx = (i % cols - (cols - 1) / 2) * pitch_x
        cy = -(i // cols) * pitch_y
        r = 0.45
        sm = bpy.data.meshes.new(f"{mat.name}_sphere")
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=40, v_segments=20, radius=r)
        for f in bm.faces:
            f.smooth = True
        bm.to_mesh(sm)
        bm.free()
        sphere_uv(sm, r, UV_M if mat.name != "mat_ground_dirt" else 4.0)
        sm.materials.append(mat)
        so = bpy.data.objects.new(f"{mat.name}_sphere", sm)
        so.location = (cx - 0.5, cy, r)
        coll.objects.link(so)
        cm = bpy.data.meshes.new(f"{mat.name}_cube")
        bm = bmesh.new()
        if mat.get("alpha_card", False):
            # Tarjeta con alfa (vegetación): un plano vertical de 0,8 m en vez del cubo.
            bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.4)
            bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(math.radians(90), 3, "X"))
        else:
            bmesh.ops.create_cube(bm, size=0.8)
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=0.03, segments=2, affect="EDGES")
        bm.to_mesh(cm)
        bm.free()
        if mat.get("alpha_card", False):
            bm = bmesh.new()
            bm.from_mesh(cm)
            uvl = bm.loops.layers.uv.verify()
            for face in bm.faces:
                for loop in face.loops:
                    loop[uvl].uv = (loop.vert.co.x / 0.8 + 0.5, loop.vert.co.z / 0.8 + 0.5)
            bm.to_mesh(cm)
            bm.free()
        else:
            box_uv(cm, UV_M if mat.name != "mat_ground_dirt" else 4.0)
        cm.materials.append(mat)
        co = bpy.data.objects.new(f"{mat.name}_cube", cm)
        co.location = (cx + 0.5, cy, 0.4)
        co.rotation_euler = (0, 0, math.radians(20))
        coll.objects.link(co)
        cu = bpy.data.curves.new(f"{mat.name}_label", "FONT")
        cu.body = mat.name.removeprefix("mat_")
        cu.size = 0.2
        cu.align_x = "CENTER"
        lo = bpy.data.objects.new(f"{mat.name}_label", cu)
        lo.location = (cx, cy - 0.85, 0.0)
        coll.objects.link(lo)
    # Suelo neutro, cámara ortográfica inclinada como la del juego (≈ 38°) y luz neutra.
    rows = (len(mats) + cols - 1) // cols
    gm = bpy.data.meshes.new("lamina_floor")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30)
    bm.to_mesh(gm)
    bm.free()
    floor_mat = bpy.data.materials.new("lamina_floor_grey")
    floor_mat.use_nodes = True
    floor_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.35, 0.35, 0.35, 1)
    floor_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    gm.materials.append(floor_mat)
    fo = bpy.data.objects.new("lamina_floor", gm)
    coll.objects.link(fo)
    label_mat = bpy.data.materials.new("lamina_label_white")
    label_mat.use_nodes = True
    label_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.95, 0.95, 0.95, 1)
    for o in coll.objects:
        if o.type == "FONT":
            o.data.materials.append(label_mat)
    cam_data = bpy.data.cameras.new("lamina_cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = cols * pitch_x + 0.6
    cam = bpy.data.objects.new("lamina_cam", cam_data)
    top, bottom = 0.6, -(rows - 1) * pitch_y - 1.05
    mid_y = (top + bottom) / 2
    tilt = math.radians(38)
    dist = 30
    cam.location = (0, mid_y - dist * math.sin(tilt) + 0.3, dist * math.cos(tilt) + 0.4)
    cam.rotation_euler = (tilt, 0, 0)
    coll.objects.link(cam)
    scene.camera = cam
    sun_data = bpy.data.lights.new("lamina_sun", "SUN")
    sun_data.energy = 3.0
    sun_data.angle = math.radians(8)
    sun = bpy.data.objects.new("lamina_sun", sun_data)
    sun.rotation_euler = (math.radians(35), math.radians(-25), math.radians(-30))
    coll.objects.link(sun)
    world = bpy.data.worlds.new("lamina_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scene.world = world
    scene.render.resolution_x = 1920
    scene.render.resolution_y = int(1920 * ((top - bottom) * math.cos(tilt) + 1.0) / (cols * pitch_x + 0.6))
    # AgX si el OCIO lo trae; el Blender de Fedora cae a la configuración de reserva (solo Standard).
    if "AgX" in [i.identifier for i in scene.view_settings.bl_rna.properties["view_transform"].enum_items]:
        scene.view_settings.view_transform = "AgX"
    scene.render.film_transparent = False


def linearize_for_cycles() -> None:
    """Solo para el render (no se guarda): el Blender de Fedora no carga el OCIO 2.5 y Cycles,
    en modo de reserva, lee las imágenes sRGB como lineales (salen lavadas). Se sustituyen por copias
    float ya linealizadas. El .blend y el glTF siguen usando los PNG sRGB originales."""
    import numpy as np

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
        out = np.ones((img.size[0] * img.size[1], 4), dtype=np.float32)
        out[:, : img.channels] = px
        lin.pixels.foreach_set(out.ravel())
        img.user_remap(lin)


def main() -> None:
    a = args()
    data = json.loads((SRC / "materials_v2.json").read_text(encoding="utf-8"))
    # Parte de la escena de fábrica (--factory-startup): fuera el cubo, la cámara y la luz.
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(coll):
            coll.remove(block)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    mats = [build_material(m, data["textures"]) for m in data["materials"]]
    build_lamina(mats)
    for name in ("gen_materials_v2.py", "build_materials_v2_blend.py"):
        txt = bpy.data.texts.new(name)
        txt.from_string((SRC / name).read_text(encoding="utf-8"))
        txt.use_fake_user = True
    BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND), relative_remap=True, compress=True)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_mainfile(compress=True)
    print(f"build_materials_v2: OK {BLEND.relative_to(ROOT)} ({len(mats)} materiales)")
    if a["render"]:
        linearize_for_cycles()
        out = Path(a["render"])
        out = out if out.is_absolute() else ROOT / out
        scene.render.engine = "CYCLES"
        scene.cycles.samples = 64
        scene.cycles.use_denoising = True
        scene.cycles.device = "CPU"
        scene.render.filepath = str(out)
        bpy.ops.render.render(write_still=True)
        print(f"build_materials_v2: render {out}")


main()
