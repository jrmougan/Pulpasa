---
id: PUL-050
title: Modelar la cachelera (saco o cesto de patatas)
status: draft
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/cachelos_storage.blend, godot/assets/models/stations/cachelos_storage/**, godot/entities/stations/cachelos_storage.tscn, godot/assets/models/placeholders/cachelera*, docs/evidence/PUL-050/**]
touches_scenes: [godot/entities/stations/cachelos_storage.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Saco de arpillera o cesto de patatas crudas.
2. Fuente en `art/blender/cachelos_storage.blend`; export `.glb` en `godot/assets/models/stations/cachelos_storage/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-050/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
