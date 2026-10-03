---
id: PUL-006
title: Implementar los núcleos OrderBoard y RoundState con sus tests
status: done
milestone: M0
role: gameplay-engineer
deps: [PUL-004, PUL-005]
orca_task: task_f223bf04a9b9
unity_sources: [Assets/Scripts/Systems/OrderSystem.cs, Assets/Scripts/Game/ProductivitySystem.cs, Assets/Scripts/Game/OrderStand.cs, Assets/Scripts/Game/OrderTicketUIController.cs, Assets/Scripts/Interfaces/ActiveOrder.cs]
owns: [godot/core/**, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_order_board.gd.uid, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_round_state.gd.uid, godot/tests/unit/test_order_validator.gd, godot/tests/unit/test_order_validator.gd.uid, godot/autoload/event_bus.gd, godot/resources/round_config.gd, godot/data/config/round_config.tres, godot/tests/unit/test_event_bus.gd, godot/tests/unit/test_data_*.gd]
touches_scenes: []
---

## Target
Fase 2 de M0, lógica pura: `core/` según ADR-002 (§Dos niveles, §Reloj y paciencia, §Reglas de uso)
y los tipos de `docs/arch/signals.md` §Tipos.

## Change
1. Tipos de valor: `ActiveOrder`, `BoxContents`, `RoundResult`.
2. `OrderValidator.matches(order_data, contents) -> bool`, pura. M0: especias ⊆ (paridad, B15).
3. `OrderBoard` (catálogo + RNG inyectados): `reset`, `fill_slots`, `request_order`, `advance(delta)`
   con paciencia y caducidad, `try_deliver` con la regla de empate por `order_id`, `stop`,
   `get_active_orders` (copias). Máximo 4 activas, reposición inmediata tras entrega.
4. `RoundState` (config + board inyectados): reloj único, `advance(delta)` en el orden de ADR-002,
   contador de entregas, `RoundResult` con el ratio y los textos de rendimiento del prototipo.
5. Sustituye en `autoload/event_bus.gd` los `RefCounted` provisionales de PUL-004 por los tipos reales
   (solo el tipo de los parámetros; no cambies nombres ni aridad).

## Constraints
- Sin nodos, `SceneTree`, `Time`, `Input` ni autoloads dentro de `core/`. Dependencias por constructor.
- No portes B1, B2, B10, B11, B16 (inventario §4). Una entrega = una `order_completed`.
- Los adaptadores (`OrderService`, `RoundManager`) son PUL-007: no los crees aquí.

## Acceptance
- [x] AC1 Una entrega válida emite exactamente 1 `order_completed` sobre la comanda entregada y repone el puesto en la misma llamada; 20 entregas seguidas → contador 20 y ningún puesto vacío (B1, Must 2) → `test_order_board.gd`.
- [x] AC2 `OrderValidator` cubre: caja correcta, caja errónea, ingrediente sin cocinar, especia de menos, especia de más (aceptada en M0) → `test_order_validator.gd`.
- [x] AC3 `test_ac5b_delivery_on_expiry_tick_rejected_not_redirected` tal como lo especifica ADR-002.
- [x] AC4 Con `max_time` 0 (paridad) no hay caducidad ni `order_patience_changed`.
- [x] AC5 `RoundState`: la ronda acaba exactamente en `duration` (no a 179,5 s, B2); tras `round_finished`, `try_deliver` devuelve `null` sin señales; umbrales de rendimiento (<1, <2, <3 cajas/min) iguales al prototipo → `test_round_state.gd`.
- [x] AC6 Dos instancias de `OrderBoard` con el mismo RNG sembrado producen la misma secuencia y no comparten estado.
- [x] AC7 `tools/verify.sh` en verde.

## Plan
- Ficheros (`godot/core/`): `active_order.gd` (`ActiveOrder`, con `copy()`), `box_contents.gd`
  (`BoxContents`; añade `ingredient_state: IngredientData.CookingState` para el caso «sin cocinar»,
  que en el prototipo lo garantizaba el jugador al cortar), `round_result.gd` (`RoundResult`, ratio y
  `get_performance_description()` con los umbrales <1, <2, <3 del prototipo), `order_validator.gd`
  (`static matches`), `order_board.gd` (`OrderBoard`), `round_state.gd` (`RoundState`).
- Señales del núcleo con la misma firma que `signals.md` §2: `OrderBoard` emite `orders_reset`,
  `order_generated`, `order_completed`, `delivery_rejected`, `order_patience_changed`, `order_expired`;
  `RoundState` emite `round_started`, `round_time_changed`, `round_finished`, `score_changed` y escucha
  directamente al `OrderBoard` inyectado. `RoundState.start(slot_ids)` hace reset → fill_slots →
  `round_time_changed` → `round_started` (ADR-002 regla 6).
- Validación M0 (paridad): misma caja, mismo ingrediente y cocido, especias de la comanda ⊆ especias
  de la caja (B15). Sin comprobación de `fill` (el prototipo no la hace en `ValidateBox`).
- Caducidad con tolerancia `1e-6` para que 3600 × 1/60 caduque en el tick 3600 (error de coma flotante).
- `autoload/event_bus.gd`: `RefCounted` → `ActiveOrder` / `RoundResult` (mismos nombres y aridad).
- Tests: AC1, AC3, AC4, AC6 → `test_order_board.gd`; AC2 → `test_order_validator.gd`;
  AC5 → `test_round_state.gd`; AC7 → `tools/verify.sh`.

## Evidence
Revisión de codex (CHANGES) aplicada; owns ampliado por el producer (`round_config.gd/.tres`,
`test_event_bus.gd`, `test_data_*.gd`). `tools/verify.sh` → `✓ verify OK`. Resumen GUT:
```
Scripts              10
Tests                81
Passing Tests        81
Asserts             425
---- All tests passed! ----
```
- AC1: `test_order_board.gd` `test_ac1_order_completed_once_per_delivery`,
  `test_ac1_twenty_deliveries_count_twenty_and_no_empty_slot` (+ rechazo sin cambio de estado, máx. 4, copias, tablero parado);
  traza `test_ac5_trace_delivery_completed_score_generated` (completed → score → generated).
- AC2: `test_order_validator.gd` (`test_ac2_*`: caja correcta/errónea, sin ingrediente, sin cocinar, especia de menos, especia de más aceptada).
- AC3: `test_ac5b_delivery_on_expiry_tick_rejected_not_redirected`, ahora avanzando con `RoundState.advance` (3600 × 1/60, control en el tick siguiente);
  límites: `test_ac3_patience_not_expired_one_tick_before_limit` (3599/3600 ticks), `test_ac3_patience_not_expired_just_below_limit`
  (`advance(59,9999995)` no caduca y entrega), `test_ac3_patience_expires_just_after_limit`.
- AC4: `test_ac4_zero_max_time_never_expires_nor_emits_patience`.
- AC5: `test_round_state.gd`: no acaba a 179,5 s, acaba en el tick 10800, `advance(179,9999995)` no acaba, `advance(180,0000005)` acaba en 180;
  `try_deliver` nulo y mudo tras el fin; umbrales y textos desde `RoundConfig` (`data/config/round_config.tres`, valores de Unity,
  comprobados en `test_data_catalog.gd::test_pul006_ac5_round_config_performance_tiers`). Trazas con paciencia positiva:
  `test_ac5_trace_final_tick_with_patience` y `..._with_delta_beyond_time_left` (paciencia de todas → expired/score/generated por slot
  ascendente → `time:0` → finished), `test_ac5_trace_start_sequence` (reset → generated × 4 → time(180) → started).
  Comprobación de mutación: parar el tablero antes de su `advance` en el tick final hace fallar las dos trazas.
- AC6: `test_ac6_same_seed_same_sequence`, `test_ac6_boards_do_not_share_state`.
- `test_event_bus.gd` exige `ActiveOrder`/`RoundResult` (sin el marcador `RefCounted`).
- Tolerancia: `d = min(delta, time_left)`; se absorbe un residuo ≤ 1e-9 s (el error acumulado de 60 Hz es ~1e-12).
  Un límite puede adelantarse como máximo 1e-9 s (p. ej. `advance(179.9999999995)` termina la ronda). Aceptado por
  el producer y documentado en ADR-002 §Reloj (revisión de codex, P3 baja).
- Notas: `BoxContents.ingredient_state` cubre «sin cocinar» sin cambiar el bus. `first_order_delay` no se usa (M1).
