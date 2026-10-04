---
id: PUL-053
title: Modelar el puesto de entrega
status: draft
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-039]
orca_task: null
unity_sources: []
owns: [art/blender/order_stand.blend, godot/assets/models/stations/order_stand/**, godot/entities/stations/order_stand.tscn, docs/evidence/PUL-053/**]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Mostrador/ventanilla de feria con número de puesto visible y sitio para el `#id` de la comanda.
2. Fuente en `art/blender/order_stand.blend`; export `.glb` en `godot/assets/models/stations/order_stand/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Si PUL-039 sigue abierta, espera a su merge (comparte `order_stand.tscn`).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-053/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
