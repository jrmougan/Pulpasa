---
id: PUL-115
title: Escalar mecánicas por fase (comandas por fase)
status: done
milestone: M3d
role: gameplay-engineer
deps: [PUL-114]
orca_task: null
unity_sources: []
owns: [godot/resources/phase_data.gd, godot/resources/round_config.gd, godot/core/round_state.gd, godot/core/order_board.gd, godot/data/config/round_config.tres, godot/data/levels/**, godot/tests/unit/test_phases.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_data_integrity.gd, godot/tests/integration/test_station_level.gd, docs/evidence/PUL-115/**, docs/backlog/PUL-115-fases-de-comandas.md]
touches_scenes: []
---

## Target
Contrato de ADR-003 §10.5 (PUL-111): `PhaseData.orders: Array[OrderData]` (vacía = todo el catálogo), `OrderBoard.set_order_pool(orders)` aplicado en `RoundState._enter_phase`, misma secuencia con la misma semilla, pool ⊆ catálogo. Feature `dificultad-progresiva.md` (AC7–AC9).

## Change
`level_01`: fase 1 solo «Á feira»; fase 2 + «Picante»; fase 3 las 4. Tests en `test_phases.gd` y `test_round_state.gd`.

## Constraints
- El tutorial (`tutorial-breve.md`) no está implementado: queda fuera; solo datos de fase.
- `tools/verify.sh` en verde.

## Acceptance
- [x] AC1 `dificultad-progresiva.md` AC7–AC9 → tests
- [x] AC2 Invariante pool ⊆ catálogo → test de integridad
- [x] AC3 `tools/verify.sh` en verde

## Plan
- `resources/phase_data.gd`: `orders: Array[OrderData]` (vacía = catálogo).
- `core/order_board.gd`: `set_order_pool(orders)`; `request_order` elige del pool con una sola llamada al RNG; `reset()` lo vacía.
- `core/round_state.gd`: `_enter_phase` aplica `phase.orders` al tablero.
- `data/config/round_config.tres`: fase 1 [Á feira], fase 2 [+Picante], fase 3 las 4.
- Tests: AC1 -> `test_phases.gd` (AC7 200 generaciones por fase, AC8 cambio de fase en `RoundState`, misma semilla/RNG); `test_order_board.gd` (pool y reset); AC2 -> `test_data_integrity.gd` (pool ⊆ catálogo, acumulativo).
- Los helpers de AC4 de `test_phases.gd` pasan a fases sin pool porque usan un catálogo de una sola comanda.

## Evidence
- `tools/verify.sh`: OK (gdformat, gdlint, import, GUT 828/828, smoke). Sin AC visual.
- Mapeo: AC9 (dificultad-progresiva.md) -> `test_data_integrity.gd::test_pul115_phase_pools_subset_of_catalog_and_per_phase`; AC7/AC8 y AC13 de comandas.md -> `test_phases.gd::test_ac7_*` y `test_ac8_*`; AC2 (pool ⊆ catálogo) -> el mismo test de integridad, más `push_warning` en `OrderBoard.set_order_pool`.
- `test_station_level.gd` usa `PhaselessConfig` (catálogo de una comanda, sin pool de fase).
