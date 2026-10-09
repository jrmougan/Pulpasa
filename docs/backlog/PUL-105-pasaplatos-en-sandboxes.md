---
id: PUL-105
title: Dar superficie a los pasaplatos de los sandboxes
status: review
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
- [x] AC1 Given cada sandbox, Then cada `Slot` está sobre una superficie con colisión → test o captura
- [x] AC2 Capturas de los tres sandboxes en `docs/evidence/PUL-105/`

## Plan
- Ficheros: las tres .tscn de sandbox. Bajo cada `Slot` se añade un `PassBar_<slot>` (StaticBody3D, caja 1x1,1x1 a y=0,55, como `Bar` de kitchen_layout) con el modelo `pass_1m.glb` (uid existente). Sin señales nuevas.
- AC1: `docs/evidence/PUL-105/check_and_shoot.gd` lanza un rayo vertical (capa 1) sobre cada Slot de cada sandbox y exige impacto a y > 0,9.
- AC2: el mismo script guarda las capturas de los tres sandboxes.

## Evidence
- AC1: `docs/evidence/PUL-105/check_and_shoot.gd` (rayo vertical capa 1 sobre cada Slot): kitchen_sandbox/FreeSlot, player_sandbox/SlotWithItem y EmptySlot, items_sandbox/TableWithBox impactan a y=1,1 (OK los cuatro).
- AC2: `docs/evidence/PUL-105/{kitchen,player,items}_sandbox.png` (1920x1080).
- Nota: en un worktree nuevo hace falta `godot --headless --import` antes del script.
