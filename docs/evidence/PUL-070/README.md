# PUL-070 — Dificultad por fases

## Qué hay
- `PhaseData` (`resources/phase_data.gd`): `start_fraction`, `active_slots`, `patience_multiplier`.
- `RoundConfig.phases` (vacía = sin fases, como antes) y `RoundConfig.rng_seed` (0 = aleatoria).
- `data/config/round_config.tres`: fases a 0, ⅓ y ⅔ con 2/3/4 puestos y ×1,0/×0,85/×0,7.
- `OrderBoard.set_active_slots` / `set_new_order_patience_multiplier` (`reset()` vuelve a todos
  los puestos y ×1,0). `RoundState.phase_changed`, `get_phase()`; copia las fases al arrancar.
- `EventBus.phase_changed(phase: int)` reenviada por `RoundManager`. `OrderService.setup` siembra
  el RNG con `config.rng_seed` si no se inyecta uno.

## Tests
- `godot/tests/unit/test_phases.gd`: 28 tests (lista en `test_phases.log`), AC1–AC6, bordes y
  `level_01` con las fases reales (2 → 3 → 4 puestos).
- Suites de paridad (`test_level_01`, `test_parity_smoke`, flujos M1/M2/M2b) quitan las fases del
  `round_config.tres` durante cada test con `tests/helpers/phaseless_config.gd` (decisión del
  coordinador, opción A): siguen comprobando el comportamiento sin fases.
- `tools/verify.sh`: verde, 672/672 (`verify.log`).

## Balance de la fase 3 (×0,7 sobre la paciencia de PUL-039, ya ×2)

| Comanda | `max_time` | Fase 2 (×0,85) | Fase 3 (×0,7) | Preparación (bot, PUL-039) |
|---|---|---|---|---|
| order_2 (individual, pimentón + sal) | 80 s | 68 s | **56 s** | ~54 s |
| order_6 (individual, aceite + cachelos) | 100 s | 85 s | 70 s | ~33 s |
| order_1 (familiar, picante + sal) | 120 s | 102 s | 84 s | ~50 s |
| order_5 / 4 / 3 | 140 / 150 / 180 s | 119 / 128 / 153 s | 98 / 105 / 126 s | — |

Jugable en general. La fase 3 tiene 4 puestos y las comandas vivas al cambiar de fase conservan su
paciencia. **Excepción: order_2 en fase 3** (56 s frente a ~54 s de ruta óptima de bot) es
prácticamente imposible para un humano y caducará casi siempre. PUL-039 ya veía justos sus 80 s.
No se han tocado los datos, porque es una decisión de balance. Propuesta para M4: subir order_2 a
≥ 100 s (fase 3 → 70 s) o poner un suelo de paciencia por comanda.
