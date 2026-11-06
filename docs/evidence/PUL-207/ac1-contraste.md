# AC1: contraste del AC5d nuevo con el código y los tests

Código: `godot/entities/stations/order_stand.gd`. Tests: `godot/tests/integration/test_order_stand.gd`
(T1 = `test_pul198_entry_after_expiry_tick_before_advance_does_not_reject`, l. 280-292;
T2 = `test_pul198_entry_after_the_advance_delivers_replacement`, l. 297-306).

| Afirmación de AC5d | Código | Test | Coincide |
|---|---|---|---|
| La comanda caduca en T y se repone en el mismo puesto | `_on_order_expired` (l. 213) fija `_expired_frame`, `_awaiting_advance = true`, `_set_order(null)`; `_on_order_generated` fija la repuesta | `_expiring_board` + `board.advance(max_time + 0.01)` (T1 l. 284, T2 l. 301) | si |
| Antes del `advance` de T+1 no hay `order_completed` | `_zone_accepts` (l. 160) -> `_blocked_by_expiry` (l. 167) true mientras `_awaiting_advance` y `max_time > 0`; `_try_deliver` (l. 145) sale sin llamar al servicio | T1 l. 287 `assert_signal_not_emitted(order_completed)` | si |
| Sin `delivery_rejected` | El juego no lo emite: la zona no pide `try_deliver` (misma guarda) | T1 l. 286 y l. 292 | si |
| La caja sigue en la mano | `holder.drop()` solo tras `try_deliver != null` | T1 l. 288 `assert_eq(_hold.get_held_item(), box)` | si |
| Sin penalización añadida (`wrong_delivery_penalty` = 0) | Sin llamada al servicio no hay rechazo ni penalización | `_expiring_board` fija `wrong_delivery_penalty = 0` y `expire_penalty = 3` (l. 225-226); sin `delivery_rejected` | si, por ausencia de rechazo |
| La recaudación solo baja por `expire_penalty` (3 €) | Única penalización: `order_expired(order, penalty)` (`order_board.gd` l. 138) | El test no mide la recaudación (el montaje no tiene `RoundState`); se deduce de la ausencia de `delivery_rejected` | parcial |
| Tras el `advance` de T+1, la caja que coincide con la repuesta se entrega, entrando o ya dentro | `_on_order_patience_changed` (l. 221) -> `_awaiting_advance = false`; `body_entered` y `_deliver_to_carriers_inside` (l. 106) | T1 l. 289-291 (ya dentro) y T2 l. 302-305 (entra después) | si |
| `order_completed` una vez, caja soltada y liberada | `holder.drop()` + `box.queue_free()` (`_try_deliver`) | T1 l. 291 `emit_count == 1`; T2 l. 305-306 `_is_released(box)` | si |
| Nota: el núcleo rechazaría con `delivery_rejected(slot, id_caducada, 0)` | AC5b en `OrderBoard` / `signals.md` §2 | `test_order_board.gd` l. 179 y l. 216 existen | si |

Notas:
- Límite conocido (`signals.md` §2): con `max_time` = 0 la guarda es tick + 1; AC5d presupone `max_time > 0`.
- Solo se contrastó por lectura del código y de los tests; GUT no se ejecutó en esta ficha (solo `verify.sh --quick`).
