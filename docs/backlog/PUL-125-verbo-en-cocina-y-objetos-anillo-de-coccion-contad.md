---
id: PUL-125
title: Verbo en cocina y objetos; anillo de cocción, contador de corte y aviso de quemado
status: in_progress
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-124]
orca_task: null
unity_sources: []
owns: [godot/entities/items/box.gd*, godot/entities/items/ingredient.gd*, godot/entities/stations/cooking_station.gd*, godot/entities/stations/slot.gd*, godot/entities/stations/item_spawner.gd*, godot/entities/stations/trash_bin.gd*, godot/resources/kitchen_data.gd*, godot/data/config/kitchen.tres, godot/ui/widgets/world_progress_bar.gd*, godot/ui/widgets/world_progress_ring.gd*, godot/tests/integration/test_box.gd*, godot/tests/integration/test_box_on_slot.gd*, godot/tests/integration/test_box_model.gd*, godot/tests/integration/test_box_counter.gd*, godot/tests/integration/test_box_cut_hold.gd*, godot/tests/integration/test_burn.gd*, godot/tests/integration/test_cooking_station.gd*, godot/tests/integration/test_cook_ring.gd*, godot/tests/integration/test_item_spawner.gd*, godot/tests/integration/test_slot.gd*, godot/tests/integration/test_trash_bin.gd*, godot/tests/integration/test_octopus.gd*, godot/tests/integration/test_shelves.gd*, godot/tests/integration/test_hold_component.gd*, godot/tests/integration/test_audio_feedback.gd*, godot/tests/integration/test_kitchen_hints.gd*, godot/tests/integration/test_kitchen_flow.gd*, godot/tests/integration/test_m1_flow.gd*, godot/tests/integration/test_m2_flow.gd*, godot/tests/integration/test_parity_smoke.gd*, godot/tests/integration/test_delivery_e2e.gd*, godot/tests/integration/test_level_01.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/integration/level_walker.gd*, godot/tests/integration/, docs/evidence/PUL-125/**, docs/backlog/PUL-125-verbo-en-cocina-y-objetos-anillo-de-coccion-contad.md]
touches_scenes: [godot/entities/items/box.tscn, godot/entities/stations/kitchen.tscn, godot/ui/widgets/world_progress_bar.tscn, godot/ui/widgets/world_progress_ring.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/items/box.tscn`, `godot/entities/stations/kitchen.tscn`,
  `godot/ui/widgets/world_progress_bar.tscn`, `godot/ui/widgets/world_progress_ring.tscn` (nueva)

## Change
`get_action_hint` + `_resolve` sobre `ActionRules` en caja, pulpo/cachelos, olla,
  pasaplatos, spawners y cubo (§11.2, filas A1–A6, B, C); `can_interact` honesto; `%CutCounter` y
  `get_presses()`; `%CookRing` por plaza; aviso de quemado con repetición; cues `cook_ready` (en lugar
  de `cook_done`) y `box_full`; barras ≥ 8 px. **No** quita `Box.toggle_seasoning()` (PUL-131).

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
