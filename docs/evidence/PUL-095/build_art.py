"""PUL-095: labels, size icons and independent pass/threshold exports."""
import json
import math
from pathlib import Path

import bpy

exec((Path.cwd() / 'docs/evidence/PUL-094/art_helpers.py').read_text(encoding='utf8'))
counts = {}

bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/blender/box.blend'))
mat, image = atlas('box_size_signs')
coll = bpy.data.collections['export']
tray_builder = {}
exec((ROOT / 'docs/evidence/PUL-077/build_box_v2.py').read_text(encoding='utf8'), tray_builder)
tray_builder['SEGS'] = 16  # native widths 29–42px: 16 segments suffice, including full food budget
for key in ('small', 'medium', 'large'):
    tray_builder['SEGS'] = 12 if key == 'large' else 16
    original = bpy.data.objects['box_' + key]
    original_atlas = next(m for m in original.data.materials if m.name.startswith('atlas_box'))
    rebuilt = tray_builder['build_tray'](key, original_atlas, original.parent, coll)
    original.data = rebuilt.data
    bpy.data.objects.remove(rebuilt, do_unlink=True)
    hull = bpy.data.objects['hull_' + key]
    rebuilt_hull = tray_builder['build_hull'](key, hull.parent, coll, hull.data.materials[0])
    hull.data = rebuilt_hull.data
    bpy.data.objects.remove(rebuilt_hull, do_unlink=True)
for key, letter, y in [('small', 'S', -.13), ('medium', 'M', -.12), ('large', 'L', -.15)]:
    parent = bpy.data.objects['box_' + key]
    for obj in list(parent.children):
        if obj.name.startswith('Size'):
            bpy.data.objects.remove(obj, do_unlink=True)
    cube('SizeRim_' + key, (0, y, .098), (.17, .11, .007), parent, coll, mat, 'navy')
    sign('SizeLetter_' + key, (0, y - .007, .134), .14, .14, parent, coll, mat, letter)
save('box')
counts['box_all_variants'] = export_piece('export', 'Anchor_Front',
    ROOT / 'godot/assets/models/items/box/box.glb', 6000)
# PNG silhouettes and letters derived from exactly the same atlas glyphs.
atlas_pixels = list(image.pixels)
for letter, ex, ey, rectangular in [('S', 88, 88, False), ('M', 110, 76, False), ('L', 110, 84, True)]:
    icon = bpy.data.images.new('size_' + letter, width=256, height=256, alpha=True)
    rgba = [0.0] * (256 * 256 * 4)
    navy, paper = rgb(COLORS['navy']), rgb(COLORS['paper'])
    tile = KEYS.index(letter)
    for y in range(256):
        for x in range(256):
            inside = (abs(x - 128) < ex and abs(y - 128) < ey) if rectangular else ((x - 128) / ex)**2 + ((y - 128) / ey)**2 < 1
            if inside:
                dst = (y * 256 + x) * 4
                rgba[dst:dst + 4] = navy + (1.0,)
                if 64 <= x < 192 and 64 <= y < 192:
                    src = ((tile // 4 * 128 + y - 64) * 512 + tile % 4 * 128 + x - 64) * 4
                    if atlas_pixels[src] < .3:
                        rgba[dst:dst + 4] = paper + (1.0,)
    icon.pixels.foreach_set(rgba)
    folder = ROOT / 'godot/assets/textures/ui/box_sizes'
    folder.mkdir(parents=True, exist_ok=True)
    icon.filepath_raw = str(folder / ('size_' + letter.lower() + '.png'))
    icon.file_format = 'PNG'
    icon.save()

bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/blender/box_shelf.blend'))
mat, image = atlas('rack_size_signs')
coll = bpy.data.collections['export']
parent = bpy.data.objects['box_shelf']
for obj in list(coll.objects):
    if obj.name.startswith(('Size', 'Rack')) and obj != parent:
        bpy.data.objects.remove(obj, do_unlink=True)
for key, letter, x in [('small', 'S', -.51), ('medium', 'M', 0), ('large', 'L', .536)]:
    # Original front, plus a horizontal label that remains readable after the level's 90° yaw.
    cube('SizePanel_' + key, (x, 1.064, .23), (.30, .012, .23), parent, coll, mat, 'navy')
    sign('SizeFront_' + key, (x, 1.072, .23), .23, .20, parent, coll, mat, letter, 'front')
    # Labels alongside each stack rather than on one common end panel: no S/M/L ambiguity.
    cube('RackTopPanel_' + key, (x, .76, .575), (.31, .31, .014), parent, coll, mat, 'navy')
    ob = sign('RackTopLetter_' + key, (x, .76, .585), .28, .28, parent, coll, mat, letter, 'flat')
    ob.rotation_euler.z = math.pi / 2
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
save('box_shelf')
counts['box_shelf'] = export_piece('export', 'Anchor_Front',
    ROOT / 'godot/assets/models/stations/box_shelf/box_shelf.glb', 6000)

bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/blender/counters.blend'))
mat, image = atlas('counter_pass_signs')
for name in ('pass_mark', 'pass_threshold'):
    collection_name = 'export_' + name
    if collection_name in bpy.data.collections:
        for obj in list(bpy.data.collections[collection_name].objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(bpy.data.collections[collection_name])
    coll = bpy.data.collections.new(collection_name)
    bpy.context.scene.collection.children.link(coll)
    parent = empty(name, (0, 0, 0), None, coll)
    empty('Anchor_Front_' + name, (0, .5, 0), parent, coll)
    if name == 'pass_mark':
        # Local base sits on the slot's surface; total height 5cm satisfies model validator.
        cube('PaperField', (0, 0, -.007), (.72, .52, .05), parent, coll, mat, 'paper', bevel=.015)
        for sx in (-1, 1):
            for sy in (-1, 1):
                cube('CornerX', (sx * .26, sy * .20, .019), (.17, .05, .002), parent, coll, mat, 'navy')
                cube('CornerY', (sx * .32, sy * .15, .019), (.05, .15, .002), parent, coll, mat, 'navy')
    else:
        # Floor trim, base down 3cm: visible relief is 2cm, not an obstacle.
        cube('ThresholdBody', (0, 0, -.005), (1.0, .46, .05), parent, coll,
             bpy.data.materials['mat_rubber'], bevel=.01)
        for sx in (-1, 1):
            cube('ThresholdEdge', (sx * .46, 0, .019), (.07, .44, .002), parent, coll, mat, 'paper')
        sign('ThresholdArrow', (0, 0, .020), .30, .37, parent, coll, mat, 'arrow', 'flat')
    counts[name] = export_piece(collection_name, 'Anchor_Front_' + name,
        ROOT / 'godot/assets/models/furniture/counters' / (name + '.glb'), 800)
save('counters')
(ROOT / 'docs/evidence/PUL-095/budget.json').write_text(json.dumps(counts, indent=2))
print('PUL-095 budgets', counts)
