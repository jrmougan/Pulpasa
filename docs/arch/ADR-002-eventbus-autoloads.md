# ADR-002 — Bus de eventos y autoloads (sustituto de QFramework)

- **Estado:** propuesto
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
- **Relacionado:** `docs/arch/signals.md`, ADR-001, ADR-003, ADR-005 (D14); inventario §1 (Architecture, Systems,
  Commands/Events) y §4 (B1, B2, B10, B11, B16)

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

### Lista de autoloads (en este orden en `project.godot`)

| # | Autoload | Script | Responsabilidad | `process_mode` |
|---|---|---|---|---|
| 1 | `EventBus` | `autoload/event_bus.gd` | Solo declara señales tipadas (catálogo `signals.md`). Sin estado ni lógica | `INHERIT` |
| 2 | `GameState` | `autoload/game_state.gd` | Modo de juego (`GameMode.Mode.SINGLE` / `COOP_2P`; el enum vive en `core/game_mode.gd` para poder tiparlo fuera del autoload), asignación jugador ↔ dispositivo (ADR-004), pausa (`set_paused()` → `get_tree().paused`) y cambios de escena (`go_to_main_menu()`, `start_level(mode)`) | `ALWAYS` |
| 3 | `OrderService` | `autoload/order_service.gd` | Catálogo de comandas, comandas activas (máx. 4), asignación a puesto, generación con `RandomNumberGenerator` inyectable, validación pura y completado. **Sin acceso a escena** | `INHERIT` |
| 4 | `RoundManager` | `autoload/round_manager.gd` | Reloj único de ronda (duración en `RoundConfig.tres`), contador de entregas, resultado de fin de ronda. M1: recaudación y estrellas | `INHERIT` (se detiene con la pausa) |

La ficha pedía `EventBus`, `OrderService` y `GameState`; se añade `RoundManager` porque el
inventario ya lo asigna como autoload (`ProductivitySystem` → `RoundManager (A)`) y separar el reloj
del estado de sesión evita que `GameState` crezca sin límite. El bridge del MCP de Godot se
inyecta en tiempo de ejecución y no forma parte de esta lista.

### Correspondencia QFramework → Godot

| QFramework / prototipo | Godot |
|---|---|
| `Architecture` (`PulpaSAArchitecture`) | Lista de autoloads de `project.godot` |
| `System` (`OrderSystem`) | Autoload de servicio (`OrderService`) |
| `Model` (estado del sistema) | Estado privado del autoload con getters de solo lectura |
| `Command` (`RequestOrderCommand`) | Método público del servicio (`OrderService.request_order(slot_id)`) |
| `Event` (`OrderGeneratedEvent`…) | Señal tipada de `EventBus` |
| `Query` | Getter del servicio (`OrderService.get_order_for_slot(slot_id)`) |
| `Utility` (`IRandomUtility`) | `RandomNumberGenerator` inyectable (`OrderService.set_rng(rng)`) |
| `RegisterEvent` / `UnRegister` | `EventBus.<señal>.connect(callable)`; se desconecta solo al liberar el nodo receptor |
| `MonoBehaviour` "sistema" de escena | Autoload (si es global) o nodo en su escena (si es local) |

### Reglas de uso
1. **Hechos por señal, órdenes por método.** Las señales de `EventBus` anuncian algo que *ya
   pasó* (`order_completed`). Para pedir algo se llama a un método del autoload dueño
   (`OrderService.try_deliver(...)`). No hay señales `*_requested` en el bus.
2. **Un emisor por señal.** Cada señal tiene un único dueño que la emite (columna Emisor de
   `signals.md`). Nadie más la emite, tampoco los tests de integración (los unitarios sí, para
   simular).
3. **Dependencias solo hacia arriba en la lista.** Un autoload puede llamar a los anteriores, nunca
   a los posteriores: `RoundManager` → `OrderService` → `EventBus`; `GameState` → `EventBus`.
   `OrderService` no conoce `RoundManager`; se entera de la ronda por los métodos que este le llama.
4. **Los autoloads no conocen nodos de escena.** Reciben y devuelven datos (`BoxContents`,
   `ActiveOrder`, `int slot_id`), nunca `Node`. Las escenas escuchan señales (B16: los puestos
   escuchan `orders_reset` en lugar de ser buscados).
5. **Validar no muta.** `OrderValidator.matches(order_data, contents) -> bool` es una función pura
   en `core/`. `OrderService.try_deliver(slot_id, contents) -> ActiveOrder` valida y, solo si
   coincide, completa **esa** comanda una vez, emite `order_completed` y repone el puesto
   (`order_generated`). Una entrega → una señal (B1).
6. **Arranque determinista.** El nivel llama `RoundManager.start_round(config, slot_ids)`, que en este orden
   hace `OrderService.reset()` (emite `orders_reset`), `OrderService.fill_slots(slot_ids)` y emite
   `round_started` (B10, B11). La UI nunca arranca la ronda.
7. **Datos inyectados, no cargados por ruta mágica.** `OrderService.setup(catalog: OrderCatalog)`
   recibe el catálogo desde el `@export` del nivel; nada de `ResourceLoader` sobre carpetas
   (sustituye a `Resources.LoadAll`).
8. **Testeables sin árbol.** Los autoloads no llevan `class_name` (ADR-001); el test hace
   `var svc: Node = preload("res://autoload/order_service.gd").new()`, le inyecta catálogo y RNG
   con semilla y comprueba señales con `watch_signals`. Los reinicios entre tests usan `reset()`.
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

## Consecuencias
- (+) B1, B2, B10, B11 y B16 quedan imposibles por construcción y cubiertos por tests unitarios.
- (+) `OrderService` y `RoundManager` se prueban en headless sin cargar escenas y no dependen de D14.
- (+) El catálogo de señales es el contrato entre fichas paralelas: cada ficha sabe qué emite y
  qué escucha sin leer el código de otra.
- (−) Añadir o cambiar una señal del bus es un cambio de contrato: requiere enmendar `signals.md`
  con ADR y gate humano.
- (−) Los autoloads persisten entre escenas: cada uno debe exponer `reset()` y el nivel debe
  llamarlo al empezar (lo hace `RoundManager.start_round`).
- (−) `GameState` en `PROCESS_MODE_ALWAYS` sigue vivo en pausa; no debe contener lógica de juego.
- Fase 0 de M0 registra los cuatro autoloads (vacíos pero con sus señales/métodos públicos) en
  `project.godot`; fase 2 implementa `OrderService` y `RoundManager`.
