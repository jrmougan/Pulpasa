# PUL-206 AC1: cada cita de las frases nuevas contra el código (base `81a450c`)

Comprobado abriendo cada ruta en la rama `pul-206`. La ficha citaba `godot/core/action_rules.gd:101`
para el `BLOCKED`; en `81a450c` la línea 101 es el `case` (`Held.BOX_EMPTY, Held.BOX_PARTIAL:`) y el
`return` está en la 102: se citan las dos.

## ADR-003 §9.1, fila «Caja a medio cortar», columna del cuenco

| Cita | Código en esa línea | Coincide |
|---|---|---|
| `godot/core/action_rules.gd:101` | `Held.BOX_EMPTY, Held.BOX_PARTIAL:` (en `for_bowl`) | Sí: vacía o a medias |
| `godot/core/action_rules.gd:102` | `return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.BOX_NOT_FULL)` | Sí: `BLOCKED` `cachelos` `box_not_full` |
| `godot/entities/stations/cachelos_bowl.gd:83` | `ActionHint.State.BLOCKED:` (en `interact`) | Sí |
| `godot/entities/stations/cachelos_bowl.gd:84` | `rejected.emit(_rejection_of(hint.reason))`; `_rejection_of` da `BOX_NOT_FULL` por defecto (`cachelos_bowl.gd:129`); la rama no toca caja ni `stock` | Sí |
| `godot/entities/stations/cachelos_bowl.gd:58` | `return station.side_of(floor_position) == StationSide.Side.OPERATOR` (con una `Box` en la mano y `operator_side_only`) | Sí: desde el pase, `false` |

## ADR-003 §9.1, nota de la asimetría (tachada y sustituida)

| Cita | Código en esa línea | Coincide |
|---|---|---|
| `godot/core/action_rules.gd:81` | `return ActionHint.blocked(verb, ActionReason.BOX_NOT_FULL)` (en `for_dispenser`) | Sí |
| `godot/core/action_rules.gd:102` | `return ActionHint.blocked(ActionVerb.CACHELOS, ActionReason.BOX_NOT_FULL)` (en `for_bowl`) | Sí |
| `godot/entities/stations/seasoning_dispenser.gd:50` | `func get_action_hint(actor: InteractionComponent) -> ActionHint:` | Sí |
| `godot/entities/stations/seasoning_dispenser.gd:87` | `return ActionRules.for_dispenser(HeldKind.of(item), seasoning.verb, has_it, has_other)` | Sí |
| `godot/entities/stations/cachelos_bowl.gd:61` | `func get_action_hint(actor: InteractionComponent) -> ActionHint:` | Sí |
| `godot/entities/stations/cachelos_bowl.gd:94` | `return ActionRules.for_bowl(` | Sí |
| `godot/entities/stations/cachelos_bowl.gd:51` | `func is_reachable_from(floor_position: Vector2, holder: Holder) -> bool:` (solo mira si la mano lleva una `Box` y el lado) | Sí |
| `godot/entities/stations/seasoning_dispenser.gd:42` | `func is_reachable_from(floor_position: Vector2, _holder: Holder) -> bool:` (ignora la mano) | Sí |

Diseño: `docs/design/features/lenguaje-acciones.md:218`-`:220` (E1-E3, columna M5/M6: `B:caja a medias`)
y `:221`-`:223` (E4-E6, lado de pase: `—`). El código cumple el diseño; solo el texto del contrato estaba
desfasado (ya lo decía §11.7, `docs/arch/ADR-003-arbol-escenas-composicion.md:889`-`:890`).

## `signals.md` §3, «Entrega errónea»

| Cita | Código en esa línea | Coincide |
|---|---|---|
| `godot/core/order_board.gd:159` | `if not OrderValidator.matches(order.data, contents):` (en `try_deliver`) | Sí |
| `godot/core/order_board.gd:160` | `delivery_rejected.emit(slot_id, order.id, _reject_penalty)` y después `return null` | Sí |
| `godot/core/round_state.gd:185` | `func _on_delivery_rejected(...)`: con `penalty > 0` resta y emite `score_changed` (`:186`-`:188`); `RoundManager` lo reenvía (`godot/autoload/round_manager.gd:98`-`:99`) | Sí |
| `godot/entities/stations/order_stand.gd:147` | `if box == null or not _zone_accepts(box):` → `return` (en `_try_deliver`, antes de llamar al servicio en `:154`) | Sí |
| `godot/entities/stations/order_stand.gd:163` | `return OrderValidator.matches(_order.data, box.get_contents())` (en `_zone_accepts`) | Sí: solo cajas que coinciden |

## `signals.md` §3, «Entrega en el tick de caducidad»

| Cita | Código en esa línea | Coincide |
|---|---|---|
| `docs/arch/ADR-002-eventbus-autoloads.md:127` | «Los `OrderData` tienen `max_time > 0` (40-90s) y se emite `order_patience_changed` en cada tick.» | Sí (precondición, igual que §2). Datos: `godot/data/orders/*.tres`, `max_time` 60 y 80 |
| `godot/core/order_board.gd:149` | `if _expired_this_tick.has(slot_id):` (en `try_deliver`) | Sí |
| `godot/core/order_board.gd:150` | `delivery_rejected.emit(slot_id, _expired_this_tick[slot_id], 0)` y `return null` | Sí: `order_id` de A, `penalty` 0 |
| `godot/core/order_board.gd:122` | `_expired_this_tick.clear()` (en `advance`) | Sí: B entregable desde el `advance` siguiente |
| `godot/entities/stations/order_stand.gd:161` | `if _order == null or _blocked_by_expiry():` → `return false` | Sí |
| `godot/entities/stations/order_stand.gd:170` | `return _order.max_time > 0.0 or Engine.get_physics_frames() <= _expired_frame + 1` | Sí: con `max_time > 0` espera a `order_patience_changed` (`:65`, `:221`-`:222`); con `max_time` 0 solo un tick, que es el hueco que ya anota §2 |
