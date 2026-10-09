# ADR-003 — Árbol de escenas y composición

- **Estado:** aceptado (2026-10-03); enmienda §8 (estación de condimentos) **propuesta**, pendiente
  del gate humano (PUL-056); enmienda §9 (estación al paso, D23) **aceptada** por el producer el 2026-10-07 tras la
  revisión del producer (PUL-093); sustituye las partes de §8 que dependían de la bandeja;
  enmienda de §3 (API de `Holder`), §9.4 y §9.5 tras implementar M3c (PUL-103) **aprobada** por el
  responsable en gate humano
- **Fecha:** 2026-10-03; enmiendas 2026-10-05, 2026-10-07 y 2026-10-09
- **Ficha:** PUL-003; enmiendas PUL-056 (D18, D19), PUL-093 (D23) y PUL-103 (lo que cambió al
  implementar M3c en PUL-097…PUL-101)
- **Relacionado:** `docs/arch/scene-tree.md` (árbol objetivo de M0), ADR-001 (carpetas), ADR-002
  (autoloads), ADR-005 (3D o 2D, D14 pendiente), inventario §1 (Characters, Game, Interaction,
  Interfaces) y §3 (prefabs, escenas)

## Contexto

En Unity, `Level_01.unity` contiene directamente jugador, estaciones, 17 mesas, cuatro
`OrderStand` con `deliverySlotId` sobrescrito, los "sistemas" (`ProductivitySystem`,
`OrderTicketUIController`, `PauseManager`, `GameOverUI`) y el `Bootstrap`. Muchos prefabs se
sobrescriben en la escena (las tres cajas de `Mueblecajas` pasan a spawners en
`Level_01.unity:5304-5395`). Varios prefabs duplican componentes (dos `InteractionDetector` en
`Player.prefab`, B7) y hay tres prefabs de caja y tres de condimento que solo difieren en datos.

En el flujo de trabajo con agentes, **un `.tscn` tiene un único dueño por oleada** (CLAUDE.md,
regla 5). Una escena de nivel grande serializaría todas las fichas de estaciones y UI. Además
Godot no tiene interfaces: hay que fijar cómo se expresa el contrato de `IInteractable` e
`IPickable` (el inventario lo delega a esta ADR).

Por último, **la dimensión del juego no está decidida** (D14, ADR-005): el prototipo es 3D, pero
el responsable valora 2D. Las fases 0–2 de M0 no deben depender de esa decisión, y las 3–8 deben
poder ejecutarse con cualquiera de las dos sin reescribir los contratos.

## Decisión

### 0. Dos capas: común y específica de dimensión

| Capa | Qué contiene | Depende de D14 |
|---|---|---|
| **Común** | `autoload/`, `core/`, `resources/`, `data/`; toda la UI de pantalla (`ui/` bajo `CanvasLayer`: HUD, tickets, menús, pausa, game over); `scenes/levels/level.gd`; componentes comunes `ControlComponent`, `Holder` (base abstracta), `InteractionComponent`; `CharacterSwitcher`; contrato de interacción (§4); nombres de grupos y capas (§5); InputMap (ADR-004) | No |
| **Específica** | `entities/` (jugador, objetos, estaciones, entorno, cámara), `HoldComponent` (implementa `Holder`), `InteractionDetector`, `Highlightable`, `shaders/`, `ui/widgets/world_progress_bar`, `assets/`, `level_01.tscn` | Sí |

Reglas de la capa común:
- Ningún script común referencia `Node3D`, `Node2D`, `Vector3`, `Transform3D`, `Area3D`/`Area2D`,
  cuerpos físicos **ni clases de la capa específica** (`Player`, `HoldComponent`, `Box`…), tampoco
  de forma transitiva en tipos de parámetros, `@export` o `Array[...]`. Lo específico se alcanza
  solo a través de una base común (`Holder`) o de `Node` + grupo + métodos verificados por test. Los scripts comunes que son nodos extienden `Node` o `Control` (un script
  `extends Node` se puede asignar a una raíz `Node3D` o `Node2D`).
- La geometría que la lógica necesita se expresa en el **plano del suelo** como `Vector2`
  (en 3D, `(x, z)`). Así `InteractionScoring` (cono, distancia, `dot*2 + 1/dist`) es el mismo
  código en ambas opciones.
- Las escenas específicas exponen la misma API (mismos `class_name`, `@export` públicos, señales
  locales, grupos y métodos del contrato) en 3D o en 2D; solo cambian el tipo de nodo raíz y los
  hijos visuales/físicos. La tabla de equivalencias está en `scene-tree.md` §6.
- Si D14 se resuelve en 2D, se sustituyen las escenas específicas; los tests unitarios y la UI no
  cambian.
- **Verificación**: los tests de los scripts comunes los instancian con dobles (`Node` simples y
  un `Holder` de prueba) sin cargar ninguna escena ni clase física; si un script común necesitara
  una clase específica para cargar, el test fallaría al compilar.

### 1. Escenas pequeñas, una por entidad
- Cada entidad, estación o pieza de UI es su propia escena con su script al lado
  (`entities/stations/kitchen.tscn` + `cooking_station.gd`, ADR-001).
- Las variantes que solo difieren en datos son **una escena + un `Resource`**: una `box.tscn` con
  `@export var data: BoxData` (S/M/L), una `seasoning_dispenser.tscn` con `SeasoningData` (§8; hasta
  PUL-061, también la `seasoning.tscn` de los botes, que se da de baja). Nada de escenas heredadas
  para variar un número.
- Las escenas compuestas (`box_shelf.tscn`, `seasoning_station.tscn`) instancian escenas hijas; no
  copian sus nodos.

### 2. `level_01.tscn` solo instancia
- La raíz lleva `scenes/levels/level.gd` (común, `extends Node`, **genérico para todos los
  niveles**), con `@export var round_config: RoundConfig`, `@export var order_catalog:
  OrderCatalog` y `@export var stands: Array[Node]` (los `OrderStand`; de ellos solo lee
  `slot_id`). En `_ready()` llama `OrderService.setup(order_catalog)` y
  `RoundManager.start_round(round_config, slot_ids)`. No tiene más lógica.
- El resto del nivel son instancias de escenas. Los únicos overrides permitidos son
  transformaciones, `slot_id` de cada puesto, `player_index`/`controlled_by` de cada personaje y
  referencias `@export` entre instancias del mismo nivel. Cualquier otro override indica que
  falta un `Resource` o un parámetro en la escena hija.
- La geometría estática (suelo, mesas, paredes) va en `entities/environment/kitchen_layout.tscn`
  para que su dueño (asset-pipeline / fase 8) no bloquee el nivel.
- La UI de partida es una `CanvasLayer` en el nivel que instancia `hud.tscn`,
  `order_tickets_panel.tscn`, `pause_menu.tscn` y `game_over.tscn`; cada una escucha `EventBus`.

### 3. Composición por componentes hijos
El jugador y los objetos se componen de nodos-componente reutilizables en `components/`, con
`@export` hacia sus hermanos o el padre, sin buscar por ruta:

| Componente | Capa | Nodo base (3D / 2D) | Sustituye a | Notas |
|---|---|---|---|---|
| `ControlComponent` | Común | `Node` | parte de `PlayerController` | `@export var player_index: int` (identidad del personaje), `var controlled_by: int` (jugador que lo controla, 0 = nadie), señal `control_changed(controlled_by)`. Crea el `PlayerInput` del jugador que lo controla (ADR-004) |
| `Holder` | Común (abstracta) | `Node` | `IPickable` + `PlayerHoldSystem` (API) | API de la mano: `get_held_item() -> Node`, `can_hold(item: Node) -> bool`, `pick_up(item: Node) -> bool`, `drop() -> Node`, `can_drop_freely() -> bool` (PUL-101: si soltar al suelo sin objetivo es posible; la base devuelve `true`, §9.5); señales `item_picked_up`/`item_dropped`. Los métodos base fallan con `push_error` (salvo `can_drop_freely`); los implementa `HoldComponent` |
| `InteractionComponent` | Común | `Node` | `PlayerInteractionController` | `@export var control: ControlComponent`, `@export var holder: Holder`, `@export var detector: Node` (conecta `target_changed` por nombre). Al pulsar `p<n>_interact` llama `interact(self)` del objetivo; si nada acepta y lleva algo, `holder.drop()` solo si `holder.can_drop_freely()`; si no, consume la pulsación sin soltar (PUL-101, §9.5) |
| `HoldComponent` | Específica | `Holder` + `Marker3D`/`Marker2D` `%HoldPoint` | `PlayerHoldSystem` | Implementa `Holder`: reparenta y coloca el objeto. Único camino: llama `on_picked_up`/`on_dropped` del objeto (B4); valida antes de mutar (B5). `can_drop_freely()` es `false` si el punto de soltar cae en la capa `world` (§9.5) |
| `InteractionDetector` | Específica | `Area3D` / `Area2D` | `InteractionDetector` | Un solo detector por jugador (B7); radio en `PlayerConfig.tres`. Delega la puntuación en `InteractionScoring` (común, `Vector2` del suelo) |
| `Highlightable` | Específica | `Node` | `HighlightController`, `OutlineHighlighter`, `InteractableHighlight` | 3D: `material_overlay` con shader de contorno; 2D: shader `canvas_item` de contorno. Retícula opcional. Sin `EmissionHighlighter` (B3) |

### 4. Contrato de interacción (sustituye a `IInteractable`/`IPickable`) — común
Godot no tiene interfaces; se usa **grupo + métodos con firma fija**, verificado por test:

| Grupo | Métodos obligatorios en el script raíz | Lo implementan |
|---|---|---|
| `interactable` | `can_interact(actor: InteractionComponent) -> bool`; `interact(actor: InteractionComponent) -> bool` (devuelve si consumió la pulsación). **Opcional** (§8): `is_reachable_from(floor_position: Vector2, holder: Holder) -> bool` | estaciones, slots, caja, puesto de entrega, pulpo y cachelos; dispensadores y cuenco de la estación de condimentos (§8). Condimento (bote): baja en PUL-061 |
| `pickable` | `on_picked_up(holder: Holder) -> void`; `on_dropped() -> void`; `var is_held: bool` | pulpo, cachelos, caja. Condimento (bote): baja en PUL-061 |
| `kitchen` | Ninguno (marca). Lo usa `InteractionDetector` para el bonus de puntuación con mano vacía (`PlayerConfig.kitchen_bonus`, equivale al tag `Kitchen` de Unity). No es una capa de física | raíz de `kitchen.tscn` (obligatorio) |
| `box` | Ninguno (marca, §8). Lo usaba `Slot.accepted_group` para que la bandeja de la estación solo aceptara cajas; sin usuario en el nivel desde D23 (§9), se conserva. No es una capa de física | raíz de `box.tscn` |

*Enmienda 2026-10-03 (grupo `kitchen`), aprobada por el responsable tras la revisión de PUL-015.*

*Enmienda 2026-10-03: pulpo y condimento están en `pickable` **e** `interactable`, como en Unity (`Ingredient.cs`, `SeasoningItem.cs` implementan `IPickable` e `IInteractable`). `InteractionScoring` solo elige un cogible si también es interactuable (paridad con `InteractionDetector.cs:99`). Aprobada por el responsable tras la revisión de PUL-016.*

- Los tipos del contrato (`InteractionComponent`, `Holder`) son comunes: el receptor accede a la mano
  con `actor.holder` y al jugador con `actor.control.controlled_by`, sin conocer `Player`. El
  contrato no cambia con D14.
- La interacción contextual va en el **receptor**: la caja decide si el objeto en la mano del
  actor la llena (pulpo cocido, corte D1/D13); no el controlador del jugador como en
  `PlayerInteractionController.cs:41,80`. Desde D18 la caja **no** se condimenta al interactuar con
  ella: el condimento cambia solo en los dispensadores y el cuenco de la estación (§8).
- Un test de integración recorre las escenas de `entities/` y falla si un nodo de un grupo no
  implementa sus métodos (`has_method`), para que el contrato no dependa de la disciplina.
- `InteractionDetector` solo ve cuerpos en la capa de física `interactable`; el nodo raíz de la
  entidad es ese cuerpo (o su padre directo).

### 5. Capas de física con nombre — comunes
Mismos números y nombres en `layer_names/3d_physics` o `layer_names/2d_physics`:

| Capa | Nombre | Uso |
|---|---|---|
| 1 | `world` | Suelo/paredes/mesas (en 2D: obstáculos) |
| 2 | `player` | Cuerpos de los personajes |
| 3 | `interactable` | Lo que el detector puede seleccionar |
| 4 | `held` | Objeto en la mano (sin colisión con el portador; sustituye a la capa `HeldObject`) |
| 5 | `delivery_zone` | Área del puesto de entrega |

### 6. Objetos generados y soltados — específica, misma regla
- Los spawners (`item_spawner.gd`, `@export var scene: PackedScene`) instancian el objeto
  **directamente en la mano del actor** (`actor.holder.pick_up(item)`), como el prototipo.
- Al soltar, el objeto se reparenta al nodo `Items` del nivel, que cada personaje recibe por
  `@export var items_root: Node` (override de referencia permitido en el nivel). En 2D, `Items`,
  `Characters` y `Stations` cuelgan de un mismo contenedor con `y_sort_enabled`.

### 7. Flujo de escenas — común
`ui/menus/main_menu.tscn` (escena principal desde la fase 7; `scenes/boot.tscn` queda como entrada
alternativa que salta al menú) → `scenes/levels/level_01.tscn`. Los cambios de escena pasan por
`GameState` (`start_level(mode)`, `go_to_main_menu()`, `restart_level()` para Reintentar), que usa
`get_tree().change_scene_to_file()` / `reload_current_scene()`; ninguna
escena cambia de escena por su cuenta. Pausa y game over son overlays dentro del nivel, no escenas.

### 8. Estación de condimentos (D18) — *enmienda 2026-10-05, PUL-056, pendiente del gate humano*

> **D23 (§9):** la bandeja (`Tray`) desaparece. Lo que aquí depende de ella (fila `Tray` de §8.1,
> dispensador con la mano vacía, `accepted_group` de la bandeja en §8.2 y `station.get_box()` en
> §8.3) queda sustituido por §9; el resto de §8 sigue vigente.
Diseño: `docs/design/features/estacion-condimentos.md` (aprobado el 2026-10-05, `paprika_swap` =
intercambiar). Árbol de nodos en `scene-tree.md` §3 y planta del nivel en `scene-tree.md` §2.

#### 8.1 Cómo sabe un dispensador desde qué lado se le usa
**Problema.** El dispensador solo responde desde el lado de condimentar (AC7: desde el pase «ni
se resalta ni responde»). El actor del contrato es `InteractionComponent` (común), que no tiene
posición, y el resaltado lo decide `InteractionDetector` antes de que nadie llame a
`can_interact`. Por tanto el filtro tiene que actuar **en la elección del objetivo**, y la capa común
no puede ver `Vector3` ni `Node3D` (§0).

**Decisión: geometría común en el plano del suelo + método opcional del contrato que consulta el
detector.**

| Pieza | Capa | Qué hace |
|---|---|---|
| `core/station_side.gd` (`class_name StationSide extends RefCounted`) | Común | `enum Side { PASS, OPERATOR }`; `static func classify(point: Vector2, pass_point: Vector2, operator_point: Vector2) -> Side`: `OPERATOR` si `(point − (pass_point + operator_point) / 2) · (operator_point − pass_point) ≥ 0`, si no `PASS`. Pura, test unitario. Es la misma regla en 3D (`(x, z)`) y en 2D |
| `is_reachable_from(floor_position: Vector2, holder: Holder) -> bool` | Común (contrato `interactable`, opcional) | Si la entidad lo implementa y devuelve `false`, **no es candidata** para ese jugador: no se resalta ni llega a ser objetivo. Sin el método, la entidad es alcanzable (todo lo existente sigue igual). Solo usa tipos comunes (`Vector2` del suelo y `Holder`) |
| `InteractionDetector` | Específica | Antes de crear el `Candidate` de una entidad, si `has_method(&"is_reachable_from")`, la llama con `Vector2(carrier.x, carrier.z)` y su `holder`; si devuelve `false`, la salta |
| `SeasoningStation.side_of(floor_position: Vector2) -> StationSide.Side` | Específica | Proyecta al suelo sus marcadores `%PassSide` y `%OperatorSide` (`Marker3D`, uno a cada lado del mostrador) y llama a `StationSide.classify`. Rotar o mover la estación en el nivel no cambia código |
| `SeasoningDispenser.is_reachable_from` | Específica | `false` si `holder` lleva algo (AC8, enmienda PUL-064); si no, `true` si `station.side_of(floor_position) == OPERATOR` o si `SeasoningStationData.operator_side_only` es `false` (válvula de balance de la feature) |
| `CachelosBowl.is_reachable_from` | Específica | `true` desde el lado de condimentar, o desde cualquier lado si la mano lleva algo (reponer cachelos cocidos vale por los dos lados; lo demás se rechaza, §8.2) |
| `Tray` (bandeja) | Específica | No implementa el método: se coge y se deja la caja desde los dos lados (AC9) |

`interact()` no repite la comprobación de lado: el detector recalcula el objetivo en cada tick de
física y la pulsación solo llega al objetivo publicado. Los tests de integración que llaman a
`interact()` a mano comprueban el lado con `is_reachable_from` (o pasan por el detector real).
`InteractionContract` (común) lo declara en una constante de métodos opcionales del grupo
`interactable` (solo nombres, sin tipos de mundo); el test de integración de la estación exige que
dispensadores y cuenco lo implementen.

**Alternativas descartadas.**
1. *Un `Area3D` por lado que registra quién está dentro.* Hay que mapear cuerpo → `InteractionComponent`
   (búsqueda por ruta o grupo), va un tick de física por detrás y en los extremos del mostrador los
   dos lados se solapan.
2. *Guardar la posición en `InteractionComponent` (`var floor_position: Vector2`, la escribe el
   detector).* Mete estado de mundo en un componente común y solo resuelve `interact()`, no el
   resaltado (AC7).
3. *Que el detector filtre con `can_interact(actor)`.* Cambia el resaltado de todas las entidades
   (hoy la caja se resalta aunque lo que llevas no le sirva y consume la pulsación) y el detector no
   tiene el `InteractionComponent`.
4. *Que el dispensador lea `actor.detector as Node3D`.* Funciona en la capa específica, pero ata la
   estación a cómo está montado el jugador y tampoco quita el resaltado.
5. *Colisión física por lado.* Imposible: el detector es una esfera sobre la capa `interactable`.

#### 8.2 Consumir y rechazar
`InteractionComponent.interact_pressed()` suelta lo que lleva la mano si el objetivo no consume la
pulsación. En la estación un rechazo **no debe tirar nada** (AC8: «la mano no cambia»). Regla:
- Dispensador: `can_interact(actor)` es `true` solo con `actor.holder` y la mano vacía (**enmienda
  PUL-064, aprobada por el responsable el 2026-10-05**: con algo en la mano no es objetivo —
  `is_reachable_from` devuelve `false`, §8.1—, así que el detector no lo resalta y gana la bandeja o el cuenco; `HAND_BUSY` queda en desuso). Cuenco:
  `can_interact(actor)` es `true` siempre que haya `actor.holder`. Ambos: `interact()`
  devuelve `true` aunque rechace y, al rechazar, emite su señal local `rejected(reason)` sin cambiar
  nada (`signals.md` §4). La estación oye esas señales, suena `%ErrorAudio` y sacude el emisor.
- Antirrebote (`toggle_guard`): la segunda pulsación se **consume en silencio** (sin `rejected`).
- `Slot` gana `@export var accepted_group: StringName = &""` (vacío = acepta cualquier cosa, como
  hoy). Si no está vacío y lo que lleva la mano no está en ese grupo, `interact()` consume la
  pulsación sin guardar nada. La bandeja usa `accepted_group = &"box"`. Con la bandeja ocupada, el
  detector sustituye el slot por la caja guardada, que ya consume la pulsación de una mano llena:
  no se suelta la segunda caja (AC9).

#### 8.3 Reglas en el núcleo y API de la caja
- `core/seasoning_rules.gd` (`class_name SeasoningRules`, común, puro): `enum Rejection { NONE,
  NO_BOX, BOX_NOT_FULL, HAND_BUSY (en desuso, PUL-064), EXCLUSIVE_TAKEN, BOWL_EMPTY, BOWL_FULL, NOT_ACCEPTED }`; alternar
  con o sin intercambio de exclusivos; `static func canonical_order(seasonings: Array[SeasoningData])
  -> Array[SeasoningData]` (por `SeasoningData.sort_order`, estable), que usan la fila de la caja y el
  ticket: comparten dato y regla, no nodos.
- `Box` (específica) expone `toggle_seasoning(seasoning: SeasoningData, swap_exclusive: bool) ->
  SeasoningRules.Rejection` (`NONE` = cambió algo) y `remove_seasoning(seasoning: SeasoningData) ->
  bool`. La caja deja de condimentar en `interact()` (sin botes ni cachelos en la mano, AC12).
- Los dispensadores y el cuenco alcanzan la caja con `station.get_box() -> Box` (la caja de la
  bandeja o `null`); referencias `@export` dentro de la escena de la estación, sin rutas.

#### 8.4 Escenas y bajas
- Cada dispensador es una instancia de `seasoning_dispenser.tscn` con `@export var seasoning:
  SeasoningData` (§1: variante de datos = una escena + `Resource`); el cuenco es
  `cachelos_bowl.tscn`. Así cada uno tiene su `%Highlightable` (un nombre único no se repite dentro
  de una escena) y el detector lo encuentra como hijo directo.
- La estación es `StaticBody3D` en la capa `world` (mostrador que no se cruza); no es
  `interactable`: lo son sus hijos (bandeja, dispensadores, cuenco).
- La fila de pegatinas de la caja (`%BadgeRow`) es 3D de mundo (`Sprite3D` en billboard, sin test de
  profundidad): vive en `entities/items/`, no en `ui/` (regla 4 de CLAUDE.md).
- Se dan de baja `spice_shelf.tscn`, `seasoning.tscn`, `seasoning_item.gd` (`SeasoningItem`), el
  placeholder `condiment_jar.tscn`, `Slot.initial_item_data` y la rama de condimentar de `box.gd`.
  Lista completa con la ficha que ejecuta cada baja en `scene-tree.md` §7.
- Ninguna señal nueva en `EventBus` (`signals.md` §4).

### 9. Estación al paso, pasaplatos marcados y entrega iluminada (D23) — *enmienda 2026-10-07, PUL-093, aceptada*

**Contexto.** D23 (responsable, 2026-10-07, sobre `docs/design/rediseno-estaciones.md`: C-B + B-A +
E-A + N-A) quita la bandeja de la estación: la caja llena **se lleva en la mano** y se pulsa cada
dispensador «al paso». Además: 6 pasaplatos marcados (el resto de la barra no acepta objetos),
tamaño S/M/L legible en ticket y rack, color de puesto en el ticket y zona de entrega que se
enciende, hueco de la barra a x ≈ 3,2 (montado con centro en x 3,5, §9.5) y 2 raciones por cachelo (máx. 4). Esta sección **sustituye**
lo que en §8 dependía de la bandeja (fila `Tray` de §8.1, `accepted_group` de la bandeja en §8.2,
`station.get_box()` en §8.3) y mantiene el resto de §8: la regla de lado (`StationSide`,
`is_reachable_from`, `side_of`), consumir al rechazar, `SeasoningRules` y la API de la caja. Tecla
única e InputMap sin cambios (D3, G9). Lo implementan PUL-097 (estación), PUL-098 (cajas), PUL-099
(ticket y `StandPalette`), PUL-100 (puesto) y PUL-101 (nivel).

#### 9.1 Quién es objetivo con qué en la mano
El filtro sigue siendo `is_reachable_from(floor_position, holder)` (§8.1): si devuelve `false`, el
detector no lo resalta ni lo publica. «Servicio» = `station.side_of(...) == OPERATOR`, o cualquier
lado si `SeasoningStationData.operator_side_only` es `false` (se mantiene `true`, pregunta abierta 3
de PUL-090).

| En la mano | Dispensador (×4) | Cuenco de cachelos |
|---|---|---|
| Nada | No es objetivo (R4) | No es objetivo |
| Caja llena | Servicio: alterna su condimento en **esa** caja (R1–R2) | Servicio: alterna cachelos en esa caja |
| Caja a medio cortar | Servicio: es objetivo y **rechaza** `BOX_NOT_FULL` (R3: la caja no cambia y suena `season_error`) | No es objetivo |
| Cachelos cocidos | No es objetivo | Cualquier lado: repone `+cachelos_portions_per_item` (R5–R6) |
| Otra cosa (pulpo, cachelos crudos o quemados) | No es objetivo | No es objetivo |
| Cualquier cosa, desde el lado de pase | No es objetivo | Solo cachelos cocidos (reponer) |

- La caja **siempre sigue en la mano** (R1): dispensador y cuenco consumen la pulsación (§8.2), así
  que `InteractionComponent` nunca suelta. Al rechazar emiten `rejected(reason)` sin cambiar nada.
- Asimetría deliberada con la caja a medio cortar: el dispensador es objetivo para que R3 dé
  feedback (`BOX_NOT_FULL`); el cuenco no, por la aclaración del responsable sobre D23 («con
  cualquier otra cosa no es objetivo»). Las dos son de `is_reachable_from`, sin código común.
- Con algo en la mano que no hace objetivo a nada de la estación, la pulsación sigue la regla general
  (soltar, §9.5).
- Defensa en profundidad: `can_interact(actor)` repite la condición de la mano (sin el lado, como en
  §8.1) y devuelve `false` en el resto de casos.
- `SeasoningRules.Rejection.NO_BOX` queda **en desuso** (como `HAND_BUSY`): sin caja en la mano el
  dispensador no es objetivo. No se quita del enum para no renumerar.

#### 9.2 Dónde está la caja y antirrebote
- Dispensador y cuenco toman la caja de `actor.holder.get_held_item() as Box`. **Se quitan**
  `SeasoningStation.get_box()` y `get_tray()`, y el nodo `Tray`. La estación conserva `data`,
  `side_of()` y la respuesta a `rejected` (cue `season_error` + sacudida del emisor).
- El antirrebote (`toggle_guard`, 0,25 s) usa el **reloj de juego**: segundos acumulados en
  `_physics_process` del propio nodo (se congela en pausa y sigue `Engine.time_scale`, como la olla).
  `clock: Callable` sigue siendo inyectable para tests; deja de usar `Time.get_ticks_usec`
  (pregunta abierta 4 de PUL-090). Aplica a dispensadores y al cuenco al alternar; la segunda
  pulsación dentro de la guarda se consume en silencio. Implementado en PUL-097 (`_game_time`;
  `engine_seconds` eliminado).
- Las pegatinas (`%BadgeRow`) siguen a la caja en la mano sin cambios: ya se rehacen con
  `seasoned`/`seasoning_removed`.

#### 9.3 Contratos de datos
| Recurso | Campo | Tipo | Valor / uso |
|---|---|---|---|
| `BoxData` (`resources/box_data.gd`, común) | `short_label` | `String` | «S», «M», «L» en `data/boxes/{small,medium,large}.tres` |
| `BoxData` | `icon` | `Texture2D` | silueta + letra de `assets/textures/ui/box_sizes/` (PUL-095); la usan el ticket (vía `RecipeData.box`) y, si quiere, el rack. Mismo recurso en los dos (R10) |
| `BoxData` | `fill_per_press` | `float` (ya existe) | 0,25 / 0,1667 / 0,1 → 4 / 6 / 10 pulsaciones (R9) |
| `StandPalette` (`resources/stand_palette.gd`, común, nuevo) | `colors` | `Array[Color]` | índice `slot_id − 1`; 4 entradas: rojo, azul, amarillo, verde (hex de los toldos, PUL-096) |
| `StandPalette` | `fallback` | `Color` | para un `slot_id` fuera de rango (no se espera en el nivel) |
| `StandPalette` | `color_for(slot_id: int) -> Color` | método | única forma de leerla; la usan `order_ticket.gd` (franja, R13) y `order_stand.gd` (zona encendida). Instancia: `data/config/stand_palette.tres` |
| `SeasoningStationData` (ya existe) | `cachelos_portions_per_item` / `cachelos_stock_max` | `int` | 1 → **2** / 3 → **4** (R6, D23); `operator_side_only` `true`, `toggle_guard` 0,25, `paprika_swap` `true` sin cambios |

`StandPalette` y `BoxData` solo usan `Color`, `String` y `Texture2D`: capa común (§0), válidos en
3D y 2D. El color del toldo del modelo del puesto (PUL-083/PUL-096) debe coincidir con la paleta;
PUL-100 lo comprueba (o tiñe el toldo desde la paleta).

#### 9.4 Indicador de entrega en `order_stand.tscn`
- Marca de la zona (enmienda PUL-103, implementada en PUL-100): **no hay nodo `%DeliveryMark`**.
  La pieza `delivery_zone` de PUL-096 viene dentro del `.glb` del puesto como la malla
  `DeliveryFrame` (hija de `Model`); `order_stand.gd` la localiza con
  `find_child("DeliveryFrame", true, false)` (búsqueda local en la propia escena, sin ruta absoluta)
  y alterna su `material_override` entre `@export var material_off` (compartido) y un duplicado por
  instancia de `@export var material_on` con `albedo_color` y `emission` =
  `palette.color_for(slot_id)`. Dos estados: apagado / encendido. Si el `.glb` pierde la malla, el
  puesto funciona igual y solo no se ve el encendido.
- `%ProximityArea` (`Area3D`, `collision_layer` 0, máscara `player`): cilindro de **2,0 m** de radio
  centrado en la zona (R12; el nodo está en la misma posición que `%DeliveryZone`, z 3,4 local). El
  radio es geometría de la escena y se mide **al borde de la cápsula** del jugador: basta con que la
  cápsula (radio 0,21 m) solape el cilindro, así que el centro del jugador se enciende hasta
  ≈ 2,21 m. El test de PUL-100 lo fija (1,9 m enciende, 2,6 m no).
- Regla (en `order_stand.gd`, `@export var palette: StandPalette`): encendida si algún cuerpo de
  `%ProximityArea` tiene un `%InteractionComponent` cuyo `holder` lleva una `Box` que cumple la misma
  comprobación que ya usa la zona para entregar sola (`_zone_accepts`: comanda viva y
  `OrderValidator.matches`). Se evalúa en `_physics_process` mientras haya cuerpos en el área (≤ 1
  tick, R12 pide ≤ 0,1 s) y se apaga al vaciarse el área y con `orders_reset`, `order_completed` y
  `order_expired` de su puesto. Expone `is_zone_lit() -> bool` para tests.
- No entrega nada: entregar sigue siendo `%DeliveryZone` (`body_entered`) o interactuar (B12).

#### 9.5 Pasaplatos y barra
- En el nivel hay exactamente **6** `PassSlot` (`slot.tscn`), y fuera de ellos y de la estación
  ningún `Slot` (R11). `slot.tscn` cambia su `Model` (hoy el placeholder `table_square`, oculto por
  overrides del nivel desde el QA D9) por la marca `pass_mark` de `counters` (PUL-095): la marca es
  parte del pasaplatos, no del nivel, y el nivel deja de sobrescribir `Model`/`Body`. La retícula
  de `%Highlightable` no cambia. `Slot.accepted_group` se conserva (API probada, sin usuarios en el
  nivel). Reparto 3 + 3 (PUL-101): `PassSlot01..03` en x −5,3 / −4,3 / −3,3 y `PassSlot04..06` en
  x 4,7 / 5,7 / 6,7, fuera del tramo de la estación (x −2,4…2,8) y del hueco.
- Soltar sin objetivo (enmienda PUL-103, implementada en PUL-101; **sustituye** a «se suelta a los
  pies del portador»): si el punto de soltar (§6: 0,6 m delante y 0,6 m arriba del portador,
  `PlayerConfig`) cae en un cuerpo de la capa `world` (esfera de 0,2 m: la barra, una pared, el
  mostrador de la estación), **no se suelta nada y la mano no cambia** (R11 literal). Contrato:
  - `Holder.can_drop_freely() -> bool` (común; la base devuelve `true`). `HoldComponent` devuelve
    `false` si el punto de soltar está bloqueado por `world`.
  - `InteractionComponent.interact_pressed()`: si el objetivo no consume y la mano está llena,
    llama `holder.drop()` solo si `holder.can_drop_freely()`; en los dos casos **consume** la
    pulsación (devuelve `true`), sin señal ni cue.
  - `Holder.drop()` no cambia ni consulta `can_drop_freely()`: lo siguen usando las transferencias
    (slot, olla, cuenco, puesto), que dejan el objeto en su sitio aunque esté sobre la barra.
  Sin objetivo y con el punto libre, soltar sigue como en §6 (delante del portador, al nodo `Items`).
- Hueco de la barra (PUL-101): **1,4 m libres, de x 2,8 a 4,2 (centro 3,5)**, entre el extremo
  este de la colisión de la estación (x 2,8) y el tramo este de la barra (x 4,2 hasta la pared
  derecha), con el umbral `pass_threshold` (PUL-095). El hueco de x 7,7 (col. 14) queda
  **cerrado**. Cumple R14 (rodeo cara de condimentar ↔ cara de pase 7,93 m, rango 6–10) y el
  rango de centro x ∈ [2,7; 3,7] de `level-layouts.md` (L2). `level_walker.gd::GAP_X` = 3,5.

#### 9.6 Señales
**Ninguna señal nueva ni cambio de firma.** El condimento sigue en `seasoned` / `seasoning_removed`
de la caja y `rejected` / `stock_changed` de dispensador y cuenco (locales, `signals.md` §4); la
entrega y el puesto, en `order_generated` / `order_completed` / `order_expired` / `orders_reset` /
`delivery_rejected` de `EventBus`. El indicador lee la mano del portador (local, por cuerpos del
área, como ya hace `%DeliveryZone`) y las comandas que el puesto ya oye; el ticket obtiene tamaño y
color de datos (`RecipeData.box`, `ActiveOrder.slot_id` + `StandPalette`), sin escuchar al puesto.

**Alternativas descartadas.**
1. *Mantener `Tray` como opcional y que el dispensador mire primero la mano.* Dos caminos para la
   misma acción y vuelve E2 (franja de la bandeja que compite con los dispensadores).
2. *Señal `EventBus.delivery_hint_changed(slot_id, lit)`.* Nadie fuera del puesto la necesita; el
   ticket no se ilumina (E-A solo pide el color). Se promovería con enmienda si el HUD la pide.
3. *Color por puesto como `@export var color` en cada `OrderStand` del nivel.* Duplica el dato en
   el nivel y el ticket no lo vería sin buscar nodos; un `Resource` compartido lo leen los dos.
4. *Marca del pasaplatos como piezas de `kitchen_layout.tscn`.* La marca y el `Slot` podrían
   separarse al mover uno; en `slot.tscn` van juntos.
5. *Soltar a los pies del portador si el punto delante está bloqueado* (texto original de §9.5).
   Deja la caja en el suelo junto a la barra, que R11 prohíbe («no suelta nada»); PUL-101 lo
   sustituyó por `can_drop_freely()` (enmienda PUL-103).
6. *Nodo propio `%DeliveryMark` en `order_stand.tscn`.* Duplicaría la malla que ya trae el `.glb`
   del puesto (PUL-096); se usa `DeliveryFrame` dentro de `Model` (enmienda PUL-103).

## Alternativas consideradas
1. **Nivel monolítico como `Level_01.unity`.** Un solo dueño para casi todo, conflictos de merge en
   un `.tscn` grande y overrides opacos. Descartada.
2. **Herencia de escenas** (`box_small.tscn` hereda de `box.tscn`). Útil para variantes visuales,
   pero aquí solo cambian datos; los `.tres` son más fáciles de equilibrar y de probar. Descartada
   salvo que una variante cambie nodos.
3. **Jerarquía de clases** (`Interactable extends StaticBody3D`, `Pickable extends RigidBody3D`).
   Las raíces de las entidades son de tipos distintos y GDScript no tiene herencia múltiple; además
   ataría el contrato a la dimensión. Descartada.
4. **Contrato con `Player` como tipo de actor.** Más directo, pero ata la capa común a la clase
   específica (`CharacterBody3D`/`2D`) de forma transitiva. Descartada en favor de
   `InteractionComponent` + `Holder`.
5. **Componente nodo `Interactable` que emite `interacted(actor)`.** Desacopla más, pero obliga al
   detector a buscar un hijo por nombre en cada cuerpo y duplica nodos en todas las entidades.
   Se puede adoptar más adelante con enmienda si el grupo + métodos se queda corto.
6. **Duck typing sin grupos** (`has_method("interact")` en tiempo de juego). Sin contrato
   explícito ni filtrado barato. Descartada.
7. **Esperar a D14 para fijar el árbol.** Bloquearía también fases 0–2 y las fichas de UI. Se
   prefiere separar capas y dejar pendiente solo la parte específica.

## Consecuencias
- (+) Varias fichas de la misma fase trabajan en paralelo en escenas distintas; el nivel se monta
  al final (fase 8) con pocos conflictos.
- (+) Cajas y condimentos se equilibran solo con `.tres`.
- (+) La lógica de selección y validación es pura, testeable y válida para 3D y 2D.
- (+) D14 afecta solo a la capa específica: fases 0–2 y la UI de pantalla avanzan ya.
- (−) Las llamadas a `interact()` sobre un `Node` del grupo son dinámicas (sin chequeo de tipos en
  análisis); lo compensa el test de contrato.
- (−) Proyectar a `Vector2` del suelo exige una conversión explícita en las escenas 3D
  (`Vector2(p.x, p.z)`); se encapsula en el detector y en `player.gd`.
- (−) `level.gd` es el único script del nivel; si un nivel necesita lógica propia, va en una escena
  instanciada, no en la raíz.
- (§8, +) La regla de lado es pura y común; el resto del contrato no cambia para las entidades
  existentes (el método nuevo es opcional).
- (§8, −) El detector hace una llamada dinámica más por candidato con el método; son 5 nodos en el
  nivel y solo dentro del radio del detector.
- (§9, +) Cada pieza de la estación tiene un único verbo con la caja en la mano; desaparece la
  pieza que compartía caja entre lados, y con ella `get_box()` y la franja de la bandeja.
- (§9, −) Se pierde la regla de dos lados para la caja (queda para dispensadores y cuenco), y el
  puesto hace una comprobación por tick mientras haya alguien a ≤ 2 m (≤ 2 cuerpos).
- El árbol concreto de M0 está en `docs/arch/scene-tree.md`. Cambiarlo en algo que afecte a otra
  ficha (nombres de escena, `@export` públicos, grupos, capas) requiere enmienda.
