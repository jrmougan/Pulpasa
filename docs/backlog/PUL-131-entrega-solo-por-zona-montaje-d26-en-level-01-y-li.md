---
id: PUL-131
title: Entrega solo por zona, montaje D26 en `level_01` y limpieza de contrato
status: in_progress
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-130]
orca_task: null
unity_sources: []
owns: [godot/components/interaction_component.gd*, godot/tests/unit/test_interaction_component.gd*, godot/tests/unit/test_action_icon_set.gd*, godot/tests/unit/test_icons_silhouettes.gd*, godot/entities/player/player.gd*, godot/entities/player/player.tscn, godot/entities/player/character_switcher.gd*, godot/tests/integration/test_player*.gd*, godot/assets/materials/active_indicator_p*, godot/resources/box_data.gd*, godot/data/boxes/box.tres, godot/entities/items/box.tscn, godot/ui/hud/hud.gd*, godot/ui/hud/hud.tscn, godot/tests/integration/test_hud.gd*, godot/ui/theme/default_theme.tres, godot/ui/widgets/world_progress_ring.gd*, godot/entities/stations/cooking_station.gd*, godot/entities/stations/kitchen.tscn, godot/ui/menus/game_over.gd*, godot/ui/menus/game_over.tscn, docs/assets/licenses.md, godot/entities/stations/cachelos_bowl.gd*, godot/entities/stations/order_stand.gd*, godot/entities/stations/seasoning_station.gd*, godot/scenes/levels/level_01.tscn, godot/components/interaction_contract.gd*, godot/data/audio/feedback_map.tres, godot/data/config/round_config.tres, godot/entities/items/box.gd*, godot/core/seasoning_rules.gd*, godot/tests/fixtures/action_matrix.csv, godot/tests/integration/test_action_matrix.gd*, godot/tests/integration/test_order_stand.gd*, godot/tests/integration/test_delivery_e2e.gd*, godot/tests/integration/test_kitchen_flow.gd*, godot/tests/integration/test_m1_flow.gd*, godot/tests/integration/test_m2_flow.gd*, godot/tests/integration/test_m2b_flow.gd*, godot/tests/integration/test_station_level.gd*, godot/tests/integration/test_parity_smoke.gd*, godot/tests/integration/test_level_01.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/integration/level_walker.gd*, godot/tests/integration/test_items_contract.gd*, godot/tests/integration/test_stations_contract.gd*, godot/tests/integration/test_audio_feedback.gd*, godot/tests/integration/test_seasoning_station.gd*, godot/tests/integration/, godot/tests/unit/test_seasoning_rules.gd*, godot/tests/unit/test_interaction_contract.gd*, godot/tests/unit/test_round_state.gd*, godot/tests/helpers/m0_data/**, docs/evidence/PUL-131/**, docs/backlog/PUL-131-entrega-solo-por-zona-montaje-d26-en-level-01-y-li.md]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/items/box.tscn, godot/ui/hud/hud.tscn, godot/entities/stations/kitchen.tscn, godot/ui/menus/game_over.tscn, godot/entities/stations/order_stand.tscn, godot/entities/stations/seasoning_station.tscn, godot/scenes/levels/level_01.tscn, sandbox/*.tscn]
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
- Revisión de PUL-121: (1) añadir al CSV `tests/fixtures/action_matrix.csv` las 3 filas F (zona de entrega: receptor `delivery_zone`, `reachable=0`, NONE); (2) test del invariante ADR-002 Enmienda 2: tras varios Q y en COOP_2P, ≤ 1 `InteractionComponent` con `controlled_by == p`; (3) `components/interaction_component.gd:81-82`: receptor con verbo real cuyo `interact` devuelve false → hoy `push_error` sin `interaction_resolved` (pulsación muda); emitir la respuesta; (4) quitar los bucles `for _i in 20 … get_target() == stand` de `test_m2b_flow.gd:274` y `test_station_level.gd:140`; (5) listas literales de verbos/motivos en `test_action_icon_set.gd` y `test_icons_silhouettes.gd` → `ActionVerb.ALL`/`ActionReason.ALL`; (6) placas lisas `SizePanel_*` del rack: renombrar/retirar al cambiar `test_level_01.gd`; (7) texto obsoleto de `box_sizes`/S/M/L en `docs/assets/licenses.md` (ya en owns).
- PUL-127: el aro inactivo es un nodo hermano `%InactiveIndicator` (no el mismo `%ActiveIndicator` de `scene-tree.md`) porque `test_m2_flow.gd` exige `%ActiveIndicator.visible == false` en el inactivo. Unifica al actualizar ese test (preferido) o describe en Evidence la estructura para que el producer actualice `scene-tree.md`. Materiales `assets/materials/active_indicator_p*.tres` sustituidos por `shaders/ring_*.tres`: da de baja los viejos si nada los usa.
- PUL-125: `camera_size` 12,74 fijo en `world_progress_ring.gd:32` y `cooking_station.gd:108`: leer el tamaño de `CameraRig`/`CameraProfile` activo; `unique_id` faltantes en nodos nuevos de `box.tscn` (abrir y guardar con el editor headless si es posible).
- Revisión de PUL-128: (a) velocidad analógica: `entities/player/player.gd:80` normaliza la dirección, así que el stick (y el mando) a 0,5 anda igual que a 1,0; aplica la magnitud (con zona muerta de `InputConfig`) y test; (b) en game over oculta o desactiva `TouchControls` (el árbol no se pausa); (c) `scene-tree.md` §9.3 y ADR-004 §6.2 no recogen el nodo `SafeArea/Content` (top_level) de `touch_controls.tscn`: el producer la hace en `docs/arch/` al cerrar; describe en Evidence la estructura final; (d) pictogramas de cambiar y pausa dibujados por código: ficha de assets futura.
- PUL-126: (a) al quitar `season_error` de `seasoning_station.gd`, repón en `test_seasoning_station.gd::test_audio_ac7_one_season_cue_per_dressing…` la aserción de que la estación no suena nada; (b) quita `CachelosBowl.clock` (Callable en desuso) y sus asignaciones en `test_kitchen_flow`, `test_m2_flow`, `test_parity_smoke`; (c) `Box.toggle_seasoning` y `SeasoningRules.toggle()` de baja. PUL-125: `%FillBar` de la caja oculta (no eliminada) por `test_items_contract`: retírala; `Box.COUNTER_FULL_TIME` a `BoxData`. PUL-129: `%BoxesPerMinute` oculto en `hud.tscn` por `test_parity_smoke.gd:351`: quita ambos.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [ ] AC1 (diseño AC1, AC2, AC11, AC20) `test_action_matrix.gd` recorre las ≥ 250 filas del CSV (con las 3 F añadidas) con las escenas reales y el detector real: 0 discrepancias; OK cambia el mundo con 1 señal de éxito, BLOQUEADO no cambia nada con 1 rechazo, `—` sin respuesta ni contorno; suelo libre y bloqueado. Cuentas exactas, filas mal formadas fallan
- [ ] AC2 Puesto: fuera de `interactable` y de su capa; el detector no lo elige desde ningún punto de la zona; entrega al entrar y a quien ya estaba dentro cuando sale la comanda; caja errónea: nada, sin `delivery_rejected`; `wrong_delivery_penalty` = 0 → `test_order_stand.gd`, `test_delivery_e2e.gd`
- [ ] AC3 Contrato: todo `interactable` de `entities/` implementa `get_action_hint` y ninguno usa la equivalencia sin verbo → `test_items_contract.gd`, `test_stations_contract.gd`
- [ ] AC4 `level_01`: `TouchControls` presente y en orden en `UI`; `CameraRig.characters` = [Player1, Player2]; regla de colocación de los cubos sin cambios → `test_level_01.gd`
- [ ] AC5 Mapa sin `cook_done`, `season_error` ni `deliver_error`; sin `SeasoningRules.toggle` ni `Box.toggle_seasoning`; flujos en verde entregando por zona → `test_audio_feedback.gd`, `test_seasoning_rules.gd`, flujos
- [ ] AC6 Pendientes heredados (arriba) resueltos o, si alguno no procede, justificado en Evidence
- [ ] AC7 Partida completa de `level_01` en escritorio y con `--touch` sin errores en consola (smoke de 60 s con el bot o input simulado); capturas en `docs/evidence/PUL-131/` a 1920×1080 y 2340×1080 `--touch`

## Plan

## Evidence
