---
id: PUL-058
title: Crear la escena de la estación de condimentos
status: draft
milestone: M2
role: gameplay-engineer
deps: [PUL-057]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_station.gd.uid, godot/entities/stations/seasoning_dispenser.gd, godot/entities/stations/seasoning_dispenser.gd.uid, godot/entities/stations/cachelos_bowl.gd, godot/entities/stations/cachelos_bowl.gd.uid, godot/resources/seasoning_station_data.gd, godot/resources/seasoning_station_data.gd.uid, godot/data/config/seasoning_station.tres, godot/entities/stations/sandbox/seasoning_station_sandbox.*, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_seasoning_station.gd.uid, docs/evidence/PUL-058/**, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/slot.gd, godot/components/interaction_detector.gd, godot/components/interaction_contract.gd, godot/tests/integration/test_interaction_detector.gd, godot/tests/unit/test_interaction_contract.gd, godot/tests/integration/test_slot.gd]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/sandbox/seasoning_station_sandbox.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 3. Contratos de PUL-056.

## Change
`seasoning_station.tscn` con placeholder de primitivas (el modelo es PUL-052): bandeja (`Slot` de
caja), 4 dispensadores con lado, cuenco con raciones, antirrebote con reloj inyectable, sonido de
error, resaltado; `SeasoningStationData` + `.tres` (`toggle_guard`, `cachelos_stock_max`,
`cachelos_initial_stock`, `cachelos_portions_per_item`, `paprika_swap`, `operator_side_only`);
sandbox propio.

## Constraints
- No editar `level_01.tscn` (PUL-061). Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Feature AC1, AC3, AC6–AC11 → `test_seasoning_station.gd`
- [ ] AC2 Captura del sandbox en `docs/evidence/PUL-058/`
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
