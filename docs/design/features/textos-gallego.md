# Textos en gallego (Should)

**Slug:** textos-gallego

## Descripción
La alpha se puede jugar entera en castellano y en gallego, y el idioma se cambia en la pantalla de opciones
sin reiniciar. Vocabulario: `docs/design/glosario-gl.md`. Inventario de las cadenas visibles hoy, con
fichero de origen, longitud y si caben: `docs/evidence/PUL-161/README.md` (67 filas en 8 pantallas).

Puesta al día (PUL-161) con lo que entró después de escribir la primera versión:
- **D25**: 4 recetas por contenido (*Á feira*, *Picante*, *Con cachelos*, *Bravo cachelos*, ≤ 14 caracteres)
  y 2 aliños completos; desaparecen los tamaños de caja y los condimentos sueltos.
- **D26**: 8 verbos y 6 motivos con rótulo (tutorial, accesibilidad y tooltip de PC; el prompt del mundo y el
  botón táctil son **solo iconos**), menús y tutorial táctiles con texto ≥ 36 px a 1080 de alto. El HUD ya no
  muestra «Cajas / minuto».
- **D27**: no añade textos (solo coloca botones táctiles).

Fuera de alcance: el formato de los ficheros de traducción, su ruta, el registro en `project.godot` y la API
de cambio de idioma los fija **PUL-163** (ADR-007). Esta feature dice *qué* se traduce y *cómo se comprueba*.

### Estado de partida (2026-10-14)
- `project.godot` no tiene `[internationalization]`: no hay traducciones cargadas; todo sale en castellano.
- Conviven **dos convenciones**:
  - **Clave + texto de respaldo** (`tr(KEY)`; si no hay traducción, el castellano del código): HUD
    (`HUD_*`), ticket (`TICKET_*`), menú principal (`MENU_*`, diccionario en `main_menu.gd`), pausa
    (`PAUSE_DEVICE_DISCONNECTED`) y los `translation_key` de `data/recipes/*.tres` (`RECIPE_*`) y
    `data/seasonings/*.tres` (`SEASONING_*`).
  - **Texto castellano como clave** (`tr("Pausa")`, gettext): `menu_panel.gd`, `pause_menu.gd`,
    `game_over.gd` y los `performance_texts` de `round_config.tres`.
- Verbos, motivos y tutorial no tienen texto en el código todavía (iconos en `action_icons.tres`; tutorial
  sin implementar, su diseño lo cierra PUL-162).

## Convención de claves (propuesta)
1. Clave en `MAYÚSCULAS_CON_GUIONES_BAJOS`, con prefijo de pantalla: `MENU_`, `PAUSE_`, `RESULTS_`, `HUD_`,
   `TICKET_`, `TOUCH_`, `VERB_`, `REASON_`, `TUTORIAL_`, `OPTIONS_`, `CREDITS_`; y de dato: `RECIPE_`,
   `SEASONING_`, `PERFORMANCE_`.
2. Las claves que ya existen **no cambian de nombre** (`HUD_SHIFT`, `MENU_PLAY`, `RECIPE_A_FEIRA`…).
3. Los `tr("texto castellano")` pasan a clave (p. ej. `tr("Pausa")` → `PAUSE_TITLE`, `tr("Reintentar")` →
   `RESULTS_RETRY`, `performance_texts[3]` → `PERFORMANCE_3`). Nombres propuestos: columna «Clave
   propuesta» del inventario. Cómo un `.tres` guarda la clave (`translation_key`, como ya hacen recetas y
   aliños, o un array paralelo de claves) lo decide PUL-163.
4. El **castellano es el idioma fuente**: si a una clave le falta traducción se ve el castellano (el respaldo
   actual de `_text()`), nunca la clave, y la clave sale en el informe de traducción.
5. Los marcadores (`%d`, `%.1f`) se conservan en el mismo orden y número en cada idioma.
6. No se traducen: la marca **PULPASA** (D21), el lema **«Franquicia galega de polbo»** (D22) y los formatos
   sin palabras (`#%d`, `%d/%d`, `%02d:%02d`, `%d €`).
7. Los nombres de idioma del selector van en su propia lengua: «Castellano», «Galego».

## Idiomas de la alpha (pregunta P1, abierta)
G0 no ha respondido P1 (plan de M4, `docs/evidence/PUL-141/README.md`). Hasta entonces:
- **Propuesta:** castellano y gallego, sin inglés (el inglés duplica la revisión y no aporta a una alpha
  cerrada para el responsable y su entorno).
- **Idioma por defecto:** hoy AC3 dice castellano. Alternativas: (a) castellano siempre; (b) el del sistema
  (`gl*` → gallego, cualquier otro → castellano); (c) gallego siempre (identidad gallega, pilar del juego).
  **Propuesta: (a)**, que es lo que hay y no depende de cómo informe cada sistema su idioma. AC3 se escribe
  con el valor por defecto como dato para que la respuesta de G0 no cambie el criterio.
- **Dónde se elige:** fila «Idioma» de la pantalla de opciones (feature de PUL-160, implementación PUL-171),
  accesible desde el menú principal y la pausa, en escritorio y táctil. El valor se guarda en
  `user://settings.cfg` (formato de PUL-163). No hay selector de idioma en el primer arranque.

## Criterios de aceptación
Las comprobaciones son de PUL-168 (claves), PUL-173 (traducción y cambio en caliente) y PUL-171 (fila de
opciones). Los nombres de test son propuestas; PUL-163 puede fijar otros.

- **AC1 (cobertura)** Given los ficheros de traducción de castellano y gallego, When `test_translations.gd`
  recorre las claves del inventario (las 67 filas menos las 6 que no se traducen: marca, lema y 4 formatos)
  más las de opciones, créditos y tutorial que añadan PUL-160/162, Then hay 0 claves sin traducción en
  cualquiera de los 2 idiomas y 0 llamadas `tr()` con texto castellano literal en `godot/ui/` y
  `godot/entities/` (búsqueda en el test). *Test:* `test_translations.gd` + informe de traducción.
- **AC2 (cambio en caliente)** Given el menú principal, la pausa o una partida en curso, When se cambia el
  idioma en opciones, Then en ≤ 0,5 s (≤ 30 frames a 60 fps) todo `Label` y `Button` visible de menú,
  pausa, HUD y los tickets vivos muestra el texto del idioma nuevo, sin recargar la escena (el nodo raíz es
  la misma instancia) y sin reiniciar el turno (el tiempo restante no salta más de 0,5 s). *Test:*
  `test_locale_switch.gd`.
- **AC3 (idioma por defecto)** Given que no existe `user://settings.cfg`, When arranca el juego, Then el
  idioma es el valor por defecto de datos (hoy castellano, pendiente de P1); Given `settings.cfg` con
  gallego guardado, When arranca, Then el menú principal sale en gallego desde el primer frame visible.
  *Test:* `test_translations.gd` (2 casos).
- **AC4 (caben)** Given cada idioma (2) y cada resolución (1280×720 escritorio y 2340×1080 perfil MOBILE,
  texto ≥ 36 px), When `test_ui_scale.gd` recorre los `Label`/`Button` de menú, pausa, resultados, HUD,
  4 tickets vivos (uno «Bravo cachelos») y el panel del tutorial, Then 0 textos con «…» ni con ancho de
  texto mayor que el de su control, y ninguno pasa de 3 líneas. *Test:* `test_ui_scale.gd` + 4 capturas
  (2 idiomas × 2 resoluciones) del menú y la pausa en `docs/evidence/PUL-173/`.
- **AC5 (D26: verbos y motivos)** Given los 8 verbos (COGER, SOLTAR, COCER, CORTAR, ALIÑAR DULCE, ALIÑAR
  PICANTE, CACHELOS, TIRAR) y los 7 rótulos de los 6 motivos (caja a medias, ocupado, vacío, lleno, ya
  aplicado / ya lleva, sin cocer), Then existen 15 claves `VERB_*`/`REASON_*` con texto en castellano y
  gallego (`glosario-gl.md`) que caben sin recortarse a ≥ 36 px en 2340×1080 donde se muestren (tutorial,
  tooltip de PC); y `action_prompt.tscn` y `touch_controls.tscn` tienen 0 nodos de texto (los iconos no
  llevan texto). *Test:* `test_translations.gd` + `test_ui_scale.gd`.
- **AC6 (textos de datos)** Given el idioma gallego, When sale un ticket de cada una de las 4 recetas y el
  resultado de cada uno de los 4 tramos de `performance_texts`, Then los 8 textos salen en gallego y los
  `.tres` conservan el castellano como fuente. *Test:* `test_translations.gd` (8 casos).
- **AC7 (marca)** Given cualquiera de los 2 idiomas, Then «PULPASA» y «FRANQUICIA GALEGA DE POLBO» se ven
  idénticos. *Test:* `test_translations.gd`.

## Datos
- Ficheros de traducción por idioma (formato y ruta bajo `godot/data/`: PUL-163).
- `translation_key` (o equivalente de PUL-163) en los `.tres` con texto visible: recetas, aliños y
  `performance_texts` de `round_config.tres`.
- Lista de idiomas disponibles y valor por defecto en un `.tres` de configuración (propuesta; nombre y
  ubicación de PUL-163), no en código.

## Preguntas abiertas
- **P1** (G0): idiomas de la alpha (¿castellano y gallego solo?, ¿inglés?) e idioma por defecto
  (castellano, sistema o gallego). Propuesta arriba.
- **P9** (G3): quién revisa el gallego y antes de qué gate. Todo el gallego de `glosario-gl.md` y del
  inventario es propuesta hasta esa revisión.
- **G-1..G-4** de `glosario-gl.md`: cotejo con `main.tex`, *polbeiro*/*pulpeiro*, errata de
  `performance_texts[3]` y letra de jugador (P/J/X).
- **T-1** Formato de números: hoy el HUD pinta `300.0s`. ¿Coma decimal y espacio (`300,0 s`) en los dos
  idiomas? Propuesta: sí (norma de castellano y gallego); lo aplicaría PUL-173.
- **T-2** Los textos del tutorial del inventario son propuesta de redacción sobre `tutorial-breve.md`; si
  PUL-162 cambia los pasos, manda PUL-162 y se rehacen las filas.
