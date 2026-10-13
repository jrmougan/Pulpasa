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
- [ ] AC1 Given `round_config.tres`, Then umbrales, fases y multiplicadores son los de PUL-165 → `test_data_balance.gd`.
- [ ] AC2 Given las 4 recetas, Then precios (y `presses_to_fill` si cambia) son los de PUL-165 → `test_data_balance.gd`.
- [ ] AC3 Given toda receta en su fase más dura, Then su paciencia supera el tiempo del bot de PUL-164 en
  ≥ el margen aprobado → `test_data_balance.gd`.
- [ ] AC4 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
