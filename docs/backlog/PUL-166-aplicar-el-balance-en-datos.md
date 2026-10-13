---
id: PUL-166
title: Aplicar el balance aprobado en los datos
status: draft
milestone: M4
role: gameplay-engineer
deps: [PUL-165]
orca_task: null
unity_sources: []
owns: [godot/data/config/round_config.tres, godot/data/orders/*.tres, godot/data/boxes/*.tres, godot/tests/unit/test_data_balance.gd*, godot/tests/unit/test_phases.gd*, docs/evidence/PUL-166/**, docs/backlog/PUL-166-aplicar-el-balance-en-datos.md]
touches_scenes: []
---

## Target
Tabla «campo `.tres` → valor nuevo» de PUL-165 (`docs/evidence/PUL-165/README.md`).

## Change
Cambiar los valores en los `.tres` y fijarlos con un test de datos, sin tocar código de juego.

## Constraints
- Datos de balance solo en `.tres` (regla 3). Si un valor exige código nuevo, se para y se escala.
- Los tests existentes que fijen valores antiguos se actualizan, no se borran.

## Acceptance
- [ ] AC1 Given la tabla de PUL-165, When se carga `round_config.tres`, Then cada umbral, `start_fraction`, `active_slots` y `patience_multiplier` es igual al valor aprobado (±0,001) con 0 campos distintos → `test_data_balance.gd`.
- [ ] AC2 Given la tabla de PUL-165, When se cargan los 4 `.tres` de `data/orders/` (y la caja), Then precio y `presses_to_fill` son los aprobados en los 4 casos → `test_data_balance.gd`.
- [ ] AC3 Given toda receta en su fase más dura, When se calcula `max_time × patience_multiplier`, Then supera el tiempo del bot de PUL-164 en
  ≥ el margen aprobado → `test_data_balance.gd`.
- [ ] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-166/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
