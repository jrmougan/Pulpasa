---
id: PUL-070
title: Subir la dificultad por fases
status: ready
milestone: M3
role: gameplay-engineer
deps: [PUL-066, PUL-067]
orca_task: null
unity_sources: []
owns: [godot/core/round_state.gd, godot/core/order_board.gd, godot/autoload/round_manager.gd, godot/autoload/order_service.gd, godot/resources/round_config.gd, godot/resources/phase_data.gd, godot/resources/phase_data.gd.uid, godot/data/config/round_config.tres, godot/scenes/levels/level.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_round_manager.gd, godot/tests/unit/test_phases.gd, godot/tests/unit/test_phases.gd.uid, godot/tests/integration/*flow*.gd, docs/evidence/PUL-070/**, godot/autoload/event_bus.gd, godot/tests/unit/test_event_bus.gd, godot/data/orders/*.tres]
touches_scenes: []
---

## Target
`features/dificultad-progresiva.md` (AC1–AC6) con los contratos de PUL-066.

## Change
Fases en datos (fracción de `match_duration`, puestos activos, `max_time`), `phase_changed`,
activación de puestos por fase sin dejar puestos con comanda huérfana, comandas activas conservan su
`max_time`, semilla reproducible. Revisa con el balance de PUL-039 (paciencia ×2) que la fase 3 sea
jugable y anótalo.

## Constraints
- Lógica en núcleos `RefCounted` (ADR-002). Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1–AC6 de la feature → `test_phases.gd`
- [ ] AC7 Flujos M1/M2/M2b en verde
- [ ] AC8 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
