---
id: PUL-120
title: Enmendar los contratos para D26 (verbo de acción, prompt, táctil, cámara móvil)
status: review
milestone: M3e
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/**, docs/backlog/PUL-120-contratos-d26.md]
touches_scenes: []
---

## Target
Contratos de `docs/arch/` afectados por D26 (decidida 2026-10-11 con autorización del responsable; la redacta en
paralelo PUL-119 en `decisions.md`). Contenido de D26: `docs/backlog/PUL-119-d26-lenguaje-acciones-movil.md`,
sección Change. Léela entera.

## Change
Enmendar los ADR, `signals.md` y `scene-tree.md` para que la implementación de D26 tenga contrato:

1. **Verbo de acción (ADR-003 §4, `interaction_contract`).** Método opcional en interactuables
   `get_action_hint(actor: InteractionComponent) -> ActionHint` (o equivalente), con `ActionHint` RefCounted en
   `core/` (verbo `StringName`, estado OK/BLOCKED, motivo `StringName`, progreso opcional). Regla: `interact`
   y `get_action_hint` comparten la misma resolución de rama (helper puro en `core/`), para que no diverjan.
   `can_interact` pasa a ser honesto: true solo si la pulsación tiene efecto o un BLOCKED con motivo útil.
   Decide el conjunto cerrado de verbos y motivos (`core/action_verb.gd` o similar).
2. **Histéresis del detector** (`InteractionScoring`, `player_config.tres`: `hysteresis_margin`).
3. **Señales.** La UI (prompt del botón táctil) solo escucha EventBus: añade al catálogo cerrado la señal del
   hint del objetivo activo por jugador, con primitivos (p. ej. `action_hint_changed(player_index: int, verb:
   StringName, state: int, reason: StringName)`), un único emisor, y una señal de resultado si hace falta
   (`interaction_resolved(player_index, verb, result)`). Decide si el icono sobre el objetivo vive en el mundo
   (componente en `components/`, regla 4: `ui/` sin tipos 3D) y cómo obtiene el hint (local, sin bus).
4. **Entrega solo por zona** (D26.5): `OrderStand` deja de ser objetivo de pulsación; actualizar ADR/árbol.
   Cuenco sin toggle. Cues nuevos y distintos en ADR-006 (`cook_ready`, `burn_warning`, `box_full`,
   `switch`, `rejected` único, `trash` con sonido propio, `already_applied`).
5. **Input táctil (ADR-004).** Solo Individual en táctil; el stick virtual y los botones alimentan las acciones
   existentes `p1_*` por código (`Input.parse_input_event`/`action_press` con fuerza), sin añadir eventos
   táctiles al InputMap; visibles si hay pantalla táctil, ocultos al usar teclado/mando; botón de pausa;
   corte con mantener (`is_action_pressed` + temporizador en núcleo).
6. **Escala y cámara (ADR-005).** `window/stretch` (canvas_items/expand), orientación apaisada, safe area,
   escala de UI por alto y DPI con mínimos en datos; perfil de cámara móvil (zoom ≥ 120 px/m a 1080 de alto,
   seguimiento suave del jugador activo) seleccionable por datos/plataforma sin romper la cámara de PC.
7. **Partición.** Al final de la ficha, propón la partición en fichas de implementación con `owns` disjuntos
   (un `.tscn` y `project.godot` con un solo dueño por oleada), dependencias y orden. El producer la usará.

## Constraints
- Solo `docs/arch/` y esta ficha. Sin código.
- Coherente con ADR-002 (núcleos RefCounted, autoloads finos), reglas de `signals.md` (primitivos, emisor
  único) y la regla 4 de CLAUDE.md.

## Acceptance
- [x] AC1 ADR-003 enmendado (§ D26): `get_action_hint`, `ActionHint`, verbos/motivos cerrados, `can_interact` honesto
- [x] AC2 `signals.md` con las señales nuevas (firma, emisor, oyentes) y `event_bus.gd` descrito
- [x] AC3 ADR-004 (táctil) y ADR-005 (escala, cámara móvil) enmendados; ADR-006 con los cues nuevos
- [x] AC4 `scene-tree.md` con los nodos nuevos (prompt en mundo, controles táctiles, perfil de cámara)
- [x] AC5 Partición en fichas con owns disjuntos

## Plan
1. Leer D26 (PUL-119, sección Change), el estudio (`docs/evidence/PUL-119/README.md`) y los contratos
   vigentes (ADR-002…ADR-006, `signals.md`, `scene-tree.md`, `export.md`).
2. Leer el código que se contrata: `components/{interaction_component,interaction_detector,
   interaction_contract,highlightable}.gd`, `core/{interaction_scoring,player_input}.gd`, todos los
   receptores (`entities/items/{box,ingredient}.gd`, `entities/stations/{cooking_station,slot,
   item_spawner,seasoning_dispenser,cachelos_bowl,trash_bin,order_stand}.gd`), `autoload/event_bus.gd`,
   `ui/widgets/ui_scale.gd`, `entities/camera/camera_rig.tscn`, `project.godot`,
   `data/audio/feedback_map.tres`, `level_01.tscn` y los tests que dependen de ellos.
3. ADR-003 §11 (tipos, contrato `interactable`, detector e histéresis, pulsación y mantener, prompt,
   tabla provisional, entrega por zona y cuenco, estado legible, señales, alternativas) + notas en
   estado, §3, §4, §9.4, §10.2, §10.3 y consecuencias.
4. ADR-004 §6 (táctil), ADR-005 Enmienda D26 (plataforma, stretch, `UiProfile`, `UiScale`, safe
   area, cámara), ADR-006 §4.1 (cues), ADR-002 Enmienda 2 (emisor de interacción, perfil en
   `GameState`).
5. `signals.md` (tipos, dos señales de bus con su declaración en `event_bus.gd`, dos locales,
   secuencias, receptores), `scene-tree.md` (§2, §3, §7.3 y §9 nueva), `export.md` (Android fuera),
   `README.md`.
6. Partición en fichas (abajo) y `tools/verify.sh --quick`.

## Evidence
- Ficheros: `docs/arch/ADR-003-arbol-escenas-composicion.md` (§11 nueva + notas),
  `docs/arch/ADR-004-input-coop-local.md` (§6), `docs/arch/ADR-005-dimension-3d-2d.md` (Enmienda D26),
  `docs/arch/ADR-006-audio-feedback.md` (§4.1), `docs/arch/ADR-002-eventbus-autoloads.md`
  (Enmienda 2), `docs/arch/signals.md`, `docs/arch/scene-tree.md` (§2, §3, §7.3, §9),
  `docs/arch/export.md`, `docs/arch/README.md`. ADR-001 sin cambios.
- `tools/verify.sh --quick`: verde (gdformat, gdlint, import), 2026-10-11.

### Decisiones de contrato tomadas (para el gate humano)
1. **Verbos cerrados** (`core/action_verb.gd`, `ActionVerb`, `StringName`): `pick_up` COGER,
   `put_down` SOLTAR, `cook` COCER, `cut` CORTAR, `season_sweet` ALIÑAR DULCE, `season_hot` ALIÑAR
   PICANTE, `cachelos` CACHELOS, `trash` TIRAR (incluye el quemado); `&""` = ninguno. No hay verbo
   de entregar (el puesto deja de ser objetivo).
2. **Motivos cerrados** (`core/action_reason.gd`, `ActionReason`): `box_not_full`, `busy`, `empty`,
   `full`, `already_applied`; `&""` = ninguno. Añadir uno exige enmienda (constante + icono + test).
3. **`ActionHint`** (`core/action_hint.gd`, `RefCounted`): `verb`, `state` (`NONE 0 / OK 1 /
   BLOCKED 2`), `reason`, `progress` (−1 = sin progreso; no cuenta para «cambió»). Única excepción a
   las invariantes: `OK` con verbo vacío para entidades sin migrar y dobles de test.
4. **Una sola resolución**: cada receptor tiene `_resolve(holder) -> ActionHint`, que delega en
   `ActionRules.for_*` (pura, `core/action_rules.gd`, `enum Held` de 9 valores); `get_action_hint` y
   `interact` la usan. `HeldKind.of(item)` (`entities/items/held_kind.gd`, específica) clasifica la
   mano. `get_action_hint(actor)` pasa a **obligatorio** en `entities/` en la oleada de montaje;
   `can_interact` = `is_target()` (honesto).
5. **Tabla provisional** mano × receptor en ADR-003 §11.6 (72 celdas); **manda la de PUL-119**
   (`features/lenguaje-acciones.md`) y solo cambian ramas de `ActionRules`. Celdas marcadas † para
   confirmar: olla con la mano vacía y solo cociendo (—), caja con pulpo crudo (—), cuenco con caja a
   medias (—, como D23).
6. **Detector**: `@export var actor: InteractionComponent`; descarta candidatos con hint `NONE`; sin
   control no publica objetivo; señal local `hint_changed(target, hint)` + `get_hint()`.
7. **Histéresis** en `InteractionScoring.pick_best(..., current := -1, hysteresis_margin := 0.0)`:
   se cambia si el nuevo supera al actual en `margin × max(|score|, 1)`, si el actual deja de ser
   candidato o por la prioridad categórica de cogible suelto. `PlayerConfig.hysteresis_margin` = 0,2.
8. **Bus**: dos señales nuevas, `action_hint_changed(player_index: int, verb: StringName, state: int,
   reason: StringName)` e `interaction_resolved(player_index, verb, state, reason)`, emisor el
   `InteractionComponent` del personaje que controla `player_index` (uno por jugador; ADR-002
   Enmienda 2, como `character_switched`). Receptor: el botón táctil. Local:
   `InteractionComponent.interaction_resolved(target, hint)`.
9. **Respuesta única**: el rechazo suena en el jugador (`rejected` o `already_applied`, `SHAKE` del
   objetivo); el éxito, en la escena del efecto. Las estaciones dejan de sonar `season_error`;
   `ALREADY_APPLIED` del dispensador deja de ser silencioso (sustituye §10.2).
10. **Prompt en el mundo**: `ActionPrompt` (`components/action_prompt.gd`, escena
    `entities/player/action_prompt.tscn`, `%ActionPrompt` en `player.tscn`), `Sprite3D` billboard sin
    test de profundidad, ≥ 64 px a 1080 (72 por datos), lee el hint del detector **local**. Iconos en
    `ActionIconSet` (`resources/action_icon_set.gd`, `data/config/action_icons.tres`), compartidos con
    el botón táctil. `%PromptAnchor` opcional en los objetivos.
11. **Corte al mantener**: `HoldRepeat` (núcleo) + `PlayerInput.is_interact_pressed()` +
    `InputConfig.cut_repeat_interval` = 0,2; solo `ActionVerb.REPEATABLE = [cut]`; para en silencio
    al pasar a `BLOCKED`.
12. **Entrega solo por zona**: `OrderStand` sale del grupo y de la capa `interactable` (pasa a
    `world`), sin `interact`; entrega al entrar o al pasar a coincidir estando dentro.
    `delivery_rejected` se queda sin emisión en el juego (firma intacta); D8 sin efecto práctico.
13. **Cuenco solo pone** con `Box.apply_seasoning`; bajas del toggle, `toggle_guard`,
    `SeasoningRules.toggle()` y `Box.toggle_seasoning()` (estas dos en la oleada de montaje para no
    romper el cuenco a mitad de oleada). `SeasoningData.verb` en datos.
14. **Cues** (ADR-006 §4.1): `cook_ready` (renombra `cook_done`), `burn_warning` y `trash` con
    sonido propio, `box_full` (sustituye a `cut` en el corte que llena), `switch`, `rejected`,
    `already_applied`; bajas `cook_done`, `season_error`, `deliver_error` en la oleada de montaje.
    Test de que los `stream` son distintos.
15. **Táctil** (ADR-004 §6): sin eventos táctiles en el InputMap; stick con `Input.action_press`
    con fuerza y botones con `InputEventAction` por `Input.parse_input_event`; multitáctil por
    `event.index`; visibles si hay pantalla táctil, modo `SINGLE` y la última entrada no fue teclado ni
    mando (`TouchInput.controls_visible`); ≥ 72 dp / 48 dp con 1 dp = 2,5 px a 1080.
16. **Escala** (ADR-005 E2–E4): `canvas_items` + `expand` + `sensor_landscape`; baja de
    `UiScale.factor()`; `UiProfile` por plataforma (`content_scale`, `min_text_px_1080` 36 en móvil);
    `UiScale.dp_to_units/px_to_units/safe_margins`; `SafeAreaMargin`.
17. **Plataforma** (ADR-005 E1): `PlatformProfile.detect()` (forzable con `--profile=mobile`), guardado
    en `GameState.platform`; el menú oculta Local 2P en `MOBILE`; pausa al perder el foco.
18. **Cámara** (ADR-005 E5): `CameraRig` con script y dos `CameraProfile` (escritorio 12,74 fija =
    hoy; móvil 9,0 = 120 px/m a 1080, seguimiento suavizado 0,25 s del personaje activo de J1 por
    `character_switched`); `CameraFollow` puro.
19. **Android** fuera de esta oleada (`export.md`).

### Preguntas abiertas para el gate
- P1. ¿Se acepta que, sin objetivo con verbo y con la mano llena, pulsar **suelte** delante (ya no
  hay estaciones que «protejan» la mano consumiendo la pulsación)? Alternativa: consumir en silencio
  cerca de una estación, a costa de una pulsación muda.
- P2. Las celdas † de §11.6 (las resuelve la tabla de PUL-119).
- P3. `deliver_error` y la penalización de D8 quedan muertas en el juego: ¿se quitan del núcleo en una
  ficha de limpieza posterior o se conservan por si vuelve la entrega por pulsación?

## Partición en fichas de implementación

Rutas relativas a la raíz del repo. `x.gd*` = `x.gd` y `x.gd.uid`. Cada ficha escribe su id en
`.claude/current-task`. Dentro de una oleada los `owns` y `touches_scenes` son **disjuntos**; un `.tscn`
y `project.godot` tienen un solo dueño por oleada. Los ids son propuestos (PUL-121…PUL-132); el
producer puede renumerar.

### Oleadas y dependencias
| Oleada | Fichas (en paralelo) | Depende de |
|---|---|---|
| 1 | PUL-121 núcleo (gameplay) · PUL-122 escala y plataforma (ui) · PUL-123 iconos y arte (asset) · PUL-124 audio (asset) | PUL-119 y PUL-120 en `main` |
| 2 | PUL-125 cocina y objetos (gameplay) · PUL-126 condimentos (gameplay) · PUL-127 prompt y jugador (gameplay) · PUL-128 táctil (ui) · PUL-129 HUD y tickets (ui) · PUL-130 cámara (gameplay) | 125: 121, 124 · 126: 121, 123 · 127: 121, 123, 124 · 128: 121, 122, 123 · 129: 122 · 130: 122 |
| 3 | PUL-131 entrega por zona, montaje y limpieza (gameplay) | toda la oleada 2 |
| 4 | PUL-132 QA D26 (qa-tester) | PUL-131 |

Con tres gameplay-engineers y dos ui-engineers la oleada 2 corre entera en paralelo. Orden de merge
en la oleada 2: 125 antes que 126 (los flujos de 125 deben seguir verdes con el cuenco nuevo; si no,
126 avisa); el resto en cualquier orden. El puesto va en la oleada 3 porque cambia todos los flujos
de entrega, que son de la ficha de montaje. Si un cambio rompe un test que no está en tus `owns`,
para y avisa al producer.

**Ficheros con dueño en dos oleadas** (uno en cada una): `player.tscn` (121 → 127); `hud.gd`,
`order_tickets_panel.gd`, `test_hud` y `test_order_tickets` (122 → 129); `test_audio_feedback`
(124 → 125 → 131); `box.gd` (125 → 131); flujos y `test_level_01*` (125 → 131, y `r16` también en
121); `test_m2b_station_selection` (121 → 126); `interaction_contract.gd` y su test (121 → 131);
`feedback_map.tres` (124 → 131); `test_seasoning_station`, `test_m2b_flow` y `test_station_level`
(126 → 131).

### PUL-121 — Núcleo del lenguaje de acciones, histéresis y bus (gameplay-engineer, oleada 1)
- **owns**: `godot/core/action_verb.gd*`, `godot/core/action_reason.gd*`, `godot/core/action_hint.gd*`,
  `godot/core/action_rules.gd*`, `godot/core/hold_repeat.gd*`, `godot/core/interaction_scoring.gd*`,
  `godot/core/player_input.gd*`, `godot/components/interaction_component.gd*`,
  `godot/components/interaction_detector.gd*`, `godot/components/interaction_contract.gd*` (solo
  `HINT_METHOD`, sin hacerlo obligatorio), `godot/entities/items/held_kind.gd*`,
  `godot/resources/player_config.gd*`, `godot/resources/input_config.gd*`,
  `godot/data/config/player_config.tres`, `godot/data/config/input_config.tres`,
  `godot/autoload/event_bus.gd*`; tests `godot/tests/unit/test_action_hint.gd*`,
  `test_action_rules.gd*`, `test_hold_repeat.gd*`, `test_interaction_scoring.gd*`,
  `test_interaction_component.gd*`, `test_event_bus.gd*`, `test_player_input.gd*`,
  `test_interaction_contract.gd*`, `godot/tests/integration/test_interaction_detector.gd*`,
  `test_held_kind.gd*`, `test_m2b_station_selection.gd*` y `test_level_01_r16.gd*` (solo para
  ajustarlos a la histéresis y al filtro de control),
  `godot/tests/helpers/fake_*.gd*`.
- **touches_scenes**: `godot/entities/player/player.tscn` (solo `%InteractionDetector.actor =
  %InteractionComponent`).
- **Change**: ADR-003 §11.1–§11.4 completo; `event_bus.gd` con las dos señales (`signals.md` §2).
  Equivalencia transitoria (`can_interact` → `OK` sin verbo) para que la oleada 1 no cambie el juego.
- **Tests que deben existir**: `test_action_rules.gd` exhaustivo contra la tabla de PUL-119 (las 72
  celdas mano × receptor más variantes de estado; ≥ 40 casos, nombres que citen la fila);
  `test_action_hint.gd` (constructores, invariantes, `same_as` ignora `progress`, `ALL` sin duplicados
  ni vacío); `test_hold_repeat.gd` (primer disparo a `interval`, uno por llamada, `disarm`);
  `test_interaction_scoring.gd` (margen 0 = comportamiento actual; el actual se mantiene con +19 %,
  cambia con +21 %; cambia si el actual sale del cono; la prioridad de cogible suelto manda;
  puntuaciones negativas usan base 1); `test_interaction_detector.gd` (un candidato `NONE` no se
  resalta ni se publica; `hint_changed` solo al cambiar verbo/estado/motivo u objetivo, no por
  `progress`; sin control no hay objetivo ni contorno); `test_interaction_component.gd` (sin objetivo o
  `NONE` → regla de soltar sin señal; `OK` y `BLOCKED` → una `interaction_resolved` local y una de bus
  con primitivos; sin control no emite; al cambiar de personaje, `NONE` del saliente antes que el hint
  del entrante; mantener repite `cut` cada 0,2 s de juego, para al pasar a `BLOCKED` sin emitir y se
  congela en pausa); `test_event_bus.gd` (nombre y aridad de las dos señales); `test_player_input.gd`
  (`is_interact_pressed`); test de datos: `hysteresis_margin` 0,2 y `cut_repeat_interval` 0,2.

### PUL-122 — Escala de UI, safe area y perfil de plataforma (ui-engineer, oleada 1)
- **owns**: `godot/project.godot`, `godot/core/platform_profile.gd*`, `godot/autoload/game_state.gd*`,
  `godot/resources/ui_profile.gd*`, `godot/data/config/ui_profile_desktop.tres`,
  `godot/data/config/ui_profile_mobile.tres`, `godot/ui/widgets/ui_scale.gd*`,
  `godot/ui/widgets/safe_area_margin.gd*`, `godot/ui/theme/**`, `godot/ui/menus/**`,
  `godot/ui/hud/hud.gd*` y `godot/ui/tickets/order_tickets_panel.gd*` (solo quitar la línea de
  `UiScale.factor`); tests `godot/tests/unit/test_platform_profile.gd*`, `test_ui_scale.gd*`,
  `test_game_state.gd*`, `test_project_settings.gd*`, `godot/tests/integration/test_main_menu.gd*`,
  `test_pause_menu.gd*`, `test_game_over.gd*`, `test_ui_gamepad.gd*`, `test_ui_text_min.gd*`,
  `test_hud.gd*`, `test_order_tickets.gd*`; `docs/evidence/PUL-122/**`.
- **touches_scenes**: `godot/ui/menus/main_menu.tscn`, `pause_menu.tscn`, `game_over.tscn`,
  `menu_panel.tscn`.
- **Change**: ADR-005 E1–E4, ADR-004 §6.5 (menú y pausa al perder el foco), ADR-002 Enmienda 2.2.
- **Tests que deben existir**: `test_platform_profile.gd` (forzado gana; `mobile` → `MOBILE`; web +
  táctil → `MOBILE`; resto `DESKTOP`); `test_ui_scale.gd` (`dp_to_units`: 72 dp = 180 px a 1080 de
  alto con cualquier lienzo; `px_to_units`; `safe_margins` con muesca izquierda y sin muesca);
  `test_project_settings.gd` (`stretch/mode` `canvas_items`, `aspect` `expand`, `orientation` 4);
  `test_game_state.gd` (`set_platform` aplica `content_scale_factor`; pausa al perder el foco solo en
  `MOBILE` y en ronda); `test_main_menu.gd` («Local 2P» oculto en `MOBILE`, foco en Individual);
  `test_ui_text_min.gd` (con el perfil móvil, todo texto de HUD, tickets y menús ≥ 36 px a 1080);
  capturas de menú, pausa y game over a 1280×720, 1920×1080 y 2340×1080 `--profile=mobile`.

### PUL-123 — Iconos de verbos y motivos, aliño picante propio, rack y caja sin S/M/L (asset-pipeline, oleada 1)
- **owns**: `godot/assets/textures/ui/actions/**`, `godot/assets/textures/icons/sweet_dressing.svg*`,
  `godot/assets/textures/icons/hot_dressing.svg*` (con `.import`), `godot/resources/action_icon_set.gd*`,
  `godot/data/config/action_icons.tres`, `art/blender/box_shelf.blend`,
  `godot/assets/models/stations/box_shelf/**`, `art/blender/box.blend`,
  `godot/assets/models/items/box/**`, `godot/assets/textures/ui/box_sizes/**` (baja),
  `godot/tests/unit/test_assets_actions.gd*`, `docs/evidence/PUL-123/**`.
- **touches_scenes**: ninguna (los `.glb` cambian contenido, no las escenas que los instancian).
- **Change**: SVG propios (sin créditos externos) `verb_<id>.svg` × 8, `reason_<id>.svg` × 5,
  `plate.svg`, `cross.svg`, siluetas de PUL-119 (AC5); iconos de aliño dulce y picante distinguibles
  sin color; `ActionIconSet` (ADR-003 §11.5) y `action_icons.tres` con las claves literales del
  contrato; rack y textura de la caja sin letras S/M/L (reexport con el pipeline de PUL-043).
- **Tests que deben existir**: `test_assets_actions.gd` (cada `verb_<id>` y `reason_<id>` del contrato
  existe e importa; `action_icons.tres` tiene exactamente esas claves; a 64 px en gris, la diferencia
  media de máscara entre cualquier par de verbos ≥ umbral fijado en la ficha, incluidos dulce/picante);
  evidencia: hoja de contacto a 64 px en gris y capturas del rack y la caja.

### PUL-124 — Cues de D26 (asset-pipeline, oleada 1)
- **owns**: `godot/assets/audio/sfx/**`, `godot/data/audio/feedback_map.tres`, `godot/assets/CREDITS.md`,
  `godot/tests/unit/test_assets_audio_ui.gd*`, `godot/tests/unit/test_feedback_distinct.gd*`,
  `godot/tests/integration/test_audio_feedback.gd*` (solo la lista de claves cerradas),
  `docs/evidence/PUL-124/**`.
- **touches_scenes**: ninguna.
- **Change**: claves nuevas `cook_ready`, `box_full`, `switch`, `rejected`, `already_applied` y sonido
  propio para `burn_warning` y `trash` (ADR-006 §4.1). **Sin quitar** `cook_done`, `season_error` ni
  `deliver_error` (las retira PUL-131).
- **Tests que deben existir**: `test_feedback_distinct.gd` (los `stream` de los 7 cues de D26 son
  distintos entre sí y de `drop`, `pick_up`, `cut`, `cook_start`, `season`; `visual_time ≥ 0.3` con
  visual); `test_assets_audio_ui.gd` al día (licencias en `CREDITS.md` si hay samples externos). `test_audio_feedback.gd`: `CUES` con
  las 5 claves nuevas (las 3 de baja siguen hasta PUL-131).

### PUL-125 — Verbo en cocina y objetos; barras, contador y aviso de quemado (gameplay-engineer, oleada 2)
- **owns**: `godot/entities/items/box.gd*`, `godot/entities/items/ingredient.gd*`,
  `godot/entities/stations/cooking_station.gd*`, `godot/entities/stations/slot.gd*`,
  `godot/entities/stations/item_spawner.gd*`, `godot/entities/stations/trash_bin.gd*`,
  `godot/ui/widgets/world_progress_bar.gd*`; tests `godot/tests/integration/test_box.gd*`,
  `test_box_on_slot.gd*`, `test_box_model.gd*`, `test_burn.gd*`, `test_cooking_station.gd*`,
  `test_item_spawner.gd*`, `test_slot.gd*`, `test_trash_bin.gd*`, `test_octopus.gd*`,
  `test_shelves.gd*`, `test_hold_component.gd*`, `test_audio_feedback.gd*`,
  `test_world_progress_bar.gd*`, `test_kitchen_hints.gd*` y los flujos `test_kitchen_flow.gd*`,
  `test_m1_flow.gd*`, `test_m2_flow.gd*`, `test_parity_smoke.gd*`, `test_delivery_e2e.gd*`,
  `test_level_01.gd*`, `test_level_01_r16.gd*`, `level_walker.gd*` (para mantenerlos en verde con el
  `can_interact` honesto).
- **touches_scenes**: `godot/entities/items/box.tscn`, `godot/entities/stations/kitchen.tscn`,
  `godot/ui/widgets/world_progress_bar.tscn`.
- **Change**: `get_action_hint` + `_resolve` sobre `ActionRules` en caja, pulpo/cachelos, olla,
  pasaplatos, spawners y cubo (§11.2, §11.6); `can_interact` honesto; `%CutCounter` y
  `get_presses()`; parpadeo de quemado; cues `cook_ready` (en lugar de `cook_done`) y `box_full`;
  barras ≥ 8 px a 1080. **No** quita `Box.toggle_seasoning()` (lo hace PUL-131).
- **Tests que deben existir**: `test_kitchen_hints.gd` (por cada fila de la tabla para estos
  receptores: el hint publicado coincide con el efecto de `interact` y `interact` devuelve `true`
  siempre que el hint no sea `NONE`; ninguna pulsación con hint `OK` deja el estado igual); casos de
  `can_interact` honesto (spawner, caja y olla con la mano llena → `false`); `test_box.gd`
  (`%CutCounter` «N/6», `box_full` en el 6.º corte, `CUT` `BLOCKED` `full` en el 7.º);
  `test_burn.gd` (parpadeo al `burn_warned`, ≥ 3 s antes de quemar); `test_world_progress_bar.gd`
  (grosor proyectado ≥ 8 px a 1080 con la cámara de escritorio); `test_audio_feedback.gd` al día
  (`cook_ready`, `box_full`); flujos en verde.

### PUL-126 — Verbo en la estación de condimentos y cuenco que solo pone (gameplay-engineer, oleada 2)
- **owns**: `godot/entities/stations/seasoning_dispenser.gd*`, `godot/entities/stations/cachelos_bowl.gd*`,
  `godot/resources/seasoning_data.gd*`, `godot/resources/seasoning_station_data.gd*`,
  `godot/data/seasonings/**`, `godot/data/config/seasoning_station.tres`; tests
  `godot/tests/integration/test_seasoning_station.gd*`, `test_cachelos.gd*`, `test_m2b_flow.gd*`,
  `test_station_level.gd*`, `test_m2b_station_selection.gd*`, `test_station_hints.gd*`,
  `godot/tests/unit/test_data_integrity.gd*`, `test_data_catalog.gd*`.
- **touches_scenes**: `godot/entities/stations/cachelos_bowl.tscn`,
  `godot/entities/stations/seasoning_dispenser.tscn`.
- **Change**: §11.2 en dispensadores y cuenco (verbo de `SeasoningData.verb`; `ALREADY_APPLIED` con
  `rejected` y sin silencio); cuenco solo pone con `apply_seasoning`, sin toggle ni antirrebote; baja
  de `toggle_guard`; `SeasoningData.verb` en los 3 `.tres`; `hot_dressing.tres` con el icono de
  PUL-123. **No** toca `seasoning_station.gd` (sigue sonando `season_error` hasta PUL-131) ni el
  puesto.
- **Tests que deben existir**: `test_station_hints.gd` (filas de dispensador y cuenco de la tabla,
  hint = efecto; desde el lado de pase siguen sin ser objetivo); `test_cachelos.gd` (pone; ya lleva →
  `BLOCKED` `already_applied` sin cambios; stock 0 → `empty`; reponer lleno → `full`; no hay quitar);
  `test_seasoning_station.gd` (mismo aliño → `rejected(ALREADY_APPLIED)`, ya no silencio); test de
  datos (`verb` válido en los 3 `SeasoningData`; sin `toggle_guard`); `test_m2b_flow` y
  `test_station_level` en verde.

### PUL-127 — Prompt de acción en el mundo, respuesta del jugador y aro activo (gameplay-engineer, oleada 2)
- **owns**: `godot/components/action_prompt.gd*`, `godot/entities/player/player.gd*`; tests
  `godot/tests/integration/test_action_prompt.gd*`, `test_player.gd*`, `test_player_feedback.gd*`; `docs/evidence/PUL-127/**`.
- **touches_scenes**: `godot/entities/player/player.tscn`, `godot/entities/player/action_prompt.tscn`
  (nueva).
- **Change**: ADR-003 §11.5 y §11.8 (aro); respuesta de rechazo en `%Feedback` del jugador
  (`rejected` / `already_applied`, `SHAKE` del objetivo) y cue `switch` (ADR-006 §4.1).
- **Tests que deben existir**: `test_action_prompt.gd` (visible solo con `OK`/`BLOCKED` y
  personaje controlado; icono y color del verbo; × y motivo en `BLOCKED`; usa `%PromptAnchor` si
  existe; tamaño proyectado ≥ 64 px a 1080 con los dos perfiles de cámara; salto/sacudida ≥ 0,3 s);
  `test_player_feedback.gd` (un `BLOCKED` suena `rejected` una vez; `already_applied` con su motivo;
  `OK` no suena en el jugador salvo coger/soltar; `switch` al cambiar en ronda y no al arrancar);
  `test_player.gd` (aro activo e inactivo distintos); capturas del prompt sobre olla, caja y
  dispensador con el jugador delante.

### PUL-128 — Controles táctiles (ui-engineer, oleada 2)
- **owns**: `godot/ui/touch/**`, `godot/core/touch_input.gd*`, `godot/resources/touch_config.gd*`,
  `godot/data/config/touch_config.tres`; tests `godot/tests/unit/test_touch_input.gd*`,
  `godot/tests/integration/test_touch_controls.gd*`; `docs/evidence/PUL-128/**`.
- **touches_scenes**: `godot/ui/touch/touch_controls.tscn` (nueva).
- **Change**: ADR-004 §6.1–§6.3.
- **Tests que deben existir**: `test_touch_input.gd` (`source_of` por tipo de evento, el ratón y
  `InputEventAction` no cambian la fuente; `controls_visible` en las combinaciones; `stick_vector` con
  zona muerta y recorte); `test_touch_controls.gd` (arrastre del stick → fuerza en `p1_move_*` y
  `PlayerInput.get_move_vector()`; dos dedos a la vez: stick + acción; mantener el botón → 
  `Input.is_action_pressed(&"p1_interact")` y corte repetido; al soltar todo se libera; `pause` y
  `p1_switch`; icono y color del botón con `action_hint_changed`; respuesta a `interaction_resolved`;
  ocultos en `COOP_2P`, al pulsar una tecla y visibles al tocar; tamaños ≥ 72/48 dp medidos en px a
  1080); capturas a 2340×1080 `--profile=mobile`.

### PUL-129 — HUD y tickets para móvil (ui-engineer, oleada 2)
- **owns**: `godot/ui/hud/**`, `godot/ui/tickets/**`, `godot/ui/sandbox/**`; tests
  `godot/tests/integration/test_hud.gd*`, `test_order_tickets.gd*`, `test_ui_layout_mobile.gd*`;
  `docs/evidence/PUL-129/**`.
- **touches_scenes**: `godot/ui/hud/hud.tscn`, `godot/ui/tickets/order_tickets_panel.tscn`,
  `order_ticket.tscn`, `ticket_entry.tscn`, `godot/ui/sandbox/hud_sandbox.tscn`.
- **Change**: ADR-005 E3–E4 en HUD y tickets: `SafeAreaMargin`, anclas a bordes, HUD fuera de la zona
  del stick en `MOBILE`, 4 tickets sin recortar, sin «Cajas / minuto» (D26.7), textos ≥ 36 px a 1080
  en móvil.
- **Tests que deben existir**: `test_ui_layout_mobile.gd` (a 2340×1080 y a 1920×1080 con el perfil
  móvil y safe area simulada: ningún control del HUD en la mitad inferior izquierda; 4 tickets
  visibles enteros; nada bajo la muesca; a 1280×720 escritorio sin solapes); `test_hud.gd` sin
  «Cajas / minuto»; capturas.

### PUL-130 — Cámara con perfiles y seguimiento móvil (gameplay-engineer, oleada 2)
- **owns**: `godot/entities/camera/camera_rig.gd*`, `godot/resources/camera_profile.gd*`,
  `godot/core/camera_follow.gd*`, `godot/data/config/camera_desktop.tres`,
  `godot/data/config/camera_mobile.tres`; tests `godot/tests/unit/test_camera_follow.gd*`,
  `godot/tests/integration/test_camera_rig.gd*`; `docs/evidence/PUL-130/**`.
- **touches_scenes**: `godot/entities/camera/camera_rig.tscn`.
- **Change**: ADR-005 E5.
- **Tests que deben existir**: `test_camera_follow.gd` (recorte a límites, suavizado exponencial,
  `smoothing` 0 = inmediato, `px_per_meter`); `test_camera_rig.gd` (escritorio: transformación y
  `size` 12,74 sin cambios; móvil: `size` 9,0 → ≥ 120 px/m a 1080; sigue al personaje activo tras
  `character_switched(1, 2)`; sin `characters` no falla); capturas del perfil móvil en las 4 esquinas
  de la planta para fijar los límites.

### PUL-131 — Entrega solo por zona, montaje D26 en `level_01` y limpieza de contrato (gameplay-engineer, oleada 3)
- **owns**: `godot/entities/stations/order_stand.gd*`, `godot/entities/stations/seasoning_station.gd*`,
  `godot/scenes/levels/level_01.tscn`, `godot/components/interaction_contract.gd*`,
  `godot/data/audio/feedback_map.tres`, `godot/entities/items/box.gd*`,
  `godot/core/seasoning_rules.gd*`; tests `godot/tests/integration/test_order_stand.gd*`,
  `test_delivery_e2e.gd*`, `test_kitchen_flow.gd*`, `test_m1_flow.gd*`, `test_m2_flow.gd*`,
  `test_m2b_flow.gd*`, `test_station_level.gd*`, `test_parity_smoke.gd*`, `test_level_01.gd*`,
  `test_level_01_r16.gd*`, `level_walker.gd*`, `test_items_contract.gd*`,
  `test_stations_contract.gd*`, `test_audio_feedback.gd*`, `test_seasoning_station.gd*`,
  `godot/tests/unit/test_seasoning_rules.gd*`, `test_interaction_contract.gd*`,
  `godot/tests/helpers/m0_data/**`.
- **touches_scenes**: `godot/entities/stations/order_stand.tscn`,
  `godot/entities/stations/seasoning_station.tscn`, `godot/scenes/levels/level_01.tscn` y, si algún
  sandbox necesita `CameraRig.characters` o deja de cargar por las bajas, los `sandbox/*.tscn`
  afectados (el producer los lista al abrir la ficha).
- **Change**: ADR-003 §11.7 del puesto (fuera de `interactable`, capa `world`, sin `interact`, entrega
  al entrar o al pasar a coincidir dentro de la zona); `seasoning_station.gd` y `order_stand.gd` dejan
  de reproducir `season_error` / `deliver_error`; `TouchControls` en `UI` y `CameraRig.characters` en
  el nivel (`scene-tree.md` §2); `get_action_hint` obligatorio en `INTERACTABLE_METHODS`; bajas de
  `cook_done`, `season_error` y `deliver_error` en el mapa, `SeasoningRules.toggle()` y
  `Box.toggle_seasoning()` (`scene-tree.md` §7.3).
- **Tests que deben existir**: `test_order_stand.gd` (no está en `interactable` ni en su capa; el
  detector no lo elige desde ningún punto de la zona; entrega al entrar; entrega a quien ya estaba
  dentro cuando sale la comanda; caja errónea: nada, sin `delivery_rejected`); contrato
  (`test_items_contract`, `test_stations_contract`): todo `interactable` de `entities/` implementa
  `get_action_hint` y ninguno depende de la equivalencia sin verbo; `test_level_01.gd`
  (`TouchControls` presente y en orden; `CameraRig.characters`; regla de colocación de los cubos sin
  cambios); `test_audio_feedback.gd` con las claves finales; flujos (`test_m1_flow`,
  `test_delivery_e2e`, `test_kitchen_flow`, `test_m2_flow`, `test_m2b_flow`, `test_parity_smoke`,
  `test_level_01*`) entregando por zona y en verde.

### PUL-132 — QA de D26 (qa-tester, oleada 4)
- **owns**: `docs/evidence/PUL-132/**`, `godot/tests/integration/test_d26_no_mute_press.gd*`,
  `godot/tests/integration/test_d26_touch_flow.gd*`.
- **touches_scenes**: ninguna.
- **Change**: verificación de D26 en `level_01` contra las features de PUL-119.
- **Tests que deben existir**: `test_d26_no_mute_press.gd` (recorre con `level_walker` cada tipo de
  objetivo con cada clase de mano de la tabla: antes de pulsar el hint de bus coincide con la tabla; al
  pulsar hay exactamente una `interaction_resolved` y un cue de respuesta, o ninguna señal y una
  caída si no había objetivo; ≥ 40 combinaciones); `test_d26_touch_flow.gd` (partida corta en
  `--profile=mobile` solo con eventos táctiles inyectados: coger, cocer, cortar manteniendo, aliñar,
  cambiar, pausar, entregar por zona). Evidencia: capturas a 1280×720, 1920×1080, 2340×1080 móvil y
  800×370; hoja de verbos a 64 px en gris; guía de playtest para el responsable.
