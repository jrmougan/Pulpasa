---
id: PUL-132
title: QA de D26
status: in_progress
milestone: M3e
role: qa-tester
deps: [PUL-131]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-132/**, godot/tests/integration/test_d26_no_mute_press.gd*, godot/tests/integration/test_d26_touch_flow.gd*, docs/backlog/PUL-132-qa-de-d26.md]
touches_scenes: []
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 4. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: ninguna

## Change
verificación de D26 en `level_01` contra `lenguaje-acciones.md` y
  `controles-tactiles.md`; guía de playtest para el responsable.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 `test_d26_no_mute_press.gd`: ≥ 40 combinaciones mano × objetivo sobre `level_01` real (no fixtures sueltos),
  cada pulsación con objetivo da exactamente una respuesta (éxito con su cue o `rejected` + motivo) y ninguna es muda;
  incluye los casos del estudio de PUL-119 (cortar crudo, 7.º corte, mismo aliño, caja a medias en dispensador/cuenco,
  caja errónea en la zona, olla con quemado).
- [x] AC2 `test_d26_touch_flow.gd`: partida en perfil MOBILE con `--touch` simulado solo con eventos táctiles
  (stick, acción, cambiar, pausa) que cocina, corta, aliña y entrega al menos una caja; multitáctil (stick + acción a la vez).
- [x] AC3 Capturas en `docs/evidence/PUL-132/` a 1280×720, 1920×1080, 2340×1080 `--touch` y 800×370 (con y sin `--touch`):
  prompt OK y BLOQUEADO, anillo de cocción listo y aviso de quemado, contador N/6, cuenco, zona encendida, aros activo
  e inactivo, HUD y tickets sin solaparse con stick y botones, game over sin controles táctiles.
- [x] AC4 Tabla de medidas en Evidence contra los AC de `controles-tactiles.md` y `lenguaje-acciones.md` (px reales del
  icono del prompt, botón de acción, texto mínimo, px por metro, grosor de anillos) con OK/KO por AC.
- [x] AC5 Lista de hallazgos con gravedad (sin arreglarlos fuera de owns) y guía de playtest breve para el responsable
  (qué probar en PC y en móvil, preguntas abiertas: soltar al suelo por accidente, zurdos, háptica, 36 px en un teléfono).
- [x] AC6 `tools/verify.sh` completo en verde.


## Plan
1. `tools/verify.sh` en verde antes de empezar (línea base).
2. AC1: `test_d26_no_mute_press.gd` sobre `level_01.tscn` real. El esperado de cada caso sale de una fila de
   `tests/fixtures/action_matrix.csv` (la tabla del diseño), colocada en una estación real del nivel
   (olla, pasaplatos, cubos, nevera, cachelera, rack, dispensadores, cuenco, puesto, barra). Se monta la mano y el
   estado, se pone a J1 de cara, se pulsa `E` con el teclado y el detector real, y se cuentan las respuestas.
3. AC2: `test_d26_touch_flow.gd`. Un `TouchWalker` (hereda de `level_walker.gd`) cambia teclas por contactos de
   pantalla (stick flotante, botón de acción, cambiar, pausa) y juega una comanda completa en MOBILE a 2340x1080 con
   safe area simulada. Una sonda cuenta las teclas (deben ser 0).
4. AC3/AC4: `capture_boot.gd` + `capture_d26.gd` (arrancan el nivel real con ventana a cada resolución, colocan cada
   situación, hacen la captura y vuelcan las medidas en px reales a JSON). `run_all.sh` las encadena.
5. AC5: hallazgos y guía de playtest (más abajo).
6. AC6: `tools/verify.sh` completo y `tools/check_owns.py`.

## Evidence

### Estado por AC
| AC | Resultado | Evidencia |
|---|---|---|
| AC1 | **PASA** | `godot/tests/integration/test_d26_no_mute_press.gd`: 58 combinaciones mano x objetivo en `level_01` real (12 de olla, 18 de estaciones simples, suelo y pared, 8 de caja suelta, 10 de dispensadores, 10 de cuenco) + 6 cortes y 7.º rechazado `full` + 2 rechazos seguidos a ~0,1 s (2 respuestas y 2 cues) + caja que no encaja en la zona. Incluye los casos de PUL-119: cortar crudo (`B1-M1`), 7.º corte (`B3-M2` y la secuencia de 7), mismo aliño (`D1-M8`, `D2-M9`), caja a medias en dispensador (`D1-M6`, `D2-M6`) y cuenco (`E1s0-M6`), olla con quemado (`C3-M0`, `C3b-M0`, `C3-M1`, `C3b-M1`), caja errónea en la zona. Cada pulsación da exactamente una `interaction_resolved`; OK cambia el mundo y no suena `rejected`; BLOQUEADO no cambia nada, trae su motivo y suena un solo `rejected`; las celdas `—` no son objetivo ni tienen contorno; mano vacía sin objetivo no responde. |
| AC2 | **PASA** | `godot/tests/integration/test_d26_touch_flow.gd`: MOBILE 2340x1080, solo `InputEventScreenTouch/Drag`: cambiar (4 veces), pausar y reanudar tocando «Reanudar», nevera con stick mantenido y acción a la vez (multitáctil), cocer, sacar, caja al pasaplatos, 6 cortes manteniendo el botón de acción (sin 7.º rechazado), aliño dulce y entrega por zona. 0 teclas. |
| AC3 | **PASA con observaciones** | `docs/evidence/PUL-132/<tag>-<escena>.jpg` para `1280x720-desktop`, `1920x1080-desktop`, `2340x1080-touch` (safe area simulada), `800x370-desktop` y `800x370-touch`. 14 escenas por resolución: vista general (HUD y 4 tickets), stick activo con botones (solo `--touch`), prompt OK (COGER), prompt BLOQUEADO (`caja a medias`), cuenco con 2 raciones, contador 3/6, anillo cociendo, listo y aviso de quemado, aros activo e inactivo, zona encendida, pausa, game over y menú. Observaciones: H-01 (en móvil el anillo de la olla queda fuera de pantalla); del `1920x1080-touch` solo se conservan las medidas (`1920x1080-touch-medidas.json`) para no engordar el repositorio. |
| AC4 | **KO parcial** | Tabla de medidas más abajo. KO: aro inactivo en móvil (4,6 px > 3 px, H-02) y anillo de olla fuera de pantalla en móvil (H-01). Los KO de 800x370 son esperados (fuera del rango soportado, ver nota). |
| AC5 | **PASA** | Hallazgos y guía de playtest más abajo. |
| AC6 | ver informe de entrega | `tools/verify.sh` completo en verde y `tools/check_owns.py` limpio. |

### Tabla de medidas (px reales de pantalla; entre paréntesis, equivalente a 1080 de alto)
Fuente: `docs/evidence/PUL-132/<tag>-medidas.json`, generado con `capture_d26.gd` (proyección con la cámara real y
nodos reales). Resultado OK/KO contra el AC de `controles-tactiles.md` (CT) o `lenguaje-acciones.md` (LA).

| Medida (AC) | Mínimo | 2340x1080 touch | 1920x1080 touch | 1920x1080 PC | 1280x720 PC | 800x370 touch | 800x370 PC | Resultado |
|---|---|---|---|---|---|---|---|---|
| Icono del prompt (LA AC3) | 64 a 1080; 48 a 720 | 64 | 64 | 64 | 48 | 48 | 48 | OK |
| Placa del prompt (LA AC3) | 80 a 1080 | 80 | 80 | 80 | 60 | 60 | 60 | OK |
| Icono de motivo / aspa (LA) | 32 / 24 | 32 / 24 | 32 / 24 | 32 / 24 | 24 / 18 | 24 / 18 | 24 / 18 | OK a 1080 |
| Botón de acción, zona táctil (CT AC2) | 180 +-2, zona 204 | 180 / 204 | 180 / 204 | n/a | n/a | 61,7 / 69,9 (180 / 204) | n/a | OK |
| Centro del botón de acción (CT AC2) | (2070,879) / (1782,942) | (2070, 879) | (1782, 942) | n/a | n/a | (752, 323) | n/a | OK |
| Margen a los bordes (CT AC2) | >= 48 | 48 / 48 | 48 / 48 | n/a | n/a | 16,4 (48) | n/a | OK |
| Cambiar, hueco y pausa (CT AC3) | 120 +-2; 24 +-2; pausa (2100,108) | 120 / 24 / (2100,108) | 120 / 24 / (1812,108) | n/a | n/a | 41 (120) / 8,2 (24) | n/a | OK |
| Stick (CT AC4) | base 300, radio 150 | 300 / 150 | 300 / 150 | n/a | n/a | 102,8 (300) | n/a | OK |
| Texto mínimo (CT AC14) | 36 a 1080; 24 a 720 | 36 | 36 | 22,5 (HUD 19,5) | 13 (HUD) | 12,3 (36) | 6,7 | OK en táctil con alto >= 720; PC sin cambios (AC21) |
| Botones de menú, pausa y game over (CT AC18) | >= 120 | 120 | 120 | 78-90 | 52-60 | 41 (120) | 27-31 | OK en táctil |
| 4 tickets: ancho, hueco, banda (CT AC15) | 330-380; 16 +-1; <= 200 | 380 / 16 / 174 | 342 / 15 / 174 | n/a | n/a | 130 / 5,5 / 59,6 (escalado) | n/a | OK |
| HUD y tickets fuera de zonas del stick y botones (CT AC16) | 0 solapes | 0 | 0 | n/a | n/a | 0 | n/a | OK |
| Px por metro, personaje (CT AC10) | >= 120 (>= 192) | 121,6 (194,5) | 121,6 (194,5) | 66,8 (106,9) | 44,5 (71,3) | 41,7 (121,6 a 1080) | 22,9 | OK |
| Anillo de cocción: grosor / diámetro (LA AC15) | >= 8 / >= 64 a 1080 | 8 / 64 | 8 / 64 | 8 / 64 | 5,3 / 42,7 (8 / 64) | 2,7 / 21,9 (8 / 64) | 2,7 / 21,9 | OK a 1080; **fuera de pantalla en móvil (H-01)** |
| Barra del contador y numeral (LA AC14) | >= 8; >= 36 | 16,7 / 68,9 | 16,7 / 68,9 | 9,2 / 37,8 | 6,1 / 25,2 | 5,7 / 23,6 | 3,1 / 13 | OK a 1080 |
| Muesca del cuenco (LA AC17) | >= 24 | 24 | 24 | 24 | 16 (24) | 8,2 (24) | 8,2 | OK a 1080 |
| Aro del activo (LA AC18) | >= 8 | 18,5 | 18,5 | 10,2 | 6,8 (10,2) | 6,3 (18,5) | 3,5 (10,2) | OK a 1080 |
| Aro del inactivo (LA AC18) | <= 3 | **4,6** | **4,6** | 2,5 | 1,7 (2,5) | 1,6 (4,6) | 0,9 (2,5) | **KO en móvil (H-02)**; OK en PC |
| Marcador ▼ del activo (LA AC18) | >= 24 | 28 | 28 | 28 | 24 | 24 | 24 | OK |
| Zona de entrega encendida (LA F1) | se enciende con la caja que coincide | encendida | encendida | encendida | encendida | encendida | encendida | OK |
| Game over sin controles táctiles | ocultos | ocultos | ocultos | n/a | n/a | ocultos | n/a | OK |

Nota 800x370: es un proxy de teléfono fuera del rango soportado (alto >= 720 en escritorio; en móvil, 16:9 a 2,4:1 con 1080 de
referencia). `UiScale` limita `ui_scale` a [0,67; 1,5], así que a 370 de alto el texto «de 36» mide 24 unidades
(12,3 px reales) y los controles miden 0,34 de su tamaño. Las capturas a 800x370 sirven para ver composición y solapes
(no hay: la banda superior es el 16,1 % del alto), no para validar tamaños. Las columnas de PC no tienen controles táctiles (n/a);
sus solapes HUD/zona del stick no aplican.

### Hallazgos (por gravedad; no corregidos, fuera de `owns`)
| Id | Gravedad | Hallazgo | Dónde |
|---|---|---|---|
| H-01 | **Alta** | **En el perfil móvil el cocinero no ve el anillo de la olla ni su prompt cuando está en la fila trasera.** Con la cámara móvil (zoom 7,0) y el límite de 1,0 m, el personaje queda a ~230 px del borde superior y la olla, 0,9 m al norte, queda bajo la banda de tickets (174 px). Las medidas dan el anillo en y = -65 px (fuera de pantalla) a 2340x1080 y 1920x1080, y -22 px a 800x370. Se pierde justo la señal que D26.6 añadió (listo, aviso de quemado). Capturas: `2340x1080-touch-07-anillo-cociendo.jpg`, `-08-anillo-listo.jpg`, `-09-aviso-de-quemado.jpg` (la olla asoma bajo los tickets), frente a `1920x1080-desktop-09-aviso-de-quemado.jpg` (visible). Propuesta: ampliar `camera_margin_m` por el norte, desplazar el encuadre o subir el anillo/prompt de la fila trasera. | `godot/data/config/camera_mobile.tres`, `godot/entities/camera/camera_rig.gd` |
| H-02 | Media | El aro del personaje inactivo mide 4,6 px a 1080 con la cámara móvil (2,5 px en PC). Es un toro en metros: crece con el zoom (x1,82) y el AC de `lenguaje-acciones` pide <= 3 px. `test_player_ring.gd` lo mide con la cámara de escritorio y no lo ve. | `godot/entities/player/player.tscn` (`InactiveIndicator`), `godot/tests/integration/test_player_ring.gd` |
| H-03 | Baja | El game over sigue mostrando «Rendimiento: 0.00 cajas/minuto». D26 §7 y AC19 solo exigen quitarlo del HUD, pero la métrica de partida es la recaudación (D2). `2340x1080-touch-13-game-over.jpg`. | `godot/ui/menus/game_over.gd:46` |
| H-04 | Baja | Con GUT el panel `TestOutput` cubre la ventana y se queda con el puntero (también en headless): ningún test puede hacer clic real en un botón. `test_d26_touch_flow.gd` pone el `mouse_filter` de ese panel a IGNORE para poder tocar «Reanudar». Conviene resolverlo en la configuración de GUT si se añaden más tests de menús táctiles. | configuración de GUT |

No encontrado: ninguna pulsación muda en las 58 combinaciones, ningún rechazo con cambio de mundo, ninguna doble respuesta.

### Guía de playtest para el responsable
**En PC** (`godot --path godot`; con `-- --touch` para el perfil táctil forzado):
1. Coger, cocer, cortar, aliñar y entregar una comanda de principio a fin con teclado: mira el icono sobre el objetivo antes de pulsar y comprueba que en cada pulsación pasa algo (salto del icono, o sacudida con aspa y motivo).
2. Provoca rechazos a propósito: cortar con pulpo crudo, un 7.º corte, el mismo aliño dos veces, una caja a medias en un dispensador y en el cuenco, un pulpo en una olla llena. Debe sonar siempre el mismo cue de error, una vez.
3. Deja un cocido en la olla: anillo verde con check, luego parpadeo ámbar y rojo con cue cada segundo (aviso a los 7 s), quemado a los 10 s.
4. Mantén `E` sobre la caja con pulpo cocido: 6 cortes y para.
5. Cambia de personaje (Q) y compara el aro sólido y el ▼ del activo con el discontinuo del otro; entra en la zona del puesto con una caja que coincide (se enciende) y con una que no (nada).
6. Con `-- --touch`: el stick nace donde tocas, el botón de acción cambia de icono con el objetivo (gris sin objetivo, ámbar si está bloqueado); prueba pausa, game over y menú.

**En móvil** (cuando haya export; hoy solo se simula):
1. Pulgar izquierdo en el stick y derecho en la acción a la vez; pasa el dedo del stick por encima del botón (no debe pulsarlo).
2. Cocina en la fila trasera con la cámara móvil: ¿ves el anillo de la olla (H-01)?
3. Cambia de personaje con el botón: la cámara sigue al activo y la flecha de borde señala al otro.
4. Gira, bloquea y vuelve: la partida debe quedar en pausa.

**Preguntas abiertas para decidir tras jugar:**
- **Soltar al suelo por accidente:** al ser SOLTAR el verbo sin objetivo, ¿se suelta algo sin querer cerca de una estación que no admite lo que llevas, sobre todo con el pulgar? Si molesta, exigir mantener 0,3 s.
- **Zurdos:** ¿hace falta el layout espejado (stick a la derecha)?
- **Háptica:** ¿20 ms en éxito y 20 + 20 ms en rechazo es el patrón? Solo se afina con dispositivo.
- **36 px en un teléfono:** a ~420 ppi el texto mínimo mide ~2,2 mm; míralo en un 6" real y decide si sube `text_min_px`.
- **Tamaño de los controles:** ¿el botón de acción de 180 px tapa demasiado mundo?

### Reproducir
- Tests: `godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_d26` (desde `godot/`).
- Capturas y medidas: `bash docs/evidence/PUL-132/run_all.sh` (abre ventanas; cada resolución es una ejecución de `capture_boot.gd`).
