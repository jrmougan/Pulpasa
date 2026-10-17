---
id: PUL-188
title: Integrar Feira Clara en level_01 y limpiar materiales y texturas v2 sin uso
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-183, PUL-184, PUL-185, PUL-186, PUL-187]
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/level_01.tscn, godot/assets/materials/v2/**, godot/assets/textures/v2/**, godot/assets/models/**/*.png, godot/assets/models/**/*.png.import, godot/assets/models/furniture/counters/kitchen_floor_dirt.tres*, art/blender/romeria.blend, godot/tests/unit/test_assets_models.gd, docs/evidence/PUL-188/**, docs/backlog/PUL-188-integracion-level01-y-limpieza-v2.md]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
Integrar la estética v3 «Feira Clara» en `godot/scenes/levels/level_01.tscn` (única ficha que toca `level_01.tscn`), eliminar del repositorio todos los materiales y texturas PBR de la v2 que quedan sin uso (absorbiendo y superando `PUL-146`), retirar `art/blender/romeria.blend` y blindar en `godot/tests/unit/test_assets_models.gd` que ningún `.glb` ni escena referencie materiales o texturas PBR obsoletas.

## Change
1. En `godot/scenes/levels/level_01.tscn`:
   - Verificar que todas las instancias de entorno, layout de cocina, estaciones, puestos y UI cargan limpiamente con los recursos v3 de `PUL-183..PUL-187`, sin overrides obsoletos de la v2 y sin alterar ni un solo transform de estaciones, colisiones, `CameraRig` ni `Marker3D` (**0.0 px** de deriva).
2. Limpieza de materiales y texturas v2 sin uso (§3.2 y §8.1):
   - Eliminar los 45 materiales PBR de `godot/assets/materials/v2/**` y `godot/assets/models/furniture/counters/kitchen_floor_dirt.tres`.
   - Eliminar la biblioteca de texturas procedurales PBR `godot/assets/textures/v2/**` (incluidos sus scripts generadores en `textures/v2/_src/`).
   - Eliminar las texturas PBR extraídas junto a los modelos en `godot/assets/models/**/*.png` y sus `.png.import` (con `gltf/embedded_image_handling = 0` en PUL-186 y PUL-187 no se volverán a extraer al reimportar; conservando únicamente la textura plana de la placa `res://assets/textures/brand/tent_plate_albedo.png` para `mat_tent_plate.tres`, y las texturas planas de señalética funcional).
   - Eliminar `art/blender/romeria.blend` (archivo fuente monolítico de la v1 de 2,7 MB, D9b de `PUL-146`).
3. En `godot/tests/unit/test_assets_models.gd`:
   - Añadir un test que verifique que:
     - existen `0` archivos `.tres` en `res://assets/materials/v2/` y `0` texturas en `res://assets/textures/v2/`;
     - existen `0` texturas `*_orm.png` y `*_normal.png` bajo `res://assets/models/`;
     - al instanciar los modelos `.glb` de producción (excluyendo modelos de prueba en `_pipeline/**` y materiales funcionales: `mat_outline_hull`, `delivery_zone_off.tres`, `mat_sticker_atlas` y señalética), todos sus materiales de superficie activos son recursos de `res://assets/materials/v3/` (≤ 18 `.tres` únicos del catálogo plano).

## Constraints
- No modificar posiciones, rotaciones ni escalas de ningún nodo en `level_01.tscn` (`test_level_01.gd` debe pasar íntegro sin editarse en esta ficha).
- No borrar `godot/assets/textures/brand/**` ni `godot/assets/ui/**` (iconos D26 y §3.4).

## Acceptance
- [ ] AC1 Given el árbol de archivos de `godot/assets/`, When `test_assets_models.gd` escanea `res://assets/materials/v2/`, `res://assets/textures/v2/` y `res://assets/models/`, Then hay `0` archivos en `materials/v2/` y `textures/v2/`, `0` archivos `*_orm.png` o `*_normal.png` en `assets/models/`, y `art/blender/romeria.blend` no existe.
- [ ] AC2 Given todos los `.glb` de producción bajo `res://assets/models/` (excluyendo `_pipeline/**` y slots funcionales como `mat_outline_hull`, `delivery_zone_off.tres` y `mat_sticker_atlas`), When `test_assets_models.gd` los instancia y recolecta los `Material` usados por sus `MeshInstance3D`, Then el conjunto de rutas `.tres` únicas de superficie pertenece a `res://assets/materials/v3/` y su cardinalidad es **≤ 18**.
- [ ] AC3 Given `godot/scenes/levels/level_01.tscn`, When se ejecuta la suite de integración (`test_level_01.gd`), Then pasan todos los tests de contrato, alcanzabilidad, cámara y layout con `0` warnings de recursos huérfanos o rutas rotas.
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
