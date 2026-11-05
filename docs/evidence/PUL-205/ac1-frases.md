# PUL-205 AC1: frases de contrato contra el código

Base: `250a15c`. Las líneas citadas las comprueba `comprobar_citas.py` (salida en `comprobar-citas.txt`). Solo cambia el texto y sus marcas; no cambia código.

## G08

| Sitio | Frase antigua | Frase nueva | Código |
|---|---|---|---|
| ADR-003 §8.2 | `interact_pressed()` suelta lo que lleva la mano si el objetivo no consume la pulsación y `holder.can_drop_freely()` | Solo suelta cuando la pulsación va al suelo (no hay objetivo, su hint recalculado es `NONE` o es un objetivo heredado sin verbo que devuelve `false`) y `for_floor` da `OK`. Un objetivo con verbo que devuelve `false` da `push_error` y un rechazo, y no suelta | `godot/components/interaction_component.gd:79`, `godot/components/interaction_component.gd:88`, `godot/components/interaction_component.gd:93`, `godot/components/interaction_component.gd:99`, `godot/core/action_rules.gd:124` |
| ADR-003 §8.2 | Dispensador: `can_interact(actor)` es `true` solo con `actor.holder` y la mano vacía | `true` solo con una caja en la mano (la enmienda PUL-064, que pedía la mano vacía, quedó sustituida por §9.1 y §11.2); con la mano vacía o cualquier otra cosa `for_dispenser` da `NONE`, y el detector no lo resalta | `godot/entities/stations/seasoning_dispenser.gd:56`, `godot/core/action_rules.gd:88`, `godot/components/interaction_detector.gd:110` |
| ADR-003 §8.2 | Con algo en la mano no es objetivo: `is_reachable_from` devuelve `false` | `is_reachable_from` ignora la mano y solo filtra el lado | `godot/entities/stations/seasoning_dispenser.gd:42` |
| ADR-003 §8.2 | Cuenco: `can_interact(actor)` es `true` siempre que haya `actor.holder` | `true` con cachelos cocidos o con una caja en la mano; con la mano vacía o cualquier otra cosa `for_bowl` da `NONE` | `godot/entities/stations/cachelos_bowl.gd:67`, `godot/core/action_rules.gd:110` |
| ADR-003 §8.2 | `Slot`: si lo que lleva la mano no está en el grupo, `interact()` consume la pulsación sin guardar nada. La bandeja usa `accepted_group = &"box"` | El hint es `NONE`: el slot no es objetivo e `interact()` devuelve `false` sin guardar nada. Lo usaba la bandeja; sin usuario en el nivel desde D23 | `godot/entities/stations/slot.gd:118`, `godot/tests/integration/test_slot.gd:248`; ningún `.tscn` ni `.tres` usa `accepted_group` (búsqueda en `godot/`) |
| ADR-003 §8.2 | La caja guardada ya consume la pulsación de una mano llena: no se suelta la segunda caja (AC9) | Con un objeto guardado, el detector sustituye el slot por él. La caja guardada es objetivo con la mano vacía o con pulpo crudo o cocido; con otra caja o cualquier otra cosa `for_box` da `NONE`. Sin otro objetivo, lo que lleva la mano se suelta si hay sitio; si no, rechazo `busy` (A9) | `godot/components/interaction_detector.gd:104`, `godot/core/action_rules.gd:42`, `godot/components/interaction_component.gd:99`, `godot/core/action_rules.gd:126`; ejecutado en `sonda-segunda-caja.txt` |
| `scene-tree.md` §3, caja | Con cualquier otra cosa en la mano consume la pulsación sin efecto | Con pulpo crudo, o con pulpo cocido y la caja llena, rechaza sin efecto y devuelve `true`; con cualquier otra cosa el hint es `NONE`: no es objetivo e `interact()` devuelve `false` sin efecto | `godot/core/action_rules.gd:34`, `godot/core/action_rules.gd:38`, `godot/core/action_rules.gd:42`, `godot/entities/items/box.gd:121`, `godot/entities/items/box.gd:122` |
| `scene-tree.md` §3, `slot.tscn` | Lo que no esté en el grupo se rechaza consumiendo la pulsación | Con lo que no esté en el grupo, el slot vacío da hint `NONE`: no es objetivo e `interact()` devuelve `false` | `godot/entities/stations/slot.gd:118`, `godot/tests/integration/test_slot.gd:248` |

Se conserva sin cambios porque el código coincide: `interact()` de dispensador y cuenco devuelve `true` al rechazar y emite `rejected` (`godot/entities/stations/seasoning_dispenser.gd:73`, `godot/entities/stations/cachelos_bowl.gd:83`).

**Cambio que el responsable debe mirar**: la frase antigua decía «no se suelta la segunda caja (AC9)». En `level_01` real, de cara al slot a 0,6-1,2 m, el `drop` queda bloqueado por `busy` y la caja sigue en la mano, porque el punto de soltar choca con la barra; a 1,5 m o de espaldas, cae al suelo (`sonda-segunda-caja.txt`). No es una regla nueva: es lo que hace el código, y ese AC9 lo retiró D23 (`docs/design/features/estacion-condimentos.md:165`).

## G13 y G57

| Sitio | Frase antigua | Frase nueva | Código |
|---|---|---|---|
| ADR-003 §10.3 | Regla de colocación (contrato, la exige `test_level_01.gd`) | La exige `test_t6_trash_bins_are_far_from_every_target_and_the_gap`, que mide la distancia de cada cubo a los objetivos del grupo `interactable`, a cada `OrderStand` y al hueco; `test_level_01.gd` solo fija las posiciones | `godot/tests/integration/test_trash_bin.gd:291`, `godot/tests/integration/test_trash_bin.gd:303`, `godot/tests/integration/test_trash_bin.gd:324`, `godot/tests/integration/test_trash_bin.gd:327`, `godot/tests/integration/test_level_01.gd:33` |
| ADR-003 §10.3 | Spawners: `ItemSpawner.can_interact` es `true` con la mano llena | Hasta D26 era `true` con la mano llena; ya no. Lo desmentía la nota retirada, por eso pasa a la frase | `godot/core/action_rules.gd:68` |
| `scene-tree.md` §2 | `test_level_01.gd` lo exige: recorre esas instancias y comprueba la distancia mínima de cada `TrashBin`, además del encuadre | Lo exige el mismo test de T6. El encuadre lo comprueba `test_t6_gap_keeps_one_meter_clear_and_bins_not_under_hud`; `test_level_01.gd` solo fija las posiciones | `godot/tests/integration/test_trash_bin.gd:291`, `godot/tests/integration/test_trash_bin.gd:330`, `godot/tests/integration/test_level_01.gd:33` |

## Tras PUL-198

| Sitio | Frase antigua | Frase nueva | Código |
|---|---|---|---|
| `signals.md` §2, `order_patience_changed` | Receptor: `order_ticket.gd` | Añade `order_stand.gd`: no lee los valores; es su aviso de que llegó el siguiente `advance` tras caducar su comanda | `godot/entities/stations/order_stand.gd:65`, `godot/entities/stations/order_stand.gd:221` |
| `signals.md`, «Estación al paso» | El indicador combina la comanda viva y la caja en la mano | Añade que, tras caducar su comanda, espera a `order_patience_changed` para aceptar a la repuesta | `godot/entities/stations/order_stand.gd:65`, `godot/entities/stations/order_stand.gd:167` |
| `signals.md` (2), `scene-tree.md` §7, ADR-003 §11.7 y consecuencias (2), ADR-006 §4.1 | *Nota del gate: hoy `order_stand.gd:156` incumple «sin emisión en el juego» […]. Lo corrige PUL-198; el contrato no se matiza.* | *Nota del gate, resuelta: hasta PUL-198, `order_stand.gd` podía provocar la emisión con `penalty` 0 en el tick posterior a la caducidad […]. Desde PUL-198 la zona no pide `try_deliver` hasta el siguiente `advance`; el contrato no se matizó.* Con la precondición `OrderData.max_time > 0` completa en la fila de `delivery_rejected` de `signals.md` y remisión a ella en las demás | `godot/entities/stations/order_stand.gd:161`, `godot/entities/stations/order_stand.gd:167`, `godot/entities/stations/order_stand.gd:170`, `docs/arch/ADR-002-eventbus-autoloads.md:127`; hoy `godot/entities/stations/order_stand.gd:156` es `holder.drop()` |

## «Sin emisión en el juego»: comprobación

La frase se conserva, y las notas declaran su precondición: `OrderData.max_time > 0`. Con los datos del juego no hay camino de emisión:

- **Único emisor al bus**: `godot/autoload/order_service.gd:96`, que reenvía al tablero. **Único que pide entregar**: `godot/entities/stations/order_stand.gd:154`, tras `_zone_accepts` (`godot/entities/stations/order_stand.gd:161`).
- **`godot/core/order_board.gd:150`, caducada en el último `advance`**: el puesto activa la espera en `order_expired` y la apaga en la primera `order_patience_changed`. El `advance` limpia `_expired_this_tick` antes de emitirla (`godot/core/order_board.gd:122`, `godot/core/order_board.gd:133`) y, dentro de un mismo `advance`, las emite antes de cualquier caducidad (`godot/core/order_board.gd:138`). Así que la espera no se apaga mientras el núcleo aún rechazaría.
- **`godot/core/order_board.gd:154`, sin comanda**: con `_order` nulo el puesto no pregunta, y su copia sale de las señales que quitan la comanda del tablero.
- **`godot/core/order_board.gd:157`, paciencia agotada y viva**: el mismo `advance` que agota la paciencia la borra.
- **`godot/core/order_board.gd:160`, caja errónea**: el puesto comprueba `OrderValidator.matches` con los mismos datos justo antes de preguntar.
- **Ejecutado**: reproducción de PUL-196 con `REPRO_LEAD` 0, 1 y 2, las tres con 0 emisiones (`repro-entrega.txt`). Es la que dio 1 emisión con `REPRO_LEAD=1` antes de PUL-198 (`docs/evidence/PUL-196/repro-entrega.txt`). Fuerza paciencia y teletransporte; no es una partida completa.

**Rama sin paciencia, no alcanzable con los datos del juego**. Si la repuesta tiene `max_time <= 0` y no hay otra comanda con paciencia, la espera termina por tiempo (`godot/entities/stations/order_stand.gd:170`). Una pausa justo después de la caducidad deja pasar los ticks de física sin `advance`, y al reanudar hay una emisión con `penalty` 0. Ejecutado en `sonda-pausa-sin-paciencia.txt`: 1 emisión con `max_time` 0 y 0 con `max_time` 60, con el mismo guion. Las cuatro comandas de `godot/data/orders/order_catalog.tres` tienen `max_time` 60 u 80 y los multiplicadores de `godot/data/config/round_config.tres` son 1,0, 0,85 y 0,7 (`datos-paciencia.txt`), así que no se da en el juego. Por eso las notas lo declaran como precondición, y una comanda con `max_time` 0 obligaría a revisar la frase.

## Marcas

| Sitio | Frase antigua | Frase nueva |
|---|---|---|
| ADR-003, encabezado de §10 | aceptada por el responsable el 2026-11-04 (salvo lo marcado en §10.3) | aceptada por el responsable el 2026-11-04 (atribución de §10.3 corregida en PUL-205) |

## No verificable

- **Partida completa de `level_01` con un jugador real**: la reproducción y la sonda fuerzan la situación. Motivo: sin jugador humano ni sesión grabada en este entorno.
- **Ausencia de emisión en todas las partidas posibles**: es un argumento por lectura más tres casos ejecutados, no una prueba exhaustiva.
- **Fuera de esta tabla**: otras frases de las secciones tocadas, salvo las que lista la ficha. Las que se vieron dudosas de pasada están en la ficha, sin corregir.
