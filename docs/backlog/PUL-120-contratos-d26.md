---
id: PUL-120
title: Enmendar los contratos para D26 (verbo de acción, prompt, táctil, cámara móvil)
status: done
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
7. Reconciliación con PUL-119 tras su merge (tabla A–F, iconos, cues, táctil, cámara): §11 de
   ADR-003, ADR-004 §6, ADR-005 Enmienda D26, ADR-006 §4.1, `signals.md` y `scene-tree.md` §9;
   equivalencia de nombres y partición con ACs (abajo).

## Evidence
- Ficheros: `docs/arch/ADR-003-arbol-escenas-composicion.md` (§11 nueva + notas),
  `docs/arch/ADR-004-input-coop-local.md` (§6), `docs/arch/ADR-005-dimension-3d-2d.md` (Enmienda D26),
  `docs/arch/ADR-006-audio-feedback.md` (§4.1), `docs/arch/ADR-002-eventbus-autoloads.md`
  (Enmienda 2), `docs/arch/signals.md`, `docs/arch/scene-tree.md` (§2, §3, §7.3, §9),
  `docs/arch/export.md`, `docs/arch/README.md`. ADR-001 sin cambios.
- `tools/verify.sh --quick`: verde (gdformat, gdlint, import), 2026-10-11.

### Decisiones de contrato tomadas (para el gate humano)
1. **Verbos cerrados** (`core/action_verb.gd`, `ActionVerb`, `StringName`): `pick_up` COGER, `drop`
   SOLTAR (en pasaplatos o al suelo), `cook` COCER, `cut` CORTAR, `season_sweet` ALIÑAR DULCE,
   `season_hot` ALIÑAR PICANTE, `cachelos` CACHELOS, `trash` TIRAR (incluye el quemado); `&""` =
   ninguno. Sin verbo de entregar.
2. **Motivos cerrados** (`core/action_reason.gd`, `ActionReason`, 6): `box_not_full`, `busy`, `empty`,
   `full`, `already_applied`, `not_cooked`; `&""` = ninguno. Prioridad del diseño (objetivo antes que
   mano) con la excepción de la fila E1 (cuenco a 0 con caja que ya lleva cachelos → `already_applied`).
3. **`ActionHint`** (`core/action_hint.gd`): `verb`, `state` (`NONE 0 / OK 1 / BLOCKED 2`), `reason`,
   `replaces` (insignia de sustituir aliño), `progress`. Única excepción a las invariantes: `OK` con
   verbo vacío para entidades sin migrar y dobles de test.
4. **Una sola resolución**: `_resolve(holder)` en cada receptor → `ActionRules.for_*` (pura, con `enum
   Held`); `get_action_hint` y `interact` la usan. `HeldKind.of(item)` clasifica la mano.
   `get_action_hint` obligatorio en `entities/` desde la oleada de montaje; `can_interact` honesto.
5. **Tabla**: ADR-003 §11.6 transcribe la de `lenguaje-acciones.md` (A–F). Celdas † resueltas por el
   diseño: olla vacía o solo cociendo con la mano vacía → `—`; caja con pulpo crudo → `B:not_cooked`;
   caja llena con pulpo (crudo o cocido) → `B:full`; cuenco con caja vacía o a medias (lado de aliñar)
   → `B:box_not_full`. Fixture `tests/fixtures/action_matrix.csv` (≥ 250 filas) para el test puro y el
   de escena (puerta de D26).
6. **Sin objetivo con la mano llena** (P1, decisión del producer autorizada por el responsable): hint
   de suelo `OK:drop` con sitio delante (prompt en el punto de soltar, `HoldComponent.get_drop_position()`)
   y `B:busy` contra barra o pared, con su respuesta de rechazo. Ya no hay pulsación muda; sustituye a
   la regla de §9.5 «consumir en silencio».
7. **Detector**: `@export var actor`; descarta candidatos `NONE`; sin control no publica; hint de suelo;
   `hint_changed(target, hint)` + `get_hint()`; `Highlightable.set_blocked()` para el contorno ámbar.
8. **Histéresis**: `pick_best(..., current := -1, hysteresis_margin := 0.0)`; cambia si
   `score(nuevo) > score(actual) + margin × |score(actual)|` (= ×1,20 con puntuación positiva), si el
   actual deja de ser candidato o por la prioridad categórica de cogible suelto; OK ↔ BLOQUEADO no
   invalida. `PlayerConfig.hysteresis_margin` = 0,2.
9. **Bus**: `action_hint_changed(player_index: int, verb: StringName, state: int, reason: StringName)`
   e `interaction_resolved(player_index, verb, state, reason)`, emisor el `InteractionComponent` del
   personaje que controla `player_index` (ADR-002 Enmienda 2). `interaction_resolved` sale también al
   soltar al suelo (OK o `busy`). Local: `InteractionComponent.interaction_resolved(target, hint)`.
10. **Respuesta única**: rechazo = cue único `rejected` en el `%Feedback` del jugador (todos los
    motivos, incluido «ya aplicado»), `SHAKE` del objetivo; éxito = cue del efecto en su escena. Las
    estaciones dejan de sonar `season_error`; el dispensador deja de ser silencioso con el mismo aliño.
11. **Prompt en el mundo**: `ActionPrompt` (`components/action_prompt.gd`,
    `entities/player/action_prompt.tscn`, `%ActionPrompt` en `player.tscn`), medidas del diseño (icono
    64 px, placa 80 px a 1080, mín. 48 px; motivo 32, aspa 24; `prompt_offset` 0,9 m), lado a lado en
    Local 2P con registro estático de clase. Datos en `ActionIconSet` (`data/config/action_icons.tres`).
12. **Corte al mantener**: `HoldRepeat` + `PlayerInput.is_interact_pressed()` +
    `InputConfig.cut_repeat_interval` = 0,2; solo `cut`; se para sin rechazo.
13. **Entrega solo por zona**: `OrderStand` fuera de `interactable` (capa `world`); entrega al entrar o
    al pasar a coincidir dentro. P3: `delivery_rejected`, `OrderBoard` y el campo
    `wrong_delivery_penalty` **se conservan en el núcleo**; PUL-131 pone el dato a 0 y quita
    `deliver_error` del puesto y del mapa.
14. **Cuenco solo pone**; reponer solo si `stock + 2 ≤ 4` (tabla E3); cualquier caja es candidata desde
    el lado de aliñar; bajas del toggle (`toggle_guard`, y en montaje `SeasoningRules.toggle()` y
    `Box.toggle_seasoning()`). `SeasoningData.verb` e `icon` del aliño = icono del verbo.
15. **Cues** (ADR-006 §4.1): `cook_ready` (renombra `cook_done`), `box_full`, `switch`, `rejected`;
    sample propio para `trash`, `discard` y `burn_warning` (repetido cada 1 s, máx. 3); 7 streams
    distintos; bajas `cook_done`, `season_error`, `deliver_error` en montaje.
16. **Estado legible**: `%CookRing` (`ui/widgets/world_progress_ring.tscn`), `%CutCounter` segmentado
    con «N/6», `%StockMeter` del cuenco, aro activo sólido / inactivo discontinuo + `%ActiveMarker`,
    contorno `#FFF4D6` visible a través del personaje y ámbar si bloqueado.
17. **Táctil** (ADR-004 §6): sin eventos en el InputMap; stick con `Input.action_press` con fuerza,
    botones con `InputEventAction`; multitáctil por `event.index`; visibles solo en el perfil `MOBILE`,
    en Individual y si la última entrada no fue un **mando** (el teclado no los oculta); se liberan en
    `DESKTOP`; medidas del diseño en `TouchConfig`; háptica en el botón de acción.
18. **Escala y plataforma** (ADR-005 Enmienda D26): `canvas_items` + `expand` + `sensor_landscape`;
    `UiProfile` (mínimos y maquetación del diseño en px a 1080, zonas reservadas); `UiScale.px_to_units /
    dp_to_units / safe_margins`; `SafeAreaMargin`; `PlatformProfile.detect(features, user_args)` con
    `--touch` = `--profile=mobile`, features `mobile`, `web_android`, `web_ios`; menú móvil solo
    Individual; pausa al perder el foco y con Atrás; pantalla encendida.
19. **Cámara**: `CameraRig` con script, dos `CameraProfile` (escritorio 12,74 fija; móvil 7,0 ≈ 121 px/m
    medidos sobre el personaje, `follow_time` 0,2 crítico, `switch_pan_time` 0,35, margen 1 m),
    `CameraFollow` puro y `%OffscreenArrow` para el personaje inactivo.
20. **Android** fuera de esta oleada (`export.md`).

### Gate: preguntas resueltas
- **P1** (resuelta por el producer con autorización del responsable): mano llena sin objetivo → SOLTAR
  delante si hay sitio, `B:busy` contra barra o pared (punto 6).
- **P2**: celdas † resueltas por la tabla del diseño (punto 5).
- **P3**: se conservan en el núcleo; la limpieza va en PUL-131 (punto 13).

### Contradicciones del diseño encontradas al reconciliar (resueltas en el contrato; avisar al diseñador)
1. **Prioridad de motivos frente a la fila E1**: la regla general («objetivo primero: `EMPTY` antes que
   `ALREADY`») choca con E1 (cuenco a 0 + caja con cachelos → «ya aplicado»). El contrato sigue la
   tabla y lo deja escrito como excepción.
2. **Reponer el cuenco**: E3 (stock 3 → `B:lleno`) cambia la regla vigente de D23/§9.3 (reponer con
   stock < máx. recortando a 4). El contrato adopta la tabla (`stock + 2 ≤ 4`); es un cambio de
   balance pequeño que el diseño no menciona en D26.
3. **Cue `already_applied`**: la ficha PUL-120 lo pedía como cue propio; el diseño pide un único cue de
   rechazo (AC7, AC8 cuenta 7 streams sin él). El contrato sigue al diseño: no hay cue `already_applied`.
4. **Teclado y controles táctiles**: la primera versión del contrato los ocultaba con teclado; el
   diseño solo con mando. Se sigue al diseño.
5. **px/m de la cámara**: el diseño mide sobre el personaje proyectado (66,8 px/m en escritorio); la
   primera versión del contrato usaba `alto / size` (84,8) y proponía `size` 9,0, que habría dado
   ≈ 95 px/m. Se corrige a 7,0 y la medida del diseño.
6. **Pausa móvil**: el diseño cita «Reanudar, Reiniciar y Menú» en la pausa; hoy la pausa tiene
   Reanudar y Salir (`scene-tree.md` §4). Añadir «Reiniciar» es una decisión de diseño que la ficha de
   UI (PUL-122) aplica como dice la feature, sin cambio de contrato (`GameState.restart_level()` ya
   existe).

### Nombres del diseño y del contrato (manda el contrato)
| Diseño (`lenguaje-acciones.md`, `controles-tactiles.md`) | Contrato |
|---|---|
| Verbos `PICK_UP`, `DROP`, `COOK`, `CUT`, `SEASON_SWEET`, `SEASON_HOT`, `CACHELOS`, `TRASH` | `ActionVerb.PICK_UP = &"pick_up"`, `DROP = &"drop"`, `COOK = &"cook"`, `CUT = &"cut"`, `SEASON_SWEET = &"season_sweet"`, `SEASON_HOT = &"season_hot"`, `CACHELOS = &"cachelos"`, `TRASH = &"trash"` |
| Motivos `BOX_NOT_FULL`, `BUSY`, `EMPTY`, `FULL`, `ALREADY`, `RAW` | `ActionReason.BOX_NOT_FULL = &"box_not_full"`, `BUSY = &"busy"`, `EMPTY = &"empty"`, `FULL = &"full"`, **`ALREADY_APPLIED = &"already_applied"`**, **`NOT_COOKED = &"not_cooked"`** |
| «la consulta de acción» | `get_action_hint(actor) -> ActionHint` |
| `icon_verb_<id>` | `assets/textures/ui/actions/icon_verb_<id>.svg` con `<id>` = valor del verbo (`icon_verb_drop.svg`…) |
| `icon_reason_<id>` (`already`, `raw`) | `icon_reason_<id>.svg` con el valor del motivo: **`icon_reason_already_applied.svg`**, **`icon_reason_not_cooked.svg`** |
| `icon_mark_*` (`cross`, `replace`, `ready`, `burn_warning`, `active`, `offscreen`, `player_1`, `player_2`) | Mismos nombres, `icon_mark_<nombre>.svg` |
| Cue `cook_done` (sample propio) | **`cook_ready`** |
| Cue `character_switch` | **`switch`** |
| Cue `action_rejected` | **`rejected`** |
| `box_full`, `trash`, `discard`, `burn_warning` | Iguales |
| `ActionLanguageData` (`action_language.tres`) | Repartido: `hysteresis_margin` → `PlayerConfig`; `cut_repeat_interval` → `InputConfig`; prompt, colores, `response_duration`, `reject_shake_px` → `ActionIconSet` (`action_icons.tres`); anillo y aviso de quemado → `KitchenData` (`kitchen.tres`); contorno → material de `Highlightable` |
| `TouchProfileData` (`touch_profile.tres`; `dp_px`, `secondary_button_dp`, `stick_radius_px`…) | `TouchConfig` (`touch_config.tres`; `px_per_dp_at_1080`, `small_button_dp`, `stick_radius_dp` = 60 dp = 150 px…) |
| `MobileCameraData` (`mobile_camera.tres`; `px_per_meter_min`, `follow_time`, `switch_pan_time`, `camera_margin_m`, `offscreen_arrow_px`) | `CameraProfile` (`camera_mobile.tres`, mismos campos + `ortho_size`, `follow`, `play_area_min/max`) |
| `UiScaleData` (`ui_scale.tres`; `text_min_px`, tickets, banda, botones de menú) | `UiProfile` (`ui_profile_mobile.tres`, mismos campos en px a 1080) |
| Perfil «táctil» / «escritorio»; bandera `--touch` | `PlatformProfile.Kind.MOBILE` / `DESKTOP`; `--touch` y `--profile=mobile` equivalentes |
| `ui_scale = alto / 1080` | Estiramiento `canvas_items` (alto / 720 en unidades de lienzo) + `UiProfile.content_scale`; las medidas «px a 1080» se convierten con `UiScale.px_to_units` |
| Tests `test_action_matrix.gd`, `test_icons_silhouettes.gd`, `test_box_cut_hold.gd`, `test_touch_layout.gd`… | Se conservan los nombres del diseño en la partición |

## Partición en fichas de implementación

Rutas relativas a la raíz del repo. `x.gd*` = `x.gd` y `x.gd.uid`; los `.svg` y `.ogg` van con su
`.import`. Cada ficha escribe su id en `.claude/current-task`, cumple `tools/verify.sh` en verde y deja
capturas en `docs/evidence/<id>/` cuando se piden. Dentro de una oleada los `owns` y `touches_scenes`
son **disjuntos**; un `.tscn` y `project.godot` tienen un solo dueño por oleada. Milestone de todas:
M3e. Los ids son propuestos (PUL-121…PUL-132); el producer puede renumerar.

### Oleadas y dependencias
| Oleada | Fichas (en paralelo) | Depende de |
|---|---|---|
| 1 | PUL-121 núcleo (gameplay) · PUL-122 escala, plataforma y menús (ui) · PUL-123 iconos y arte (asset) · PUL-124 audio (asset) | PUL-119 y PUL-120 en la rama de integración |
| 2 | PUL-125 cocina y objetos (gameplay) · PUL-126 condimentos (gameplay) · PUL-127 prompt, jugador y contorno (gameplay) · PUL-128 táctil (ui) · PUL-129 HUD y tickets (ui) · PUL-130 cámara (gameplay) | 125: 121, 124 · 126: 121, 123 · 127: 121, 123, 124 · 128: 121, 122, 123 · 129: 122, 123 · 130: 122, 123 |
| 3 | PUL-131 entrega por zona, montaje y limpieza (gameplay) | toda la oleada 2 |
| 4 | PUL-132 QA D26 (qa-tester) | PUL-131 |

Con tres gameplay-engineers y dos ui-engineers la oleada 2 corre entera en paralelo. Orden de merge en
la oleada 2: 125 antes que 126 (los flujos de 125 deben seguir verdes con el cuenco nuevo; si no, 126
avisa); el resto en cualquier orden. El puesto va en la oleada 3 porque cambia todos los flujos de
entrega, que son de la ficha de montaje. Si un cambio rompe un test que no está en tus `owns`, para y
avisa al producer.

**Ficheros con dueño en varias oleadas** (uno en cada una): `player.tscn` (121 → 127);
`hold_component.gd`/`test_hold_component` (121 → 125); `hud.gd`, `order_tickets_panel.gd`,
`test_hud`, `test_order_tickets` (122 → 129); `test_audio_feedback` (124 → 125 → 131); `box.gd`
(125 → 131); flujos y `test_level_01*` (125 → 131; `test_level_01_r16` también en 121);
`test_m2b_station_selection` (121 → 126); `interaction_contract.gd` y su test (121 → 131);
`feedback_map.tres` (124 → 131); `test_seasoning_station`, `test_m2b_flow`, `test_station_level`
(126 → 131); `tests/fixtures/action_matrix.csv` (121 → 131).

### PUL-121 — Núcleo del lenguaje de acciones, histéresis y bus
- **role**: gameplay-engineer · **oleada** 1 · **deps**: PUL-119, PUL-120
- **owns**: `godot/core/action_verb.gd*`, `godot/core/action_reason.gd*`, `godot/core/action_hint.gd*`,
  `godot/core/action_rules.gd*`, `godot/core/hold_repeat.gd*`, `godot/core/interaction_scoring.gd*`,
  `godot/core/player_input.gd*`, `godot/components/interaction_component.gd*`,
  `godot/components/interaction_detector.gd*`, `godot/components/interaction_contract.gd*`,
  `godot/components/highlightable.gd*`, `godot/components/hold_component.gd*`,
  `godot/entities/items/held_kind.gd*`, `godot/resources/player_config.gd*`,
  `godot/resources/input_config.gd*`, `godot/data/config/player_config.tres`,
  `godot/data/config/input_config.tres`, `godot/autoload/event_bus.gd*`,
  `godot/tests/fixtures/action_matrix.csv`, `godot/tests/unit/test_action_hint.gd*`,
  `godot/tests/unit/test_action_rules.gd*`, `godot/tests/unit/test_hold_repeat.gd*`,
  `godot/tests/unit/test_interaction_scoring.gd*`, `godot/tests/unit/test_interaction_component.gd*`,
  `godot/tests/unit/test_event_bus.gd*`, `godot/tests/unit/test_player_input.gd*`,
  `godot/tests/unit/test_interaction_contract.gd*`, `godot/tests/integration/test_interaction_detector.gd*`,
  `godot/tests/integration/test_held_kind.gd*`, `godot/tests/integration/test_highlightable.gd*`,
  `godot/tests/integration/test_hold_component.gd*`, `godot/tests/integration/test_m2b_station_selection.gd*`,
  `godot/tests/integration/test_level_01_r16.gd*`, `godot/tests/helpers/fake_*.gd*`
- **touches_scenes**: `godot/entities/player/player.tscn` (solo `%InteractionDetector.actor = %InteractionComponent`)
- **Change**: ADR-003 §11.1–§11.4: tipos, `ActionRules` con la tabla completa (§11.6, fixture CSV
  transcrito de `lenguaje-acciones.md` A–F), `HeldKind`, detector (filtro, sin control, hint de suelo,
  histéresis, `hint_changed`, `set_blocked`), `InteractionComponent` (respuesta, suelo, mantener, bus),
  `HoldComponent.get_drop_position()`, `Highlightable.set_blocked()` + `@export var blocked_material`,
  `InteractionContract.HINT_METHOD` (sin hacerlo obligatorio), señales en `event_bus.gd`. Equivalencia
  transitoria para entidades sin `get_action_hint`. Los dos tests de nivel solo se ajustan a la
  histéresis y al filtro de control.
- **Acceptance**:
  - [ ] AC1 Given el CSV de la tabla A–F (≥ 250 filas), When `test_action_rules.gd` evalúa `ActionRules`, Then 0 discrepancias de verbo, estado y motivo → `test_action_rules.gd`
  - [ ] AC2 Given `ActionHint`, Then se cumplen las invariantes y `same_as` ignora `progress` y compara `replaces`; `ALL` sin duplicados ni vacíos → `test_action_hint.gd`
  - [ ] AC3 Histéresis (diseño AC9): actual con s y candidato con 1,19·s → sigue el actual; 1,21·s → cambia; actual inválido → cambia; margen 0 = comportamiento previo; OK ↔ BLOQUEADO no invalida → `test_interaction_scoring.gd`
  - [ ] AC4 (diseño AC10, AC20) Detector: un candidato `NONE` no se resalta ni publica; puntuaciones que oscilan ±10 % durante 5 s → 0 cambios; `hint_changed` solo al cambiar objetivo/verbo/estado/motivo/`replaces`; sin control, `null` sin contorno; mano llena sin candidatos → `drop` OK o `busy` según `can_drop_freely` → `test_interaction_detector.gd`
  - [ ] AC5 (diseño AC2, AC11) `interact_pressed`: `NONE` → nada; con objetivo → 1 `interaction_resolved` local y 1 de bus con primitivos; suelo libre → suelta + OK; suelo bloqueado → `BLOCKED` `busy` y la mano no cambia; sin control no emite; cambio de personaje: `NONE` del saliente antes que el hint del entrante → `test_interaction_component.gd`
  - [ ] AC6 (diseño AC13, parte de núcleo) Mantener con `cut` OK repite cada 0,2 s de juego (1,05 s → 6 pulsaciones), para sin emitir al pasar a `BLOCKED` o cambiar de objetivo, no repite otros verbos y se congela en pausa → `test_hold_repeat.gd`, `test_interaction_component.gd`
  - [ ] AC7 `EventBus` declara `action_hint_changed` e `interaction_resolved` con 4 argumentos; `hysteresis_margin` = 0,2 y `cut_repeat_interval` = 0,2 en los `.tres` → `test_event_bus.gd`, `test_player_input.gd`
  - [ ] AC8 Sin entidades migradas, el juego se comporta como antes (flujos y `test_level_01_r16` en verde)

### PUL-122 — Escala de UI, safe area, perfil de plataforma y menús móviles
- **role**: ui-engineer · **oleada** 1 · **deps**: PUL-119, PUL-120
- **owns**: `godot/project.godot`, `godot/core/platform_profile.gd*`, `godot/autoload/game_state.gd*`,
  `godot/resources/ui_profile.gd*`, `godot/data/config/ui_profile_desktop.tres`,
  `godot/data/config/ui_profile_mobile.tres`, `godot/ui/widgets/ui_scale.gd*`,
  `godot/ui/widgets/safe_area_margin.gd*`, `godot/ui/theme/**`, `godot/ui/menus/**`,
  `godot/ui/hud/hud.gd*`, `godot/ui/tickets/order_tickets_panel.gd*`,
  `godot/tests/unit/test_platform_profile.gd*`, `godot/tests/unit/test_ui_scale_math.gd*`,
  `godot/tests/unit/test_game_state.gd*`, `godot/tests/unit/test_project_settings.gd*`,
  `godot/tests/integration/test_main_menu.gd*`, `godot/tests/integration/test_main_menu_touch.gd*`,
  `godot/tests/integration/test_touch_menus.gd*`, `godot/tests/integration/test_pause_menu.gd*`,
  `godot/tests/integration/test_game_over.gd*`, `godot/tests/integration/test_ui_gamepad.gd*`,
  `godot/tests/integration/test_ui_scale.gd*`, `godot/tests/integration/test_app_lifecycle.gd*`,
  `godot/tests/integration/test_hud.gd*`, `godot/tests/integration/test_order_tickets.gd*`,
  `docs/evidence/PUL-122/**`
- **touches_scenes**: `godot/ui/menus/main_menu.tscn`, `godot/ui/menus/pause_menu.tscn`,
  `godot/ui/menus/game_over.tscn`, `godot/ui/menus/menu_panel.tscn`, `godot/ui/menus/sandbox/**`
- **Change**: ADR-005 E1–E4 (sin la disposición de HUD y tickets, que es de PUL-129: aquí solo se quita
  la línea de `UiScale.factor`), ADR-004 §6.5, ADR-002 Enmienda 2.2. Tema con mínimos de texto móviles;
  menús con botones ≥ 120 px en `MOBILE`; «Reiniciar» en la pausa si la feature lo mantiene.
- **Acceptance**:
  - [ ] AC1 `PlatformProfile.detect`: `--touch` o `--profile=mobile` → `MOBILE`; `--profile=desktop` → `DESKTOP`; features `mobile`/`web_android`/`web_ios` → `MOBILE`; resto → `DESKTOP` → `test_platform_profile.gd`
  - [ ] AC2 `project.godot`: `stretch/mode` `canvas_items`, `aspect` `expand`, `handheld/orientation` 4 → `test_project_settings.gd`
  - [ ] AC3 `UiScale`: 72 dp = 180 px de pantalla a 1080 con cualquier lienzo; `px_to_units`; `safe_margins` con 132 / 0 / 132 / 63 y con safe area nula → `test_ui_scale_math.gd`
  - [ ] AC4 (diseño AC1) Con `--touch`, el menú solo muestra «Individual» con foco y carga el nivel en `SINGLE`; en escritorio siguen los 3 botones → `test_main_menu_touch.gd`
  - [ ] AC5 (diseño AC14) Perfil móvil a 2340×1080: ningún texto de menú, pausa o game over < 36 px; a 1600×720 < 24 px → `test_ui_scale.gd`
  - [ ] AC6 (diseño AC18) Botones de menú, pausa y game over ≥ 120 px de alto y ≥ 24 px de separación en `MOBILE`; reanudar ≤ 0,1 s → `test_touch_menus.gd`
  - [ ] AC7 (diseño AC19) Perder el foco o Atrás en ronda pausan en ≤ 1 frame y no se reanuda sola; solo en `MOBILE` → `test_app_lifecycle.gd`
  - [ ] AC8 (diseño AC21) En escritorio, HUD y tickets conservan su tamaño a 1280×720 y 1920×1080 (sin doble escala) → `test_hud.gd`, `test_order_tickets.gd`; capturas de menús a 1280×720, 1920×1080 y 2340×1080 `--touch`

### PUL-123 — Iconos de verbos, motivos y marcas; aliño picante propio; rack y caja sin S/M/L
- **role**: asset-pipeline · **oleada** 1 · **deps**: PUL-119, PUL-120
- **owns**: `godot/assets/textures/ui/actions/**`, `godot/resources/action_icon_set.gd*`,
  `godot/data/config/action_icons.tres`, `art/blender/box_shelf.blend`,
  `godot/assets/models/stations/box_shelf/**`, `art/blender/box.blend`,
  `godot/assets/models/items/box/**`, `godot/assets/textures/ui/box_sizes/**` (baja),
  `godot/tests/unit/test_icons_silhouettes.gd*`, `godot/tests/unit/test_action_icon_set.gd*`,
  `docs/evidence/PUL-123/**`
- **touches_scenes**: ninguna (los `.glb` cambian contenido, no las escenas que los instancian)
- **Change**: SVG propios, monocromos, 128×128, trazo ≥ 8 % del lado, según «Iconografía» de
  `lenguaje-acciones.md`: `icon_verb_<id>.svg` × 8 (ids del contrato), `icon_reason_<id>.svg` × 6
  (`box_not_full`, `busy`, `empty`, `full`, `already_applied`, `not_cooked`), `icon_mark_<nombre>.svg`
  (`cross`, `replace`, `ready`, `burn_warning`, `active`, `offscreen`, `player_1`, `player_2`, `plate`
  si la placa es textura). `ActionIconSet` (ADR-003 §11.5) y `action_icons.tres` con las claves
  literales del contrato y los valores del diseño. Rack y textura de señales de la caja sin letras
  S/M/L (pipeline de PUL-043). Sin créditos externos.
- **Acceptance**:
  - [ ] AC1 (diseño AC4) Los 8 verbos a 64 px y los 6 motivos a 32 px, en gris y binarizados al 50 %: IoU de cualquier par ≤ 0,6; dulce y picante incluidos → `test_icons_silhouettes.gd`
  - [ ] AC2 `action_icons.tres` tiene exactamente las claves de verbos y motivos del contrato, todas con textura que importa, y los valores del diseño (64/80/48/32/24 px, 0,9 m, 0,35 s, 6 px, colores) → `test_action_icon_set.gd`
  - [ ] AC3 (diseño AC19, parte de arte) `box_shelf.glb` y `box.glb` sin S, M ni L → capturas en `docs/evidence/PUL-123/` y hoja de contacto de iconos a 64 px en gris

### PUL-124 — Cues de D26
- **role**: asset-pipeline · **oleada** 1 · **deps**: PUL-119, PUL-120
- **owns**: `godot/assets/audio/sfx/**`, `godot/data/audio/feedback_map.tres`, `godot/assets/CREDITS.md`,
  `godot/tests/unit/test_assets_audio_ui.gd*`, `godot/tests/unit/test_feedback_distinct.gd*`,
  `godot/tests/integration/test_audio_feedback.gd*` (solo la lista de claves cerradas),
  `docs/evidence/PUL-124/**`
- **touches_scenes**: ninguna
- **Change**: claves nuevas `cook_ready`, `box_full`, `switch`, `rejected` y sample propio para
  `trash`, `discard` y `burn_warning` (ADR-006 §4.1). **Sin quitar** `cook_done`, `season_error` ni
  `deliver_error` (las retira PUL-131). `rejected` con `SHAKE` de ±6 px y `visual_time` 0,35.
- **Acceptance**:
  - [ ] AC1 (diseño AC8) Los streams de `trash`, `discard`, `cook_ready`, `burn_warning`, `box_full`, `switch` y `rejected` son 7 distintos entre sí y de `pick_up`, `drop`, `cook_start`, `cut`, `season`; todos con `visual_time ≥ 0,3` salvo visual `NONE` → `test_feedback_distinct.gd`
  - [ ] AC2 Licencias en `CREDITS.md` si hay samples externos → `test_assets_audio_ui.gd`
  - [ ] AC3 `test_audio_feedback.gd` con las 4 claves nuevas en `CUES`, en verde

### PUL-125 — Verbo en cocina y objetos; anillo de cocción, contador de corte y aviso de quemado
- **role**: gameplay-engineer · **oleada** 2 · **deps**: PUL-121, PUL-124 (y PUL-123 para `icon_mark_ready`/`burn_warning`)
- **owns**: `godot/entities/items/box.gd*`, `godot/entities/items/ingredient.gd*`,
  `godot/entities/stations/cooking_station.gd*`, `godot/entities/stations/slot.gd*`,
  `godot/entities/stations/item_spawner.gd*`, `godot/entities/stations/trash_bin.gd*`,
  `godot/resources/kitchen_data.gd*`, `godot/data/config/kitchen.tres`,
  `godot/ui/widgets/world_progress_bar.gd*`, `godot/ui/widgets/world_progress_ring.gd*`,
  `godot/tests/integration/test_box.gd*`, `test_box_on_slot.gd*`, `test_box_model.gd*`,
  `test_box_counter.gd*`, `test_box_cut_hold.gd*`, `test_burn.gd*`, `test_cooking_station.gd*`,
  `test_cook_ring.gd*`, `test_item_spawner.gd*`, `test_slot.gd*`, `test_trash_bin.gd*`,
  `test_octopus.gd*`, `test_shelves.gd*`, `test_hold_component.gd*`, `test_audio_feedback.gd*`,
  `test_kitchen_hints.gd*`, `test_kitchen_flow.gd*`, `test_m1_flow.gd*`, `test_m2_flow.gd*`,
  `test_parity_smoke.gd*`, `test_delivery_e2e.gd*`, `test_level_01.gd*`, `test_level_01_r16.gd*`,
  `level_walker.gd*` (todos en `godot/tests/integration/`), `docs/evidence/PUL-125/**`
- **touches_scenes**: `godot/entities/items/box.tscn`, `godot/entities/stations/kitchen.tscn`,
  `godot/ui/widgets/world_progress_bar.tscn`, `godot/ui/widgets/world_progress_ring.tscn` (nueva)
- **Change**: `get_action_hint` + `_resolve` sobre `ActionRules` en caja, pulpo/cachelos, olla,
  pasaplatos, spawners y cubo (§11.2, filas A1–A6, B, C); `can_interact` honesto; `%CutCounter` y
  `get_presses()`; `%CookRing` por plaza; aviso de quemado con repetición; cues `cook_ready` (en lugar
  de `cook_done`) y `box_full`; barras ≥ 8 px. **No** quita `Box.toggle_seasoning()` (PUL-131).
- **Acceptance**:
  - [ ] AC1 (diseño AC2) Para cada fila A1–A6, B y C: el hint publicado coincide con el efecto de `interact` (OK cambia el mundo, BLOQUEADO no, `—` no es objetivo) y `interact` devuelve `true` si el hint no es `NONE` → `test_kitchen_hints.gd`
  - [ ] AC2 (diseño AC13) 1,05 s mantenido con pulpo cocido (100 u) y caja vacía → 6 cortes y 50 u, sin rechazo; soltar y pulsar sobre la llena → 1 rechazo `full`; toque < 0,2 s → 1 corte → `test_box_cut_hold.gd`
  - [ ] AC3 (diseño AC14) Con k = 1…5 cortes se ve `k/6`, numeral ≥ 36 px y barra ≥ 8 px a 1080; k = 0 no se ve; en k = 6 muestra `6/6` 0,5 s, suena `box_full` 1 vez y se oculta → `test_box_counter.gd` + captura
  - [ ] AC4 (diseño AC15) Anillo ≥ 64 px y trazo ≥ 8 px a 1080; listo verde con ✓ y `cook_ready` 1 vez → `test_cook_ring.gd` + captura
  - [ ] AC5 (diseño AC16) Aviso a los 7,0 s (±0,1): parpadeo 3 Hz (±0,5) y `burn_warning` repetido cada 1 s hasta 3 veces; retirar a los 8 s lo para; a los 10 s rojo fijo → `test_burn.gd`
  - [ ] AC6 Flujos (`test_kitchen_flow`, `test_m1_flow`, `test_m2_flow`, `test_parity_smoke`, `test_delivery_e2e`, `test_level_01*`) y `test_audio_feedback` en verde con el `can_interact` honesto

### PUL-126 — Verbo en la estación de condimentos y cuenco que solo pone
- **role**: gameplay-engineer · **oleada** 2 · **deps**: PUL-121, PUL-123 · merge después de PUL-125
- **owns**: `godot/entities/stations/seasoning_dispenser.gd*`, `godot/entities/stations/cachelos_bowl.gd*`,
  `godot/resources/seasoning_data.gd*`, `godot/resources/seasoning_station_data.gd*`,
  `godot/data/seasonings/**`, `godot/data/config/seasoning_station.tres`,
  `godot/tests/integration/test_seasoning_station.gd*`, `godot/tests/integration/test_cachelos.gd*`,
  `godot/tests/integration/test_cachelos_bowl_view.gd*`, `godot/tests/integration/test_m2b_flow.gd*`,
  `godot/tests/integration/test_station_level.gd*`, `godot/tests/integration/test_m2b_station_selection.gd*`,
  `godot/tests/integration/test_station_hints.gd*`, `godot/tests/integration/test_box_badges.gd*`,
  `godot/tests/unit/test_data_integrity.gd*`, `godot/tests/unit/test_data_catalog.gd*`,
  `docs/evidence/PUL-126/**`
- **touches_scenes**: `godot/entities/stations/cachelos_bowl.tscn`,
  `godot/entities/stations/seasoning_dispenser.tscn`
- **Change**: §11.2 en dispensadores y cuenco (filas D y E; verbo de `SeasoningData.verb`;
  `replaces`; `ALREADY_APPLIED` con `rejected` y sin silencio); cuenco solo pone con
  `apply_seasoning`, reponer con `stock + 2 ≤ 4`, cualquier caja desde el lado de aliñar, sin toggle
  ni antirrebote, `%StockMeter`; baja de `toggle_guard`; `verb` e `icon` en los 3 `SeasoningData`
  (pimentonera / guindilla). **No** toca `seasoning_station.gd` ni el puesto.
- **Acceptance**:
  - [ ] AC1 (diseño AC2) Filas D y E: hint = efecto; desde el lado de pase dispensadores y cuenco-con-caja no son candidatos → `test_station_hints.gd`
  - [ ] AC2 Cuenco: pone (stock −1); ya lleva → `B:already_applied` sin cambios (también con stock 0); stock 0 → `B:empty`; caja a medias → `B:box_not_full`; reponer con stock 3 → `B:full`; no hay quitar → `test_cachelos.gd`
  - [ ] AC3 Dispensador: mismo aliño → `rejected(ALREADY_APPLIED)`; el otro → sustituye con `replaces` en el hint → `test_seasoning_station.gd`
  - [ ] AC4 (diseño AC17) Con stock 2 se ven 4 muescas, 2 llenas, contraste ≥ 3:1, ≥ 24 px a 1080; con 0 y 4, 0 y 4 llenas → `test_cachelos_bowl_view.gd` + captura
  - [ ] AC5 Datos: `verb` válido en los 3 `SeasoningData`; `hot_dressing` con `icon_verb_season_hot` y `sweet_dressing` con `icon_verb_season_sweet`; sin `toggle_guard` → `test_data_integrity.gd`, `test_box_badges.gd`; `test_m2b_flow` y `test_station_level` en verde

### PUL-127 — Prompt de acción en el mundo, respuesta del jugador, aro activo y contorno
- **role**: gameplay-engineer · **oleada** 2 · **deps**: PUL-121, PUL-123, PUL-124
- **owns**: `godot/components/action_prompt.gd*`, `godot/entities/player/player.gd*`,
  `godot/shaders/**`, `godot/tests/integration/test_action_prompt.gd*`,
  `godot/tests/integration/test_player.gd*`, `godot/tests/integration/test_player_ring.gd*`,
  `godot/tests/integration/test_player_feedback.gd*`, `docs/evidence/PUL-127/**`
- **touches_scenes**: `godot/entities/player/player.tscn`, `godot/entities/player/action_prompt.tscn` (nueva)
- **Change**: ADR-003 §11.5 y §11.8 (aro, `%ActiveMarker`, contorno `#FFF4D6` / ámbar visible a través
  del personaje); rechazo en el `%Feedback` del jugador (`rejected`) y cue `switch` (ADR-006 §4.1).
- **Acceptance**:
  - [ ] AC1 (diseño AC3, AC5) A 1920×1080 icono ≥ 64 px, placa ≥ 80 px, contraste ≥ 4,5:1; a 1280×720 icono ≥ 48 px; OK blanco sin aspa, BLOQUEADO ámbar + aspa + motivo; visible solo con OK/BLOQUEADO y personaje controlado; sobre el punto de soltar con el hint de suelo → `test_action_prompt.gd` + captura
  - [ ] AC2 (diseño AC6, AC7) Éxito: sube 12 px y escala 1,25 en 0,35 s; rechazo: parpadeo y sacudida ±6 px ≥ 0,3 s y exactamente 1 `rejected`; dos pulsaciones a 0,1 s → 2 cues y 2 respuestas → `test_action_prompt.gd`, `test_player_feedback.gd`
  - [ ] AC3 (diseño AC21) Local 2P en el mismo objetivo: 2 prompts con marcador, separados ≥ 8 px → `test_action_prompt.gd`
  - [ ] AC4 (diseño AC12) Con una caja en la mano apuntando al cubo desde el sur, prompt entero visible y ≥ 25 % del contorno visible tras el personaje → captura a 1920×1080
  - [ ] AC5 (diseño AC18) Aro activo sólido ≥ 8 px + ▼ ≥ 24 px; inactivo discontinuo ≤ 3 px sin ▼; contraste en gris ≥ 3:1; `switch` 1 vez al cambiar en ronda y no al arrancar → `test_player_ring.gd`, `test_player_feedback.gd` + captura

### PUL-128 — Controles táctiles
- **role**: ui-engineer · **oleada** 2 · **deps**: PUL-121, PUL-122, PUL-123
- **owns**: `godot/ui/touch/**`, `godot/core/touch_input.gd*`, `godot/resources/touch_config.gd*`,
  `godot/data/config/touch_config.tres`, `godot/tests/unit/test_touch_input_rules.gd*`,
  `godot/tests/integration/test_touch_input.gd*`, `godot/tests/integration/test_virtual_stick.gd*`,
  `godot/tests/integration/test_touch_multitouch.gd*`, `godot/tests/integration/test_action_button.gd*`,
  `godot/tests/integration/test_touch_layout.gd*`, `docs/evidence/PUL-128/**`
- **touches_scenes**: `godot/ui/touch/touch_controls.tscn` (nueva) y su sandbox en `godot/ui/touch/sandbox/`
- **Change**: ADR-004 §6.1–§6.4 con las medidas de `controles-tactiles.md`.
- **Acceptance**:
  - [ ] AC1 `TouchInput`: `source_of` por tipo (ratón e `InputEventAction` no cambian la fuente); `controls_visible` solo `MOBILE` + `SINGLE` + última fuente ≠ mando; `stick_vector` y `follow_center` → `test_touch_input_rules.gd`
  - [ ] AC2 (diseño AC2, AC3) A 2340×1080 con safe area 132/0/132/63: acción 180 ± 2 px, zona ≥ 204 px, centro (2070, 879) ± 2; a 1920×1080 centro (1782, 942) ± 2; cambiar 120 px a 24 px sobre la acción; pausa 120 px en (2100, 108) ± 2; sin solapes → `test_touch_layout.gd` + capturas
  - [ ] AC3 (diseño AC4) Stick: base en el toque; 75 px → 0,50 ± 0,02; 20 px → 0; ≥ 150 px → 1,0; a 400 px la base sigue; levantar → 0 en ≤ 1 frame y fundido 0,15 s; toque en (140, 1000) → centro (282, 867); fuera de zona o sobre botón → sin stick → `test_virtual_stick.gd`
  - [ ] AC4 (diseño AC5) 3 contactos simultáneos sin interferencias; un dedo del stick sobre el botón no lo pulsa; un dedo que sale del botón no lo cancela → `test_touch_multitouch.gd`
  - [ ] AC5 (diseño AC6, AC7, AC20) Mismas acciones que el mando de J1 (5 ± 0,1 m/s con magnitud 1); interactuar en el mismo frame; un evento de mando oculta los controles en ≤ 1 frame y un toque los muestra; el teclado no los oculta; en `DESKTOP` no existen → `test_touch_input.gd`
  - [ ] AC6 (diseño AC8, AC9) Los 6 casos de botón (gris + COGER al 40 %; COGER; CORTAR; ALIÑAR PICANTE; ámbar + caja a medias; SOLTAR) con el mismo icono que el prompt, actualizado en ≤ 0,1 s; mantener con CORTAR → 6 cortes en 1,05 s; con COGER, 1 acción → `test_action_button.gd`

### PUL-129 — HUD y tickets para móvil
- **role**: ui-engineer · **oleada** 2 · **deps**: PUL-122, PUL-123
- **owns**: `godot/ui/hud/**`, `godot/ui/tickets/**`, `godot/ui/sandbox/**`,
  `godot/tests/integration/test_hud.gd*`, `godot/tests/integration/test_order_tickets.gd*`,
  `godot/tests/integration/test_touch_hud_layout.gd*`, `docs/evidence/PUL-129/**`
- **touches_scenes**: `godot/ui/hud/hud.tscn`, `godot/ui/tickets/order_tickets_panel.tscn`,
  `godot/ui/tickets/order_ticket.tscn`, `godot/ui/tickets/ticket_entry.tscn`,
  `godot/ui/sandbox/hud_sandbox.tscn`
- **Change**: ADR-005 E3–E4 en HUD y tickets: `SafeAreaMargin`, banda superior en `MOBILE` con la
  maquetación del diseño, zonas reservadas, sin «Cajas / minuto» (D26.7), icono del aliño =
  `SeasoningData.icon`, textos ≥ 36 px a 1080 en móvil; escritorio sin cambios.
- **Acceptance**:
  - [ ] AC1 (diseño AC15) 4 comandas (una «Bravo cachelos») a 2340×1080 con safe area y a 1920×1080: sin «…», tickets de 330–380 px, 16 ± 1 px entre ellos, ≥ 24 px de hueco a HUD y pausa, banda ≤ 200 px → `test_touch_hud_layout.gd` + captura
  - [ ] AC2 (diseño AC16, AC17) Ningún rectángulo de HUD o ticket en la zona del stick ni en la de botones; nada en los márgenes del safe area; con safe area nula, anclado con 48 px → `test_touch_hud_layout.gd`
  - [ ] AC3 (diseño AC14, AC19) Textos de HUD y tickets ≥ 36 px a 2340×1080 y ≥ 24 px a 1600×720 en móvil; ningún texto ni clave contiene «Cajas / minuto» → `test_hud.gd`
  - [ ] AC4 (diseño AC21) Escritorio a 1280×720: disposición y tamaño actuales → `test_hud.gd`, `test_order_tickets.gd`

### PUL-130 — Cámara con perfiles, seguimiento móvil y flecha de borde
- **role**: gameplay-engineer · **oleada** 2 · **deps**: PUL-122, PUL-123
- **owns**: `godot/entities/camera/camera_rig.gd*`, `godot/resources/camera_profile.gd*`,
  `godot/core/camera_follow.gd*`, `godot/data/config/camera_desktop.tres`,
  `godot/data/config/camera_mobile.tres`, `godot/tests/unit/test_camera_follow_math.gd*`,
  `godot/tests/integration/test_camera_profile.gd*`, `godot/tests/integration/test_camera_follow.gd*`,
  `docs/evidence/PUL-130/**`
- **touches_scenes**: `godot/entities/camera/camera_rig.tscn`
- **Change**: ADR-005 E5.
- **Acceptance**:
  - [ ] AC1 `CameraFollow`: amortiguación crítica sin cruzar el objetivo; paneo ease-out; `clamp_focus` con vista mayor y menor que el área → `test_camera_follow_math.gd`
  - [ ] AC2 (diseño AC10) Perfil móvil a 2340×1080 y 1920×1080: personaje de 1,6 m ≥ 192 px; escritorio 107 ± 2 px y transformación sin cambios → `test_camera_profile.gd`
  - [ ] AC3 (diseño AC11) Corriendo 5 m/s 2 s: siempre en el 60 % central del alto y 80 % del ancho; parado, desfase ≤ 0,1 m a 0,6 s → `test_camera_follow.gd`
  - [ ] AC4 (diseño AC12) Personajes a > 8 m: llega al nuevo activo en 0,35 ± 0,05 s ease-out; el control pasa en < 0,2 s; flecha de borde ≥ 48 px dentro del safe area y a ≥ 16 px de la zona de botones → `test_camera_follow.gd` + captura
  - [ ] AC5 (diseño AC13) En cada esquina de la planta la vista no sale más de 1,0 m del área jugable; sin `characters` no falla → `test_camera_follow.gd` + capturas

### PUL-131 — Entrega solo por zona, montaje D26 en `level_01` y limpieza de contrato
- **role**: gameplay-engineer · **oleada** 3 · **deps**: PUL-121…PUL-130
- **owns**: `godot/entities/stations/order_stand.gd*`, `godot/entities/stations/seasoning_station.gd*`,
  `godot/scenes/levels/level_01.tscn`, `godot/components/interaction_contract.gd*`,
  `godot/data/audio/feedback_map.tres`, `godot/data/config/round_config.tres`,
  `godot/entities/items/box.gd*`, `godot/core/seasoning_rules.gd*`,
  `godot/tests/fixtures/action_matrix.csv`, `godot/tests/integration/test_action_matrix.gd*`,
  `godot/tests/integration/test_order_stand.gd*`, `test_delivery_e2e.gd*`, `test_kitchen_flow.gd*`,
  `test_m1_flow.gd*`, `test_m2_flow.gd*`, `test_m2b_flow.gd*`, `test_station_level.gd*`,
  `test_parity_smoke.gd*`, `test_level_01.gd*`, `test_level_01_r16.gd*`, `level_walker.gd*`,
  `test_items_contract.gd*`, `test_stations_contract.gd*`, `test_audio_feedback.gd*`,
  `test_seasoning_station.gd*` (en `godot/tests/integration/`), `godot/tests/unit/test_seasoning_rules.gd*`,
  `godot/tests/unit/test_interaction_contract.gd*`, `godot/tests/unit/test_round_state.gd*`,
  `godot/tests/helpers/m0_data/**`, `docs/evidence/PUL-131/**`
- **touches_scenes**: `godot/entities/stations/order_stand.tscn`,
  `godot/entities/stations/seasoning_station.tscn`, `godot/scenes/levels/level_01.tscn` y los
  `sandbox/*.tscn` que dejen de cargar por las bajas (el producer los lista al abrir la ficha)
- **Change**: ADR-003 §11.7 del puesto; `seasoning_station.gd` y `order_stand.gd` sin `season_error` /
  `deliver_error`; `wrong_delivery_penalty` = 0; `TouchControls` en `UI` y `CameraRig.characters` en el
  nivel (`scene-tree.md` §2); `get_action_hint` obligatorio; bajas `cook_done`, `season_error`,
  `deliver_error` del mapa, `SeasoningRules.toggle()` y `Box.toggle_seasoning()` (`scene-tree.md`
  §7.3); test de matriz sobre escenas reales.
- **Acceptance**:
  - [ ] AC1 (diseño AC1, AC2, AC11, AC20) `test_action_matrix.gd` recorre las ≥ 250 filas del CSV con las escenas reales y el detector real: 0 discrepancias; OK cambia el mundo con 1 señal de éxito, BLOQUEADO no cambia nada con 1 rechazo, `—` sin respuesta ni contorno; suelo libre y bloqueado
  - [ ] AC2 Puesto: fuera de `interactable` y de su capa; el detector no lo elige desde ningún punto de la zona; entrega al entrar y a quien ya estaba dentro cuando sale la comanda; caja errónea: nada, sin `delivery_rejected`; `wrong_delivery_penalty` = 0 → `test_order_stand.gd`, `test_delivery_e2e.gd`
  - [ ] AC3 Contrato: todo `interactable` de `entities/` implementa `get_action_hint` y ninguno usa la equivalencia sin verbo → `test_items_contract.gd`, `test_stations_contract.gd`
  - [ ] AC4 `level_01`: `TouchControls` presente y en orden en `UI`; `CameraRig.characters` = [Player1, Player2]; regla de colocación de los cubos sin cambios → `test_level_01.gd`
  - [ ] AC5 Mapa sin `cook_done`, `season_error` ni `deliver_error`; sin `SeasoningRules.toggle` ni `Box.toggle_seasoning`; flujos en verde entregando por zona → `test_audio_feedback.gd`, `test_seasoning_rules.gd`, flujos

### PUL-132 — QA de D26
- **role**: qa-tester · **oleada** 4 · **deps**: PUL-131
- **owns**: `docs/evidence/PUL-132/**`, `godot/tests/integration/test_d26_no_mute_press.gd*`,
  `godot/tests/integration/test_d26_touch_flow.gd*`
- **touches_scenes**: ninguna
- **Change**: verificación de D26 en `level_01` contra `lenguaje-acciones.md` y
  `controles-tactiles.md`; guía de playtest para el responsable.
- **Acceptance**:
  - [ ] AC1 Con `level_walker` y teclado real, cada tipo de objetivo con cada clase de mano de la tabla (≥ 40 recorridos): el `action_hint_changed` previo coincide con la tabla y cada pulsación da exactamente 1 `interaction_resolved` y 1 cue de respuesta, o ninguna con la mano vacía sin objetivo → `test_d26_no_mute_press.gd`
  - [ ] AC2 Partida corta con `--touch` solo con eventos táctiles inyectados: coger, cocer, cortar manteniendo, aliñar, cachelos, cambiar, pausar y entregar por zona → `test_d26_touch_flow.gd`
  - [ ] AC3 Capturas a 1280×720, 1920×1080, 2340×1080 `--touch` (safe area simulada) y 800×370; hoja de verbos a 64 px en gris; informe con los AC del diseño que se verifican por captura (AC3, AC12, AC14, AC15, AC17, AC18 de `lenguaje-acciones`; AC2, AC3, AC8, AC15, AC17 de `controles-tactiles`)
