---
id: PUL-015
title: Montar detector 3D, resaltado por shader y slots con ancla
status: review
milestone: M0
role: gameplay-engineer
deps: [PUL-012, PUL-014]
orca_task: null
unity_sources: [Assets/Scripts/Interaction/**, Assets/Scripts/Game/InteractableSlot.cs, Assets/Art/Materials/HighlightTexture.mat]
owns: [godot/entities/player/sandbox/**, godot/resources/player_config.gd, godot/data/config/player_config.tres, godot/tests/unit/test_data_*.gd, godot/components/interaction_detector.gd, godot/components/interaction_detector.gd.uid, godot/components/highlightable.gd, godot/components/highlightable.gd.uid, godot/shaders/**, godot/entities/stations/slot.tscn, godot/entities/stations/slot.gd, godot/entities/stations/slot.gd.uid, godot/entities/player/player.tscn, godot/scenes/sandbox/**, godot/tests/integration/test_interaction_detector.gd, godot/tests/integration/test_interaction_detector.gd.uid, godot/tests/integration/test_slot.gd, godot/tests/integration/test_slot.gd.uid, docs/evidence/PUL-015/**]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/stations/slot.tscn, godot/scenes/sandbox/player_sandbox.tscn]
---

## Target
Fase 5 de M0, **capa específica 3D** (`scene-tree.md` §3; ADR-003 §3).

## Change
1. Añade a `PlayerConfig` (+ `.tres`) los parámetros de puntuación que `InteractionScoring.pick_best` recibe: cono 30° (semiángulo), distancia mínima 0,7 m, bonus de cocina 1,0 y altura de origen 0,8 m (valores de `InteractionDetector.cs`). El detector calcula la distancia 3D desde el jugador + 0,8 m y la pasa al `Candidate`.
2. `components/interaction_detector.gd` (`Area3D`, máscara `interactable`, radio de `PlayerConfig`):
   delega en `InteractionScoring` y emite `target_changed(target)`. Uno por jugador (B7).
3. `components/highlightable.gd` + `shaders/highlight_outline.gdshader` (inverted hull en
   `material_overlay`): se activa cuando el objeto es el objetivo. Sin `EmissionHighlighter` (B3).
4. `entities/stations/slot.{tscn,gd}`: mesa/hueco que guarda un objeto alineado por su `%AnchorPoint`
   (sustituye `InteractableSlot` + `SnappingHelper`).
5. Añade `%InteractionDetector` e `%InteractionComponent` a `player.tscn` y un par de slots y objetos
   al sandbox.

## Constraints
- Reutiliza `InteractionScoring`, `InteractionComponent` y el contrato de PUL-014; no dupliques lógica.
- `.tscn` vía MCP o editor; no inventes uid.

## Acceptance
- [x] AC1 En el sandbox, el detector selecciona el objetivo que dicta `InteractionScoring` y lo resalta; al girar, cambia el resaltado sin dejar dos objetos resaltados → `test_interaction_detector.gd`.
- [x] AC2 Dejar un objeto en un slot lo alinea a su `%AnchorPoint`; cogerlo de nuevo libera el slot → `test_slot.gd`.
- [x] AC3 Captura del sandbox con un objeto resaltado y otro en un slot, vía MCP con `simulate_input`, en `docs/evidence/PUL-015/`.
- [x] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` sin rutas fuera.

## Plan
- `resources/player_config.gd` + `data/config/player_config.tres`: `detector_cone_half_angle` 30,
  `detector_near_distance` 0,7, `detector_kitchen_bonus` 1,0, `detector_origin_height` 0,8
  (`tests/unit/test_data_player_config.gd`).
- `components/interaction_detector.gd` (`InteractionDetector`, `Area3D`, máscara `interactable`,
  esfera con `detector_radius`): cada tick de física construye un `Candidate` por cuerpo
  (dirección en el suelo, distancia 3D desde el portador + `detector_origin_height`), delega en
  `InteractionScoring.pick_best` y emite `target_changed(previous, current)` solo al cambiar
  (firma de `signals.md`, la que conecta `InteractionComponent`). Resuelve los slots antes de
  puntuar: slot ocupado con la mano llena se descarta; slot ocupado con la mano vacía cuenta como
  cogible. El detector enciende/apaga el `Highlightable` del objetivo (el del objeto guardado si
  es un slot ocupado), de modo que nunca hay dos resaltados.
- `components/highlightable.gd` + `shaders/highlight_outline.gdshader` + `shaders/highlight_outline.tres`:
  `show()`/`hide()` ponen/quitan el contorno (inverted hull) en `material_overlay` de las mallas
  de su entidad (sin bajar a otras entidades) y una retícula opcional. Sin `EmissionHighlighter` (B3).
- `entities/stations/slot.{tscn,gd}` (`Slot`, `StaticBody3D`, grupo `interactable`, `%Anchor`,
  `%Highlightable` con retícula, `@export initial_item`): `interact` deja lo que lleva la mano
  alineado por el `%AnchorPoint` del objeto (sustituye `InteractableSlot` + `SnappingHelper`) o se
  lo devuelve a la mano vacía; el objeto guardado sale de la capa `interactable` y se congela.
- `player.tscn`: `%InteractionDetector` (+ `CollisionShape3D`) e `%InteractionComponent`.
- Sandbox: `entities/player/sandbox/sandbox_item.{gd,tscn}` (pickable + interactable con
  `%AnchorPoint` y `%Highlightable`) sustituye a `SandboxPickable`; `player_sandbox.gd` pierde la
  lógica provisional de coger/soltar (ahora la hace `InteractionComponent`). La escena añade dos
  slots (uno con objeto inicial) y dos objetos sueltos.
- Tests: AC1 `tests/integration/test_interaction_detector.gd`; AC2 `tests/integration/test_slot.gd`;
  AC3 captura MCP en `docs/evidence/PUL-015/`; AC4 `tools/verify.sh`.

## Evidence
- **AC1** `tests/integration/test_interaction_detector.gd` (10 tests): un único detector cableado a
  `%InteractionComponent` (B7); máscara `interactable` y radio de `PlayerConfig`; el objetivo
  coincide con `InteractionScoring.pick_best`; el objetivo se resalta (`material_overlay`); al
  girar 180° cambia el objetivo con un solo `target_changed(front, back)` y un solo resaltado; sin
  objetivo se apaga y emite `(prev, null)`; no emite cada frame; slot ocupado → resalta su objeto,
  y se descarta con la mano llena; al recoger del slot el objeto en la mano deja de resaltarse.
- **AC2** `tests/integration/test_slot.gd` (11 tests): al dejarlo, el `%AnchorPoint` del objeto
  (desplazado y girado 90°) coincide con `%Anchor` del slot (girado 30°); sin `%AnchorPoint` se
  alinea el origen; guardado = congelado y fuera de la capa `interactable`; recogerlo libera el
  slot; al soltarlo después no queda congelado y recupera capa/máscara; slot ocupado rechaza mano
  llena; slot vacío + mano vacía no hace nada; objeto liberado libera el slot; flujo completo con
  `interact_pressed()` + detector; `initial_item`; contrato `interactable` cumplido.
- **AC3** `docs/evidence/PUL-015/ac3-resaltado-y-slot.png`: MCP `run_project` (background) del
  sandbox, `simulate_input` `p1_move_right` 200 ms → ItemA con contorno amarillo
  (`Highlightable._highlighted = true`, el resto `false`) y otro objeto en `SlotWithItem` (mesa
  izquierda, por `initial_item`). `get_debug_output` sin errores.
- **AC4** `tools/verify.sh`: ✓ verify OK (gdformat, gdlint, import, GUT 233/233, smoke).
  `tools/check_owns.py` sin rutas fuera de owns.
- **Revisión de codex**: el detector conserva `_has_target` aparte para publicar
  `target_changed(null, …)` cuando el objetivo se libera (`free` o `queue_free`) y excluye
  candidatos en cola de borrado; nunca emite un objeto liberado como `previous`. +9 tests: liberar
  el único objetivo (emite `[null, null]` una vez) o con sustituto (emite `[null, sustituto]` y lo
  resalta), altura de mira 0,8 m frente a distancia plana, excepción de 0,7 m en 3D (dentro y fuera)
  y bonus `kitchen` con mano vacía/llena. `tools/verify.sh` ✓ (GUT 242/242).

Notas para revisión:
- `PlayerConfig` gana `detector_cone_half_angle`, `detector_near_distance`, `detector_kitchen_bonus`,
  `detector_origin_height`; su test va en `test_data_integrity.gd` (un `test_data_*.gd` nuevo
  necesitaría un `.uid` fuera de owns).
- El resaltado lo enciende/apaga el **detector** (AC1 de la ficha), no `InteractionComponent`
  como sugiere la columna «receptores» de `target_changed` en `signals.md`: el componente es común
  y no puede conocer `Highlightable`. Conviene ajustar esa celda en `signals.md` (architect).
- El bonus de cocina usa el grupo `kitchen` (equivale al tag `Kitchen`); no está en ADR-003 §4/§5:
  la ficha de la cocina debe añadirlo o el architect fijar otro mecanismo.
- `Slot` sigue a Unity: un slot vacío sigue siendo candidato con la mano vacía (resalta, pero
  `can_interact` es falso). Con un objeto dentro el detector selecciona el slot (el objeto sale de
  la capa `interactable` para no duplicarse) y resalta el objeto guardado.
- Hallazgo: un `Area3D` con `collision_layer = 0` y `monitorable = false` no detecta cuerpos en
  4.7.2; el detector deja `monitorable` por defecto.
- Las herramientas de edición headless del MCP fallan en este proyecto (su `godot_operations.gd`
  no está tipado y `untyped_declaration` es error); las escenas se generaron con un script
  `SceneTree` tipado que usa `PackedScene.pack` + `ResourceSaver` (uid/unique_id del motor).
- La lógica provisional de coger/soltar de `entities/player/sandbox/` se sustituye por
  `InteractionComponent`; `SandboxPickable` ahora también es `interactable` y vive en
  `sandbox_item.tscn`.
