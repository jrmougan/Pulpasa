# ADR-003 — Árbol de escenas y composición

- **Estado:** aceptado (2026-10-03)
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
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
  `@export var data: BoxData` (S/M/L), una `seasoning.tscn` con `SeasoningData`. Nada de escenas
  heredadas para variar un número.
- Las escenas compuestas (`box_shelf.tscn`, `spice_shelf.tscn`) instancian escenas hijas; no
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
| `Holder` | Común (abstracta) | `Node` | `IPickable` + `PlayerHoldSystem` (API) | API de la mano: `get_held_item() -> Node`, `can_hold(item: Node) -> bool`, `pick_up(item: Node) -> bool`, `drop() -> Node`; señales `item_picked_up`/`item_dropped`. Los métodos base fallan con `push_error`; los implementa `HoldComponent` |
| `InteractionComponent` | Común | `Node` | `PlayerInteractionController` | `@export var control: ControlComponent`, `@export var holder: Holder`, `@export var detector: Node` (conecta `target_changed` por nombre). Al pulsar `p<n>_interact` llama `interact(self)` del objetivo; si nada acepta y lleva algo, `holder.drop()` |
| `HoldComponent` | Específica | `Holder` + `Marker3D`/`Marker2D` `%HoldPoint` | `PlayerHoldSystem` | Implementa `Holder`: reparenta y coloca el objeto. Único camino: llama `on_picked_up`/`on_dropped` del objeto (B4); valida antes de mutar (B5) |
| `InteractionDetector` | Específica | `Area3D` / `Area2D` | `InteractionDetector` | Un solo detector por jugador (B7); radio en `PlayerConfig.tres`. Delega la puntuación en `InteractionScoring` (común, `Vector2` del suelo) |
| `Highlightable` | Específica | `Node` | `HighlightController`, `OutlineHighlighter`, `InteractableHighlight` | 3D: `material_overlay` con shader de contorno; 2D: shader `canvas_item` de contorno. Retícula opcional. Sin `EmissionHighlighter` (B3) |

### 4. Contrato de interacción (sustituye a `IInteractable`/`IPickable`) — común
Godot no tiene interfaces; se usa **grupo + métodos con firma fija**, verificado por test:

| Grupo | Métodos obligatorios en el script raíz | Lo implementan |
|---|---|---|
| `interactable` | `can_interact(actor: InteractionComponent) -> bool`; `interact(actor: InteractionComponent) -> bool` (devuelve si consumió la pulsación) | estaciones, slots, caja, puesto de entrega, pulpo, condimento |
| `pickable` | `on_picked_up(holder: Holder) -> void`; `on_dropped() -> void`; `var is_held: bool` | pulpo, caja, condimento |
| `kitchen` | Ninguno (marca). Lo usa `InteractionDetector` para el bonus de puntuación con mano vacía (`PlayerConfig.kitchen_bonus`, equivale al tag `Kitchen` de Unity). No es una capa de física | raíz de `kitchen.tscn` (obligatorio) |

*Enmienda 2026-10-03 (grupo `kitchen`), aprobada por el responsable tras la revisión de PUL-015.*

*Enmienda 2026-10-03: pulpo y condimento están en `pickable` **e** `interactable`, como en Unity (`Ingredient.cs`, `SeasoningItem.cs` implementan `IPickable` e `IInteractable`). `InteractionScoring` solo elige un cogible si también es interactuable (paridad con `InteractionDetector.cs:99`). Aprobada por el responsable tras la revisión de PUL-016.*

- Los tipos del contrato (`InteractionComponent`, `Holder`) son comunes: el receptor accede a la mano
  con `actor.holder` y al jugador con `actor.control.controlled_by`, sin conocer `Player`. El
  contrato no cambia con D14.
- La interacción contextual va en el **receptor**: la caja decide si el objeto en la mano del
  actor la llena (pulpo cocido, corte D1/D13) o la condimenta; no el controlador del jugador como
  en `PlayerInteractionController.cs:41,80`.
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
`scenes/boot.tscn` (escena principal; provisional hasta la fase 7) → `ui/menus/main_menu.tscn` →
`scenes/levels/level_01.tscn`. Los cambios de escena pasan por `GameState`
(`start_level(mode)`, `go_to_main_menu()`), que usa `get_tree().change_scene_to_file()`; ninguna
escena cambia de escena por su cuenta. Pausa y game over son overlays dentro del nivel, no escenas.

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
- El árbol concreto de M0 está en `docs/arch/scene-tree.md`. Cambiarlo en algo que afecte a otra
  ficha (nombres de escena, `@export` públicos, grupos, capas) requiere enmienda.
