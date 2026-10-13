# PUL-160 — Evidencia

Fecha: 2026-10-14. Rama `jrmougan/pul-160`. Solo diseño: `docs/design/features/opciones-de-volumen.md` (reescrita)
y `docs/design/features/creditos-y-version.md` (nueva). Estado de G0: **sin decidir** (`decisions.md` llega a
D27; P2 y P4 del plan de M4 siguen abiertas), así que todo lo que no está en el alcance aprobado va como propuesta.

## AC1 — `opciones-de-volumen.md`: ≥ 6 AC con números y prueba

10 AC del núcleo aprobado + 7 condicionados a G0 (ACp1–ACp7). Todos Given/When/Then.

| AC | Números | Prueba |
|---|---|---|
| AC1 apertura desde el menú | ≤ 1 frame, 1 `ui_cancel` | `test_options_menu.gd` |
| AC2 apertura desde la pausa | 2,0 s en pausa → 0,0 s de ronda, 1 + 1 pulsaciones | `test_options_menu.gd` |
| AC3 sliders | 0–100 %, paso 10 %, 70 → 80 %, 10 + 1 pulsaciones | `test_options_menu.gd` |
| AC4 bus | 0 / 50 / 100 % → −80 / −6,02 ± 0,01 / 0 dB; 0 llamadas directas | `test_settings_persistence.gd` + `test_options_menu.gd` |
| AC5 valores por defecto | 0,70 / 0,70 / 1,00 ± 0,001; `.tres` a 0,5 | `test_settings_store.gd` |
| AC6 persistencia | 70 → 40 %, 0,5 s, ± 0,001; 10 cambios en 1,0 s → ≤ 3 escrituras | `test_settings_persistence.gd` |
| AC7 fichero dañado | 1,7 → 1,0; −0,2 → 0,0; 0,75 → 0,8; 0 errores; ≤ 1 guardado | `test_settings_store.gd` |
| AC8 teclado y mando | N − 1 pulsaciones, 0 frames sin foco, 0 eventos de teclado | `test_options_menu.gd` |
| AC9 táctil | 2340×1080, filas ≥ 120 px, 24 ± 2 px, texto ≥ 36 px, tirador ≥ 72 px, toque al 43 % → 40 % | `test_options_menu.gd` + captura |
| AC10 muestra y capturas | 1 sonido por paso, 5 pulsaciones en 0,2 s → ≤ 3; 4 capturas | `test_options_menu.gd` + capturas |
| ACp1–ACp7 | ≤ 0,5 s / ≤ 1 frame / ≤ 3 s / 300 px; condicionados | `test_options_menu.gd` (ACp4: GUT del dueño del nivel + capturas) |

## AC2 — Candidatos de P2 como propuestas

Revisión de la sección «Ajustes candidatos (P2, propuestas sin aprobar)»:

| Candidato | Estado en la feature | Coste (AC / ficheros extra) |
|---|---|---|
| C1 Volumen ×3 | **Aprobado** por el alcance de la alpha (`roadmap.md`, Should «opciones de volumen»), no por esta ficha | AC1–AC10 / `audio_director.gd` |
| C2 Idioma | Propuesta | 1 / `data/i18n/options.*` |
| C3 Pantalla completa | Propuesta | 1 / adaptador de pantalla (ADR-007) |
| C4 VSync | Propuesta | 1 / el mismo adaptador |
| C5 Tilt-shift | Propuesta | 1 + captura / `render_config.gd`, aplicador del nivel, 1 señal |
| C6 Repetir tutorial | Propuesta (depende de P5) | 1 / API de ADR-007 |
| C7 Restablecer | Propuesta | 1 / — |
| C8 Reasignar controles | Propuesta (recomendado fuera) | ≥ 3 / pantalla nueva, `InputMap` |
| C9 Resolución | Propuesta (recomendado fuera) | 1–2 / adaptador de C3 |

La elección queda en «Preguntas abiertas» (P2, O1–O4). **0 ajustes dados por aprobados sin gate**: el único
aprobado (C1) lo está por el alcance MoSCoW ya decidido; los AC de C2–C7 van aparte como ACp1–ACp7,
«solo si se aprueba el candidato». También queda como propuesta (O3) añadir «Opciones» al menú táctil, porque
cambiaría `menu-principal.md` AC6.

## AC3 — Créditos frente a `licenses.md`

```text
$ L=docs/assets/licenses.md; F=docs/design/features/creditos-y-version.md
$ grep -c 'CC BY' $L                       → 9   (8 iconos de game-icons.net + box.blend con iconos del atlas)
$ grep -c 'OFL' $L                         → 6   (Montserrat ×2, DSEG7, Liberation Sans + 2 modelos con letras de Montserrat)
$ grep -c '| MIT' $L                       → 2   (pepper-hot-solid ×2)
$ grep -c '| CC0 |' $L                     → 8   (cortesía, no exigidos)
$ grep -cE '^\| E[0-9]+ \|' $F             → 12  (E1–E11 atribución + E12 Godot)
$ grep -E '^\| E[0-9]+ \|' $F | grep -c 'CC BY'  → 7
$ grep -E '^\| E[0-9]+ \|' $F | grep -c 'OFL'    → 3
$ grep -E '^\| E[0-9]+ \|' $F | grep -c 'MIT'    → 2   (E8 Line Awesome, E12 Godot)
```

Filas con atribución exigida (columna «Licencia» con CC BY/OFL/MIT o «Atribución requerida» que empieza por
«Sí»/«Incluir», secciones «Confirmados» y «Creados»): **17** (líneas 10, 13, 14, 15, 17, 32, 51, 52, 53, 54, 55, 57,
58, 59, 60, 62, 63 de `licenses.md`). Cada una tiene su entrada:

| Línea | Fila | Entrada |
|---|---|---|
| 10, 13 | Montserrat (trazados y `.otf`) | E9 |
| 14 | DSEG7 Classic Bold | E10 |
| 15, 17 | `seasoning_station` v3, `order_stand` v3 (letras Montserrat + iconos del atlas) | E9 + E1, E2, E5, E6, E8 |
| 32 | `box.blend` (iconos del atlas, CC BY + MIT) | E1, E2, E5, E6, E8 |
| 51 | Liberation Sans | E11 |
| 52, 63 | Line Awesome «pepper-hot-solid» | E8 |
| 53 | Octopus (Lorc) | E1 |
| 54 | Salt shaker (Lorc) | E2 |
| 55 | Crosshair (Delapouite) | E4 |
| 57 | Olive (Delapouite) | E5 |
| 58 | Potato (Delapouite) | E6 |
| 59, 60 | Round star y su derivado (Delapouite) | E7 |
| 62 | Small fire (Lorc) | E3 |

Resultado: 9 filas CC BY → 7 entradas CC BY (una por obra; el derivado y el atlas no duplican), 6 filas OFL → 3
entradas OFL, 2 filas MIT → 1 entrada; 0 filas sin cubrir. Además, E12 (Godot Engine, MIT + componentes),
que no está en `licenses.md` y también exige el aviso en el binario.

La feature fija también el **formato de `LICENSES.txt`** (UTF-8 sin BOM, LF, 5 secciones fijas, bloque de 5 líneas
por atribución, carpeta `licenses/` con 5 textos completos) para PUL-170, y la **versión visible en 2 pantallas**
(menú principal y resultados, `v` + `application/config/version`; AC7–AC8).

**Hallazgos:** `godot/assets/CREDITS.md` no recoge Montserrat, DSEG7, Godot ni el CC0 de música y ambiente
(pregunta C6); la cobertura de las filas «iconos del atlas» depende de qué iconos usa el atlas (hoy E1, E2, E5, E6, E8,
según `box.blend`), y si cambia hay que actualizar la lista de la feature.

## AC4 — Valores numéricos en tablas «Datos (`.tres`)»

Valores configurables y su tabla:

| Feature | Valor | Campo en «Datos» |
|---|---|---|
| Opciones | Música 70 %, Ambiente 70 %, Efectos 100 % | `music_volume`, `ambience_volume`, `sfx_volume` |
| Opciones | Paso del slider 10 % | `volume_step` |
| Opciones | Guardado 0,5 s tras el último cambio | `save_debounce` |
| Opciones | Muestra de Efectos cada ≥ 0,1 s | `preview_min_interval` |
| Opciones | Esquema 1 | `schema_version` |
| Opciones | Idioma, pantalla completa, VSync y tilt-shift por defecto (si se aprueban) | `language`, `fullscreen`, `vsync`, `tilt_shift` |
| Opciones | Fila ≥ 120 px, hueco 24 px | `menu_button_min_px`, `menu_button_gap_px` (ya existen) |
| Opciones | Tarjeta de 1080 px | `options_card_width` |
| Opciones | Tirador ≥ 72 px (táctil) / 48 px | `slider_grabber_px` |
| Opciones | 6 filas sin scroll | `options_max_rows_without_scroll` |
| Créditos | Tarjeta 1440 / 1280 px | `credits_card_width` |
| Créditos | 120 px por pulsación, 900 px/s con el stick | `credits_scroll_step_px`, `credits_scroll_speed_px_s` |
| Créditos | Versión a 36 px, margen 24 px | `version_font_px`, `version_margin_px` |
| Créditos | Prefijo «v» | clave `version.label` (texto traducible) |

Números que no son datos configurables, y la feature lo dice: −80 dB a 0 % y la ruta `user://settings.cfg`
(contrato de ADR-006 §2 / ADR-007), `pause_duck_db` y el texto ≥ 36 px (ya en `audio_mix.tres` y
`controles-tactiles.md`), la versión (`project.godot`, PUL-170) y los límites de prueba de los AC (≤ 1 frame,
≤ 0,5 s, ± 2 px, 4,5:1). Las cifras de la prosa de maquetación (1017 px útiles, título de 96 px, 840 px) son
el cálculo que justifica `options_max_rows_without_scroll` = 6. **0 valores configurables solo en prosa.**

## AC5 — Verificación

```text
$ tools/verify.sh --quick
== gdformat --check
235 files would be left unchanged

== gdlint
Success: no problems found

== import

✓ verify OK
(exit 0)
```

```text
$ python3 tools/check_owns.py jrmougan/pul-160 main
check_owns: 4 rutas dentro de owns de PUL-160.
(exit 0)
```

Rutas: `docs/backlog/PUL-160-…md`, `docs/design/features/creditos-y-version.md`,
`docs/design/features/opciones-de-volumen.md`, `docs/evidence/PUL-160/README.md`.
