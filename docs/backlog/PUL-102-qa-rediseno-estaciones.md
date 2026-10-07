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
