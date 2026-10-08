"""Production signage helpers for PUL-094..096 (Blender CLI, original atlas)."""
import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path.cwd()
COLORS = {'navy': '#1D3557', 'paper': '#F4EFE6', 'sweet': '#D6361F',
          'hot': '#8F1A14', 'salt': '#F7F4EC', 'oil': '#F2C230', 'potato': '#F2D56B'}
KEYS = list(COLORS) + ['S', 'M', 'L', 'sweet_icon', 'hot_icon', 'salt_icon', 'oil_icon', 'potato_icon', 'arrow']


def rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


def atlas(name):
    """512px atlas: shared swatches, Montserrat letters, existing canonical icons."""
    image = bpy.data.images.get(name) or bpy.data.images.new(name, width=512, height=512, alpha=True)
    pixels = [1.0] * (512 * 512 * 4)
    ink = rgb(COLORS['navy']) + (1.0,)
    paper = rgb(COLORS['paper']) + (1.0,)
    font = bpy.data.fonts.load(str(ROOT / 'godot/assets/fonts/montserrat/Montserrat-Bold.otf'))
    for index, key in enumerate(KEYS):
        ox, oy = index % 4 * 128, index // 4 * 128
        color = rgb(COLORS[key]) + (1.0,) if key in COLORS else paper
        for y in range(128):
            for x in range(128):
                p = ((oy + y) * 512 + ox + x) * 4
                pixels[p:p + 4] = color
        if key in ('S', 'M', 'L'):
            curve = bpy.data.curves.new('atlas_letter', 'FONT')
            curve.body = key
            curve.font = font
            ob = bpy.data.objects.new('atlas_letter', curve)
            bpy.context.scene.collection.objects.link(ob)
            bpy.context.view_layer.update()
            mesh = bpy.data.meshes.new_from_object(ob.evaluated_get(bpy.context.evaluated_depsgraph_get()))
            mesh.calc_loop_triangles()
            pts = [v.co for v in mesh.vertices]
            xmin, xmax = min(p.x for p in pts), max(p.x for p in pts)
            ymin, ymax = min(p.y for p in pts), max(p.y for p in pts)
            scale = min(94 / (xmax - xmin), 100 / (ymax - ymin))
            def point(v):
                return Vector(((v.x - (xmin + xmax) / 2) * scale + 64,
                               (v.y - (ymin + ymax) / 2) * scale + 64))
            for tri in mesh.loop_triangles:
                a, b, c = [point(pts[i]) for i in tri.vertices]
                def cross(u, v):
                    return u.x * v.y - u.y * v.x
                for y in range(max(0, int(min(a.y, b.y, c.y))), min(128, math.ceil(max(a.y, b.y, c.y)))):
                    for x in range(max(0, int(min(a.x, b.x, c.x))), min(128, math.ceil(max(a.x, b.x, c.x)))):
                        p = Vector((x + .5, y + .5))
                        signs = [cross(b - a, p - a), cross(c - b, p - b), cross(a - c, p - c)]
                        if all(s >= 0 for s in signs) or all(s <= 0 for s in signs):
                            offset = ((oy + y) * 512 + ox + x) * 4
                            pixels[offset:offset + 4] = ink
            bpy.data.objects.remove(ob, do_unlink=True)
            bpy.data.meshes.remove(mesh)
        elif key.endswith('_icon'):
            kind = key.replace('_icon', '')
            source = bpy.data.images.load(str(ROOT / 'art/concepts/estaciones' / ('icon_' + kind + '.png')), check_existing=True)
            w, h = source.size
            source_pixels = list(source.pixels)
            for y in range(100):
                for x in range(100):
                    src = (min(h - 1, int(y * h / 100)) * w + min(w - 1, int(x * w / 100))) * 4
                    alpha = source_pixels[src + 3]
                    dst = ((oy + 14 + y) * 512 + ox + 14 + x) * 4
                    pixels[dst:dst + 4] = [ink[i] * alpha + paper[i] * (1 - alpha) for i in range(4)]
            if kind == 'hot':
                fire = bpy.data.images.load(str(ROOT / 'art/concepts/estaciones/icon_fire.png'), check_existing=True)
                fw, fh = fire.size
                fp = list(fire.pixels)
                for y in range(46):
                    for x in range(38):
                        alpha = fp[(int(y * fh / 46) * fw + int(x * fw / 38)) * 4 + 3]
                        dst = ((oy + 68 + y) * 512 + ox + 82 + x) * 4
                        pixels[dst:dst + 4] = [ink[i] * alpha + pixels[dst + i] * (1 - alpha) for i in range(4)]
        elif key == 'arrow':
            for y in range(24, 105):
                for x in range(16, 113):
                    if abs(y - (35 + abs(x - 64))) < 10:
                        dst = ((oy + y) * 512 + ox + x) * 4
                        pixels[dst:dst + 4] = ink
    image.pixels.foreach_set(pixels)
    image.pack()
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bs = mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Roughness'].default_value = .82
    for node in list(mat.node_tree.nodes):
        if node.type == 'TEX_IMAGE':
            mat.node_tree.nodes.remove(node)
    texture = mat.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = image
    mat.node_tree.links.new(texture.outputs['Color'], bs.inputs['Base Color'])
    return mat, image


def cell_uv(obj, key, full=False):
    index = KEYS.index(key)
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new()
    for poly in obj.data.polygons:
        for j, loop in enumerate(poly.loop_indices):
            if full:
                u, v = [(0, 0), (1, 0), (1, 1), (0, 1)][j % 4]
                u, v = .03 + u * .94, .03 + v * .94
            else:
                u, v = .5, .5
            uv.data[loop].uv = ((index % 4 + u) / 4, (index // 4 + v) / 4)


def add(obj, name, parent, collection, material):
    obj.name = name
    for coll in list(obj.users_collection):
        coll.objects.unlink(obj)
    collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.clear()
    obj.data.materials.append(material)
    return obj


def cube(name, pos, size, parent, coll, mat, key=None, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = add(bpy.context.object, name, parent, coll, mat)
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if key:
        cell_uv(obj, key)
    if bevel:
        mod = obj.modifiers.new('soft_edges', 'BEVEL')
        mod.width, mod.segments = bevel, 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cyl(name, pos, radius, height, parent, coll, mat, key=None, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=height, location=pos)
    obj = add(bpy.context.object, name, parent, coll, mat)
    if key:
        cell_uv(obj, key)
    return obj


def sign(name, pos, width, height, parent, coll, mat, key, facing='service'):
    """Camera-facing plane, flat or front; applied rotation, no text curves exported."""
    circular = key.endswith('_icon')
    if circular:
        bpy.ops.mesh.primitive_circle_add(vertices=24, radius=.5, fill_type='NGON', location=pos)
    else:
        bpy.ops.mesh.primitive_plane_add(size=1, location=pos)
    obj = add(bpy.context.object, name, parent, coll, mat)
    if circular:
        index = KEYS.index(key)
        uv = obj.data.uv_layers.active or obj.data.uv_layers.new()
        for loop in obj.data.loops:
            co = obj.data.vertices[loop.vertex_index].co
            uv.data[loop.index].uv = ((index % 4 + .03 + (co.x + .5) * .94) / 4,
                                     (index // 4 + .03 + (co.y + .5) * .94) / 4)
    obj.scale = (width, height, 1)
    if facing == 'service':
        obj.rotation_euler.x = math.radians(52)
    elif facing == 'front':
        obj.rotation_euler.x = math.radians(-90)
    elif facing == 'side':
        obj.rotation_euler = (math.radians(90), 0, math.radians(90))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if not circular:
        cell_uv(obj, key, True)
    return obj


def empty(name, pos, parent, coll):
    ob = bpy.data.objects.new(name, None)
    coll.objects.link(ob)
    ob.parent = parent
    ob.location = pos
    return ob


def export_piece(collection, anchor, output, budget):
    """Use the repository validator/exporter, temporarily changing collection names."""
    original = bpy.data.collections['export']
    active = bpy.data.collections[collection]
    old_name = active.name
    front = bpy.data.objects[anchor]
    original_front = bpy.data.objects['Anchor_Front']
    if active != original:
        original.name = '_export_inactive'
        active.name = 'export'
        original_front.name = '_Anchor_Front_inactive'
        front.name = 'Anchor_Front'
    argv = sys.argv
    sys.argv = ['blender', '--', '--out', str(output), '--max-tris', str(budget)]
    namespace = {'__name__': '__main__', '__file__': str(ROOT / 'tools/blender_export.py')}
    try:
        exec(compile((ROOT / 'tools/blender_export.py').read_text(encoding='utf8'), namespace['__file__'], 'exec'), namespace)
        tris = namespace['validate'](list(active.all_objects), budget)
    finally:
        sys.argv = argv
        if active != original:
            active.name = old_name
            original.name = 'export'
            front.name = anchor
            original_front.name = 'Anchor_Front'
    return tris


def save(asset):
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art/blender' / (asset + '.blend')))
