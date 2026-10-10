---
id: PUL-115
title: Escalar mecánicas por fase (comandas por fase)
status: todo
milestone: M3d
role: gameplay-engineer
deps: [PUL-114]
orca_task: null
unity_sources: []
owns: [godot/resources/phase_data.gd, godot/resources/round_config.gd, godot/core/round_state.gd, godot/core/order_board.gd, godot/data/config/round_config.tres, godot/data/levels/**, godot/tests/unit/test_phases.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_data_integrity.gd, docs/evidence/PUL-115/**, docs/backlog/PUL-115-fases-de-comandas.md]
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
- [ ] AC1 `dificultad-progresiva.md` AC7–AC9 → tests
- [ ] AC2 Invariante pool ⊆ catálogo → test de integridad
- [ ] AC3 `tools/verify.sh` en verde

## Plan

## Evidence
