---
id: PUL-026
title: Ajustar el layout de HUD y tickets a Unity y cerrar los menores de level_01
status: done
milestone: M0
role: ui-engineer
deps: []
orca_task: task_7dae950412cd
unity_sources: [Assets/Scenes/Levels/Level_01.unity, Assets/Prefabs/UI/**, Assets/Scripts/UI/ProductivityUIDisplay.cs]
owns: [godot/ui/hud/**, godot/ui/tickets/**, godot/scenes/levels/level_01.tscn, godot/scenes/levels/level.gd, godot/entities/camera/camera_rig.tscn, godot/tests/integration/test_hud.gd, godot/tests/integration/test_order_tickets.gd, godot/tests/integration/test_level_01.gd, docs/evidence/PUL-026/**]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_tickets_panel.tscn, godot/ui/tickets/order_ticket.tscn, godot/scenes/levels/level_01.tscn, godot/entities/camera/camera_rig.tscn]
---

## Target
Hallazgos de la revisión de PUL-024 (fusionada). El panel de tickets de PUL-020 tapa nevera, olla y
estanterías con la cámara de juego: regresión de layout, no paridad.

## Change
1. Layout como Unity (Canvas 1920×1080 escalado a 720p): `hud.tscn` abajo a la izquierda (ScoreTimePanel
   −820/−358; anchors_preset 2); `order_tickets_panel.tscn` en la franja superior (offset_top ≈ 8, alto ≤ 250,
   HorizontalLayout desde la izquierda); `order_ticket.tscn` ≈ 236×245 (Order.prefab 354×367 a 720p).
   Debe verse la fila trasera de estaciones con la cámara de juego.
2. `level_01.tscn`: pose de la cámara como override de transform de `CameraRig` (ADR-003 §2) y pose
   neutra en `camera_rig.tscn`, para que otros niveles no hereden la de level_01.
3. `level.gd`: `push_error` si un puesto no tiene `slot_id` o si faltan `round_config` / `order_catalog`.
4. `test_level_01.gd`: AC1 con `GameState.start_level()` real esperando la escena actual; AC3 con
   `GameState.restart_level()` en vez de free+instantiate (o documentar por qué no).

## Constraints
Capa común en `ui/`; sin contadores propios; navegación y `tr()` intactos. `.tscn` con script tipado o editor.

## Acceptance
- [ ] AC1 Con la cámara de juego de `level_01`, ningún panel de UI tapa nevera, olla ni estanterías (test que proyecta sus posiciones a pantalla y comprueba que caen fuera de los rects de HUD y tickets) → `test_level_01.gd`.
- [ ] AC2 Puntos 2–4 cubiertos por tests.
- [ ] AC3 Captura nueva de `level_01` con la cámara de juego en `docs/evidence/PUL-026/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
- Captura de `level_01` con la cámara de juego: `docs/evidence/PUL-026/level_01_layout.png` (fila trasera visible).
- AC1: `test_ui_does_not_cover_fridge_pot_or_shelves_with_game_camera`; AC2: tests de cámara, `level.gd` y layout en `test_level_01.gd`.
- AC1/AC3 de PUL-024 usan `GameState.start_level()` / `restart_level()` reales (el runner de GUT no tiene `current_scene`).
- Regla de cámara (decisión del producer): `camera_rig.tscn` tiene como pose por defecto la vista de Unity, para que sandboxes y `test_player.gd` sigan igual; cada nivel fija la suya con un override de transform de `CameraRig` (`level_01.tscn` lo conserva explícito).
