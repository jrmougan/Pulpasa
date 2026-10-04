---
id: PUL-044
title: Modelar y animar el personaje (dos variantes)
status: draft
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/cook.blend, godot/assets/models/characters/cook/**, godot/entities/player/player.tscn, godot/entities/player/player_animation.gd, godot/tests/integration/test_player_animation.gd, docs/evidence/PUL-044/**]
touches_scenes: [godot/entities/player/player.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Personaje cocinero/a de pulpería con dos variantes de color (J1, J2; paleta en la biblia). Rig y clips Idle, Walk, Pick, WalkWhileHolding y Cut (corte con pulsación repetida, D13). Sustituye a PUL-013 (bloqueada por licencia).
2. Fuente en `art/blender/cook.blend`; export `.glb` en `godot/assets/models/characters/cook/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. AnimationTree con StateMachine (`speed`, `is_holding`) como pedía PUL-013; el aro de PUL-035 sigue visible.
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-044/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
