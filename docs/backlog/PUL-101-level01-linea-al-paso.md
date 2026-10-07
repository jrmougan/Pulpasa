---
id: PUL-101
title: Montar level_01 con la línea al paso, el hueco nuevo y 6 pasaplatos
status: ready
milestone: M3c
role: gameplay-engineer
deps: [PUL-097, PUL-098, PUL-100]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/slot.tscn, godot/entities/stations/slot.gd, godot/components/hold_component.gd, godot/tests/**/test_slot.gd, godot/tests/**/test_hold*.gd, godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn, godot/tests/integration/level_walker.gd, godot/tests/integration/test_level_01.gd, docs/evidence/PUL-101/**, docs/backlog/PUL-101-level01-linea-al-paso.md]
touches_scenes: [godot/entities/stations/slot.tscn, godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn]
---

## Target
Nivel `level_01` (planta B) según D23 y `level-layouts.md` reescrito.

## Change
Hueco de la barra a x≈3,2 con el umbral de PUL-095; 6 `PassSlot` con `pass_mark` visible y el resto de la barra sin `Slot`; estación sin bandeja; `GAP_X` del `level_walker`. `pass_mark` va en `slot.tscn` (ADR-003 §9). Si R11 exige que pulsar fuera de un `PassSlot` no suelte la caja, cámbialo en `HoldComponent` con su test. Retira los restos ocultos de QA D9 en `PassSlot` (placeholder `table_square`).

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [ ] AC1 R11: exactamente 6 `PassSlot` marcados; fuera de ellos y de la estación no se suelta nada → test
- [ ] AC2 R14: camino más corto cara de condimentar ↔ cara de pase 6–10 m → test
- [ ] AC3 R16: Individual, 2 pedidos S con un pulpo y 2 cambios en total → test con el walker
- [ ] AC4 Captura del nivel completo a 1080p

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
