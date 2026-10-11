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

### Pendientes heredados (producer)
- Revisión de PUL-121: (1) añadir al CSV `tests/fixtures/action_matrix.csv` las 3 filas F (zona de entrega: receptor `delivery_zone`, `reachable=0`, NONE); (2) test del invariante ADR-002 Enmienda 2: tras varios Q y en COOP_2P, ≤ 1 `InteractionComponent` con `controlled_by == p`; (3) `components/interaction_component.gd:81-82`: receptor con verbo real cuyo `interact` devuelve false → hoy `push_error` sin `interaction_resolved` (pulsación muda); emitir la respuesta; (4) quitar los bucles `for _i in 20 … get_target() == stand` de `test_m2b_flow.gd:274` y `test_station_level.gd:140`; (5) listas literales de verbos/motivos en `test_action_icon_set.gd` y `test_icons_silhouettes.gd` → `ActionVerb.ALL`/`ActionReason.ALL`; (6) placas lisas `SizePanel_*` del rack: renombrar/retirar al cambiar `test_level_01.gd`; (7) texto obsoleto de `box_sizes`/S/M/L en `docs/assets/licenses.md` (pídelo si no está en owns).
- PUL-127: el aro inactivo es un nodo hermano `%InactiveIndicator` (no el mismo `%ActiveIndicator` de `scene-tree.md`) porque `test_m2_flow.gd` exige `%ActiveIndicator.visible == false` en el inactivo. Unifica al actualizar ese test o actualiza `scene-tree.md` (pídelo). Materiales `assets/materials/active_indicator_p*.tres` sustituidos por `shaders/ring_*.tres`: da de baja los viejos si nada los usa.
- Revisión de PUL-128: (a) velocidad analógica: `entities/player/player.gd:80` normaliza la dirección, así que el stick (y el mando) a 0,5 anda igual que a 1,0; aplica la magnitud (con zona muerta de `InputConfig`) y test; (b) en game over oculta o desactiva `TouchControls` (el árbol no se pausa); (c) `scene-tree.md` §9.3 y ADR-004 §6.2 no recogen el nodo `SafeArea/Content` (top_level) de `touch_controls.tscn`: pide al producer la enmienda documental; (d) pictogramas de cambiar y pausa dibujados por código: ficha de assets futura.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
