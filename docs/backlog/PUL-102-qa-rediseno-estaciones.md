---
id: PUL-102
title: Medir el rediseño de estaciones y preparar el playtest
status: ready
milestone: M3c
role: qa-tester
deps: [PUL-101]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-102/**, docs/design/m3c-gate.md, docs/backlog/PUL-102-qa-rediseno-estaciones.md]
touches_scenes: []
---

## Target
Rama de integración tras PUL-097..PUL-101.

## Change
Adapta `docs/evidence/PUL-090/measure_flow.gd` (copia en tu evidencia) al flujo nuevo y compara con `PUL-090/metrics.json`. Regresión con `tools/verify.sh` y partida corta en Individual y Local 2P sin errores. Escribe `docs/design/m3c-gate.md` con qué probar en el playtest humano.

Hallazgos de revisión a comprobar en QA: (1) el cuenco con 2 y con 4 raciones casi no se distingue desde la cámara (arte de PUL-094); (2) `fill_per_press` de M es 0.16666667: si se redondea a la baja, el pulpo no llega a 0 y no se libera, porque `Ingredient.take` compara `remaining <= 0.0` sin épsilon. Propuesta para una ficha nueva: `presses_to_fill: int` en `BoxData` y épsilon en `ingredient.gd`; (3) los Godot de varios worktrees comparten `user://` (`app_userdata/Pulpasa`); la caída de un `verify.sh` en paralelo la causó un `taskkill /IM godot.exe` de otro worker, así que no hay que matar Godot por nombre de imagen; (4) el ticket mantiene 212 px y recorta nombres largos («Pulpo Individ…»): validar en el playtest si se entiende o hace falta un nombre corto en `RecipeData`.

## Constraints
No cambies código del juego; los fallos se reportan con pasos. Godot con `--audio-driver Dummy` (MCP: silencia los buses).

## Acceptance
- [ ] AC1 R15: Individual sin cambio, pedido S desde cero ≤ 50 m
- [ ] AC2 R17: Coop, media de pedidos 2–4 ≤ 4,6 s del bot; tabla antes/después
- [ ] AC3 Partidas sin errores y `m3c-gate.md` listo

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
