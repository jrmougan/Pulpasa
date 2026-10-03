---
id: PUL-004
title: Montar el esqueleto de M0 - EventBus, GameState e InputMap
status: review
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
- [x] AC1 `EventBus` declara las 13 señales de bus de signals.md con las firmas exactas → `test_event_bus.gd`.
- [x] AC2 `GameState.set_paused(true)` pone `get_tree().paused` y emite `pause_changed(true)` una vez; `false` lo revierte → `test_game_state.gd`.
- [x] AC3 El InputMap contiene todas las acciones de ADR-004 §1 con sus eventos de teclado y mando → `test_input_map.gd`.
- [x] AC4 `tools/verify.sh` en verde y el smoke run arranca con los dos autoloads sin errores.

## Plan
1. Tests primero (TDD): `test_event_bus.gd` (AC1), `test_game_state.gd` (AC2), `test_input_map.gd` (AC3).
2. `core/game_mode.gd`, `autoload/event_bus.gd`, `autoload/game_state.gd`.
3. `project.godot`: `[autoload]` (EventBus, GameState) e `[input]` de ADR-004 §1.
4. `tools/verify.sh`.

## Evidence
`tools/verify.sh` en verde (2026-10-03): gdformat/gdlint OK, import sin errores, smoke OK
(`Pulpasa boot OK — Godot 4.7.2-stable` con los dos autoloads cargados). GUT:

```
Scripts               4
Tests                22
Passing Tests        22
Asserts             157
---- All tests passed! ----
```

Notas para revisión:
- **Señales: el catálogo tiene 14, no 13.** `signals.md` §2 lista 4 de ronda, 6 de comandas
  (`orders_reset`, `order_generated`, `order_completed`, `delivery_rejected`,
  `order_patience_changed`, `order_expired`) y 4 de sesión. Se declaran las 14 (manda el
  contrato); el test compara contra las 14, con nombres, nº de args, nombres de args y tipos.
- **Tipos provisionales (PUL-006):** `round_finished(result: RefCounted)` (`RoundResult`) y
  `order_generated`, `order_completed`, `order_expired` (`order: RefCounted`, `ActiveOrder`),
  marcados con `# TODO(PUL-006)`. El test ya admite `ActiveOrder`/`RoundResult`, así que PUL-006
  solo cambia el tipo en `event_bus.gd`.
- Las señales llevan `@warning_ignore("unused_signal")`: el bus las declara y otros las emiten.
- `GameState`: `set_bus(bus)` para inyectar un bus en tests (ADR-002 regla 8); `start_level(mode)`
  y `go_to_main_menu()` devuelven `Error` y, si la escena no existe, `push_warning` +
  `ERR_FILE_NOT_FOUND` sin cambiar de escena. Rutas previstas (ADR-001/scene-tree):
  `res://scenes/levels/level_01.tscn` y `res://ui/menus/main_menu.tscn`. Ambas despausan antes de
  cambiar. Reparto de mandos (M2) solo como comentarios en `_ready` y `start_level`.
- InputMap: teclado de jugador con `physical_keycode` (WASD/E/Q independientes del layout),
  `device = -1`; mando plantilla `device = 0` (J1) / `1` (J2) con botón de cruceta + eje del stick
  izquierdo para mover, A (0) interactuar, Y (3) `p1_switch`; `pause` = Esc + Start (6) con
  `device = -1`. `deadzone` 0,5 (valor por defecto de Godot): la de 0,2 de `InputConfig.tres` se
  aplica en tiempo de ejecución (ADR-004, fuera de esta ficha).
- **`ui_accept`/`ui_cancel` sobrescritos:** en Godot 4.7 sus valores por defecto no traen mando, y
  ADR-004 §1 pide A/B. Se redeclaran con sus teclas por defecto (Intro, Intro del teclado numérico,
  Espacio / Esc) + botón A (0) / B (1) con `device = -1`. Las direcciones `ui_*` ya traen cruceta
  y stick por defecto y no se tocan.

