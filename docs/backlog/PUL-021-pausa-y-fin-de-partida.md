---
id: PUL-021
title: Crear el menú de pausa y la pantalla de fin de partida
status: ready
milestone: M0
role: ui-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/Game/PauseManager.cs, Assets/Scripts/UI/PauseMenuController.cs, Assets/Scripts/UI/GameOverUI.cs, Assets/Prefabs/UI/**]
owns: [godot/ui/menus/pause_menu.tscn, godot/ui/menus/pause_menu.gd, godot/ui/menus/pause_menu.gd.uid, godot/ui/menus/game_over.tscn, godot/ui/menus/game_over.gd, godot/ui/menus/game_over.gd.uid, godot/ui/menus/menu_panel.tscn, godot/ui/menus/menu_panel.gd, godot/ui/menus/menu_panel.gd.uid, godot/ui/menus/sandbox/**, godot/tests/integration/test_pause_menu.gd, godot/tests/integration/test_pause_menu.gd.uid, godot/tests/integration/test_game_over.gd, godot/tests/integration/test_game_over.gd.uid, docs/evidence/PUL-021/**]
touches_scenes: [godot/ui/menus/pause_menu.tscn, godot/ui/menus/game_over.tscn, godot/ui/menus/menu_panel.tscn]
---

## Target
Fase 7 de M0, `scene-tree.md` §4 (pausa, game over, panel común). Overlays dentro del nivel (ADR-003 §7).

## Change
1. `ui/menus/menu_panel.tscn`: panel y estilo comunes (sustituye `PanelPauseBase.prefab`).
2. `pause_menu.tscn` (`process_mode = ALWAYS`): la acción `pause` alterna `GameState.set_paused()`;
   se muestra/oculta con `pause_changed`; botones Reanudar y Salir (→ `GameState.go_to_main_menu()`).
   Sin deshabilitar al jugador a mano ni flags paralelos (B13).
3. `game_over.tscn`: oculto hasta `round_finished(result)`; muestra el rendimiento del `RoundResult`
   (texto y ratio como `GameOverUI`, umbrales en datos desde PUL-006); botones Reintentar
   (recarga la escena actual vía `GameState`) y Salir. Sin sondear estado cada frame.
4. Sandbox en `ui/menus/sandbox/` para pruebas y capturas.

## Constraints
- Capa común (ADR-003 §0): nada de tipos 3D en `ui/`. La UI escucha señales de `EventBus` y llama métodos de los autoloads; nunca consulta sistemas por ruta (B16). Sin contadores propios (B2).
- Navegable con teclado y mando: `Button` con foco nativo, `focus_neighbor_*`, `grab_focus()` al abrir y acciones `ui_*` (ADR-004; sustituye B13/B14).
- Textos con `tr()` y claves (preparado para gallego, Should de la alpha). Tema `ui/theme/default_theme.tres` (PUL-009).
- `.tscn` con un script tipado propio o el editor; las tools headless del MCP fallan por `untyped_declaration=error`. No inventes uid.
- Si `GameState` necesita un método nuevo (p. ej. `restart_level()`), no lo añadas: pregunta al coordinador.

## Acceptance
- [ ] AC1 `pause` abre el menú, congela el árbol y da foco a Reanudar; Reanudar o `pause` de nuevo lo cierran y descongelan → `test_pause_menu.gd`.
- [ ] AC2 Tras `round_finished` el game over aparece una vez con el texto de rendimiento correcto para 0,5 / 1,5 / 2,5 / 3,5 cajas/min y foco en Reintentar → `test_game_over.gd`.
- [ ] AC3 Todo el flujo se puede manejar solo con `ui_*` (teclado o mando) → tests.
- [ ] AC4 Capturas de pausa y game over en `docs/evidence/PUL-021/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
