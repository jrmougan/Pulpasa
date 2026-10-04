---
id: PUL-045
title: Modelar el pulpo crudo, cocido y troceado
status: draft
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/octopus.blend, godot/assets/models/food/octopus/**, godot/entities/items/octopus.tscn, docs/evidence/PUL-045/**]
touches_scenes: [godot/entities/items/octopus.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Pulpo entero crudo (rosado-grisáceo) y cocido (rojo-morado), legibles y distintos desde la cámara; trozos de pulpo «á feira» para el contenido de la caja.
2. Fuente en `art/blender/octopus.blend`; export `.glb` en `godot/assets/models/food/octopus/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-045/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
