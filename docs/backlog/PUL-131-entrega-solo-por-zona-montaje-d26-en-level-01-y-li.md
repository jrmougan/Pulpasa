---
id: PUL-131
title: Entrega solo por zona, montaje D26 en `level_01` y limpieza de contrato
status: todo
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-130]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd*, godot/entities/stations/seasoning_station.gd*, godot/scenes/levels/level_01.tscn, godot/components/interaction_contract.gd*, godot/data/audio/feedback_map.tres, godot/data/config/round_config.tres, godot/entities/items/box.gd*, godot/core/seasoning_rules.gd*, godot/tests/fixtures/action_matrix.csv, godot/tests/integration/test_action_matrix.gd*, godot/tests/integration/test_order_stand.gd*, godot/tests/integration/test_delivery_e2e.gd*, godot/tests/integration/test_kitchen_flow.gd*, godot/tests/integration/test_m1_flow.gd*, godot/tests/integration/test_m2_flow.gd*, godot/tests/integration/test_m2b_flow.gd*, godot/tests/integration/test_station_level.gd*, godot/tests/integration/test_parity_smoke.gd*, godot/tests/integration/test_level_01.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/integration/level_walker.gd*, godot/tests/integration/test_items_contract.gd*, godot/tests/integration/test_stations_contract.gd*, godot/tests/integration/test_audio_feedback.gd*, godot/tests/integration/test_seasoning_station.gd*, godot/tests/integration/, godot/tests/unit/test_seasoning_rules.gd*, godot/tests/unit/test_interaction_contract.gd*, godot/tests/unit/test_round_state.gd*, godot/tests/helpers/m0_data/**, docs/evidence/PUL-131/**, docs/backlog/PUL-131-entrega-solo-por-zona-montaje-d26-en-level-01-y-li.md]
touches_scenes: [godot/entities/stations/order_stand.tscn, godot/entities/stations/seasoning_station.tscn, godot/scenes/levels/level_01.tscn, sandbox/*.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 3. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/stations/order_stand.tscn`,
  `godot/entities/stations/seasoning_station.tscn`, `godot/scenes/levels/level_01.tscn` y los
  `sandbox/*.tscn` que dejen de cargar por las bajas (el producer los lista al abrir la ficha)

## Change
ADR-003 §11.7 del puesto; `seasoning_station.gd` y `order_stand.gd` sin `season_error` /
  `deliver_error`; `wrong_delivery_penalty` = 0; `TouchControls` en `UI` y `CameraRig.characters` en el
  nivel (`scene-tree.md` §2); `get_action_hint` obligatorio; bajas `cook_done`, `season_error`,
  `deliver_error` del mapa, `SeasoningRules.toggle()` y `Box.toggle_seasoning()` (`scene-tree.md`
  §7.3); test de matriz sobre escenas reales.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
