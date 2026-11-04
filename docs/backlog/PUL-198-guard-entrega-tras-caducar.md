---
id: PUL-198
title: Evitar delivery_rejected en el tick posterior a la caducidad de una comanda
status: review
milestone: M4
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/tests/integration/test_order_stand.gd]
touches_scenes: []
---

## Target
`godot/entities/stations/order_stand.gd` y su test de integración.

## Change
Decisión del responsable en el gate de enmiendas (G22, G51). Una caja que entra en el tick posterior a la caducidad y coincide con la repuesta hace que el puesto llame a `try_deliver`, y el núcleo emite `delivery_rejected` con `penalty` 0. `signals.md` dice «sin emisión en el juego». Se extiende la protección del guard (`order_stand.gd:156`) hasta el siguiente `advance`. Reproducción: `docs/evidence/PUL-196/repro-entrega.txt`.

## Constraints
No toca el núcleo: `try_deliver`, D24, ADR-002 y los tests de `OrderBoard` quedan igual. Un simple «tick + 1» puede chocar con `test_order_stand.gd:272`: compruébalo.

## Acceptance
- [x] AC1 Given una comanda que caduca, When una caja real entra por física en el tick siguiente antes de su `advance`, Then no se emite `delivery_rejected` → test en test_order_stand.gd
- [x] AC2 Given el tick siguiente tras ese `advance`, When entra la caja que coincide con la repuesta, Then se entrega → test en test_order_stand.gd
- [x] AC3 Given la suite, When `tools/verify.sh`, Then verde → salida en docs/evidence/PUL-198/

## Plan
- Causa: `_expired_frame` solo cubre el tick de la caducidad. El `body_entered` del tick siguiente llega en el flush de física, antes del `advance` de `RoundManager`, y el núcleo (`_expired_this_tick`, vivo hasta el siguiente `advance`) rechaza.
- Arreglo en `order_stand.gd`, sin tocar el núcleo: `_expired_frame` pasa a `_awaiting_advance`. Se activa en `order_expired` de su puesto y se apaga con la primera `order_patience_changed` (cada `advance` emite una por comanda con paciencia, antes de las caducidades, así que la del `advance` que caduca ya pasó). Si no hay señal posible (repuesta con `max_time <= 0`) cae al plazo anterior ampliado: tick de caducidad + 1. Un «tick + 1» a secas no sirve: `test_pul039_zone_delivers_replacement_in_a_later_tick` espera un tick y llama a `advance` a mano; con la señal sigue verde.
- Se limpia también en `orders_reset`.
- Tests en `test_order_stand.gd`, con entrada física real (`_enter_zone`): AC1 (caduca, entra antes del `advance`: ni `delivery_rejected` ni entrega; tras el `advance` entrega al que ya está dentro) y AC2 (tras un tick y su `advance`, entra la caja de la repuesta y se entrega).
- AC3: `tools/verify.sh` completo en `docs/evidence/PUL-198/`; se comprueba que el test de AC1 falla sin el arreglo.

## Evidence
Todo en `docs/evidence/PUL-198/`.
- Reproducción previa (`PUL-196/repro_lanzador.gd`, `REPRO_LEAD=1`, entrada física en el tick posterior a la caducidad): `repro-sin-arreglo-lead1.txt` → `delivery_rejected emitidas = 1`. Con el arreglo (`repro-con-arreglo-lead1.txt`): 0; la caja se entrega en el mismo tick, tras el `advance`, por el sondeo de `_physics_process`.
- AC1 y AC2: `test_pul198_entry_after_expiry_tick_before_advance_does_not_reject` y `test_pul198_entry_after_the_advance_delivers_replacement`. `test-sin-arreglo.txt`: AC1 falla sin el arreglo (37/38); `test-con-arreglo.txt`: 38/38.
- Cambio en un test existente: `test_pul100_ac1_zone_turns_off_on_expired_and_reset` fabrica la caducidad en el bus sin `advance`; ahora emite también `order_patience_changed` (lo que haría el `advance` real) antes de regenerar la comanda.
- Sin tocar el núcleo ni `docs/arch`. La frase de `order_stand.gd:11` («el juego ya no lo emite») queda cierta. `test_pul039_zone_delivers_replacement_in_a_later_tick` (el «tick + 1» a secas lo rompería) sigue verde.
- AC3: `verify-completo.txt`: 1380/1380 tests, smoke OK, `verify OK`, rc=0.
- No verificable: repro con `REPRO_LEAD=0` y `2` tras el arreglo (no lanzadas; no cambian el camino); comportamiento con repuesta sin paciencia (`max_time <= 0`), caso sin test.
