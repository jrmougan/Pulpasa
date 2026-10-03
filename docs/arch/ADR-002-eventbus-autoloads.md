# ADR-002 — Bus de eventos y autoloads (sustituto de QFramework)

- **Estado:** aceptado (2026-10-03)
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
- **Relacionado:** `docs/arch/signals.md`, ADR-001, ADR-003, ADR-005 (D14); inventario §1 (Architecture, Systems,
  Commands/Events) y §4 (B1, B2, B10, B11, B16); feature `comandas` (paciencia)

## Contexto

El prototipo usa QFramework (`Plugins/QFramework/QFramework.cs`, MIT):
- `PulpaSAArchitecture` (`Architecture/PulpasaArchitecture.cs`) es un contenedor IoC que registra
  un único sistema, `OrderSystem`.
- `OrderSystem` (`Systems/OrderSystem.cs`) mezcla estado (`ActiveOrders`), generación aleatoria,
  validación y **acceso a la escena** (`ResetOrders` usa `FindObjectsByType<OrderStand>`, B16).
- Eventos `OrderGeneratedEvent` / `OrderCompletedEvent` se envían de forma síncrona;
  `ObjectPickedUpEvent` / `ObjectDroppedEvent` nunca se usan.
- `Bootstrap` registra `IRandomUtility`, que nadie consume.
- El resto de "sistemas" son `MonoBehaviour` en `Level_01` (`ProductivitySystem`,
  `OrderTicketUIController`, `PauseManager`) que se buscan unos a otros por referencia de
  inspector, con orden de `Start` no determinista (B10) y lógica de ronda arrancada desde la UI (B11).

El bug más grave del prototipo (B1, doble `CompleteOrder`) nace de que validar **también** completa
y de que un listener síncrono reasigna el puesto en mitad de la entrega.

Godot ofrece autoloads (nodos singleton bajo `/root`, creados antes de la escena principal, en el
orden de `project.godot`) y señales tipadas. Necesitamos estado global de partida, un servicio de
comandas testeable sin escena y un canal de eventos entre escenas desacopladas.

## Decisión

### Dos niveles: núcleo `RefCounted` + autoload adaptador

Toda la lógica y el estado viven en clases `RefCounted` de `core/` que reciben sus dependencias
por constructor (datos, RNG, otros núcleos) y **emiten sus propias señales**. No tocan `SceneTree`,
`Time`, `Input` ni ningún singleton. El tiempo solo avanza cuando alguien llama `advance(delta)`.

Los autoloads son **adaptadores finos**: crean el núcleo, le pasan `delta` desde `_physics_process`, reenvían
sus señales a `EventBus` y exponen sus métodos al resto del juego. No contienen reglas de juego.

| Núcleo (`core/`, `class_name`) | Dependencias inyectadas | Responsabilidad | Adaptador (autoload) |
|---|---|---|---|
| `OrderBoard` | `OrderCatalog`, `RandomNumberGenerator` | Comandas activas (máx. 4) por puesto, generación, paciencia (`advance(delta)`), caducidad, validación (con `OrderValidator` puro), completado, reposición | `OrderService` |
| `RoundState` | `RoundConfig`, `OrderBoard` | Reloj único de ronda, contador de entregas, recaudación (M1), fin de ronda, `RoundResult` | `RoundManager` |
| `DeviceAssignment` | — (funciones `static`) | Reparto jugador ↔ mando según modo y mandos conectados (ADR-004) | `GameState` |

Un test crea `OrderBoard.new(catalog, RandomNumberGenerator con semilla)` y
`RoundState.new(config, board)` sin árbol, llama `advance()` con deltas exactos y comprueba señales
con `watch_signals` sobre las instancias. Dos instancias de cada núcleo no comparten nada (sin
estáticos mutables), así que se pueden probar en paralelo y en aislamiento. Los adaptadores se
prueban aparte, solo para comprobar el reenvío al bus.

### Lista de autoloads (en este orden en `project.godot`)

| # | Autoload | Script | Responsabilidad | `process_mode` |
|---|---|---|---|---|
| 1 | `EventBus` | `autoload/event_bus.gd` | Solo declara señales tipadas (catálogo `signals.md`). Sin estado ni lógica | `INHERIT` |
| 2 | `GameState` | `autoload/game_state.gd` | Modo de juego (`GameMode.Mode.SINGLE` / `COOP_2P`; el enum vive en `core/game_mode.gd` para poder tiparlo fuera del autoload), aplica `DeviceAssignment` al InputMap (ADR-004), pausa (`set_paused()` → `get_tree().paused`) y cambios de escena (`go_to_main_menu()`, `start_level(mode)`) | `ALWAYS` |
| 3 | `OrderService` | `autoload/order_service.gd` | Adaptador de `OrderBoard`: `setup(catalog)`, `try_deliver(slot_id, contents)`, `get_active_orders()`; reenvía sus señales al bus. **Sin acceso a escena**. No tiene `_process`: su tiempo lo avanza `RoundManager` | `INHERIT` |
| 4 | `RoundManager` | `autoload/round_manager.gd` | Adaptador de `RoundState`: `start_round(config, slot_ids)`; en `_physics_process(delta)` llama `RoundState.advance(delta)`; reenvía señales | `INHERIT` (se detiene con la pausa) |

La ficha pedía `EventBus`, `OrderService` y `GameState`; se añade `RoundManager` porque el
inventario ya lo asigna como autoload (`ProductivitySystem` → `RoundManager (A)`) y separar el reloj
del estado de sesión evita que `GameState` crezca sin límite. El bridge del MCP de Godot se
inyecta en tiempo de ejecución y no forma parte de esta lista.

### Correspondencia QFramework → Godot

| QFramework / prototipo | Godot |
|---|---|
| `Architecture` (`PulpaSAArchitecture`) | Lista de autoloads de `project.godot` (composición de núcleos en sus `_ready`) |
| `System` (`OrderSystem`) | Núcleo `RefCounted` (`OrderBoard`) + autoload adaptador (`OrderService`) |
| `Model` (estado del sistema) | Estado privado del núcleo con getters de solo lectura |
| `Command` (`RequestOrderCommand`) | Método público del núcleo, expuesto por el adaptador (`request_order(slot_id)`) |
| `Event` (`OrderGeneratedEvent`…) | Señal del núcleo, reenviada como señal tipada de `EventBus` |
| `Query` | Getter (`get_order_for_slot(slot_id)`, `get_active_orders()`) |
| `Utility` (`IRandomUtility`) | `RandomNumberGenerator` inyectado en el constructor del núcleo |
| `RegisterEvent` / `UnRegister` | `EventBus.<señal>.connect(callable)`; se desconecta solo al liberar el nodo receptor |
| `MonoBehaviour` "sistema" de escena | Núcleo + autoload (si es global) o nodo en su escena (si es local) |

### Reloj y paciencia (Must 3, B2)
`RoundManager._physics_process(delta)` es el **único** sitio donde entra tiempo. Se usa el paso
fijo de física (determinista, 60 Hz) y `process_physics_priority` mínima, para que en cada tick
el reloj avance **antes** que cualquier otro nodo. Llama `RoundState.advance(delta)`, que hace, en
este orden y en la misma llamada:
1. `d = min(delta, time_left)` (no se pasa del fin de ronda).
2. `OrderBoard.advance(d)`: resta `d` al `time_left` de cada comanda activa con `max_time > 0`;
   emite `order_patience_changed(order_id, time_left, max_time)` por comanda; las que llegan a
   `time_left <= 0` **caducan** (`order_expired`) y su puesto se repone en la misma llamada
   (`order_generated`), en orden ascendente de `slot_id`.
3. Resta `d` al reloj de ronda, emite `round_time_changed` si cambió el segundo entero y, si llega
   a 0, `OrderBoard.stop()` (no repone ni caduca más) y `round_finished`.

Consecuencias de ese orden:
- **Pausa**: `get_tree().paused` detiene `RoundManager._physics_process`; nada avanza, ni ronda ni
  paciencia. La UI no lleva contadores propios.
- **Empate caducar/entregar (por `order_id`)**: gana la caducidad y la entrega **no se redirige a
  la comanda repuesta** (feature `entrega-y-puntuacion` AC5b).
  - Al empezar cada `advance`, `OrderBoard` vacía `_expired_this_tick: Dictionary[int, int]`
    (`slot_id → order_id`) y registra en él cada comanda que caduca en ese `advance`.
  - Todo intento de entrega que llega **después** de ese `advance` y antes del siguiente
    (`body_entered` o `_physics_process` del puesto en el mismo tick, o la pulsación de
    interactuar del tick siguiente, que se procesa antes de su `advance`) queda vinculado al
    `order_id` que el puesto tenía **antes** del avance. Si ese puesto está en
    `_expired_this_tick`, `try_deliver` emite `delivery_rejected(slot_id, order_id_caducada, 0)`,
    devuelve `null` y **no valida** contra la repuesta, aunque tenga la misma receta. La penalización
    ya la aplicó `order_expired`; el rechazo no penaliza otra vez.
  - Una entrega que llega antes del `advance` que agota la paciencia ve la comanda viva
    (`time_left > 0`) y se completa (AC5c). `try_deliver` nunca acepta una comanda con
    `time_left <= 0`.
  - La comanda repuesta es entregable a partir del siguiente `advance` (un tick, 1/60 s).
  - **Caso de prueba obligatorio** (`test_order_board.gd`, sin árbol):
    `test_ac5b_delivery_on_expiry_tick_rejected_not_redirected`. Catálogo con **una sola** receta
    (`max_time` = 60), un puesto, RNG con semilla. `advance()` hasta `t` = 60,0 exacto (p. ej.
    3600 × 1/60 o `advance(60.0)`), luego `try_deliver(slot, contenido_valido)`. Esperado:
    1 `order_expired`, 1 `order_generated` de reposición para ese puesto en el mismo `advance`,
    `try_deliver` devuelve `null`, 1 `delivery_rejected` con el `order_id` caducado y `penalty` 0,
    **0** `order_completed` e ingreso 0 en `RoundState`. Control: tras un `advance(1/60)` más, la
    misma entrega completa la repuesta (1 `order_completed`).
- **Fin de ronda**: una comanda que caduca en el mismo `advance` que acaba la ronda caduca (paso 2
  antes que 3). Tras `round_finished`, `try_deliver` devuelve `null` sin señales.
- **Paridad M0**: los tres `OrderData` del prototipo tienen `max_time = 0` → sin paciencia ni
  `order_patience_changed`. M1 rellena `max_time` (40–90 s) y `first_order_delay` sin cambiar
  contratos.
- **Tickets**: al crearse leen el estado inicial de `order_generated(order)` (`time_left`,
  `max_time`) y luego escuchan `order_patience_changed`; `OrderService.get_active_orders()`
  devuelve copias para reconstruir la vista (p. ej. al cargar la UI tarde).

### Reglas de uso
1. **Hechos por señal, órdenes por método.** Las señales de `EventBus` anuncian algo que *ya
   pasó* (`order_completed`). Para pedir algo se llama a un método del autoload dueño
   (`OrderService.try_deliver(...)`). No hay señales `*_requested` en el bus.
2. **Un emisor por señal.** Cada señal del bus la emite un solo adaptador (columna Emisor de
   `signals.md`), reenviando la señal homónima de su núcleo. Nadie más la emite; los tests
   unitarios trabajan con las señales del núcleo, no con el bus.
3. **Dependencias explícitas.** Un núcleo solo conoce lo que recibe en el constructor
   (`RoundState` recibe el `OrderBoard`; `OrderBoard` no conoce `RoundState`). Los adaptadores
   componen: `RoundManager.start_round` toma `OrderService.board` (autoload anterior en la lista);
   ningún núcleo lee un autoload.
4. **Los núcleos no conocen nodos.** Reciben y devuelven datos (`BoxContents`, `ActiveOrder`,
   `int slot_id`), nunca `Node`. Las escenas escuchan señales (B16: los puestos escuchan
   `orders_reset` en lugar de ser buscados).
5. **Validar no muta.** `OrderValidator.matches(order_data, contents) -> bool` es una función pura
   en `core/`. `OrderBoard.try_deliver(slot_id, contents) -> ActiveOrder` primero aplica la regla de
   empate por `order_id` (rechaza si la comanda del puesto caducó en el último `advance`), valida y,
   solo si coincide, completa **esa** comanda una vez, emite `order_completed` y repone el puesto
   (`order_generated`). Una entrega → una señal (B1).
6. **Arranque determinista.** El nivel llama `RoundManager.start_round(config, slot_ids)`, que
   crea un `RoundState` nuevo y en este orden hace `OrderBoard.reset()` (`orders_reset`),
   `OrderBoard.fill_slots(slot_ids)` y emite `round_started` (B10, B11). La UI nunca arranca la ronda.
7. **Datos inyectados, no cargados por ruta mágica.** El catálogo llega desde el `@export` del
   nivel (`OrderService.setup(catalog)` → `OrderBoard.new(catalog, rng)`); nada de
   `ResourceLoader` sobre carpetas (sustituye a `Resources.LoadAll`).
8. **Testeables sin árbol ni singletons.** Los tests de reglas instancian núcleos, nunca autoloads.
   Los autoloads no llevan `class_name` (ADR-001); su test (reenvío al bus) los instancia con
   `preload("res://autoload/<x>.gd").new()` y un `EventBus` también instanciado a mano, inyectado
   con `set_bus(bus)` (por defecto, el autoload).
9. **Señales locales fuera del bus.** Lo que solo importa dentro de una escena (la olla terminó,
   la caja se llenó) es señal del propio nodo, no de `EventBus`. Se promueve al bus solo cuando un
   sistema de otra escena la necesita, con enmienda de `signals.md`.
10. **Independiente de la dimensión (D14).** Autoloads, `core/`, `resources/` y las firmas de
    `EventBus` no usan nodos ni tipos espaciales (`Node3D`, `Node2D`, `Vector3`, `Transform3D`…):
    solo primitivos, `Resource` y tipos de valor de `core/`; las entidades se identifican por
    índice o id (`slot_id`, `player_index`, `order.id`). Así las fases 0–2 de M0 sirven para 3D y
    para 2D (ADR-005). Si la lógica pura necesita geometría, usa `Vector2` en el plano del suelo.

## Alternativas consideradas
1. **Portar QFramework o usar un contenedor IoC en GDScript.** Añade una capa ajena al motor y
   ninguna ventaja: los autoloads ya son singletons con ciclo de vida gestionado. Descartada.
2. **Señales directas entre nodos sin bus** (`stand.order_completed.connect(hud...)`). Obliga a
   que cada receptor tenga referencia al emisor, entre escenas que no se conocen (HUD ↔ puestos)
   y lleva a rutas absolutas. Descartada para tráfico entre sistemas; se usa para señales locales.
3. **Un único autoload `Game` con todo** (estado, comandas, ronda). Menos ficheros, pero un dueño
   gigante que todas las fichas tocarían a la vez y difícil de probar. Descartada.
4. **Servicios como nodos dentro del nivel** (como `ProductivitySystem` en `Level_01`). Desaparecen
   al cambiar de escena y obligan a buscarlos; reaparece B10. Descartada; solo lo local vive en escena.
5. **Bus genérico por strings** (`EventBus.emit("order_completed", [...])`). Pierde tipado y
   autocompletado. Descartada en favor de señales declaradas con tipos.
6. **Lógica directamente en los autoloads** (instanciarlos con `new()` en tests). No aísla: llaman
   a otros singletons y emiten al `EventBus` global, y su tiempo depende de `_process`. Descartada
   en favor de núcleo `RefCounted` + adaptador.
7. **Paciencia con `Timer` por comanda o contador en el ticket.** Reintroduce relojes paralelos
   (B2), no se prueba sin árbol y rompe el orden caducar/entregar. Descartada.

## Consecuencias
- (+) B1, B2, B10, B11 y B16 quedan imposibles por construcción y cubiertos por tests unitarios.
- (+) Entrega, caducidad, pausa y fin de ronda se prueban sin `SceneTree` con deltas exactos.
- (+) Núcleos y bus no dependen de D14.
- (+) El catálogo de señales es el contrato entre fichas paralelas: cada ficha sabe qué emite y
  qué escucha sin leer el código de otra.
- (−) Cada señal existe dos veces (núcleo y bus) y el adaptador debe reenviarla; un test por
  adaptador comprueba que no falta ninguna.
- (−) Añadir o cambiar una señal del bus es un cambio de contrato: requiere enmendar `signals.md`
  con ADR y gate humano.
- (−) Los autoloads persisten entre escenas: `start_round` crea núcleos nuevos en vez de reutilizar
  estado.
- (−) `GameState` en `PROCESS_MODE_ALWAYS` sigue vivo en pausa; no debe contener lógica de juego.
- Fase 0 de M0 registra los cuatro autoloads (con sus señales/métodos públicos) en `project.godot`;
  fase 2 implementa `OrderBoard`, `RoundState` y sus adaptadores.
