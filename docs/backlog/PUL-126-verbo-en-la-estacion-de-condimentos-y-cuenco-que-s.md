---
id: PUL-126
title: Verbo en la estación de condimentos y cuenco que solo pone
status: todo
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


## Plan

## Evidence
