---
id: PUL-105
title: Dar superficie a los pasaplatos de los sandboxes
status: ready
milestone: M3c
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/scenes/sandbox/kitchen_sandbox.tscn, godot/scenes/sandbox/player_sandbox.tscn, godot/entities/items/sandbox/items_sandbox.tscn, docs/evidence/PUL-105/**, docs/backlog/PUL-105-pasaplatos-en-sandboxes.md]
touches_scenes: [godot/scenes/sandbox/kitchen_sandbox.tscn, godot/scenes/sandbox/player_sandbox.tscn, godot/entities/items/sandbox/items_sandbox.tscn]
---

## Target
Sandboxes que instancian `slot.tscn` (hallazgo de PUL-101).

## Change
Desde PUL-101 el `Model` de `slot.tscn` es la marca `pass_mark` (antes, la mesa `table_square`). En `kitchen_sandbox`, `player_sandbox` e `items_sandbox` los `Slot` quedan con la marca flotando a 1,1 m, sin mesa ni cuerpo que bloquee. Poner debajo un módulo de barra de `counters` (o una mesa) con su colisión.

## Constraints
- `tools/verify.sh` en verde. No tocar `slot.tscn` ni `level_01.tscn`.

## Acceptance
- [ ] AC1 Given cada sandbox, Then cada `Slot` está sobre una superficie con colisión → test o captura
- [ ] AC2 Capturas de los tres sandboxes en `docs/evidence/PUL-105/`

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
