---
id: PUL-070
title: Subir la dificultad por fases
status: review
milestone: M3
role: gameplay-engineer
deps: [PUL-066, PUL-067]
orca_task: null
unity_sources: []
owns: [godot/core/round_state.gd, godot/core/order_board.gd, godot/autoload/round_manager.gd, godot/autoload/order_service.gd, godot/resources/round_config.gd, godot/resources/phase_data.gd, godot/resources/phase_data.gd.uid, godot/data/config/round_config.tres, godot/scenes/levels/level.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_round_manager.gd, godot/tests/unit/test_phases.gd, godot/tests/unit/test_phases.gd.uid, godot/tests/integration/*flow*.gd, docs/evidence/PUL-070/**, godot/autoload/event_bus.gd, godot/tests/unit/test_event_bus.gd, godot/data/orders/*.tres, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_parity_smoke.gd, godot/tests/helpers/phaseless_config.gd, godot/tests/helpers/phaseless_config.gd.uid]
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
- [x] AC1–AC6 de la feature → `test_phases.gd`
- [x] AC7 Flujos M1/M2/M2b en verde
- [x] AC8 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `resources/phase_data.gd` (nuevo) y `RoundConfig.phases` / `rng_seed`. `round_config.tres`
  lleva 3 fases (0, ⅓, ⅔ · 2/3/4 puestos · ×1,0/×0,85/×0,7).
- `OrderBoard.set_active_slots(slot_ids)` y `set_new_order_patience_multiplier(factor)`: un
  puesto inactivo no recibe comandas nuevas (ni reposición) y el multiplicador solo afecta a las
  comandas nuevas. `reset()` vuelve a todos los puestos y ×1,0.
- `RoundState`: `signal phase_changed(phase)` y `get_phase()`. En `start`, tras `reset`, entra
  en la fase 1. En `advance`, tras el reloj, entra en cada fase alcanzada (una vez por fase y nunca
  con `time_left` = 0) y rellena los puestos que se abren. Copia `phases` al arrancar.
- `EventBus.phase_changed` y su reenvío en `RoundManager`. `OrderService.setup` usa
  `config.rng_seed` si no recibe RNG. `level.gd` sin cambios: los puestos se abren en el orden
  de `stands`.
- Tests: `test_phases.gd` (AC1–AC6, bordes, bus, `level_01` real) y `test_event_bus.gd` (catálogo).
  Las suites de paridad usan `tests/helpers/phaseless_config.gd` (owns ampliadas por el
  coordinador: `test_level_01.gd`, `test_parity_smoke.gd`, helper).

## Evidence
`docs/evidence/PUL-070/README.md` (resumen, tabla de balance), `test_phases.log`, `verify.log`.
- AC1: `test_ac1_*` (fase 1, puestos 1–2, ×1,0, orden `orders_reset → phase_changed(1) →
  order_generated`). AC2: `test_ac2_*` (tick 5999 → fase 1, tick 6000 = 100,0 s → fase 2, una
  señal, puesto 3 con comanda en el mismo tick, ×0,85). AC3: `test_ac3_*` (4 puestos a 200 s, nunca
  más de `max_active_orders`, también con tope 3). AC4: `test_ac4_*`. AC5: `test_ac5_*` (misma
  semilla → misma secuencia en una ronda entera con entregas y caducidades). AC6: `test_ac6_*`
  (150 s → 50/100 s; 600 s → tick 12000).
- AC7: `test_m1_flow`, `test_m2_flow` y `test_m2b_flow` en verde (sin fases, con el helper).
- AC8: `tools/verify.sh` verde (672/672) y `check_owns` limpio.
- Balance: la fase 3 es jugable salvo order_2 (56 s frente a ~54 s de ruta de bot). Se anota
  para M4 sin tocar datos.
- Nota de contrato: `docs/arch/signals.md` (tabla de tipos, `PhaseData`) aún dice `max_time: float`.
  El ADR-006 aprobado dice `patience_multiplier`, que es lo implementado. Está fuera de owns y
  tiene que corregirlo el coordinador o el arquitecto.
