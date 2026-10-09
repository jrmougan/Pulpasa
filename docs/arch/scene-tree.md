# Árbol de escenas objetivo de M0

- **Estado:** propuesto (contrato; ver ADR-003)
- **Ficha:** PUL-003; enmienda de la estación de condimentos y la planta B en PUL-056
  (2026-10-05, D18/D19, ADR-003 §8), **pendiente del gate humano**: §2, §3 (caja, slot, estación),
  §5, §6 y §7 (bajas). Lo marcado **M2b** lo implementan PUL-057..PUL-061.
- **Enmienda M3** (PUL-066, 2026-10-06, ADR-006), **pendiente del gate humano**: `AudioDirector`
  (§1), `LevelAudio` (§2), `%Feedback` y quemado en las entidades (§3), datos de audio, fases y
  quemado (§5), equivalencia 2D (§6) y §8 (buses). Lo marcado **M3** lo implementan PUL-069..071.
- **Enmienda D23** (PUL-093, 2026-10-07, ADR-003 §9), **pendiente de la revisión del producer**:
  estación sin `Tray` y dispensadores/cuenco sobre la caja en la mano (§3), 6 `PassSlot` marcados y
  hueco de la barra a x ≈ 3,2 (§2; montado en x 2,8…4,2, enmienda PUL-103), indicador de entrega en `order_stand.tscn` (§3), `BoxData` y
  `StandPalette` (§5), bajas (§7). Además recoge `Bulbs` y `Vignette` de `environment.tscn` (PUL-073,
  pendiente del QA de M3b). Lo marcado **M3c** lo implementan PUL-097..PUL-101.
- **Enmienda PUL-103** (2026-10-09, ADR-003 §9.4–§9.5), **aprobada por el responsable en gate
  humano**: recoge lo que cambió al implementar M3c. Pasaplatos 3 + 3 y hueco de 1,4 m en x 2,8…4,2
  (§2, PUL-101), marca de entrega `DeliveryFrame` dentro del `Model` del puesto y radio al borde de
  la cápsula (§3, PUL-100), colisión de la estación de 5,2 m, raíz de dispensadores y cuenco
  desplazada respecto al arte y antirrebote con reloj de juego (§3, PUL-097), soltar bloqueado por
  `world` (ADR-003 §9.5, PUL-101).

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

## 2. `scenes/levels/level_01.tscn` [8; planta B en M2b; D23 en M3c]

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
 4 #PPPCCCCCC.PPP##     M3c (D23, PUL-101): PassSlot01–03 · SeasoningStation (x −2,4…2,8) · hueco x 2,8…4,2 · PassSlot04–06
 5 #..............#
 6 B..............#     BoxShelf (pared izquierda del servicio)
 7 B..........a...#     Player1 (a)
 8 #..............#
 9 #..............#
10 ###1#2##3#4#####     OrderStand1–4
```
Cambio respecto a la planta B publicada: la estación ocupa **4 celdas** (cols 5–8, 4 m) en lugar
de 2, con el **mismo centro** (x ≈ 0,2), porque la feature pide 4 dispensadores a ≥ 0,9 m entre
centros más el cuenco (≈ 3,6 m útiles). ~~El pasaplatos queda en 9 `Slot` (cols 1–4 y 9–13).~~

**M3c (D23, N-A y B-A; ADR-003 §9.5).** En el dibujo, `P` = `PassSlot`, `C` = estación. El hueco
de la barra pasa de la col. 14 (x 7,7, ahora cerrada) a un hueco de **1,4 m libres, x 2,8…4,2
(centro 3,5)**, entre el extremo este de la colisión de la estación (x 2,8) y el tramo este de la
barra, que se cierra hasta la pared derecha (PUL-101; en el dibujo, col. 10). Hay **exactamente 6**
`PassSlot`, cada uno con su marca visible, y ningún otro `Slot` en la barra (R11), repartidos
**3 + 3** (PUL-101; enmienda PUL-103, antes «4 + 2»): `PassSlot01..03` al oeste de la estación
(x −5,3 / −4,3 / −3,3) y `PassSlot04..06` al este del hueco (x 4,7 / 5,7 / 6,7). Los 4 del oeste
de M2b no caben: la estación mide 5,2 m (x −2,4…2,8) y pisaba el antiguo `PassSlot04` (x −2,3).
Son contrato el número, los nombres `PassSlot01..06`, la marca y que fuera de ellos no se deja nada
(ADR-003 §9.5); las posiciones son las de `level_01.tscn` y las prueba `test_level_01.gd` (R11,
R14: rodeo 7,93 m), con `level_walker.gd::GAP_X` = 3,5.

```
Level01 (Node3D)                         scenes/levels/level.gd  (común, extends Node)
│   @export round_config = data/config/round_config.tres   (300 s, D5)
│   @export order_catalog = data/orders/order_catalog.tres
│   @export stands = [OrderStand1..4]
├── Environment          entities/environment/environment.tscn     LevelEnvironment: WorldEnvironment, Sun, Bulbs,
│                        Vignette y Model (§3) [8; M3b]
├── KitchenLayout        entities/environment/kitchen_layout.tscn  suelo 16 × 11, paredes y la barra de la fila 4
│                        (cols 1–13; hueco de 1 m en la col. 14), todo en la capa world [3/8; M2b]
│                        M3c (D23, PUL-101): BarKitchenSide x −5,8…−1,8, hueco libre x 2,8…4,2 (centro 3,5)
│                        y BarServiceSide x 4,2…8,2 hasta la pared derecha (col. 14 cerrada); umbral
│                        GapThreshold (pass_threshold, PUL-095) en el hueco para que no parezca más barra
├── Stations (Node3D)
│   ├── OctopusStorage   entities/stations/octopus_storage.tscn    celda (2, 0)  [6]
│   ├── CachelosStorage  entities/stations/cachelos_storage.tscn   celda (3, 0)  [M1]
│   ├── Kitchen          entities/stations/kitchen.tscn            celda (5, 0)  [6]
│   ├── Kitchen2         entities/stations/kitchen.tscn            celda (7, 0)  [M2b] segunda olla de 2 plazas (D9)
│   ├── PassSlot01..03   entities/stations/slot.tscn               x −5,3 / −4,3 / −3,3, z 0 (cols 1–3, fila 4); sin initial_item [M2b; M3c]
│   ├── SeasoningStation entities/stations/seasoning_station.tscn  fila 4, centro x 0,2, z 0,0; colisión x −2,4…2,8 (M3c);
│   │                    %PassSide hacia la cocina (z−), %OperatorSide hacia el servicio (z+)  [M2b; sin Tray en M3c]
│   ├── PassSlot04..06   entities/stations/slot.tscn               al este del hueco: x 4,7 / 5,7 / 6,7, z 0 (cols 11–13)  [M3c, PUL-101]
│   │                    (M2b tenía PassSlot01..04 en las cols 1–4 y 05..09 en las cols 9–13; quedan 6, 3 + 3, §7)
│   │                    Sin overrides de Model/Body: la marca pass_mark es parte de slot.tscn (§3)
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
sobrescribe nada dentro de la estación (ni datos ni marcadores): solo su transformación. Desde D23,
con una caja en la mano, en el tramo de la estación solo son objetivo los dispensadores y el cuenco
(R7): no hay `Slot` en esas 4 celdas.

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
pulsación sin efecto (ya no condimenta, AC12). D23 no cambia esta API: el dispensador y el cuenco la
llaman sobre la caja **de la mano** del actor en vez de la de la bandeja.

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
                      │   lo que no esté en el grupo se rechaza consumiendo la pulsación (ADR-003 §8.2).
                      │   Sin usuario en el nivel desde D23 (lo usaba Tray); se conserva
                      ├── CollisionShape3D, Model, %Anchor (Marker3D), %Highlightable (retícula)
                      │   [M3c, D23] Model = marca pass_mark de counters (PUL-095; esquinas papel/marino,
                      │   ≥ 18 px de lado a 1280×720, R11) en lugar del placeholder table_square; el nivel
                      │   deja de ocultarlo con overrides (ADR-003 §9.5). Lo integra PUL-101
cachelos_storage.tscn CachelosStorage (StaticBody3D; grupo interactable)  item_spawner.gd  scene = cachelos.tscn  [M1]
                      ├── CollisionShape3D, Model (cachelera), %Highlightable
spice_shelf.tscn      BAJA en M2b (PUL-061, §7). SpiceShelf con SaltSlot / PaprikaSlot / HotPaprikaSlot
order_stand.tscn      OrderStand (StaticBody3D; grupo interactable)  order_stand.gd  class_name OrderStand  @export slot_id: int
                      ├── CollisionShape3D, Model (order_stand)
                      ├── %DeliveryZone (Area3D, capa delivery_zone)   body_entered → intenta entregar (B12: también al interactuar)
                      ├── %OrderLabel (Label3D, billboard)             "#id" o "–"  [M3c: sobre la placa papel del modelo, PUL-096]
                      │   [M3c, PUL-100] la marca de la zona es la malla DeliveryFrame dentro de Model (.glb de PUL-096);
                      │   no hay nodo %DeliveryMark. order_stand.gd la halla con find_child("DeliveryFrame") y alterna
                      │   material_override: @export material_off / material_on (encendido: albedo y emisión del color
                      │   de palette.color_for(slot_id))
                      ├── %ProximityArea (Area3D, collision_layer 0, máscara player)  [M3c, D23]
                      │   └── CollisionShape3D (cilindro, radio 2,0 m, centrado en la zona; R12). Se mide al borde
                      │       de la cápsula del jugador (radio 0,21): enciende con su centro a ≲ 2,21 m (PUL-100)
                      └── %OkAudio, %ErrorAudio (AudioStreamPlayer3D)  → M3: un %Feedback (FeedbackPlayer), pulse_target = el puesto:
                          deliver_ok (POP), deliver_error (SHAKE), order_new (POP de %OrderLabel, delay), order_expired (SHAKE de %OrderLabel)
```
**Indicador de entrega (M3c, D23, ADR-003 §9.4; PUL-100).** `order_stand.gd` gana
`@export var palette: StandPalette = data/config/stand_palette.tres`, `@export var material_off` /
`material_on` (`delivery_zone_off.tres` / `delivery_zone_on.tres`) e `is_zone_lit() -> bool`. Lo
que se ilumina es `DeliveryFrame` del `Model`, no un nodo propio (enmienda PUL-103). La
zona está encendida mientras algún cuerpo de `%ProximityArea` tenga un `%InteractionComponent` cuyo
`holder` lleve una `Box` que pase `_zone_accepts` (comanda viva del puesto + `OrderValidator.matches`,
lo mismo que ya decide la entrega sola). Se evalúa en `_physics_process` solo con cuerpos en el
área; se apaga al vaciarse y con `orders_reset` / `order_completed` / `order_expired` del puesto. No
entrega: eso sigue en `%DeliveryZone` e `interact`. Sin señales nuevas.
Un puesto sin comanda (también los que una fase aún no abre, M3) muestra «–»; entregar en él da
`delivery_rejected(slot_id, −1, 0)` como hoy.
Los modelos de nevera, olla, fogón y mesas dependen de D6 (Pandazole o sustitutos).

### `entities/stations/` — estación de condimentos [M2b; al paso en M3c] (D18, D23, ADR-003 §8–§9)
Diseño: `docs/design/features/estacion-condimentos.md` y boceto `docs/evidence/PUL-040/boceto-estacion.svg`.
Escenas y scripts de PUL-058; el `Model` definitivo, de PUL-052 (sin tocar el resto de nodos).
Frente del modelo hacia −Z (biblia de arte) = lado de pase; +Z = lado de condimentar.
**M3c (D23, PUL-097; modelos de PUL-094):** sin `Tray`; la caja se lleva en la mano y la estación
es una línea de 4 dispensadores (≥ 1,0 m entre centros, orden del ticket: dulce, picante, sal,
aceite) y el cuenco. Quién es objetivo con qué en la mano: ADR-003 §9.1 (resumen abajo).

```
seasoning_station.tscn
SeasoningStation (StaticBody3D, capa world; sin grupos)   seasoning_station.gd  class_name SeasoningStation
│   @export data: SeasoningStationData = data/config/seasoning_station.tres
│   side_of(floor_position: Vector2) -> StationSide.Side       (ADR-003 §8.1)
│   get_box() -> Box, get_tray() -> Slot                       BAJA en M3c (D23): no hay bandeja
│   conecta rejected de los 4 dispensadores y del cuenco → %Feedback (season_error) + sacudida del emisor
├── CollisionShape3D (Box 5,2 × 1,1 × 1,12 m, PUL-097)   mostrador, capa world: no se cruza ni se suelta encima
├── Model                                placeholder de primitivas (PUL-058) → .glb de PUL-052
├── %PassSide (Marker3D)                 en el suelo, centro del pasillo del lado de pase (z− local)
├── %OperatorSide (Marker3D)             en el suelo, centro del pasillo del lado de condimentar (z+ local)
├── Tray        BAJA en M3c (D23). Era instancia de slot.tscn con accepted_group = &"box"
├── Dispensers (Node3D)                  fila hacia el lado de condimentar, ≥ 0,9 m entre centros (M3c: 1,0 m,
│                                        raíces en x −2 / −1 / 0 / 1, z −0,1; cuenco en x 2, z −0,1)
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
│   is_reachable_from(floor_position: Vector2, holder: Holder) -> bool
│                     M3c (D23): true solo si holder lleva una Box (llena o a medio cortar) y desde el lado
│                     de condimentar (o los dos con data.operator_side_only = false); mano vacía u otra cosa: false
│   can_interact(actor) -> bool   M3c: true si actor.holder lleva una Box; interact(actor) -> bool  siempre consume
│                     (ADR-003 §8.2): caja a medio cortar → rejected(BOX_NOT_FULL); llena → box.toggle_seasoning
│                     sobre la caja de la mano (con paprika_swap); la caja sigue en la mano
│   antirrebote: data.toggle_guard s por dispensador; M3c (PUL-097): reloj de juego (_game_time acumulado en
│                     _physics_process, se congela en pausa y sigue Engine.time_scale; sin Time.get_ticks_usec),
│                     clock: Callable inyectable para tests (sin await)
│   signal rejected(reason: SeasoningRules.Rejection)
├── CollisionShape3D, Model (bote fijo del condimento; color de SeasoningData)
│   [M3c, PUL-097] el Model está en z +0,45 local: la raíz (objetivo del detector) queda 0,45 m hacia el
│   pase respecto al arte para que las franjas de selección no tengan huecos (R8). Para anclar algo al
│   arte del dispensador, usar Model, no global_position de la raíz
└── %Highlightable

cachelos_bowl.tscn
CachelosBowl (StaticBody3D, capa interactable; grupo interactable)   cachelos_bowl.gd  class_name CachelosBowl
│   @export seasoning: SeasoningData = data/seasonings/cachelos.tres
│   @export station: SeasoningStation
│   var stock: int  (0..data.cachelos_stock_max; empieza en data.cachelos_initial_stock)
│   is_reachable_from (M3c, D23): true con cachelos cocidos en la mano (Ingredient cocido cuyo
│             data.as_seasoning.same_as(seasoning)) desde cualquier lado; con una Box **llena** en la mano
│             solo desde el lado de condimentar; con cualquier otra cosa (mano vacía, pulpo, cachelos crudos
│             o quemados, caja a medio cortar) false
│   interact: cachelos cocidos → +data.cachelos_portions_per_item (máx. stock_max) y los libera; caja llena →
│             alterna cachelos en la caja de la mano (±1 ración; BOWL_EMPTY / BOWL_FULL); antirrebote como el
│             dispensador (reloj de juego propio, _game_time; PUL-097)
│   signal rejected(reason: SeasoningRules.Rejection); signal stock_changed(stock: int)
├── CollisionShape3D, Model (cuenco)   [M3c, PUL-097] Model en z +0,25 local: la raíz queda 0,25 m hacia el
│                                      pase respecto al arte; para anclar algo al cuenco, usar Model
├── %Portions (Node3D)   M2b: una malla por ración, visibles según stock. M3c (PUL-094): estados
│                        Portions0..Portions4 (sub-mallas del .glb); solo es visible Portions<stock>
└── %Highlightable
```
Cada dispensador y el cuenco son escenas propias para que cada uno tenga su `%Highlightable`
(hijo directo, como lo busca `InteractionDetector`) y para que las 4 variantes sean una escena +
`SeasoningData` (ADR-003 §1). ~~La caja en la bandeja se sigue pudiendo cortar (D1): el detector
sustituye `Tray` por la caja guardada, como en cualquier `Slot`.~~ Desde D23 la caja se corta en un
`PassSlot` (el detector sustituye el `Slot` por la caja guardada, como siempre) y llega llena a la
mano para condimentar.

Objetivo por lo que hay en la mano (M3c, ADR-003 §9.1; «servicio» = lado de condimentar):

| En la mano | Dispensador | Cuenco |
|---|---|---|
| Nada | — | — |
| Caja llena | servicio: alterna | servicio: alterna cachelos |
| Caja a medio cortar | servicio: rechaza `BOX_NOT_FULL` (R3) | — |
| Cachelos cocidos | — | cualquier lado: repone +2 (máx. 4) |
| Pulpo, cachelos crudos o quemados | — | — |

«—» = no es objetivo (ni se resalta).

### `entities/environment/environment.tscn` [8; luz v2 en M3b, PUL-073/PUL-085]
```
Environment (Node3D)   environment.gd  class_name LevelEnvironment
│   @export config: RenderConfig = data/config/render_config.tres  → environment y camera_attributes del WorldEnvironment
├── WorldEnvironment
├── Sun (DirectionalLight3D)        energía 1,34 (la fija test_level_01), sombras
├── Bulbs (Node3D)                  bombillas de la carpa y las guirnaldas: OmniLight3D cálidas
│   ├── BulbTentWest, BulbTentCenter, BulbTentEast        (y ≈ 1,85, sobre la cocina; rango 3,5 m)
│   └── BulbGarlandWest, BulbGarlandEast                  (y ≈ 2,1, laterales del servicio; rango 4,5 m)
├── Vignette (CanvasLayer, layer −1)  viñeta de pantalla por debajo de la UI del nivel
│   └── Overlay (TextureRect, anclas a pantalla completa, mouse_filter IGNORE, GradientTexture2D radial)
└── Model (Node3D)                  suelos, fondos, carpa y atrezo (.glb de PUL-085); solo visual
```
`Bulbs` y `Vignette` son estéticos: ningún script los busca y no tienen grupos ni capas de física.
`Vignette` es un `CanvasLayer` dentro de una escena de mundo (no de `ui/`) porque pertenece al
render del nivel; su capa −1 la deja bajo `UI` (capa 1 por defecto) y no recibe input.

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
**M3c** (D23, ADR-003 §9.3):
```
resources/box_data.gd                            BoxData + short_label: String («S» / «M» / «L»), + icon: Texture2D
                                                 (silueta + letra de assets/textures/ui/box_sizes/, PUL-095); PUL-098
data/boxes/{small,medium,large}.tres             fill_per_press 0.25 / 0.1667 / 0.1 (4 / 6 / 10 pulsaciones, R9),
                                                 short_label e icon rellenos; el ticket los lee por order.data.recipe.box
resources/stand_palette.gd                       StandPalette (común) [PUL-099]: @export colors: Array[Color]
                                                 (índice slot_id − 1), @export fallback: Color,
                                                 func color_for(slot_id: int) -> Color
data/config/stand_palette.tres                   StandPalette: 4 colores de toldo (rojo, azul, amarillo, verde; hex
                                                 de PUL-096); lo leen order_ticket.gd (franja, R13) y order_stand.gd
                                                 (zona encendida, R12)
data/config/seasoning_station.tres               cachelos_portions_per_item 2, cachelos_stock_max 4 (D23, R6);
                                                 resto sin cambios (operator_side_only true, toggle_guard 0.25,
                                                 paprika_swap true, cachelos_initial_stock 0); PUL-097
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
| `%ProximityArea` (`Area3D`, cilindro 2 m) y la malla `DeliveryFrame` del `Model` [M3c] | `Area2D` (círculo 2 m) y `Sprite2D` con dos texturas | Misma regla de `is_zone_lit()` y mismo `StandPalette` |
| `Bulbs` (`OmniLight3D`) | `PointLight2D` (opcional) | Estético |
| `Vignette` (`CanvasLayer` −1 + `TextureRect`) | Igual | Ya es 2D de pantalla |

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

### 7.1 Bajas por la estación al paso (D23, M3c; ADR-003 §9)

| Qué | Dónde | La ejecuta | Nota |
|---|---|---|---|
| `Tray` (y sus overrides de `Model`/`Body`) | `entities/stations/seasoning_station.tscn` | PUL-097 | La caja se condimenta en la mano |
| `SeasoningStation.get_box()`, `get_tray()` | `entities/stations/seasoning_station.gd` | PUL-097 | Dispensador y cuenco leen `actor.holder.get_held_item() as Box` |
| Dispensador y cuenco con la mano vacía | `seasoning_dispenser.gd`, `cachelos_bowl.gd` (`is_reachable_from`, `can_interact`, `_toggle`) | PUL-097 | Matriz de ADR-003 §9.1 |
| Antirrebote con reloj de pared (`engine_seconds`, `Time.get_ticks_usec`) | `seasoning_dispenser.gd`, `cachelos_bowl.gd` | PUL-097 | Reloj de juego; `clock` sigue inyectable |
| `PassSlot07..09` y el hueco de la col. 14 | `level_01.tscn`, `kitchen_layout.tscn` | PUL-101 | Quedan 6 `PassSlot` (3 + 3); hueco x 2,8…4,2 (centro 3,5) |
| Overrides `Model.visible`/`Body.collision_layer` de los `PassSlot` (QA D9) | `level_01.tscn` | PUL-101 | La marca `pass_mark` va en `slot.tscn` (requiere que PUL-101 tenga `slot.tscn` en `owns`/`touches_scenes`) |
| Placeholder `table_square` como `Model` del `Slot` | `entities/stations/slot.tscn` | PUL-101 | Lo sustituye `pass_mark` (PUL-095) |
| Tests de la bandeja | En `owns`: `test_seasoning_station.gd`, `test_cachelos.gd` (PUL-097); `test_level_01.gd`, `level_walker.gd` (`GAP_X`) (PUL-101). **Sin dueño** a 2026-10-07: `test_m2b_station_selection.gd`, `test_m2b_flow.gd`, `test_station_level.gd`, `test_delivery_e2e.gd`, `test_kitchen_flow.gd`, `test_m1_flow.gd`, `test_m2_flow.gd`, `test_parity_smoke.gd` | PUL-097 / PUL-101 (el producer reparte los sin dueño) | Usan `Tray`/`get_tray()`/`get_box()`; se reescriben contra la caja en la mano |

`SeasoningRules.Rejection.NO_BOX` y `HAND_BUSY` quedan en desuso (nadie los emite) sin quitarse del
enum. `Slot.accepted_group` y el grupo `box` se conservan.

## 8. Buses de audio (M3, ADR-006 §1)

`godot/default_bus_layout.tres` (lo carga Godot sin tocar `project.godot`):
`Master` ← `Music`, `Ambience`, `SFX`. Todo `AudioStreamPlayer*` de las escenas declara bus
(`SFX` salvo `%Music`/`%Ambience` de `LevelAudio`); ninguno en `Master`. Solo `AudioDirector`
escribe `AudioServer.set_bus_volume_db`.
