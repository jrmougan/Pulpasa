# ADR-003 — Árbol de escenas y composición

- **Estado:** aceptado (2026-10-03); enmienda §8 (estación de condimentos) **propuesta**, pendiente
  del gate humano (PUL-056); enmienda §9 (estación al paso, D23) **aceptada** por el producer el 2026-10-07 tras la
  revisión del producer (PUL-093); sustituye las partes de §8 que dependían de la bandeja;
  enmienda de §3 (API de `Holder`), §9.4 y §9.5 tras implementar M3c (PUL-103) **aprobada** por el
  responsable en gate humano; enmienda §10 (D25: caja única, aliño de una pulsación, cubo de
  basura y comandas por fase) **propuesta**, pendiente del gate humano (PUL-111); enmienda §11
  (D26: verbo de acción, prompt, histéresis, entrega solo por zona y cuenco que solo pone)
  **propuesta**, pendiente del gate humano (PUL-120)
- **Fecha:** 2026-10-03; enmiendas 2026-10-05, 2026-10-07, 2026-10-09, 2026-10-10 y 2026-10-11
- **Ficha:** PUL-003; enmiendas PUL-056 (D18, D19), PUL-093 (D23) y PUL-103 (lo que cambió al
  implementar M3c en PUL-097…PUL-101), PUL-111 (D25) y PUL-120 (D26)
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
  `@export var data: BoxData` (S/M/L hasta D25; desde D25 una sola `BoxData`, §10.1), una `seasoning_dispenser.tscn` con `SeasoningData` (§8; hasta
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
| `InteractionComponent` | Común | `Node` | `PlayerInteractionController` | `@export var control: ControlComponent`, `@export var holder: Holder`, `@export var detector: Node` (conecta `target_changed` por nombre). Al pulsar `p<n>_interact` llama `interact(self)` del objetivo; si nada acepta y lleva algo, `holder.drop()` solo si `holder.can_drop_freely()`; si no, consume la pulsación sin soltar (PUL-101, §9.5). *D26 (§11.4):* resuelve el `ActionHint` antes de `interact`, emite `interaction_resolved` (local y de bus), repite el corte manteniendo y publica `action_hint_changed` en `EventBus` |
| `HoldComponent` | Específica | `Holder` + `Marker3D`/`Marker2D` `%HoldPoint` | `PlayerHoldSystem` | Implementa `Holder`: reparenta y coloca el objeto. Único camino: llama `on_picked_up`/`on_dropped` del objeto (B4); valida antes de mutar (B5). `can_drop_freely()` es `false` si el punto de soltar cae en la capa `world` (§9.5) |
| `InteractionDetector` | Específica | `Area3D` / `Area2D` | `InteractionDetector` | Un solo detector por jugador (B7); radio en `PlayerConfig.tres`. Delega la puntuación en `InteractionScoring` (común, `Vector2` del suelo). *D26 (§11.3):* `@export var actor: InteractionComponent`; descarta candidatos con `ActionHint` `NONE`, aplica histéresis y emite `hint_changed`; sin control no publica objetivo |
| `ActionPrompt` | Específica | `Node3D` (2D: `Node2D`) | — (nuevo, D26) | Icono del verbo sobre el objetivo activo del personaje controlado (§11.5). `components/action_prompt.gd`, escena `entities/player/action_prompt.tscn` |
| `Highlightable` | Específica | `Node` | `HighlightController`, `OutlineHighlighter`, `InteractableHighlight` | 3D: `material_overlay` con shader de contorno; 2D: shader `canvas_item` de contorno. Retícula opcional. Sin `EmissionHighlighter` (B3) |

### 4. Contrato de interacción (sustituye a `IInteractable`/`IPickable`) — común
Godot no tiene interfaces; se usa **grupo + métodos con firma fija**, verificado por test:

| Grupo | Métodos obligatorios en el script raíz | Lo implementan |
|---|---|---|
| `interactable` | `can_interact(actor: InteractionComponent) -> bool`; `interact(actor: InteractionComponent) -> bool` (devuelve si consumió la pulsación). **Opcional** (§8): `is_reachable_from(floor_position: Vector2, holder: Holder) -> bool`. *D26 (§11.2):* `get_action_hint(actor: InteractionComponent) -> ActionHint`, **obligatorio** en `entities/` (el test de contrato lo exige desde la oleada de montaje); `can_interact` = `get_action_hint(actor).is_target()` | estaciones, slots, caja, pulpo y cachelos; dispensadores y cuenco de la estación de condimentos (§8); cubo de basura (§10.3, *Enmienda D25 (PUL-111, 2026-10-10)*). Condimento (bote): baja en PUL-061. *D26 (§11.7):* el puesto de entrega **sale** del grupo |
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

> **Enmienda D25 (PUL-111, 2026-10-10):** los 4 dispensadores que alternan pasan a 2 dispensadores
> de aliño que **aplican** (§10.2): `toggle_seasoning(…, swap_exclusive)` y `paprika_swap` dejan de
> ser la API del dispensador y el antirrebote (`toggle_guard`) queda solo para el cuenco. La regla de
> lado (§8.1), consumir al rechazar (§8.2) y el cuenco siguen vigentes.

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
pulsación y `holder.can_drop_freely()` (§9.5). En la estación un rechazo **no debe tirar nada** (AC8: «la mano no cambia»). Regla:
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

> **Enmienda D25 (PUL-111, 2026-10-10):** las filas de `BoxData` (`short_label`, `icon`, 4 / 6 / 10)
> y `paprika_swap` quedan sustituidas por §10.1 y §10.2: una sola caja de 6 pulsaciones, sin talla
> en ticket ni rack. `StandPalette` y las filas del cuenco siguen vigentes.
| Recurso | Campo | Tipo | Valor / uso |
|---|---|---|---|
| `BoxData` (`resources/box_data.gd`, común) | `short_label` | `String` | «S», «M», «L» en `data/boxes/{small,medium,large}.tres` |
| `BoxData` | `icon` | `Texture2D` | silueta + letra de `assets/textures/ui/box_sizes/` (PUL-095); la usan el ticket (vía `RecipeData.box`) y, si quiere, el rack. Mismo recurso en los dos (R10) |
| `BoxData` | `presses_to_fill` | `int` (`@export_range(1, 20)`; enmienda PUL-106, sustituye a `fill_per_press: float`, eliminado en PUL-104) | 4 / 6 / 10 pulsaciones (R9) |
| `BoxData` | `fill_after(presses: int) -> float` | método (PUL-104) | llenado tras `presses` cortes, `clampf(presses / presses_to_fill, 0, 1)`: exacto (1,0) en el último corte. `Box` cuenta los cortes enteros y gasta del pulpo la diferencia de llenado × `amount_per_full_box` |
| `StandPalette` (`resources/stand_palette.gd`, común, nuevo) | `colors` | `Array[Color]` | índice `slot_id − 1`; 4 entradas: rojo, azul, amarillo, verde (hex de los toldos, PUL-096) |
| `StandPalette` | `fallback` | `Color` | para un `slot_id` fuera de rango (no se espera en el nivel) |
| `StandPalette` | `color_for(slot_id: int) -> Color` | método | única forma de leerla; la usan `order_ticket.gd` (franja, R13) y `order_stand.gd` (zona encendida). Instancia: `data/config/stand_palette.tres` |
| `SeasoningStationData` (ya existe) | `cachelos_portions_per_item` / `cachelos_stock_max` | `int` | 1 → **2** / 3 → **4** (R6, D23); `operator_side_only` `true`, `toggle_guard` 0,25, `paprika_swap` `true` sin cambios |

`StandPalette` y `BoxData` solo usan `Color`, `String`, `int`, `float`, `Texture2D` y `PackedScene`: capa común (§0), válidos en
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
  *Enmienda D26 (PUL-120):* interactuar ya no entrega; solo la zona (§11.7).

#### 9.5 Pasaplatos y barra
- En el nivel hay exactamente **6** `PassSlot` (`slot.tscn`), y fuera de ellos y de la estación
  ningún `Slot` (R11). `slot.tscn` cambia su `Model` (hoy el placeholder `table_square`, oculto por
  overrides del nivel desde el QA D9) por la marca `pass_mark` de `counters` (PUL-095): la marca es
  parte del pasaplatos, no del nivel, y el nivel deja de sobrescribir `Model`/`Body`. La retícula
  de `%Highlightable` no cambia. `Slot.accepted_group` se conserva (API probada, sin usuarios en el
  nivel). Reparto 3 + 3 (PUL-101): `PassSlot01..03` en x −5,3 / −4,3 / −3,3 y `PassSlot04..06` en
  x 4,7 / 5,7 / 6,7, fuera del tramo de la estación (x −2,4…2,8) y del hueco.
- Soltar sin objetivo (enmienda PUL-103, implementada en PUL-101; **sustituye** a «se suelta a los
  pies del portador»): si el punto de soltar (delante y arriba del portador según
  `PlayerConfig.drop_forward_offset` / `drop_up_offset`, 0,6 / 0,6 m en
  `data/config/player_config.tres`; el destino `Items` es el de §6) cae en un cuerpo de la capa `world` (esfera de 0,2 m: la barra, una pared, el
  mostrador de la estación), **no se suelta nada y la mano no cambia** (R11 literal). Contrato:
  - `Holder.can_drop_freely() -> bool` (común; la base devuelve `true`). `HoldComponent` devuelve
    `false` si el punto de soltar está bloqueado por `world`.
  - `InteractionComponent.interact_pressed()`: si el objetivo no consume y la mano está llena,
    llama `holder.drop()` solo si `holder.can_drop_freely()`; en los dos casos **consume** la
    pulsación (devuelve `true`), sin señal ni cue. *Enmienda D26 (PUL-120):* sin objetivo, la
    pulsación tiene hint de suelo (`drop` OK o BLOQUEADO `busy`) y siempre responde (§11.3–§11.4).
  - `Holder.drop()` no cambia ni consulta `can_drop_freely()`: lo siguen usando las transferencias
    (slot, olla, cuenco, puesto), que dejan el objeto en su sitio aunque esté sobre la barra.
  Sin objetivo y con el punto libre, soltar sigue como en §6 (delante del portador, al nodo `Items`).
- Hueco de la barra (PUL-101): **1,4 m libres, de x 2,8 a 4,2 (centro 3,5)**, entre el extremo
  este de la colisión de la estación (x 2,8) y el tramo este de la barra (x 4,2 hasta la pared
  derecha), con el umbral `pass_threshold` (PUL-095). El hueco de x 7,7 (col. 14) queda
  **cerrado**. Cumple R14 (rodeo cara de condimentar ↔ cara de pase 7,93 m, rango 6–10) y el
  rango de centro x ∈ [2,7; 3,7] de `level-layouts.md` (L2). `level_walker.gd::GAP_X` = 3,5.

#### 9.6 Señales
*Enmienda D25 (PUL-111, 2026-10-10): el ticket ya no lee `RecipeData.box` (§10.1).*
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

### 10. Caja única, aliño de una pulsación, cubo de basura y comandas por fase (D25) — *Enmienda D25 (PUL-111, 2026-10-10), propuesta, pendiente del gate humano*

**Contexto.** D25 (responsable, 2026-10-10, tras el playtest de M3c; registro en
`docs/design/decisions.md`, PUL-110) quita las mecánicas que no piden decisión: tamaños S/M/L, los
4 dispensadores que alternan y el toggle de quitar. Añade un cubo de basura y escala qué comandas
salen por fase. Modifica D23 (corte 4/6/10, talla en ticket y rack, «se pulsa cada dispensador»),
D18 (dispensadores que alternan, `paprika_swap`) y concreta D8 (la caja errónea es solo de
contenido). Esta sección **sustituye** las partes de §8 y §9 citadas en sus notas; el resto de §8–§9
(regla de lado, consumir al rechazar, caja en la mano, pasaplatos, hueco, entrega iluminada) sigue.
Tecla única, InputMap y capas de física sin cambios.

#### 10.1 Caja única
| Pieza | Fichero | Contrato D25 |
|---|---|---|
| `BoxData` | `resources/box_data.gd` | Se quedan `display_name`, `capacity`, `presses_to_fill` (`@export_range(1, 20)`), `scene`, `description` y `fill_after(presses)`. **Se quitan** `short_label` e `icon` (nadie muestra talla) |
| Instancia única | `data/boxes/box.tres` (nuevo) | `presses_to_fill` = **6** (provisional, se re-mide en QA). Se dan de baja `small.tres`, `medium.tres` y `large.tres`; las texturas de `assets/textures/ui/box_sizes/` se quedan sin usuario (baja del asset-pipeline). `box.tscn` lleva `data = box.tres` por defecto |
| `RecipeData` | `resources/recipe_data.gd` | **Se quita `box`**: una receta es `display_name` (≤ 14 caracteres), `translation_key`, `ingredient` (pulpo), `base_points` (precio, D2) y `description`. Las recetas se distinguen por el contenido de la `OrderData` que las usa (§10.4) |
| `OrderValidator.matches` | `core/order_validator.gd` | **Deja de comparar la caja**: mismo ingrediente, cocido e igualdad exacta del conjunto de condimentos (D4). La caja errónea de D8 es solo de contenido (aliño o cachelos). El llenado no se compara: un aliño exige caja llena (§10.2) y toda comanda lleva aliño, así que una caja sin llenar nunca coincide |
| `BoxContents` | `core/box_contents.gd` | Sin cambio de firma: `box` se conserva como dato informativo (lo rellena `Box.get_contents()`) y **no se valida**. Quitarlo obligaría a reescribir todas las llamadas posicionales al constructor por un campo inofensivo |
| Rack | `entities/stations/box_shelf.tscn` | Un solo spawner `BoxSpawner` (`item_spawner.gd`, `scene = box.tscn`, `data = box.tres`) en lugar de `SmallSpawner`/`MediumSpawner`/`LargeSpawner`, en `(0, 0,31, −0,78)` local (el sitio de `MediumSpawner`; (−5,52; 2,5) en `level_01`); su colisión cubre el frente del mueble y `%Highlightable.root` es `Model/box_shelf/OutlineHull` (`Highlightable` recorre los descendientes: resalta el mueble entero). El `.glb` puede seguir mostrando tres huecos hasta que el arte lo cambie: es visual |
| Ticket | `ui/tickets/ticket_entry.gd` / `.tscn` | **Se quitan** `_show_size()` y los nodos `%SizeBadge`, `%SizeIcon` y `%SizeLabel`. El ticket muestra nombre de receta + 1 pegatina de aliño + la de cachelos si la lleva, en `SeasoningRules.canonical_order()` |

`level_01.tscn` no cambia por la caja: `BoxShelf` sigue siendo una instancia con su transformación.

#### 10.2 Aliño de una pulsación
**Datos.** Los condimentos de la caja pasan a ser **tres** `SeasoningData`:

| `.tres` | `type` | `exclusivity_group` | `sort_order` | Nota |
|---|---|---|---|---|
| `data/seasonings/sweet_dressing.tres` (nuevo) | `SWEET_DRESSING` | `&"dressing"` | 0 | aliño dulce: sal gorda + aceite + pimentón dulce. Pegatina sin llama |
| `data/seasonings/hot_dressing.tres` (nuevo) | `HOT_DRESSING` | `&"dressing"` | 0 | aliño picante: sal gorda + aceite + pimentón picante. Pegatina con `BoxBadgeStyle.hot_mark` |
| `data/seasonings/cachelos.tres` (sin cambios) | `CACHELOS` | `&""` | 3 | lo sigue sirviendo el cuenco (D10, D23) |

- `SeasoningData.SeasoningType` gana `SWEET_DRESSING` y `HOT_DRESSING` **al final del enum** (valores
  5 y 6): `cachelos.tres` guarda `type = 4` como entero y no se renumera. `SALT`, `PAPRIKA`,
  `HOT_PAPRIKA` y `OIL` quedan en desuso (sin `.tres`), como `NO_BOX` en `Rejection`.
- Bajas: `salt.tres`, `oil.tres`, `paprika.tres`, `hot_paprika.tres`.
- `BoxBadgeStyle.has_hot_mark(seasoning)` pasa a mirar `HOT_DRESSING`.
- `same_as()` no cambia (compara `type`): dulce y picante son distintos y exclusivos por grupo.

**Regla en el núcleo** (`core/seasoning_rules.gd`, común, puro). Nueva función:

```gdscript
## D25: aplica `seasoning` a una caja. Sin llenar: BOX_NOT_FULL. Si ya lo lleva: ALREADY_APPLIED
## (sin cambios). Si lleva otro de su `exclusivity_group`, lo sustituye (removed = el viejo).
## Si no, lo añade al final. No muta: devuelve copias en un `Toggle`.
static func apply(current: Array[SeasoningData], seasoning: SeasoningData, is_full: bool) -> Toggle
```
- Orden de comprobación: `seasoning` nulo → `NOT_ACCEPTED`; `is_full` falso → `BOX_NOT_FULL`;
  `find(current, seasoning)` → `ALREADY_APPLIED`; `find_in_group(current, group)` → sustituye; si no,
  añade. Generaliza `paprika_swap` = `true` a cualquier grupo de exclusividad; deja de existir la
  opción de rechazar con `EXCLUSIVE_TAKEN`.
- `Rejection` gana **`ALREADY_APPLIED` al final** (valor 8, sin renumerar). `EXCLUSIVE_TAKEN` pasa a
  desuso (como `NO_BOX`, `HAND_BUSY` y `NOT_ACCEPTED`).
- `toggle()` pierde el parámetro `swap_exclusive`: `toggle(current, seasoning, is_full) -> Toggle`.
  Solo la usa el cuenco (cachelos, sin grupo); si algún día se alterna algo con grupo, sustituye
  siempre. `canonical_order`, `find`, `find_in_group`, `remove`, `can_restock` y `restocked` sin
  cambios.

**API de la caja** (`entities/items/box.gd`):
- Nuevo `apply_seasoning(seasoning: SeasoningData) -> SeasoningRules.Rejection` sobre
  `SeasoningRules.apply`: con `NONE` emite `seasoning_removed(viejo)` (solo al sustituir) **antes** que
  `seasoned(nuevo)`, una vez cada una y en la misma llamada (el orden de AC4 de `paprika_swap`).
  Con otro valor no cambia nada ni emite.
- `toggle_seasoning(seasoning: SeasoningData) -> SeasoningRules.Rejection` pierde `swap_exclusive`
  (la llama solo el cuenco). `remove_seasoning`, `has_seasoning`, `is_full` y `get_contents` sin
  cambios.

**Dispensador** (`entities/stations/seasoning_dispenser.gd`, `SeasoningDispenser`):
- Hay **2** en la estación: `SweetDressing` (`seasoning = sweet_dressing.tres`) y `HotDressing`
  (`seasoning = hot_dressing.tres`). Misma escena `seasoning_dispenser.tscn` (§1).
- Quién es objetivo: **igual que §9.1** (caja en la mano, llena o a medio cortar, desde el lado de
  condimentar; mano vacía u otra cosa: no es objetivo).
- `interact(actor)`: siempre consume; caja de la mano = `actor.holder.get_held_item() as Box`;
  `box.apply_seasoning(seasoning)` → `NONE`: lanza el gesto visual del dispensador (abajo);
  `BOX_NOT_FULL`: `rejected(BOX_NOT_FULL)` (suena `season_error`); `ALREADY_APPLIED`: **se consume en
  silencio** (ni `rejected` ni cue: «pulsar el mismo no hace nada», D25). No hay toggle de quitar: lo
  que está mal se tira al cubo (§10.3). *Enmienda D26 (PUL-120):* `ALREADY_APPLIED` deja de ser
  silencioso: es `BLOCKED` con motivo y suena `rejected` en el jugador (§11.7).
- **Sin antirrebote**: aplicar es idempotente (la segunda pulsación del mismo da `ALREADY_APPLIED`), así
  que el dispensador pierde `clock`, `_game_time` y `_last_change`.
- Gesto visual (D25: sal gorda, pimentón y aceite): nodo `%Gesture` dentro de
  `seasoning_dispenser.tscn` (`GPUParticles3D` `one_shot` o `AnimationPlayer`, lo decide el arte), que
  el propio dispensador lanza al aplicar con `NONE`; ≥ 0,3 s. Es visual interno de la escena: sin
  señal. El sonido sigue siendo la cue `season` de la caja (`seasoned`).
- Disposición: dispensadores y cuenco en bloque centrado del mostrador, ≥ 1,0 m entre centros, en el
  orden del ticket (dulce, picante, cuenco): raíces en x −1 / 0 / 1 local, z −0,1 (ajustable ±0,5 m
  por la ficha de la estación si el test de franjas de selección, R8, lo pide). El mostrador
  (colisión de 5,2 m, x −2,4…2,8) y el hueco no cambian.

**`SeasoningStationData`** (`resources/seasoning_station_data.gd`, `data/config/seasoning_station.tres`):
se mantiene. **Se quita `paprika_swap`.** `toggle_guard` (0,25) queda **solo para el cuenco** (que
sigue alternando cachelos). `operator_side_only`, `cachelos_stock_max` (4),
`cachelos_initial_stock` (0) y `cachelos_portions_per_item` (2) sin cambios.

**Motivos de rechazo que quedan** (`rejected`, señal local): dispensador → `BOX_NOT_FULL`;
cuenco → `BOWL_EMPTY`, `BOWL_FULL`. `ALREADY_APPLIED` existe en el enum pero no se emite en `rejected`.

**Cuenco** (`cachelos_bowl.gd`): sin cambio de comportamiento (§9.1); llama
`box.toggle_seasoning(seasoning)` sin el segundo argumento.
*Enmienda D26 (PUL-120):* el cuenco solo pone, con `box.apply_seasoning(seasoning)`; se van el
toggle y su antirrebote (§11.7).

#### 10.3 Cubo de basura
| Pieza | Capa | Contrato |
|---|---|---|
| `core/trash_rules.gd` (`class_name TrashRules extends RefCounted`) | Común | `static func can_trash(item: Node) -> bool`: `true` si `item` no es nulo, `is_instance_valid(item)`, no está `is_queued_for_deletion()` y está en el grupo `pickable` (caja vacía, a medias o llena con lo que lleve; pulpo crudo o cocido; cachelos). Usa solo `Node` + grupo (§0) |
| `resources/trash_bin_data.gd` (`class_name TrashBinData extends Resource`) | Común | `@export var trash_penalty: int = 0` (euros que restaría cada tirada) |
| `data/config/trash_bin.tres` | Datos | `TrashBinData` con `trash_penalty = 0` (D25). Un test de datos fija que vale 0 mientras no haya enmienda (abajo) |
| `entities/stations/trash_bin.tscn` + `trash_bin.gd` (`class_name TrashBin extends StaticBody3D`) | Específica | Raíz `StaticBody3D` en la capa `interactable` (como `Kitchen`), grupo `interactable` (§4). `@export var data: TrashBinData` (por defecto `trash_bin.tres`, `preload` como `SeasoningStation.DEFAULT_DATA`) |

Contrato `interactable` del cubo:
- `is_reachable_from(floor_position: Vector2, holder: Holder) -> bool`: `holder != null and
  TrashRules.can_trash(holder.get_held_item())`. **Sin regla de lado.** Con la mano vacía no es
  objetivo (no se resalta, T3).
- `can_interact(actor: InteractionComponent) -> bool`: la misma condición con `actor.holder`
  (defensa en profundidad, §9.1).
- `interact(actor) -> bool`: si no `can_interact`, `false`. Si no: `var item: Node =
  actor.holder.drop()` (único camino para vaciar la mano: llama `on_dropped` y emite `item_dropped`,
  §3) → `trashed.emit(item)` → `item.queue_free()` → `true`. La mano queda vacía en el mismo frame
  y el objeto se libera al final del frame (T1, T2). No suma ni resta recaudación.
- `signal trashed(item: Node)` (**local**, `signals.md` §4): una vez por tirada, después de vaciar
  la mano y antes de `queue_free`. Receptor: `%Feedback` del propio cubo (cue `trash`, ADR-006 §4).
- El pulpo quemado se sigue desechando en la olla (ADR-006 §5): nunca llega a la mano, así que el
  cubo no lo ve.
- `trash_penalty`: el cubo **no** lo aplica mientras valga 0 y no hay señal de `EventBus` ni método
  de autoload para restar. `TrashBin._ready()` hace `push_warning` si `data.trash_penalty != 0`. Para
  usar un valor > 0 hace falta otra enmienda (señal o método de `RoundManager` que reste y reenvíe
  `score_changed`).

Escena:
```
trash_bin.tscn
TrashBin (StaticBody3D, capa interactable; grupo interactable)   trash_bin.gd  class_name TrashBin
│   @export data: TrashBinData = data/config/trash_bin.tres
│   signal trashed(item: Node)
├── CollisionShape3D (cilindro ≈ r 0,3 m, h 0,8 m)
├── Model                  placeholder de primitivas → arte (cubo de feria)
├── %Highlightable
└── %Feedback (FeedbackPlayer)   cue trash, POP del cubo (pulse_target = la raíz)
```
Nivel: dos instancias, `TrashBinKitchen` y `TrashBinService`, en `Stations` de `level_01.tscn`
(posiciones en `scene-tree.md` §2: x 2,6 / z −3,1 y x −5,4 / z 4,3). Override permitido: solo la
transformación (§2). *Enmienda D26 (PUL-120):* con el contrato honesto (§11.2) los spawners ya no son
objetivo con la mano llena y el puesto deja de ser objetivo; la regla se **conserva tal cual** (más
estricta de lo necesario, inocua). **Regla de colocación** (contrato, la exige `test_level_01.gd`): cada cubo a
≥ 1,5 m de todo lo que es objetivo con la mano llena (spawners —`ItemSpawner.can_interact` es `true`
con la mano llena—, ollas, pasaplatos, dispensadores, cuenco y puestos) y del hueco, para que no
compitan como objetivo y no se tire nada por error.

#### 10.4 Comandas por fase
El dato vive en la ronda (`RoundConfig.phases`), junto a puestos y paciencia. Contrato completo en
ADR-006 §6 (*Enmienda D25*): `PhaseData.orders: Array[OrderData]` (vacío = todo el catálogo) y
`OrderBoard.set_order_pool(orders)`, que `RoundState` aplica al entrar en cada fase. Recetas y
comandas de D25:

| Receta (`display_name`) | `base_points` | `seasonings` de la comanda | `max_time` | Fase en que entra | Ficheros |
|---|---|---|---|---|---|
| Á feira | 8 | `[sweet_dressing]` | 60 | 1 | `data/recipes/a_feira.tres`, `data/orders/a_feira.tres` |
| Picante | 9 | `[hot_dressing]` | 60 | 2 | `data/recipes/picante.tres`, `data/orders/picante.tres` |
| Con cachelos | 12 | `[sweet_dressing, cachelos]` | 80 | 3 | `data/recipes/con_cachelos.tres`, `data/orders/con_cachelos.tres` |
| Bravo cachelos | 13 | `[hot_dressing, cachelos]` | 80 | 3 | `data/recipes/bravo_cachelos.tres`, `data/orders/bravo_cachelos.tres` |

Nombres, precios (€) y `max_time` (s) son los de `docs/design/features/comandas.md` (PUL-110); si el
diseño los cambia, manda `comandas.md` y solo cambian los `.tres`. Una `RecipeData` por comanda
(1:1): nombre, `translation_key` y precio en la receta; contenido y paciencia en la `OrderData`.
`ingredient` = `data/ingredients/octopus.tres` en las cuatro.

**Datos que se van o se rehacen** (lo más simple: bajas y un único catálogo):
- `data/orders/order_catalog.tres` se **rehace** con las 4 comandas de arriba (mismo fichero y `uid`).
- **Bajas**: `data/recipes/{individual,combo_duo,familiar}.tres`, `data/orders/order_1..6.tres` y
  `data/orders/order_catalog_basic.tres`. Sus usuarios pasan a `order_catalog.tres`:
  `scenes/sandbox/kitchen_sandbox.tscn` (su `order_catalog`) y
  `tests/unit/test_data_integrity.gd` (rutas esperadas; las recetas por id pasan a
  `a_feira`/`picante`/`con_cachelos`/`bravo_cachelos`), y los tests que cargan `order_N.tres`
  (`test_data_catalog.gd`, `test_order_board.gd`, `test_order_validator.gd`, `test_m1_flow.gd`,
  `test_m2b_flow.gd`, `test_m2b_station_selection.gd`, `test_station_level.gd`,
  `test_level_01_r16.gd`) usan las comandas nuevas.
- `tests/helpers/m0_data/` (copias de paridad M0) apunta a `small/medium/large.tres` y a los
  condimentos de baja: se rehace sin `box` y con los aliños nuevos, o se da de baja si ya no lo usa
  ningún test; lo decide la ficha que tenga esos tests.
- Catálogo de fase 1 para el tutorial o el sandbox: no hace falta fichero; se expresa con
  `PhaseData.orders` (ADR-006 §6).

#### 10.5 Señales
**Ninguna señal nueva en `EventBus` ni cambio de firma.** Una señal local nueva, `TrashBin.trashed`.
Los dispensadores siguen con `rejected` (solo `BOX_NOT_FULL`); la caja con `seasoned` /
`seasoning_removed` (al sustituir aliño, en ese orden). Detalle en `signals.md`.

**Alternativas descartadas.**
1. *`RecipeData.box` apuntando a la única caja.* Campo que nadie necesita y una comparación de caja en
   `OrderValidator` que siempre se cumple; si vuelven los tamaños, se repone con enmienda.
2. *Reutilizar `PAPRIKA` / `HOT_PAPRIKA` como tipo de los aliños.* Menos cambio, pero el nombre del
   tipo mentiría (el aliño lleva sal y aceite) y mezcla datos dados de baja con los nuevos.
3. *`ALREADY_APPLIED` como rechazo con `season_error`.* D25 dice «no hace nada»; un error sonoro por
   repetir una acción correcta castigaría la doble pulsación. Si el playtest pide feedback, basta con
   emitirlo en `rejected` (señal local, sin enmienda del bus).
4. *Cubo sin `drop()`, con un método nuevo `Holder.release()` que vacíe la mano sin reparentar.*
   Evitaría la cue `drop` junto a `trash`, pero cambia la API común de `Holder` (§3) por un efecto que
   ya se acepta en las estaciones (ADR-006 §4: suenan las dos).
5. *Penalización del cubo con `EventBus.item_trashed(penalty)`.* Con `trash_penalty` = 0 no tiene
   receptor; se añade con enmienda si el diseño sube el valor.
6. *Comandas por fase como `OrderData.min_phase: int`.* Un campo por comanda y acumulativo por
   construcción, pero ata cada comanda a la estructura de fases de una ronda concreta; el pool en
   `PhaseData` deja que otra ronda (tutorial, otro nivel) reparta las mismas comandas de otra forma.

### 11. Lenguaje de acciones, prompt, histéresis, entrega por zona y cuenco que solo pone (D26) — *Enmienda D26 (PUL-120, 2026-10-11), propuesta, pendiente del gate humano*

**Contexto.** D26 (producer con autorización del responsable, 2026-10-11; `docs/design/decisions.md`;
estudio en `docs/evidence/PUL-119/README.md`). El contorno solo dice «esto es objetivo», no «esto va
a pasar»; hay pulsaciones mudas porque `can_interact` miente a propósito (caja, olla, slot y spawner
devuelven `true` y luego `interact` no hace nada); el objetivo salta entre candidatos cercanos; el
puesto compite como objetivo con la caja en la mano. Esta sección fija: el verbo de cada pulsación y
su estado **antes** de pulsar (§11.1–§11.2), cómo lo calcula y publica el detector con histéresis,
también sin objetivo (§11.3), la respuesta única a cada pulsación y el corte al mantener (§11.4), el
icono sobre el objetivo (§11.5), la tabla de ramas (§11.6), la entrega solo por zona y el cuenco que
solo pone (§11.7) y el estado legible en el mundo (§11.8). El táctil está en ADR-004 §6, la escala y
la cámara móvil en ADR-005 (Enmienda D26) y los cues en ADR-006 §4.1.

**Especificación de diseño.** `docs/design/features/lenguaje-acciones.md` (PUL-119): vocabulario,
tabla mano × objetivo (A–F), medidas y AC. La tabla de §11.6 es su **transcripción** a los nombres del
contrato; si en el futuro difieren, manda la del diseño y solo cambian las ramas de `ActionRules` y su
fixture (los tipos, firmas y señales de esta sección no). Un verbo o un motivo nuevo exige enmienda
(constante + icono + test). Equivalencia de nombres diseño → contrato en la ficha PUL-120 («Nombres
del diseño y del contrato»).

#### 11.1 Tipos comunes (`core/`)

| Pieza | Fichero | Contrato |
|---|---|---|
| `ActionVerb` | `core/action_verb.gd` (`class_name ActionVerb extends RefCounted`) | Constantes `StringName`, conjunto **cerrado**: `NONE = &""`; `PICK_UP = &"pick_up"` (COGER); `DROP = &"drop"` (SOLTAR: en pasaplatos o al suelo); `COOK = &"cook"` (COCER); `CUT = &"cut"` (CORTAR); `SEASON_SWEET = &"season_sweet"` (ALIÑAR DULCE); `SEASON_HOT = &"season_hot"` (ALIÑAR PICANTE); `CACHELOS = &"cachelos"` (CACHELOS: reponer el cuenco o poner en la caja); `TRASH = &"trash"` (TIRAR, incluye desechar el quemado). `const ALL: Array[StringName]` (los 8, sin `NONE`, en este orden); `const REPEATABLE: Array[StringName] = [CUT]` (§11.4); `static func is_valid(verb: StringName) -> bool` |
| `ActionReason` | `core/action_reason.gd` (`class_name ActionReason extends RefCounted`) | Constantes `StringName`, conjunto **cerrado** de 6: `NONE = &""`; `BOX_NOT_FULL = &"box_not_full"` (caja a medias); `BUSY = &"busy"` (ocupado: olla sin plaza, soltar donde no cabe); `EMPTY = &"empty"` (vacío); `FULL = &"full"` (lleno); `ALREADY_APPLIED = &"already_applied"` (ya aplicado / ya lleva); `NOT_COOKED = &"not_cooked"` (sin cocer: cortar con pulpo crudo). `const ALL: Array[StringName]` (los 6, sin `NONE`); `static func is_valid(reason: StringName) -> bool` |
| `ActionHint` | `core/action_hint.gd` (`class_name ActionHint extends RefCounted`) | `enum State { NONE = 0, OK = 1, BLOCKED = 2 }` (valores fijos: viajan como `int` por el bus). `var verb: StringName`, `var state: State`, `var reason: StringName`, `var replaces: bool = false` (ALIÑAR que sustituye al otro aliño: insignia del prompt), `var progress: float = -1.0` (0–1 o −1 = sin progreso). Constructores `static func none() -> ActionHint`, `static func ok(verb: StringName, progress: float = -1.0) -> ActionHint`, `static func blocked(verb: StringName, reason: StringName) -> ActionHint`. `func is_target() -> bool` (`state != NONE`); `func same_as(other: ActionHint) -> bool` (compara `verb`, `state`, `reason` y `replaces`; **ignora `progress`**). Invariantes (test): `NONE` ⇒ `verb == &""` y `reason == &""`; `OK` ⇒ `ActionVerb.is_valid(verb)` y `reason == &""` (única excepción: verbo vacío heredado, §11.3); `BLOCKED` ⇒ verbo válido y `ActionReason.is_valid(reason)` |
| `ActionRules` | `core/action_rules.gd` (`class_name ActionRules extends RefCounted`) | Reglas puras mano × receptor (§11.6), **única fuente de ramas** de `get_action_hint` e `interact`. `enum Held { NOTHING, OCTOPUS_RAW, OCTOPUS_COOKED, CACHELOS_RAW, CACHELOS_COOKED, BOX_EMPTY, BOX_PARTIAL, BOX_FULL, OTHER }` (M0…M7 del diseño; M8/M9 = `BOX_FULL` + qué aliño lleva, que se pasa aparte; `OTHER` = cualquier otra cosa). Funciones `static`, solo con primitivos, `StringName` y `Held`, todas `-> ActionHint`: `for_loose_item(held: Held, can_hold: bool)` (A4: pulpo o cachelos sueltos o en un pasaplatos); `for_box(held: Held, box_full: bool, fill: float)` (B: caja suelta o en pasaplatos); `for_pot(held: Held, free_places: int, has_burnt: bool, has_ready: bool)` (C); `for_pass_slot(held: Held, accepts: bool)` (A5, pasaplatos **vacío**); `for_spawner(held: Held)` (A1–A3); `for_dispenser(held: Held, verb: StringName, box_has_it: bool, box_has_other: bool)` (D; `replaces` = `box_has_other`); `for_bowl(held: Held, stock: int, stock_max: int, portions_per_item: int, box_has_cachelos: bool)` (E); `for_trash(held: Held, can_trash: bool)` (A6); `for_floor(held: Held, can_drop: bool)` (A8–A9: sin objetivo) |
| `HoldRepeat` | `core/hold_repeat.gd` (`class_name HoldRepeat extends RefCounted`) | Temporizador puro del corte al mantener (§11.4): `_init(interval: float)`, `arm()`, `disarm()`, `is_armed() -> bool`, `advance(delta: float) -> bool` (`true` como mucho una vez por llamada, al cumplirse `interval` desde `arm()` o desde el último `true`; el sobrante se conserva). Sin `Input` ni árbol |

`HeldKind` (`entities/items/held_kind.gd`, `class_name HeldKind extends RefCounted`, **capa
específica**: conoce `Box` e `Ingredient`): `static func of(item: Node) -> ActionRules.Held`. Es el único
sitio que traduce el objeto de la mano a `Held`; lo usan todos los receptores y el detector.

**Prioridad de motivos** (diseño): un único motivo por hint; primero el estado del **objetivo**
(`busy` > `full` > `empty`), luego lo que se **lleva** (`already_applied` > `box_not_full` >
`not_cooked`). **Excepción de la tabla**: en el cuenco con stock 0 y una caja llena que **ya lleva**
cachelos el motivo es `already_applied`, no `empty` (fila E1 del diseño; el contrato sigue la tabla).

#### 11.2 Contrato `interactable` desde D26

- **`get_action_hint(actor: InteractionComponent) -> ActionHint`**: obligatorio en todo nodo del grupo
  `interactable` de `entities/` (`InteractionContract.INTERACTABLE_METHODS` lo incluye en la oleada de
  montaje; hasta entonces es opcional y el detector tolera su ausencia, §11.3). Consulta pura, sin
  efectos ni señales. Devuelve `none()` si la pulsación no haría nada (la entidad **no se resalta ni
  es objetivo**), `ok(verbo)` si cambia el juego y `blocked(verbo, motivo)` si no lo cambia pero el
  motivo es útil (D26.2).
- **Una sola resolución.** Cada receptor implementa `_resolve(holder: Holder) -> ActionHint`, que lee su
  estado, clasifica la mano con `HeldKind.of(holder.get_held_item())` y delega en `ActionRules.for_*`.
  `get_action_hint(actor)` = `_resolve(actor.holder)` (o `none()` sin `actor`/`holder`).
  `interact(actor)` llama **una vez** a `_resolve` al empezar y ejecuta solo la rama de ese resultado:
  - `NONE` → `false` sin efectos (el `InteractionComponent` ya no debería llamarlo).
  - `BLOCKED` → `true` sin cambiar estado. Dispensador y cuenco siguen emitiendo su
    `rejected(reason: SeasoningRules.Rejection)` local (tests y compatibilidad); **ninguna estación
    reproduce un cue de error** (lo hace el jugador, §11.4 y ADR-006 §4.1).
  - `OK` → ejecuta el efecto del verbo y `true`.
  Prohibido decidir en `interact` una rama distinta de la publicada (AC2 del diseño, §11.6).
- **`can_interact(actor) -> bool`** se conserva y pasa a ser honesto: `get_action_hint(actor).is_target()`.
  Desaparecen los `true` que «consumían sin hacer nada» (caja con algo que no le sirve, olla con un
  cocido o una caja en la mano, slot ocupado con la mano llena, spawner con la mano llena).
- **`is_reachable_from`** (§8.1) no cambia de firma y se evalúa **antes** que `get_action_hint` (filtro
  de lado). `get_action_hint` no repite la comprobación de lado.
- `InteractionContract` (común) gana `const HINT_METHOD: StringName = &"get_action_hint"`; la oleada de
  montaje lo mueve a `INTERACTABLE_METHODS`.

#### 11.3 Detector: filtro honesto, histéresis, suelo y publicación del hint

- `InteractionDetector` gana `@export var actor: InteractionComponent` (en `player.tscn`:
  `%InteractionComponent`). Por cada entidad, en este orden: `is_reachable_from` (si existe) →
  `hint := entity.get_action_hint(actor)` si tiene el método; si no, `ActionHint.ok(&"")` cuando
  `can_interact(actor)` es `true` y `none()` si no → con `NONE` la entidad **no es candidata**. Guarda
  el hint de cada candidato. `OK` con verbo vacío es la **única excepción** a las invariantes de
  `ActionHint` («objetivo heredado sin verbo», solo dobles de test y entidades sin migrar): el botón
  táctil lo pinta sin icono y el prompt no se muestra. Desde la oleada de montaje el test de contrato
  impide que una entidad de `entities/` dependa de ella.
- **Sin control no hay objetivo.** Si `actor == null`, `actor.control == null` o
  `actor.control.controlled_by == 0`, el detector publica `null` con hint `none()` y apaga su
  resaltado. El personaje no controlado no muestra contorno ni prompt.
- **Sin objetivo con la mano llena** (filas A8–A9 del diseño): si no queda ningún candidato y el
  `holder` lleva algo, el hint publicado (con objetivo `null`) es `ActionRules.for_floor(held,
  holder.can_drop_freely())`: `ok(DROP)` si el punto de soltar está libre y `blocked(DROP, BUSY)` si cae
  en `world` (barra, pared). Mano vacía y sin candidatos: `none()`.
- **Histéresis** (D26.4) en `InteractionScoring` (común, pura). `pick_best` gana dos parámetros con
  valor por defecto (los tests actuales no cambian):
  ```gdscript
  static func pick_best(origin: Vector2, forward: Vector2, candidates: Array[Candidate], holding: bool,
          cone_half_angle_deg: float, near_distance: float, kitchen_bonus: float,
          current: int = -1, hysteresis_margin: float = 0.0) -> int
  ```
  `current` = índice en `candidates` del objetivo publicado si sigue siendo candidato (si no, −1).
  Regla: se calcula `best` como hoy (prioridad de cogible suelto incluida). Si `current` ≥ 0, pasa el
  cono y `best != current`, se mantiene `current` salvo que (a) `best` tenga prioridad de cogible y
  `current` no (regla categórica de PUL-063), o (b) `score(best) > score(current) + hysteresis_margin ×
  absf(score(current))` (con puntuación positiva, `> score × 1,20`, AC9 del diseño), con las
  puntuaciones ya con `kitchen_bonus`. Si `current` deja de ser candidato (fuera de radio o cono,
  `is_reachable_from` falso, liberado o hint `NONE`) se cambia en ese tick. Pasar de `OK` a `BLOCKED`
  (o al revés) **no** invalida al actual.
- `PlayerConfig` (`resources/player_config.gd`) gana `@export var hysteresis_margin: float = 0.2`;
  `data/config/player_config.tres` lo fija a **0,2**. 0 = sin histéresis (comportamiento previo).
- **Resaltado** (§11.8): el detector llama `Highlightable.set_blocked(hint.state == BLOCKED)` sobre el
  objetivo que enciende (contorno ámbar si está bloqueado).
- **Publicación** (local): señal nueva `hint_changed(target: Node, hint: ActionHint)` y
  `func get_hint() -> ActionHint` (nunca `null`). En cada `refresh()`, tras `target_changed` (si cambió
  el objetivo), emite `hint_changed` si cambió el objetivo **o** `not hint.same_as(anterior)`. Los
  cambios solo de `progress` no emiten: quien lo pinte lo lee con `get_hint()`. El hint de suelo
  (A8–A9) viaja con `target = null`.

#### 11.4 `InteractionComponent`: respuesta única, suelo, mantener y bus

- `interact_pressed() -> bool` (D26.3):
  1. `hint` = el vigente del detector (`get_hint()`, el mismo que se ve) y `target` = su objetivo; si
     hay objetivo se recalcula con `target.get_action_hint(self)` (el estado puede haber cambiado en
     este frame).
  2. `hint.state == NONE` (mano vacía y sin objetivo): nada; devuelve `false`.
  3. Sin objetivo (suelo): `OK` `drop` → `holder.drop()`; `BLOCKED` `busy` → nada cambia. En los dos
     casos se emite la respuesta (paso 5). Sustituye a la regla «consumir en silencio» de §9.5: soltar
     contra la barra o la pared ya **no es una pulsación muda**.
  4. Con objetivo: `target.interact(self)` (debe devolver `true`; si devuelve `false`, `push_error`: el
     receptor incumple §11.2).
  5. Señal **local** `interaction_resolved(target: Node, hint: ActionHint)` (`target` puede ser `null`
     en el suelo) → `EventBus.interaction_resolved(player_index, hint.verb, hint.state, hint.reason)` si
     `control.controlled_by > 0`. Devuelve `true`.
  `player_index` del bus = `control.controlled_by` (el **jugador**, no el personaje).
- **Respuesta al rechazo** (D26.3): la da el jugador, no la estación. `player.gd` conecta
  `interaction_resolved` local y, con `BLOCKED`, llama a su `%Feedback.play_cue(&"rejected", target)`
  (`SHAKE` del objetivo; sin objetivo, del propio personaje): **un único cue de rechazo** para todos
  los motivos (diseño AC7). `%ActionPrompt` muestra × + motivo y se sacude. Con `OK` el cue es el del
  efecto (el de la escena que cambia: `pick_up`, `drop`, `cut`, `season`…) y el prompt «salta». Cada
  pulsación con respuesta da **exactamente un** cue de respuesta (ADR-006 §4.1).
- **Mantener para cortar** (D26.5, diseño AC13): `PlayerInput` gana `is_interact_pressed() -> bool`
  (`Input.is_action_pressed(_interact, true)`). `InputConfig` gana `@export var cut_repeat_interval:
  float = 0.2` (`input_config.tres`: 0,2). `InteractionComponent` guarda un `HoldRepeat`: tras una
  pulsación resuelta `OK` con `hint.verb in ActionVerb.REPEATABLE` lo arma (recordando el objetivo); en
  `_physics_process(delta)`, si `is_interact_pressed()` es `false`, cambió el objetivo o su hint ya no
  es ese verbo en `OK` (caja llena, pulpo agotado), lo desarma **sin** pulsar (no hay rechazo mientras
  se mantiene); si no, cuando `advance(delta)` da `true`, llama a `interact_pressed()`. Primer corte al
  pulsar; los demás cada 0,2 s de juego (1,05 s mantenido = 6 cortes). Se congela en pausa. Pulsar
  sigue valiendo (D13).
- **Bus del hint** (ADR-002 Enmienda 2, `signals.md` §2): `InteractionComponent` conecta `hint_changed`
  de su `detector` (por nombre) y emite `EventBus.action_hint_changed(controlled_by, hint.verb,
  hint.state, hint.reason)` solo si `controlled_by > 0`. Al **perder** el control emite una vez
  `action_hint_changed(jugador_anterior, &"", 0, &"")`; al **ganarlo**, una vez el hint vigente de su
  detector. Como `CharacterSwitcher` pone 0 al saliente antes que 1 al entrante en la misma llamada
  (ADR-004 §4), el último hecho para el jugador es el del entrante. En cada instante hay como mucho un
  `InteractionComponent` controlado por cada jugador: es el emisor único de `action_hint_changed` e
  `interaction_resolved` para ese `player_index`.

#### 11.5 Prompt en el mundo (`ActionPrompt`)

Decisión: el icono sobre el objetivo vive **en el mundo** (capa específica), no en `ui/` (regla 4: un
`Control` que proyecte posiciones 3D necesitaría la cámara y `Vector3`). Obtiene el hint
**localmente** de su detector, sin bus.

```
entities/player/action_prompt.tscn
ActionPrompt (Node3D, top_level = true)   components/action_prompt.gd  class_name ActionPrompt
│   @export detector: InteractionDetector     (el del mismo personaje)
│   @export actor: InteractionComponent       (el del mismo personaje)
│   @export hold: HoldComponent               (punto de soltar para el hint de suelo)
│   @export icons: ActionIconSet = data/config/action_icons.tres
│   hint_changed(target, hint) → se coloca y pinta; interaction_resolved(target, hint) → animación
├── %Plate        (Sprite3D billboard, no_depth_test, render_priority alta)  placa circular oscura
├── %VerbIcon     (Sprite3D, ídem)  icons.verb_icons[hint.verb]; ok_color / blocked_color
├── %ReasonIcon   (Sprite3D, ídem)  icons.reason_icons[hint.reason]; solo BLOCKED (esquina inferior derecha)
├── %Cross        (Sprite3D, ídem)  icons.cross; solo BLOCKED (esquina superior derecha)
├── %ReplaceBadge (Sprite3D, ídem)  icons.replace; solo si hint.replaces (esquina superior izquierda)
└── %PlayerMarker (Sprite3D, ídem)  icons.player_markers[jugador − 1]; solo en COOP_2P
```
- Visible solo con hint `OK` o `BLOCKED` (con verbo no vacío) y el personaje controlado.
- **Posición**: con objetivo, su `%PromptAnchor` (`Marker3D`, opcional, hijo directo de la raíz del
  objetivo; `target.get_node_or_null(^"%PromptAnchor")`) o, si no tiene, la parte alta de su
  `Highlightable` (AABB de sus mallas) + `icons.prompt_offset` (0,9 m) hacia arriba. Sin objetivo
  (hint de suelo), sobre el punto de soltar: `HoldComponent.get_drop_position() -> Vector3` (método
  nuevo, específico; mismo punto que usa `can_drop_freely`). Se recoloca cada frame.
- **Tamaño en pantalla** (diseño): icono `prompt_icon_px_1080` (64) y placa `prompt_plate_px_1080` (80)
  × alto de ventana / 1080, con mínimo absoluto `prompt_min_px` (48) para el icono; motivo 32 px y aspa
  24 px a 1080. Con la ortográfica, metros = píxeles × `size` / alto. Sin test de profundidad: el
  jugador no lo tapa.
- **Dos prompts en el mismo objetivo** (Local 2P): se colocan lado a lado separados 8 px. Coordinación
  por un registro **estático de la clase** `ActionPrompt` (objetivo → prompts visibles), sin buscar
  nodos en la escena.
- **Respuesta** (`response_duration` 0,35 s): `OK` → el icono sube 12 px y escala 1,0 → 1,25 → 1,0;
  `BLOCKED` → aspa y motivo parpadean una vez y el prompt se sacude ±`reject_shake_px` (6) px, 3 ciclos.
  Cada pulsación reinicia la animación. Tween del nodo (se congela en pausa).
- Lo instancia `player.tscn` como `%ActionPrompt` (uno por personaje). El nivel no cambia por él.

**Datos de iconos y prompt** (`resources/action_icon_set.gd`, `class_name ActionIconSet extends
Resource`, común: solo `Texture2D`, `Color`, `float`): `verb_icons: Dictionary[StringName, Texture2D]`
(claves = `ActionVerb.ALL`), `reason_icons: Dictionary[StringName, Texture2D]` (claves =
`ActionReason.ALL`), `plate`, `cross`, `replace: Texture2D`, `player_markers: Array[Texture2D]` (J1, J2),
`ok_color` `#FFFFFF`, `blocked_color` `#FFB020`, `plate_color` `#1B1B1F` al 85 %, `idle_color` `#6B6B73`,
`idle_alpha` 0,4 (botón táctil sin objetivo), `prompt_icon_px_1080` 64, `prompt_plate_px_1080` 80,
`prompt_min_px` 48, `reason_icon_px_1080` 32, `cross_px_1080` 24, `prompt_offset` 0,9,
`response_duration` 0,35, `reject_shake_px` 6. Instancia: `data/config/action_icons.tres`. La
comparten `ActionPrompt` (mundo) y el botón de acción táctil (UI, ADR-004 §6): mismo icono en los dos.
Texturas (SVG monocromos, diseño «Iconografía») en `assets/textures/ui/actions/`:
`icon_verb_<id>.svg` (`<id>` = valor del `StringName` del verbo), `icon_reason_<id>.svg` (ídem del
motivo) e `icon_mark_<nombre>.svg` (`cross`, `replace`, `ready`, `burn_warning`, `active`,
`offscreen`, `player_1`, `player_2`); la placa es `icon_mark_plate.svg` o un círculo generado (decide
el arte). Test de datos: todas las claves de `ALL` tienen textura.

#### 11.6 Tabla por receptor (`ActionRules`; transcripción de `lenguaje-acciones.md` A–F)

Notación: `OK:VERBO`, `B:motivo` (`BLOCKED` con el verbo de la columna de acción del receptor), `—` =
`NONE` (ni contorno ni prompt). Manos: M0 `NOTHING`, M1 `OCTOPUS_RAW`, M2 `OCTOPUS_COOKED`, M3
`CACHELOS_RAW`, M4 `CACHELOS_COOKED`, M5 `BOX_EMPTY`, M6 `BOX_PARTIAL`, M7–M9 `BOX_FULL` (sin aliño /
dulce / picante; `+C` = con cachelos).

| Receptor (fila del diseño) | Función | Regla |
|---|---|---|
| A1–A3 Nevera, cachelera, rack | `for_spawner` | M0 `OK:pick_up`; resto `—` |
| A4 Pulpo/cachelos sueltos o en pasaplatos | `for_loose_item` | M0 `OK:pick_up` (si `can_hold`); resto `—` |
| A5 Pasaplatos vacío | `for_pass_slot` | M0 `—`; M1–M9 `OK:drop` (si `accepts`; si no, `—`) |
| A6 Cubo | `for_trash` | M0 `—`; M1–M9 `OK:trash` (`TrashRules.can_trash`) |
| A7 Puesto | — | No es `interactable` (§11.7) |
| A8–A9 Sin objetivo | `for_floor` | M0 `—`; M1–M9 `OK:drop` con sitio; `B:busy` (verbo `drop`) sin sitio |
| B1–B2 Caja vacía o a medias | `for_box` | M0 `OK:pick_up`; M1 `B:not_cooked` (verbo `cut`); M2 `OK:cut` (`progress` = llenado); M3–M9 `—` |
| B3 Caja llena | `for_box` | M0 `OK:pick_up`; M1 y M2 `B:full` (verbo `cut`); M3–M9 `—` |
| C Olla | `for_pot` | M0: quemado → `OK:trash` (el más antiguo); si no, listo → `OK:pick_up`; si no `—`. M1/M3: plaza libre → `OK:cook`; si no `B:busy`. M2, M4–M9 `—` |
| D Dispensador (lado de aliñar; desde el de pase no es candidato) | `for_dispenser` | M0–M4 `—`; M5/M6 `B:box_not_full`; M7 `OK:<verbo del aliño>`; con el mismo aliño `B:already_applied`; con el otro `OK:<verbo>` y `replaces = true` |
| E Cuenco | `for_bowl` | M4: `stock + portions_per_item ≤ stock_max` → `OK:cachelos` (repone), si no `B:full` (cualquier lado). M5/M6 (lado de aliñar) `B:box_not_full`. M7–M9 (lado de aliñar): ya lleva cachelos → `B:already_applied` (también con stock 0); si no, stock 0 → `B:empty`, si no `OK:cachelos` (pone). M0–M3 `—`. Desde el lado de pase con caja: no es candidato |
| F Zona de entrega | — | No usa el hint (§11.7) |

- Un pasaplatos con objeto y la mano llena no es objetivo; su objeto lo sustituye (como hoy) y solo es
  candidato si su verbo no es `—`.
- **Fixture**: `godot/tests/fixtures/action_matrix.csv` (una fila por combinación del diseño, ≥ 250, con
  mano, receptor, estado del receptor, verbo, estado y motivo esperados; no es dato de balance). La
  lee `tests/unit/test_action_rules.gd` (reglas puras) y, en la oleada de montaje,
  `tests/integration/test_action_matrix.gd` (escenas reales, AC1–AC2 y AC11 y AC20 del diseño: es la
  **puerta** de D26).

#### 11.7 Entrega solo por zona, cuenco que solo pone y verbo del aliño en datos

**Puesto** (`order_stand.gd`, `order_stand.tscn`; D26.5, modifica D8):
- La raíz `OrderStand` **sale del grupo `interactable`** y su `collision_layer` pasa de `interactable`
  a `world` (sigue siendo un mostrador que no se cruza y bloquea el punto de soltar, §9.5). Se quitan
  `can_interact`, `interact` y la rama de B12.
- Entrega: solo `%DeliveryZone`. Además de `body_entered`, en `_physics_process` (ya existe por el
  indicador, §9.4) entrega a un portador que **ya está dentro** de `%DeliveryZone` en el primer tick en
  que su caja pasa a cumplir `_zone_accepts`. Mismo antirrebote por caja y tick. Una caja que no
  encaja no enciende la zona ni hace nada.
- `EventBus.delivery_rejected` y `OrderBoard` **se conservan** (firma, núcleo y tests de núcleo; P3 del
  gate) pero la señal queda **sin emisión en el juego**. `order_stand.gd` deja de reproducir
  `deliver_error` y `RoundConfig.wrong_delivery_penalty` pasa a **0** en `round_config.tres` (D8
  modificada; ficha de montaje).

**Cuenco** (`cachelos_bowl.gd`; D26.5, modifica D23/D25):
- Con caja llena solo **pone**: `box.apply_seasoning(seasoning)` (cachelos, grupo `&""`) y gasta 1
  ración. Se van `_toggle`, `clock`, `_game_time`, `_last_change`.
- Reponer solo si `stock + cachelos_portions_per_item ≤ cachelos_stock_max` (con 2 y 4: stock ≤ 2);
  con stock 3 ya no se repone «recortando» (cambio respecto a §9.3, por la tabla E3 del diseño). La
  regla vive en `ActionRules.for_bowl`; `SeasoningRules.restocked` no cambia.
- `is_reachable_from`: cachelos cocidos desde cualquier lado; **cualquier caja** (vacía, a medias o
  llena) solo desde el lado de aliñar (antes, solo llena), para que la caja a medias dé `B:box_not_full`.
- Bajas: `SeasoningStationData.toggle_guard` (y en `seasoning_station.tres`), `SeasoningRules.toggle()`
  y `Box.toggle_seasoning()` (sin usuarios; las dos últimas en la oleada de montaje).
  `Box.remove_seasoning()` se conserva.
- `rejected` local del cuenco: `BOWL_EMPTY`, `BOWL_FULL`, `ALREADY_APPLIED` y `BOX_NOT_FULL` (mapeo de
  los motivos de la tabla). Sin cue en la estación.

**Dispensador** (`seasoning_dispenser.gd`; sustituye lo dicho en §10.2 sobre `ALREADY_APPLIED`): con el
mismo aliño el hint es `B:already_applied` y la pulsación **deja de ser silenciosa**: emite
`rejected(ALREADY_APPLIED)` local y el jugador suena `rejected` (D26.3; pregunta 3 del diseño). Caja
vacía o a medias: `B:box_not_full`, como hoy.

**Verbo del aliño en datos.** `SeasoningData` gana `@export var verb: StringName = &""`:
`sweet_dressing.tres` → `&"season_sweet"`, `hot_dressing.tres` → `&"season_hot"`, `cachelos.tres` →
`&"cachelos"`. Su `icon` pasa a ser el del verbo (`icon_verb_season_sweet.svg` pimentonera,
`icon_verb_season_hot.svg` guindilla): mismo icono en dispensador, ticket y pegatina (D26.7). Test de
datos: todo `SeasoningData` con `.tres` tiene `ActionVerb.is_valid(verb)`.

**Estación** (`seasoning_station.gd`): deja de reproducir `season_error` al oír `rejected` (lo hace el
jugador); la sacudida del emisor la da ya el `SHAKE` del cue `rejected` sobre el objetivo.

#### 11.8 Estado legible en el mundo (D26.6; medidas a 1080 de alto)

| Qué | Dónde | Contrato |
|---|---|---|
| Cocción por plaza | `kitchen.tscn`: un `%CookRing` por plaza (sustituye a `%CookBar`), instancia de `ui/widgets/world_progress_ring.tscn` (nuevo; `Sprite3D` + `SubViewport`, específico como `world_progress_bar`) | Diámetro ≥ 64 px, grosor ≥ 8 px. Cociendo: arco blanco 0→100 %. Listo: verde + `icon_mark_ready` + cue `cook_ready`. Quemándose (desde `burn_warned`): parpadeo ámbar `#FFB020` ↔ rojo `#E03A2F` a `warn_blink_hz` (3) + `icon_mark_burn_warning`; cue `burn_warning` al empezar y cada `warn_repeat_interval` (1 s) hasta `warn_repeat_count` (3) veces o hasta retirar. Quemado: rojo fijo. Datos en `KitchenData` (`warn_blink_hz`, `warn_repeat_interval`, `warn_repeat_count`, `ring_thickness_px` 8, `ring_diameter_px` 64) |
| Corte en la caja | `box.tscn`, nodo nuevo `%CutCounter` (`Node3D`: 6 segmentos + `Label3D`, billboard, `no_depth_test`) | Barra de `presses_to_fill` segmentos (≥ 14 px de ancho, grosor ≥ 8 px) y numeral `"N/6"` ≥ 36 px. Visible con 0 < N < total; en el corte que llena muestra `6/6` 0,5 s, suena `box_full` y se oculta. `Box` expone `get_presses() -> int` |
| Barras restantes | `ui/widgets/world_progress_bar.{gd,tscn}` (pulpo) | Grosor ≥ 8 px |
| Raciones del cuenco | `cachelos_bowl.tscn`, `%StockMeter` (`Sprite3D` billboard) | 4 muescas ≥ 24 px, `stock` llenas, el resto huecas con contorno; contraste ≥ 3:1. `%Portions` del modelo se conserva |
| Personaje activo | `player.tscn` `%ActiveIndicator` + `%ActiveMarker` (nuevo, `Sprite3D` billboard `icon_mark_active` ≥ 24 px sobre la cabeza) | Activo: anillo sólido ≥ 8 px del color del jugador + ▼. Inactivo: anillo discontinuo gris ≤ 3 px, sin ▼. `player.gd` gana `@export var inactive_material: Material`; contraste en gris ≥ 3:1 |
| Contorno del objetivo | `components/highlightable.gd` + `shaders/highlight_outline*` | Color blanco cálido `#FFF4D6` (se retira el amarillo); `set_blocked(blocked: bool)` cambia a ámbar; el contorno se ve **a través** del personaje (pasada sin profundidad al 40 %). API `acquire`/`release`/`show`/`hide` sin cambios |

#### 11.9 Señales
`EventBus` gana **dos** señales: `action_hint_changed(player_index: int, verb: StringName, state: int,
reason: StringName)` e `interaction_resolved(player_index: int, verb: StringName, state: int, reason:
StringName)`, ambas con emisor `InteractionComponent` (§11.4). Señales locales nuevas:
`InteractionDetector.hint_changed(target: Node, hint: ActionHint)` e
`InteractionComponent.interaction_resolved(target: Node, hint: ActionHint)` (`target` `null` en el
suelo). Detalle en `signals.md`.

**Alternativas descartadas (§11).**
1. *Derivar el icono de `can_interact` + tipo del objetivo.* `can_interact` mentía a propósito y el
   verbo depende del estado (olla: coger o tirar); dos funciones que pueden divergir. Se prefiere una
   sola resolución (`_resolve` → `ActionRules`).
2. *Calcular el hint en `InteractionComponent` cada tick.* El detector ya lo necesita para filtrar
   candidatos; calcularlo dos veces es coste y riesgo de divergencia entre lo resaltado y lo
   publicado.
3. *Prompt como `Control` en `ui/` que proyecta la posición del objetivo.* Necesita `Camera3D` y
   `Vector3` en `ui/` (regla 4) y una ruta al objetivo.
4. *`EventBus` con el nodo objetivo o su posición.* Rompe la regla de primitivos (D14); la UI de
   pantalla solo necesita verbo y estado.
5. *Verbos como `enum` entero.* El `StringName` se lee en `.tres` (`SeasoningData.verb`, diccionarios de
   iconos), en nombres de fichero y en los logs; el conjunto se cierra con `ALL` + test.
6. *Histéresis por tiempo mínimo en el objetivo.* D26.4 la define por margen de puntuación; el tiempo
   retrasa también los cambios buenos.
7. *Mantener el puesto como objetivo con BLOQUEADO para la caja que no encaja.* D26.5 lo quita de la
   pulsación; la zona iluminada ya dice si encaja.
8. *Un `ActionLanguageData` único* (propuesta del diseño). Mezclaría datos del detector
   (`PlayerConfig`), del input (`InputConfig`) y del prompt; cada consumidor lee su recurso.
9. *Un cue de rechazo distinto para «ya aplicado».* El diseño pide un único cue de rechazo (AC7); el
   motivo ya lo dice el icono.

**Estado tras el montaje (PUL-131).** Quedan superados en §8–§10 el cue `season_error` (§8, tabla de
§9 y rechazo `BOX_NOT_FULL` de §10: ahora suena `rejected` en el jugador), `Box.toggle_seasoning()` y
`SeasoningRules.toggle()` (§8.3, §10.2: el cuenco solo pone con `apply_seasoning`); se conservan como
historia. El puesto ya no es objetivo y entrega al entrar en `%DeliveryZone` o estando dentro cuando la
caja pasa a encajar (§11.7).

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
- (§10, +) Una sola caja, dos dispensadores y una regla (`SeasoningRules.apply`) en lugar de tallas,
  cuatro dispensadores y el toggle: menos datos, menos tests de combinatoria y un ticket más corto.
- (§10, −) La caja ya no se corrige quitando condimento: el error se tira al cubo (coste en tiempo,
  sin penalización en euros mientras `trash_penalty` = 0). Tirar suena `drop` + `trash`.
- (§10, −) `SeasoningType` y `Rejection` acumulan valores en desuso para no renumerar los `.tres`.
- (§11, +) El verbo y su estado salen de la misma función que ejecuta la pulsación: lo que se ve es
  lo que pasa, y las 72 combinaciones se prueban en `core/` sin escenas.
- (§11, +) La UI de pantalla (botón táctil) solo escucha dos señales de primitivos; el icono del
  mundo es local al jugador.
- (§11, −) El detector hace una llamada dinámica más por candidato (`get_action_hint`) en cada tick
  (≤ ~6 cuerpos en el radio); los receptores no deben tener efectos en `_resolve`.
- (§11, −) Sin pulsaciones «protegidas»: con la mano llena y sin objetivo con verbo, pulsar suelta
  delante si el punto está libre (prompt SOLTAR visible) o da un rechazo `busy` contra barra o pared
  (decisión del producer autorizada por el responsable, P1 de PUL-120).
- (§11, −) `delivery_rejected` y la penalización de caja errónea (D8) quedan sin uso en el juego; se
  conservan por no cambiar firmas.
- El árbol concreto de M0 está en `docs/arch/scene-tree.md`. Cambiarlo en algo que afecte a otra
  ficha (nombres de escena, `@export` públicos, grupos, capas) requiere enmienda.
