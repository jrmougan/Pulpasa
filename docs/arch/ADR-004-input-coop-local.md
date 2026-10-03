# ADR-004 — Input para coop local y cambio de personaje

- **Estado:** propuesto
- **Fecha:** 2026-10-03
- **Ficha:** PUL-003
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
- (−) La plantilla `device = 0/1` hace que, sin `GameState`, el primer mando controle a J1; solo
  ocurre en escenas lanzadas sueltas desde el editor.
