---
id: PUL-016
title: Crear los objetos jugables - pulpo, caja y condimento
status: review
milestone: M0
role: gameplay-engineer
deps: [PUL-015]
orca_task: null
unity_sources: [Assets/Scripts/Game/Ingredient.cs, Assets/Scripts/Game/Box.cs, Assets/Scripts/Game/SeasoningItem.cs, Assets/Scripts/UI/SimpleProgressBar.cs, Assets/Scripts/UI/FaceToCamera.cs, Assets/Prefabs/Ingredients/**, Assets/Prefabs/Packaging/**, Assets/Animations/Packaging/**]
owns: [godot/entities/items/**, godot/components/interaction_detector.gd, godot/entities/stations/slot.gd, godot/entities/stations/slot.tscn, godot/tests/integration/test_interaction_detector.gd, godot/tests/integration/test_slot.gd, godot/tests/integration/test_box_on_slot.gd, godot/tests/integration/test_box_on_slot.gd.uid, godot/entities/player/sandbox/sandbox_pickable.gd, godot/entities/player/sandbox/sandbox_pickable.gd.uid, godot/resources/ingredient_data.gd, godot/data/ingredients/octopus.tres, godot/tests/unit/test_data_*.gd, godot/ui/widgets/**, godot/tests/integration/test_octopus.gd, godot/tests/integration/test_octopus.gd.uid, godot/tests/integration/test_box.gd, godot/tests/integration/test_box.gd.uid, godot/tests/integration/test_seasoning.gd, godot/tests/integration/test_seasoning.gd.uid, godot/tests/integration/test_items_contract.gd, godot/tests/integration/test_items_contract.gd.uid, docs/evidence/PUL-016/**]
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
- [x] AC1 Con pulpo cocido en la mano, N pulsaciones sobre una caja S/M/L la llenan en 5/10/20 pulsaciones y gastan pulpo; con pulpo crudo no hace nada → `test_box.gd`.
- [x] AC2 Con la caja llena, cada condimento se aplica una vez; repetir el mismo no duplica; con la caja sin llenar no se aplica → `test_box.gd`.
- [x] AC3 El pulpo se libera al agotarse aunque no tenga barra (B9) → `test_octopus.gd`.
- [x] AC4 Los tres objetos cumplen el contrato `pickable`/`interactable` (InteractionContract) → `test_items_contract.gd`.
- [x] AC5 Captura de una caja llenándose y condimentada en el sandbox, en `docs/evidence/PUL-016/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan
- Datos (aprobado por el coordinador): `IngredientData.amount_per_full_box = 50.0`
  (`PlayerInteractionController.cs:59`); gasto por corte = `fill_per_press * amount_per_full_box`.
  Paridad en `tests/unit/test_data_catalog.gd`.
- `ui/widgets/world_progress_bar.{tscn,gd}`: `WorldProgressBar` (`Sprite3D` billboard +
  `SubViewport` + `ProgressBar`), `set_progress(value)`.
- `entities/items/ingredient.gd` + `octopus.tscn`: `Ingredient` (`RigidBody3D`), crudo/cocido
  (`cooked_material` exportado en la escena), `remaining` 100, `take(amount)`, señal
  `amount_changed`; a 0 se libera aunque no tenga `%AmountBar` (B9).
- `entities/items/box.gd` + `box.tscn`: `Box` (`@export data: BoxData`), señales `fill_changed`,
  `seasoned`; la caja decide en `can_interact`/`interact` (ADR-003 §4): mano vacía → coger; pulpo
  cocido y caja sin llenar → corte (`%CutAudio`); condimento y caja llena → aplica una vez por tipo
  (`%SeasonAudio`); `get_contents() -> BoxContents`. `%AnimationPlayer` `box_open`/`box_close`
  sobre `%Lid`. Barra opcional y comprobada (B8).
- `entities/items/seasoning_item.gd` + `seasoning.tscn`: `SeasoningItem` (`@export data:
  SeasoningData`), solo coger/soltar; el bote no se consume (B6).
- Escenas generadas con un script `SceneTree` tipado (fuera del repo), como PUL-012/015.
- Sandbox de captura: `entities/items/sandbox/items_sandbox.tscn`.
- Tests: AC1/AC2 `test_box.gd`, AC3 `test_octopus.gd`, AC4 `test_items_contract.gd`,
  bote no consumido en `test_seasoning.gd`; AC5 captura MCP.

## Evidence
- **AC1** `tests/integration/test_box.gd`: S/M/L se llenan en exactamente 5/10/20 pulsaciones
  (no antes) y cada caja llena gasta 50 de pulpo (`fill_per_press * amount_per_full_box`); cada
  corte emite `fill_changed`; con pulpo crudo `can_interact`/`interact` son `false` y nada cambia;
  un pulpo llena dos cajas y se libera dejando la mano libre; `get_contents()` da `BoxContents`
  con caja, ingrediente (solo al llenarse, como `SetIngredient` de Unity), `COOKED` y `fill` 1.0.
  Sin `%FillBar` llena igual (B8). Mano vacía → coge la caja.
- **AC2** `test_box.gd`: caja llena + sal → una vez; repetir consume la pulsación sin duplicar
  (`seasoned` ×1); pimentón después → `[SALT, PAPRIKA]`; caja sin llenar → `false`, no aplica.
  `test_seasoning.gd`: el bote no se consume y sigue en la mano (B6).
- **AC3** `tests/integration/test_octopus.gd`: sin `%AmountBar` se libera al llegar a 0 (B9);
  `take` solo da lo que queda; `amount_changed`; barra oculta hasta el primer corte; al cocerse
  cambia `raw_material` → `cooked_material` (materiales exportados en la escena, sin colores).
- **AC4** `tests/integration/test_items_contract.gd`: las tres escenas están en `pickable` e
  `interactable`, `InteractionContract.scan_tree` vacío, `PickableContract` válido, `RigidBody3D`
  en capa `interactable`, `%Highlightable`, `%AnchorPoint` y barras `WorldProgressBar`.
- **AC5** Sandbox `entities/items/sandbox/items_sandbox.tscn` con MCP (`run_project` background +
  `simulate_input` de acciones `p1_*`): `ac5-caja-llenandose.png` (+ `-zoom`): pulpo cocido en la
  mano, caja pequeña al 60 % con barra y tapa abierta, barra de pulpo restante;
  `ac5-caja-llena-condimentada.png` (+ `-zoom`): caja llena (barra oculta), pimentón aplicado
  (`_seasonings = [paprika.tres]` en el `watch`, la 2.ª pulsación no duplica) y el bote sigue en
  la mano. `get_debug_output` sin errores. `tools/verify.sh` ✓.

Notas para revisión:
- Datos: `IngredientData.amount_per_full_box = 50.0` (aprobado por el coordinador; owns ampliado a
  `resources/ingredient_data.gd`, `data/ingredients/octopus.tres`, `tests/unit/test_data_*.gd`);
  paridad en `test_data_catalog.gd`.
- Pulpo y bote también están en `interactable` (además de `pickable`, como dice scene-tree §3):
  sin `can_interact`/`interact` no se podrían coger del suelo con `InteractionComponent`. Conviene
  ajustar scene-tree §3 (architect).
- Se añade `%CutAudio` a `box.tscn` (cut.ogg; en Unity sonaba en el jugador). Animación: la tapa
  (`%Lid`) se abre con el primer corte y se cierra al coger la caja (Unity solo la abría al dejarla
  en un `InteractableSlot`); 1 s, 0°↔140° como los `.anim`.
- `box.tscn` usa el modelo `box_medium` para las tres tallas: `BoxData` no tiene campo de modelo.
- `world_progress_bar` (`Sprite3D` + `SubViewport`) vive en `ui/widgets/` por la ficha y
  scene-tree §6, aunque es capa específica (CLAUDE.md regla 4 pide `ui/` sin tipos 3D).
- Escenas generadas con scripts tipados fuera del repo (`PackedScene.pack` + `ResourceSaver`,
  `GEN_EDIT_STATE_*` para no volcar overrides); el sandbox con una escena temporal para tener
  autoloads, borrada después.

Revisión de codex (CHANGES):
- **P1 caja sobre la mesa**: `InteractionDetector` sustituye un slot ocupado por su objeto
  guardado antes del filtro de mano llena, puntuando con la posición del slot
  (InteractionDetector.cs:57). Con mano vacía el objetivo es el objeto (para cogerlo); con mano
  llena solo si el objeto declara que acepta lo que se lleva (método opcional
  `can_receive(held) -> bool`, que implementa `Box`), así se mantiene el rechazo de objetos
  incompatibles. La lógica de cortar/condimentar sigue en `Box`. Recoger un objeto guardado pasa
  siempre por `Slot.pick_up_item(actor, item)` (+ `Slot.slot_of(item)`), un único sitio que
  usan `Box`, `Ingredient`, `SeasoningItem` y `SandboxPickable` (owns ampliado, aprobado): el slot
  restaura capa y `freeze` antes de que la mano los guarde (paridad con `Box.OnPickedUp` →
  `ForceClearSlot`).
- **P1 tests**: `tests/integration/test_box_on_slot.gd` (5 tests, escenas reales Player + Slot +
  Box + detector + `interact_pressed`): dejar la caja en la mesa, llenarla en 5/10/20 pulsaciones
  con pulpo cocido (gasta 50), pulpo crudo descartado, condimentar con el bote en la mano (una vez,
  bote conservado), recogerla (mesa libre) y soltarla sin `freeze`, en capa `interactable`, máscara
  original y con su contenido. `test_interaction_detector.gd`: el slot ocupado resuelve a su objeto;
  el objeto incompatible se descarta con mano llena (el caso que acepta, la caja con pulpo cocido o
  bote, lo cubre `test_box_on_slot.gd`; el fichero del detector está en el máximo de gdlint).
  `test_slot.gd`: coger del slot vía detector y soltar restaura capa/máscara/`freeze`;
  `slot_of`/`pick_up_item`.
- Hallazgo en tests: un `Slot` añadido en el origen y movido después llegaba a solapar la cápsula
  del jugador (máscara `world|interactable`) en algún paso de física y lo empujaba 0,9 m según el
  orden de los tests; ahora se coloca antes de `add_child` y los objetos nacen lejos.
- **P2 grupos**: se mantienen `pickable` + `interactable` (enmienda aprobada, rebase sobre
  `ebb28c5`).
- **P2 sandbox**: una sola ruta de input; `mcp_bridge` apagado por defecto y activado en caliente
  con `run_script` solo para la captura. El sandbox tiene ahora una mesa (`Slot`) con una caja
  pequeña como `initial_item`.
- **Captura**: `docs/evidence/PUL-016/review-caja-llenandose-en-mesa.png` (+ `-zoom`): pulpo
  cocido en la mano, objetivo = la caja de la mesa, 3 pulsaciones = 3 cortes (`fill` 0,2 → 0,4 →
  0,6 en el `watch`), barra y tapa abierta. `get_debug_output` sin errores.
- Para el architect: `can_receive(held)` es un método opcional nuevo que consulta el detector;
  convendría anotarlo en ADR-003 §4.
