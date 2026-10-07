---
id: PUL-092
title: Reescribir las features de estaciones según D23
status: ready
milestone: M3c
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/estacion-condimentos.md, docs/design/features/condimentacion.md, docs/design/features/corte-pulpo.md, docs/design/features/entrega-y-puntuacion.md, docs/design/features/comandas.md, docs/design/level-layouts.md, docs/evidence/PUL-092/**, docs/backlog/PUL-092-features-estaciones-d23.md]
touches_scenes: []
---

## Target
Features afectadas por D23 (rediseño de estaciones aprobado el 2026-10-07): `estacion-condimentos.md`, `condimentacion.md`, `corte-pulpo.md`, `entrega-y-puntuacion.md`, `comandas.md` y `level-layouts.md`.

## Change
Reescribe las features con el paquete aprobado de `docs/design/rediseno-estaciones.md` §4 (C-B línea al paso, B-A, E-A, N-A, cachelos ×2). Traslada R1–R17 como AC numerados y verificables en cada feature. Recoge las preguntas abiertas §7: `operator_side_only` se mantiene (los dispensadores solo desde el lado de servicio), el antirrebote usa el reloj de juego, y el precio de la L lo decide el playtest. Marca como «sustituido por D23» lo que cambie de D18.

## Constraints
Solo documentación. No toques `godot/` ni `docs/arch/`.

## Acceptance
- [ ] AC1 Cada feature refleja D23 sin contradicciones con `decisions.md` (D3, D4, D13, D18 modificada)
- [ ] AC2 R1–R17 repartidos como AC Given/When/Then con números y su test previsto
- [ ] AC3 Boceto actualizado de la línea al paso y de la planta con el hueco a x≈3,2 (`level-layouts.md`)

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
