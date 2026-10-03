# Árbol de escenas objetivo de M0

- **Estado:** propuesto (contrato; ver ADR-003)
- **Ficha:** PUL-003

Árbol que debe existir al cerrar M0 (fase 8). Rutas relativas a `godot/` (estructura de ADR-001).
`%Nombre` = nodo con nombre único de escena. Entre corchetes, la fase de M0 en que se crea la
escena y, si aplica, el hito en que se amplía. Lo marcado **M2** no existe en M0 pero se reserva
su sitio para no reestructurar.

**Dimensión pendiente (D14, ADR-005).** Las secciones §1 (autoloads y flujo), §4 (UI de pantalla,
salvo `world_progress_bar`) y §5 (datos) son **comunes**. Las §2 y §3 se dibujan en **3D** porque es
la opción del prototipo; si D14 resuelve 2D, se aplica la tabla de equivalencias de §6 manteniendo
nombres de escena, `class_name`, `@export` públicos, grupos, capas y señales locales.

## 1. Árbol en ejecución

```
/root (Window)
├── EventBus        autoload/event_bus.gd        [0]
├── GameState       autoload/game_state.gd       [0]   process_mode ALWAYS
├── OrderService    autoload/order_service.gd    [0, lógica en 2]  adaptador de core/order_board.gd
├── RoundManager    autoload/round_manager.gd    [0, lógica en 2]  adaptador de core/round_state.gd; único reloj (_physics_process)
└── <escena actual> boot.tscn → main_menu.tscn → level_01.tscn
```

Flujo: `scenes/boot.tscn` (escena principal; en fase 7 pasa a ser `main_menu.tscn` o un boot que
salta a él) → `ui/menus/main_menu.tscn` → `GameState.start_level(mode)` →
`scenes/levels/level_01.tscn`. Game over → reintentar (`start_level` con el mismo modo) o salir al
menú (`GameState.go_to_main_menu()`).

## 2. `scenes/levels/level_01.tscn` [8]

Solo instancias (ADR-003). Overrides permitidos: transform, `slot_id`, `player_index`,
`controlled_by` inicial y referencias `@export` entre instancias.

```
Level01 (Node3D)                         scenes/levels/level.gd  (común, extends Node)
│   @export round_config = data/config/round_config.tres   (duration 300 s, D5)
│   @export order_catalog = data/orders/order_catalog.tres
│   @export stands = [OrderStand1..4]
├── Environment          entities/environment/environment.tscn     WorldEnvironment + DirectionalLight3D [8]
├── KitchenLayout        entities/environment/kitchen_layout.tscn  suelo + 17 mesas (capa world) [3/8]
├── Stations (Node3D)
│   ├── OctopusStorage   entities/stations/octopus_storage.tscn    [6]
│   ├── Kitchen          entities/stations/kitchen.tscn            [6]
│   ├── BoxShelf         entities/stations/box_shelf.tscn          [6]
│   ├── SpiceShelf       entities/stations/spice_shelf.tscn        [6]
│   ├── OrderStand1      entities/stations/order_stand.tscn  slot_id = 1  [6]
│   ├── OrderStand2      …                                   slot_id = 2
│   ├── OrderStand3      …                                   slot_id = 3
│   └── OrderStand4      …                                   slot_id = 4
├── Characters (Node3D)
│   ├── Player1          entities/player/player.tscn  player_index = 1, controlled_by = 1, items_root = Items  [4]
│   └── Player2          entities/player/player.tscn  player_index = 2                                         [M2]
├── CharacterSwitcher    entities/player/character_switcher.tscn  (común) characters = [Player1/%Control, Player2/%Control]  [M2]
├── Items (Node3D)       destino de los objetos soltados (ADR-003 §6)
├── CameraRig            entities/camera/camera_rig.tscn  Camera3D fija, vista del prototipo [4]
└── UI (CanvasLayer)
    ├── HUD              ui/hud/hud.tscn                          [7]
    ├── OrderTicketsPanel ui/tickets/order_tickets_panel.tscn     [7]
    ├── PauseMenu        ui/menus/pause_menu.tscn   process_mode ALWAYS  [7]
    └── GameOver         ui/menus/game_over.tscn    oculto hasta round_finished  [7]
```

## 3. Escenas de entidad

### `entities/player/player.tscn` [4]
```
Player (CharacterBody3D, capa player)     player.gd  class_name Player
├── CollisionShape3D (Capsule)
├── Model                                  instancia de assets/models/freakycapucha (rotado 180° Y)
├── %AnimationTree                         StateMachine Idle/Walk/Pick/WalkWhileHolding; speed, is_holding
├── %HoldPoint (Marker3D)
├── %Control (Node)                        components/control_component.gd  (común) player_index, controlled_by
├── %HoldComponent (Node)                  components/hold_component.gd  extends Holder (común)  @export hold_point
├── %InteractionDetector (Area3D)          components/interaction_detector.gd  máscara interactable
│   └── CollisionShape3D (Sphere, radio de PlayerConfig)
├── %InteractionComponent (Node)           components/interaction_component.gd  (común) @export control, holder, detector
└── %ActiveIndicator (MeshInstance3D)      aro bajo el personaje [M2]
```
Un único detector (B7). Movimiento 5 m/s y giro en `PlayerConfig.tres`.

### `entities/items/`
```
octopus.tscn [6]   Octopus (RigidBody3D, capa interactable; grupos pickable, interactable)    ingredient.gd  class_name Ingredient
                   ├── CollisionShape3D, Model, %AnchorPoint (Marker3D)
                   ├── %Highlightable (Node)                                components/highlightable.gd
                   └── %AmountBar                                           ui/widgets/world_progress_bar.tscn
box.tscn [6]       Box (RigidBody3D; grupos pickable, interactable)          box.gd  class_name Box  @export data: BoxData
                   ├── CollisionShape3D, Model, %AnchorPoint, %AnimationPlayer (box_open / box_close)
                   ├── %Highlightable, %FillBar (world_progress_bar.tscn)
                   └── %SeasonAudio (AudioStreamPlayer3D)
seasoning.tscn [6] Seasoning (RigidBody3D; grupos pickable, interactable)                   seasoning_item.gd  @export data: SeasoningData
                   ├── CollisionShape3D, Model, %AnchorPoint, %Highlightable
```
Tres cajas y tres condimentos = una escena + `.tres` (`data/boxes/{small,medium,large}.tres`,
`data/seasonings/{salt,paprika,hot_paprika}.tres`).

### `entities/stations/`
```
item_spawner.gd [6]   script genérico (no escena): @export scene: PackedScene; @export data: Resource
octopus_storage.tscn  OctopusStorage (StaticBody3D; grupo interactable)  item_spawner.gd  scene = octopus.tscn
                      ├── CollisionShape3D, Model (nevera), %Highlightable
kitchen.tscn          Kitchen (StaticBody3D; grupos interactable, kitchen)  cooking_station.gd
                      ├── CollisionShape3D, Model (olla + fogón), %AnchorPoint, %Highlightable
                      ├── %CookBar (world_progress_bar.tscn), %BoilAudio (AudioStreamPlayer3D)
                      └── (reloj interno en _physics_process, sin nodo Timer; cook_time desde IngredientData; se congela con la pausa)
box_shelf.tscn        BoxShelf (StaticBody3D)  Model (mueble)
                      ├── SmallSpawner  (StaticBody3D; interactable)  item_spawner.gd  scene = box.tscn, data = small.tres
                      ├── MediumSpawner …                                                 data = medium.tres
                      └── LargeSpawner  …                                                 data = large.tres
slot.tscn [5]         Slot (StaticBody3D; grupo interactable)  slot.gd  @export initial_item: PackedScene
                      ├── CollisionShape3D, %Anchor (Marker3D), %Highlightable (retícula)
spice_shelf.tscn      SpiceShelf (StaticBody3D)  Model (mueble)
                      ├── SaltSlot / PaprikaSlot / HotPaprikaSlot   instancias de slot.tscn con su seasoning
order_stand.tscn      OrderStand (StaticBody3D; grupo interactable)  order_stand.gd  class_name OrderStand  @export slot_id: int
                      ├── CollisionShape3D, Model (order_stand)
                      ├── %DeliveryZone (Area3D, capa delivery_zone)   body_entered → intenta entregar (B12: también al interactuar)
                      ├── %OrderLabel (Label3D, billboard)             "#id" o "–"
                      └── %OkAudio, %ErrorAudio (AudioStreamPlayer3D)
```
Los modelos de nevera, olla, fogón y mesas dependen de D6 (Pandazole o sustitutos).

## 4. Escenas de UI [7]
```
ui/menus/main_menu.tscn      MainMenu (Control)        main_menu.gd   Individual / Local 2P (M2) / Salir; foco inicial en Individual
ui/menus/pause_menu.tscn     PauseMenu (Control)       pause_menu.gd  Reanudar / Salir; escucha `pause`, pause_changed, device_disconnected
ui/menus/game_over.tscn      GameOver (Control)        game_over.gd   escucha round_finished; Reintentar / Salir
ui/menus/menu_panel.tscn     panel y Theme comunes (sustituye a PanelPauseBase.prefab)
ui/hud/hud.tscn              HUD (Control)             hud.gd         tiempo, cajas/minuto (M1: recaudación)
ui/tickets/order_tickets_panel.tscn  (Control)         order_tickets_panel.gd  escucha orders_reset / order_generated / order_completed / order_expired; get_active_orders() para reconstruir
ui/tickets/order_ticket.tscn         (PanelContainer)  order_ticket.gd   "#id" + ticket_entry + %PatienceBar (TextureProgressBar) que solo pinta order_patience_changed de su order_id; sin contador propio (M1)
ui/tickets/ticket_entry.tscn         (HBoxContainer)   ticket_entry.gd   receta + condimentos
ui/widgets/world_progress_bar.tscn   (Sprite3D billboard + SubViewport con TextureProgressBar)
```
En M0 el menú muestra «Jugar» (= Individual con un solo personaje) y «Salir»; «Local 2P» llega en M2.

## 5. Datos (`data/`) [1]
```
data/boxes/{small,medium,large}.tres            BoxData        (capacity, fill_per_press 0.2/0.1/0.05)
data/ingredients/octopus.tres                    IngredientData (cook_time 5)
data/recipes/{individual,combo_duo,familiar}.tres RecipeData
data/orders/order_{1,2,3}.tres                   OrderData
data/orders/order_catalog.tres                   OrderCatalog   (orders: Array[OrderData], max_active_orders 4)
data/seasonings/{salt,paprika,hot_paprika}.tres  SeasoningData
data/config/round_config.tres                    RoundConfig    (duration 300)
data/config/player_config.tres                   PlayerConfig   (speed 5, rotation_speed 20, detector_radius 2.2: valor efectivo en Level_01 del prototipo; 1,5 en el prefab)
data/config/input_config.tres                    InputConfig    (deadzone 0.2, switch_cooldown 0.2)
```

## 6. Equivalencias si D14 = 2D

Misma estructura y nombres; cambian el nodo base y los hijos visuales/físicos.

| 3D (§2–§3) | 2D | Nota |
|---|---|---|
| `Level01 (Node3D)` | `Level01 (Node2D)` | `level.gd` no cambia |
| `Stations`, `Characters`, `Items` (`Node3D`) | Hijos de un único `World (Node2D, y_sort_enabled)` | Orden de dibujo por Y; objetos soltados y personajes deben compartir contenedor |
| `Environment` (`WorldEnvironment` + luz) | `CanvasModulate` opcional | Sin iluminación 3D |
| `KitchenLayout` (mallas + colisión `world`) | `TileMapLayer` (suelo) + `StaticBody2D` (mesas) | Mismas capas de física |
| `CharacterBody3D` / `RigidBody3D` / `StaticBody3D` | `CharacterBody2D` / `RigidBody2D` o `Area2D` / `StaticBody2D` | En 2D los objetos sueltos pueden ser estáticos (sin física de caída) |
| `Area3D` (detector, `DeliveryZone`) | `Area2D` | `InteractionScoring` es el mismo (`Vector2`) |
| `Marker3D` (`HoldPoint`, `AnchorPoint`) | `Marker2D` | |
| `Model` + `AnimationTree` (esqueleto del FBX) | `AnimatedSprite2D` (+ `AnimationTree` si hace falta) | Idle/Walk/Pick/WalkWhileHolding × direcciones |
| `Highlightable` con `material_overlay` (inverted hull) | `Highlightable` con shader `canvas_item` de contorno | Misma API `show()` / `hide()` |
| `Label3D` billboard (`OrderLabel`) | `Label` bajo un `Node2D` | |
| `world_progress_bar` (`Sprite3D` + `SubViewport`) | `TextureProgressBar` bajo un `Node2D` | Más simple en 2D |
| `AudioStreamPlayer3D` | `AudioStreamPlayer2D` | |
| `CameraRig` (`Camera3D` fija) | `Camera2D` fija | |
| `%ActiveIndicator` (aro `MeshInstance3D`) | `Sprite2D` bajo los pies | |
