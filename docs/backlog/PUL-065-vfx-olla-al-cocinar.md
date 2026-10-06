---
id: PUL-065
title: Encender fuego y vapor de la olla solo al cocinar
status: draft
milestone: M3
role: gameplay-engineer
deps: [PUL-048]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/kitchen.tscn, godot/entities/stations/cooking_station.gd, godot/tests/integration/test_cooking_station.gd, docs/evidence/PUL-065/**]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
Hallazgo de PUL-048: las partículas de fuego y vapor del caldeiro están siempre encendidas. Must 9
(feedback mínimo) pide respuesta visual al cocer.

## Change
Vapor solo con alguna plaza cociendo (más intenso al terminar si se quiere); fuego bajo en reposo y
vivo al cocer, a partir de `cooking_started`/`cooking_finished` (señales locales de la estación).
Se congela con la pausa.

## Constraints
- Sin nuevas señales de `EventBus`. Antes de cerrar: `tools/verify.sh` verde y `check_owns` limpio.

## Acceptance
- [ ] AC1 Sin nada cociendo, el vapor está apagado; al aceptar un ingrediente se enciende → test
- [ ] AC2 En pausa las partículas se congelan → test
- [ ] AC3 Captura antes/durante en `docs/evidence/PUL-065/`
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
