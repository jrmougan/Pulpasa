---
id: PUL-121
title: Núcleo del lenguaje de acciones, histéresis y bus
status: review
milestone: M3e
role: gameplay-engineer
deps: [PUL-119, PUL-120]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_m2b_flow.gd, godot/tests/integration/test_station_level.gd, godot/tests/integration/test_trash_bin.gd, godot/tests/fixtures/.gdignore, godot/tests/fixtures/action_matrix.csv.import, godot/core/action_verb.gd*, godot/core/action_reason.gd*, godot/core/action_hint.gd*, godot/core/action_rules.gd*, godot/core/hold_repeat.gd*, godot/core/interaction_scoring.gd*, godot/core/player_input.gd*, godot/components/interaction_component.gd*, godot/components/interaction_detector.gd*, godot/components/interaction_contract.gd*, godot/components/highlightable.gd*, godot/components/hold_component.gd*, godot/entities/items/held_kind.gd*, godot/resources/player_config.gd*, godot/resources/input_config.gd*, godot/data/config/player_config.tres, godot/data/config/input_config.tres, godot/autoload/event_bus.gd*, godot/tests/fixtures/action_matrix.csv, godot/tests/unit/test_action_hint.gd*, godot/tests/unit/test_action_rules.gd*, godot/tests/unit/test_hold_repeat.gd*, godot/tests/unit/test_interaction_scoring.gd*, godot/tests/unit/test_interaction_component.gd*, godot/tests/unit/test_event_bus.gd*, godot/tests/unit/test_player_input.gd*, godot/tests/unit/test_interaction_contract.gd*, godot/tests/integration/test_interaction_detector.gd*, godot/tests/integration/test_held_kind.gd*, godot/tests/integration/test_highlightable.gd*, godot/tests/integration/test_hold_component.gd*, godot/tests/integration/test_m2b_station_selection.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/helpers/fake_*.gd*, docs/backlog/PUL-121-nucleo-del-lenguaje-de-acciones-histeresis-y-bus.md]
touches_scenes: [godot/entities/player/player.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 1. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/player/player.tscn` (solo `%InteractionDetector.actor = %InteractionComponent`)

## Change
ADR-003 §11.1–§11.4: tipos, `ActionRules` con la tabla completa (§11.6, fixture CSV
  transcrito de `lenguaje-acciones.md` A–F), `HeldKind`, detector (filtro, sin control, hint de suelo,
  histéresis, `hint_changed`, `set_blocked`), `InteractionComponent` (respuesta, suelo, mantener, bus),
  `HoldComponent.get_drop_position()`, `Highlightable.set_blocked()` + `@export var blocked_material`,
  `InteractionContract.HINT_METHOD` (sin hacerlo obligatorio), señales en `event_bus.gd`. Equivalencia
  transitoria para entidades sin `get_action_hint`. Los dos tests de nivel solo se ajustan a la
  histéresis y al filtro de control.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 Given el CSV de la tabla A–F (≥ 250 filas), When `test_action_rules.gd` evalúa `ActionRules`, Then 0 discrepancias de verbo, estado y motivo → `test_action_rules.gd`
- [x] AC2 Given `ActionHint`, Then se cumplen las invariantes y `same_as` ignora `progress` y compara `replaces`; `ALL` sin duplicados ni vacíos → `test_action_hint.gd`
- [x] AC3 Histéresis (diseño AC9): actual con s y candidato con 1,19·s → sigue el actual; 1,21·s → cambia; actual inválido → cambia; margen 0 = comportamiento previo; OK ↔ BLOQUEADO no invalida → `test_interaction_scoring.gd` (y `test_interaction_detector.gd` para OK ↔ BLOQUEADO)
- [x] AC4 (diseño AC10, AC20) Detector: un candidato `NONE` no se resalta ni publica; puntuaciones que oscilan ±10 % durante 5 s → 0 cambios; `hint_changed` solo al cambiar objetivo/verbo/estado/motivo/`replaces`; sin control, `null` sin contorno; mano llena sin candidatos → `drop` OK o `busy` según `can_drop_freely` → `test_interaction_detector.gd`
- [x] AC5 (diseño AC2, AC11) `interact_pressed`: `NONE` → nada; con objetivo → 1 `interaction_resolved` local y 1 de bus con primitivos; suelo libre → suelta + OK; suelo bloqueado → `BLOCKED` `busy` y la mano no cambia; sin control no emite; cambio de personaje: `NONE` del saliente antes que el hint del entrante → `test_interaction_component.gd`
- [x] AC6 (diseño AC13, parte de núcleo) Mantener con `cut` OK repite cada 0,2 s de juego (1,05 s → 6 pulsaciones), para sin emitir al pasar a `BLOCKED` o cambiar de objetivo, no repite otros verbos y se congela en pausa → `test_hold_repeat.gd`, `test_interaction_component.gd`
- [x] AC7 `EventBus` declara `action_hint_changed` e `interaction_resolved` con 4 argumentos; `hysteresis_margin` = 0,2 y `cut_repeat_interval` = 0,2 en los `.tres` → `test_event_bus.gd`, `test_player_input.gd`
- [x] AC8 Sin entidades migradas, el juego se comporta como antes (flujos y `test_level_01_r16` en verde)

## Plan
Ficheros (todos en `owns`):
- `core/`: `action_verb.gd`, `action_reason.gd`, `action_hint.gd`, `action_rules.gd` (tabla §11.6: `for_*` puras), `hold_repeat.gd`; `interaction_scoring.gd` (histéresis: `current`, `hysteresis_margin`); `player_input.gd` (`is_interact_pressed`).
- `entities/items/held_kind.gd` (única traducción mano → `ActionRules.Held`).
- `components/`: `interaction_contract.gd` (`HINT_METHOD`, `hint_of` con la equivalencia transitoria `ok(&"")` si `can_interact`), `interaction_detector.gd` (`actor`, filtro por hint, sin control → `null`, hint de suelo, histéresis, `hint_changed`/`get_hint()`, ámbar), `interaction_component.gd` (respuesta única, suelo, bus, `HoldRepeat`), `highlightable.gd` (`set_blocked`, `blocked_material`), `hold_component.gd` (`get_drop_position`).
- Datos: `resources/player_config.gd` + `player_config.tres` (`hysteresis_margin` 0,2), `resources/input_config.gd` + `input_config.tres` (`cut_repeat_interval` 0,2). `autoload/event_bus.gd`: `action_hint_changed` e `interaction_resolved`.
- Escena: `player.tscn` solo `InteractionDetector.actor = ../InteractionComponent`.
Señales: bus `action_hint_changed` / `interaction_resolved` (emisor `InteractionComponent`, `player_index` = `controlled_by`); locales `InteractionDetector.hint_changed(target, hint)` e `InteractionComponent.interaction_resolved(target, hint)`.
Tests por AC: AC1 `test_action_rules.gd` + `tests/fixtures/action_matrix.csv` (generado celda a celda de las tablas A–F); AC2 `test_action_hint.gd`; AC3 `test_interaction_scoring.gd`; AC4 `test_interaction_detector.gd` (+ `test_highlightable.gd`, `test_hold_component.gd`, `test_held_kind.gd`); AC5/AC6 `test_interaction_component.gd` + `test_hold_repeat.gd` + `test_player_input.gd`; AC7 `test_event_bus.gd`, `test_player_input.gd`; AC8 suite completa (`test_m2b_station_selection.gd`, `test_level_01_r16.gd` ajustados solo a histéresis y filtro de control).
Helpers: `fake_detector.gd` (+`hint_changed`, `get_hint`), `fake_holder.gd` (+`can_drop`), `fake_hinted_interactable.gd` (nuevo).

## Evidence
- `bash tools/verify.sh --quick` verde (gdformat, gdlint, import). Suite GUT completa: 943 tests (828 antes de la ficha; +115), **938 en verde y 5 en rojo fuera de `owns`** (ver «Bloqueo»). Líneas base: 828/828 en `b1f66e5`.
- Tests nuevos o ampliados: `test_action_hint` (12), `test_action_rules` (9, 350 filas del CSV transcritas celda a celda de A–F: 0 discrepancias), `test_hold_repeat` (6), `test_interaction_scoring` (+14), `test_interaction_component` (+26: respuesta única, suelo libre y bloqueado, sin control, bus con primitivos, cambio de personaje, mantener 1,05 s = 6 cortes, pausa), `test_interaction_detector` (+24: filtro `NONE`, ±10 % durante 5 s = 0 cambios, 1 cambio al acercarse, `hint_changed`, sin control, hint de suelo, ámbar), `test_held_kind` (8), `test_highlightable` (+5), `test_hold_component` (+3), `test_event_bus` (+1 y catálogo), `test_player_input` (+4), `test_interaction_contract` (+6), `test_m2b_station_selection` (+2).
- Datos: `hysteresis_margin` = 0,2 (`player_config.tres`), `cut_repeat_interval` = 0,2 (`input_config.tres`).
- Desviaciones del contrato: (1) `Highlightable.blocked_material` sin valor por defecto en recurso: si no se asigna se deriva en `_ready` de `material` con el ámbar `Highlightable.BLOCKED_COLOR` (`#FFB020`), porque `shaders/**` es de PUL-127; PUL-127 puede asignar un `.tres` propio. (2) `InteractionComponent` calcula el hint de suelo con `ActionRules.for_floor(Held.OTHER|NOTHING, holder.can_drop_freely())` (el suelo no depende de la clase de la mano) en vez de pedirlo al detector, porque el componente es común y `HeldKind` es específico; el detector publica el mismo hint con `HeldKind`. (3) Con un objetivo heredado (`ok(&"")`) cuyo `interact` devuelve `false`, el componente cae al suelo como antes (compatibilidad) y solo hace `push_error` con un verbo real.

### Bloqueo: 5 tests fuera de `owns` en rojo por el filtro honesto y la histéresis
Causa única: dejan de ser ciertas dos suposiciones de esos tests (no es un fallo del núcleo).
1. `test_m2b_flow.gd` (`test_ac1_single_three_deliveries_through_the_pass_switching_characters`, `test_ac1_coop_three_deliveries_cook_and_server_each_on_their_side`) y `test_station_level.gd` (`test_ac16_…`, `test_ac17_…`): `assert_eq(…get_target(), stand, "de cara al puesto N")` tras `walk_to` delante del puesto. El portador ya entregó al entrar en `%DeliveryZone` (mano vacía), así que `OrderStand.can_interact` es falso y el puesto, antes objetivo aunque no hiciera nada, ya no es candidato. Arreglo comprobado: quitar esa aserción (y el bucle `push_towards` previo es inofensivo); con ello pasan 2/2 y 6/6. Dueños: PUL-126 (`test_m2b_flow`, `test_station_level`) y PUL-131.
2. `test_trash_bin.gd::test_t8_only_closest_of_bin_and_free_slot_is_target`: añade el cubo al nivel con el slot ya como objetivo y espera que el cubo gane; con la histéresis (D26.4) el actual se mantiene salvo +20 %. Arreglo: apartar y volver (`_face_bin()` con el slot fuera) o instanciar el cubo antes de que el slot sea objetivo. Dueño: PUL-125.
- Fixture CSV: Godot importa los `.csv` como traducciones y genera `action_matrix.csv.import` y 9 `action_matrix.*.translation` junto al fichero; no están en `owns` y no se versionan. Solución propuesta al producer: un `godot/tests/fixtures/.gdignore` o un `action_matrix.csv.import` con `importer="keep"` en `owns`.

### Resuelto (owns ampliado en 17c23a4)
`verify.sh` completo en verde: 943/943. Quitada la aserción de puesto como objetivo en `test_m2b_flow` y `test_station_level`; `test_trash_bin` t8 aparta al jugador antes de añadir el cubo (mide lo mismo). `tests/fixtures/.gdignore` evita el import del CSV (el test lo lee con `FileAccess`).
