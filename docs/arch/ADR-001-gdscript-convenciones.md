# ADR-001 — Lenguaje y convenciones GDScript

- **Estado:** aceptado (2026-10-03)
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
- **Relacionado:** `docs/design/decisions.md` (T1–T4), skill `gdscript-conventions`, ADR-003

## Contexto

El prototipo Unity está en C# con QFramework (`Assets/Scripts/`, 47 `.cs`). La migración a Godot
4.7.2 la hacen agentes en paralelo, cada uno en su worktree, y se integra por `tools/merge_gate.sh`.
Eso exige un código uniforme y comprobable por máquina: `tools/verify.sh` ya ejecuta `gdformat`,
`gdlint`, import headless, GUT y un smoke run, y `project.godot` trata `untyped_declaration` como
error (T2).

El inventario (`docs/migration/inventory.md`) propone rutas destino como `scenes/items/box.tscn`,
mientras la skill `gdscript-conventions` usa `entities/stations/kitchen_station.{tscn,gd}`. Hace
falta fijar una sola estructura de carpetas antes de la fase 0 de M0.

## Decisión

### Lenguaje
1. **GDScript con tipado estático en todo** el código del proyecto (fuera de `addons/`). Se
   mantienen los ajustes de `project.godot`: `untyped_declaration = error`,
   `inferred_declaration = ignorar` (se permite `:=` cuando el tipo es obvio).
2. Sin C# ni GDExtension en la alpha.
3. Los scripts reutilizables, los `Resource` y los tipos de valor llevan `class_name`.
   **Excepción:** los scripts de autoload **no** llevan `class_name` (chocaría con el nombre del
   singleton); los tests los instancian con `preload("res://autoload/<x>.gd").new()` (ADR-002).
4. Lógica de juego que no necesita escena → `RefCounted` (o funciones `static`) en `core/`, para
   probarla en headless sin árbol. Los nodos solo adaptan esa lógica a física, input y vista.
5. `autoload/`, `core/`, `resources/` y `ui/` (pantalla) no usan tipos 3D ni 2D de mundo
   (`Node3D`, `Node2D`, `Vector3`, cuerpos físicos): son la capa común de ADR-003 §0 y no deben
   depender de D14 (ADR-005).

### Nombres
| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case` | `order_service.gd`, `entities/stations/` |
| Nodos en escena | `PascalCase` | `HoldPoint`, `InteractionDetector` |
| `class_name` | `PascalCase` | `ActiveOrder`, `BoxData` |
| Funciones, variables, señales | `snake_case` | `try_deliver()`, `slot_id` |
| Privados | prefijo `_` | `_active_orders` |
| Constantes y valores de enum | `UPPER_SNAKE_CASE` | `MAX_ACTIVE_ORDERS`, `Mode.COOP_2P` |
| Señales | hecho en pasado (`<sujeto>_<verbo_participio>`) | `order_completed`, `round_finished` |
| Acciones de InputMap | `p<n>_<verbo>` por jugador; globales sin prefijo | `p1_interact`, `pause` (ADR-004) |
| Grupos | `snake_case` en plural o adjetivo | `interactable`, `pickable` |
| `Resource` de datos | sufijo `Data` / `Config` / `Catalog` | `RecipeData`, `RoundConfig` |

Las erratas del prototipo no se arrastran: `OctopusSwapner` → `item_spawner.gd`,
`remainintCuantity` → `remaining_amount`, `FooxBoxAnimationClose` → `box_close`.

### Orden dentro de un script
`class_name`, `extends`, docstring `##`, señales, enums, constantes, `@export`, variables
públicas, variables `_privadas`, `@onready`, métodos built-in (`_ready`, `_process`…), métodos
públicos, métodos privados. Es el orden de la guía oficial de estilo y el que impone `gdlint`
(`class-definitions-order`).

### Referencias y comunicación
- Hijos de la propia escena: `%NombreUnico` o `@export var x: Tipo`. Nunca `get_node("/root/…")`,
  rutas `../..` hacia fuera de la escena ni `get_tree().get_first_node_in_group()` para encontrar
  sistemas.
- Entre sistemas: señales de `EventBus` y métodos de los autoloads (ADR-002). Catálogo cerrado en
  `docs/arch/signals.md`.
- `is_instance_valid()` antes de usar un nodo que pueda haberse liberado (bug B18 del inventario).

### Datos
Números de balance en `Resource` `.tres` bajo `godot/data/`, nunca literales en código
(tiempos, capacidades, `fill_per_press`, zona muerta, cooldown de cambio…). La aleatoriedad usa
un `RandomNumberGenerator` inyectable con semilla fija en tests.

### Estructura de carpetas (`godot/`)
```
godot/
├── autoload/           # singletons (ADR-002): event_bus.gd, game_state.gd, order_service.gd, round_manager.gd
├── core/               # núcleos y tipos de valor (RefCounted, ADR-002): order_board.gd, round_state.gd,
│                       #   device_assignment.gd, active_order.gd, box_contents.gd, order_validator.gd,
│                       #   round_result.gd, interaction_scoring.gd, player_input.gd, game_mode.gd
├── resources/          # scripts de clases Resource: box_data.gd, recipe_data.gd, round_config.gd…
├── data/               # instancias .tres: boxes/, ingredients/, recipes/, orders/, seasonings/, config/
├── components/         # nodos reutilizables por composición. Comunes: control_component, holder,
│                       #   interaction_component. Específicos (3D/2D): hold_component, interaction_detector,
│                       #   highlightable
├── entities/           # una carpeta por entidad, escena y script juntos (capa específica 3D/2D)
│   ├── player/         #   player.tscn, player.gd, character_switcher.{tscn,gd}
│   ├── items/          #   octopus, box, seasoning
│   └── stations/       #   kitchen, octopus_storage, box_shelf, spice_shelf, slot, order_stand, item_spawner
├── ui/                 # hud/, tickets/, menus/ (main_menu, pause_menu, game_over), widgets/
├── scenes/             # escenas de flujo: boot.tscn, levels/level_01.tscn, levels/level.gd
├── shaders/            # highlight_outline.gdshader
├── assets/             # importados: models/, textures/, materials/, audio/, fonts/ (asset-pipeline)
└── tests/              # unit/ (lógica pura), integration/ (escenas), helpers/
```
Correspondencia con las rutas propuestas en el inventario: `scenes/player/` → `entities/player/`,
`scenes/items/` → `entities/items/`, `scenes/stations/` → `entities/stations/`, `scenes/ui/` →
`ui/`, `scenes/main_menu.tscn` → `ui/menus/main_menu.tscn`. `scenes/boot.tscn` y
`scenes/levels/level_01.tscn` se mantienen.

### Tests
GUT 9.7.1. `tests/unit/test_<sistema>.gd` para `core/` y autoloads instanciados a mano;
`tests/integration/test_<escena>.gd` para escenas. Un `func test_<comportamiento>() -> void` por
caso; cuando cubre un criterio de una ficha, el nombre lo cita: `test_ac1_order_completed_once_per_delivery`.

### Escenas y recursos
`.tscn`/`.tres` se editan con el editor o el MCP; a mano solo cambios triviales. Nunca se inventan
`uid://`. Los `.uid` se versionan. Un `.tscn` tiene un solo dueño por oleada (`touches_scenes`).

## Alternativas consideradas
1. **C# en Godot (.NET).** Facilitaría portar código del prototipo, pero el build .NET no exporta
   a Web, complica el headless/CI y el código Unity se va a reescribir de todos modos (bugs B1–B18,
   QFramework). Descartada.
2. **GDScript sin tipado estricto.** Menos fricción inicial, pero pierde errores en tiempo de
   análisis y autocompletado, y deja a los agentes sin red. Descartada (T2).
3. **Carpetas por tipo de archivo** (`scripts/`, `scenes/`, `prefabs/` como en Unity). Separa
   escena y script de la misma entidad y multiplica conflictos entre fichas. Descartada en favor
   de carpetas por entidad + capas transversales (`autoload/`, `core/`, `resources/`, `data/`).
4. **Scripts de clase Resource junto a sus `.tres`** (`data/boxes/box_data.gd`). Mezcla código
   con datos de balance que editará el diseño; se separan en `resources/` y `data/`.

## Consecuencias
- (+) `verify.sh` detecta en CI casi todo lo que esta ADR exige (tipado, formato, orden).
- (+) La lógica en `core/` y autoloads se prueba sin escena; los tests de escena quedan para
  integración.
- (+) Una ficha suele tocar una carpeta de `entities/` o `ui/`, lo que simplifica `owns`.
- (−) Las rutas del inventario quedan desfasadas; manda esta ADR (se corrige al cerrar M0 o en la
  ficha que cree cada escena).
- (−) Los autoloads sin `class_name` obligan a `preload` en tests y a tipar como `Node` cuando se
  pasan como parámetro.
- La skill `gdscript-conventions` debe enlazar esta ADR y usar la misma estructura (fuera del
  alcance de PUL-003: lo actualiza el producer al aceptar la ADR).
