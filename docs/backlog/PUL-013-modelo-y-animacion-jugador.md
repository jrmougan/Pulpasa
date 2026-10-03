---
id: PUL-013
title: Sustituir la cápsula por el modelo del personaje con AnimationTree
status: blocked
milestone: M0
role: asset-pipeline
deps: [PUL-012]
orca_task: null
unity_sources: [Assets/Art/Characters/freakycapucha.fbx, Assets/Animations/Character/**, Assets/Animations/Character/Player.controller]
owns: [godot/assets/models/characters/**, godot/entities/player/player.tscn, godot/entities/player/player_animation.gd, godot/tests/integration/test_player_animation.gd, docs/evidence/PUL-013/**]
touches_scenes: [godot/entities/player/player.tscn]
---

**Bloqueada:** `freakycapucha.fbx` está en «Pendientes» de `docs/assets/licenses.md` (D16). Se
desbloquea cuando el responsable confirme que es propio, o cuando haya otro modelo con licencia.

## Target
Fase 4 de M0. `scene-tree.md` §3: `Model` + `%AnimationTree`.

## Change
1. Importa `freakycapucha.fbx` con sus clips (Idle, Walk, Pick, WalkWhileHolding) y recrea `CustomIdle.anim` si es posible.
2. `AnimationTree` con StateMachine equivalente a `Player.controller` (`speed`, `is_holding`).
3. Sustituye la cápsula de `player.tscn`, rotado 180° en Y si mira hacia atrás.

## Acceptance
- [ ] AC1 Al moverse pasa a Walk y al parar a Idle; con objeto en la mano usa WalkWhileHolding → `test_player_animation.gd`.
- [ ] AC2 Escala y frente correctos frente a `scale_check.tscn`; captura en `docs/evidence/PUL-013/`.
- [ ] AC3 `tools/verify.sh` en verde.

## Plan

## Evidence
