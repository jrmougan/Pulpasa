---
id: PUL-011
title: Implementar los componentes comunes del jugador - Control, Holder y PlayerInput
status: review
milestone: M0
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/Characters/PlayerController.cs, Assets/Scripts/Characters/PlayerHoldSystem.cs, Assets/Scripts/Interfaces/IPickable.cs, Assets/PlayerInputActions.inputactions]
owns: [godot/components/control_component.gd, godot/components/control_component.gd.uid, godot/components/holder.gd, godot/components/holder.gd.uid, godot/core/player_input.gd, godot/core/player_input.gd.uid, godot/resources/player_config.gd, godot/resources/player_config.gd.uid, godot/resources/input_config.gd, godot/resources/input_config.gd.uid, godot/data/config/player_config.tres, godot/data/config/input_config.tres, godot/project.godot, godot/tests/unit/test_control_component.gd, godot/tests/unit/test_control_component.gd.uid, godot/tests/unit/test_holder.gd, godot/tests/unit/test_holder.gd.uid, godot/tests/unit/test_player_input.gd, godot/tests/unit/test_player_input.gd.uid, godot/tests/unit/test_physics_layers.gd, godot/tests/unit/test_physics_layers.gd.uid, godot/tests/helpers/**]
touches_scenes: []
---

## Target
Fase 4 de M0, **capa común** (ADR-003 §0 y §3, ADR-004). Nada de 3D en estos ficheros.

## Change
1. `core/player_input.gd` (`class_name PlayerInput`, `RefCounted`) según ADR-004: cachea los
   `StringName` de las acciones de un jugador (`p1_*`), `get_move_vector() -> Vector2` con la zona
   muerta de `InputConfig`, `is_interact_just_pressed()`.
2. `components/control_component.gd` (`class_name ControlComponent`, `extends Node`):
   `player_index`, `controlled_by`, señal `control_changed(controlled_by)`, crea el `PlayerInput`
   del jugador que lo controla. M0: `controlled_by = 1` fijo (el cambio de personaje es M2).
3. `components/holder.gd` (`class_name Holder`, `extends Node`, base abstracta): `get_held_item`,
   `can_hold`, `pick_up`, `drop`, señales `item_picked_up` / `item_dropped`; los métodos base hacen
   `push_error`.
4. `resources/player_config.gd` + `data/config/player_config.tres` (velocidad 5, giro 20, radio
   del detector 2,2, desplazamiento al soltar 0,6 delante y 0,6 arriba: valores de Unity) y
   `resources/input_config.gd` + `input_config.tres` (zona muerta 0,2; cooldown de cambio 0,2).
5. Nombres de capas de física en `project.godot` (`layer_names/3d_physics`, ADR-003 §5:
   world, player, interactable, held, delivery_zone). Toca solo esa sección.

## Constraints
- Capa común: sin `Node3D`, `Vector3`, cuerpos físicos ni clases específicas (`Player`,
  `HoldComponent`). Los tests usan dobles (`Node` simples, un `Holder` de prueba) y no cargan escenas.
- No portes B4/B5: `Holder` documenta que el único camino es `on_picked_up`/`on_dropped` y que se
  valida antes de mutar.

## Acceptance
- [ ] AC1 `PlayerInput` para J1 devuelve `Vector2.ZERO` por debajo de la zona muerta y el vector normalizado por encima, usando `Input.action_press` simulado → `test_player_input.gd`.
- [ ] AC2 `ControlComponent` emite `control_changed` una vez al cambiar `controlled_by` y expone el `PlayerInput` del jugador correcto → `test_control_component.gd`.
- [ ] AC3 Los métodos base de `Holder` fallan con `push_error` y un `Holder` de prueba cumple el contrato (señales y orden validar → mutar) → `test_holder.gd`.
- [ ] AC4 Los 5 nombres de capa existen en `project.godot` con su número → `test_physics_layers.gd`.
- [ ] AC5 Ningún fichero de esta ficha referencia tipos 3D/2D (test que carga los scripts sin escenas) y `tools/verify.sh` en verde.

## Plan
- AC1 `test_player_input.gd` · AC2 `test_control_component.gd` · AC3 `test_holder.gd` (dobles `tests/helpers/fake_holder.gd`, `fake_pickable.gd`) · AC4 y AC5 `test_physics_layers.gd` (AC5: regex sobre el código fuente de los 5 scripts comunes, sin cargar escenas).
- Sin señales nuevas de EventBus; `ControlComponent.control_changed` y `Holder.item_*` son locales.
- Fuera de `owns`: `tests/unit/test_data_integrity.gd` contaba 15 `.tres` y ahora hay 17 (los dos de config); ajustado el número.

## Evidence
`tools/verify.sh` → `✓ verify OK` (gdformat, gdlint, import, GUT, smoke).
GUT: Scripts 17 · Tests 133 · Passing 133 · Failing 0 · Asserts 606 · "All tests passed!"
