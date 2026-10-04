---
id: PUL-027
title: Activar paciencia, recaudación, penalizaciones y estrellas en los núcleos
status: done
milestone: M1
role: gameplay-engineer
agent: antigravity · gemini-3.1-pro-high (difícil)
deps: [PUL-028]
orca_task: task_1c6148bc198c
unity_sources: []
owns: [godot/core/order_board.gd, godot/core/round_state.gd, godot/core/round_result.gd, godot/core/active_order.gd, godot/resources/round_config.gd, godot/resources/order_data.gd, godot/resources/recipe_data.gd, godot/data/config/**, godot/data/orders/**, godot/data/recipes/**, godot/autoload/round_manager.gd, godot/autoload/order_service.gd, godot/scenes/levels/level.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_data_*.gd, godot/tests/unit/test_order_service.gd, godot/tests/unit/test_round_manager.gd, godot/tests/integration/test_parity_smoke.gd, docs/arch/signals.md, docs/arch/ADR-002-eventbus-autoloads.md, godot/tests/integration/test_kitchen_flow.gd, godot/tests/integration/test_hud.gd, godot/tests/unit/test_data_integrity.gd, godot/tests/integration/test_order_stand.gd, godot/tests/integration/test_level_01.gd, godot/tests/helpers/**]
touches_scenes: []
---

## Target
M1, features `comandas.md` (AC1–AC3, AC5, AC7, AC8), `entrega-y-puntuacion.md` (AC1–AC8, AC5b/c), `partida-5-min.md`
(AC6), decisiones D2, D5, D8. Los contratos (señales con `penalty`, `score_changed(boxes, revenue)`) ya existen.

## Change
1. Paciencia activa: `max_time` por plantilla (40–90 s), `first_order_delay` 5 s, `max_active_orders` 4 desde datos.
2. Recaudación en `RoundState`: base de la receta (8–14 €) + `floor(t_restante/max_time × time_bonus_max)`;
   caducidad resta `expire_penalty`; **caja errónea resta `wrong_delivery_penalty` (D8)**; nunca negativa.
3. `RoundResult`: recaudación y estrellas por umbrales en datos (feature: 30/60/90 € → 1/2/3; < 30 € = 0).
4. `round_config.tres`: duración 300 s (D5).
5. ≥ 4 plantillas de comanda que usen aceite y pimentones (los datos de condimentos los crea PUL-028; cachelos
   se añadirán en PUL-029).
6. Actualiza `test_parity_smoke.gd` para que no exija valores de M0 (180 s, `max_time` 0).

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).

## Acceptance
- [x] AC1 Todos los AC citados de `entrega-y-puntuacion` (salvo UI: AC9–AC12) y `comandas` (AC1–AC3, AC5, AC7, AC8) con test unitario cuyo nombre cite el AC.
- [x] AC2 Caja errónea: `delivery_rejected` con `penalty` > 0 y recaudación reducida sin bajar de 0 (D8).
- [x] AC3 `partida-5-min` AC6: cambiar la duración en datos cambia la ronda sin tocar código.
- [x] AC4 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan
Se añadieron los valores de M1 a las plantillas de `OrderCatalog`, `RoundConfig` y `RecipeData`.
Se implementaron los cálculos de puntuación de estrellas y penalizaciones en `RoundState` y `RoundResult`.
Se crearon mocks M0 para mantener verdes los tests de integración de M0 que asumen las mecánicas del prototipo sin modificar.

## Evidence
- `tools/verify.sh` en verde (389 tests, smoke OK) y `tools/check_owns.py jrmougan/pul-027 jrmougan/agentica-migracion-godot-alpha` limpio.
- Resolución de la revisión (H1–H8):

| Hallazgo | Cómo se resolvió | Test que lo prueba |
| --- | --- | --- |
| H1 `first_order_delay` no se leía | `RoundState.start` difiere `fill_slots` hasta `first_order_delay` dentro de `advance` (reloj único, sin timers); con delay 0 se genera en `start` antes de `round_started` (orden de signals.md) | `test_comandas_ac1_first_order_delay` (datos reales: 0 comandas a 4,9 s; comanda + `order_generated` a 5,0 s) |
| H2 penalizaciones como «flag» | `OrderBoard` recibe `reject_penalty`/`expire_penalty` por constructor desde `RoundConfig` (vía `OrderService.setup(catalog, rng, config)`), emite la cantidad real y `RoundState` resta `penalty` de la señal, con `score_changed` solo si `penalty` > 0. Constantes borradas; `level.gd` pasa `round_config` (sandboxes sin penalización, acordado con coordinación) | `test_entrega_d8_wrong_box_penalty`, `test_entrega_d8_wrong_box_penalty_min_zero`, `test_comandas_ac3_expire_replenish`, `test_m1_level_wires_expire_penalty_from_data` (level_01 real) |
| H3 doble campo de precio | Un solo `base_points` en recetas (8/12/14 €); `base_price` eliminado de `RecipeData` y de las fixtures M0; `order_completed` lleva `base_points` y `RoundState` suma `points` | `test_entrega_ac4_time_bonus` (score_changed(1, base+bonus) con datos reales) |
| H4 tests M1 sin flujo real | Sección M1 de `test_round_state.gd` reescrita: datos reales sin mutar, todo por `advance`/`try_deliver`, sin tocar privados (el ingreso previo se gana con una entrega real) | `test_entrega_ac5b_tie_break_penalty_0`, `test_entrega_ac5c_deliver_before_expire`, `test_comandas_ac3_expire_replenish`, `test_entrega_d8_wrong_box_penalty(_min_zero)`, `test_entrega_ac6_stars` |
| H5 integración sin datos reales | Fixtures M0 solo en tests de paridad (`test_round_state`/`test_round_manager` M0, kitchen_flow, HUD); integración M1 con datos reales | `test_m1_ac2_ac4_integration_with_real_data` (RoundManager+OrderService: entrega → `score_changed(1, base+bonus)`, caducidad → −3) y `test_m1_level_wires_expire_penalty_from_data` |
| H6 estrellas con índices fijos | `RoundResult` recorre `revenue_thresholds` ascendentes (stars = umbrales alcanzados), documentado con docstring | `test_entrega_ac6_stars` (29→0, 30/59→1, 60→2, 90→3 con los umbrales reales) |
| H7 datos a medias | `order_3` (combo_duo) lleva aceite; las 4 plantillas usan aceite/pimentón; test de datos de rangos | `test_comandas_ac5_m1_data_ranges` (max_time 40–90, base 8–14, aceite y pimentón presentes), `test_ac1_order_3_combo_duo_with_oil` |
| H8 docs desfasadas | Comentarios de `order_board`/`round_state`, cabecera de tests, `signals.md` (`score_changed`, `delivery_rejected`) y ADR-002 (paciencia/`first_order_delay`) actualizados; docstrings de las exports de `RoundConfig` | gdformat/gdlint en verde; revisión de texto en el diff |
| — limpieza | Eliminado `scratch_tests.gd` (script auxiliar); `OrderService.setup` reordenado a `(catalog, rng, config)` para no tocar llamantes ajenos; revertidos `kitchen_sandbox.tscn`, `hud_sandbox.gd`, `test_order_tickets.gd` | `check_owns` limpio |
