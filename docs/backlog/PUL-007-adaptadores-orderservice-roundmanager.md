---
id: PUL-007
title: Crear los autoloads OrderService y RoundManager como adaptadores
status: review
milestone: M0
role: gameplay-engineer
deps: [PUL-006]
orca_task: null
unity_sources: [Assets/Scripts/Systems/OrderSystem.cs, Assets/Scripts/Game/ProductivitySystem.cs]
owns: [godot/autoload/order_service.gd, godot/autoload/order_service.gd.uid, godot/autoload/round_manager.gd, godot/autoload/round_manager.gd.uid, godot/project.godot, godot/tests/unit/test_order_service.gd, godot/tests/unit/test_order_service.gd.uid, godot/tests/unit/test_round_manager.gd, godot/tests/unit/test_round_manager.gd.uid]
touches_scenes: []
---

## Target
Fase 2 de M0, adaptadores de ADR-002 (§Lista de autoloads, reglas 1–3, 6–8).

## Change
1. `autoload/order_service.gd`: crea `OrderBoard` en `setup(catalog)`, expone `try_deliver`,
   `request_order`, `get_active_orders`, `board`; reenvía cada señal del núcleo a `EventBus`. Sin `_process`.
2. `autoload/round_manager.gd`: `start_round(config, slot_ids)` en el orden de la regla 6;
   `_physics_process(delta)` → `RoundState.advance(delta)` con prioridad de física mínima; reenvía señales.
3. Registra ambos en `project.godot` tras `EventBus` y `GameState`.
4. `set_bus(bus)` para inyectar un `EventBus` de test.

## Constraints
Sin reglas de juego en los adaptadores. Sin acceso a escena. Sin tipos 3D.

## Acceptance
- [ ] AC1 Cada señal del núcleo llega al bus inyectado exactamente una vez, con los mismos argumentos → `test_order_service.gd`, `test_round_manager.gd`.
- [ ] AC2 `start_round` emite `orders_reset`, luego `order_generated` por puesto y luego `round_started`, en ese orden (B10).
- [ ] AC3 Con el árbol en pausa, `RoundManager` no avanza ni la ronda ni la paciencia.
- [ ] AC4 `tools/verify.sh` en verde y el smoke run arranca con los 4 autoloads.

## Plan
- `autoload/order_service.gd`: `setup(catalog, rng=null)`, `try_deliver`, `request_order`, `get_active_orders`, `board`, `set_bus`; reenvía las 6 señales de `OrderBoard`. Sin `_process`.
- `autoload/round_manager.gd`: `start_round` → `RoundState.start`, `_physics_process` → `advance`, prioridad de física mínima, reenvía las 4 señales de `RoundState`; `set_bus`, `set_order_service` (inyección en tests).
- `project.godot`: `OrderService` y `RoundManager` tras `EventBus` y `GameState`.
- AC1 → `test_order_service.gd` (`test_ac1_*`) y `test_round_manager.gd` (`test_ac1_*`); AC2 → `test_ac2_start_round_order_reset_generated_per_slot_then_started`; AC3 → `test_ac3_paused_tree_*`; AC4 → `tools/verify.sh`.

## Evidence
`tools/verify.sh` → `✓ verify OK` (gdformat, gdlint, import, GUT, smoke con los 4 autoloads sin errores).

```
Scripts              13
Tests               105
Passing Tests       105
Asserts             520
---- All tests passed! ----
```
