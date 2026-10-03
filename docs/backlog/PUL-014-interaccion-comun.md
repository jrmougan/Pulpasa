---
id: PUL-014
title: Implementar la interacción común - InteractionScoring, InteractionComponent y contrato
status: review
milestone: M0
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/Interaction/InteractionDetector.cs, Assets/Scripts/Characters/PlayerInteractionController.cs, Assets/Scripts/Interfaces/IInteractable.cs, Assets/Scripts/Interfaces/IPickable.cs]
owns: [godot/core/interaction_scoring.gd, godot/core/interaction_scoring.gd.uid, godot/components/interaction_component.gd, godot/components/interaction_component.gd.uid, godot/components/interaction_contract.gd, godot/components/interaction_contract.gd.uid, godot/tests/unit/test_interaction_scoring.gd, godot/tests/unit/test_interaction_scoring.gd.uid, godot/tests/unit/test_interaction_component.gd, godot/tests/unit/test_interaction_component.gd.uid, godot/tests/unit/test_interaction_contract.gd, godot/tests/unit/test_interaction_contract.gd.uid, godot/tests/helpers/**]
touches_scenes: []
---

## Target
Fase 5 de M0, **capa común** (ADR-003 §0, §3 y §4).

## Change
1. `core/interaction_scoring.gd` (`class_name InteractionScoring`, funciones `static`, `Vector2` del
   plano del suelo): reproduce `InteractionDetector.cs` del prototipo — cono de 30° salvo por debajo
   de 0,7 m, puntuación `dot * 2 + 1 / dist`, prioridad a los cogibles cuando la mano está vacía y
   +1 a la cocina (como el tag `Kitchen`). Los números (ángulo, distancia mínima, bonus) llegan como
   parámetros desde `PlayerConfig` o un `Resource`, no literales.
2. `components/interaction_contract.gd`: comprobaciones del contrato de ADR-003 §4 (grupo
   `interactable` → `can_interact`/`interact`; grupo `pickable` → `on_picked_up`/`on_dropped`/`is_held`).
   Si PUL-012 ya creó `components/pickable_contract.gd`, reutilízalo en vez de duplicar.
3. `components/interaction_component.gd` (`class_name InteractionComponent`, `extends Node`):
   `@export control`, `holder`, `detector` (conectado por nombre a `target_changed`). Al pulsar
   `p<n>_interact` llama `interact(self)` del objetivo si `can_interact`; si nada consume la
   pulsación y lleva algo, `holder.drop()`. La lógica contextual (cortar, condimentar) **no** va
   aquí: va en el receptor (ADR-003 §4, inventario fila `PlayerInteractionController`).

## Constraints
- Capa común: sin tipos 3D/2D ni clases específicas; tests con dobles, sin escenas.
- No portes B7 (un solo detector) ni B18 (`is_instance_valid`).

## Acceptance
- [ ] AC1 `InteractionScoring` elige el mismo objetivo que el prototipo en casos tabulados: delante vs. detrás, cerca vs. lejos, fuera del cono pero a < 0,7 m, cogible vs. no cogible con mano vacía y llena, bonus de cocina → `test_interaction_scoring.gd`.
- [ ] AC2 `InteractionComponent`: con objetivo que acepta, llama `interact` una vez y no suelta; con objetivo que rechaza y mano llena, suelta; sin objetivo y mano vacía, no hace nada; ignora la pulsación si `controlled_by` = 0 → `test_interaction_component.gd`.
- [ ] AC3 El contrato detecta nodos de grupo sin los métodos obligatorios → `test_interaction_contract.gd`.
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` sin rutas fuera.

## Plan
- `core/interaction_scoring.gd`: `pick_best` + `score` estáticas, `Candidate` interno (cono, distancia mínima y bonus por parámetro). AC1.
- `components/interaction_contract.gd`: `violations(node)` / `scan_tree(root)`. AC3.
- `components/interaction_component.gd`: `_unhandled_input` → `interact_pressed()`. AC2.
- Dobles en `tests/helpers/` (`FakeInteractable`, `FakeDetector`, `incomplete_interactable`).

## Evidence
- `tools/verify.sh`: OK. GUT: Scripts 20, Tests 178, Passing 178, Asserts 675, All tests passed.
- Tests nuevos: `test_interaction_scoring.gd` (AC1), `test_interaction_component.gd` (AC2), `test_interaction_contract.gd` (AC3).
- Nota: `PlayerConfig` no tiene aún cono/distancia mínima/bonus de cocina (30°, 0,7 m, 1,0); `pick_best` los recibe por parámetro y el detector (ficha del detector) deberá aportarlos.
- Revisión (codex): `Candidate.distance` escalar 3D aportada por el adaptador (altura 0,8 m → `PlayerConfig` en PUL-015); `pick_best` replica `InteractionDetector.cs:99` (cogible solo devuelve si también es interactuable; si no, mejor interactuable o -1). Tests ampliados: cogible solo, doble, fallback, empates, fronteras 0,7 m y 30°.
