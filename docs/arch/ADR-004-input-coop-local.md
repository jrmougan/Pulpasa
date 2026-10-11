# ADR-004 — Input para coop local y cambio de personaje

- **Estado:** aceptado (2026-10-03); enmienda §6 (D26: input táctil en Individual y corte al
  mantener) **propuesta**, pendiente del gate humano (PUL-120)
- **Fecha:** 2026-10-03; enmienda 2026-10-11
- **Ficha:** PUL-003; enmienda PUL-120 (D26)
- **Relacionado:** D3 y D11 (`docs/design/decisions.md`), ADR-005 (D14, 3D o 2D), Must 5–7 (`docs/design/roadmap.md`), features
  `jugadores-y-cambio`, `mando-y-reasignacion`, `menu-principal` (PUL-002), ADR-002 (`GameState`),
  inventario §3 (`PlayerInputActions.inputactions`) y B13

## Contexto

El prototipo tiene un solo jugador con `PlayerInput` (Input System) y el mapa `Player`: `Move`
(WASD) e `Interact` (E). La pausa lee `Esc` con el Input Manager antiguo (B13). No hay mando ni
segundo jugador.

La alpha exige (Must 5–7):
- Coop local 2P con teclado + mando o dos mandos; cada dispositivo controla a un solo jugador.
- Modo individual con **cambio de personaje** en < 0,2 s (D3); el no controlado se queda quieto y
  conserva lo que lleva.
- Flujo menú → partida → game over completable solo con mando.
- Test que compruebe que toda acción de juego tiene binding de teclado y de mando.

Restricciones de Godot 4.7: `Input.get_vector()` / `is_action_pressed()` no filtran por
dispositivo; el filtrado se hace en el propio `InputEvent` de la acción (`device = -1` significa
todos). Los ids de mando empiezan en 0 y los eventos de teclado también llevan `device = 0`, pero
nunca coinciden con eventos de mando porque el tipo de evento es distinto.

M0 es paridad (1 jugador, teclado); coop, mando y cambio son M2. La fase 0 de M0 crea ya el
InputMap con el esquema definitivo para no cambiar nombres después.

La dimensión del juego está pendiente (D14, ADR-005), así que esta ADR separa lo que no depende de
ella (acciones, dispositivos, quién controla a quién) de cómo se traduce el input en movimiento.

## Decisión

### 0. Común y específico de dimensión
| Parte | Capa |
|---|---|
| Acciones del InputMap, asignación de dispositivos (`DeviceAssignment` + `GameState`), `PlayerInput`, `ControlComponent`, `CharacterSwitcher`, menús | **Común**: no cambia con D14 |
| Convertir el `Vector2` de movimiento en velocidad del cuerpo, orientación del personaje, indicador de personaje activo | **Específica** de `player.gd` (3D o 2D) |

`PlayerInput.get_move_vector()` devuelve siempre un `Vector2` en el plano de pantalla/suelo
(x derecha, y abajo = hacia la cámara). En 3D, `player.gd` lo pasa a `Vector3(v.x, 0, v.y)` (girado
por el yaw de la cámara si no es 0) y orienta con slerp en Y; en 2D lo usa tal cual (top-down) o
escalado en y (vista oblicua) y elige la animación por dirección.

### 1. Acciones del InputMap (`project.godot`)
Acciones **por jugador** con prefijo `p<n>_` y acciones **globales** sin prefijo.

| Acción | J1 teclado (K1) | J2 teclado (K2) | Mando (plantilla) | Fase |
|---|---|---|---|---|
| `p<n>_move_left/right/up/down` | A/D/W/S | ←/→/↑/↓ | stick izq. + cruceta | M0 (p1), M2 (p2) |
| `p<n>_interact` | E | Intro | A (botón 0) | M0 (p1), M2 (p2) |
| `p1_switch` | Q | — | Y (botón 3) | M2 |
| `pause` | Esc | — | Start (botón 6) | M0 |
| `ui_*` (de Godot) | flechas/Intro/Esc | | cruceta / stick / A / B | M0 |

- Interactuar cubre coger, soltar, cortar, condimentar y entregar, como el prototipo. No se añade
  un botón de "soltar" ni de "cortar" separado en M0 (cambio de diseño → gate).
- Solo el jugador 1 tiene `switch`: el modo individual siempre lo juega J1.
- Los eventos de **teclado** de K1/K2 usan `device = -1` y son fijos: J1 siempre responde a K1 y
  J2 a K2 (dos personas pueden compartir teclado).
- Los eventos de **mando** de las acciones `p<n>_*` vienen en `project.godot` como plantilla con
  `device = 0` (J1) y `device = 1` (J2), para que el test de bindings pase con el InputMap estático.
  En tiempo de ejecución se reescribe su `device` según la asignación (punto 2).
- `pause` y `ui_*` aceptan cualquier dispositivo (`device = -1`): cualquiera puede pausar y navegar
  menús (Must 5 / `menu-principal` AC4). Se sustituye B13 por la acción `pause`.
- Zona muerta de stick en datos (`InputConfig.tres`, 0,2) aplicada a las acciones de movimiento
  al arrancar.

### 2. Asignación de dispositivos (`DeviceAssignment` + `GameState`)
La regla es pura y vive en `core/device_assignment.gd` (`class_name DeviceAssignment`, funciones
`static`, testeable sin árbol); `GameState` solo la aplica al InputMap. Cada jugador tiene un valor
de mando con **tres significados distintos**, sin reutilizar `-1` para dos cosas:

| Constante | Valor | Significado | Cuándo |
|---|---|---|---|
| id de mando | `>= 0` | Solo ese mando | `COOP_2P` |
| `DeviceAssignment.ANY` | `-1` (= `device` comodín de Godot) | Cualquier mando | **Solo** J1 en `SINGLE` |
| `DeviceAssignment.NONE` | `-2` | Ningún mando: solo teclado | Jugador sin mando asignado |

Aplicación (`GameState.apply_devices()`): al arrancar, `GameState` copia los eventos de mando de
la plantilla de cada acción `p<n>_*`. Para aplicar una asignación, en cada acción `p<n>_*`
**borra solo los eventos de mando** (`InputEventJoypadButton`/`InputEventJoypadMotion`) y, según el
valor del jugador: `NONE` → no añade ninguno; id → añade las copias de plantilla con ese `device`;
`ANY` → las añade con `device = -1`. Los eventos de teclado no se tocan nunca.

| Situación | J1 | J2 |
|---|---|---|
| `SINGLE` | K1 + `ANY` | `NONE` (sin personaje controlado) |
| `COOP_2P`, 0 mandos | K1 + `NONE` | K2 + `NONE` |
| `COOP_2P`, 1 mando | K1 + `NONE` | K2 + mando A |
| `COOP_2P`, 2+ mandos | K1 + mando A | K2 + mando B |

"Mando A/B" = orden de `Input.get_connected_joypads()` al llamar `GameState.start_level(mode)`.
**Invariante**: en `COOP_2P` un id de mando está como mucho en un jugador y `ANY` no aparece nunca.

Hot-plug (M2), `GameState` escucha `Input.joy_connection_changed`:
- **Desconexión** de un mando asignado: ese jugador pasa a `NONE` (se borran sus eventos de mando;
  conserva su teclado), `set_paused(true)` y `EventBus.device_disconnected(player_index)`.
- **Conexión** en `COOP_2P`: el mando va al jugador que lo perdió si sigue en `NONE`; si no, al
  primer jugador en `NONE`; si no hay ninguno, queda sin asignar. Se emite `device_assigned`.
  En `SINGLE` no hace falta reasignar (`ANY` ya lo acepta).

*Aclaración 2026-10-04, ratificada por el responsable tras la revisión de PUL-034:*
- «Durante la ronda» = entre `round_started` y `round_finished`. Fuera de ese tramo, retirar un
  mando no pausa: solo emite `device_assigned(p, NONE)`.
- Al retirar un mando en ronda se emiten `device_disconnected(p)` y `device_assigned(p, NONE)`.
- En `SINGLE`, J1 conserva `ANY`. Si se desconecta el último mando conectado durante la ronda, se
  pausa y se emite `device_disconnected(1)`; al conectarse cualquier mando se emite
  `device_assigned(1, ANY)` para retirar el aviso.

Casos de test (unitarios sobre `DeviceAssignment` + uno de integración sobre el InputMap):
teclado + un mando (J1 no responde al mando de J2), dos mandos (cada uno mueve solo a su
jugador), desconexión del mando de J2 (J2 sigue con K2, J1 no gana el mando), reconexión (vuelve a
J2, nunca a ambos) y `SINGLE` con cualquier mando.

### 3. Lectura de input en el personaje
- `core/player_input.gd` (`class_name PlayerInput`, `RefCounted`) construye y cachea los
  `StringName` de las acciones de un jugador (`&"p1_move_left"`…) y expone
  `get_move_vector() -> Vector2` (`Input.get_vector`) e `is_interact_event(event: InputEvent) -> bool`.
- El componente común `ControlComponent` (ADR-003 §3) lleva `@export var player_index: int`
  (identidad del personaje, 1 o 2) y `var controlled_by: int` (jugador que lo controla; `0` =
  nadie), y emite `control_changed`. `player.gd` (específico) lo consulta: si `controlled_by == 0`,
  velocidad horizontal 0, no procesa input y conserva el objeto en la mano (feature
  `jugadores-y-cambio` AC3–AC4). Sigue con gravedad y física.
- El input de acciones puntuales (`interact`) se lee en `_unhandled_input`, para que la pausa y la
  UI lo consuman antes.
- En M0 el nivel tiene un personaje con `controlled_by = 1`.

### 4. Cambio de personaje (`CharacterSwitcher`, M2)
- Escena `entities/player/character_switcher.tscn` (común: raíz `Node`) instanciada en el nivel,
  con `@export var characters: Array[ControlComponent]` (los componentes de control de cada
  personaje; nunca `Player`) y `@export var config: InputConfig`
  (`switch_cooldown` 0,2 s, de `jugadores-y-cambio`).
- `SINGLE`: al pulsar `p1_switch`, si pasó el cooldown y la ronda está en curso, pone `controlled_by = 0` al actual y `1`
  al siguiente **en el mismo frame** y emite `EventBus.character_switched(1, player_index_del_nuevo)`
  (índices, no nodos: el bus es independiente de la dimensión). Cumple
  < 0,2 s por construcción (el siguiente `_physics_process` ya mueve).
- `COOP_2P`: asigna `controlled_by = 1` y `2` al empezar e ignora `p1_switch`.
- Siempre hay exactamente un personaje con cada `controlled_by` activo; el indicador visual lo
  pinta el propio `player.gd` al recibir `control_changed`.
- Se prueba sin escena: `CharacterSwitcher` + dos `ControlComponent` sueltos, sin `Player` ni
  clases físicas.
- D11 cierra la pregunta del GDD §11.3: **tecla fija que alterna entre los dos**.

### 5. Menús y UI
Los menús usan `Button` con foco nativo y las acciones `ui_*` (B14). El menú principal pone
`GameState.mode` antes de cargar el nivel. La pausa (`pause_menu.tscn`, `PROCESS_MODE_ALWAYS`)
escucha `pause` y llama `GameState.set_paused()`.

### 6. Input táctil y corte al mantener (D26) — *Enmienda D26 (PUL-120, 2026-10-11), propuesta, pendiente del gate humano*

D26.8: móvil entra en el alcance de la alpha **solo en Individual** (con cambio de personaje),
apaisado. Local 2P sigue siendo de PC/mando. Diseño medible en
`docs/design/features/controles-tactiles.md` (PUL-119). Escala, safe area y perfil de plataforma en
ADR-005 (Enmienda D26). Export Android: fuera de esta oleada (`export.md`).

**6.1 Sin eventos táctiles en el InputMap.** Los controles táctiles **alimentan las acciones que ya
existen** (`p1_move_*`, `p1_interact`, `p1_switch`, `pause`) desde código; `project.godot` no gana
acciones ni eventos (`InputEventScreenTouch` no es un binding). Así todo el juego (jugador,
`InteractionComponent`, `CharacterSwitcher`, pausa) sigue leyendo `PlayerInput` y `_unhandled_input`
sin saber de dónde viene la pulsación, y el test de bindings (teclado + mando) no cambia.

| Control | Cómo alimenta | Acción |
|---|---|---|
| Stick virtual | `Input.action_press(acción, fuerza)` / `Input.action_release(acción)` por eje en cada `InputEventScreenDrag` y al soltar: `x > 0` → `p1_move_right` con fuerza `x`, `x < 0` → `p1_move_left` con `−x` (y la opuesta liberada); igual en `y` con `p1_move_down` / `p1_move_up`. `Input.get_vector` de `PlayerInput` lo lee igual que un stick | `p1_move_*` |
| Botón de acción | `Input.parse_input_event()` de un `InputEventAction` (`action = &"p1_interact"`, `pressed = true`, `strength = 1.0`) al tocar y otro con `pressed = false` al levantar el dedo: llega a `_unhandled_input` (pulsación) y deja `Input.is_action_pressed` verdadero mientras se mantiene (corte al mantener, 6.4) | `p1_interact` |
| Botón de cambiar | `InputEventAction` `p1_switch` (pulsar y soltar) | `p1_switch` |
| Botón de pausa | `InputEventAction` `pause` (pulsar y soltar) | `pause` |

Al ocultarse los controles o salir del árbol se liberan todas las acciones que hubieran pulsado
(`action_release` y `InputEventAction` con `pressed = false`), para que no quede nada pegado.

**6.2 Escenas y datos** (capa común: `ui/`, `core/`, `resources/`, sin tipos de mundo):

```
ui/touch/touch_controls.tscn
TouchControls (Control, anclas a pantalla completa, mouse_filter IGNORE)   touch_controls.gd  class_name TouchControls
│   @export config: TouchConfig = data/config/touch_config.tres
│   @export icons: ActionIconSet = data/config/action_icons.tres
│   visible según TouchInput.controls_visible(...) (6.3); en COOP_2P oculto y sin procesar input
└── %SafeArea (SafeAreaMargin, ADR-005)
    ├── %MoveStick     (Control)  virtual_stick.gd  class_name VirtualStick   mitad izquierda, flotante
    ├── %ActionButton  (Control)  action_button.gd  class_name ActionButton   abajo a la derecha
    ├── %SwitchButton  (Control)  touch_button.gd   class_name TouchButton    action = &"p1_switch"
    └── %PauseButton   (Control)  touch_button.gd                             action = &"pause"
```
- **Multitáctil**: cada control procesa `InputEventScreenTouch` / `InputEventScreenDrag` en `_input`
  filtrando por `event.index` (el stick recuerda el índice del dedo que lo abrió; cada botón, el suyo)
  y marca el evento como gestionado. `mouse_filter = IGNORE` en todos para que la emulación de ratón
  desde táctil (activa por defecto; la usan los menús) no los dispare dos veces.
- **Stick flotante**: un toque en la zona del stick (`stick_zone_fraction` del ancho desde la
  izquierda, dentro del safe area y fuera de los botones) fija el centro; el vector es
  `TouchInput.stick_vector(center, point, radius, deadzone)` (puro): `(point − center) / radius`
  recortado a longitud 1, y cero por debajo de `deadzone`. Al levantar el dedo, vector cero y
  acciones liberadas.
- **Botón de acción**: escucha `EventBus.action_hint_changed` con `player_index == 1` y muestra
  `icons.verb_icons[verb]`: `OK` blanco (`ok_color`), `BLOCKED` ámbar (`blocked_color`) con
  `icons.reason_icons[reason]`; sin objetivo (`NONE`), placa gris (`idle_color`) sin verbo. Con
  `EventBus.interaction_resolved` de J1 da la misma respuesta que el prompt (salto en `OK`, sacudida
  en `BLOCKED`, ≥ 0,3 s). Pulsarlo sin objetivo envía igualmente `p1_interact` (soltar, ADR-003 §9.5).
- Tamaños (D26.8): botón de acción **≥ 72 dp**, cambiar y pausa **≥ 48 dp**; 1 dp = 2,5 px a 1080 de
  alto (`TouchConfig.px_per_dp_at_1080`). Conversión a unidades de lienzo con `UiScale.dp_to_units()`
  (ADR-005, Enmienda D26).
- `resources/touch_config.gd` (`class_name TouchConfig extends Resource`): `px_per_dp_at_1080: float =
  2.5`, `stick_radius_dp: float = 60.0`, `stick_deadzone: float = 0.2`, `stick_zone_fraction: float =
  0.5`, `action_button_dp: float = 72.0`, `small_button_dp: float = 48.0`, `edge_margin_dp: float =
  16.0`. Instancia `data/config/touch_config.tres`. Test de datos: `action_button_dp ≥ 72`,
  `small_button_dp ≥ 48`.
- `TouchControls` se instancia en la `UI` (`CanvasLayer`) del nivel, encima de HUD y tickets y debajo
  de pausa y game over (orden de hijos, `scene-tree.md` §2).

**6.3 Cuándo se ven** (`core/touch_input.gd`, `class_name TouchInput extends RefCounted`, puro):
- `enum Source { NONE, TOUCH, KEYS, JOYPAD }`.
- `static func source_of(event: InputEvent) -> Source`: `InputEventScreenTouch` / `ScreenDrag` →
  `TOUCH`; `InputEventKey` → `KEYS`; `InputEventJoypadButton` y `InputEventJoypadMotion` por encima de
  la zona muerta → `JOYPAD`; el resto (ratón, también el emulado desde táctil, e `InputEventAction`,
  que inyectan los propios controles) → `NONE` = no cambia la fuente.
- `static func controls_visible(touch_available: bool, mode: GameMode.Mode, last: Source) -> bool`:
  `touch_available and mode == GameMode.Mode.SINGLE and last in [Source.NONE, Source.TOUCH]`. Visibles
  si hay pantalla táctil (`DisplayServer.is_touchscreen_available()`) y la última entrada no fue
  teclado ni mando; se ocultan al usar teclado o mando y vuelven al tocar la pantalla. En `COOP_2P`,
  nunca.
- `static func stick_vector(center: Vector2, point: Vector2, radius: float, deadzone: float) -> Vector2`
  (6.2).
- `TouchControls` guarda la última fuente en `_input` (sin consumir el evento) y reevalúa.

**6.4 Corte al mantener.** Común a teclado, mando y táctil: `PlayerInput.is_interact_pressed()` +
`HoldRepeat` (núcleo) con `InputConfig.cut_repeat_interval` (0,2 s) en `InteractionComponent`
(ADR-003 §11.4). Solo repite verbos de `ActionVerb.REPEATABLE` (`cut`). Pulsar sigue valiendo (D13).

**6.5 Menú y pausa en móvil.** En el perfil `MOBILE` (ADR-005, Enmienda D26) el menú principal oculta
«Local 2P» (D26.8) y el foco inicial sigue en Individual; los menús funcionan con toque gracias a la
emulación de ratón de Godot (sin código táctil propio). Si la aplicación pierde el foco
(`NOTIFICATION_APPLICATION_FOCUS_OUT`, p. ej. al cambiar de app) durante la ronda en el perfil
`MOBILE`, `GameState` llama `set_paused(true)`.

**Alternativas descartadas (§6).**
1. *Eventos `InputEventScreenTouch` en el InputMap.* No llevan zona ni índice útiles para un stick y
   romperían el test de bindings y la reasignación de `GameState.apply_devices()`.
2. *Leer el táctil directamente en `player.gd`.* Duplica la ruta de input y ata la capa específica a
   la UI; con acciones, el personaje no cambia.
3. *Addon de joystick virtual.* Dependencia en `addons/` (no editable) para un cálculo puro de pocas
   líneas.
4. *Táctil también en Local 2P.* Dos jugadores en un teléfono no es viable (estudio de PUL-119,
   diagnóstico 7).

## Alternativas consideradas
1. **Acciones sin prefijo y filtrado por dispositivo en código** (leer `InputEvent.device` y
   `Input.get_joy_axis(device, …)` a mano). Pierde `get_vector`, el remapeo del InputMap y la
   visibilidad en el editor. Descartada.
2. **Crear las acciones por dispositivo solo en tiempo de ejecución** (sin `p<n>_*` en
   `project.godot`). El InputMap del editor quedaría vacío y el test estático de bindings no
   tendría qué comprobar. Descartada; se usa plantilla estática + reescritura de `device`.
3. **Addon de multijugador local** (p. ej. "Multiplayer Input"). Resuelve lo mismo pero añade una
   dependencia en `addons/` que no podemos editar y un modelo de acciones propio. Descartada para
   dos jugadores.
4. **Cambio de personaje instanciando/liberando el controlador** o moviendo la cámara de uno a
   otro. Más caro y con riesgo de perder estado (objeto en mano, corte en curso). Descartada: solo
   cambia `controlled_by`.
5. **Un único valor `-1` para "sin mando" y "cualquier mando"**, como en la primera versión de
   esta ADR. En `COOP_2P` con un mando, J1 acabaría aceptando el mando de J2. Descartada:
   `NONE` y `ANY` son constantes distintas y `ANY` solo existe en `SINGLE`.
6. **Mando único compartido por J1 en coop.** Contradice "cada dispositivo controla a un solo
   jugador". Descartada.

## Consecuencias
- (+) Los nombres de acción de M0 (`p1_*`, `pause`) no cambian al llegar el coop.
- (+) Todo salvo la traducción a movimiento es común: D14 no reabre esta ADR.
- (+) El test de bindings (feature `mando-y-reasignacion` AC4) se escribe sobre el InputMap estático.
- (+) La asignación de mandos es pura y probada por casos; el cambio de personaje es una asignación de un entero: barato, testeable en headless y sin
  pérdida de estado.
- (−) `GameState` modifica el InputMap global en tiempo de ejecución: los tests que dependan de
  `device` deben restaurarlo (`GameState.reset_input()`) en `after_each`.
- (−) Dos jugadores en un teclado pueden sufrir ghosting de teclas; es aceptable (el Must habla de
  teclado + mando o dos mandos).
- (§6, +) El táctil no añade rutas de input: el juego sigue leyendo `p1_*`; los tests de jugador e
  interacción valen igual y el táctil se prueba inyectando `InputEventScreenTouch` / `Drag`.
- (§6, −) `Input.action_press` de los controles convive con el teclado y el mando de J1; si se usan
  a la vez gana la fuerza mayor (`Input.get_vector`). Aceptable: los controles se ocultan al usar
  teclado o mando.
- (−) La plantilla `device = 0/1` hace que, sin `GameState`, el primer mando controle a J1; solo
  ocurre en escenas lanzadas sueltas desde el editor.
