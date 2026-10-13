# PUL-161 · Evidencia: textos en gallego y glosario

Entregables: `docs/design/glosario-gl.md` y `docs/design/features/textos-gallego.md` (reescrita).
Todo el gallego es **propuesta** (revisión nativa en G3, pregunta P9).

## AC1 · Inventario de cadenas visibles

**Método.** Búsqueda de `text =` en los `.tscn` de `godot/ui/`, `godot/entities/` y `godot/scenes/` (sin
sandboxes), de `tr(`, `_text(` y `.text =` en los `.gd`, y de `display_name`/`performance_texts` en
`godot/data/**/*.tres`; luego se comprobó qué llega a pantalla (p. ej. los `display_name` de
`data/orders/`, `data/boxes/` y `data/ingredients/` **no** se muestran: solo los usa la lógica; el nombre del
aliño solo se ve si falta su icono, `ticket_entry.gd:51`). Verbos, motivos y tutorial no tienen texto en el
código: sus filas salen de `lenguaje-acciones.md` y de `tutorial-breve.md` (redacción propuesta).

**Longitud.** Caracteres del texto; con marcadores se cuenta un valor de ejemplo (`J2`, `999 €`, `300.0s`).

**¿Cabe?** Estimación, no medida: ancho ≈ caracteres × 0,60 × tamaño de fuente (0,70 si va en
mayúsculas; Montserrat). Calibrado con el dato medido de `controles-tactiles.md` («Bravo cachelos» a 36 px
cabe en 298 px ⇒ factor ≤ 0,59, así que 0,60 es conservador). Unidades de lienzo (`u`): el proyecto es
1280×720 con `canvas_items`/`expand`, así que a 1280×720 1 u = 1 px y a 2340×1080 1 u = 1,5 px (lienzo
1560×720 u); en el perfil MOBILE la fuente efectiva es max(fuente, 24 u) = 36 px (`ui_profile_mobile.tres`).
Ancho útil por contenedor: menú principal 480 u (columna) / 440 u (botones), tarjeta de menú 456 u
(`menu_panel.tscn` 520 − márgenes), bloque HUD 152 u (escritorio) / 131 u (MOBILE, `hud_block_width` 240 px),
ticket 180 u (escritorio, 212 − márgenes) / 224 u (MOBILE, 380 − 44 px), panel del tutorial 456 u (supuesto,
lo fija PUL-162/163). Se evalúa la versión más larga (castellano o gallego). «N líneas» = el control tiene
`autowrap` y el texto se parte; «riesgo» = el control no parte y el texto estimado supera el ancho útil.
Lo verifica con medida real `test_ui_scale.gd` (AC4 de la feature). Script reproducible:
`docs/evidence/PUL-161/inventario.py` (`python3 inventario.py`).

| # | Pantalla | Origen | Clave hoy | Clave propuesta | Castellano | Lon. es | Gallego (propuesta) | Lon. gl | 1280×720 (gl) | 2340×1080 (gl) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Menú | `ui/menus/main_menu.tscn:46` | `— (marca D21)` | `— (no se traduce)` | PULPASA | 7 | PULPASA | 7 | 167/440 u · cabe | 167/440 u · cabe |
| 2 | Menú | `ui/menus/main_menu.gd:8` | `MENU_TAGLINE` | `MENU_TAGLINE` | Pulpo á feira · Romerías gallegas | 33 | Polbo á feira · Romarías galegas | 32 | 396/480 u · cabe | 475/480 u · cabe |
| 3 | Menú | `ui/menus/main_menu.gd:5` | `MENU_PLAY` | `MENU_PLAY` | Individual | 10 | Individual | 10 | 132/440 u · cabe | 144/440 u · cabe |
| 4 | Menú | `ui/menus/main_menu.gd:6` | `MENU_LOCAL_2P` | `MENU_LOCAL_2P` | Local 2P | 8 | Local 2X | 8 | 106/440 u · cabe | oculta en MOBILE |
| 5 | Menú | `ui/menus/main_menu.gd:7` | `MENU_EXIT` | `MENU_EXIT` | Salir | 5 | Saír | 4 | 66/440 u · cabe | oculta en MOBILE |
| 6 | Menú | `ui/menus/main_menu.gd:9` | `MENU_MODE` | `MENU_MODE` | Individual: un personaje · Local 2P: dos jugadores | 50 | Individual: un personaxe · Local 2X: dous xogadores | 51 | 490/480 u · **riesgo** | oculta en MOBILE |
| 7 | Menú | `ui/menus/main_menu.gd:10` | `MENU_LEVEL_UNAVAILABLE` | `MENU_LEVEL_UNAVAILABLE` | La cocina todavía no está disponible. Vuelve pronto. | 52 | A cociña aínda non está dispoñible. Volve pronto. | 49 | 562/460 u · 2 líneas | 749/460 u · 2 líneas |
| 8 | Menú | `ui/menus/main_menu.gd:11` | `MENU_LOAD_FAILED` | `MENU_LOAD_FAILED` | No se pudo abrir la cocina. Inténtalo de nuevo. | 47 | Non se puido abrir a cociña. Téntao de novo. | 44 | 508/460 u · 2 líneas | 677/460 u · 2 líneas |
| 9 | Menú | `ui/menus/menu_panel.tscn:59` | `— (lema D22)` | `— (no se traduce)` | FRANQUICIA GALEGA DE POLBO | 26 | FRANQUICIA GALEGA DE POLBO | 26 | 273/456 u · cabe | 437/456 u · cabe |
| 10 | Pausa | `ui/menus/pause_menu.gd:16` | `tr("Pausa")` | `PAUSE_TITLE` | Pausa | 5 | Pausa | 5 | 102/456 u · cabe | 102/456 u · cabe |
| 11 | Pausa | `ui/menus/pause_menu.gd:17` | `tr(texto)` | `PAUSE_DESCRIPTION` | La romería puede esperar un momento. | 36 | A romaría pode agardar un momento. | 34 | 432/456 u · cabe | 518/456 u · 2 líneas |
| 12 | Pausa | `ui/menus/pause_menu.gd:16` | `tr("Reanudar")` | `PAUSE_RESUME` | Reanudar | 8 | Continuar | 9 | 119/456 u · cabe | 130/456 u · cabe |
| 13 | Pausa | `ui/menus/pause_menu.gd:24` | `tr("Reiniciar")` | `PAUSE_RESTART` | Reiniciar | 9 | Reiniciar | 9 | 119/456 u · cabe | 130/456 u · cabe |
| 14 | Pausa | `ui/menus/menu_panel.gd:22` | `tr("Salir") (PC)` | `MENU_EXIT` | Salir | 5 | Saír | 4 | 66/456 u · cabe | oculta en MOBILE |
| 15 | Pausa | `ui/menus/pause_menu.gd:95` | `PAUSE_DEVICE_DISCONNECTED` | `PAUSE_DEVICE_DISCONNECTED` | Mando de J%d desconectado | 24 | Mando do X%d desconectado | 24 | 317/456 u · cabe | oculta en MOBILE |
| 16 | Resultados | `ui/menus/game_over.gd:17` | `tr("Turno terminado")` | `RESULTS_TITLE` | Turno terminado | 15 | Quenda rematada | 15 | 306/456 u · cabe | 306/456 u · cabe |
| 17 | Resultados | `ui/menus/game_over.gd:17` | `tr("Reintentar")` | `RESULTS_RETRY` | Reintentar | 10 | Tentar de novo | 14 | 185/456 u · cabe | 202/456 u · cabe |
| 18 | Resultados | `ui/menus/game_over.gd:48` | `tr("Recaudación: %d €")` | `RESULTS_REVENUE` | Recaudación: %d € | 18 | Recadación: %d € | 17 | 216/456 u · cabe | 259/456 u · cabe |
| 19 | Resultados | `data/config/round_config.tres:41 [0]` | `performance_texts[0] (tr(literal))` | `PERFORMANCE_0` | Pulpeiro ineficiente | 20 | Polbeiro ineficiente | 20 | 240/456 u · cabe | 288/456 u · cabe |
| 20 | Resultados | `data/config/round_config.tres:41 [1]` | `performance_texts[1] (tr(literal))` | `PERFORMANCE_1` | Pulpeiro aceptable | 18 | Polbeiro aceptable | 18 | 216/456 u · cabe | 259/456 u · cabe |
| 21 | Resultados | `data/config/round_config.tres:41 [2]` | `performance_texts[2] (tr(literal))` | `PERFORMANCE_2` | Pulpeiro eficiente | 18 | Polbeiro eficiente | 18 | 216/456 u · cabe | 259/456 u · cabe |
| 22 | Resultados | `data/config/round_config.tres:41 [3]` | `performance_texts[3] (tr(literal))` | `PERFORMANCE_3` | !Pulpeiro lexendario! | 21 | ¡Polbeiro lendario! | 19 | 252/456 u · cabe | 302/456 u · cabe |
| 23 | HUD | `ui/hud/hud.gd:37` | `HUD_SHIFT` | `HUD_SHIFT` | Turno | 5 | Quenda | 6 | 58/152 u · cabe | oculta en MOBILE |
| 24 | HUD | `ui/hud/hud.gd:38` | `HUD_TIME_LEFT` | `HUD_TIME_LEFT` | Tiempo restante | 15 | Tempo restante | 14 | 117/152 u · cabe | oculta en MOBILE |
| 25 | HUD | `ui/hud/hud.gd:39` | `HUD_REVENUE` | `HUD_REVENUE` | Recaudación | 11 | Recadación | 10 | 86/152 u · cabe | oculta en MOBILE |
| 26 | HUD | `ui/hud/hud.gd:81` | `HUD_ACTIVE_CHARACTER` | `HUD_ACTIVE_CHARACTER` | Controlas: P%d | 13 | Controlas: P%d | 13 | 117/152 u · cabe | oculta en MOBILE |
| 27 | HUD | `ui/hud/hud.gd:88` | `HUD_DEVICE_CONNECTED` | `HUD_DEVICE_CONNECTED` | J%d conectado | 12 | X%d conectado | 12 | 108/152 u · cabe | oculta en MOBILE |
| 28 | HUD | `ui/hud/hud.gd:102` | `HUD_SECONDS_FORMAT` | `HUD_SECONDS_FORMAT` | %.1fs | 6 | %.1f s | 7 | 101/152 u · cabe | 101/131 u · cabe |
| 29 | HUD | `ui/hud/hud.gd:103` | `HUD_REVENUE_FORMAT` | `— (no se traduce)` | %d € | 5 | %d € | 5 | 72/152 u · cabe | 72/131 u · cabe |
| 30 | Tickets | `ui/tickets/order_ticket.gd:30` | `TICKET_TITLE` | `TICKET_TITLE` | Comanda | 7 | Comanda | 7 | 67/180 u · cabe | 101/224 u · cabe |
| 31 | Tickets | `ui/tickets/order_ticket.gd:43` | `TICKET_ID_FORMAT` | `— (no se traduce)` | #%d | 3 | #%d | 3 | 36/180 u · cabe | 43/224 u · cabe |
| 32 | Tickets | `data/recipes/a_feira.tres:8` | `RECIPE_A_FEIRA` | `RECIPE_A_FEIRA` | Á feira | 7 | Á feira | 7 | 80/180 u · cabe | 101/224 u · cabe |
| 33 | Tickets | `data/recipes/picante.tres:8` | `RECIPE_PICANTE` | `RECIPE_PICANTE` | Picante | 7 | Picante | 7 | 80/180 u · cabe | 101/224 u · cabe |
| 34 | Tickets | `data/recipes/con_cachelos.tres:8` | `RECIPE_CON_CACHELOS` | `RECIPE_CON_CACHELOS` | Con cachelos | 12 | Con cachelos | 12 | 137/180 u · cabe | 173/224 u · cabe |
| 35 | Tickets | `data/recipes/bravo_cachelos.tres:8` | `RECIPE_BRAVO_CACHELOS` | `RECIPE_BRAVO_CACHELOS` | Bravo cachelos | 14 | Bravo cachelos | 14 | 160/180 u · cabe | 202/224 u · cabe |
| 36 | Tickets | `data/seasonings/sweet_dressing.tres:8 (solo si falta el icono)` | `SEASONING_SWEET_DRESSING` | `SEASONING_SWEET_DRESSING` | Aliño dulce | 11 | Aliño doce | 10 | 119/180 u · cabe | 158/224 u · cabe |
| 37 | Tickets | `data/seasonings/hot_dressing.tres:8 (solo si falta el icono)` | `SEASONING_HOT_DRESSING` | `SEASONING_HOT_DRESSING` | Aliño picante | 13 | Aliño picante | 13 | 140/180 u · cabe | 187/224 u · cabe |
| 38 | Tickets | `data/seasonings/cachelos.tres:8 (solo si falta el icono)` | `SEASONING_CACHELOS` | `SEASONING_CACHELOS` | Cachelos | 8 | Cachelos | 8 | 86/180 u · cabe | 115/224 u · cabe |
| 39 | Táctil | `ui/menus/menu_panel.gd:22` | `tr("Menú") (perfil MOBILE)` | `MENU_BACK` | Menú | 4 | Menú | 4 | 53/456 u · cabe | 58/456 u · cabe |
| 40 | Táctil | `ui/menus/main_menu.gd:5 (único botón en MOBILE)` | `MENU_PLAY` | `MENU_PLAY` | Individual | 10 | Individual | 10 | 132/440 u · cabe | 144/440 u · cabe |
| 41 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_PICK_UP` | `VERB_PICK_UP` | COGER | 5 | COLLER | 6 | 101/456 u · cabe | 101/456 u · cabe |
| 42 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_DROP` | `VERB_DROP` | SOLTAR | 6 | DEIXAR | 6 | 101/456 u · cabe | 101/456 u · cabe |
| 43 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_COOK` | `VERB_COOK` | COCER | 5 | COCER | 5 | 84/456 u · cabe | 84/456 u · cabe |
| 44 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_CUT` | `VERB_CUT` | CORTAR | 6 | CORTAR | 6 | 101/456 u · cabe | 101/456 u · cabe |
| 45 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_SEASON_SWEET` | `VERB_SEASON_SWEET` | ALIÑAR DULCE | 12 | ALIÑAR DOCE | 11 | 202/456 u · cabe | 202/456 u · cabe |
| 46 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_SEASON_HOT` | `VERB_SEASON_HOT` | ALIÑAR PICANTE | 14 | ALIÑAR PICANTE | 14 | 235/456 u · cabe | 235/456 u · cabe |
| 47 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_CACHELOS` | `VERB_CACHELOS` | CACHELOS | 8 | CACHELOS | 8 | 134/456 u · cabe | 134/456 u · cabe |
| 48 | Prompts | `features/lenguaje-acciones.md §Verbos (sin implementar)` | `VERB_TRASH` | `VERB_TRASH` | TIRAR | 5 | BOTAR | 5 | 84/456 u · cabe | 84/456 u · cabe |
| 49 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_BOX_NOT_FULL` | `REASON_BOX_NOT_FULL` | caja a medias | 13 | caixa a medias | 14 | 202/456 u · cabe | 202/456 u · cabe |
| 50 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_BUSY` | `REASON_BUSY` | ocupado | 7 | ocupado | 7 | 101/456 u · cabe | 101/456 u · cabe |
| 51 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_EMPTY` | `REASON_EMPTY` | vacío | 5 | baleiro | 7 | 101/456 u · cabe | 101/456 u · cabe |
| 52 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_FULL` | `REASON_FULL` | lleno | 5 | cheo | 4 | 72/456 u · cabe | 72/456 u · cabe |
| 53 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_ALREADY` | `REASON_ALREADY` | ya aplicado | 11 | xa aplicado | 11 | 158/456 u · cabe | 158/456 u · cabe |
| 54 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_ALREADY_HAS` | `REASON_ALREADY_HAS` | ya lleva | 8 | xa leva | 7 | 115/456 u · cabe | 115/456 u · cabe |
| 55 | Prompts | `features/lenguaje-acciones.md §Motivos (sin implementar)` | `REASON_RAW` | `REASON_RAW` | sin cocer | 9 | sen cocer | 9 | 130/456 u · cabe | 130/456 u · cabe |
| 56 | Prompts | `entities/items/box.gd:191 (Label3D)` | `— (formato)` | `— (no se traduce)` | %d/%d | 3 | %d/%d | 3 | 43/456 u · cabe | 43/456 u · cabe |
| 57 | Prompts | `entities/stations/order_stand.gd:173 (Label3D)` | `— (formato)` | `— (no se traduce)` | #%d | 2 | #%d | 2 | 29/456 u · cabe | 29/456 u · cabe |
| 58 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_PICK_UP` | `TUTORIAL_STEP_PICK_UP` | Coge un pulpo de la nevera. | 27 | Colle un polbo da neveira. | 26 | 389/456 u · cabe | 389/456 u · cabe |
| 59 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_COOK` | `TUTORIAL_STEP_COOK` | Mételo en la olla para cocerlo. | 31 | Méteo na pota para cocelo. | 26 | 446/456 u · cabe | 446/456 u · cabe |
| 60 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_CUT` | `TUTORIAL_STEP_CUT` | Córtalo sobre una caja: 6 pulsaciones (o mantén pulsado). | 57 | Córtao sobre unha caixa: 6 pulsacións (ou mantén premido). | 58 | 835/456 u · 2 líneas | 835/456 u · 2 líneas |
| 61 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_SEASON` | `TUTORIAL_STEP_SEASON` | Aliña la caja llena con el aliño dulce. | 39 | Aliña a caixa chea co aliño doce. | 33 | 562/456 u · 2 líneas | 562/456 u · 2 líneas |
| 62 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_SEASON_REPLACE` | `TUTORIAL_SEASON_REPLACE` | ¿Picante? Pulsa el dulce y lo sustituye. | 40 | Picante? Preme o doce e substitúeo. | 35 | 576/456 u · 2 líneas | 576/456 u · 2 líneas |
| 63 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_TRASH_HINT` | `TUTORIAL_TRASH_HINT` | Lo que salga mal, al cubo. | 26 | O que saia mal, ao lixo. | 24 | 374/456 u · cabe | 374/456 u · cabe |
| 64 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_DELIVER` | `TUTORIAL_STEP_DELIVER` | Entra con la caja correcta en la zona del puesto. | 49 | Entra coa caixa correcta na zona do posto. | 42 | 706/456 u · 2 líneas | 706/456 u · 2 líneas |
| 65 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_COOPERATE` | `TUTORIAL_STEP_COOPERATE` | Cooperad: uno cuece y el otro corta. | 36 | Cooperade: un coce e o outro corta. | 35 | 518/456 u · 2 líneas | 518/456 u · 2 líneas |
| 66 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_STEP_SWITCH` | `TUTORIAL_STEP_SWITCH` | Cambia de personaje con el botón. | 33 | Cambia de personaxe co botón. | 29 | 475/456 u · 2 líneas | 475/456 u · 2 líneas |
| 67 | Tutorial | `features/tutorial-breve.md (sin implementar; PUL-162)` | `TUTORIAL_SKIP` | `TUTORIAL_SKIP` | Saltar | 6 | Omitir | 6 | 86/456 u · cabe | 86/456 u · cabe |

**Filas por pantalla** (≥ 1 en las 8): Menú 9 · Pausa 6 · Resultados 7 · HUD 7 · Tickets 9 · Táctil 2 ·
Prompts 17 · Tutorial 10 = **67 filas**. 6 no se traducen (marca, lema y 4 formatos).

**Hallazgos del inventario**
1. **Riesgo de ancho, 1 fila**: `MENU_MODE` en gallego (≈ 490 u frente a 480 u de columna, sin `autowrap`) en
   1280×720. Margen de error de la estimación; si `test_ui_scale.gd` lo confirma, `autowrap` en `%Mode` o
   texto más corto («Individual: 1 personaxe · Local 2X: 2 xogadores», 47 caracteres). En MOBILE está oculto.
2. En MOBILE el HUD oculta los títulos (`hud.gd:125-131`) y el menú oculta `Local 2P`, `Salir` y `Mode`
   (`main_menu.gd:53-55`): esas filas solo cuentan en escritorio.
3. Dos convenciones de claves conviven (clave + respaldo y `tr()` con castellano literal): la feature
   propone migrar las 13 del segundo tipo a claves (columna «Clave propuesta»).
4. Errata en `round_config.tres`: «!Pulpeiro lexendario!» (signo de apertura y *lexendario* no normativo):
   glosario G-3.
5. Letras de jugador mezcladas: «P» (`Controlas: P%d`, `Local 2P`) y «J» (`J%d conectado`, `Mando de J%d`):
   glosario G-4.
6. El HUD formatea los segundos con punto y sin espacio (`300.0s`): feature T-1.
7. `main.tex` no está en `/home/jeromo/vibedora/dev/pulpasa_docs/` en esta máquina: las fuentes `main.tex`
   del glosario son solo las citas literales de `gdd.md` §8 (glosario G-1).

## AC2 · Conteo del glosario

Cruce con D26 (`lenguaje-acciones.md` §Verbos y §Motivos), `godot/data/recipes/*.tres` (`display_name`) y
`godot/data/config/round_config.tres:41` (`performance_texts`):

| Grupo | Esperados | En `glosario-gl.md` | Con fuente | `main.tex` | Propuesta | Faltan |
|---|---|---|---|---|---|---|
| Verbos (D26) | 8 | 8 | 8 | 1 (CACHELOS) | 7 | 0 |
| Motivos (D26) | 6 | 6 | 6 | 0 | 6 | 0 |
| Recetas (`data/recipes/`) | 4 | 4 | 4 | 1 (Con cachelos) | 3 | 0 |
| `performance_texts` | 4 | 4 | 4 | 0 | 4 | 0 |
| **Total** | **22** | **22** | **22** | **2** | **20** | **0** |

Además: 40 términos de vocabulario general (polbo á feira, cachelos, aliño, pulpeiro, pementón, comanda…),
con fuente `main.tex`, `brand.md` (D22) o propuesta.

## AC3 · AC de `textos-gallego.md` → prueba

| AC | Given/When/Then | Números | Prueba | Ficha que lo cumple |
|---|---|---|---|---|
| AC1 cobertura | Sí | 61 claves del inventario + las de PUL-160/162; 2 idiomas; 0 sin traducir; 0 `tr()` literales | `test_translations.gd` + informe | PUL-168, 173 |
| AC2 cambio en caliente | Sí | ≤ 0,5 s (≤ 30 frames), misma instancia, reloj ±0,5 s | `test_locale_switch.gd` | PUL-173 |
| AC3 idioma por defecto | Sí | 2 casos (sin `settings.cfg` / con gallego) | `test_translations.gd` | PUL-168, 171 |
| AC4 caben | Sí | 2 idiomas × 2 resoluciones, 4 tickets, 0 «…», ≤ 3 líneas, ≥ 36 px | `test_ui_scale.gd` + 4 capturas | PUL-173 |
| AC5 verbos y motivos | Sí | 8 verbos, 7 rótulos de 6 motivos = 15 claves; ≥ 36 px; 0 nodos de texto en 2 escenas | `test_translations.gd` + `test_ui_scale.gd` | PUL-168, 173 |
| AC6 textos de datos | Sí | 4 recetas + 4 tramos = 8 casos | `test_translations.gd` | PUL-168, 173 |
| AC7 marca | Sí | 2 textos idénticos en 2 idiomas | `test_translations.gd` | PUL-173 |

**P1** (idiomas e idioma por defecto) sigue sin respuesta de G0 (`docs/evidence/PUL-141/README.md`: no hay
acta de G0): aparece como pregunta abierta en la feature, con propuesta (castellano + gallego, sin inglés,
castellano por defecto) y AC3 escrito con el valor por defecto como dato. P9 también queda abierta.

## AC4 · Verificación

```text
$ tools/verify.sh --quick
== gdformat --check
235 files would be left unchanged
== gdlint
Success: no problems found
== import
✓ verify OK
exit=0

$ python3 tools/check_owns.py jrmougan/pul-161 main
check_owns: 5 rutas dentro de owns de PUL-161.
exit=0
```

(`exit` de `verify.sh --quick` medido también sin tubería: `EXIT=0`. `check_owns.py` se pasó sobre el commit de la ficha; este apartado se añadió con `--amend` y toca solo `docs/evidence/PUL-161/README.md`.)
