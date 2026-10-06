"""Exporta la colección `export` de un .blend a .glb para Godot (D20, PUL-043).

Se ejecuta dentro de Blender, sin pantalla, desde la raíz del repo:

  blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --category <cat>
  blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --out <ruta.glb>
  blender -b art/blender/_template.blend --python tools/blender_export.py -- --smoke-cube
  blender -b art/blender/_template.blend --python tools/blender_export.py -- --materials-test

Opciones (tras `--`):
  --category CAT    destino godot/assets/models/CAT/<asset>/<asset>.glb (<asset> = nombre del .blend)
  --out RUTA        destino explícito (.glb), relativo a la raíz del repo o absoluto
  --animations      exporta animaciones (solo el personaje, art-bible §2.4)
  --max-tris N      falla si la colección supera N triángulos (presupuesto de art-bible §2.2)
  --smoke-cube      construye el cubo de prueba sobre la plantilla y lo exporta a
                    godot/assets/models/_pipeline/test_cube/test_cube.glb
  --materials-test  construye un taburete con tres materiales v2 (PUL-074) y lo exporta a
                    godot/assets/models/_pipeline/materials_v2_test/materials_v2_test.glb

Reglas que comprueba antes de exportar (art-bible §2): existe la colección `export`, hay una sola
raíz, escalas y rotaciones aplicadas en todos los objetos (local y mundo), no hay cámaras ni luces y existe el
marcador `Anchor_Front` en +Y con ≤ 1° de desviación (frente −Z en Godot). Texturas (biblioteca v2,
docs/art/materials-v2.md): cada imagen de los materiales exportados existe en disco y mide ≤ 1024 px por
lado (art-bible v2 §4.2); el .glb las embebe y Godot las extrae junto a él al importar. Sale con código 1
si algo falla.
"""

import argparse
import math
import sys
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = ROOT / "godot" / "assets" / "models"
CATEGORIES = ("characters", "food", "items", "stations", "furniture", "environment", "_pipeline")
EXPORT_COLLECTION = "export"
FRONT_ANCHOR = "Anchor_Front"
EPS = 1e-4
ROT_EPS = math.radians(0.01)
FRONT_MAX_ANGLE_DEG = 1.0

# Ajustes de import que el pipeline fija en cada .glb.import (pipeline.md §4).
IMPORT_PARAMS = {
    "nodes/root_type": '""',
    "nodes/root_name": '""',
    "nodes/apply_root_scale": "true",
    "nodes/root_scale": "1.0",
    "nodes/use_name_suffixes": "false",
    "nodes/use_node_type_suffixes": "false",
    "meshes/ensure_tangents": "true",
    "meshes/generate_lods": "true",
    "meshes/create_shadow_meshes": "true",
    "meshes/light_baking": "1",
    "materials/extract": "0",
    "animation/import": "true",
    "animation/fps": "30",
    "gltf/naming_version": "2",
    "gltf/embedded_image_handling": "1",
}


def fail(msg: str) -> None:
    print(f"blender_export: ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    p = argparse.ArgumentParser(prog="blender_export.py")
    p.add_argument("--category", choices=CATEGORIES)
    p.add_argument("--out")
    p.add_argument("--animations", action="store_true")
    p.add_argument("--max-tris", type=int, default=0)
    p.add_argument("--smoke-cube", action="store_true")
    p.add_argument("--materials-test", action="store_true")
    return p.parse_args(argv)


def hex_material(name: str) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        fail(f"falta el material {name} (usa los mat_* de la plantilla)")
    return mat


def build_smoke_cube() -> None:
    """Cubo de 1 m con origen en el centro de la base y una 'nariz' roja en el frente (+Y)."""
    coll = bpy.data.collections[EXPORT_COLLECTION]
    root = bpy.data.objects["asset"]
    root.name = "test_cube"
    me = bpy.data.meshes.new("test_cube_body")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0.0, 0.0, 0.5))
    nose = bmesh.ops.create_cube(bm, size=1.0)["verts"]
    bmesh.ops.scale(bm, verts=nose, vec=(0.3, 0.2, 0.3))
    bmesh.ops.translate(bm, verts=nose, vec=(0.0, 0.6, 0.5))
    nose_set = set(nose)
    me.materials.append(hex_material("mat_wood_used"))
    me.materials.append(hex_material("mat_plastic_red"))
    for face in bm.faces:
        face.material_index = 1 if all(v in nose_set for v in face.verts) else 0
    bm.to_mesh(me)
    bm.free()
    body = bpy.data.objects.new("test_cube_body", me)
    body.parent = root
    coll.objects.link(body)


def box_uv(bm: bmesh.types.BMesh, meters_per_unit: float = 2.0) -> None:
    """Proyección de caja a la densidad de la biblioteca v2: 1 unidad de UV = 2 m (256 px/m)."""
    uv = bm.loops.layers.uv.verify()
    for face in bm.faces:
        n = face.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            co = loop.vert.co
            u, v = ((co.y, co.z), (co.x, co.z), (co.x, co.y))[ax]
            loop[uv].uv = (u / meters_per_unit, v / meters_per_unit)


def build_materials_test() -> None:
    """Taburete de 0,45 m: patas y travesaños de acero, asiento de plástico rojo y balda de madera.

    Prueba de AC2 de PUL-074: un asset con materiales enlazados de _materials_v2.blend importa en
    Godot con sus texturas (albedo, ORM y normal) y pasa test_assets_models.gd.
    """
    coll = bpy.data.collections[EXPORT_COLLECTION]
    root = bpy.data.objects["asset"]
    root.name = "materials_v2_test"
    parts = (
        ("materials_v2_test_frame", "mat_steel_brushed"),
        ("materials_v2_test_seat", "mat_plastic_red"),
        ("materials_v2_test_shelf", "mat_wood_used"),
    )
    for name, mat_name in parts:
        bm = bmesh.new()
        if name.endswith("frame"):
            for sx in (-1, 1):
                for sy in (-1, 1):
                    leg = bmesh.ops.create_cube(bm, size=1.0)["verts"]
                    bmesh.ops.scale(bm, verts=leg, vec=(0.04, 0.04, 0.42))
                    bmesh.ops.translate(bm, verts=leg, vec=(sx * 0.15, sy * 0.15, 0.21))
        elif name.endswith("seat"):
            seat = bmesh.ops.create_cone(bm, segments=24, radius1=0.21, radius2=0.2, depth=0.04, cap_ends=True)
            bmesh.ops.translate(bm, verts=seat["verts"], vec=(0.0, 0.0, 0.44))
        else:
            shelf = bmesh.ops.create_cube(bm, size=1.0)["verts"]
            bmesh.ops.scale(bm, verts=shelf, vec=(0.34, 0.34, 0.025))
            bmesh.ops.translate(bm, verts=shelf, vec=(0.0, 0.0, 0.15))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        box_uv(bm)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for poly in me.polygons:
            poly.use_smooth = name.endswith("seat")
        me.materials.append(hex_material(mat_name))
        ob = bpy.data.objects.new(name, me)
        ob.parent = root
        coll.objects.link(ob)


def check_textures(objs: list) -> list:
    """Imágenes de los materiales exportados: deben existir y medir ≤ 1024 px (art-bible v2 §4.2)."""
    errors, seen = [], set()
    for o in objs:
        if o.type != "MESH":
            continue
        for slot in o.material_slots:
            mat = slot.material
            if mat is None or mat.node_tree is None or mat.name in seen:
                continue
            seen.add(mat.name)
            for node in mat.node_tree.nodes:
                img = getattr(node, "image", None)
                if node.type != "TEX_IMAGE" or img is None:
                    continue
                path = Path(bpy.path.abspath(img.filepath, library=img.library))
                if img.packed_file is None and not path.is_file():
                    errors.append(f"{mat.name}: falta la textura {path}")
                elif max(img.size) > 1024:
                    errors.append(f"{mat.name}: textura {img.name} de {tuple(img.size)} > 1024 px")
    return errors


def collection_objects() -> list:
    coll = bpy.data.collections.get(EXPORT_COLLECTION)
    if coll is None:
        fail(f"el .blend no tiene la colección '{EXPORT_COLLECTION}' (parte de art/blender/_template.blend)")
    return list(coll.all_objects)


def validate(objs: list, max_tris: int) -> int:
    if not objs:
        fail(f"la colección '{EXPORT_COLLECTION}' está vacía")
    names = {o.name for o in objs}
    roots = [o for o in objs if o.parent is None or o.parent.name not in names]
    if len(roots) != 1:
        fail(f"debe haber una sola raíz en '{EXPORT_COLLECTION}', hay {[o.name for o in roots]}")
    errors = []
    tris = 0
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type in {"CAMERA", "LIGHT"}:
            errors.append(f"{o.name}: cámaras y luces no se exportan")
        if o.name.endswith(("-col", "-colonly", "-convcol", "-navmesh")):
            errors.append(f"{o.name}: sufijos de colisión prohibidos")
        # Se comprueban la transformación local y la de mundo de TODOS los objetos (también
        # Empty y raíz): una rotación o escala en un padre se propaga a lo exportado.
        for label, matrix in (("local", o.matrix_basis), ("mundo", o.matrix_world)):
            _loc, rot, scale = matrix.decompose()
            if any(abs(s - 1.0) > EPS for s in scale):
                errors.append(f"{o.name}: escala {label} {tuple(round(s, 4) for s in scale)} sin aplicar")
            if abs(rot.angle) > ROT_EPS:
                errors.append(f"{o.name}: rotación {label} de {math.degrees(rot.angle):.2f}° sin aplicar")
        if o.type == "MESH":
            mesh = o.evaluated_get(depsgraph).to_mesh()
            tris += sum(len(p.vertices) - 2 for p in mesh.polygons)
            o.evaluated_get(depsgraph).to_mesh_clear()
    front = next((o for o in objs if o.name == FRONT_ANCHOR), None)
    if front is None:
        errors.append(f"falta el marcador {FRONT_ANCHOR} (frente en +Y de Blender)")
    else:
        p = front.matrix_world.translation
        where = tuple(round(c, 3) for c in p)
        if math.hypot(p.x, p.y) < EPS:
            errors.append(f"{FRONT_ANCHOR} sobre el origen: no define frente ({where})")
        else:
            deviation = math.degrees(math.atan2(p.x, p.y))
            if abs(deviation) > FRONT_MAX_ANGLE_DEG:
                errors.append(f"{FRONT_ANCHOR} desviado {deviation:.1f}° de +Y, está en {where}")
    errors += check_textures(objs)
    if max_tris and tris > max_tris:
        errors.append(f"{tris} triángulos > presupuesto {max_tris}")
    if errors:
        fail("\n  ".join(["validación:"] + errors))
    return tris


def resolve_out(args: argparse.Namespace) -> Path:
    if args.smoke_cube:
        return MODELS_DIR / "_pipeline" / "test_cube" / "test_cube.glb"
    if args.materials_test:
        return MODELS_DIR / "_pipeline" / "materials_v2_test" / "materials_v2_test.glb"
    if args.out:
        out = Path(args.out)
        return out if out.is_absolute() else ROOT / out
    if args.category:
        stem = Path(bpy.data.filepath).stem
        if stem.startswith("_"):
            fail("no se exporta la plantilla: guárdala como art/blender/<asset>.blend")
        return MODELS_DIR / args.category / stem / f"{stem}.glb"
    fail("indica --category, --out o --smoke-cube")
    return Path()


def write_import_defaults(glb: Path) -> None:
    """Siembra el .glb.import con los ajustes del pipeline si aún no existe.

    Godot conserva la sección [params] al importar y completa uid, rutas y el resto de claves.
    """
    imp = glb.with_name(glb.name + ".import")
    if imp.exists():
        return
    lines = ["[remap]", "", 'importer="scene"', "importer_version=1", 'type="PackedScene"', "", "[params]", ""]
    lines += [f"{k}={v}" for k, v in IMPORT_PARAMS.items()]
    imp.write_text("\n".join(lines) + "\n", encoding="utf-8")


def select_export_collection() -> None:
    def find(layer_coll):
        if layer_coll.collection.name == EXPORT_COLLECTION:
            return layer_coll
        for child in layer_coll.children:
            hit = find(child)
            if hit is not None:
                return hit
        return None

    layer = find(bpy.context.view_layer.layer_collection)
    if layer is None or layer.exclude:
        fail(f"la colección '{EXPORT_COLLECTION}' no está activa en la view layer")
    bpy.context.view_layer.active_layer_collection = layer


def main() -> None:
    args = parse_args()
    if args.smoke_cube:
        build_smoke_cube()
    if args.materials_test:
        build_materials_test()
    objs = collection_objects()
    tris = validate(objs, args.max_tris)
    out = resolve_out(args)
    if out.suffix != ".glb":
        fail(f"el destino debe ser .glb: {out}")
    out.parent.mkdir(parents=True, exist_ok=True)
    select_export_collection()
    bpy.ops.export_scene.gltf(
        filepath=str(out),
        export_format="GLB",
        use_active_collection=True,
        use_active_collection_with_nested=True,
        use_visible=False,
        export_yup=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=False,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_tangents=True,
        export_animations=args.animations,
        export_skins=args.animations,
        export_morph=False,
    )
    write_import_defaults(out)
    size = out.stat().st_size
    rel = out.relative_to(ROOT) if out.is_relative_to(ROOT) else out
    print(f"blender_export: OK {rel} ({len(objs)} objetos, {tris} triángulos, {math.ceil(size / 1024)} KiB)")


main()
