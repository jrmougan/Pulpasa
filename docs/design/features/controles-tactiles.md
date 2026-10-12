# Móvil: controles táctiles, cámara móvil y escala de UI (Must, D26)

**Slug:** controles-tactiles · **Prototipo:** ninguno (nuevo en D26). **Estudio:**
`docs/evidence/PUL-119/README.md` (legibilidad en 800×370, 1280×720 y 2340×1080; auditoría de input
y UI). **Lenguaje de acciones:** `lenguaje-acciones.md` (el botón de acción muestra su icono).
**Contratos:** PUL-120 (`docs/arch/`, en paralelo). Los nombres de recursos de esta feature son
*(propuesta)* hasta que el contrato los fije.

## Descripción
Llevar el juego a teléfonos exige tres cosas que hoy no existen: **controles táctiles**, una **cámara
con más zoom** (con la actual, un personaje de 1,6 m mide ~107 px a 2340×1080 y un dispensador ~1,2 mm
en un 6") y una **UI escalada** (texto, tickets y HUD no caben ni se leen en 800×370, y no hay safe area
ni escalado de menús).

**Alcance (D26):**
- **Solo Individual** con cambio de personaje (D3). Local 2P sigue siendo de PC/mando.
- **Apaisado** (orientación fija). Relación de aspecto soportada: de 16:9 (1.920×1.080) a 2,4:1
  (2.400×1.000). Referencia de diseño: **2340×1080**.
- **Fuera de esta oleada:** export Android, preset de exportación, renderizador móvil (Compatibility/
  Mobile), rendimiento en dispositivo, tiendas. Ficha aparte cuando haya toolchain y dispositivo. Los
  criterios de aquí se verifican **en PC** con el perfil táctil forzado y eventos de pantalla
  simulados, a las resoluciones indicadas.

Unidad: **1 dp ≈ 2,5 px a 1080 de alto** (`dp_px`); en otros altos, `dp_px × alto / 1080`. Con
~420 ppi, 48 dp = 120 px ≈ 7,3 mm (blanco táctil mínimo recomendado).

### Perfiles
| Perfil | Cuándo | Qué cambia |
|---|---|---|
| **Escritorio** (el actual) | PC, mando | Sin cambios: teclado/mando, cámara actual, menú con Individual / Local 2P / Salir |
| **Táctil** | `OS.has_feature("mobile")`, o forzado por la bandera de desarrollo `--touch` *(propuesta)* para verificar en PC | Controles táctiles, cámara móvil, UI escalada a 1080, menú solo Individual |

Si en el perfil táctil llega un evento de mando (stick o botón), los controles táctiles se **ocultan**
y vuelven a aparecer con el siguiente toque de pantalla. El teclado no oculta nada.

## Controles táctiles
```
  2340×1080, safe area (izq 132 · der 132 · inf 63)

  ┌─ HUD ───┐ ┌── 4 tickets (fila) ─────────────────────────┐   ┌pausa┐
  │ 120 €   │ │ #1 │ │ #2 │ │ #3 │ │ #4 │                     │   │ ‖   │ 120 px
  │ 04:32   │ └────┘ └────┘ └────┘ └────┘                     │   └─────┘
  └─────────┘                                                  (y ≤ 200: banda superior)
  ·····················································································
  ZONA DEL STICK (x < 1170, y ≥ 200)           ZONA DE BOTONES (x ≥ 1950, y ≥ 600)
   toque → aparece la base (300 px)                              ┌───────┐
        ◯ base ── ● pulgar                                       │cambiar│ 120 px
                                                                 └───────┘
                                                                 ╭───────╮
                                                                 │ verbo │ 180 px (72 dp)
                                                                 ╰───────╯
```

### Stick flotante (movimiento)
- **Zona:** la mitad izquierda de la pantalla (`stick_zone_fraction` = 0,5 del ancho útil), por debajo
  de la banda superior (`y ≥ 200 px`). Un toque nuevo en la zona hace **aparecer la base** centrada en
  el punto de contacto (clampeada para que la base quede entera dentro de la safe area); soltar la
  desvanece en 0,15 s y el movimiento vuelve a 0.
- **Medidas** (a 1080 de alto): base de **300 px** de diámetro (120 dp), pulgar de **150 px**,
  radio de recorrido `stick_radius_px` = **150 px**. Si el dedo supera el radio, la **base lo sigue**
  (el dedo queda en el borde, magnitud 1,0).
- **Respuesta:** analógica; magnitud = distancia / 150 px, con **zona muerta de 0,2** (30 px), como el
  mando (`mando-y-reasignacion.md` AC1). La dirección alimenta el movimiento del personaje activo
  igual que el stick del mando; velocidad máxima `move_speed` (5 m/s).
- **Prioridad:** un toque que empieza sobre un botón o el HUD no inicia el stick.

### Botón de acción (el que enseña el verbo)
- **Tamaño:** círculo de **180 px** (72 dp) con zona táctil de **204 px** (`hit_slop_px` 12). Anclado
  abajo a la derecha de la safe area con **48 px** de margen a los bordes
  (`button_margin_px`). Con safe area (132, 0, 132, 63) a 2340×1080: centro (2070, 879).
- **Contenido:** el **icono del verbo** del objetivo activo de ese jugador (96 px dentro del botón),
  **el mismo que el prompt del mundo** (`lenguaje-acciones.md`). Estados:

| Situación | Botón | Icono |
|---|---|---|
| Sin objetivo y **mano vacía** | **Gris** `#6B6B73`, sin aro | COGER atenuado al 40 % |
| Objetivo OK (incluye SOLTAR al suelo con la mano llena) | Oscuro con **aro blanco** | Verbo en blanco |
| Objetivo BLOQUEADO | Oscuro con **aro ámbar** `#FFB020` | Verbo en ámbar + aspa × + icono de motivo (32 px) |

- **Pulsar** = una pulsación de interactuar (misma acción que `pN_interact`). **Mantener** repite solo
  si el verbo al empezar era CORTAR, cada `cut_repeat_interval` (0,2 s; `lenguaje-acciones.md` AC13);
  con cualquier otro verbo, mantener no repite.
- **Respuesta:** el botón se hunde (escala 0,92 en 0,1 s) y el icono responde igual que el prompt
  (salto de éxito o sacudida de rechazo). El botón cambia de icono ≤ 0,1 s tras cambiar el verbo.

### Botones de cambiar y pausa
- **Cambiar de personaje:** círculo de **120 px** (48 dp), encima del botón de acción con **24 px** de
  separación; icono de dos personajes con flechas. Misma acción que `p1_switch` (D11, < 0,2 s).
- **Pausa:** círculo de **120 px** en la esquina superior derecha de la safe area (48 px de margen).
  Misma acción que `pause`. La pausa muestra el menú de pausa escalado (más abajo).
- No hay gestos (deslizar, doble toque) ni toque sobre el mundo: el mundo no es táctil.

### Multitáctil
Mínimo **3 contactos simultáneos** (stick + acción + cambiar). Cada contacto pertenece al control
donde empezó hasta que se levanta: deslizar el dedo del stick sobre el botón no lo pulsa, y mover el
dedo de un botón fuera de él no lo cancela hasta soltar.

### Reglas generales
- Los controles táctiles generan **las mismas acciones de entrada** que teclado y mando (movimiento
  analógico, interactuar, cambiar, pausa); el resto del juego no distingue el origen. No se añaden
  acciones nuevas por sí mismos (el contrato decide cómo se alimentan).
- **Háptica** (Android): vibración corta de 20 ms en éxito y doble de 20 + 20 ms en rechazo;
  desactivable. *Propuesta*, ver pregunta 3.
- **Ciclo de vida:** perder el foco de la aplicación o la tecla Atrás **pausan** la partida; al volver
  no se reanuda sola. La pantalla no se apaga durante la partida.

## Cámara móvil
La cámara es ortográfica y fija en escritorio (D14); en el perfil táctil usa un **perfil propio**.

| Parámetro | Escritorio (actual) | Táctil | Dato |
|---|---|---|---|
| Escala en el personaje a 1080 de alto | 66,8 px/m | **≥ 120 px/m** (1,8×) | `px_per_meter_min` |
| Personaje (1,6 m) a 1080 de alto | 107 px | **≥ 192 px** | derivada |
| Seguimiento | Fija | Sigue al personaje **activo**, amortiguación crítica `follow_time` = **0,2 s** | `follow_time` |
| Cambio de personaje | — | Desplaza la cámara al nuevo activo en `switch_pan_time` = **0,35 s** (ease-out); el control pasa en < 0,2 s sin esperar a la cámara | `switch_pan_time` |
| Límites | Nivel entero | La vista no sale más de `camera_margin_m` = **1,0 m** del límite jugable del nivel | `camera_margin_m` (+ límites por nivel) |

La escala se mide **proyectando** los pies y la cabeza del personaje (1,6 m) con la cámara:
px/m = distancia en pantalla / 1,6. Con ≥ 120 px/m, a 1080 de alto se ven ≤ 9 m de profundidad útil
(el nivel mide unos 9–10 m de fondo): casi todo el nivel cabe en alto y el seguimiento mueve la vista
sobre todo en horizontal.

**Personaje inactivo fuera de cuadro:** si su posición proyectada queda fuera de la pantalla, una
**flecha de borde** (chevron de 48 px, `icon_mark_offscreen`, dentro de la safe area y a ≥ 16 px de los
controles) señala su dirección. Sin lógica nueva: solo lectura de su posición.

## Escala de UI
Referencia de diseño: **1080 de alto**. En el perfil táctil `ui_scale = alto / 1080`, limitado a
[0,67, 1,5] (`UiScaleData`, *propuesta*); el escritorio conserva su `UiScale` actual (alto/720, 1…2).
Los mínimos son de **1080** y escalan con `ui_scale`.

| Elemento | Mínimo a 1080 de alto | Notas |
|---|---|---|
| Texto de UI (tickets, HUD, tutorial, menús, pausa, game over) | **36 px** | A 720 de alto: 24 px |
| Prompt de acción (icono de verbo) | 64 px (placa 80 px) | `lenguaje-acciones.md` |
| Iconos de ticket (aliño, cachelos) | 48 px | |
| Barra de paciencia del ticket | 12 px de grosor | |
| Botones de menú, pausa y game over | **120 px de alto** (48 dp) y 24 px entre ellos | Hit area = visible |
| Botones del tutorial («Saltar») | 120 px de alto | |
| Barras y anillos en el mundo | ≥ 8 px de grosor | `lenguaje-acciones.md` |

### Maquetación de la banda superior (2340×1080, safe area 132 / 0 / 132 / 63)
| Pieza | Rectángulo (x, y, ancho × alto) |
|---|---|
| Bloque HUD (recaudación y tiempo, 2 líneas de 36–48 px) | (180, 24, 240 × 150) |
| Fila de **4 tickets** de 380 × 150 px y 16 px entre ellos | (444, 24, 1568 × 150) |
| Botón de pausa (esquina superior derecha) | (2040, 48, 120 × 120) |

- Ancho de ticket = `clamp(ancho disponible / 4, 330, 380)`: a 1920×1080 (sin safe area) cada ticket
  mide 342 px; el nombre más largo («Bravo cachelos», 14 caracteres) a 36 px cabe en 298 px útiles sin
  «…». Altura de la banda superior ≤ 200 px (≤ 18,5 % del alto; AC15).
- **Zonas reservadas** (nada del HUD ni de los tickets las toca): **zona del stick** x < 50 % del ancho,
  y ≥ 200 px; **zona de botones** x ≥ ancho − 390 px, y ≥ 600 px. La flecha de borde y los prompts del
  mundo están exentos (se dibujan sobre el mundo), pero la flecha evita los botones.
- El HUD ya **no muestra «Cajas / minuto»** (la métrica es la recaudación, D2); solo recaudación,
  tiempo y fase.

### Menús y flujos
- **Menú principal:** solo **Individual** (las demás opciones del escritorio se ocultan en el perfil
  táctil: Local 2P es de PC/mando y «Salir» no es una acción móvil); botón ≥ 120 px de alto, foco
  inicial en Individual.
- **Pausa:** Reanudar, Reiniciar y Menú, botones ≥ 120 px; reanudar ≤ 0,1 s.
- **Game over:** recaudación y estrellas con texto ≥ 36 px; Reintentar y Menú ≥ 120 px.
- **Tutorial** (`tutorial-breve.md`): el paso 1 señala el stick y el botón de acción.

## Contadores del pasaplatos bajo los botones (caso 09, PUL-136)
*Propuesta pendiente de gate humano.* Medidas y capturas: `docs/evidence/PUL-136/README.md`.

**Problema.** Con el activo en las ollas, la banda superior empuja la vista al norte y la fila de
pasaplatos (z = 0) cae en la franja de botones. El contador N/6 de una caja en los pasaplatos 04-06
queda bajo los botones aunque el activo no la esté usando: el recorte este de PUL-134 no actúa porque
el activo está arriba, fuera de la franja (ADR-005 E5, «Limitación conocida»). Se mide con el activo en
reposo en las dos ollas: en su plaza (z −3,1) y en el punto más al norte al que llega caminando
(z −3,4; el centro de la olla no es alcanzable). Safe area nula, como en PUL-134.

| Medida (activo en las ollas) | 2340×1080 | 1920×1080 | 800×370 |
|---|---|---|---|
| Zona de botones de E4 (x ≥ …, y ≥ …) | 1950, 600 | 1530, 600 | 666, 205,6 |
| Borde inferior del contador, plaza z −3,1 / z −3,4 | 798 / 828 | 798–800 / 828 | 284 / 294 |
| Pasaplatos con el contador en la zona de E4 (olla oeste · olla este) | 04-06 · 05-06 | 04 · 04-06 | 04-06 · 05-06 |
| Pasaplatos con el contador bajo un botón visible o su margen de toque | 05-06 · 06 | 04 · 05-06 | 05-06 · 06 |

En la captura el solape real es el botón de cambiar sobre la barra del contador del pasaplatos 06 (y
del 05 a 2340×1080): el número se sigue leyendo, la barra no entera.

### Alternativas
| | **A. Mover el contador** | **B. Botones en fila** | **C. Aceptar la limitación** |
|---|---|---|---|
| Qué | Desplazar `CutCounter` de la caja: al oeste (A1, −0,85 m) o más alto (A2 +0,6 m, A3 +1,2 m) | El botón de cambiar pasa a la **izquierda** del de acción, alineado por abajo (24 px entre ellos); la zona de botones baja a `y ≥ alto − 240 px` (840 a 1080) | Dejar el caso 09 como está y anotarlo en el roadmap |
| Resultado (plaza z −3,1) | A1 sigue bajo los botones (2340: 06; 1920: 04-06; 800: 06). A3 sale de los botones visibles pero no de la zona de E4 (borde inferior 652 > 600) | **0 contadores en la zona** en las 3 resoluciones (borde inferior 798 frente a 840; 284 frente a 287,8) | 2-3 contadores tapados en parte |
| Resultado (z −3,4, extremo) | A3 a 800×370: 05-06 bajo los botones | 0 a 2340 y 1920 (828 frente a 840). **800×370: 6,4 px** de solape (294,2 frente a 287,8; 2,3 px con el botón visible) | Igual que arriba |
| Coste | `box.tscn` (escena con dueño); un contador flotando a 1,2 m pierde su caja; al oeste se monta con el de la caja vecina (1 m entre pasaplatos, contador de 1,08 m) | `touch_controls.gd` (colocación del botón de cambiar), `ui_profile_mobile.tres` (`button_zone_top_px` 600 → 840), tests de maquetación y de cámara. **Contrato**: la zona de E4 cambia de valor y, con safe area derecha, los botones en fila llegan a ancho − 516 px (132 + 384): la zona tiene que medirse desde el borde derecho de la safe area (la duda abierta de PUL-135) o ensancharse. ADR del arquitecto | 0 |
| Riesgo escritorio / Local 2P | **Sí**: la caja es la misma en todos los perfiles | **Ninguno**: `TouchControls` no existe en escritorio y `ui_profile_mobile.tres` solo se usa en móvil | Ninguno |
| Riesgo móvil | — | El pulgar recorre los botones en horizontal (patrón habitual); las zonas táctiles siguen tangentes (174 px entre centros = 102 + 72), como hoy en vertical. La franja de botones tapa menos mundo, así que el recorte este actúa menos | El jugador no ve el progreso de una caja ajena mientras cuece |
| Cómo se mide | Sonda o test: rectángulo del contador frente a la zona | Test con el nivel real: rectángulo del contador frente a la zona nueva y a los discos de los botones | — |

Descartadas sin medir: reordenar los pasaplatos o hacer un mapa móvil (`level_01.tscn`, rediseño de
estaciones, afecta a escritorio y Local 2P) y sesgar la cámara al este (PUL-134: a 1920×1080 saca al
activo de la safe area en la nevera).

### Recomendación: B (botones en fila)
Es la única que deja los contadores fuera de la zona sin tocar la caja ni el nivel, y el cambio queda
dentro del perfil móvil. Como se toca el contrato de E4 (valor de la zona y su referencia con safe
area), se puede resolver en la misma ADR la duda de PUL-135. Residuo: a 800×370 con el activo pegado al
norte de las ollas (z −3,4), la barra del contador solapa 6,4 px con el margen de toque del botón de
acción (2,3 px con el botón visible). **Variante B+A2** si el responsable quiere 0 también ahí: subir el
contador 0,6 m (bordes inferiores 755 y 269,2, sin solape en ningún caso); cuesta tocar `box.tscn` y
cambia la caja en escritorio y Local 2P.

### Criterios de aceptación para la ficha de implementación (si se elige B)
Se verifican como el resto, en PC con perfil táctil, a 2340×1080, 1920×1080 y 800×370, con safe area
nula y con la de diseño (132 / 0 / 132 / 63).
- **B-AC1 (botones en fila)** Given 2340×1080 con safe area nula, Then el botón de acción sigue en
  (2202 ± 2, 942 ± 2) y 180 ± 2 px; el de cambiar mide 120 ± 2 px, su centro está en (2028 ± 2,
  972 ± 2) (a su izquierda, borde inferior alineado ± 2 px, 24 ± 2 px de hueco horizontal) y las zonas
  táctiles no se solapan. Sustituye la colocación de AC3 («sobre el de acción»). *Test:*
  `test_touch_layout.gd`.
- **B-AC2 (zona de botones)** Given las 3 resoluciones y ambas safe areas, Then cada botón con su margen
  de toque queda dentro de la zona de botones que usa la cámara, y la zona empieza en y = alto − 240 px
  × alto / 1080 (840 a 1080, 287,8 a 370). *Test:* el de PUL-135.
- **B-AC3 (caso 09)** Given una caja con contador en cada pasaplatos 01-06 y el activo en reposo en cada
  olla, en su plaza (z −3,1), Then ningún contador interseca la zona de botones ni los discos táctiles en
  las 3 resoluciones; Given el activo en z −3,4, Then 0 a 2340×1080 y 1920×1080, y a 800×370 el solape
  es ≤ 8 px (0 si se elige B+A2). *Test:* `test_camera_button_zone.gd`.
- **B-AC4 (sin regresión)** Given el activo en la plaza de cada estación con widget, Then AC2 de PUL-134
  sigue en 0 cruces; Given el perfil de escritorio, Then no hay `TouchControls` y la caja no cambia.
  *Test:* `test_camera_button_zone.gd` y suite existente.
- **B-AC5 (captura)** Capturas del caso 09 a las 3 resoluciones en `docs/evidence/<ficha>/`.

## Criterios de aceptación
Se verifican en PC con el perfil táctil forzado, `emulate_touch_from_mouse` desactivado y eventos de
pantalla de GUT/MCP; resoluciones 2340×1080 (con la safe area simulada 132 / 0 / 132 / 63),
1920×1080 (sin safe area) y 1600×720 (para la escala). Dimensiones en px de pantalla.

- **AC1 (perfil)** Given `--touch` (o `OS.has_feature("mobile")`), When arranca el menú principal, Then solo hay el botón «Individual» (sin «Local 2P» ni «Salir»), con foco inicial; When se pulsa, Then el nivel carga en ≤ 3 s con `mode = SINGLE`; Given el perfil de escritorio, Then los 3 botones siguen. *Test:* `test_main_menu_touch.gd`.
- **AC2 (botón de acción)** Given 2340×1080 con la safe area simulada, Then el botón de acción mide 180 ± 2 px de diámetro, su zona táctil ≥ 204 px, su centro está en (2070 ± 2, 879 ± 2) y a ≥ 48 px de los bordes de la safe area; a 1920×1080 sin safe area su centro es (1782 ± 2, 942 ± 2). *Test:* `test_touch_layout.gd`.
- **AC3 (cambiar y pausa)** Given 2340×1080, Then el botón de cambiar mide 120 ± 2 px, está sobre el de acción con una separación vertical de 24 ± 2 px; el de pausa mide 120 ± 2 px y está en (2100 ± 2, 108 ± 2); ningún par de zonas táctiles se solapa. *Test:* `test_touch_layout.gd`.
- **AC4 (stick flotante)** Given un toque nuevo en (300, 700), Then la base (300 px) aparece centrada en ese punto; When el dedo se desplaza 75 px, Then la magnitud es 0,50 ± 0,02; a 20 px (< 30 px de zona muerta) es 0; a 150 px o más es 1,0; When el dedo llega a 400 px, Then la base lo sigue y el dedo queda a 150 px de su centro (magnitud 1,0); When se levanta, Then la magnitud es 0 en ≤ 1 frame y la base se desvanece en 0,15 s. Given un toque en (140, 1000), Then la base queda entera dentro de la safe area (centro (282, 867)). Given un toque en x ≥ 1170 o sobre un botón, Then no hay stick. *Test:* `test_virtual_stick.gd`.
- **AC5 (multitáctil)** Given tres contactos a la vez (stick, acción, cambiar), Then el personaje se mueve con la magnitud del stick, se emite 1 interactuar y 1 cambiar, y ninguno interfiere con los otros; Given un dedo que empieza en el stick y pasa por encima del botón de acción, Then el botón no se pulsa; Given un dedo que empieza en el botón y sale de él, Then la pulsación sigue hasta levantar. *Test:* `test_touch_multitouch.gd`.
- **AC6 (mismas acciones)** Given cada control táctil, When se activa, Then se producen las mismas acciones de entrada que teclado/mando del jugador 1 (movimiento analógico, interactuar, cambiar, pausa) y el personaje reacciona igual que con el stick del mando (`mando-y-reasignacion.md` AC1) con el mismo `move_speed` (5 ± 0,1 m/s con magnitud 1,0 durante 1 s). *Test:* `test_touch_input.gd`.
- **AC7 (latencia)** Given un toque en el botón de acción, When llega el evento, Then la acción de interactuar se emite en el mismo frame; Given un cambio de verbo del objetivo, Then el icono del botón se actualiza en ≤ 0,1 s. *Test:* `test_touch_input.gd` (reloj inyectado).
- **AC8 (el botón enseña el verbo)** Given seis casos de la tabla de `lenguaje-acciones.md` (sin objetivo con mano vacía; COGER del pulpo; CORTAR con pulpo cocido; ALIÑAR PICANTE sustituyendo; BLOQUEADO por caja a medias; SOLTAR con la mano llena sin objetivo), Then el botón muestra respectivamente: gris con COGER atenuado; aro blanco + COGER; aro blanco + CORTAR; aro blanco + ALIÑAR PICANTE; aro ámbar + aliñar en ámbar + × + `caja a medias`; aro blanco + SOLTAR; y el icono coincide con el del prompt del mundo en todos. *Test:* `test_action_button.gd`.
- **AC9 (mantener = atajo solo de corte)** Given el verbo CORTAR con pulpo cocido y una caja vacía, When se mantiene pulsado el botón de acción 1,05 s (reloj de juego), Then la caja tiene 6 cortes y no hay un 7.º; Given el verbo COGER, When se mantiene 2 s, Then se coge una vez y no hay más acciones. *Test:* `test_action_button.gd`.
- **AC10 (zoom móvil)** Given el perfil táctil a 1080 de alto (2340×1080 y 1920×1080), When se proyectan los pies y la cabeza (1,6 m) del personaje activo, Then la altura en pantalla es ≥ 192 px (≥ 120 px/m); Given el perfil de escritorio, Then sigue en 107 ± 2 px (66,8 px/m, sin regresión). *Test:* `test_camera_profile.gd`.
- **AC11 (seguimiento suave)** Given el personaje activo corriendo a 5 m/s durante 2 s, Then permanece siempre en el 60 % central del alto y el 80 % central del ancho de la pantalla; When se detiene, Then el desfase cámara-personaje es ≤ 0,1 m (≤ 12 px) a los 0,6 s y la cámara no oscila (sin cruzar el objetivo). *Test:* `test_camera_follow.gd` (física a paso fijo).
- **AC12 (cambio de personaje)** Given Individual con los personajes separados > 8 m, When se pulsa cambiar, Then el control pasa en < 0,2 s (D3), la cámara llega al nuevo activo en 0,35 ± 0,05 s con ease-out (sin salto), y 0,5 s después el activo está en el 60 % central; Given el inactivo fuera de cuadro, Then hay una flecha de borde de ≥ 48 px, dentro de la safe area y a ≥ 16 px de los botones, apuntando a su dirección. *Test:* `test_camera_follow.gd`.
- **AC13 (límites de cámara)** Given el personaje en cada esquina del nivel, Then la vista nunca muestra más de 1,0 m fuera de los límites jugables. *Test:* `test_camera_follow.gd`.
- **AC14 (texto mínimo)** Given el perfil táctil a 2340×1080, When un test recorre todos los `Label` y `RichTextLabel` de HUD, tickets, tutorial, menú principal, pausa y game over, Then ninguno efectivo mide < 36 px; a 1600×720 ninguno < 24 px. *Test:* `test_ui_scale.gd`.
- **AC15 (4 tickets sin recortar)** Given 4 comandas vivas, una de ellas «Bravo cachelos», a 2340×1080 (con safe area) y a 1920×1080, Then ningún texto de ticket está recortado (sin «…» y ancho del texto ≤ ancho útil), los 4 tickets miden entre 330 y 380 px de ancho, la separación entre ellos es 16 ± 1 px, no se solapan con el bloque HUD ni con el botón de pausa (≥ 24 px de hueco) y la banda superior mide ≤ 200 px de alto. *Test:* `test_touch_hud_layout.gd` + captura.
- **AC16 (zonas reservadas)** Given el HUD, los tickets y los botones, Then ningún rectángulo de HUD o ticket interseca la zona del stick (x < 50 % del ancho, y ≥ 200 px) ni la zona de botones (x ≥ ancho − 390 px, y ≥ 600 px). *Test:* `test_touch_hud_layout.gd`.
- **AC17 (safe area)** Given la safe area simulada (132, 0, 132, 63), Then ningún control, texto, ticket ni prompt de UI queda dentro de los márgenes excluidos, y todos los botones táctiles están a ≥ 48 px de su borde; Given una safe area nula, Then la misma maquetación se ancla a los bordes con 48 px de margen. *Test:* `test_touch_hud_layout.gd`.
- **AC18 (menús)** Given el perfil táctil, Then en menú principal, pausa y game over todos los botones miden ≥ 120 px de alto y están separados ≥ 24 px, y los textos cumplen AC14; Given la pausa, When se pulsa «Reanudar», Then la partida continúa en ≤ 0,1 s. *Test:* `test_touch_menus.gd`.
- **AC19 (ciclo de vida)** Given una partida en curso, When la aplicación pierde el foco o llega la tecla Atrás, Then la partida pasa a pausa en ≤ 1 frame y, al recuperar el foco, sigue en pausa. *Test:* `test_app_lifecycle.gd` (notificaciones simuladas).
- **AC20 (mando sobre táctil)** Given el perfil táctil, When llega un evento de mando, Then los controles táctiles se ocultan en ≤ 1 frame y el personaje responde al mando; When llega un toque, Then reaparecen. *Test:* `test_touch_input.gd`.
- **AC21 (sin regresión en PC)** Given el perfil de escritorio, Then no se instancian controles táctiles, el HUD y los tickets conservan su tamaño actual y los flujos de teclado y mando de `mando-y-reasignacion.md` pasan. *Test:* suite existente + `test_touch_layout.gd`.

## Datos (`.tres`)
*(Nombres propuesta; el contrato los fija.)*
- **`TouchProfileData`** (`data/config/touch_profile.tres`): `dp_px` (2,5), `action_button_dp` (72),
  `secondary_button_dp` (48), `button_margin_px` (48), `button_gap_px` (24), `hit_slop_px` (12),
  `stick_radius_px` (150), `stick_base_diameter_px` (300), `stick_deadzone` (0,2),
  `stick_zone_fraction` (0,5), `stick_zone_top_px` (200), `stick_fade_s` (0,15), `haptics_enabled`
  (true), `haptic_ok_ms` (20), `haptic_reject_ms` (20 + 20).
- **`MobileCameraData`** (`data/config/mobile_camera.tres`): `px_per_meter_min` (120), `follow_time`
  (0,2), `switch_pan_time` (0,35), `camera_margin_m` (1,0), `offscreen_arrow_px` (48). Límites
  jugables por nivel en los datos del nivel.
- **`UiScaleData`** (`data/config/ui_scale.tres`): `reference_height` (1080), `scale_min` (0,67),
  `scale_max` (1,5), `text_min_px` (36), `ticket_width_min` (330), `ticket_width_max` (380),
  `ticket_height` (150), `ticket_gap` (16), `hud_block_width` (240), `top_band_max_px` (200),
  `menu_button_min_px` (120), `menu_button_gap_px` (24).

## Verificación
GUT para AC1–AC9, AC14–AC21 (eventos de pantalla sintéticos y reloj de juego inyectado) y AC10–AC13
(proyección con la cámara real y paso de física). Capturas a 2340×1080 y 1920×1080 con el perfil
táctil forzado en `docs/evidence/<ficha>/` para AC2, AC3, AC8, AC15 y AC17, y una captura a 1600×720
para AC14. La verificación en dispositivo real queda para la ficha de export Android.

## Preguntas abiertas
1. **Zurdos.** ¿Layout espejado (stick a la derecha, botones a la izquierda)? Es una opción de
   ajustes (Could); no cambia ningún criterio de aquí.
2. **Tamaño de los controles ajustable.** ¿Deslizador 0,8–1,3 de `ui_scale` de los controles? Could.
3. **Háptica.** ¿20 ms OK y 20 + 20 ms en rechazo es el patrón correcto? Se afina con dispositivo.
4. **Texto de 36 px a 1080.** A ~420 ppi mide ~2,2 mm de altura de «x»; la ficha lo fija en 36 px.
   Si el playtest en teléfono lo ve pequeño, sube `text_min_px` (dato) y se revisa el ancho de ticket.
5. **Sustitución de la zona de entrega.** En móvil no hay equivalente a «pulsar en el puesto»: la
   entrega es solo por zona (D26 §5), lo que ya es lo ideal para táctil.
6. **Orientación y notch.** El perfil asume safe area solo en los laterales y abajo; un recorte
   superior (cámara) se resuelve en la ficha de export con la safe area real del dispositivo.
