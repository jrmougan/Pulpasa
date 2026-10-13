# Pantalla de opciones (Should)

**Slug:** opciones-de-volumen (se conserva el nombre del fichero; el alcance pasa a ser la pantalla de opciones)
· **Ficha de diseño:** PUL-160 · **Contrato:** ADR-007 (PUL-163) · **Implementación:** PUL-167 (núcleo de
ajustes), PUL-171 (pantalla) · **Prototipo:** no tiene (Unity no guardaba ajustes).

## Estado de las decisiones
- **Aprobado** (alcance de la alpha, `roadmap.md`, Should «opciones de volumen»): volumen de **Música, Ambiente y
  Efectos** con persistencia. Es el núcleo de esta feature (AC1–AC11).
- **Propuesta, sin aprobar** (pregunta **P2** del plan de M4, `docs/evidence/PUL-141/README.md`, gate **G0**):
  cualquier otro ajuste. Están en «Ajustes candidatos» con su coste; ninguno se implementa sin la elección del
  responsable. PUL-171 implementa solo la lista aprobada en G0.

## Descripción
Una pantalla con una fila por ajuste y un botón «Volver». Se abre desde el **menú principal** y desde el
**menú de pausa**; los cambios se aplican al momento y se guardan solos en `user://settings.cfg`. Es la misma
pantalla en los dos sitios: solo cambia a dónde vuelve.

```
┌──────────────────── Opciones ────────────────────┐
│  Música      ◀━━━━━━━━━━━━●━━━━━━━━━▶    70 %    │  fila ≥ 120 px
│  Ambiente    ◀━━━━━━━━━━━━●━━━━━━━━━▶    70 %    │  24 px entre filas
│  Efectos     ◀━━━━━━━━━━━━━━━━━━━━━━●▶  100 %    │
│  (filas de los ajustes aprobados en G0)          │
│                   [ Volver ]                     │
└──────────────────────────────────────────────────┘
```

## Apertura y cierre
- **Menú principal (escritorio):** botón «Opciones» entre «Local 2P» y «Salir» (con créditos:
  Individual, Local 2P, Opciones, Créditos, Salir; `creditos-y-version.md`).
- **Menú principal (táctil):** hoy solo «Individual» (`menu-principal.md` AC6). Añadir «Opciones» ahí cambia ese
  AC: queda como **propuesta** (pregunta O3). Sin ella, en móvil se llega a opciones desde la pausa.
- **Pausa:** botón «Opciones» entre «Reanudar» y «Menú» (en táctil: Reanudar, Reiniciar, Opciones, Menú).
  El juego **sigue en pausa** mientras la pantalla está abierta (el reloj de ronda no avanza) y la atenuación de
  pausa de Música y Ambiente (`pause_duck_db`, ADR-006 §2) sigue aplicada: lo que se oye en la pausa es el
  volumen elegido menos esa atenuación.
- **Cerrar:** «Volver», `ui_cancel` (Esc / B del mando) o `pause` vuelven al menú de origen con el foco en
  «Opciones». Desde la pausa, cerrar opciones **no reanuda**: hace falta otra pulsación en la pausa.

## Navegación
| Entrada | Cambiar de fila | Cambiar valor | Activar botón / interruptor | Volver |
|---|---|---|---|---|
| Teclado | `ui_up` / `ui_down` | `ui_left` / `ui_right`: 1 paso por pulsación; mantener repite con el eco de entrada de Godot | `ui_accept` | `ui_cancel`, `pause` |
| Mando | Cruceta o stick izquierdo | Cruceta o stick izquierdo ←/→ | A | B, Start |
| Táctil | — (no hay foco visible) | Tocar un punto de la pista fija el valor al paso más cercano; arrastrar el tirador lo cambia en el mismo frame | Tocar | Botón «Volver» |

- Foco inicial: la primera fila (Música). El recorrido con `ui_down` no envuelve: en «Volver» se queda.
- Toda la fila es zona táctil (hit area = fila visible), no solo el tirador.
- Los sliders van de **0 a 100 %** en pasos de `volume_step` (10 %): 11 posiciones; el valor se muestra en
  números («70 %») a la derecha.
- Mover el slider de **Efectos** reproduce 1 vez el clic de UI (`fx_ui_click`, bus `SFX`) al nuevo volumen, como
  muestra, como mucho 1 vez cada `preview_min_interval`. Música y Ambiente no tienen muestra: en el menú
  principal no suena música (la pone `LevelAudio` en el nivel) y en la pausa ya se oye.

## Volumen y persistencia
- El slider llama a `AudioDirector.set_volume(bus, linear)` (ADR-006 §2; único escritor de los buses):
  0 % → −80 dB; si no, `linear_to_db(linear)` (50 % → −6,02 dB; 100 % → 0 dB).
- **Valores por defecto** en `settings_defaults.tres`: Música 70 %, Ambiente 70 %, Efectos 100 % (los mismos que hoy
  tiene `data/audio/audio_mix.tres`; ADR-007 decide cuál de los dos es la fuente única, pregunta O4).
- **Fichero** `user://settings.cfg` (`ConfigFile`). Esquema **propuesto** (lo fija ADR-007):

  ```ini
  [meta]
  schema=1
  [audio]
  music=0.7
  ambience=0.7
  sfx=1.0
  ; solo si G0 aprueba los candidatos correspondientes:
  [locale]
  language="es"
  [display]
  fullscreen=false
  vsync=true
  tilt_shift=false
  ```
- **Cuándo se guarda** (solo si hay cambios sin guardar; si no, nunca se escribe):
  1. `save_debounce` (0,5 s) después del último cambio, para no escribir en cada frame de un arrastre;
  2. como mucho `save_max_interval` (2,0 s) después del **primer** cambio sin guardar, aunque el arrastre siga: un
     cambio continuo reinicia el debounce, pero no puede aplazar la escritura más de 2,0 s;
  3. al momento, en el mismo frame, al cerrar la pantalla de opciones;
  4. al momento al **suspender o salir**: `NOTIFICATION_APPLICATION_PAUSED` (Android en segundo plano),
     `NOTIFICATION_APPLICATION_FOCUS_OUT` y `NOTIFICATION_WM_CLOSE_REQUEST`. Cerrar la pantalla no es suspender la
     aplicación: el juego puede ir a segundo plano con la pantalla abierta y en mitad de un arrastre.
  Las notificaciones solo llegan a nodos: las recibe el adaptador del núcleo de ajustes (cuál, lo fija ADR-007) y
  llama a su `flush()`; el núcleo `RefCounted` no sabe de notificaciones.
- **Garantía:** si el sistema entrega la notificación de suspensión o cierre, se pierden **0 cambios**. Si el proceso
  muere sin notificación (cuelgue, el sistema lo mata sin avisar), se pierden como mucho los cambios de los últimos
  `save_max_interval` (2,0 s).
- **Al cargar:** fichero ausente → valores por defecto (sin crear el fichero hasta el primer cambio); fichero
  ilegible o con claves desconocidas → valores por defecto para lo que falte, 0 errores en consola; valores
  fuera de rango → se recortan a [0, 1] y se ajustan al paso más cercano (1,7 → 1,0; −0,2 → 0,0; 0,75 → 0,8).

## Maquetación
- Tarjeta centrada de `options_card_width` de ancho. Texto ≥ 36 px y filas ≥ 120 px de alto con 24 px entre
  ellas a 1080 de alto en el perfil táctil (`controles-tactiles.md`, «Escala de UI»); tirador ≥ `slider_grabber_px`.
  En escritorio, las mismas medidas escaladas por `UiScale` (texto ≥ 24 px a 720).
- **Cabida sin desplazamiento:** a 1080 de alto con safe area inferior de 63 px quedan 1017 px; título (96 px) +
  6 filas (6 × 120 + 5 × 24 = 840 px) = 936 px. Hasta **6 filas** (contando «Volver») no hace falta scroll.
  Con la propuesta mínima (3 sliders + idioma + Volver) son 5. Por encima de 6, la lista va en un
  `ScrollContainer` que sigue al foco: +1 AC (ACp7).

## Ajustes candidatos (P2, propuestas sin aprobar)
Coste = AC que añade a esta feature y ficheros que toca más allá de los de la propuesta mínima
(`core/settings_store.gd`, `data/config/settings_defaults.tres`, `ui/menus/options_menu.{tscn,gd}`).
Filas = filas que suma a la pantalla.

| Id | Ajuste | Plataforma | Filas | AC extra | Ficheros extra | Dependencias y riesgo | Recomendación del diseño |
|---|---|---|---|---|---|---|---|
| C1 | Volumen Música, Ambiente, Efectos | Todas | 3 | — (AC1–AC11) | `autoload/audio_director.gd` | Ninguna: `AudioMix.set_volume` ya existe | **Aprobado** (Should del alcance) |
| C2 | Idioma (castellano / gallego) | Todas | 1 | 1 (ACp1) | `data/i18n/options.*` | P1 (qué idiomas); claves de PUL-168, textos de PUL-173; cambio en caliente de ADR-007 | Incluir si P1 aprueba gallego (propuesta de PUL-171) |
| C3 | Pantalla completa / ventana | Escritorio | 1 | 1 (ACp2) | 1 adaptador que aplique `DisplayServer.window_set_mode` al arrancar (ADR-007) | Oculto en táctil (Android siempre a pantalla completa) | Incluir: barato y esperado en PC |
| C4 | Sincronización vertical (VSync) | Escritorio | 1 | 1 (ACp3) | El mismo adaptador que C3 | Oculto en táctil; objetivo de 60 fps de D22 | Opcional |
| C5 | Tilt-shift (desenfoque de maqueta) | Todas | 1 | 1 (ACp4) + 1 captura | `resources/render_config.gd` (cambio en caliente), quien aplica `camera_attributes` en el nivel y 1 señal nueva en `signals.md` | D22 lo hace opcional y hoy está a `false`; toca el nivel (dueño en O5: PUL-175) | Opcional; mejor fuera de la alpha si el nivel no puede tener otro dueño |
| C6 | Repetir tutorial | Todas | 1 | 1 (ACp5) | API del tutorial de ADR-007 (PUL-169) | P5: solo si el tutorial entra y su entrada no es ya un botón del menú | Solo si P5 elige (a) automático sin botón |
| C7 | Restablecer valores por defecto | Todas | 1 | 1 (ACp6) | — | Ninguna | Opcional, barato |
| C8 | Reasignar controles | Escritorio | ≥ 1 (pantalla propia) | ≥ 3 | Pantalla nueva, persistencia del `InputMap`, conflictos de teclas entre P1 y P2 | Choca con la tecla única de D26 y con `mando-y-reasignacion.md` | Fuera de la alpha |
| C9 | Resolución | Escritorio | 1 | 1–2 | Adaptador de C3 | Con `stretch = canvas_items` + `expand` aporta poco | Fuera de la alpha |

Con la propuesta mínima (C1 + C2) la pantalla tiene 5 filas y PUL-171 queda en 5 AC. Con todo lo
«incluir/opcional» (C1–C7) son 10 filas: hace falta scroll (ACp7) y PUL-171 pasa de 5 AC, así que se parte
(regla de su ficha).

## Criterios de aceptación
Núcleo aprobado (C1). Los tests citados son los de `owns` de PUL-167 (`test_settings_store.gd`,
`test_settings_persistence.gd`) y PUL-171 (`test_options_menu.gd`; las rutas definitivas las fija ADR-007).

- **AC1 (apertura desde el menú)** Given el menú principal de escritorio, When se activa «Opciones», Then la pantalla
  se muestra en ≤ 1 frame con el foco en la fila Música; When se pulsa «Volver» o 1 vez `ui_cancel`, Then se vuelve al
  menú en ≤ 1 frame con el foco en «Opciones». *Test:* `test_options_menu.gd`.
- **AC2 (apertura desde la pausa)** Given una partida en pausa, When se activa «Opciones» y pasan 2,0 s, Then
  `get_tree().paused` sigue `true` y el tiempo de ronda avanza 0,0 s; When se pulsa 1 vez `ui_cancel` (o `pause`),
  Then se vuelve a la pausa con el foco en «Opciones» y el juego sigue en pausa; When se pulsa otra vez `ui_cancel`,
  Then la partida se reanuda. *Test:* `test_options_menu.gd`.
- **AC3 (sliders)** Given los 3 sliders (Música, Ambiente, Efectos) de 0 a 100 % con `volume_step` = 10 %, When el foco
  está en Música a 70 % y se pulsa 1 vez `ui_right`, Then vale 80 % y el texto muestra «80 %»; When desde 100 % se
  pulsa 10 veces `ui_left`, Then vale 0 %, y una 11.ª pulsación lo deja en 0 %. *Test:* `test_options_menu.gd`.
- **AC4 (bus)** Given un slider de volumen fuera de pausa, When se fija a 0 %, 50 % y 100 %, Then en el mismo frame su bus
  queda a −80 dB, −6,02 ± 0,01 dB y 0 ± 0,01 dB, y el cambio pasa por `AudioDirector.set_volume` (0 llamadas a
  `AudioServer.set_bus_volume_db` desde `ui/` ni `core/settings_store.gd`, comprobado con `grep`).
  *Test:* `test_settings_persistence.gd` + `test_options_menu.gd`.
- **AC5 (valores por defecto)** Given que no existe `user://settings.cfg`, When se crea el núcleo de ajustes, Then Música
  = 0,70, Ambiente = 0,70 y Efectos = 1,00 (± 0,001), leídos de `settings_defaults.tres`; Given ese `.tres` con Música
  = 0,5, Then el valor inicial es 0,50 sin cambiar código. *Test:* `test_settings_store.gd`.
- **AC6 (persistencia)** Given Música cambiada de 70 % a 40 %, When pasan `save_debounce` (0,5 s) o se cierra la
  pantalla, y se recrea el núcleo, Then Música = 0,40 ± 0,001 leído de `[audio] music` de `user://settings.cfg`;
  Given 10 cambios de slider en 1,0 s, Then el fichero se escribe ≤ 3 veces. *Test:* `test_settings_persistence.gd`.
- **AC11 (cambio continuo y suspensión)** Given un reloj inyectado y Música cambiada cada 0,1 s durante 3,0 s
  seguidos (arrastre), When pasa el tiempo, Then el fichero se escribe en t = 2,0 ± 0,05 s (`save_max_interval`, con el
  valor de ese instante) y en t = 3,5 ± 0,05 s (debounce tras el último cambio): 2 escrituras, ninguna más tarde de
  2,0 s tras un cambio sin guardar; Given un cambio de Música a 40 % en t = 0 y la notificación
  `NOTIFICATION_APPLICATION_PAUSED` en t = 0,2 s (antes de que venza el debounce), Then en ese mismo frame el fichero
  tiene `music = 0.4` (± 0,001); lo mismo con `NOTIFICATION_APPLICATION_FOCUS_OUT`; y Given 0 cambios pendientes, When
  llega la notificación, Then 0 escrituras. *Test:* `test_settings_persistence.gd`.
- **AC7 (fichero dañado)** Given un `settings.cfg` ilegible, o con claves desconocidas, o con `music=1.7`,
  `ambience=-0.2`, `sfx=0.75`, When se carga, Then hay 0 errores en consola, lo ilegible o ausente toma el valor por
  defecto y los valores quedan en 1,0, 0,0 y 0,8; el fichero se reescribe válido en ≤ 1 guardado.
  *Test:* `test_settings_store.gd`.
- **AC8 (teclado y mando)** Given la pantalla abierta con el foco en Música, When se pulsa `ui_down` N − 1 veces
  (N = filas visibles), Then el foco recorre todas las filas en orden y acaba en «Volver», con 0 frames sin foco, y
  otra pulsación lo deja en «Volver»; Given solo eventos de mando (cruceta, A, B), Then se hace el mismo recorrido,
  se cambia un volumen y se vuelve al menú de origen sin ningún evento de teclado. *Test:* `test_options_menu.gd`.
- **AC9 (táctil)** Given el perfil táctil a 2340×1080 con safe area 132 / 0 / 132 / 63, When se abre la pantalla,
  Then cada fila mide ≥ 120 px de alto con 24 ± 2 px entre filas, el texto ≥ 36 px, el tirador ≥ 72 px, 0 filas
  fuera de la safe area y 0 zonas táctiles solapadas; When se toca la pista de Música al 43 % de su ancho, Then
  vale 40 %; When se arrastra el tirador, Then el valor cambia en el mismo frame del evento. *Test:*
  `test_options_menu.gd` (o `test_options_menu_touch.gd`) + captura `options_touch_2340x1080.png` en `docs/evidence/PUL-171/`.
- **AC10 (muestra de efectos y capturas)** Given el foco en Efectos a 50 %, When se pulsa 1 vez `ui_right`, Then
  `fx_ui_click` suena 1 vez en el bus `SFX`, y 5 pulsaciones en 0,2 s lo hacen sonar ≤ 3 veces
  (`preview_min_interval` = 0,1 s); y existen 4 capturas (escritorio 1920×1080 y táctil 2340×1080, desde el menú y
  desde la pausa) con las filas legibles. *Test:* `test_options_menu.gd` + capturas en `docs/evidence/PUL-171/`.

### AC condicionados a G0 (solo si se aprueba el candidato)
- **ACp1 (C2 idioma)** Given el selector en «Castellano», When se cambia a «Galego», Then en ≤ 0,5 s el título y
  las etiquetas de la pantalla salen en gallego, `[locale] language = "gl"` y, tras recrear el núcleo, el juego
  arranca en gallego. *Test:* `test_options_menu.gd`.
- **ACp2 (C3 pantalla completa)** Given escritorio en ventana, When se activa «Pantalla completa», Then en ≤ 0,5 s
  `DisplayServer.window_get_mode()` es `WINDOW_MODE_FULLSCREEN` y se conserva al reiniciar; Given el perfil
  táctil, Then la fila no existe. *Test:* `test_options_menu.gd`.
- **ACp3 (C4 VSync)** Given escritorio, When se desactiva VSync, Then en ≤ 0,5 s
  `DisplayServer.window_get_vsync_mode()` es `VSYNC_DISABLED` y se conserva; en táctil la fila no existe.
  *Test:* `test_options_menu.gd`.
- **ACp4 (C5 tilt-shift)** Given una partida en pausa, When se activa «Tilt-shift» y se vuelve a la partida,
  Then los `camera_attributes` del nivel tienen `dof_blur_far_enabled = true` en ≤ 1 frame y se conserva al
  reiniciar. *Test:* GUT de la ficha dueña del nivel + capturas con y sin tilt-shift a 1920×1080.
- **ACp5 (C6 repetir tutorial)** Given el menú principal, When se activa «Repetir tutorial» en opciones, Then el
  nivel carga en modo tutorial en ≤ 3 s por la API de ADR-007. *Test:* `test_options_menu.gd`.
- **ACp6 (C7 restablecer)** Given Música 20 %, Ambiente 0 % y Efectos 50 %, When se activa «Restablecer», Then
  vuelven a 70 / 70 / 100 % en ≤ 1 frame y se guardan. *Test:* `test_options_menu.gd`.
- **ACp7 (scroll, solo si hay > 6 filas)** Given más de 6 filas a 2340×1080, When el foco baja hasta «Volver»,
  Then la fila con foco queda visible entera en todo momento (0 frames recortada) y un arrastre vertical táctil
  de 300 px desplaza la lista sin cambiar ningún valor. *Test:* `test_options_menu.gd`.

## Datos (`.tres`)
`SettingsDefaults` (*propuesta*; `data/config/settings_defaults.tres`, PUL-167; nombres finales en ADR-007):

| Campo | Valor | Unidad | Uso |
|---|---|---|---|
| `music_volume` | 0,7 | lineal 0–1 | Defecto de Música (AC5) |
| `ambience_volume` | 0,7 | lineal 0–1 | Defecto de Ambiente (AC5) |
| `sfx_volume` | 1,0 | lineal 0–1 | Defecto de Efectos (AC5) |
| `volume_step` | 0,1 | lineal | Paso del slider (AC3, AC7) |
| `save_debounce` | 0,5 | s | Espera tras el último cambio antes de guardar (AC6, AC11) |
| `save_max_interval` | 2,0 | s | Máximo desde el primer cambio sin guardar hasta escribirlo (AC11) |
| `preview_min_interval` | 0,1 | s | Mínimo entre muestras de Efectos (AC10) |
| `schema_version` | 1 | — | `[meta] schema` del fichero (AC7) |
| `language` *(si C2)* | P1 (`"es"` hoy, `textos-gallego.md` AC3) | código | Idioma por defecto (ACp1) |
| `fullscreen` *(si C3)* | `false` | bool | Defecto en escritorio (ACp2) |
| `vsync` *(si C4)* | `true` | bool | Defecto en escritorio (ACp3) |
| `tilt_shift` *(si C5)* | `false` | bool | Igual que `render_config.tres` hoy (ACp4) |

Perfil de UI (`UiProfileData`, `data/config/ui_profile_{mobile,desktop}.tres`; campos nuevos *propuestos*):

| Campo | Táctil | Escritorio | Uso |
|---|---|---|---|
| `menu_button_min_px` (ya existe) | 120 | (escala `UiScale`) | Alto mínimo de fila (AC9) |
| `menu_button_gap_px` (ya existe) | 24 | (escala `UiScale`) | Hueco entre filas (AC9) |
| `options_card_width` | 1080 | 1080 | Ancho de la tarjeta de opciones a 1080 de alto |
| `slider_grabber_px` | 72 | 48 | Tamaño mínimo del tirador (AC9) |
| `options_max_rows_without_scroll` | 6 | 6 | Umbral para el `ScrollContainer` (ACp7) |

Ya existen y no se duplican: `pause_duck_db` (−12 dB, `audio_mix.tres`) y el texto mínimo de 36 px a 1080
(`controles-tactiles.md`). Constantes de contrato, no configurables: −80 dB para 0 % (ADR-006 §2) y la ruta
`user://settings.cfg`. Los límites de los AC (≤ 1 frame, ≤ 0,5 s, tolerancias) son criterios de prueba, no datos.

## Verificación
GUT: AC1–AC11 y los ACp aprobados (`test_settings_store.gd`, `test_settings_persistence.gd` de PUL-167;
`test_options_menu.gd` de PUL-171). Capturas en `docs/evidence/PUL-171/`: AC9, AC10 y ACp4.

## Preguntas abiertas (para G0)
- **P2 (plan de M4)** ¿Qué ajustes entran además del volumen? Candidatos C2–C9 con su coste arriba. Propuesta
  del diseño: C1 + C2 (5 filas, PUL-171 en 5 AC); C3 y C7 si se acepta partir PUL-171; C8 y C9 fuera.
- **O1** Si entra C5 (tilt-shift), ¿qué ficha es dueña del cambio en el nivel, si `level_01.tscn` es de PUL-175 en O5?
- **O2** Si entra C6, ¿«Repetir tutorial» va en opciones o como botón del menú principal (P5 b/c)? No deben existir los dos.
- **O3** ¿El menú principal táctil muestra «Opciones» (y «Créditos»)? Cambia `menu-principal.md` AC6 (hoy solo
  «Individual»); sin ello, en móvil se llega a opciones solo desde la pausa.
- **O4** (para ADR-007) ¿Fuente única de los volúmenes por defecto: `settings_defaults.tres` o `audio_mix.tres`?
  Hoy los dos tendrían 0,7 / 0,7 / 1,0.
