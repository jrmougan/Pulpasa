---
id: PUL-012
title: Montar la escena del jugador con movimiento, HoldComponent y cámara
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-011, PUL-008]
orca_task: null
unity_sources: [Assets/Scripts/Characters/PlayerController.cs, Assets/Scripts/Characters/PlayerHoldSystem.cs, Assets/Prefabs/Characters/Player.prefab, Assets/Scenes/Levels/Level_01.unity]
owns: [godot/entities/player/**, godot/components/pickable_contract.gd, godot/components/pickable_contract.gd.uid, godot/entities/camera/**, godot/components/hold_component.gd, godot/components/hold_component.gd.uid, godot/scenes/sandbox/player_sandbox.tscn, godot/scenes/sandbox/player_sandbox.tscn.uid, godot/tests/integration/test_player.gd, godot/tests/integration/test_player.gd.uid, godot/tests/integration/test_hold_component.gd, godot/tests/integration/test_hold_component.gd.uid, docs/evidence/PUL-012/**]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/camera/camera_rig.tscn, godot/scenes/sandbox/player_sandbox.tscn]
---

## Target
Fase 4 de M0, **capa específica 3D** (`scene-tree.md` §3 `player.tscn`, ADR-003 §3).

## Change
1. `entities/player/player.tscn` + `player.gd` (`class_name Player`, `CharacterBody3D`, capa
   `player`): cápsula placeholder de PUL-008 como `Model` (los modelos con licencia sin confirmar
   no se usan, D16), `%HoldPoint`, `%Control` (ControlComponent), `%HoldComponent`.
   Movimiento con `PlayerInput.get_move_vector()` mapeado al plano XZ según la cámara, 5 m/s y giro
   suave (×20) desde `PlayerConfig`; se bloquea fuera de ronda escuchando `EventBus`
   (`round_started` / `round_finished`), no consultando sistemas.
   Sin `AnimationTree` todavía (PUL-013), pero deja el hueco y las variables `speed`/`is_holding`.
   Sin `InteractionDetector` ni `InteractionComponent` (fase 5).
2. `components/hold_component.gd` (`extends Holder`): reparenta el objeto al `HoldPoint`,
   lo congela y lo pasa a la capa `held`; al soltar lo coloca 0,6 m delante y 0,6 m arriba, en el
   nodo `items_root` (ADR-003 §6). Llama siempre `on_picked_up` / `on_dropped` (B4) y valida antes
   de mutar (B5).
3. `entities/camera/camera_rig.tscn`: `Camera3D` ortográfica con los parámetros de
   `scale_check.tscn` (PUL-008).
4. `scenes/sandbox/player_sandbox.tscn`: suelo, cámara, jugador y un objeto `pickable` de prueba
   (puede ser un `RigidBody3D` con script mínimo que cumpla el contrato) para probar a mano y con el MCP.

## Constraints
- No portes los bugs de `PlayerHoldSystem` (B4, B5) ni el doble detector (B7).
- Datos de movimiento solo desde `PlayerConfig.tres`.
- `.tscn` con el MCP o el editor; no inventes uid.

## Acceptance
- [ ] AC1 Con `p1_move_right` pulsado 1 s, el jugador se desplaza 5 m ± 5 % en la dirección de pantalla correcta y mira hacia ella → `test_player.gd`.
- [ ] AC2 Fuera de ronda (antes de `round_started` o tras `round_finished`) el jugador no se mueve → `test_player.gd`.
- [ ] AC3 `pick_up` de un objeto pickable: queda bajo `HoldPoint`, capa `held`, `is_held = true`, `on_picked_up` llamado una vez; `drop` lo deja 0,6 m delante y 0,6 m arriba bajo `items_root` con `on_dropped` una vez → `test_hold_component.gd`.
- [ ] AC4 `pick_up` de algo que no es pickable, o que no cumple el contrato completo (`on_picked_up`, `on_dropped`, `is_held`), no cambia el estado ni emite señales (B5). Extrae la validación a un helper común reutilizable (p. ej. `static func Holder.is_valid_pickable(item)` no está en owns: ponlo en `components/pickable_contract.gd`, común) → `test_hold_component.gd`.
- [ ] AC5 Captura del sandbox con el jugador llevando el objeto, vía MCP (`simulate_input`), en `docs/evidence/PUL-012/`. `tools/verify.sh` en verde.

## Plan

## Evidence
