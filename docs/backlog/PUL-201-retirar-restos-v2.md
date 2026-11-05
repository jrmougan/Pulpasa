---
id: PUL-201
title: Retirar los restos v2 que ninguna ficha cubre
status: draft
milestone: M4
role: asset-pipeline
deps: [PUL-188]
orca_task: null
unity_sources: []
owns: [art/blender/_materials_v2.blend, art/blender/_template.blend, docs/art/materials-v2.md, docs/art/pipeline.md, tools/blender_export.py, art/blender/environment_v2_src/gen_textures.py, godot/assets/models/_pipeline/**]
touches_scenes: []
---

## Target
`_materials_v2.blend`, `_template.blend` (enlaza los 45 materiales v2), `materials-v2.md`, `--materials-test` y el banco `_pipeline/materials_v2_test/`.

## Change
Tras PUL-188: migrar la plantilla a v3 sin materiales `mat_*` v2, retirar la biblioteca y su documento, y quitar `--materials-test` o rehacerlo para v3. Decidir qué pasa con el banco `_pipeline/**`, hoy excluido por art-bible §3.3.5.

## Constraints
Depende de PUL-188: no se lanza antes. Solo con Blender propio en modo `-b`, sin tocar el puerto 9876.

## Acceptance
(Se concretan al pasar a `ready`, después de PUL-188.)

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
