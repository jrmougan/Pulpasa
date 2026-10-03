---
id: PUL-023
title: Pulir la UI de la fase 7 con los hallazgos de revisión
status: done
milestone: M0
role: ui-engineer
deps: []
orca_task: task_8bfc4d097b07
unity_sources: [Assets/Scripts/UI/ProductivityUIDisplay.cs, Assets/Scripts/UI/MainMenu.cs, Assets/Scripts/Game/PauseManager.cs]
owns: [godot/ui/hud/**, godot/ui/tickets/**, godot/ui/menus/**, godot/ui/sandbox/**, godot/ui/theme/**, godot/autoload/game_state.gd, godot/resources/recipe_data.gd, godot/resources/seasoning_data.gd, godot/data/recipes/**, godot/data/seasonings/**, godot/tests/unit/test_game_state.gd, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_hud.gd, godot/tests/integration/test_order_tickets.gd, godot/tests/integration/test_pause_menu.gd, godot/tests/integration/test_game_over.gd, godot/tests/integration/test_main_menu.gd, docs/arch/ADR-002-eventbus-autoloads.md, docs/evidence/PUL-023/**]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn, godot/ui/menus/game_over.tscn, godot/ui/sandbox/hud_sandbox.tscn]
---

## Target
Hallazgos no bloqueantes de las revisiones de PUL-020, PUL-021 y PUL-022 (ya fusionadas).

## Change
1. HUD: escucha `pause_changed` y se atenúa en pausa (`signals.md`: receptor `hud.gd`).
2. HUD, paridad con `ProductivityUIDisplay.cs:25-30`: tiempo como `{F1}s` y ratio `{F2}` en verde si > 1 y
   en rojo si no; los colores, en el tema.
3. Tickets: clave de `tr()` explícita en `RecipeData`/`SeasoningData` (no derivada del nombre de fichero) y
   parámetros tipados en `ticket_entry.gd`.
4. Escenas: quita los overrides de `script`/`theme` que repiten la escena base en instancias (`hud_sandbox.tscn`,
   `order_ticket.tscn`, `pause_menu.tscn`, `game_over.tscn`). En `main_menu.tscn`: renombra `@Control@2` a
   `Spacer` sin unique, preset de anclas 15, vecinos de foco izquierda/derecha vacíos, y los StyleBox al
   `default_theme.tres` como variaciones de tipo reutilizables por pausa y game over.
5. `GameState.restart_level()` delega en `start_level(mode)` (el reparto de mandos de M2 irá ahí) y se
   documenta en ADR-002 §Lista de autoloads. `test_game_state.gd:78-83`: aserción incondicional (con
   escena inyectada o `ERR_UNCONFIGURED` explícito).
6. Pausa: `ui_cancel` (B del mando) también reanuda.
7. `test_main_menu.gd`: dos `ui_accept` seguidos → `start_level` una sola vez.

## Constraints
- Sin cambios de comportamiento fuera de estos puntos. Capa común, `tr()`, navegación `ui_*` (ADR-003/004).
- `.tscn` con script tipado o editor; no inventes uid.

## Acceptance
- [ ] AC1 Cada punto 1–7 tiene test o evidencia (captura del HUD en pausa y en colores en `docs/evidence/PUL-023/`).
- [ ] AC2 `tools/verify.sh` en verde y `check_owns` limpio.

## Plan

## Evidence
