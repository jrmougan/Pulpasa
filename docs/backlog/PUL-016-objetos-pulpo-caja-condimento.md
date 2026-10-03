---
id: PUL-016
title: Crear los objetos jugables - pulpo, caja y condimento
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-015]
orca_task: null
unity_sources: [Assets/Scripts/Game/Ingredient.cs, Assets/Scripts/Game/Box.cs, Assets/Scripts/Game/SeasoningItem.cs, Assets/Scripts/UI/SimpleProgressBar.cs, Assets/Scripts/UI/FaceToCamera.cs, Assets/Prefabs/Ingredients/**, Assets/Prefabs/Packaging/**, Assets/Animations/Packaging/**]
owns: [godot/entities/items/**, godot/ui/widgets/**, godot/tests/integration/test_octopus.gd, godot/tests/integration/test_octopus.gd.uid, godot/tests/integration/test_box.gd, godot/tests/integration/test_box.gd.uid, godot/tests/integration/test_seasoning.gd, godot/tests/integration/test_seasoning.gd.uid, godot/tests/integration/test_items_contract.gd, godot/tests/integration/test_items_contract.gd.uid, docs/evidence/PUL-016/**]
touches_scenes: [godot/entities/items/octopus.tscn, godot/entities/items/box.tscn, godot/entities/items/seasoning.tscn, godot/ui/widgets/world_progress_bar.tscn]
---

## Target
Fase 6 de M0, objetos (`scene-tree.md` §3 `entities/items/`). Flujo de cocina en `docs/design/roadmap.md`.

## Change
1. `ui/widgets/world_progress_bar.tscn`: barra 3D en billboard (sustituye `SimpleProgressBar` + `FaceToCamera`).
2. `octopus.tscn` + `ingredient.gd` (`class_name Ingredient`): estado crudo/cocido (material de
   cocido desde datos, no color literal), cantidad restante 100, `take(amount)`; se destruye al
   agotarse **sin depender de la barra** (B9). Cumple el contrato `pickable`.
3. `box.tscn` + `box.gd` (`class_name Box`, `@export data: BoxData`): `interactable` y
   `pickable`. Si el actor lleva pulpo **cocido**, cada pulsación llena `fill_per_press` y gasta
   pulpo (D1/D13: corte por pulsación sobre la caja). Si lleva un condimento y la caja está llena,
   lo aplica una vez por tipo. Expone un `BoxContents` (core) para la entrega. Animación abrir/cerrar
   recreada en `AnimationPlayer`. Sin NRE de barra (B8).
4. `seasoning.tscn` + `seasoning_item.gd` (`@export data: SeasoningData`): `pickable`; una sola
   ruta de condimentar (la de la caja, B6); el bote no se consume.
5. Sonidos de PUL-009 (corte, molinillo) donde correspondan.

## Constraints
- `.tscn` con el MCP o el editor; no inventes uid. Escenas pequeñas: una por entidad (ADR-003 §1).
- La lógica contextual vive en el **receptor** (ADR-003 §4): la caja decide si el objeto en la mano la llena o la condimenta.
- Datos de balance solo en `.tres` (ADR-001). Paridad M0: valores de Unity; D8–D10 son M1.
- Usa placeholders de PUL-008 como `Model` y `Highlightable` de PUL-015.

## Acceptance
- [ ] AC1 Con pulpo cocido en la mano, N pulsaciones sobre una caja S/M/L la llenan en 5/10/20 pulsaciones y gastan pulpo; con pulpo crudo no hace nada → `test_box.gd`.
- [ ] AC2 Con la caja llena, cada condimento se aplica una vez; repetir el mismo no duplica; con la caja sin llenar no se aplica → `test_box.gd`.
- [ ] AC3 El pulpo se libera al agotarse aunque no tenga barra (B9) → `test_octopus.gd`.
- [ ] AC4 Los tres objetos cumplen el contrato `pickable`/`interactable` (InteractionContract) → `test_items_contract.gd`.
- [ ] AC5 Captura de una caja llenándose y condimentada en el sandbox, en `docs/evidence/PUL-016/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
