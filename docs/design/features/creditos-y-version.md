# Créditos y versión visible (publicación de la alpha)

**Slug:** creditos-y-version · **Ficha de diseño:** PUL-160 · **Implementación:** PUL-172 (pantalla, datos y
versión visible), PUL-170 (`LICENSES.txt` en el paquete) · **Prototipo:** no tiene.

## Por qué
La alpha se distribuye como `.zip` (PUL-170/176/179). Varios assets exigen atribución en la obra distribuida
(`docs/assets/licenses.md`): iconos de game-icons.net (CC BY 3.0), Line Awesome (MIT, texto de licencia) y tres
familias tipográficas (SIL OFL 1.1, aviso de copyright y licencia si se distribuye la fuente; van dentro del
`.pck`). El propio **Godot Engine** (MIT) exige incluir su aviso de copyright y licencia, y la de sus componentes
de terceros (FreeType, mbedTLS, etc.), en todo binario exportado. Hoy no hay pantalla de créditos y
`godot/assets/CREDITS.md` no recoge Montserrat, DSEG7 ni Godot. Además, para el playtest hay que saber qué build
se está jugando: la versión tiene que verse.

## Fuente única de los créditos
- **`godot/data/credits/credits.tres`** (recurso `CreditsData` con un `Array[CreditEntry]`; dueño PUL-172): la
  única fuente. De ella salen la pantalla de créditos y `LICENSES.txt`. `licenses.md` sigue siendo el registro
  de entrada de assets (D16); `credits.tres` es lo que se muestra y se distribuye, y un test cruza ambos (AC1).
- `CreditEntry` (*propuesta*; nombres finales en ADR-007):

| Campo | Tipo | Ejemplo |
|---|---|---|
| `section` | enum `TEAM`, `TOOLS`, `ATTRIBUTION`, `CC0` | `ATTRIBUTION` |
| `work` | `String` | `Octopus` |
| `author` | `String` | `Lorc` |
| `source_name` | `String` | `game-icons.net` |
| `source_url` | `String` (https) | `https://game-icons.net/1x1/lorc/octopus.html` |
| `license` | `String`, identificador SPDX: `CC-BY-3.0`, `MIT`, `OFL-1.1`, `CC0-1.0` | `CC-BY-3.0` |
| `license_url` | `String` (https) | `https://creativecommons.org/licenses/by/3.0/` |
| `license_file` | `String`, ruta dentro de `licenses/` del paquete o vacío | `licenses/OFL-Montserrat.txt` |
| `files` | `PackedStringArray` (rutas `res://`) | `["res://assets/textures/icons/octopus.svg"]` |
| `changes` | `String` (traducible) | `Se elimina el fondo negro` |
| `match_keys` | `PackedStringArray`: textos que identifican sus filas en `licenses.md` | `["game-icons.net/1x1/lorc/octopus"]` |

## Entradas exigidas (cruce con `licenses.md`, 2026-10-14)
Filas de `licenses.md` (secciones «Confirmados» y «Creados en el proyecto») que **exigen atribución**: la columna
«Licencia» contiene `CC BY`, `OFL` o `MIT`, o «Atribución requerida» empieza por «Sí» o «Incluir». Hoy son
**17 filas**: 9 con CC BY (8 iconos + `box.blend`), 6 con OFL (4 fuentes + 2 modelos con letras de Montserrat;
`seasoning_station` v3 y `order_stand` v3 llevan también iconos) y 2 con MIT. Se agrupan en **11 entradas
de atribución**, una por obra, más la de Godot:

| # | Entrada (`work` · `author`) | Licencia | Filas de `licenses.md` que cubre |
|---|---|---|---|
| E1 | Octopus · Lorc (game-icons.net) | CC BY 3.0 | `octopus.svg`; atlas de `box.blend`, `seasoning_station` v3, `order_stand` v3 |
| E2 | Salt shaker · Lorc (game-icons.net) | CC BY 3.0 | `salt.svg`; atlas |
| E3 | Small fire · Lorc (game-icons.net) | CC BY 3.0 | `small-fire.svg` |
| E4 | Crosshair · Delapouite (game-icons.net) | CC BY 3.0 | `selection.svg` |
| E5 | Olive · Delapouite (game-icons.net) | CC BY 3.0 | `oil.svg`; atlas |
| E6 | Potato · Delapouite (game-icons.net) | CC BY 3.0 | `potato.svg`; atlas |
| E7 | Round star · Delapouite (game-icons.net) | CC BY 3.0 | `star_full.svg` y `star_empty.svg` (`changes`: solo el contorno) |
| E8 | Line Awesome «pepper-hot-solid» · Icons8 | MIT | Las 2 filas de `pepper-hot-solid.svg`; atlas |
| E9 | Montserrat · Julieta Ulanovsky y colaboradores | OFL 1.1 | `.otf` y trazados de `art/brand`; letras de `seasoning_station` v3 y `order_stand` v3 |
| E10 | DSEG7 Classic · keshikan | OFL 1.1 | `DSEG7Classic-Bold.ttf` |
| E11 | Liberation Sans · Red Hat, Inc. (y Google para los datos digitalizados, según su `OFL.txt`) | OFL 1.1 | `LiberationSans.ttf` |
| E12 | Godot Engine · Juan Linietsky, Ariel Manzur y colaboradores | MIT (+ componentes) | No está en `licenses.md` (es el motor): sección `TOOLS` |

Reglas del cruce (las aplica el test de AC1):
- Una fila queda cubierta si alguna `match_keys` de una entrada aparece en su texto. Las filas que solo dicen
  «iconos del atlas» quedan cubiertas cuando existen todas las entradas de game-icons.net y Line Awesome que el
  atlas usa (hoy E1, E2, E5, E6, E8; si el atlas cambia, se actualiza esta lista).
- Una entrada `ATTRIBUTION` sin ninguna fila de `licenses.md` que la cite es un error (crédito huérfano).
- Si `licenses.md` gana una fila con atribución, el test falla hasta que `credits.tres` tenga su entrada.

**Cortesía, sin obligación (CC0, sección `CC0`):** «Celtic Loop» (stereoscopic), ambiente de multitud
(StarNinjas), «boiling water loops» (TinyWorlds), «various scissors» (sinny), «scrapes» (AntumDeluge) y los packs
de Kenney (RPG Audio, Music Jingles, Interface Sounds, UI Audio). Hoy 8 filas CC0 en `licenses.md`. Que se citen o
no es una **propuesta** (pregunta C3); el cruce de AC1 no las exige.

## Formato de `LICENSES.txt` (lo consume PUL-170)
- Fichero de texto **UTF-8 sin BOM, fin de línea LF**, en `godot/data/credits/LICENSES.txt`, generado a partir de
  `credits.tres` + `Engine.get_license_text()` + `Engine.get_copyright_info()` y versionado. El test de AC3 lo
  regenera y exige que sea idéntico byte a byte, así no se desincroniza.
- `tools/export.sh` (PUL-170) lo copia a la **raíz de cada `.zip`** junto a la carpeta `licenses/` con los textos
  completos: `OFL-Montserrat.txt`, `OFL-DSEG.txt`, `OFL-LiberationSans.txt` (copias de los `OFL.txt` de
  `godot/assets/fonts/**`), `MIT-LineAwesome.md` (de `assets/textures/icons/LICENSE-line-awesome.md`) y
  `MIT-Godot.txt` (de `Engine.get_license_text()`). CC BY 3.0 se cumple con el enlace a la licencia.
- Estructura exacta (los títulos de sección son fijos; las entradas, en el orden de `credits.tres`):

```text
PulpaSA v<config/version> — Créditos y licencias
================================================

== Equipo ==
<author> — <work>

== Herramientas ==
Godot Engine <Engine.get_version_info().string> — MIT — https://godotengine.org/license
  Licencia: licenses/MIT-Godot.txt

== Atribuciones ==
[<license>] «<work>» por <author> — <source_name>
  Origen: <source_url>
  Ficheros: <files, separados por ", ", sin "res://">
  Cambios: <changes | "ninguno">
  Licencia: <license_url>[ · texto completo en <license_file>]

== Recursos CC0 (cortesía) ==
«<work>» por <author> — <source_url>

== Componentes de terceros de Godot Engine ==
<una línea por componente de Engine.get_copyright_info(): nombre — copyright — licencia>
```
- Una línea en blanco entre entradas; ninguna línea de más de 120 caracteres salvo URLs (que no se parten).

## Pantalla de créditos
- **Apertura:** botón «Créditos» del menú principal de escritorio, entre «Opciones» y «Salir»
  (`opciones-de-volumen.md`). En táctil depende de la pregunta O3 de esa feature. No se abre desde la pausa.
- **Contenido:** las secciones de `LICENSES.txt` salvo la de componentes de Godot, que se resume en una línea
  («Godot Engine usa componentes de terceros: ver LICENSES.txt») para no llenar la pantalla. Los enlaces se
  muestran como texto, no se abren (sin `OS.shell_open` en la alpha). Cabecera con el logo y la versión.
- **Navegación:** lista en un `ScrollContainer`; el botón «Volver» queda fijo debajo, fuera del desplazamiento, con
  el foco al abrir. `ui_up`/`ui_down` (cruceta o stick) desplazan `credits_scroll_step_px` por pulsación; el stick
  analógico desplaza a `credits_scroll_speed_px_s` según su inclinación; en táctil, arrastrar. Sin desplazamiento
  automático. `ui_cancel` o «Volver» devuelven al menú con el foco en «Créditos».
- **Maquetación:** tarjeta de `credits_card_width`; texto ≥ 36 px a 1080 de alto en táctil y ≥ 24 px a 720 en
  escritorio (`controles-tactiles.md`); las líneas largas (URLs) se parten en varias líneas: 0 texto recortado y
  0 desplazamiento horizontal.

## Versión visible
- **Texto:** clave traducible `version.label` = `"v%s"` con `ProjectSettings.get_setting("application/config/version")`
  (hoy `0.1.0`; la de la alpha la decide G0, P4, y la escribe PUL-170). Nunca un literal en código ni en escena.
- **Dónde (2 pantallas):** **menú principal** y **resultados** (`game_over.tscn`), esquina inferior derecha dentro de
  la safe area con `version_margin_px` de margen, a `version_font_px`, sin solapar ningún botón. También en la
  cabecera de créditos y de `LICENSES.txt` (no cuentan para las 2).
- Igual en todos los modos y perfiles; contraste del texto con su fondo ≥ 4,5:1.

## Criterios de aceptación
Tests de `owns` de PUL-172 (`test_credits.gd`); el paquete lo comprueba PUL-170 (ensayo) y PUL-176 (builds finales).

- **AC1 (cobertura)** Given `docs/assets/licenses.md` y `credits.tres`, When el test lee las filas de «Confirmados» y
  «Creados en el proyecto» que exigen atribución (hoy 17) y las cruza por `match_keys`, Then 0 filas sin entrada y
  0 entradas `ATTRIBUTION` sin fila (hoy 11 entradas, E1–E11), más la de Godot (E12) en `TOOLS`. *Test:* `test_credits.gd`.
- **AC2 (campos)** Given cada entrada `ATTRIBUTION` y `TOOLS`, When se valida, Then `work`, `author`, `source_url`,
  `license` y `license_url` no están vacíos, las 2 URL empiezan por `https://`, `license` es uno de los 4 identificadores
  SPDX permitidos y cada `files` existe en `res://` (0 rutas rotas); las entradas MIT y OFL tienen `license_file`.
  *Test:* `test_credits.gd`.
- **AC3 (`LICENSES.txt`)** Given `credits.tres`, When el test genera el texto, Then es idéntico byte a byte a
  `godot/data/credits/LICENSES.txt`, tiene las 5 secciones en el orden del formato, contiene la primera línea de
  `Engine.get_license_text()` y ≥ 1 componente de `Engine.get_copyright_info()`, y su cabecera lleva `v<config/version>`.
  *Test:* `test_credits.gd`.
- **AC4 (paquete)** Given un `.zip` de `tools/export.sh` (Linux y Windows), When se lista con `unzip -l`, Then en la raíz
  están `LICENSES.txt` y `licenses/` con 5 ficheros (3 OFL, Line Awesome, Godot), 2 de 2 plataformas. *Prueba:* log en
  `docs/evidence/PUL-170/` (ensayo) y `docs/evidence/PUL-176/` (finales).
- **AC5 (pantalla y navegación)** Given el menú principal de escritorio, When se activa «Créditos», Then la pantalla se
  muestra en ≤ 1 frame con el foco en «Volver»; When se pulsa `ui_down` ⌈(alto del contenido − alto visible) /
  `credits_scroll_step_px`⌉ veces, Then la última entrada queda visible; Given solo eventos de mando, Then se llega al
  final y se vuelve sin teclado; When se pulsa `ui_cancel`, Then se vuelve al menú con el foco en «Créditos».
  *Test:* `test_credits.gd`.
- **AC6 (táctil y legibilidad)** Given el perfil táctil a 2340×1080, When se abre la pantalla, Then el texto mide ≥ 36 px,
  «Volver» ≥ 120 px de alto, 0 etiquetas recortadas o con desbordamiento horizontal y un arrastre vertical de 300 px
  desplaza la lista 300 ± 2 px. *Test:* `test_credits.gd` + captura `credits_touch_2340x1080.png` en `docs/evidence/PUL-172/`.
- **AC7 (versión en 2 pantallas)** Given `application/config/version`, When se abren el menú principal y los resultados,
  Then las 2 muestran `v` + esa cadena exacta (2 de 2); Given el ajuste cambiado en el test a `9.9.9`, Then ambas muestran
  `v9.9.9` sin cambiar código; y `grep` de la versión actual en `godot/ui/` da 0 literales. *Test:* `test_credits.gd`
  + capturas 1920×1080 y 2340×1080 de las 2 pantallas en `docs/evidence/PUL-172/`.
- **AC8 (posición de la versión)** Given el menú principal y los resultados a 1920×1080 y 2340×1080 (safe area 132 / 0 /
  132 / 63), Then la etiqueta está a `version_margin_px` ± 2 px de los bordes derecho e inferior de la safe area, mide
  ≥ 36 px a 1080, solapa 0 botones y su contraste con el fondo es ≥ 4,5:1. *Test:* `test_credits.gd` + las capturas de AC7.

## Datos (`.tres`)
Contenido: `godot/data/credits/credits.tres` (`CreditsData`, entradas E1–E12 y las de equipo y CC0 que se aprueben).

Maquetación (`UiProfileData`, `data/config/ui_profile_{mobile,desktop}.tres`; campos nuevos *propuestos*):

| Campo | Táctil | Escritorio | Uso |
|---|---|---|---|
| `credits_card_width` | 1440 | 1280 | Ancho de la tarjeta de créditos a 1080 de alto |
| `credits_scroll_step_px` | 120 | 120 | Desplazamiento por pulsación (AC5) |
| `credits_scroll_speed_px_s` | 900 | 900 | Velocidad con el stick a fondo (AC5) |
| `version_font_px` | 36 | 36 | Tamaño del texto de versión a 1080 de alto (AC8) |
| `version_margin_px` | 24 | 24 | Margen a la safe area (AC8) |
| `menu_button_min_px` (ya existe) | 120 | (escala `UiScale`) | Alto de «Volver» (AC6) |

Texto: `version.label` = `"v%s"` en `data/i18n/credits.*` (PUL-168/172). La versión en sí vive en
`project.godot` (`application/config/version`), no en `.tres`: es metadato del build, la fija PUL-170.
Los límites de los AC (≤ 1 frame, ± 2 px, contraste 4,5:1) son criterios de prueba, no datos.

## Verificación
GUT: AC1–AC3, AC5–AC8 (`test_credits.gd`, PUL-172). Log de `unzip -l`: AC4 (PUL-170 en ensayo, PUL-176 en finales).
Capturas en `docs/evidence/PUL-172/`: AC6–AC8.

## Preguntas abiertas
- **C1 Equipo.** ¿Qué nombres o alias y qué roles salen en «Equipo»? ¿Se menciona que el desarrollo lo hacen
  agentes de IA coordinados (Claude, Orca)? Sin respuesta, la sección dice «Equipo Pulpasa».
- **C2 Licencia del juego.** ¿«© 2026 Equipo Pulpasa. Todos los derechos reservados» o una licencia abierta? Va en
  la cabecera de `LICENSES.txt`; no bloquea la pantalla.
- **C3 CC0.** ¿Se citan por cortesía los 8 recursos CC0 (música, ambiente, efectos)? Propuesta: sí, en su sección.
- **C4 Versión en desarrollo.** ¿Las ejecuciones desde el editor muestran `v<versión>-dev` (o el commit corto) para
  no confundirlas con un build? Si se aprueba, AC7 se aplica solo a builds exportados.
- **C5 Herramientas de cortesía.** ¿Se cita Blender (el arte se hizo con él; su GPL no alcanza a los modelos)? GUT y
  gdtoolkit no necesitan entrada si no se distribuyen: PUL-170 debe excluir `addons/gut` además de los tests.
- **C6 `CREDITS.md`.** `godot/assets/CREDITS.md` queda desfasado (sin Montserrat, DSEG7, CC0 de música y ambiente,
  Godot). Propuesta: que PUL-172 lo sustituya por `LICENSES.txt` o lo genere igual; dueño a decidir por el producer.
- **P4 (plan de M4)** Número de versión de la alpha: G0.
