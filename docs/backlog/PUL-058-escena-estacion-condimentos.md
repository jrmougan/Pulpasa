---
id: PUL-058
title: Crear la escena de la estación de condimentos
status: review
milestone: M2
role: gameplay-engineer
deps: [PUL-057]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_station.gd.uid, godot/entities/stations/seasoning_dispenser.gd, godot/entities/stations/seasoning_dispenser.gd.uid, godot/entities/stations/cachelos_bowl.gd, godot/entities/stations/cachelos_bowl.gd.uid, godot/resources/seasoning_station_data.gd, godot/resources/seasoning_station_data.gd.uid, godot/data/config/seasoning_station.tres, godot/entities/stations/sandbox/seasoning_station_sandbox.*, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_seasoning_station.gd.uid, docs/evidence/PUL-058/**, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/slot.gd, godot/components/interaction_detector.gd, godot/components/interaction_contract.gd, godot/tests/integration/test_interaction_detector.gd, godot/tests/unit/test_interaction_contract.gd, godot/tests/integration/test_slot.gd, godot/tests/unit/test_data_integrity.gd]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/sandbox/seasoning_station_sandbox.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 3. Contratos de PUL-056.

## Change
`seasoning_station.tscn` con placeholder de primitivas (el modelo es PUL-052): bandeja (`Slot` de
caja), 4 dispensadores con lado, cuenco con raciones, antirrebote con reloj inyectable, sonido de
error, resaltado; `SeasoningStationData` + `.tres` (`toggle_guard`, `cachelos_stock_max`,
`cachelos_initial_stock`, `cachelos_portions_per_item`, `paprika_swap`, `operator_side_only`);
sandbox propio.

## Constraints
- No editar `level_01.tscn` (PUL-061). Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Feature AC1, AC3, AC6–AC11 → `test_seasoning_station.gd`
- [x] AC2 Captura del sandbox en `docs/evidence/PUL-058/`
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `resources/seasoning_station_data.gd` (`SeasoningStationData`) + `data/config/seasoning_station.tres`
  (`toggle_guard` 0,25, `cachelos_stock_max` 3, `cachelos_initial_stock` 0,
  `cachelos_portions_per_item` 1, `paprika_swap` true, `operator_side_only` true). Test de valores en
  `tests/unit/test_data_integrity.gd` (recuento de `.tres` 26 → 27; autorizado por el coordinador).
- Contrato (ADR-003 §8.1/§8.2): `InteractionContract.INTERACTABLE_OPTIONAL_METHODS = ["is_reachable_from"]`
  (test en `test_interaction_contract.gd`); `InteractionDetector.refresh()` salta la entidad cuyo
  `is_reachable_from(Vector2(x, z), holder)` devuelve `false` (test en `test_interaction_detector.gd`);
  `Slot.accepted_group` (vacío = todo; si no, consume sin guardar lo que no esté en el grupo; test en
  `test_slot.gd`).
- `seasoning_dispenser.{gd,tscn}` (`SeasoningDispenser`): `is_reachable_from` por lado (o los dos con
  `operator_side_only` = false), `can_interact` con holder, `interact` siempre consume: antirrebote
  silencioso tras un cambio (`clock: Callable` inyectable), `HAND_BUSY`, `NO_BOX`, y si no
  `box.toggle_seasoning(seasoning, data.paprika_swap)`; rechazo → `rejected(reason)`. Bote de
  primitivas con el color e icono del `SeasoningData`.
- `cachelos_bowl.{gd,tscn}` (`CachelosBowl`): `stock` 0..max, `%Portions` (una malla por ración),
  reponer con cachelos cocidos desde cualquier lado (`NOT_ACCEPTED`, `BOWL_FULL`), alternar con la
  mano vacía desde el lado de condimentar (`NO_BOX`, `BOX_NOT_FULL`, `BOWL_EMPTY`, ±1 ración; quitar
  con el cuenco lleno se rechaza con `BOWL_FULL` para no pasar del máximo), mismo antirrebote,
  `stock_changed` tras la señal de la caja y una vez en `_ready()`.
- `seasoning_station.{gd,tscn}` (`SeasoningStation`): mostrador 4 × 1,1 m en capa `world`, `Model` de
  primitivas, `%PassSide` (z−) / `%OperatorSide` (z+), `Tray` (slot.tscn, `accepted_group = &"box"`,
  sin mesa), 4 dispensadores a 0,9 m, cuenco en el extremo, `%ErrorAudio`; `side_of()`, `get_box()`;
  oye `rejected` → error + sacudida del `Model` del emisor.
- Sandbox `entities/stations/sandbox/seasoning_station_sandbox.{tscn,gd}`: estación, suelo, cámara,
  dos jugadores (uno por lado) y una caja llena con picante, sal y aceite en la bandeja, cuenco con 2.
- `tests/integration/test_seasoning_station.gd`: feature AC1 (sal, `seasoned` una vez), AC3
  (antirrebote con reloj inyectado), AC4/AC5 por la escena, AC6 (bandeja vacía), AC7 (detector real:
  desde el pase el dispensador no es objetivo ni se resalta; desde condimentar sí), AC8 (mano ocupada),
  AC9 (coger/dejar desde los dos lados, segunda caja rechazada), AC10 (reponer, crudo/quemado, lleno),
  AC11 (alternar cachelos ±1 ración, cuenco vacío), contrato de nodos de scene-tree §3.
  La pegatina de AC1 es de `BadgeRow` (PUL-059).

## Evidence
- `tools/verify.sh` verde (589/589 tests, gdformat/gdlint limpios, import y smoke OK):
  `docs/evidence/PUL-058/verify.log`. `tools/check_owns.py` limpio contra
  `jrmougan/agentica-migracion-godot-alpha`.
- AC1 → `tests/integration/test_seasoning_station.gd` (36 tests): `test_scene_contract_*` (nodos de
  scene-tree §3, `accepted_group = &"box"`, 4 dispensadores con su `SeasoningData` y ≥ 0,9 m,
  `is_reachable_from` en dispensadores y cuenco, `InteractionContract.scan_tree` limpio),
  `test_side_of_*`, feature `test_ac1_*` (sal: `seasoned` una vez; quitar tras el guard),
  `test_ac3_*` (antirrebote con reloj inyectado, por dispensador, leído del `.tres`), `test_ac4_*`
  (intercambio y `EXCLUSIVE_TAKEN` sin `paprika_swap`), `test_ac5_*` (caja vacía y a 0,6: error),
  `test_ac6_*` (bandeja vacía sin errores de motor; sacudida que vuelve a reposo), `test_ac7_*`
  (detector real: desde el pase ningún dispensador es objetivo ni se resalta; desde condimentar sí;
  `operator_side_only` = false), `test_ac8_*` (mano ocupada: `HAND_BUSY`, no se suelta ni por
  `InteractionComponent`), `test_ac9_*` (bandeja por los dos lados, rechaza lo que no es caja y una
  segunda caja), `test_ac10_*` (reponer cocidos desde cualquier lado, crudos/quemados/otro objeto
  `NOT_ACCEPTED`, lleno `BOWL_FULL`, raciones visibles), `test_ac11_*` (stock inicial del `.tres`,
  ±1 ración, `BOWL_EMPTY`, `NO_BOX`/`BOX_NOT_FULL`, antirrebote del cuenco).
  Contrato: `test_slot.gd` `test_pul058_*` (`accepted_group`), `test_interaction_detector.gd`
  `test_pul058_*` (`is_reachable_from` filtra objetivo y resaltado), `test_interaction_contract.gd`
  `test_pul058_*`, `test_data_integrity.gd` `test_pul058_*` (valores del `.tres`; recuento 26 → 27,
  autorizado por el coordinador).
- AC2 → `docs/evidence/PUL-058/sandbox.png` (sandbox `seasoning_station_sandbox.tscn` vía MCP:
  cuenco con 2 raciones, dulce/picante/sal/aceite y caja llena en la bandeja con picante, sal y
  aceite aplicados por las rutas reales). Las pegatinas sobre la caja son de PUL-059.
- Notas: la pegatina de feature AC1 la cubre `BadgeRow` (PUL-059). Decisiones de implementación:
  el antirrebote cuenta desde la última pulsación que **cambió** algo (un rechazo no lo arma); el
  cuenco usa el mismo `toggle_guard` al alternar y la misma válvula `operator_side_only`; quitar
  cachelos con el cuenco lleno se rechaza (`BOWL_FULL`). El `Model` de `Tray` (mesa de `slot.tscn`)
  se oculta y sin colisión mediante hijos editables; la bandeja visible es `Tray/TrayMesh`.
  `condiment_jar.tscn` no se usa: PUL-061 puede borrarlo. En tests, liberar una caja recién soltada
  con `free()` colgaba a veces el teardown de GUT; se usa `queue_free()`.
