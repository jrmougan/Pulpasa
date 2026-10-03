# PUL-025 · Smoke checklist de paridad M0 (informe de QA)

Fecha: 2026-10-04 · Rama `jrmougan/pul-025` (base `e4ba5c1`) · Godot 4.7.2.stable.official ·
Feature `docs/design/features/paridad-unity.md` (AC1–AC8).

Resumen: **AC1–AC7 pasan en el proyecto y en el build de Linux**. **AC8**: Linux pasa en lo
verificable (headless + ventana real bajo `xvfb-run`); **Windows se exporta pero no es verificable**
(no hay Windows ni Wine en esta máquina). Ningún fallo en código de otras fichas: no ha hecho falta
escalar.

`tools/verify.sh`: ✓ verify OK (42 scripts, 383 tests, 3049 asserts; incluye este smoke).

## AC1–AC6 · `godot/tests/integration/test_parity_smoke.gd`

Corre sobre el proyecto real: escena principal (menú) → `ui_accept` sobre «Jugar» →
`GameState.start_level` → `level_01.tscn` con los autoloads de verdad. Las pulsaciones de
interactuar pasan por `InteractionComponent.interact_pressed()` con el objetivo que publicaría el
detector (patrón de `test_kitchen_flow.gd`); el recorrido físico hasta cada puesto ya lo cubre
`test_level_01.gd::test_ac4_player_reaches_and_interacts_with_every_station_and_slot`.

| AC | Test | Qué comprueba | Proyecto | Build Linux |
|---|---|---|---|---|
| AC1 | `test_ac1_main_scene_is_menu_and_loads_under_budget_without_errors` | escena principal = menú, listo en < 5 s, foco en Jugar, 0 errores | pasa | pasa: menú en la captura a 2 s ([ac1](ac1-linux-build-menu-2s.png)); 300 frames headless en 2,25 s sin `ERROR` ([log](linux-headless.log)) |
| AC2 | `test_ac2_play_loads_level_with_one_controllable_player` | Jugar → `level_01`, modo SINGLE, 1 personaje controlado por J1, ronda a 180 s, 4 puestos con comanda | pasa | pasa: Enter en el menú carga el nivel ([ac2](ac2-linux-build-level.png), [ac8](ac8-linux-build-level.png)) |
| AC3 | `test_ac3_full_flow_completes_one_order_and_adds_exactly_one` | nevera → olla → caja → cortes → condimentos → entrega: 1 `order_completed` (la entregada), `boxes_delivered` = 1, HUD actualizado, solo ese puesto cambia de comanda, sin segunda señal 5 ticks después | pasa | no automatizable en el build (sin puente de input); cubierto en el proyecto |
| AC4 | `test_ac4_twenty_deliveries_leave_no_empty_stands_duplicates_or_ghosts` | 20 entregas seguidas rotando los 4 puestos (10 pulpos): 20 señales, 4 comandas con ids únicos y etiquetas correctas tras cada entrega, 0 cajas/pulpos vivos, 3 botes en sus slots, olla libre, mano vacía | pasa (~50 s) | ídem AC3 |
| AC5 | `test_ac5_pause_and_resume_keeps_state_within_tolerance` | acción `pause` con un pulpo cociendo: 0,5 s reales en pausa; reloj, progreso de la olla y posición del jugador iguales (±0,05 s), mismas comandas; el reloj sigue al reanudar | pasa | pasa a ojo: Esc abre la pausa con el reloj en 177,0 s, igual que antes de pausar ([ac8-pause](ac8-linux-build-pause.png)) |
| AC6 | `test_ac6_round_end_and_retry_reset_state` | tras una entrega y un pulpo en la olla, fin de ronda → game over con foco en Reintentar → `ui_accept` → nivel nuevo: `orders_reset` + 4 comandas nuevas, olla libre, 0 objetos, reloj a 180 s («180.0s» en el HUD), contador a 0, sin pausa | pasa | pasa: tras 180 s reales sale «Turno terminado» con el reloj a 0,0 s y foco en Reintentar ([ac6](ac6-linux-build-game-over.png)); Enter → nivel nuevo con otras comandas y el reloj reiniciado (178,0 s a los 3 s) ([retry](ac6-linux-build-retry.png)) |

Nota AC6: el test agota el reloj único con `RoundManager.round_state.advance(time_left)` en vez de
esperar 180 s reales; el final exacto en `duration` lo cubre `test_round_state.gd` (B2). En el build
sí se esperan los 180 s reales (sección AC8).

## AC7 · Bugs del inventario (`docs/migration/inventory.md` §4)

Ninguno se reproduce. Tests en `godot/tests/`; «estático» = comprobación por búsqueda en el código.

| # | Bug del prototipo | Evidencia de que no se reproduce |
|---|---|---|
| B1 | Doble `CompleteOrder` (una entrega completa 2 comandas) | `unit/test_order_board.gd::test_ac1_order_completed_once_per_delivery`, `integration/test_order_stand.gd::test_ac1_valid_box_in_zone_completes_exactly_one_order`, `test_review_same_tick_both_entry_points_valid_box_completes_once`; `test_parity_smoke.gd` AC3 (+1 exacto y la completada es la entregada) y AC4 (20 entregas = 20 señales) |
| B2 | Dos temporizadores; fin a 179,5 s; game over que no sale | `unit/test_round_state.gd::test_ac5_round_does_not_end_at_179_5`, `test_ac5_round_ends_exactly_at_duration`; `integration/test_hud.gd::test_ac1_mount_does_not_start_round_or_own_clock`, `test_ac1_round_signals_update_time_and_finish_at_zero`; build: game over al llegar a 0 ([ac6](ac6-linux-build-game-over.png)) |
| B3 | `EmissionHighlighter` roto; la sal no se resalta | `integration/test_items_contract.gd::test_ac4_items_are_bodies_on_interactable_layer_with_highlight` (también el bote), `integration/test_interaction_detector.gd::test_ac1_target_is_highlighted`; estático: sin `EmissionHighlighter`/`DynamicGI` en `godot/` |
| B4 | `OnPickedUp` nunca se llama; `IsHeld` siempre falso | `integration/test_hold_component.gd::test_ac3_pick_up_calls_on_picked_up_once_and_emits`, `test_ac3_drop_calls_on_dropped_once_and_restores_physics` |
| B5 | `heldObject` asignado antes de validar `IPickable` | `integration/test_hold_component.gd::test_ac4_non_pickable_body_is_rejected_without_changes` y los `test_ac4_*_rejected_without_changes` |
| B6 | Rama de condimentar inalcanzable y bote destruido | `integration/test_seasoning.gd::test_b6_jar_is_not_consumed_when_seasoning`; `test_parity_smoke.gd` AC4 (3 botes vivos en sus slots tras 20 entregas) |
| B7 | Dos `InteractionDetector` en el jugador | `integration/test_interaction_detector.gd::test_ac1_one_detector_per_player_wired_to_interaction_component`, `test_ac1_turning_switches_highlight_without_two_highlighted` |
| B8 | `Box.Fill` sin comprobar null de la barra | `integration/test_box.gd::test_box_without_fill_bar_does_not_crash` |
| B9 | Pulpo agotado solo se destruye si tiene barra | `integration/test_octopus.gd::test_ac3_freed_when_depleted_without_bar`, `test_ac3_freed_when_depleted_with_bar`; `integration/test_box.gd::test_ac1_one_octopus_fills_two_boxes_then_is_freed`; `test_parity_smoke.gd` AC4 (0 pulpos vivos tras 20 cajas) |
| B10 | Orden de `Start` no determinista borra pedidos | `unit/test_round_manager.gd::test_ac2_start_round_order_reset_generated_per_slot_then_started`, `unit/test_round_state.gd::test_ac5_start_sequence_resets_fills_and_announces`; `test_parity_smoke.gd` AC2/AC6 (4 comandas al entrar y al reintentar) |
| B11 | La UI arranca la ronda | `integration/test_hud.gd::test_ac1_mount_does_not_start_round_or_own_clock`; estático: `RoundManager.start_round` solo en `scenes/levels/level.gd` (y sandboxes) |
| B12 | Entrega solo al entrar en el trigger | `integration/test_order_stand.gd::test_ac3_already_inside_zone_interact_delivers`; `test_parity_smoke.gd` AC3/AC4 entregan con E sin entrar en la zona |
| B13 | Pausa redundante (`timeScale` + flag + input viejo) | `integration/test_pause_menu.gd::test_ac1_pause_freezes_tree_and_focuses_resume`, `unit/test_round_manager.gd::test_ac3_paused_tree_does_not_advance_round_clock`, `unit/test_input_map.gd` (acción `pause`); `test_parity_smoke.gd` AC5; estático: sin `time_scale` en `godot/` |
| B14 | Hover de menús con `rect` local | `integration/test_main_menu.gd::test_ac3_native_navigation_wraps_and_tabs`, `test_ac3_joypad_dpad_and_accept_use_native_actions` (`Button` y foco nativos) |
| B15 | Especias de más aceptadas | Regla mantenida en M0 (inventario): `unit/test_order_validator.gd`, `integration/test_kitchen_flow.gd::test_ac2_missing_seasoning_rejected_extra_seasoning_accepted`. Decisión exacta pendiente en M1 (D4) |
| B16 | `OrderSystem` busca objetos de escena | `unit/test_order_service.gd::test_ac1_service_has_no_process_callbacks`; puestos escuchan `orders_reset`: `integration/test_order_stand.gd::test_ac1_label_clears_on_reset_completed_and_expired`; estático: `core/` y `order_service.gd` sin `get_node`/`get_tree` |
| B17 | `Salt.asset` antiguo y `BoxSO` a GUID inexistente | `unit/test_data_integrity.gd::test_ac3_all_tres_load`, `test_ac3_no_missing_dependencies`, `test_ac3_references_are_filled`; `unit/test_data_boxes.gd`, `unit/test_data_catalog.gd` |
| B18 | `?.` sobre objetos destruidos | `integration/test_hold_component.gd::test_ac3_freed_held_item_clears_hand_and_allows_new_pick_up`, `test_ac3_item_queued_for_deletion_is_not_reported_as_held`; `integration/test_interaction_detector.gd::test_ac1_freeing_only_target_emits_null_once` y `test_ac1_queue_freeing_*` |

## AC8 · Builds (`tools/export.sh`)

Log de exportación: [export.log](export.log) (import + export sin `ERROR`, código 0 en ambos).

| Plataforma | Export | Tamaño | Ejecución | Resultado |
|---|---|---|---|---|
| Linux x86_64 | OK | 71 MB (`pulpasa.x86_64` 70 MB + `.pck` 845 KB) | headless `--quit-after 300`: 2,25 s, código 0, sin `ERROR` ([log](linux-headless.log)). Ventana real (Vulkan, Forward+) bajo `xvfb-run` 1280×720 movida con `xdotool`: menú → Enter → nivel → Esc → pausa ([log](linux-xvfb.log)), y partida completa de 180 s → game over → Enter (Reintentar) ([log](linux-xvfb-round.log)). Solo el aviso conocido de X11 `wd.xic` | **pasa** AC1, AC2, AC5 (a ojo), AC6 en el build; AC3/AC4/AC7 por los tests del proyecto (mismo `.pck`, sin código específico de plataforma) |
| Windows x86_64 | OK | 106 MB (`pulpasa.exe` 105 MB + `.pck` 845 KB, mismo `.pck` que Linux) | **no verificable**: no hay Windows ni Wine en la máquina de QA | Pendiente: repetir la tabla de `docs/design/m0-gate.md` en Windows si hay máquina disponible |

Capturas del build de Linux:
- [ac1-linux-build-menu-2s.png](ac1-linux-build-menu-2s.png): menú a los 2 s del arranque.
- [ac2-linux-build-level.png](ac2-linux-build-level.png), [ac8-linux-build-level.png](ac8-linux-build-level.png): nivel tras «Jugar» (4 tickets, 4 puestos, cápsula del jugador, HUD).
- [ac8-linux-build-pause.png](ac8-linux-build-pause.png): pausa con Esc.
- [ac6-linux-build-game-over.png](ac6-linux-build-game-over.png): game over a los 180 s.
- [ac6-linux-build-retry.png](ac6-linux-build-retry.png): 3 s después de Reintentar: comandas nuevas y reloj en 178,0 s.

No se han usado las capturas del MCP de Godot: el build exportado es mejor evidencia de AC8 que el
proyecto lanzado desde el editor, y `xdotool` sí genera input real (`_input`/`_unhandled_input`).

## Lo que no se ha podido comprobar
- Windows: ejecución del build (ver arriba).
- AC3/AC4 jugados a mano en el build: sin puente de input no se automatiza el recorrido; cubierto
  por los tests sobre el mismo proyecto y por la puerta humana (`docs/design/m0-gate.md`).
- Comparación con Unity: es la puerta humana de M0 (`docs/design/m0-gate.md`).

## Observaciones (no bloquean)
- El menú dice «Jugar» con el rótulo «Individual · Un personaje»; la feature (AC2) y Unity hablan
  del botón «Individual». Equivalente funcional; anotado en la fila F2/F3 de `m0-gate.md`.
- El jugador es una cápsula (PUL-013 bloqueada); anotado en la fila F3.
