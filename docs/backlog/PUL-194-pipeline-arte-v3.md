---
id: PUL-194
title: Pasar el pipeline de arte y blender_export a la estética v3
status: review
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
- [x] AC1 Given `blender_export.py`, When se inspeccionan los parámetros de import, Then `gltf/embedded_image_handling` es 0 → salida en docs/evidence/PUL-194/
- [x] AC2 Given `pipeline.md`, When se contrasta con art-bible §3, Then no queda ninguna instrucción v2 presentada como vigente → tabla en docs/evidence/PUL-194/
- [x] AC3 Given Blender 5.2 en modo `-b` con una escena de prueba temporal, When se exporta, Then se genera un `.glb` en el destino temporal; si no se puede, «no verificable» con motivo → salida en docs/evidence/PUL-194/

## Plan
1. `IMPORT_PARAMS` de `blender_export.py`: `gltf/embedded_image_handling` = 0 y `meshes/ensure_tangents` = false (la biblia prohibe texturas y normal maps); el export deja de escribir tangentes; docstring al dia.
2. `pipeline.md`: reescribir §3, §5, §7 y §8 para v3, revisar §4 (`materials_v2_test`), referencias `art-bible §2.x` a `art-bible-v1`, y documentar Blender en Windows solo con lo probado (§1.1).
3. `asset-pipeline.md`: retirar el aviso de v2.
4. Pruebas en directorio temporal: export headless con Blender 5.2 de una escena de prueba y `tools/verify.sh --quick`.

## Evidence
- **AC1** (`docs/evidence/PUL-194/ac1_import_params.txt`): `IMPORT_PARAMS` impreso del fichero; `gltf/embedded_image_handling` = 0. Tambien `meshes/ensure_tangents` = false.
- **AC2** (`docs/evidence/PUL-194/ac2_pipeline_vs_artbible.md`): tabla v2 -> regla v3 -> estado nuevo. Las menciones v2 restantes son de lo que sigue en el repo hasta PUL-188, dichas como tal.
- **AC3** (`docs/evidence/PUL-194/ac3_export_salida.txt`): Blender 5.2.3 LTS en `-b` abre `_template.blend` (no se guarda), un script temporal anade un cubo y llama a `tools/blender_export.py --out <tmp>/...`. Resultado: `blender_export: OK ... (3 objetos, 12 triangulos, 2 KiB)`, `.glb` valido (cabecera `glTF`) y `.glb.import` sembrado con `embedded_image_handling=0`. Nada nuevo dentro de `godot/` (`git status`).
- **verify** (`docs/evidence/PUL-194/verify_quick.txt`): `tools/verify.sh --quick` en verde, exit 0.
- **Windows** (pipeline.md §1.1): probado export headless y `tools/blender_mcp.sh start/status/stop` bajo Git Bash con puerto propio (19876) y `BLENDER_PATH` al `.exe`; el puerto 9876 no se toco. Funciona porque Git Bash emula `/proc` y `/dev/tcp`; con `XDG_RUNTIME_DIR` ausente usa `/tmp`. No verificable: macOS (sin maquina), `uvx blender-mcp` desde Claude en Windows, variantes `_for_cli`.
- **Versiones**: documentado «Blender 5.2 LTS (Flathub)»; instalado 5.2.3 LTS (instalador oficial, no Flathub). Add-on MCP 1.0.3 coincide. Python 3.13.18, uv 0.12.24, Godot 4.7.2: sin diferencias. No se cambio ninguna version fijada.
- **Revision (correcciones)**: (1) `export_image_format` = `NONE` y `check_textures` solo en `--materials-test`; `--smoke-cube` probado en destino temporal con copias de `_template.blend` y `_materials_v2.blend` sin `textures/v2` alcanzable: exit 0, 2,9 KiB, sin imagenes. Queda documentado (§3) que el color base v2 llega a Godot hasta redirigir el slot. (2) Falso lo de `embedded_image_handling=1`: los 40 `.glb.import` estan en 0; 30 conservan `ensure_tangents=true` sin ficha (§5 corregido). (3) Frase de §3 corregida. (4) Regla unica de slot (§2, §3, §7, §8.1). (5) docstring a `art-bible-v1`. (6) §8.4 condicionado. (7) `asset-pipeline.md` remite a §1.1. (8) `--python 3.13` en el bloque de `.mcp.json`. (9) linea en blanco antes de §4.
- **Pendiente de decidir**: ninguna ficha (ni PUL-188) retira `_materials_v2.blend`, `_template.blend` (aun enlaza la v2) ni `materials-v2.md`. `--materials-test` sigue en el script (escribe en `godot/`); no se ejecuto. La plantilla no seeda `_subresources`: el mapeo de slots sigue siendo manual.
- No se re-exporto ningun asset del repo ni se dejaron generados en `godot/`.
