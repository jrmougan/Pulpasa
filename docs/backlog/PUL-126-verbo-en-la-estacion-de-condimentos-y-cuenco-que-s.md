---
id: PUL-126
title: Verbo en la estación de condimentos y cuenco que solo pone
status: review
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-123, PUL-125]
orca_task: null
unity_sources: []
owns: [godot/data/config/box_badges.tres, godot/tests/integration/test_box_badges.gd*, godot/entities/stations/seasoning_dispenser.gd*, godot/entities/stations/cachelos_bowl.gd*, godot/resources/seasoning_data.gd*, godot/resources/seasoning_station_data.gd*, godot/data/seasonings/**, godot/data/config/seasoning_station.tres, godot/tests/integration/test_seasoning_station.gd*, godot/tests/integration/test_cachelos.gd*, godot/tests/integration/test_cachelos_bowl_view.gd*, godot/tests/integration/test_m2b_flow.gd*, godot/tests/integration/test_station_level.gd*, godot/tests/integration/test_m2b_station_selection.gd*, godot/tests/integration/test_station_hints.gd*, godot/tests/integration/test_box_badges.gd*, godot/tests/unit/test_data_integrity.gd*, godot/tests/unit/test_data_catalog.gd*, docs/evidence/PUL-126/**, docs/backlog/PUL-126-verbo-en-la-estacion-de-condimentos-y-cuenco-que-s.md]
touches_scenes: [godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/seasoning_dispenser.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/stations/cachelos_bowl.tscn`,
  `godot/entities/stations/seasoning_dispenser.tscn`

## Change
§11.2 en dispensadores y cuenco (filas D y E; verbo de `SeasoningData.verb`;
  `replaces`; `ALREADY_APPLIED` con `rejected` y sin silencio); cuenco solo pone con
  `apply_seasoning`, reponer con `stock + 2 ≤ 4`, cualquier caja desde el lado de aliñar, sin toggle
  ni antirrebote, `%StockMeter`; baja de `toggle_guard`; `verb` e `icon` en los 3 `SeasoningData`
  (pimentonera / guindilla). **No** toca `seasoning_station.gd` ni el puesto.

### Pendientes heredados (producer)
- Icono propio de cada aliño (PUL-123): `icon` de `data/seasonings/sweet_dressing.tres` y `hot_dressing.tres` → `res://assets/textures/ui/actions/icon_verb_season_sweet.svg` / `icon_verb_season_hot.svg` (ticket y dispensador); `hot_mark`/pegatina en `data/config/box_badges.tres` igual. Ajusta `test_box_badges.gd` y los tests de datos si los comprueban (`test_data_integrity`, `test_assets_audio_ui`: si están fuera de owns, avisa).

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 (diseño AC2) Filas D y E: hint = efecto; desde el lado de pase dispensadores y cuenco-con-caja no son candidatos → `test_station_hints.gd`
- [x] AC2 Cuenco: pone (stock −1); ya lleva → `B:already_applied` sin cambios (también con stock 0); stock 0 → `B:empty`; caja a medias → `B:box_not_full`; reponer con stock 3 → `B:full`; no hay quitar → `test_cachelos.gd`
- [x] AC3 Dispensador: mismo aliño → `rejected(ALREADY_APPLIED)`; el otro → sustituye con `replaces` en el hint → `test_seasoning_station.gd`
- [x] AC4 (diseño AC17) Con stock 2 se ven 4 muescas, 2 llenas, contraste ≥ 3:1, ≥ 24 px a 1080; con 0 y 4, 0 y 4 llenas → `test_cachelos_bowl_view.gd` + captura
- [x] AC5 Datos: `verb` válido en los 3 `SeasoningData`; `hot_dressing` con `icon_verb_season_hot` y `sweet_dressing` con `icon_verb_season_sweet`; sin `toggle_guard` → `test_data_integrity.gd`, `test_box_badges.gd`; `test_m2b_flow` y `test_station_level` en verde

## Plan
Ficheros (todos en `owns` / `touches_scenes`):
- `resources/seasoning_data.gd`: `@export var verb: StringName`. `data/seasonings/*.tres`: `verb` (`season_sweet`, `season_hot`, `cachelos`); `icon` de dulce y picante = `icon_verb_season_sweet.svg` / `icon_verb_season_hot.svg`.
- `data/config/box_badges.tres`: `hot_mark` se queda en la llama `small-fire.svg` (decisión del producer: el icono propio ya distingue; la llama es acento).
- `resources/seasoning_station_data.gd` + `data/config/seasoning_station.tres`: baja `toggle_guard`; alta de los datos del medidor (`stock_notch_px` 24, hueco, contorno, colores, opacidad de la placa).
- `entities/stations/seasoning_dispenser.gd`: placa con `seasoning.icon` sobre el cartel baked del frontal (se oculta el cartel `seasoning_signs`); `_resolve` → `ActionRules.for_dispenser`; `get_action_hint`; `can_interact` = `is_target()`; `interact` ejecuta la rama del hint (`OK` aplica y gesto, `BLOCKED` emite `rejected` y consume, `NONE` `false`); `is_reachable_from` = solo el lado.
- `entities/stations/cachelos_bowl.gd` + `cachelos_bowl.tscn`: `_resolve` → `ActionRules.for_bowl`; solo pone (`Box.apply_seasoning`), repone si `stock + 2 <= 4`; sin `_toggle`, `toggle_guard` ni reloj; `%StockMeter` (`Sprite3D` billboard, textura generada por `build_meter_image`); `stock` con setter que refresca modelo y medidor.
- Señales: ninguna nueva ni cambiada. `rejected(SeasoningRules.Rejection)` local sigue (dispensador: `BOX_NOT_FULL`, `ALREADY_APPLIED`; cuenco: además `BOWL_EMPTY`, `BOWL_FULL`). Sin cues de error en estas entidades (los da el jugador, ADR-003 §11.4).
Tests:
- AC1 → `tests/integration/test_station_hints.gd`: 40 filas D + las E de `tests/fixtures/action_matrix.csv` contra `is_reachable_from`, `get_action_hint` e `interact` con la estación y el jugador reales, más contrato y detector.
- AC2 → `test_cachelos.gd` (mapa de motivos del cuenco con escena real) y `test_seasoning_station.gd` (`stock + 2 <= 4`, no quita).
- AC3 → `test_seasoning_station.gd` (`ALREADY_APPLIED` con `rejected`, `replaces` en el hint).
- AC4 → `test_cachelos_bowl_view.gd` (lee los píxeles de la textura del medidor).
- AC5 → `test_data_integrity.gd`, `test_box_badges.gd`; `test_m2b_flow` y `test_station_level` sin cambios y en verde.

## Evidence
- `bash tools/verify.sh` completo en verde (981 tests GUT, 0 fallos; gdformat, gdlint, import, smoke).
- Capturas (1920×1080, cámara real de `level_01`; `docs/evidence/PUL-126/capture.gd` las regenera):
  - `station_dispensers_and_meter.png`: estación con el cuenco a 2 raciones (4 muescas, 2 llenas) e icono propio de cada aliño (pimentonera, guindilla) en el frontal de su dispensador.
  - `bowl_stock_0.png` … `bowl_stock_4.png`: el medidor con 0…4 raciones.
  - `box_badges_sweet_hot.png` y `box_badges_sweet_hot_zoom.png` (recorte ×4): pegatinas de la caja dulce, picante y dulce + cachelos.
  - `tickets_stickers.png` (ticket ×3): pegatina dulce (pimentonera) y picante (guindilla) en las cuatro comandas.
- Desviaciones y avisos:
  - `seasoning_station.gd` (fuera de `owns`, PUL-131) sigue reproduciendo `season_error` al oír `rejected`; el fin del cue de error en estaciones llega con el montaje. Los tests de esta ficha que lo ven (`test_ac5_*`, `test_audio_ac7_unfilled_*`) no cambian de comportamiento.
  - `CachelosBowl.clock` se queda como `Callable` vacío en desuso (sin efecto) porque `test_kitchen_flow`, `test_m2_flow` y `test_parity_smoke` (fuera de `owns`, PUL-131) todavía lo asignan; PUL-131 lo retira con ellos. `Box.toggle_seasoning` no se toca (`box.gd` es de PUL-131): ya no lo llama nadie en `entities/`.
  - `is_reachable_from` pasa a ser solo el filtro de lado (la mano la decide el hint), como fija la columna `reachable` del fixture: dispensador, solo lado; cuenco, solo lado con caja en la mano.
  - `hot_mark` se queda en la llama (`small-fire.svg`) por decisión del producer; el icono propio de cada aliño va en el disco de la pegatina.
  - El `.glb` trae la misma guindilla en los dos dispensadores: `seasoning_dispenser.gd` tapa ese cartel y pone una placa con `seasoning.icon` (sin tocar el `.glb`).
