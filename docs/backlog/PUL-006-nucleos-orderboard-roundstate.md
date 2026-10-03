---
id: PUL-006
title: Implementar los núcleos OrderBoard y RoundState con sus tests
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-004, PUL-005]
orca_task: null
unity_sources: [Assets/Scripts/Systems/OrderSystem.cs, Assets/Scripts/Game/ProductivitySystem.cs, Assets/Scripts/Game/OrderStand.cs, Assets/Scripts/Game/OrderTicketUIController.cs, Assets/Scripts/Interfaces/ActiveOrder.cs]
owns: [godot/core/**, godot/tests/unit/test_order_board.gd, godot/tests/unit/test_order_board.gd.uid, godot/tests/unit/test_round_state.gd, godot/tests/unit/test_round_state.gd.uid, godot/tests/unit/test_order_validator.gd, godot/tests/unit/test_order_validator.gd.uid, godot/autoload/event_bus.gd]
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
- [ ] AC1 Una entrega válida emite exactamente 1 `order_completed` sobre la comanda entregada y repone el puesto en la misma llamada; 20 entregas seguidas → contador 20 y ningún puesto vacío (B1, Must 2) → `test_order_board.gd`.
- [ ] AC2 `OrderValidator` cubre: caja correcta, caja errónea, ingrediente sin cocinar, especia de menos, especia de más (aceptada en M0) → `test_order_validator.gd`.
- [ ] AC3 `test_ac5b_delivery_on_expiry_tick_rejected_not_redirected` tal como lo especifica ADR-002.
- [ ] AC4 Con `max_time` 0 (paridad) no hay caducidad ni `order_patience_changed`.
- [ ] AC5 `RoundState`: la ronda acaba exactamente en `duration` (no a 179,5 s, B2); tras `round_finished`, `try_deliver` devuelve `null` sin señales; umbrales de rendimiento (<1, <2, <3 cajas/min) iguales al prototipo → `test_round_state.gd`.
- [ ] AC6 Dos instancias de `OrderBoard` con el mismo RNG sembrado producen la misma secuencia y no comparten estado.
- [ ] AC7 `tools/verify.sh` en verde.

## Plan

## Evidence
