---
id: PUL-015
title: Montar detector 3D, resaltado por shader y slots con ancla
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-012, PUL-014]
orca_task: null
unity_sources: [Assets/Scripts/Interaction/**, Assets/Scripts/Game/InteractableSlot.cs, Assets/Art/Materials/HighlightTexture.mat]
owns: [godot/components/interaction_detector.gd, godot/components/interaction_detector.gd.uid, godot/components/highlightable.gd, godot/components/highlightable.gd.uid, godot/shaders/**, godot/entities/stations/slot.tscn, godot/entities/stations/slot.gd, godot/entities/stations/slot.gd.uid, godot/entities/player/player.tscn, godot/scenes/sandbox/**, godot/tests/integration/test_interaction_detector.gd, godot/tests/integration/test_interaction_detector.gd.uid, godot/tests/integration/test_slot.gd, godot/tests/integration/test_slot.gd.uid, docs/evidence/PUL-015/**]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/stations/slot.tscn, godot/scenes/sandbox/player_sandbox.tscn]
---

## Target
Fase 5 de M0, **capa específica 3D** (`scene-tree.md` §3; ADR-003 §3).

## Change
1. `components/interaction_detector.gd` (`Area3D`, máscara `interactable`, radio de `PlayerConfig`):
   delega en `InteractionScoring` y emite `target_changed(target)`. Uno por jugador (B7).
2. `components/highlightable.gd` + `shaders/highlight_outline.gdshader` (inverted hull en
   `material_overlay`): se activa cuando el objeto es el objetivo. Sin `EmissionHighlighter` (B3).
3. `entities/stations/slot.{tscn,gd}`: mesa/hueco que guarda un objeto alineado por su `%AnchorPoint`
   (sustituye `InteractableSlot` + `SnappingHelper`).
4. Añade `%InteractionDetector` e `%InteractionComponent` a `player.tscn` y un par de slots y objetos
   al sandbox.

## Constraints
- Reutiliza `InteractionScoring`, `InteractionComponent` y el contrato de PUL-014; no dupliques lógica.
- `.tscn` vía MCP o editor; no inventes uid.

## Acceptance
- [ ] AC1 En el sandbox, el detector selecciona el objetivo que dicta `InteractionScoring` y lo resalta; al girar, cambia el resaltado sin dejar dos objetos resaltados → `test_interaction_detector.gd`.
- [ ] AC2 Dejar un objeto en un slot lo alinea a su `%AnchorPoint`; cogerlo de nuevo libera el slot → `test_slot.gd`.
- [ ] AC3 Captura del sandbox con un objeto resaltado y otro en un slot, vía MCP con `simulate_input`, en `docs/evidence/PUL-015/`.
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` sin rutas fuera.

## Plan

## Evidence
