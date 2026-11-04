---
id: PUL-194
title: Pasar el pipeline de arte y blender_export a la estética v3
status: ready
milestone: M4
role: asset-pipeline
deps: []
orca_task: null
unity_sources: []
owns: [tools/blender_export.py, docs/art/pipeline.md, .claude/agents/asset-pipeline.md]
touches_scenes: []
---

## Target
`tools/blender_export.py`, `docs/art/pipeline.md` y `.claude/agents/asset-pipeline.md`.

## Change
`pipeline.md` y `blender_export.py` siguen en v2 y contradicen `docs/art/art-bible.md` §3: un `.glb` nuevo recibe `gltf/embedded_image_handling` = 1 y vuelve a extraer los PNG prohibidos.

- `IMPORT_PARAMS` de `blender_export.py` con `gltf/embedded_image_handling` = 0, y lo demás que la biblia exija para un `.glb` nuevo.
- `pipeline.md`: reescribir §3, §5 y §8 para v3 (D28). La biblioteca v2 sigue en el repo hasta PUL-188: decirlo sin afirmar que ya no existe. Revisar la prueba de humo `materials_v2_test` de §4.
- Documentar Blender en Windows solo con lo que compruebes aquí (hay Blender 5.2 en `C:/Program Files/Blender Foundation`, fuera del PATH); macOS, solo si se puede probar. `tools/blender_mcp.sh` usa `XDG_RUNTIME_DIR` y `/proc`: si no funciona en Windows, decirlo.
- `asset-pipeline.md`: retirar el aviso de que §3, §5 y §8 siguen en v2.

## Constraints
No toques un Blender que no hayas lanzado ni el puerto 9876. No cambies las versiones fijadas de herramientas: si la documentada difiere de la instalada, anótalo en Evidence. No re-exportes assets del repo ni dejes ficheros generados dentro de `godot/`: las pruebas van a un directorio temporal. PUL-188 sigue siendo quien borra lo v2.

## Acceptance
- [ ] AC1 Given `blender_export.py`, When se inspeccionan los parámetros de import, Then `gltf/embedded_image_handling` es 0 → salida en docs/evidence/PUL-194/
- [ ] AC2 Given `pipeline.md`, When se contrasta con art-bible §3, Then no queda ninguna instrucción v2 presentada como vigente → tabla en docs/evidence/PUL-194/
- [ ] AC3 Given Blender 5.2 en modo `-b` con una escena de prueba temporal, When se exporta, Then se genera un `.glb` en el destino temporal; si no se puede, «no verificable» con motivo → salida en docs/evidence/PUL-194/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
