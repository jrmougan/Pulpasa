# Catálogo de señales

- **Estado:** propuesto (contrato; ver ADR-002)
- **Ficha:** PUL-003

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

`Player` (`entities/player/player.gd`, `CharacterBody3D` o `CharacterBody2D` según D14) es de la
capa específica y **no** aparece en ninguna firma común: ni en el bus ni en el contrato de
interacción (que usa `InteractionComponent` y `Holder`, ADR-003 §4).

`BoxContents` no es señal, pero es el parámetro de `OrderService.try_deliver(slot_id, contents)`:
así el servicio valida datos y nunca recibe un nodo.

## 2. Señales de `EventBus`

### Ronda — emisor `RoundManager` (reenvía `RoundState`)

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `round_started(duration: float)` | `RoundManager` (en `start_round`, después de `OrderBoard.reset()` y `fill_slots()`) | `hud.gd` (inicia la vista del tiempo), `player.gd` (habilita input), `game_over.gd` (se oculta) | Una vez por ronda | 2 (emisor), 4/7 (receptores) |
| `round_time_changed(time_left: float)` | `RoundManager` | `hud.gd` | Al empezar y cada vez que cambia el segundo entero de `time_left`, dentro de `RoundState.advance()`; es el **único reloj** (B2) | 2 / 7 |
| `round_finished(result: RoundResult)` | `RoundManager` | `game_over.gd` (muestra resultado), `player.gd` (bloquea input), `character_switcher.gd` (bloquea cambio, M2), `pause_menu.gd` (no permite pausar) | Exactamente al llegar `time_left` a 0 (no antes por redondeo, B2), después de procesar la paciencia de ese mismo `advance` (ADR-002) | 2 / 4, 7 |
| `score_changed(boxes_delivered: int, revenue: int)` | `RoundManager` (tras `order_completed`, `order_expired` o `delivery_rejected` con `penalty` > 0) | `hud.gd` | M0: `revenue` siempre 0 y el HUD muestra cajas/minuto como el prototipo. M1: recaudación (D2) | 2 / 7 |

### Comandas — emisor `OrderService` (reenvía `OrderBoard`)

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `orders_reset()` | `OrderService` (`OrderBoard.reset()`) | `order_stand.gd` (vacía su `#id`), `order_tickets_panel.gd` (borra tickets) | Al empezar ronda, antes de generar comandas (B10, B16) | 2 / 6, 7 |
| `order_generated(order: ActiveOrder)` | `OrderService` (`OrderBoard`: `request_order` / `fill_slots` / reposición) | `order_tickets_panel.gd` (crea ticket con `time_left`/`max_time` iniciales), `order_stand.gd` (si `order.slot_id == slot_id`, muestra `#id`) | Al crear una comanda, máx. 4 activas; una por puesto | 2 / 6, 7 |
| `order_completed(order: ActiveOrder, points: int)` | `OrderService` (`OrderBoard.try_deliver()` cuando la caja coincide) | `RoundState` (señal del núcleo: cuenta entrega; M1 suma `points`), `order_tickets_panel.gd` (quita ticket), `order_stand.gd` (sonido OK, limpia `#id`) | **Una vez por entrega**, sobre la comanda entregada (B1). Después se emite `order_generated` para reponer ese puesto | 2 / 6, 7 |
| `delivery_rejected(slot_id: int, order_id: int, penalty: int)` | `OrderService` (`OrderBoard.try_deliver()` cuando la caja no coincide con la comanda viva del puesto, o cuando la comanda del puesto caducó en el último `advance`) | `order_stand.gd` (sonido de error si es su `slot_id`; la caja se queda en la mano), `RoundState` (M1: resta `penalty`) | Cada intento fallido. `order_id` = comanda a la que se vinculó el intento (−1 si el puesto no tenía). Caja errónea: M0 `penalty` = 0 (paridad), M1 penalización en datos (D8). Empate con caducidad: `order_id` de la caducada, `penalty` = 0 (ya penalizó `order_expired`) y sin redirigir a la repuesta (AC5b; ADR-002) | 2 / 6 |
| `order_patience_changed(order_id: int, time_left: float, max_time: float)` | `OrderService` (`OrderBoard.advance()`) | `order_ticket.gd` (barra lineal de paciencia, Must 3; sin contador propio) | Una vez por comanda con `max_time > 0` en cada `advance` (cada tick de física). No se emite en pausa ni tras `round_finished` | M1 (firma desde fase 0) |
| `order_expired(order: ActiveOrder, penalty: int)` | `OrderService` (`OrderBoard.advance()`, paciencia agotada) | `RoundState` (resta penalización), `order_tickets_panel.gd` (quita ticket), `order_stand.gd` (limpia `#id`) | En el `advance` en que `time_left` llega a 0, antes que cualquier entrega del mismo tick; luego repone con `order_generated` en la misma llamada | M1 |

### Sesión y jugadores — emisores `GameState` y `CharacterSwitcher`

| Señal | Emisor | Receptores | Cuándo | Fase |
|---|---|---|---|---|
| `pause_changed(is_paused: bool)` | `GameState.set_paused()` | `pause_menu.gd` (muestra/oculta y da foco), `hud.gd` (atenúa) | Al cambiar `get_tree().paused`; no se emite si no cambia | 7 |
| `character_switched(player_index: int, character_index: int)` | `character_switcher.gd` | `player.gd` (todos: indicador activo si su `player_index == character_index`), `hud.gd` (retrato activo) | Al cambiar el personaje controlado por `player_index`; una vez por cambio y también al asignar al empezar la ronda | M2 |
| `device_assigned(player_index: int, device: int)` | `GameState` | `hud.gd` (aviso "J2 conectado"), `pause_menu.gd` (oculta aviso de desconexión) | Al asignar o quitar un mando a un jugador (inicio o hot-plug); `device` = id del mando, `DeviceAssignment.ANY` (−1, solo en `SINGLE`) o `DeviceAssignment.NONE` (−2, solo teclado) | M2 |
| `device_disconnected(player_index: int)` | `GameState` (desde `Input.joy_connection_changed`) | `pause_menu.gd` (muestra aviso en ≤ 0,5 s; `GameState` ya pausó) | Al desconectarse un mando asignado durante la ronda | M2 |

## 3. Secuencias

**Arranque de ronda** (`level.gd._ready`):
`OrderService.setup(catalog)` → `RoundManager.start_round(config, slot_ids)` →
`orders_reset` → `order_generated` × nº de puestos (máx. 4) → `round_time_changed(duration)` →
`round_started(duration)`.

**Tick** (`RoundManager._physics_process`, primero del tick; ADR-002 «Reloj y paciencia»):
`RoundState.advance(d)` → `OrderBoard.advance(d)` → `order_patience_changed` × comandas con paciencia
→ por cada vencida, en orden de `slot_id`: `order_expired` → `score_changed` → `order_generated`
(mismo puesto, mismo frame) → `round_time_changed` si cambia el segundo → si `time_left` = 0:
`OrderBoard.stop()` y `round_finished(result)`. En pausa no hay ticks.

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
| `item_picked_up(item: Node)` | `Holder` (base común; lo emite `HoldComponent`) | `player.gd` (parámetro `is_holding` del `AnimationTree`) | Tras `on_picked_up` del objeto | 4 |
| `item_dropped(item: Node)` | `Holder` (ídem) | `player.gd` (ídem) | Tras `on_dropped` del objeto | 4 |
| `target_changed(previous: Node, current: Node)` | `InteractionDetector` (específico: `Area3D`/`Area2D`) | `interaction_component.gd` (guarda el objetivo). El propio `InteractionDetector` (capa específica) desactiva el `Highlightable` de `previous` y activa el de `current` antes de emitir; ambos pueden ser `null`. *Enmienda 2026-10-03, aprobada por el responsable tras la revisión de PUL-015* | Solo cuando cambia el objetivo, no cada frame (B7) | 5 |
| `cooking_started(ingredient: Ingredient)` | `cooking_station.gd` | barra de progreso de `kitchen.tscn`, `AudioStreamPlayer3D` de hervir | Al aceptar un pulpo crudo | 6 |
| `cooking_finished(ingredient: Ingredient)` | `cooking_station.gd` | barra de progreso y audio de `kitchen.tscn` | Al cumplirse `cook_time` de `IngredientData` | 6 |
| `fill_changed(fill: float)` | `box.gd` | barra en mundo de `box.tscn` | Cada corte sobre la caja (D1) | 6 |
| `seasoned(seasoning: SeasoningData)` | `box.gd` | audio de molinillo de `box.tscn` | Al aplicar un condimento | 6 |
| `amount_changed(remaining: float)` | `ingredient.gd` | barra en mundo de `octopus.tscn` | Cada corte; a 0 el pulpo se libera solo (B9) | 6 |

`Ingredient` es el `class_name` de `entities/items/ingredient.gd` (raíz de `octopus.tscn`).

Si una señal local la necesita otra escena (p. ej. audio global de feedback, Must 9), se promueve
a `EventBus` con enmienda de este documento.
