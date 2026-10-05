---
id: PUL-062
title: Pasar el QA de la estación y la planta B y preparar el playtest
status: draft
milestone: M2
role: qa-tester
deps: [PUL-061]
orca_task: null
unity_sources: []
owns: [docs/design/m2b-gate.md, godot/tests/integration/test_m2b_flow.gd, godot/tests/integration/test_m2b_flow.gd.uid, docs/evidence/PUL-062/**]
touches_scenes: []
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 7. Cierre de los rediseños del playtest de M2.

## Change
Regresión completa con el MCP (Individual y Local 2P, a ritmo humano), `test_m2b_flow.gd` y guía de
playtest `docs/design/m2b-gate.md`: tiempo medio por comanda con condimentos, pulsaciones de error,
uso del cambio de personaje y preguntas abiertas de la feature (una o dos bandejas, rodeo,
raciones de cachelos, `operator_side_only`).

## Constraints
- Solo QA: lo que falle se reporta al coordinador. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Una partida completa por modo sin errores en consola y con al menos 3 entregas
- [ ] AC2 Guía de playtest y capturas
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
