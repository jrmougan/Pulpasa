# Árbol de escenas objetivo de M0

- **Estado:** propuesto (contrato; ver ADR-003)
- **Ficha:** PUL-003; enmienda de la estación de condimentos y la planta B en PUL-056
  (2026-10-05, D18/D19, ADR-003 §8), **pendiente del gate humano**: §2, §3 (caja, slot, estación),
  §5, §6 y §7 (bajas). Lo marcado **M2b** lo implementan PUL-057..PUL-061.
- **Enmienda M3** (PUL-066, 2026-10-06, ADR-006), **pendiente del gate humano**: `AudioDirector`
  (§1), `LevelAudio` (§2), `%Feedback` y quemado en las entidades (§3), datos de audio, fases y
  quemado (§5), equivalencia 2D (§6) y §8 (buses). Lo marcado **M3** lo implementan PUL-069..071.

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
├── AudioDirector   autoload/audio_director.gd   [M3]  process_mode ALWAYS; adaptador de core/audio_mix.gd; volumen de buses y bajada en pausa (no reproduce)
└── <escena actual> main_menu.tscn → level_01.tscn  (boot.tscn: entrada alternativa que salta al menú)
```

Flujo: `ui/menus/main_menu.tscn` (escena principal desde la fase 7; `boot.tscn` salta a él) →
`GameState.start_level(mode)` →
`scenes/levels/level_01.tscn`. Game over → reintentar (`start_level` con el mismo modo) o salir al
menú (`GameState.go_to_main_menu()`).

## 2. `scenes/levels/level_01.tscn` [8; planta B en M2b]

Solo instancias (ADR-003). Overrides permitidos: transform, `slot_id`, `player_index`,
`controlled_by` inicial y referencias `@export` entre instancias.

**Planta B · barra partida** (D19, `docs/design/level-layouts.md`, PUL-061). Cuadrícula de 16 × 11
celdas de 1 m: columna `c` ocupa x ∈ [c − 6,8, c − 5,8] (centro c − 6,3); fila `r` ocupa
z ∈ [r − 4,5, r − 3,5] (centro r − 4,0). Arriba (z−) la cocina, abajo (z+) el servicio. Las
coordenadas son orientativas: manda `docs/design/level-layouts/gen_layouts.py` con ±1 m
(AC2 de PUL-061).

```
   0123456789012345
 0 ##NK#O#O########     cocina: OctopusStorage, CachelosStorage, Kitchen, Kitchen2
 1 #..............#
 2 #.b............#     Player2 (b)
 3 #..............#
 4 #====CCCC=====.#     barra: PassSlot01–04 · SeasoningStation (cols 5–8) · PassSlot05–09 · hueco col 14
 5 #..............#
 6 B..............#     BoxShelf (pared izquierda del servicio)
 7 B..........a...#     Player1 (a)
 8 #..............#
 9 #..............#
10 ###1#2##3#4#####     OrderStand1–4
```
Cambio respecto a la planta B publicada: la estación ocupa **4 celdas** (cols 5–8, 4 m) en lugar
de 2, con el **mismo centro** (x ≈ 0,2), porque la feature pide 4 dispensadores a ≥ 0,9 m entre
centros más el cuenco (≈ 3,6 m útiles). El pasaplatos queda en 9 `Slot` (cols 1–4 y 9–13).

```
Level01 (Node3D)                         scenes/levels/level.gd  (común, extends Node)
│   @export round_config = data/config/round_config.tres   (300 s, D5)
│   @export order_catalog = data/orders/order_catalog.tres
│   @export stands = [OrderStand1..4]
├── Environment          entities/environment/environment.tscn     WorldEnvironment + DirectionalLight3D [8]
├── KitchenLayout        entities/environment/kitchen_layout.tscn  suelo 16 × 11, paredes y la barra de la fila 4
│                        (cols 1–13; hueco de 1 m en la col. 14), todo en la capa world [3/8; M2b]
├── Stations (Node3D)
│   ├── OctopusStorage   entities/stations/octopus_storage.tscn    celda (2, 0)  [6]
│   ├── CachelosStorage  entities/stations/cachelos_storage.tscn   celda (3, 0)  [M1]
│   ├── Kitchen          entities/stations/kitchen.tscn            celda (5, 0)  [6]
│   ├── Kitchen2         entities/stations/kitchen.tscn            celda (7, 0)  [M2b] segunda olla de 2 plazas (D9)
│   ├── PassSlot01..04   entities/stations/slot.tscn               celdas (1..4, 4) pasaplatos, sin initial_item [M2b]
│   ├── SeasoningStation entities/stations/seasoning_station.tscn  cols 5–8 de la fila 4, centro x ≈ 0,2, z ≈ 0,0;
│   │                    %PassSide hacia la cocina (z−), %OperatorSide hacia el servicio (z+)  [M2b]
│   ├── PassSlot05..09   entities/stations/slot.tscn               celdas (9..13, 4)  [M2b]
│   ├── BoxShelf         entities/stations/box_shelf.tscn          celdas (0, 6–7), de frente al servicio (+x)  [6; M2b]
│   ├── OrderStand1      entities/stations/order_stand.tscn  slot_id = 1  celda (3, 10)  [6]
│   ├── OrderStand2      …                                   slot_id = 2  celda (5, 10)
│   ├── OrderStand3      …                                   slot_id = 3  celda (8, 10)
│   └── OrderStand4      …                                   slot_id = 4  celda (10, 10)
├── Characters (Node3D)
│   ├── Player1          entities/player/player.tscn  player_index = 1, controlled_by = 1, items_root = Items, celda (11, 7) (servicio)  [4]
│   └── Player2          entities/player/player.tscn  player_index = 2, celda (2, 2) (cocina)                                         [M2]
├── CharacterSwitcher    entities/player/character_switcher.tscn  (común) characters = [Player1/%Control, Player2/%Control]  [M2]
├── Items (Node3D)       destino de los objetos soltados (ADR-003 §6)
├── LevelAudio           entities/environment/level_audio.tscn  (común) BG, FOL y cue de fase; process_mode ALWAYS  [M3]
├── CameraRig            entities/camera/camera_rig.tscn  Camera3D ortográfica fija (size 12,74, D14) [4]
└── UI (CanvasLayer)
    ├── HUD              ui/hud/hud.tscn                          [7]
    ├── OrderTicketsPanel ui/tickets/order_tickets_panel.tscn     [7]
    ├── PauseMenu        ui/menus/pause_menu.tscn   process_mode ALWAYS  [7]
    └── GameOver         ui/menus/game_over.tscn    oculto hasta round_finished  [7]
```
No hay `SpiceShelf` ni ningún `SeasoningItem` (AC18 de la feature): los únicos puntos donde cambia
el condimento de una caja son los 4 dispensadores y el cuenco de `SeasoningStation`. El nivel no
sobrescribe nada dentro de la estación (ni datos ni marcadores): solo su transformación.

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
├── %ActiveIndicator (MeshInstance3D)      aro bajo el personaje [M2]
└── %Feedback (FeedbackPlayer)             cues pick_up / drop desde item_picked_up / item_dropped de %HoldComponent [M3]
```
Un único detector (B7). Movimiento 5 m/s y giro en `PlayerConfig.tres`.

### `entities/items/`
```
octopus.tscn [6]   Octopus (RigidBody3D, capa interactable; grupos pickable, interactable)    ingredient.gd  class_name Ingredient
                   ├── CollisionShape3D, Model, %AnchorPoint (Marker3D)
                   ├── %Highlightable (Node)                                components/highlightable.gd
                   └── %AmountBar                                           ui/widgets/world_progress_bar.tscn
box.tscn [6]       Box (RigidBody3D; grupos pickable, interactable, box [M2b])  box.gd  class_name Box  @export data: BoxData
                   ├── CollisionShape3D, Model, %AnchorPoint, %AnimationPlayer (box_open / box_close), Lid
                   ├── %Highlightable, %FillBar (world_progress_bar.tscn)
                   ├── %CutAudio, %SeasonAudio (AudioStreamPlayer3D)  → M3: un %Feedback (FeedbackPlayer): cut, season, unseason
                   └── %BadgeRow (Node3D)  badge_row.gd  class_name BadgeRow  [M2b, PUL-059]
                       @export box: Box (el padre), @export style: BoxBadgeStyle = data/config/box_badges.tres
                       hijos Sprite3D creados en código, uno por condimento: billboard, no_depth_test,
                       círculo de SeasoningData.color + SeasoningData.icon en blanco; el picante lleva
                       además style.hot_mark. Fila centrada a style.badge_height sobre la tapa,
                       style.badge_icon_px por pegatina y style.badge_gap_px entre ellas.
                       Orden: SeasoningRules.canonical_order(box.get_contents().seasonings). Se rehace al
                       oír seasoned / seasoning_removed; sin condimentos, oculta.
                       get_shown() -> Array[SeasoningData]  (lo que muestra, en orden; para tests)
cachelos.tscn [M1] Cachelos (RigidBody3D; grupos pickable, interactable)     ingredient.gd  data = data/ingredients/cachelos.tres
seasoning.tscn [6] BAJA en M2b (PUL-061, §7). Seasoning (RigidBody3D; pickable, interactable)  seasoning_item.gd
```
Tres cajas = una escena + `.tres` (`data/boxes/{small,medium,large}.tres`). Los cinco
condimentos son datos (`data/seasonings/*.tres`) que usan los dispensadores, el cuenco, la fila de
la caja y el ticket; ya no hay un objeto de mundo por condimento.

Caja (API del contrato con la estación, M2b, PUL-057; ADR-003 §8.3):
`toggle_seasoning(seasoning: SeasoningData, swap_exclusive: bool) -> SeasoningRules.Rejection`,
`remove_seasoning(seasoning: SeasoningData) -> bool`, `has_seasoning()`, `is_full()`,
`get_contents()`. `interact()` corta (D1) o se coge; con cualquier otra cosa en la mano consume la
pulsación sin efecto (ya no condimenta, AC12).

### `entities/stations/`
```
item_spawner.gd [6]   script genérico (no escena): @export scene: PackedScene; @export data: Resource
octopus_storage.tscn  OctopusStorage (StaticBody3D; grupo interactable)  item_spawner.gd  scene = octopus.tscn
                      ├── CollisionShape3D, Model (nevera), %Highlightable
kitchen.tscn          Kitchen (StaticBody3D; grupos interactable, kitchen)  cooking_station.gd
                      ├── CollisionShape3D, Model (olla + fogón), %AnchorPoint, %Highlightable
                      ├── %CookBar (world_progress_bar.tscn), %BoilAudio (AudioStreamPlayer3D, bus SFX)
                      ├── Model/Fire, Model/Steam (GPUParticles3D)  [M3] vapor solo con plazas cociendo; fuego bajo en reposo, vivo al cocer
                      ├── %Feedback (FeedbackPlayer)  [M3] cook_start, cook_done, burn_warning, burnt, discard
                      └── (reloj interno en _physics_process, sin nodo Timer; cook_time desde IngredientData; se congela con la pausa)
                          [M3] tras cooking_finished la plaza sigue contando: warn_time → burn_warned (barra visible y
                          parpadeando), burn_time → Ingredient.set_burnt() + burnt; mano vacía: desecha el BURNT más
                          antiguo (discarded, queue_free) antes de dar un cocido FIFO
box_shelf.tscn        BoxShelf (StaticBody3D)  Model (mueble)
                      ├── SmallSpawner  (StaticBody3D; interactable)  item_spawner.gd  scene = box.tscn, data = small.tres
                      ├── MediumSpawner …                                                 data = medium.tres
                      └── LargeSpawner  …                                                 data = large.tres
slot.tscn [5]         Slot (StaticBody3D; grupo interactable)  slot.gd  @export initial_item: PackedScene
                      │   @export accepted_group: StringName = &""  [M2b] vacío = acepta cualquier objeto; si no,
                      │   lo que no esté en el grupo se rechaza consumiendo la pulsación (ADR-003 §8.2)
                      ├── CollisionShape3D, Model, %Anchor (Marker3D), %Highlightable (retícula)
cachelos_storage.tscn CachelosStorage (StaticBody3D; grupo interactable)  item_spawner.gd  scene = cachelos.tscn  [M1]
                      ├── CollisionShape3D, Model (cachelera), %Highlightable
spice_shelf.tscn      BAJA en M2b (PUL-061, §7). SpiceShelf con SaltSlot / PaprikaSlot / HotPaprikaSlot
order_stand.tscn      OrderStand (StaticBody3D; grupo interactable)  order_stand.gd  class_name OrderStand  @export slot_id: int
                      ├── CollisionShape3D, Model (order_stand)
                      ├── %DeliveryZone (Area3D, capa delivery_zone)   body_entered → intenta entregar (B12: también al interactuar)
                      ├── %OrderLabel (Label3D, billboard)             "#id" o "–"
                      └── %OkAudio, %ErrorAudio (AudioStreamPlayer3D)  → M3: un %Feedback (FeedbackPlayer), pulse_target = el puesto:
                          deliver_ok (POP), deliver_error (SHAKE), order_new (POP de %OrderLabel, delay), order_expired (SHAKE de %OrderLabel)
```
Un puesto sin comanda (también los que una fase aún no abre, M3) muestra «–»; entregar en él da
`delivery_rejected(slot_id, −1, 0)` como hoy.
Los modelos de nevera, olla, fogón y mesas dependen de D6 (Pandazole o sustitutos).

### `entities/stations/` — estación de condimentos [M2b] (D18, ADR-003 §8)
Diseño: `docs/design/features/estacion-condimentos.md` y boceto `docs/evidence/PUL-040/boceto-estacion.svg`.
Escenas y scripts de PUL-058; el `Model` definitivo, de PUL-052 (sin tocar el resto de nodos).
Frente del modelo hacia −Z (biblia de arte) = lado de pase; +Z = lado de condimentar.

```
seasoning_station.tscn
SeasoningStation (StaticBody3D, capa world; sin grupos)   seasoning_station.gd  class_name SeasoningStation
│   @export data: SeasoningStationData = data/config/seasoning_station.tres
│   side_of(floor_position: Vector2) -> StationSide.Side       (ADR-003 §8.1)
│   get_box() -> Box                                           caja de la bandeja o null
│   conecta rejected de los 4 dispensadores y del cuenco → %ErrorAudio + sacudida del emisor
├── CollisionShape3D (Box ≈ 4 × 1,1 m)   mostrador: no se cruza
├── Model                                placeholder de primitivas (PUL-058) → .glb de PUL-052
├── %PassSide (Marker3D)                 en el suelo, centro del pasillo del lado de pase (z− local)
├── %OperatorSide (Marker3D)             en el suelo, centro del pasillo del lado de condimentar (z+ local)
├── Tray        instancia de slot.tscn   accepted_group = &"box", sin initial_item; centro del mostrador,
│                                        hacia el lado de pase; alcanzable desde los dos lados (AC9)
├── Dispensers (Node3D)                  fila hacia el lado de condimentar, ≥ 0,9 m entre centros
│   ├── SweetPaprika  seasoning_dispenser.tscn  seasoning = data/seasonings/paprika.tres
│   ├── HotPaprika    seasoning_dispenser.tscn  seasoning = data/seasonings/hot_paprika.tres
│   ├── Salt          seasoning_dispenser.tscn  seasoning = data/seasonings/salt.tres
│   └── Oil           seasoning_dispenser.tscn  seasoning = data/seasonings/oil.tres
│                     (cada uno: station = SeasoningStation, override de referencia dentro de la escena)
├── CachelosBowl  cachelos_bowl.tscn     extremo del mostrador; station = SeasoningStation
└── %ErrorAudio (AudioStreamPlayer3D)    sonido de rechazo (dispensadores, cuenco) → M3: %Feedback (FeedbackPlayer), cue season_error

seasoning_dispenser.tscn
SeasoningDispenser (StaticBody3D, capa interactable; grupo interactable)   seasoning_dispenser.gd  class_name SeasoningDispenser
│   @export seasoning: SeasoningData
│   @export station: SeasoningStation
│   is_reachable_from(floor_position: Vector2, holder: Holder) -> bool   lado de condimentar
│                     (o los dos con data.operator_side_only = false)
│   can_interact(actor) -> bool   true si hay holder; interact(actor) -> bool  siempre consume (ADR-003 §8.2)
│   antirrebote: data.toggle_guard s por dispensador, con reloj inyectable para tests (sin await)
│   signal rejected(reason: SeasoningRules.Rejection)
├── CollisionShape3D, Model (bote fijo del condimento; color de SeasoningData)
└── %Highlightable

cachelos_bowl.tscn
CachelosBowl (StaticBody3D, capa interactable; grupo interactable)   cachelos_bowl.gd  class_name CachelosBowl
│   @export seasoning: SeasoningData = data/seasonings/cachelos.tres
│   @export station: SeasoningStation
│   var stock: int  (0..data.cachelos_stock_max; empieza en data.cachelos_initial_stock)
│   is_reachable_from: lado de condimentar, o cualquier lado con algo en la mano
│   interact: mano con un Ingredient cocido cuyo data.as_seasoning.same_as(seasoning) → +data.cachelos_portions_per_item
│             y libera los cachelos; mano vacía → alterna cachelos en la caja de la bandeja (±1 ración)
│   signal rejected(reason: SeasoningRules.Rejection); signal stock_changed(stock: int)
├── CollisionShape3D, Model (cuenco)
├── %Portions (Node3D)   una malla por ración, visibles según stock
└── %Highlightable
```
Cada dispensador y el cuenco son escenas propias para que cada uno tenga su `%Highlightable`
(hijo directo, como lo busca `InteractionDetector`) y para que las 4 variantes sean una escena +
`SeasoningData` (ADR-003 §1). La caja en la bandeja se sigue pudiendo cortar (D1): el detector
sustituye `Tray` por la caja guardada, como en cualquier `Slot`.

### `entities/environment/level_audio.tscn` [M3] (común, ADR-006 §2)
```
LevelAudio (Node, process_mode ALWAYS)   level_audio.gd
│   @export music: AudioStream, @export ambience: AudioStream (bucles de PUL-068)
│   @export map: AudioFeedbackMap = data/audio/feedback_map.tres
│   round_started → arranca %Music y %Ambience; phase_changed(n ≥ 2) → %PhaseCue con la cue phase_up
├── %Music     (AudioStreamPlayer, bus Music)
├── %Ambience  (AudioStreamPlayer, bus Ambience)
└── %PhaseCue  (AudioStreamPlayer, bus SFX, process_mode INHERIT)
```
`ALWAYS` en la raíz para que BG y FOL sigan en pausa, atenuados por `AudioDirector` (AC3).

### `components/feedback_player.gd` [M3] (específico, ADR-006 §4)
`FeedbackPlayer extends AudioStreamPlayer3D` (`class_name`). `@export map: AudioFeedbackMap`,
`@export pulse_target: Node3D` (por defecto el padre). `bus` = `SFX`, `max_polyphony` ≥ 2.
`play_cue(cue: StringName, target: Node3D = null)`: un `play()` por llamada, `signal played(cue)`,
respuesta visual `POP`/`SHAKE` con un `Tween` del nodo (`visual_time` ≥ 0,3 s, se congela en pausa).

## 4. Escenas de UI [7]
```
ui/menus/main_menu.tscn      MainMenu (Control)        main_menu.gd   Individual / Local 2P (M2) / Salir; foco inicial en Individual
ui/menus/pause_menu.tscn     PauseMenu (Control)       pause_menu.gd  Reanudar / Salir; escucha `pause`, pause_changed, device_disconnected
ui/menus/game_over.tscn      GameOver (Control)        game_over.gd   escucha round_finished; Reintentar / Salir
ui/menus/menu_panel.tscn     panel y Theme comunes (sustituye a PanelPauseBase.prefab)
ui/hud/hud.tscn              HUD (Control)             hud.gd         tiempo, cajas/minuto (M1: recaudación)
ui/tickets/order_tickets_panel.tscn  (Control)         order_tickets_panel.gd  escucha orders_reset / order_generated / order_completed / order_expired; get_active_orders() para reconstruir
ui/tickets/order_ticket.tscn         (PanelContainer)  order_ticket.gd   "#id" + ticket_entry + %PatienceBar (TextureProgressBar) que solo pinta order_patience_changed de su order_id; sin contador propio (M1)
ui/tickets/ticket_entry.tscn         (HBoxContainer)   ticket_entry.gd   receta + condimentos; M2b (PUL-060): condimentos en SeasoningRules.canonical_order() y como pegatinas con BoxBadgeStyle (mismo icono y marca de llama que %BadgeRow)
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
data/seasonings/{salt,paprika,hot_paprika,oil,cachelos}.tres  SeasoningData  (M2b: sort_order pimentón 0, sal 1, aceite 2, cachelos 3)
data/config/seasoning_station.tres               SeasoningStationData [M2b] (toggle_guard 0.25, cachelos_stock_max 3,
                                                 cachelos_initial_stock 0, cachelos_portions_per_item 1,
                                                 paprika_swap true, operator_side_only true)
data/config/box_badges.tres                      BoxBadgeStyle [M2b] (badge_icon_px 24, badge_gap_px 3, badge_height 0.35,
                                                 hot_mark = small-fire.svg); lo leen BadgeRow y ticket_entry
data/config/round_config.tres                    RoundConfig    (duration 180 en M0; 300 en M1, D5)
data/config/player_config.tres                   PlayerConfig   (speed 5, rotation_speed 20, detector_radius 2.2: valor efectivo en Level_01 del prototipo; 1,5 en el prefab)
data/config/input_config.tres                    InputConfig    (deadzone 0.2, switch_cooldown 0.2)
```
**M3** (ADR-006):
```
data/config/round_config.tres                    RoundConfig    + phases: Array[PhaseData] (sub-recursos: 0 / ⅓ / ⅔ ·
                                                 2 / 3 / 4 puestos · max_time 90 / 70 / 50), + rng_seed: int (0 = aleatoria)
data/ingredients/{octopus,cachelos}.tres         IngredientData + burn_time (10; 0 = no se quema), warn_time (7)
data/audio/feedback_map.tres                     AudioFeedbackMap (cues: Dictionary[StringName, AudioCue]; claves de ADR-006 §4)
data/audio/audio_mix.tres                        AudioMixConfig (music 0.7, ambience 0.7, sfx 1.0, pause_duck_db −12)
resources/{phase_data,audio_cue,audio_feedback_map,audio_mix_config}.gd   PhaseData, AudioCue, AudioFeedbackMap, AudioMixConfig
core/audio_mix.gd                                AudioMix (núcleo de AudioDirector)
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
| `FeedbackPlayer extends AudioStreamPlayer3D` (`pulse_target: Node3D`) | `extends AudioStreamPlayer2D` (`pulse_target: Node2D`) | Misma API `play_cue()` / `played` y mismo `AudioFeedbackMap` |
| `CameraRig` (`Camera3D` fija) | `Camera2D` fija | |
| `%ActiveIndicator` (aro `MeshInstance3D`) | `Sprite2D` bajo los pies | |
| `%BadgeRow` (`Sprite3D` billboard sin test de profundidad) | `HBoxContainer` o `Sprite2D` bajo un `Node2D` con `z_index` alto | Misma API `get_shown()` |
| `%PassSide` / `%OperatorSide` (`Marker3D`) | `Marker2D` | `StationSide.classify` es el mismo (`Vector2`) |

## 7. Bajas por la estación de condimentos (D18, M2b)

| Qué | Dónde | La ejecuta | Nota |
|---|---|---|---|
| `SpiceShelf` | `entities/stations/spice_shelf.tscn`, su instancia en `level_01.tscn` y en los sandboxes (`stations_sandbox`, `kitchen_sandbox`, `player_sandbox`, `items_sandbox`, `scale_check`) | PUL-061 | La sustituye `SeasoningStation` |
| Bote de condimento | `entities/items/seasoning.tscn`, `entities/items/seasoning_item.gd` (`SeasoningItem`) | PUL-061 | Sale de los grupos `pickable`/`interactable` (ADR-003 §4) |
| Placeholder del bote | `assets/models/placeholders/condiment_jar.tscn` | PUL-061 | Si lo usa el `Model` de un dispensador, se conserva (decide PUL-058) |
| Slots de bote | `SaltSlot`, `PaprikaSlot`, `HotPaprikaSlot` (y los de aceite si existen) | PUL-061 | Con `spice_shelf.tscn` |
| `Slot.initial_item_data` | `entities/stations/slot.gd` | PUL-061 | Solo lo usaban los botes. `initial_item` se mantiene |
| Condimentar al interactuar con la caja | `box.gd`: ramas de `SeasoningItem` en la mano y de cachelos cocidos (`as_seasoning`) | PUL-061 | PUL-057 añade `toggle_seasoning` sin quitarlas aún. `IngredientData.as_seasoning` se queda: lo usa el cuenco |
| Tests de botes | `test_seasoning.gd`, `test_shelves.gd` y partes de `test_box.gd`, `test_cachelos.gd`, `test_slot.gd`, `test_items_contract.gd`, `test_m1_flow.gd`, `test_m2_flow.gd`, `test_kitchen_flow.gd`, `test_parity_smoke.gd`, `test_order_stand.gd`, `test_scale_check.gd`, `test_box_on_slot.gd` | PUL-061 (y PUL-057 en `test_box.gd`) | Se reescriben contra la estación |

Se mantienen: `SeasoningData` y los cinco `.tres`, `BoxContents`, `OrderValidator` (coincidencia
exacta), `IngredientData.as_seasoning` y la señal local `seasoned`.

## 8. Buses de audio (M3, ADR-006 §1)

`godot/default_bus_layout.tres` (lo carga Godot sin tocar `project.godot`):
`Master` ← `Music`, `Ambience`, `SFX`. Todo `AudioStreamPlayer*` de las escenas declara bus
(`SFX` salvo `%Music`/`%Ambience` de `LevelAudio`); ninguno en `Master`. Solo `AudioDirector`
escribe `AudioServer.set_bus_volume_db`.
