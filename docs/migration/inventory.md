# Inventario de migración Unity → Godot

Ficha: PUL-001. Fuente: `Assets/` (solo lectura) en `bd56649`. Las referencias `archivo:línea`
son relativas a `Assets/Scripts/` salvo que se indique otra ruta.

Lo que se lee aquí es **la especificación**, no el diseño final: si algo choca con
`docs/design/decisions.md`, manda `decisions.md` (se indica en la columna Notas).

## Fases de M0

Fases de `docs/design/roadmap.md` (propuesta aprobada). Cada fila del inventario lleva
una. Coop de 2 jugadores, audio completo y pulido **no** son M0: se marcan `post-M0`. Los bugs y el
código muerto van en su propia sección y no llevan fase (`—`).

| Fase | Contenido |
|---|---|
| 0 | Esqueleto: InputMap, autoloads, GUT, CI (ya existe `godot/` mínimo) |
| 1 | Datos: `Resource` + `.tres` equivalentes a los ScriptableObjects |
| 2 | Lógica pura: `OrderService` (generar, validar, completar, límite 4) y `RoundManager` (tiempo, puntuación) |
| 3 | Assets: FBX, materiales, audio, fuentes; escena de escala |
| 4 | Jugador: movimiento, rotación, AnimationTree, coger/soltar |
| 5 | Interacción: detector con cono y puntuación, slots, resaltado (shader) |
| 6 | Estaciones: spawner de pulpo y cajas, olla, cortar→llenar caja, condimentar, entrega en stand |
| 7 | UI: tickets, HUD, pausa, game over, menú principal y cambio de escena |
| 8 | Montaje de `level_01.tscn`, iluminación, export Linux/Web |

## Resumen del flujo del prototipo

1. `OctopusStorage` (nevera) instancia un pulpo crudo en la mano (`OctopusSwapner.cs:19`).
2. El pulpo se deja en la olla (`Kitchen.cs:19`): `KitchenProgress` cuenta `cookTime` (5 s) y lo marca cocido.
3. Con el pulpo cocido en la mano, cada pulsación de interactuar sobre una caja corta y llena
   (`PlayerInteractionController.cs:41`). Corte sobre la caja (D1). Cajas de `Mueblecajas` (spawners).
4. Con un condimento en la mano sobre una caja llena se aplica (`PlayerInteractionController.cs:80`).
5. Entrar con la caja en el trigger de un `OrderStand` valida contra el pedido de su puesto
   (`OrderStand.cs:19`). 4 puestos (`deliverySlotId` 1–4), máx. 4 pedidos activos (`OrderSystem.cs:28`).
6. `ProductivitySystem` cuenta 180 s y cajas entregadas; `GameOverUI` muestra cajas/minuto.
   En la alpha la métrica pasa a recaudación + estrellas (D2, **M1**) y la partida dura 5 min (D5).

**M0 = paridad.** La fase de cada fila es la de migrar el componente tal como está en Unity (sin sus
bugs). Lo que amplía el prototipo (recaudación/estrellas, paciencia y caducidad, aceite/cachelos,
condimento sí/no) se marca **[M1]** en Notas y no entra en la fase M0 indicada
(ver `docs/design/roadmap.md`).

## 1. Scripts (`Assets/Scripts`, 47 archivos `.cs`)

La ficha habla de 46; en el árbol hay 47 `.cs` propios (`find Assets/Scripts -name '*.cs' | wc -l`).
Se listan todos. Destino: **A** = autoload, **N** = script de nodo, **R** = `Resource`,
**S** = escena `.tscn`, **—** = no se porta.

### Architecture

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Architecture/Bootstrap.cs` | Fija 60 FPS + vsync y registra `IRandomUtility` en QFramework | `project.godot` (`application/run/max_fps`, vsync) | 0 | `IRandomUtility`/`UnityRandomUtility` (:16-27) son código muerto (ver §4). Aleatoriedad: `RandomNumberGenerator` inyectable en `OrderService` para tests |
| `Architecture/PulpasaArchitecture.cs` | Contenedor QFramework; registra `OrderSystem` | Autoloads `EventBus` + `OrderService` (A) | 0 | QFramework no se porta: Architecture → lista de autoloads |

### Characters

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Characters/PlayerController.cs` | Movimiento (CharacterController, 5 m/s), rotación slerp ×20, parámetros Animator `Speed`/`IsHolding`; recibe `OnMove`/`OnInteract` del PlayerInput | `player.gd` (N) en `CharacterBody3D` de `player.tscn` (S) | 4 | `Input.get_vector("p1_*")`. Bloqueo por estado de ronda vía señal de `EventBus`, no referencia a `ProductivitySystem` (:12, :24). `GetComponent` por pulsación (:51) → referencia `@export` |
| `Characters/PlayerHoldSystem.cs` | Coger/soltar: reparenta al `holdPoint`, rigidbody cinemático, capa `HeldObject` | `hold_component.gd` (N) hijo del jugador con `Marker3D` HoldPoint | 4 | Bugs :15-24 y :82-97 (§4). Soltar a 0,6 m delante y 0,6 m arriba (:47) |
| `Characters/PlayerInteractionController.cs` | Despacha interactuar: cortar pulpo sobre caja, condimentar caja, o `Interact` del objetivo, o soltar | `interaction_component.gd` (N) | 5 | Cortar/condimentar deberían vivir en la caja como receptor (fase 6). Dos referencias al detector (:8 y :10) (§4) |

### Commands / Events

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Commands/RequestOrderCommand.cs` | Comando QFramework: pide pedido para un puesto | Método `OrderService.request_order(slot_id)` | 2 | Comando → método del servicio |
| `Events/ObjectDroppedEvent.cs` | Evento soltar objeto | — | — | Nunca se envía ni escucha: código muerto (§4) |
| `Events/ObjectPickedUpEvent.cs` | Evento coger objeto | — | — | Ídem |
| `Events/OrderCompletedEvent.cs` | Pedido completado (+`qualityScore` = `basePoints`) | Señal `EventBus.order_completed(order, score)` | 2 | Nombre/firma final los fija PUL-003 (`docs/arch/signals.md`) |
| `Events/OrderGeneratedEvent.cs` | Pedido generado | Señal `EventBus.order_generated(order)` | 2 | Ídem |

### Game

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Game/Box.cs` | Caja: llenado por pulsación, ingrediente, condimentos aplicados, coger/soltar, modo spawner | `box.gd` (N) en `box.tscn` (S) + `box_spawner.gd` (N) separado | 6 | `fillPerPress` por prefab (S 0.2 / M 0.1 / L 0.05) → mover a `BoxData` (.tres). Separar spawner (:10-11, :150-168) de la caja. NRE :58 (§4). **[M1]** D4: condimento sí/no |
| `Game/Ingredient.cs` | Pulpo: estado de cocción, cantidad restante (100), corte, coger/soltar | `ingredient.gd` (N) en `octopus.tscn` (S) | 6 | `ISeasonable` stub (:100-109) no se porta. Destrucción condicionada a `progressBar` (:46-54) (§4). Errata `remainintCuantity` |
| `Game/InteractableSlot.cs` | Hueco que guarda un objeto alineado por `AnchorPoint`; dispara trigger `Open` | `slot.gd` (N) en `slot.tscn` (S) | 5 | `Marker3D` AnchorPoint en cada objeto colocable |
| `Game/Kitchen.cs` (clase `KitchenStation`) | Olla: acepta pulpo crudo cocinable, lo cuece, lo devuelve cocido y cambia color | `cooking_station.gd` (N) en `kitchen.tscn` (S) | 6 | Color hardcodeado (:61-62) → material "cocido" en datos. `CookingState.Burnt` no se usa: no hay quemado en M0 |
| `Game/OctopusSwapner.cs` (clase `OctopusSpawner`) | Nevera: instancia pulpo en la mano si está vacía | `item_spawner.gd` (N) genérico con `@export var scene: PackedScene` | 6 | Errata en el nombre del archivo. Reutilizable con el spawner de cajas |
| `Game/OrderStand.cs` | Puesto de entrega: muestra `#id`, valida caja al entrar en el trigger, sonidos ok/error | `order_stand.gd` (N) en `order_stand.tscn` (S), `Area3D.body_entered` | 6 | Doble `CompleteOrder` (:61) (§4). Validar solo en `OnTriggerEnter` impide entregar si ya estás dentro → validar también al interactuar |
| `Game/OrderTicketSpawner.cs` | Pinta tickets al generarse pedidos | — | — | No está en ninguna escena; duplicado de `OrderTicketUIController` (§4) |
| `Game/OrderTicketUIController.cs` | Pide pedido inicial por puesto, crea/destruye tickets, asigna pedido al stand | `order_tickets_panel.gd` (N, UI) + `OrderService` (asignación a puesto) | 7 | La lógica de asignar y reponer pedidos (:20-37, :84-85) pasa a `OrderService` (fase 2); la UI solo escucha señales |
| `Game/PauseManager.cs` (clase `PauseMenuManager`) | Esc pausa/reanuda (`timeScale`), deshabilita jugador, sale al menú | `pause_menu.gd` (N) en `pause_menu.tscn` (S), `process_mode = ALWAYS` | 7 | `get_tree().paused`; sobra `productivitySystem.isPaused` y deshabilitar al jugador (§4) |
| `Game/ProductivitySystem.cs` | Cronómetro de ronda (180 s), cajas entregadas, ratio y texto de rendimiento | `RoundManager` (A) | 2 | M0: ratio de cajas/minuto como el prototipo, duración en datos (`RoundConfig.tres`, 5 min por D5). **[M1]** D2: recaudación + estrellas. Temporizador duplicado (§4) |
| `Game/SeasoningItem.cs` | Condimento cogible; rama de aplicar a caja (y se destruye) | `seasoning_item.gd` (N) en `seasoning_*.tscn` (S) | 6 | Rama :51-67 inalcanzable en la práctica (§4). Sin destruir el bote al usarlo (decisión de diseño a confirmar en PUL-002) |

### Interaction

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Interaction/EmissionHighlighter.cs` | Resaltado por emisión URP | — (sustituido por shader de resaltado) | — | Bug conocido (§4). Solo lo usa `Salt.prefab`, que por ello nunca se resalta |
| `Interaction/HighlightController.cs` | Fachada Show/Hide sobre outline + retícula | `highlightable.gd` (N) o grupo `highlightable` + `material_overlay` | 5 | Un único componente de resaltado |
| `Interaction/InteractableHighlight.cs` | Activa un visual de retícula (slots) | Parte de `highlightable.gd` (nodo visual opcional) | 5 | |
| `Interaction/InteractionDetector.cs` | Elige objetivo: OverlapSphere 1,5 m (2,2 en el nivel), cono 30° (salvo < 0,7 m), puntuación `dot*2 + 1/dist`, prioriza cogibles con manos vacías y `Kitchen` +1 | `interaction_detector.gd` (N) con `Area3D` | 5 | Lógica de puntuación como función pura testeable con GUT. Duplicado en `Player.prefab` (§4) |
| `Interaction/OutlineHighlighter.cs` | Clona mallas ×1,05 con material de contorno | Shader inverted hull como `material_overlay` | 5 | Ver skill `unity-to-godot` |
| `Interaction/SlotHelper.cs` (clase `SnappingHelper`) | Alinea un objeto a un ancla usando su hijo `AnchorPoint` | Función estática en `slot.gd` o `util/snapping.gd` | 5 | Usa `transform.Find("AnchorPoint")`: en Godot `%AnchorPoint` / `@export` |

### Interfaces

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Interfaces/ActiveOrder.cs` | Pedido en curso: id, plantilla, puesto | `ActiveOrder` (`RefCounted` con `class_name`) | 2 | **[M1]** Añadir tiempo restante (D2: bonus por tiempo / caducada) |
| `Interfaces/IInteractable.cs` | Contrato `Interact` + `GetGameObject` | Duck typing: método `interact(actor)` + grupo `interactable` | 5 | Contrato a fijar en ADR (PUL-003) |
| `Interfaces/IPickable.cs` | Contrato coger/soltar | Grupo `pickable` + `on_picked_up/on_dropped` | 4 | `OnPickedUp` nunca se llama (§4) |
| `Interfaces/ISeasonable.cs` | Contrato condimentar | — | — | Solo lo implementa `Ingredient` con stub; la caja no lo implementa (§4) |

### ScriptableObjects

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `ScriptableObjects/BoxSO.cs` | Tipo de caja: nombre, icono, prefab, capacidad | `BoxData` (R) | 1 | Añadir `fill_per_press` (hoy en el prefab). `requiredCapacity` no se usa |
| `ScriptableObjects/DrinkSO.cs` | Bebida | — | — | Sin assets ni usos: código muerto (§4) |
| `ScriptableObjects/IngredientSO.cs` | Ingrediente + enums `IngredientType`, `CookingState` | `IngredientData` (R) + enums en el script | 1 | `totalCapacity`, `isCuttable` no se usan; `Burnt` no se usa |
| `ScriptableObjects/OrderSO.cs` | Plantilla de pedido: receta + especias + `maxTime` | `OrderData` (R) | 1 | M0: portar el campo tal cual. `maxTime` no se usa (0 en los 3 assets). **[M1]** Paciencia/caducidad (D2) |
| `ScriptableObjects/RecipeSO.cs` | Receta: ingrediente, caja, `basePoints` | `RecipeData` (R) | 1 | M0: portar `base_points` tal cual (0 en los 3 assets). **[M1]** D2: precio base por receta en `.tres` |
| `ScriptableObjects/SpicesSO.cs` | Condimento + enum `SeasoningType` (Salt, Paprika, Hot_Paprika) | `SeasoningData` (R) | 1 | M0: los 3 tipos actuales. **[M1]** D4: aceite y cachelos |

### Systems

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Systems/OrderSystem.cs` | Carga pedidos de `Resources/Orders`, genera (máx. 4), valida caja (tipo, ingrediente, especias ⊆), completa, resetea | `OrderService` (A) | 2 | Sin acceso a escena (`ResetOrders` usa `FindObjectsByType`, :113). Validación como función pura. Doble `CompleteOrder` (§4). Especias: hoy acepta especias extra (solo comprueba ⊆, :84-92). **[M1]** D4: igualdad exacta sí/no |

### UI

| Origen | Responsabilidad | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `UI/BoxEntryUI.cs` | Línea de ticket: receta + lista de especias | `ticket_entry.gd` (N) en `ticket_entry.tscn` (S) | 7 | |
| `UI/FaceToCamera.cs` | Billboard de canvas en mundo | — (`Label3D`/`Sprite3D` billboard) | 7 | Sin script en Godot |
| `UI/GameOverUI.cs` | Panel fin de turno: rendimiento, reiniciar, salir | `game_over.gd` (N) en `game_over.tscn` (S) | 7 | Escucha `EventBus.round_finished` en vez de sondear `isFinished` cada frame (:27-33). M0: rendimiento como el prototipo. **[M1]** D2: estrellas y recaudación |
| `UI/KitchenProgress.cs` | Temporizador de cocción + barra + audio de hervir; evento `OnCookingFinished` | `Timer` + señal en `cooking_station.gd` | 6 | Barra: `TextureProgressBar` en `SubViewport`/`Sprite3D` o `ProgressBar` 3D |
| `UI/MainMenu.cs` | Menú con flechas/Enter/ratón: Jugar → `Level_01`, Salir | `main_menu.gd` (N) en `main_menu.tscn` (S) | 7 | Botones `Button` con foco nativo; hover de ratón buggy (§4) |
| `UI/OrderTicket.cs` | Ticket: `#id` + una entrada | `order_ticket.gd` (N) en `order_ticket.tscn` (S) | 7 | |
| `UI/PauseMenuController.cs` | Navegación del menú de pausa (Reanudar/Salir) | `pause_menu.gd` (N) | 7 | Copia literal de `MainMenu` (§4): un único componente de menú |
| `UI/ProductivityUIDisplay.cs` | HUD: tiempo restante y ratio; arranca la ronda | `hud.gd` (N) en `hud.tscn` (S) | 7 | Muestra el tiempo de `RoundManager`; no lleva su propio contador ni arranca la ronda (§4) |
| `UI/SimpleProgressBar.cs` | `Image.fillAmount` | — (`TextureProgressBar`) | 7 | Sin script |

## 2. ScriptableObjects (`Assets/Resources`, 13 `.asset`)

Destino: `godot/data/<tipo>/<nombre>.tres`. Todos en fase **1**.

| Origen | Tipo | Valores | Destino Godot | Notas |
|---|---|---|---|---|
| `Resources/Boxes/SmallBox.asset` | BoxSO | "Pequeña", capacidad 100 | `data/boxes/small.tres` (BoxData) | `prefab` apunta a un GUID inexistente. `fill_per_press` 0.2 (de `Small.prefab`) |
| `Resources/Boxes/MediumBox.asset` | BoxSO | "Mediana", 100 | `data/boxes/medium.tres` | `prefab` roto (GUID inexistente). `fill_per_press` 0.1 |
| `Resources/Boxes/LargeBox.asset` | BoxSO | "Grande", 100 | `data/boxes/large.tres` | `fill_per_press` 0.05 |
| `Resources/Ingredients/Octopus.asset` | IngredientSO | "Pulpo", cocinable, cortable, `cookTime` 5 | `data/ingredients/octopus.tres` | `prefab` vacío |
| `Resources/Recipes/Individual.asset` | RecipeSO | "Pulpo Individual": pulpo + SmallBox, 0 pts | `data/recipes/individual.tres` | **[M1]** Precio base (D2) pendiente de PUL-002 |
| `Resources/Recipes/ComboDuo.asset` | RecipeSO | "Pulpo Doble": pulpo + MediumBox, 0 pts | `data/recipes/combo_duo.tres` | Ídem |
| `Resources/Recipes/Familiar.asset` | RecipeSO | "Pulpo Familiar": pulpo + LargeBox, 0 pts | `data/recipes/familiar.tres` | Ídem |
| `Resources/Orders/Order_1.asset` | OrderSO | Familiar + Hot_Paprika + Salt | `data/orders/order_1.tres` | `maxTime` 0 |
| `Resources/Orders/Order_2.asset` | OrderSO | Individual + Paprika + Salt | `data/orders/order_2.tres` | `maxTime` 0 |
| `Resources/Orders/Order_3.asset` | OrderSO | ComboDuo sin especias | `data/orders/order_3.tres` | `maxTime` 0 |
| `Resources/Spices/Salt.asset` | SpicesSO | — | `data/seasonings/salt.tres` | **Serializado con un esquema antiguo** (`spiceName`, `visualColor`, `pointsBonus`…): no tiene `type`, vale `Salt` (0) por defecto. Rehacer a mano |
| `Resources/Spices/Paprika.asset` | SpicesSO | `Paprika`, prefab `Pepper.prefab` | `data/seasonings/paprika.tres` | Pimentón dulce |
| `Resources/Spices/Hot_Paprika.asset` | SpicesSO | `Hot_Paprika`, prefab `Hot_Pepper.prefab` | `data/seasonings/hot_paprika.tres` | Pimentón picante |

`OrderService` debe recibir la lista de pedidos como `@export var orders: Array[OrderData]`
(o un `OrderCatalog.tres`), no con `Resources.LoadAll` (`OrderSystem.cs:22`).

## 3. Prefabs y escenas

### Prefabs propios (`Assets/Prefabs`, 18)

| Origen | Componentes | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Prefabs/Characters/Player.prefab` | PlayerInput, CharacterController, Animator, PlayerController, PlayerHoldSystem, PlayerInteractionController, **2×** InteractionDetector | `scenes/player/player.tscn` | 4 | Modelo `freakycapucha.fbx`, controller `Player.controller` (Idle/Walk/Pick/WalkWhileHolding; `Speed`, `IsHolding`) |
| `Prefabs/Ingredients/Octopus.prefab` | Ingredient, SimpleProgressBar, FaceToCamera | `scenes/items/octopus.tscn` | 6 | Barra de corte en mundo |
| `Prefabs/Ingredients/Salt.prefab` | SeasoningItem, HighlightController, EmissionHighlighter | `scenes/items/seasoning_salt.tscn` | 6 | Usa `EmissionHighlighter` en vez de outline (§4) |
| `Prefabs/Ingredients/Pepper.prefab` | SeasoningItem, HighlightController, OutlineHighlighter | `scenes/items/seasoning_paprika.tscn` | 6 | |
| `Prefabs/Ingredients/Hot_Pepper.prefab` | SeasoningItem, HighlightController, OutlineHighlighter | `scenes/items/seasoning_hot_paprika.tscn` | 6 | Mejor una escena `seasoning.tscn` + `SeasoningData` |
| `Prefabs/Packaging/Small.prefab` | Box, SimpleProgressBar, Animator (BoxAnimation) | `scenes/items/box.tscn` + `small.tres` | 6 | Las tres cajas = una escena + `BoxData` |
| `Prefabs/Packaging/Medium.prefab` | Ídem | `box.tscn` + `medium.tres` | 6 | |
| `Prefabs/Packaging/Large.prefab` | Ídem | `box.tscn` + `large.tres` | 6 | |
| `Prefabs/KitchenStations/Kitchen.prefab` | KitchenStation, KitchenProgress, ProgressBar, Highlight/Outline | `scenes/stations/kitchen.tscn` | 6 | Modelos Pandazole `Prop_Pot_06`, `Prop_Heater`. Tag `Kitchen` → grupo |
| `Prefabs/KitchenStations/OctopusStorage.prefab` | OctopusSpawner, Highlight/Outline | `scenes/stations/octopus_storage.tscn` | 6 | Modelo Pandazole `Prop_Fridge_01` |
| `Prefabs/KitchenStations/Mueblecajas.prefab` | Mueble (`Mueblecajas.fbx`) + 3 cajas anidadas | `scenes/stations/box_shelf.tscn` | 6 | En `Level_01` las 3 cajas se sobrescriben como spawners (`isSpawner: 1`, `boxPrefab` S/M/L, `Level_01.unity:5304-5395`) |
| `Prefabs/KitchenStations/MuebleEspecias.prefab` | Mueble + 3 condimentos + 3 `InteractableSlot` | `scenes/stations/spice_shelf.tscn` | 6 | Los botes son únicos (no spawner) |
| `Prefabs/KitchenStations/OrderStand.prefab` | OrderStand, trigger, TextMeshPro, AudioSource | `scenes/stations/order_stand.tscn` | 6 | `deliverySlotId` sobrescrito 1–4 en el nivel |
| `Prefabs/UI/InteractableSlot.prefab` | InteractableSlot, InteractableHighlight, HighlightController | `scenes/stations/slot.tscn` | 5 | Retícula `Reticule.mat` |
| `Prefabs/UI/Order.prefab` | OrderTicket | `scenes/ui/order_ticket.tscn` | 7 | Fondo `ticket_dentado.png` |
| `Prefabs/UI/Entry.prefab` | BoxEntryUI | `scenes/ui/ticket_entry.tscn` | 7 | |
| `Prefabs/UI/PanelPauseBase.prefab` | Panel uGUI sin scripts | `scenes/ui/panel_base.tscn` o `Theme` | 7 | Usado 2× en `Level_01` (pausa y game over) |
| `Prefabs/UI/ProgressBar.prefab` | SimpleProgressBar | `scenes/ui/world_progress_bar.tscn` | 7 | Barra en mundo reutilizable (olla, caja, pulpo) |

### Escenas (`Assets/Scenes`, 2; ambas en Build Settings)

| Origen | Contenido | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `Scenes/MainMenu/MainMenu.unity` | Canvas con `MainMenu` (Jugar/Salir), logo | `scenes/main_menu.tscn` (escena principal) | 7 | Primera escena del build |
| `Scenes/Levels/Level_01.unity` | Player, Kitchen, OctopusStorage, Mueblecajas, MuebleEspecias, 4× OrderStand, 17 mesas Pandazole (`Prop_KitchenTable_04/06/07`), Bootstrap, ProductivitySystem, ProductivityUIDisplay, OrderTicketUIController (4 puestos), PauseManager + PauseMenuController, GameOverUI | `scenes/levels/level_01.tscn` | 8 | `timeLimit` 180 (`Level_01.unity:5113`) → 300 por D5 en datos. Systems de escena → autoloads |

### Otros assets de configuración

| Origen | Contenido | Destino Godot | Fase | Notas |
|---|---|---|---|---|
| `PlayerInputActions.inputactions` | Mapa `Player`: `Move` (WASD), `Interact` (E) | InputMap `p1_move_*`, `p1_interact` | 0 | Es el que usa `Player.prefab`. Añadir mando y `p1_switch` (D3) |
| `InputSystem_Actions.inputactions` | Plantilla por defecto de Unity (Look, Jump, Sprint, UI…) | — | — | No se usa en el juego |
| `Animations/Character/Player.controller` | Estados Idle, Walk, Pick, WalkWhileHolding; `Speed`, `IsHolding` | `AnimationTree` StateMachine + BlendSpace1D | 4 | Clips dentro de `freakycapucha.fbx` + `CustomIdle.anim` |
| `Animations/Packaging/BoxAnimation.controller` | `FoodBoxAnimationOpen`/`FooxBoxAnimationClose`, trigger `Open` | `AnimationPlayer` en `box.tscn` | 6 | Errata `Foox` |
| `Settings/*` (URP, Volume) | Pipeline URP PC/Mobile, post-proceso | `Environment` + `WorldEnvironment` | 8 | Solo como referencia visual |
| `Readme.asset` | Readme de la plantilla URP | — | — | Basura de plantilla |

## 4. Bugs y código muerto que NO se portan

Sin fase. Cada entrada dice qué hacer en Godot. "Deducido" = de lectura de código, no
reproducido en Unity.

### Bugs conocidos (AC3)

| # | Bug | Ubicación | Efecto | En Godot |
|---|---|---|---|---|
| B1 | **Doble `CompleteOrder`** | `Systems/OrderSystem.cs:103` (dentro de `ValidateBox`) y `Game/OrderStand.cs:61` | QFramework ejecuta eventos y comandos de forma síncrona (`Plugins/QFramework/QFramework.cs:175,621,823`). Secuencia: (1) `ValidateBox` completa la comanda original → `OrderCompletedEvent` → `OrderTicketUIController.OnClearTicket` limpia el stand y pide una comanda nueva (`OrderTicketUIController.cs:82-85`), que se asigna al mismo stand (`:62`); (2) de vuelta en `OrderStand`, `completedOrder = currentOrder` (`OrderStand.cs:59`) captura **esa comanda nueva**, la limpia y la completa (`:61`) **sin entrega**; (3) el segundo evento vuelve a pedir y asignar otra comanda. Resultado: por cada entrega se completan dos comandas (la segunda de forma fraudulenta), `boxesDelivered` suma 2 (`ProductivitySystem.cs:57`) y el puesto sigue ocupado (con 4 puestos quedan 4 comandas activas) | `validate()` es pura y no completa; solo `complete_order()` emite `order_completed`, una vez, sobre la comanda validada. Test GUT: una entrega = una señal y la comanda completada es la entregada |
| B2 | **Temporizadores duplicados** | `Game/ProductivitySystem.cs:45` (`elapsedTime`) y `UI/ProductivityUIDisplay.cs:23` (`remainingTime`) | Dos contadores independientes. El sistema termina con `RoundToInt(elapsed) >= RoundToInt(limit)` (`ProductivitySystem.cs:47`), es decir a 179,5 s, mientras el HUD aún marca 0,5 s; el HUD llama `StopTracking` (`ProductivityUIDisplay.cs:36`) que no marca `isFinished`: si llegara antes, nunca saldría el game over | Un único reloj en `RoundManager`; el HUD solo lee/escucha. Fin exacto a `duration` |
| B3 | **`EmissionHighlighter`** | `Interaction/EmissionHighlighter.cs:15` (variable local `renderers` oculta el campo de :11), :25-28, :50/:63; `Interaction/HighlightController.cs:11-12` | La lista `renderers` nunca se llena, así que `DynamicGI.SetEmissive` no se ejecuta; fuerza el shader `URP/Lit` en todos los materiales del objeto (rompe otros shaders); y `HighlightController` no lo conoce, por lo que `Salt.prefab` (único usuario) nunca se resalta | No se porta. Un solo resaltado por shader (`material_overlay`) para todos los interactuables |

### Otros bugs

| # | Bug | Ubicación | En Godot |
|---|---|---|---|
| B4 | `IPickable.OnPickedUp` nunca se llama: `PickUp` reparenta a mano. `IsHeld` de Box/Ingredient/SeasoningItem nunca es `true` | `Characters/PlayerHoldSystem.cs:15-40`; definiciones `Game/Box.cs:97`, `Game/Ingredient.cs:58`, `Game/SeasoningItem.cs:9` | Un único camino: el hold llama `on_picked_up`/`on_dropped` |
| B5 | `PickUp` asigna `heldObject` antes de comprobar `IPickable`; si no lo es, queda `HeldObject != null` con `HasItem == false` | `Characters/PlayerHoldSystem.cs:21-24` | Validar antes de mutar estado |
| B6 | Rama de aplicar condimento en `SeasoningItem.Interact` inalcanzable (con `IsHeld` siempre falso y `TrySeasonBox` antes), y además destruye el bote | `Game/SeasoningItem.cs:44-67`, `Characters/PlayerInteractionController.cs:28` | Una sola ruta de condimentar; el bote no se consume salvo decisión de diseño |
| B7 | `Player.prefab` tiene **dos** `InteractionDetector` (dos OverlapSphere y dos cambios de resaltado por frame) y el controlador guarda dos referencias distintas | `Prefabs/Characters/Player.prefab:120,196`; `Characters/PlayerInteractionController.cs:8,10,17` | Un detector, referenciado por `@export` |
| B8 | `Box.Fill` hace `progressBar.gameObject.SetActive(false)` sin comprobar null | `Game/Box.cs:58` | Comprobar o garantizar el nodo con `%` |
| B9 | `Ingredient.Cut` solo destruye el pulpo agotado si tiene `progressBar` | `Game/Ingredient.cs:46-54` | Destrucción independiente de la UI |
| B10 | Orden de `Start` no determinista: `ProductivityUIDisplay.Start` → `StartTracking` → `ResetOrders` puede borrar los pedidos que `OrderTicketUIController.Start` acaba de generar | `UI/ProductivityUIDisplay.cs:16`, `Game/ProductivitySystem.cs:33`, `Game/OrderTicketUIController.cs:20-37` | `RoundManager.start_round()` resetea y luego pide los pedidos iniciales, en ese orden |
| B11 | La UI arranca la ronda | `UI/ProductivityUIDisplay.cs:16` | El nivel/`RoundManager` arranca; la UI solo escucha |
| B12 | Entrega solo en `OnTriggerEnter`: si el jugador ya estaba dentro al coger la caja, no valida | `Game/OrderStand.cs:19-32` | Validar al entrar y al interactuar en el stand |
| B13 | Pausa redundante: `timeScale = 0` + flag `isPaused` + deshabilitar `PlayerController`; Esc leído con el Input Manager antiguo (`activeInputHandler: 2`, ambos) | `Game/PauseManager.cs:21,34-44` | `get_tree().paused` y acción `pause` del InputMap |
| B14 | Hover de ratón en menús compara `rect` local con `mousePosition − position` (falla con escalado del Canvas) | `UI/MainMenu.cs:44`, `UI/PauseMenuController.cs:45` | `Button` con foco/hover nativo |
| B15 | Validación de especias acepta especias de más (solo comprueba inclusión) | `Systems/OrderSystem.cs:84-92` | M0: mantener la regla actual (⊆) salvo que PUL-002 diga otra cosa. **[M1]** D4: igualdad exacta del conjunto sí/no |
| B16 | `OrderSystem` (System QFramework) busca objetos de escena | `Systems/OrderSystem.cs:113` | Servicio sin acceso a escena; stands escuchan `order_reset` |
| B17 | `Salt.asset` con esquema antiguo (sin `type`) y `BoxSO.prefab` de Small/Medium a GUID inexistente | `Resources/Spices/Salt.asset`, `Resources/Boxes/{Small,Medium}Box.asset` | Recrear los `.tres` a mano |
| B18 | `?.` sobre objetos de Unity (salta el null de Unity → `MissingReferenceException` con objetos destruidos) | p. ej. `Characters/PlayerInteractionController.cs:52`, `Interaction/InteractionDetector.cs:103-104` | `is_instance_valid()` |

### Código muerto

| Elemento | Ubicación | Motivo |
|---|---|---|
| `IRandomUtility`, `UnityRandomUtility` | `Architecture/Bootstrap.cs:12,16-27` | Se registra pero `OrderSystem` usa `Random.Range` (`OrderSystem.cs:30`) |
| `OrderTicketSpawner` | `Game/OrderTicketSpawner.cs` | No está en ninguna escena; duplica `OrderTicketUIController` |
| `DrinkSO` | `ScriptableObjects/DrinkSO.cs` | Sin assets ni referencias |
| `ObjectDroppedEvent`, `ObjectPickedUpEvent` | `Events/` | Nunca se envían ni escuchan |
| `ISeasonable` y su stub en `Ingredient` | `Interfaces/ISeasonable.cs`, `Game/Ingredient.cs:100-109` | `ApplySeasoning` solo hace log; la caja no implementa la interfaz |
| `EmissionHighlighter` | `Interaction/EmissionHighlighter.cs` | Ver B3 |
| Campos sin uso | `BoxSO.requiredCapacity`, `IngredientSO.totalCapacity/isCuttable`, `CookingState.Burnt`, `Box.isFilled/IsFilled`, `OrderSO.maxTime` | No se leen. `maxTime` se recupera en **[M1]** (D2) |
| `PauseMenuController` ≈ `MainMenu` | `UI/PauseMenuController.cs`, `UI/MainMenu.cs` | Código copiado; un componente de menú |
| `InputSystem_Actions.inputactions`, `Readme.asset` | `Assets/` | Plantilla de Unity sin uso |
| Animaciones Kevin Iglesias y maniquíes | `Animations/Character/{Idles,Movement}/*.fbx`, `Art/Characters/HumanCharacterDummy_*.fbx` | 0 referencias en prefabs/escenas/controllers |
| `BillGatos.fbx` | `Art/Characters/` | 0 referencias |
| `using` sobrantes | `Box.cs:3-4` (`UIElements`, `VisualScripting`), `OrderSystem.cs:4`, `RecipeSO.cs:3`, `PlayerInteractionController.cs:2` | Ruido |

## 5. Assets (arte, audio, fuentes)

"Usos" = referencias desde prefabs/escenas/materiales/controllers del prototipo. Licencias
marcadas **verificar** no constan en el repo: lo resuelve el responsable antes de publicar.
Conversión en fase 3 (no en esta ficha).

### Modelos

| Archivo | Origen / licencia | Usos | ¿Se reutiliza? |
|---|---|---|---|
| `Art/Characters/freakycapucha.fbx` | Propio (Blender 4.4.1); **verificar** | `Player.prefab`, `Player.controller` (contiene los clips) | Sí — jugador |
| `Art/Characters/BillGatos.fbx` | Propio (Blender 4.4.0); **verificar** | 0 | Candidato a 2.º personaje (D3), post-M0 |
| `Art/Characters/HumanCharacterDummy_{F,M}.fbx` | Kevin Iglesias, Human Animations (Unity Asset Store, EULA estándar) | 0 | No |
| `Art/Furniture/Mueblecajas.fbx` | Propio (Blender 4.4.1) | `Mueblecajas.prefab`, `MuebleEspecias.prefab` | Sí |
| `Art/Furniture/order_stand.fbx` | Propio (Blender 4.4.0) | `OrderStand.prefab` | Sí |
| `Art/Ingredients/Octopus.fbx` | Propio (Blender 4.4.0); **verificar** | `Octopus.prefab` (+ referencia en `Hot_Pepper.prefab`) | Sí |
| `Art/Ingredients/Condiment.obj` (2,3 MB) | **verificar** (sin metadatos) | Salt/Pepper/Hot_Pepper | Sí; revisar peso |
| `Art/Packaging/Boite Hamburger.fbx` | Externo probable (nombre en francés, Blender 4.0.2); **verificar** | Small/Medium/Large | Sí si la licencia lo permite |
| `Plugins/Pandazole_Kitchen_Assets/Models/*.fbx` (15) + `PandaMat.png` | Pandazole Kitchen Assets (Unity Asset Store, EULA estándar) | Usados: `Prop_KitchenTable_04/06/07` (nivel), `Prop_Pot_06` y `Prop_Heater` (Kitchen), `Prop_Fridge_01` (OctopusStorage) | Según D6: puede que no; si se usan, solo los 6 citados |

### Animaciones

| Archivo | Origen / licencia | Usos | ¿Se reutiliza? |
|---|---|---|---|
| Clips en `freakycapucha.fbx` + `Animations/Character/Idles/CustomIdle.anim` | Propio | `Player.controller` | Sí (`AnimationTree`, fase 4) |
| `Animations/Character/Idles/HumanM@*.fbx` (4), `Movement/Walk/**/HumanM@Walk01_*.fbx` (16) | Kevin Iglesias (Asset Store) | 0 | No |
| `Animations/Packaging/Box/FoodBoxAnimationOpen.anim`, `FooxBoxAnimationClose.anim` | Propio | `BoxAnimation.controller` | Recrear en `AnimationPlayer` (fase 6) |

### Texturas, iconos y materiales

| Archivo | Origen / licencia | Usos | ¿Se reutiliza? |
|---|---|---|---|
| `Art/Icons/pepper-hot-solid.{svg,png}` | Font Awesome Free (iconos CC BY 4.0) — **verificar** atribución | `Hot_Pepper_Quad.mat` | Sí, con atribución |
| `Art/Icons/{octopus,salt,selection}.{svg,png}` | **verificar** | png: materiales de condimento/retícula/símbolo | Sí (usar SVG en Godot) |
| `Art/Logo/PulpaSA.png` | Propio | Menú principal | Sí |
| `Art/UI/ticket_dentado.png` | Propio probable | `Order.prefab` | Sí |
| `Art/UI/white_sprite.png` | Propio (sprite blanco) | Barra de progreso | No (`StyleBoxFlat`) |
| `Art/Materials/**/*.mat` (10) | Propio, URP Lit | Prefabs | Recrear como `StandardMaterial3D` (fase 3). `HighlightTexture.mat` → shader de resaltado (fase 5) |

### Audio

Todo sin metadatos de origen (**verificar**; `error.mp3` codificado con LAME 3.100).

| Archivo | Uso en el prototipo | ¿Se reutiliza? |
|---|---|---|
| `Audio/SFX/boilling_water.wav` | Olla (`KitchenProgress`) | Sí (fase 6) |
| `Audio/SFX/scissorcut.wav` | Corte (`PlayerInteractionController.cutAudio`) | Sí (fase 6) |
| `Audio/SFX/pepperMill.wav` | Condimentar (`Box.millSound`); también referenciado en Salt/Pepper y en un `AudioSource` de `Level_01` | Sí (fase 6/7) |
| `Audio/SFX/validationOK.wav` | Entrega correcta (`OrderStand`) | Sí (fase 6) |
| `Audio/SFX/error.mp3` | Entrega incorrecta (`OrderStand`) | Sí (fase 6) |
| `Audio/Music/` | Carpeta vacía | Música: post-M0 |

### Fuentes

| Archivo | Origen / licencia | Usos | ¿Se reutiliza? |
|---|---|---|---|
| `Plugins/TextMesh Pro/Fonts/OCRAEXT.TTF` (+ `OCRAEXT SDF.asset`) | Distribuida con ejemplos de TMP; **verificar** licencia | Tickets, HUD, menús (6 referencias) | Sí si la licencia lo permite; si no, sustituta OFL |
| `Plugins/TextMesh Pro/Fonts/LiberationSans.ttf` | SIL OFL 1.1 (`LiberationSans - OFL.txt`) | Fallback TMP | Opcional (Godot trae fuente por defecto) |

### Plugins de código

| Plugin | Licencia | ¿Se porta? |
|---|---|---|
| `Plugins/QFramework/QFramework.cs` | MIT (liangxiegame) | No: sustituido por autoloads + `EventBus` |
| `Plugins/TextMesh Pro/` | Unity Companion License | No: `Label`/`Label3D` + fuentes |
