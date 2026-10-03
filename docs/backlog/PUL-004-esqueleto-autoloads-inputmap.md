---
id: PUL-004
title: Montar el esqueleto de M0 - EventBus, GameState e InputMap
status: ready
milestone: M0
role: godot-architect
deps: []
orca_task: null
unity_sources: [Assets/Scripts/Architecture/**, Assets/Scripts/Game/PauseManager.cs, Assets/PlayerInputActions.inputactions]
owns: [godot/project.godot, godot/autoload/event_bus.gd, godot/autoload/event_bus.gd.uid, godot/autoload/game_state.gd, godot/autoload/game_state.gd.uid, godot/core/game_mode.gd, godot/core/game_mode.gd.uid, godot/tests/unit/test_event_bus.gd, godot/tests/unit/test_event_bus.gd.uid, godot/tests/unit/test_game_state.gd, godot/tests/unit/test_game_state.gd.uid, godot/tests/unit/test_input_map.gd, godot/tests/unit/test_input_map.gd.uid, godot/tests/helpers/**]
touches_scenes: []
---

## Target
Fase 0 de M0 (`docs/design/roadmap.md`). Capa común de ADR-002 y ADR-004: `godot/project.godot`,
`godot/autoload/`, `godot/core/game_mode.gd`, tests unitarios.

## Change
1. `autoload/event_bus.gd`: declara **todas** las señales de bus de `docs/arch/signals.md` con su
   firma tipada exacta. Sin estado ni lógica. Si alguna firma usa un tipo de `core/` que aún no existe
   (`ActiveOrder`, `RoundResult`), tipa ese parámetro como `RefCounted` con un comentario
   `# TODO(PUL-006): ActiveOrder` y avísalo en Evidence: PUL-006 ajustará el tipo.
2. `core/game_mode.gd` (`class_name GameMode`) con el enum `Mode { SINGLE, COOP_2P }`.
3. `autoload/game_state.gd`: modo de juego, `set_paused(bool)` → `get_tree().paused` + `pause_changed`,
   `start_level(mode)` y `go_to_main_menu()` (pueden apuntar a escenas que aún no existen: no
   fallar en tests; documenta las rutas previstas según ADR-001). `process_mode = ALWAYS`.
   El reparto de mandos (`DeviceAssignment`) es M2: deja solo un punto de extensión comentado.
4. `project.godot`: registra los autoloads `EventBus` y `GameState` en el orden de ADR-002
   (`OrderService` y `RoundManager` los añade PUL-007) y el **InputMap completo** de ADR-004 §1
   (acciones `p1_*`, `p2_*` y globales, con teclado y mando), aunque M0 solo use J1.
5. Tests GUT: el bus declara exactamente las señales del catálogo (nombres y nº de argumentos);
   pausa congela y reanuda; InputMap contiene todas las acciones con sus bindings de ADR-004.

## Constraints
- Capa común: sin `Node3D`, `Vector3` ni tipos 3D en estos ficheros (ADR-002 regla 10).
- Autoloads sin `class_name` (ADR-001); los tests los instancian con `preload(...).new()`.
- No crear escenas. No tocar `resources/`, `data/` ni `core/` salvo `game_mode.gd`.
- Edita `project.godot` con cuidado: conserva `directory_rules`, GUT y el resto de ajustes.

## Acceptance
- [ ] AC1 `EventBus` declara las 13 señales de bus de signals.md con las firmas exactas → `test_event_bus.gd`.
- [ ] AC2 `GameState.set_paused(true)` pone `get_tree().paused` y emite `pause_changed(true)` una vez; `false` lo revierte → `test_game_state.gd`.
- [ ] AC3 El InputMap contiene todas las acciones de ADR-004 §1 con sus eventos de teclado y mando → `test_input_map.gd`.
- [ ] AC4 `tools/verify.sh` en verde y el smoke run arranca con los dos autoloads sin errores.

## Plan

## Evidence
