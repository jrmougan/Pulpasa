---
id: PUL-061
title: Montar level_01 con la planta B y la estación, y retirar los botes
status: draft
milestone: M2
role: gameplay-engineer
deps: [PUL-039, PUL-058, PUL-059, PUL-060]
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/**, godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/spice_shelf.tscn, godot/entities/items/seasoning.tscn, godot/entities/items/seasoning_item.gd, godot/entities/items/seasoning_item.gd.uid, godot/entities/items/box.gd, godot/entities/items/sandbox/**, godot/entities/stations/sandbox/stations_sandbox.*, godot/entities/player/sandbox/**, godot/tests/integration/*.gd, godot/tests/integration/*.gd.uid, docs/evidence/PUL-061/**]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 6, y planta **B · barra partida** de `docs/design/level-layouts.md` (D19, elegida por
el responsable el 2026-10-05).

## Change
1. `kitchen_layout.tscn` y `level_01.tscn` según la planta B: barra con pasaplatos que separa
   cocina (nevera, cachelera, 2 ollas) y servicio (estantería de cajas, puestos 1–4); estación de
   condimentos en la barra; salidas de J1/J2. Placeholders de primitivas (el arte llega en M3).
2. Retirar `SpiceShelf`, `seasoning.tscn`, `SeasoningItem` y las rutas de bote/cachelos de `box.gd`.
3. Reescribir los tests de integración afectados (flujos M1/M2, kitchen_flow, parity_smoke,
   level_01, cachelos, seasoning, shelves, slot, items_contract, delivery_e2e) al nuevo flujo.

## Constraints
- Contratos de PUL-056. No cambiar firmas de `EventBus`. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Feature AC16–AC18 → tests de integración en el nivel real
- [ ] AC2 Distancias de la planta B (±1 m) frente a `docs/evidence/PUL-041/distancias.md`
- [ ] AC3 Captura del nivel en Individual y Local 2P en `docs/evidence/PUL-061/`
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
