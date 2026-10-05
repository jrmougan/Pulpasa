"""Exporta la colección `export` de un .blend a .glb para Godot (D20, PUL-043).

Se ejecuta dentro de Blender, sin pantalla, desde la raíz del repo:

  blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --category <cat>
  blender -b art/blender/<asset>.blend --python tools/blender_export.py -- --out <ruta.glb>
  blender -b art/blender/_template.blend --python tools/blender_export.py -- --smoke-cube

Opciones (tras `--`):
  --category CAT    destino godot/assets/models/CAT/<asset>/<asset>.glb (<asset> = nombre del .blend)
  --out RUTA        destino explícito (.glb), relativo a la raíz del repo o absoluto
  --animations      exporta animaciones (solo el personaje, art-bible §2.4)
  --max-tris N      falla si la colección supera N triángulos (presupuesto de art-bible §2.2)
  --smoke-cube      construye el cubo de prueba sobre la plantilla y lo exporta a
                    godot/assets/models/_pipeline/test_cube/test_cube.glb

Reglas que comprueba antes de exportar (art-bible §2): existe la colección `export`, hay una sola
raíz, todas las escalas y rotaciones de malla están aplicadas, no hay cámaras ni luces y existe el
marcador `Anchor_Front` en +Y (frente −Z en Godot). Sale con código 1 si algo falla.
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

# Ajustes de import que el pipeline fija en cada .glb.import (pipeline.md §4).
IMPORT_PARAMS = {
    "nodes/root_type": '""',
    "nodes/root_name": '""',
    "nodes/apply_root_scale": "true",
    "nodes/root_scale": "1.0",
    "nodes/use_name_suffixes": "false",
    "nodes/use_node_type_suffixes": "false",
    "meshes/ensure_tangents": "false",
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
    me.materials.append(hex_material("mat_wood_light"))
    me.materials.append(hex_material("mat_canvas_stripe"))
    for face in bm.faces:
        face.material_index = 1 if all(v in nose_set for v in face.verts) else 0
    bm.to_mesh(me)
    bm.free()
    body = bpy.data.objects.new("test_cube_body", me)
    body.parent = root
    coll.objects.link(body)


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
        if any(abs(s - 1.0) > EPS for s in o.scale):
            errors.append(f"{o.name}: escala {tuple(round(s, 4) for s in o.scale)} sin aplicar")
        if o.type == "MESH":
            if any(abs(r) > EPS for r in o.rotation_euler):
                errors.append(f"{o.name}: rotación sin aplicar")
            if o.name.endswith(("-col", "-colonly", "-convcol", "-navmesh")):
                errors.append(f"{o.name}: sufijos de colisión prohibidos")
            mesh = o.evaluated_get(depsgraph).to_mesh()
            tris += sum(len(p.vertices) - 2 for p in mesh.polygons)
            o.evaluated_get(depsgraph).to_mesh_clear()
    front = next((o for o in objs if o.name == FRONT_ANCHOR), None)
    if front is None:
        errors.append(f"falta el marcador {FRONT_ANCHOR} (frente en +Y de Blender)")
    else:
        p = front.matrix_world.translation
        if p.y <= abs(p.x):
            errors.append(f"{FRONT_ANCHOR} debe estar delante (+Y), está en {tuple(round(c, 3) for c in p)}")
    if max_tris and tris > max_tris:
        errors.append(f"{tris} triángulos > presupuesto {max_tris}")
    if errors:
        fail("\n  ".join(["validación:"] + errors))
    return tris


def resolve_out(args: argparse.Namespace) -> Path:
    if args.smoke_cube:
        return MODELS_DIR / "_pipeline" / "test_cube" / "test_cube.glb"
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
        export_animations=args.animations,
        export_skins=args.animations,
        export_morph=False,
    )
    write_import_defaults(out)
    size = out.stat().st_size
    rel = out.relative_to(ROOT) if out.is_relative_to(ROOT) else out
    print(f"blender_export: OK {rel} ({len(objs)} objetos, {tris} triángulos, {math.ceil(size / 1024)} KiB)")


main()
