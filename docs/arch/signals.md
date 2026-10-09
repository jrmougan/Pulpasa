# Catálogo de señales

- **Estado:** propuesto (contrato; ver ADR-002)
- **Ficha:** PUL-003; enmienda de la estación de condimentos en PUL-056 (2026-10-05, D18),
  **pendiente del gate humano**: §1 (tipos nuevos) y §4 (señales locales). `EventBus` no cambia.
- **Enmienda M3** (PUL-066, 2026-10-06, ADR-006 y ADR-002 Enmienda 1), **pendiente del gate
  humano**: `phase_changed` en `EventBus` (§2); secuencias de arranque y tick con fases (§3);
  señales locales de quemado y `FeedbackPlayer.played`, y receptores de feedback (§4, §5).
  Ninguna señal local sube al bus por el audio (ADR-006 §3).
- **Enmienda D23** (PUL-093, 2026-10-07, ADR-003 §9), **pendiente de la revisión del producer**:
  **ninguna señal nueva ni cambio de firma** (ni en `EventBus` ni locales). Cambian los casos en que
  dispensador y cuenco emiten `rejected` (§4: caja en la mano, sin bandeja), `NO_BOX` y
  `NOT_ACCEPTED` pasan a desuso (§1) y se documentan los receptores nuevos de señales existentes
  (indicador de entrega del puesto y franja de color del ticket, §2 y §4).

Contrato entre fichas. Las señales de `EventBus` (§2) son las únicas que cruzan escenas; cambiarlas
(añadir, renombrar, cambiar firma o emisor) requiere enmienda con ADR y gate humano. Las señales
locales (§4) se documentan para que cada ficha sepa qué exponen sus escenas vecinas; cambiarlas
solo requiere actualizar esta tabla en la misma ficha.

Reglas (ADR-002): hechos en pasado; **un emisor por señal**; las órdenes van por método del
autoload, no por señal; se conectan en `_ready()` del receptor. Las señales de ronda y comandas
nacen en los núcleos `RefCounted` (`RoundState`, `OrderBoard`, misma firma) y su autoload
adaptador las reenvía con `EventBus.<señal>.emit(...)`: el emisor en el bus es el adaptador; los
tests unitarios observan el núcleo. Entre núcleos no se usa el bus: `RoundState` escucha
directamente las señales del `OrderBoard` que recibe en su constructor. **Las firmas de `EventBus` son independientes de la dimensión** (D14, ADR-005): solo
primitivos, `Resource` y tipos de valor de `core/`; nunca nodos ni `Vector2`/`Vector3`. Las
entidades se identifican por índice o id. "Fase" = fase de M0 (0–8) en que se implementa emisor o primer receptor, o hito
posterior (M1, M2…). Todas se **declaran** en `event_bus.gd` en la fase 0, aunque se emitan después.

## 1. Tipos usados en las firmas

| Tipo | Clase base | Archivo | Campos relevantes |
|---|---|---|---|
| `ActiveOrder` | `RefCounted` | `core/active_order.gd` | `id: int`, `data: OrderData`, `slot_id: int`, `max_time: float` (de `OrderData`; 0 = sin paciencia, todo M0), `time_left: float`. Las señales y `get_active_orders()` entregan copias: modificarlas no altera el `OrderBoard` |
| `RoundResult` | `RefCounted` | `core/round_result.gd` | `duration: float`, `boxes_delivered: int`, `boxes_per_minute: float`; M1: `revenue: int`, `stars: int` |
| `BoxContents` | `RefCounted` | `core/box_contents.gd` | `box: BoxData`, `ingredient: IngredientData` (o `null`), `fill: float` (0–1), `seasonings: Array[SeasoningData]` |
| `OrderData`, `BoxData`, `IngredientData`, `SeasoningData` | `Resource` | `resources/*.gd` | Ver inventario §1 (ScriptableObjects) |
| `GameMode.Mode` | enum | `core/game_mode.gd` | `SINGLE`, `COOP_2P` |
| `SeasoningRules.Rejection` | enum | `core/seasoning_rules.gd` | `NONE`, `NO_BOX` (en desuso desde D23: sin caja en la mano el dispensador no es objetivo), `BOX_NOT_FULL`, `HAND_BUSY` (en desuso desde PUL-064: nadie lo emite), `EXCLUSIVE_TAKEN` (solo con `paprika_swap` = `false`), `BOWL_EMPTY`, `BOWL_FULL`, `NOT_ACCEPTED` (en desuso desde D23: con cachelos crudos o quemados u otra cosa el cuenco no es objetivo). No se quitan del enum para no renumerar. Solo en señales locales (§4) |
| `PhaseData` | `Resource` | `resources/phase_data.gd` | `start_fraction: float` (0–1 de `duration`), `active_slots: int`, `patience_multiplier: float` (1,0 = el `max_time` de `OrderData`; cambio del responsable al aprobar ADR-006). En `RoundConfig.phases`; no aparece en señales (M3, ADR-006 §6) |
| `IngredientData.CookingState` | enum | `resources/ingredient_data.gd` | `RAW`, `COOKED`, `BURNT` (M3: `BURNT` lo pone la olla tras `burn_time`). No aparece en señales |
| `StationSide.Side` | enum | `core/station_side.gd` | `PASS`, `OPERATOR` (ADR-003 §8.1). No aparece en ninguna señal; lo devuelve `SeasoningStation.side_of()` |

`Player` (`entities/player/player.gd`, `CharacterBody3D` o `CharacterBody2D` según D14) es de la
capa específica y **no** aparece en ninguna firma común: ni en el bus ni en el contrato de
interacción (que usa `InteractionComponent` y `Holder`, ADR-003 §4).

`BoxContents` no es señal, pero es el parámetro de `OrderService.try_deliver(slot_id, contents)`:
así el servicio valida datos y nunca recibe un nodo.

## 2. Señales de `EventBus`

### Ronda — emisor `RoundManager` (reenvía `RoundState`)

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `round_started(duration: float)` | `RoundManager` (en `start_round`, después de `OrderBoard.reset()`; las comandas iniciales llegan con `fill_slots()` antes de `round_started` si `first_order_delay` = 0, o tras ese retardo dentro de `RoundState.advance()` si es > 0) | `hud.gd` (inicia la vista del tiempo), `player.gd` (habilita input), `game_over.gd` (se oculta), `level_audio.gd` (M3: arranca BG y FOL) | Una vez por ronda | 2 (emisor), 4/7 (receptores) |
| `round_time_changed(time_left: float)` | `RoundManager` | `hud.gd` | Al empezar y cada vez que cambia el segundo entero de `time_left`, dentro de `RoundState.advance()`; es el **único reloj** (B2) | 2 / 7 |
| `round_finished(result: RoundResult)` | `RoundManager` | `game_over.gd` (muestra resultado), `player.gd` (bloquea input), `character_switcher.gd` (bloquea cambio, M2), `pause_menu.gd` (no permite pausar) | Exactamente al llegar `time_left` a 0 (no antes por redondeo, B2), después de procesar la paciencia de ese mismo `advance` (ADR-002) | 2 / 4, 7 |
| `score_changed(boxes_delivered: int, revenue: int)` | `RoundManager` (tras `order_completed`, `order_expired` o `delivery_rejected` con `penalty` > 0) | `hud.gd` | Recaudación en euros (D2) | 2 / 7 |
| `phase_changed(phase: int)` | `RoundManager` (reenvía `RoundState`) | `level_audio.gd` (cue `phase_up` si `phase` ≥ 2), `hud.gd` (aviso «Fase n», Could) | `phase` desde 1. Una vez en `start` (fase 1, tras `orders_reset` y antes de las comandas iniciales) y una vez por fase al alcanzar `start_fraction × duration` dentro de `advance`, antes de `round_time_changed` y de rellenar los puestos que abre; nunca con la ronda terminada. Sin `RoundConfig.phases` no se emite. *Enmienda PUL-066* | M3 |

### Comandas — emisor `OrderService` (reenvía `OrderBoard`)

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `orders_reset()` | `OrderService` (`OrderBoard.reset()`) | `order_stand.gd` (vacía su `#id`; M3c: apaga `DeliveryFrame` (malla dentro de `Model`, `material_off`)), `order_tickets_panel.gd` (borra tickets) | Al empezar ronda, antes de generar comandas (B10, B16) | 2 / 6, 7 |
| `order_generated(order: ActiveOrder)` | `OrderService` (`OrderBoard`: `request_order` / `fill_slots` / reposición) | `order_tickets_panel.gd` (crea ticket con `time_left`/`max_time` iniciales; M3c: tamaño de `order.data.recipe.box` y franja `StandPalette.color_for(order.slot_id)`), `order_stand.gd` (si `order.slot_id == slot_id`, muestra `#id`; M3: cue `order_new`, con `delay`; M3c: nueva comanda viva para el indicador de entrega) | Al crear una comanda, máx. 4 activas; una por puesto | 2 / 6, 7 |
| `order_completed(order: ActiveOrder, points: int)` | `OrderService` (`OrderBoard.try_deliver()` cuando la caja coincide) | `RoundState` (señal del núcleo: cuenta entrega; M1 suma `points`), `order_tickets_panel.gd` (quita ticket), `order_stand.gd` (limpia `#id`; M3: cue `deliver_ok` + `POP` si es su `slot_id`; M3c: apaga `DeliveryFrame` (malla dentro de `Model`, `material_off`)) | **Una vez por entrega**, sobre la comanda entregada (B1). Después se emite `order_generated` para reponer ese puesto | 2 / 6, 7 |
| `delivery_rejected(slot_id: int, order_id: int, penalty: int)` | `OrderService` (`OrderBoard.try_deliver()` cuando la caja no coincide con la comanda viva del puesto, o cuando la comanda del puesto caducó en el último `advance`) | `order_stand.gd` (si es su `slot_id`: cue `deliver_error` + `SHAKE`; la caja se queda en la mano), `RoundState` (M1: resta `penalty`) | Cada intento fallido. `order_id` = comanda a la que se vinculó el intento (−1 si el puesto no tenía). Caja errónea: Penalización según datos (D8). Empate con caducidad: `order_id` de la caducada, `penalty` = 0 (ya penalizó `order_expired`) y sin redirigir a la repuesta (AC5b; ADR-002) | 2 / 6 |
| `order_patience_changed(order_id: int, time_left: float, max_time: float)` | `OrderService` (`OrderBoard.advance()`) | `order_ticket.gd` (barra lineal de paciencia, Must 3; sin contador propio) | Una vez por comanda con `max_time > 0` en cada `advance` (cada tick de física). No se emite en pausa ni tras `round_finished` | M1 (firma desde fase 0) |
| `order_expired(order: ActiveOrder, penalty: int)` | `OrderService` (`OrderBoard.advance()`, paciencia agotada) | `RoundState` (resta penalización), `order_tickets_panel.gd` (quita ticket), `order_stand.gd` (limpia `#id`; M3: cue `order_expired` si es su `slot_id`; M3c: apaga `DeliveryFrame` (malla dentro de `Model`, `material_off`)) | En el `advance` en que `time_left` llega a 0, antes que cualquier entrega del mismo tick; luego repone con `order_generated` en la misma llamada | M1 |

### Sesión y jugadores — emisores `GameState` y `CharacterSwitcher`

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `pause_changed(is_paused: bool)` | `GameState.set_paused()` | `pause_menu.gd` (muestra/oculta y da foco), `hud.gd` (atenúa), `AudioDirector` (M3: baja `Music`/`Ambience` `pause_duck_db`, ADR-006 §2) | Al cambiar `get_tree().paused`; no se emite si no cambia | 7 |
| `character_switched(player_index: int, character_index: int)` | `character_switcher.gd` | `player.gd` (todos: indicador activo si su `player_index == character_index`), `hud.gd` (retrato activo) | Al cambiar el personaje controlado por `player_index`; una vez por cambio y también al asignar al empezar la ronda | M2 |
| `device_assigned(player_index: int, device: int)` | `GameState` | `hud.gd` (aviso "J2 conectado"), `pause_menu.gd` (oculta aviso de desconexión) | Al asignar o quitar un mando a un jugador (inicio o hot-plug); `device` = id del mando, `DeviceAssignment.ANY` (−1, solo en `SINGLE`) o `DeviceAssignment.NONE` (−2, solo teclado) | M2 |
| `device_disconnected(player_index: int)` | `GameState` (desde `Input.joy_connection_changed`) | `pause_menu.gd` (muestra aviso en ≤ 0,5 s; `GameState` ya pausó) | Al desconectarse un mando asignado durante la ronda | M2 |

## 3. Secuencias

**Arranque de ronda** (`level.gd._ready`):
`OrderService.setup(catalog, null, config)` (semilla `config.rng_seed` si ≠ 0) →
`RoundManager.start_round(config, slot_ids)` → `orders_reset` → [con fases: `phase_changed(1)`] →
`order_generated` × puestos activos (máx. 4; todos sin fases; solo si `first_order_delay` = 0) →
`round_time_changed(duration)` → `round_started(duration)`.

**Tick** (`RoundManager._physics_process`, primero del tick; ADR-002 «Reloj y paciencia»):
`RoundState.advance(d)` → `OrderBoard.advance(d)` → `order_patience_changed` × comandas con paciencia
→ por cada vencida, en orden de `slot_id`: `order_expired` → `score_changed` → `order_generated`
(mismo puesto, mismo frame) → reloj de ronda − `d` → por cada fase alcanzada (M3):
`phase_changed(n)` → `order_generated` × puestos que abre → `round_time_changed` si cambia el
segundo → si `time_left` = 0: `OrderBoard.stop()` y `round_finished(result)`. En pausa no hay ticks.

**Entrega correcta** (`order_stand.gd`, al entrar el portador en el área o al interactuar, B12):
`OrderService.try_deliver(slot_id, box.get_contents())` →
`order_completed(order, points)` → `score_changed(n, revenue)` (desde `RoundManager`) →
`order_generated(nueva)` para el mismo `slot_id` → el puesto suelta y libera la caja.

**Entrega errónea**: `try_deliver` devuelve `null` → `delivery_rejected(slot_id, order_id, penalty)`; no cambia el estado de las comandas (M1: `RoundState` resta `penalty` y `RoundManager` reenvía `score_changed`).

**Entrega en el tick de caducidad** (AC5b): tick N: `advance` → `order_expired(A)` → `order_generated(B)` (mismo puesto) → entrega de la caja → `delivery_rejected(slot_id, A.id, 0)`; sin `order_completed` ni ingreso. B solo es entregable desde el `advance` del tick N+1.

**Fin de ronda**: `round_time_changed(0.0)` → `round_finished(result)`; el reloj se para y
`OrderService` no repone más.

## 4. Señales locales (no pasan por `EventBus`)

Las de componentes comunes (`ControlComponent`, `Holder`) y las de la capa específica (ADR-003 §0)
usan `Node` en sus firmas para valer en 3D y en 2D.

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `control_changed(controlled_by: int)` | `ControlComponent` (común) | `player.gd` (activa/desactiva movimiento e indicador), `InteractionComponent` (ignora input si 0) | Al cambiar quién controla el personaje (`CharacterSwitcher` o inicio de ronda) | 4 / M2 |
| `item_picked_up(item: Node)` | `Holder` (base común; lo emite `HoldComponent`) | `player.gd` (parámetro `is_holding` del `AnimationTree`); M3: `%Feedback` de `player.tscn` (cue `pick_up`, `POP` de `item`) | Tras `on_picked_up` del objeto | 4 |
| `item_dropped(item: Node)` | `Holder` (ídem) | `player.gd` (ídem); M3: `%Feedback` (cue `drop`) | Tras `on_dropped` del objeto. También al dejarlo en una estación: suena junto a la cue de la estación (ADR-006 §4) | 4 |
| `target_changed(previous: Node, current: Node)` | `InteractionDetector` (específico: `Area3D`/`Area2D`) | `interaction_component.gd` (guarda el objetivo). El propio `InteractionDetector` (capa específica) desactiva el `Highlightable` de `previous` y activa el de `current` antes de emitir; ambos pueden ser `null`. *Enmienda 2026-10-03, aprobada por el responsable tras la revisión de PUL-015* | Solo cuando cambia el objetivo, no cada frame (B7) | 5 |
| `cooking_started(ingredient: Ingredient)` | `cooking_station.gd` | barra de progreso de `kitchen.tscn`, `AudioStreamPlayer3D` de hervir; M3: `%Feedback` (cue `cook_start`), vapor y fuego vivo | Al aceptar un ingrediente crudo cocinable (pulpo o cachelos, D10) en una plaza libre (D9) | 6 |
| `cooking_finished(ingredient: Ingredient)` | `cooking_station.gd` | barra de progreso y audio de `kitchen.tscn`; M3: `%Feedback` (cue `cook_done`) | Al cumplirse `cook_time` de `IngredientData`. Desde M3 (con `burn_time` > 0) arranca el reloj de quemado de la plaza | 6 |
| `burn_warned(ingredient: Ingredient)` | `cooking_station.gd` | `%CookBar` de la plaza (se muestra y parpadea), `%Feedback` (cue `burn_warning`) | Una vez por plaza al cumplirse `warn_time` (s desde `cooking_finished`) con el ingrediente aún en ella; no si `burn_time` = 0. Se congela en pausa. *Enmienda PUL-066* | M3 |
| `burnt(ingredient: Ingredient)` | `cooking_station.gd` | `%Feedback` (cue `burnt`); la malla `_burnt` la pone `Ingredient.set_burnt()` antes de emitir | Una vez al cumplirse `burn_time`; el ingrediente pasa a `BURNT`. Es la `octopus_burnt` de `olla-que-se-pasa` AC1, generalizada a cualquier ingrediente. *Enmienda PUL-066* | M3 |
| `discarded(ingredient: Ingredient)` | `cooking_station.gd` | `%Feedback` (cue `discard`) | Al desechar un `BURNT` (mano vacía sobre la olla; el quemado más antiguo antes que cualquier cocido), antes de `queue_free`; la plaza queda libre. *Enmienda PUL-066* | M3 |
| `played(cue: StringName)` | `FeedbackPlayer` (`components/feedback_player.gd`, capa específica) | tests (AC2/AC5 de `audio-y-fx`) | Una vez por `play_cue()` con cue conocida, al llamar a `play()` (tras el `delay` si lo hay). *Enmienda PUL-066* | M3 |
| `fill_changed(fill: float)` | `box.gd` | barra en mundo de `box.tscn`; M3: `%Feedback` (cue `cut`, sustituye a `%CutAudio`) | Cada corte sobre la caja (D1) | 6 |
| `seasoned(seasoning: SeasoningData)` | `box.gd` | audio de molinillo de `box.tscn` (M3: `%Feedback`, cue `season`); `%BadgeRow` de `box.tscn` (M2, PUL-059) | Al aplicar un condimento. Desde D18 solo la emite `Box.toggle_seasoning()` (la llaman dispensadores y cuenco); `interact()` ya no condimenta | 6 / M2 |
| `seasoning_removed(seasoning: SeasoningData)` | `box.gd` | `%BadgeRow` de `box.tscn` (rehace la fila); M3: `%Feedback` (cue `unseason`) | Al quitar un condimento: `toggle_seasoning()` sobre uno que ya lleva, o `remove_seasoning()`. En el intercambio de pimentón (`paprika_swap`) se emite **antes** que el `seasoned` del nuevo, una vez cada una, en la misma llamada (AC4). *Enmienda PUL-056* | M2 |
| `rejected(reason: SeasoningRules.Rejection)` | `seasoning_dispenser.gd` (`SeasoningDispenser`) | `seasoning_station.gd` (suena `%ErrorAudio` y sacude el emisor; M3: `%Feedback`, cue `season_error`) | Al consumir una pulsación sin cambiar nada: caja de la mano sin llenar (`BOX_NOT_FULL`, R3), pimentón exclusivo con `paprika_swap` = `false`. **No** se emite por el antirrebote, ni desde el lado de pase (ADR-003 §8.1), ni sin una caja en la mano (el dispensador no es objetivo, `is_reachable_from` = `false`). *Enmienda PUL-056; PUL-064 quita «mano ocupada»; D23 (PUL-093, ADR-003 §9.1): actúa sobre la caja de la mano, sin bandeja* | M2 |
| `rejected(reason: SeasoningRules.Rejection)` | `cachelos_bowl.gd` (`CachelosBowl`) | `seasoning_station.gd` (ídem) | Al consumir una pulsación sin cambiar nada: cuenco vacío al poner cachelos en la caja (`BOWL_EMPTY`), cuenco lleno al reponer o al quitar cachelos de la caja (`BOWL_FULL`). Desde D23 no hay `NO_BOX`, `BOX_NOT_FULL` ni `NOT_ACCEPTED`: solo es objetivo con cachelos cocidos o con una caja llena en la mano (ADR-003 §9.1). *Enmienda PUL-056; D23 (PUL-093)* | M2 |
| `stock_changed(stock: int)` | `cachelos_bowl.gd` | visual de raciones de `cachelos_bowl.tscn` (`%Portions`) | Al reponer (+`cachelos_portions_per_item`), al poner cachelos en la caja (−1) y al quitarlos (+1). También una vez en `_ready()` con `cachelos_initial_stock`. *Enmienda PUL-056* | M2 |
| `amount_changed(remaining: float)` | `ingredient.gd` | barra en mundo de `octopus.tscn` | Cada corte; a 0 el pulpo se libera solo (B9) | 6 |

`Ingredient` es el `class_name` de `entities/items/ingredient.gd` (raíz de `octopus.tscn`).

`SeasoningDispenser`, `CachelosBowl` y `SeasoningStation` son los `class_name` de
`entities/stations/{seasoning_dispenser,cachelos_bowl,seasoning_station}.gd` (PUL-058).

**Estación de condimentos: por qué nada sube a `EventBus`** (PUL-056). Todos los receptores de
`seasoned`, `seasoning_removed`, `rejected` y `stock_changed` están dentro de la misma escena que el
emisor (`box.tscn` o `seasoning_station.tscn`). El ticket no escucha a la caja: ordena los
condimentos de la **comanda** con `SeasoningRules.canonical_order()` y comparte con la caja solo
datos (`SeasoningData`, `BoxBadgeStyle`). La entrega sigue leyendo `box.get_contents()`. Los
tests de integración y la guía de playtest de PUL-062 (pulsaciones de error) se conectan a las
señales locales de la instancia del nivel. Si una métrica o el audio global (Must 9) los necesita
fuera de la escena, se promueven con enmienda.

**Secuencia de un dispensador** (D23, `SeasoningDispenser.interact`, lado de condimentar, **caja en
la mano**; sin caja no es objetivo): antirrebote (`toggle_guard`, reloj de juego inyectable) → caja
= `actor.holder.get_held_item() as Box` → sin llenar: `rejected(BOX_NOT_FULL)` →
`box.toggle_seasoning(seasoning, data.paprika_swap)` → `NONE`: la caja emite
`seasoning_removed(anterior)` (solo si intercambia o quita) y/o `seasoned(nuevo)`; otro valor:
`rejected(valor)`. La caja sigue en la mano y su `%BadgeRow` se rehace con esas señales. **Cuenco**
al alternar (caja llena en la mano): si la caja no lleva cachelos y `stock` = 0,
`rejected(BOWL_EMPTY)`; si los lleva y `stock` = máx., `rejected(BOWL_FULL)`; si cambia,
`stock_changed` tras la señal de la caja. ~~`station.get_box()` nulo: `rejected(NO_BOX)`~~ (baja
D23).

**Estación al paso, puesto y ticket: por qué no hace falta ninguna señal nueva** (D23, PUL-093).
Condimentar en la mano reutiliza `seasoned` / `seasoning_removed` / `rejected` / `stock_changed`
con los mismos emisores y receptores. El indicador de la zona de entrega (`order_stand.gd`, ADR-003
§9.4) combina dos cosas que el puesto ya tiene: la comanda viva de su `slot_id` (de
`orders_reset` / `order_generated` / `order_completed` / `order_expired`) y la caja en la mano de los
cuerpos de su `%ProximityArea` (lectura local, como `%DeliveryZone`); se recalcula en
`_physics_process`, así que tampoco necesita `item_picked_up` ni `seasoned` del portador. El ticket
lee el tamaño (`order.data.recipe.box.short_label` / `icon`) y el color
(`StandPalette.color_for(order.slot_id)`) de los datos que ya recibe en `order_generated`. Se
descartó `EventBus.delivery_hint_changed(slot_id, lit)`: ningún receptor fuera del puesto.

Si una señal local la necesita otra escena, se promueve a `EventBus` con enmienda de este documento.

## 5. Feedback de audio y visual (M3, ADR-006)

El feedback de Must 9 **no** promueve señales locales: cada escena conecta sus señales (locales o
de `EventBus` filtradas por su id) a su `%Feedback` (`FeedbackPlayer`), que reproduce **un** sonido
por llamada en el bus `SFX` y lanza la respuesta visual de la cue (`data/audio/feedback_map.tres`).
La mezcla (buses, pausa, volúmenes) es de `AudioDirector`; BG y FOL, de `LevelAudio`. Tabla
completa evento → cue → escena → visual en ADR-006 §4.

Cobertura de las features:

| Feature · AC | Señal | Dónde |
|---|---|---|
| audio-y-fx AC1 (BG/FOL) | `EventBus.round_started` | `LevelAudio` (`Music`, `Ambience`) |
| audio-y-fx AC2 corte · caldero · coger · soltar | `fill_changed` · `cooking_started` · `item_picked_up` · `item_dropped` (locales) | `box.tscn` · `kitchen.tscn` · `player.tscn` |
| audio-y-fx AC2 nueva comanda · entrega · caducada | `EventBus.order_generated` · `order_completed` · `order_expired` | `order_stand.tscn` (su `slot_id`) |
| audio-y-fx AC5 cocer · condimentar | `cooking_started`/`cooking_finished` · `seasoned` | `kitchen.tscn` · `box.tscn` |
| audio-y-fx AC5 entrega correcta / errónea | `EventBus.order_completed` / `delivery_rejected` | `order_stand.tscn`: `deliver_ok` + `POP` / `deliver_error` + `SHAKE` |
| audio-y-fx AC3 (pausa) | `EventBus.pause_changed` | `AudioDirector` |
| olla AC1 · AC2 · AC3 | `burnt` · `burn_warned` · `discarded` (locales) | `kitchen.tscn` |
| olla AC4 (pausa) | — (reloj en `_physics_process`) | `CookingStation` |
| fases AC1–AC6 | `EventBus.phase_changed` + secuencias §3 | `RoundState` / `RoundManager` |

AC2 de `audio-y-fx` dice "su señal de `EventBus`"; con ADR-006 §3 se lee "su señal (de `EventBus`
o local)". Pendiente de R2 en el gate.
