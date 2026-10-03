---
id: PUL-027
title: Activar paciencia, recaudación, penalizaciones y estrellas en los núcleos
status: ready
milestone: M1
role: gameplay-engineer
agent: antigravity · gemini-3.1-pro-high (difícil)
deps: [PUL-028]
orca_task: null
unity_sources: []
owns: [godot/core/order_board.gd, godot/core/round_state.gd, godot/core/round_result.gd, godot/core/active_order.gd, godot/resources/round_config.gd, godot/resources/order_data.gd, godot/resources/recipe_data.gd, godot/data/config/**, godot/data/orders/**, godot/data/recipes/**, godot/autoload/round_manager.gd, godot/autoload/order_service.gd, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_data_*.gd, godot/tests/unit/test_order_service.gd, godot/tests/unit/test_round_manager.gd, godot/tests/integration/test_parity_smoke.gd, docs/arch/signals.md, docs/arch/ADR-002-eventbus-autoloads.md]
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
- [ ] AC1 Todos los AC citados de `entrega-y-puntuacion` (salvo UI: AC9–AC12) y `comandas` (AC1–AC3, AC5, AC7, AC8) con test unitario cuyo nombre cite el AC.
- [ ] AC2 Caja errónea: `delivery_rejected` con `penalty` > 0 y recaudación reducida sin bajar de 0 (D8).
- [ ] AC3 `partida-5-min` AC6: cambiar la duración en datos cambia la ronda sin tocar código.
- [ ] AC4 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
