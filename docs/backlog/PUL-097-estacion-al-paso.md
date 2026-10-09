---
id: PUL-097
title: Implementar la estación de condimentos al paso
status: review
milestone: M3c
role: gameplay-engineer
deps: [PUL-092, PUL-093, PUL-094]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.*, godot/entities/stations/cachelos_bowl.*, godot/entities/stations/sandbox/seasoning_station_sandbox.*, godot/core/seasoning_rules.gd, godot/resources/seasoning_station_data.gd, godot/data/config/seasoning_station.tres, godot/tests/unit/test_seasoning_rules.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_cachelos.gd, godot/tests/integration/test_m2b_station_selection.gd, godot/tests/integration/test_m2b_flow.gd, godot/tests/integration/test_station_level.gd, godot/tests/integration/test_delivery_e2e.gd, godot/tests/integration/test_kitchen_flow.gd, godot/tests/integration/test_m1_flow.gd, godot/tests/integration/test_m2_flow.gd, godot/tests/integration/test_parity_smoke.gd, docs/evidence/PUL-097/**, docs/backlog/PUL-097-estacion-al-paso.md]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/sandbox/seasoning_station_sandbox.tscn]
---

## Target
Estación de condimentos (D23, C-B): sin `Tray`; dispensadores y cuenco actúan sobre la caja en la mano del actor.

## Change
Quita `Tray`. Dispensador: con caja llena en la mano y desde el lado de servicio alterna su condimento (toggle, `paprika_swap`, antirrebote con **reloj de juego**). Mano vacía: no es objetivo. Cuenco: reponer con cachelos cocidos desde cualquier lado (+2 raciones, máx. 4, en `.tres`); alternar cachelos con caja llena en la mano; con cualquier otra cosa no es objetivo; muestra `Portions0..4`. Decisiones del producer sobre preguntas de PUL-092: reponer con el cuenco por debajo del máximo se acepta y se recorta a 4 (con 3 queda en 4); con el cuenco en 4 se rechaza. Las raciones siempre se ven en el modelo. Integra los modelos de PUL-094. Adapta los 8 tests de integración que usan `Tray`/`get_tray`/`get_box` (detectados en PUL-093) al flujo con la caja en la mano; no los borres sin sustituir lo que prueban.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.
- No toques `level_01.tscn` (PUL-101). `seasoned`/`seasoning_removed` sin cambios de firma.
- Revisión de PUL-094: los anclajes de dispensadores y cuenco cambiaron y el mostrador mide 5,2 m (colisión actual de 4 m; `Tray` queda flotando sin malla). `cachelos_bowl.glb` trae `Portions0..4` todos visibles: la escena debe mostrar solo uno; añade un test que lo compruebe. Detalle en `docs/evidence/PUL-094/README.md`.

## Acceptance
- [x] AC1 R1–R4 (toggle con caja en mano, antirrebote, caja a medio cortar rechazada, mano vacía sin objetivo) → tests
- [x] AC2 R5–R6 (cuenco solo con cachelos; 2 raciones, máx. 4) → tests
- [x] AC3 R7–R8 (sin `Tray`; franjas ≥ 0,6 m sin huecos en el sandbox) → test + mapa de objetivos
- [x] AC4 Captura del sandbox con los modelos nuevos y cuenco a 0/2/4

## Plan
Ficheros (todos en `owns`): `core/seasoning_rules.gd` (+`can_restock`/`restocked`, puras), `resources/seasoning_station_data.gd` y `data/config/seasoning_station.tres` (`cachelos_stock_max` 4, `cachelos_portions_per_item` 2), `seasoning_station.{gd,tscn}` (sin `Tray` ni `get_tray`/`get_box`; colisión 5,2 x 1,1 x 1,12; dispensadores y cuenco en los anclajes de PUL-094), `seasoning_dispenser.gd` (objetivo solo con una `Box` en la mano y desde el lado de condimentar; toggle sobre la caja en la mano; antirrebote con reloj inyectable), `cachelos_bowl.{gd,tscn}` (objetivo con cachelos cocidos desde cualquier lado y con una caja desde el lado de condimentar; reponer +2 recortado a 4, rechazo con 4; muestra exactamente una malla `Portions0..4` del GLB), sandbox (caja en la mano, cuenco 0/2/4) y los 8 tests de integración con `Tray`.
Señales: ninguna nueva ni cambiada (`seasoned`/`seasoning_removed` de la caja, `rejected`/`stock_changed` locales).
Decisión de diseño: con una caja que no esté llena en la mano el dispensador sigue siendo objetivo y rechaza con `BOX_NOT_FULL` (R3); el cuenco, con una caja en la mano, es objetivo solo desde el lado de condimentar (desde el pase deja pasar, R5).
Tests por AC:
- AC1 (R1-R4): `test_seasoning_station.gd` (toggle con caja en mano y señales, antirrebote con reloj de juego, `BOX_NOT_FULL` con sonido, mano vacia/otro objeto sin objetivo ni resaltado) + `test_seasoning_rules.gd`.
- AC2 (R5-R6): `test_seasoning_station.gd` y `test_cachelos.gd` (solo cachelos cocidos, +2, recorte a 4, rechazo con 4, caja/pulpo desde el pase no es objetivo, `Portions` unica visible).
- AC3 (R7-R8): `test_seasoning_station.gd` (sin `Tray`, colision 5,2 m, barrido del mapa de objetivos con caja en mano a 1,0 m: franjas continuas >= 0,6 m sin huecos; guardado en `docs/evidence/PUL-097/target_map.txt`).
- AC4: captura CLI del sandbox con cuenco a 0/2/4 en `docs/evidence/PUL-097/`.
- Los 8 tests de flujo se adaptan: la caja descansa en un `PassSlot` mientras se corta, se coge y se lleva a los dispensadores en la mano; el resto de lo que probaban se mantiene.
Fuera de `owns` (se reporta): `test_data_integrity.gd` (stock 3 / 1 racion) y `test_level_01.gd` (usa `get_tray`) quedan rotos por el contrato; los toca PUL-101 / coordinador.

## Evidence
- Verify: con el parche de `fuera_de_owns.patch` aplicado, `tools/verify.sh` termina en verde (745 tests, 745 pasan; `docs/evidence/PUL-097/verify_con_parche.log`). **Sin el parche, la rama deja 3 tests en rojo en ficheros fuera de `owns`** (ver Pendiente).
- AC1 (R1-R4): `tests/integration/test_seasoning_station.gd` (toggle con caja en la mano y `seasoned`/`seasoning_removed`, antirrebote 0,1 s vs 0,25 s con reloj inyectado, `BOX_NOT_FULL` con `season_error`, mano vacía/otro objeto sin objetivo ni resaltado, lado de pase sin objetivo) y `test_m2b_station_selection.gd` con el detector real en `level_01`.
- AC2 (R5-R6): `test_seasoning_station.gd` (cachelos crudos/quemados, mano vacía y pulpo no son objetivo; caja desde el pase no es objetivo; cachelos cocidos desde los dos lados; +2 raciones, 3 pasa a 4, con 4 `BOWL_FULL`), `test_cachelos.gd` (olla a cuenco), `test_seasoning_rules.gd` (`restocked`/`can_restock`) y test de `Portions0..4` con exactamente una malla visible (escena sola y por stock 0/2/4).
- AC3 (R7-R8): sin `Tray` (nodo, `get_tray` y `get_box` eliminados), colisión de 5,2 m; mapa de objetivos a 1,0 m con caja en la mano en `docs/evidence/PUL-097/target_map.txt`: dulce 1,15 m, picante 1,0 m, sal 1,0 m, aceite 1,0 m, cuenco 1,1 m, 0 huecos.
- AC4: capturas CLI (`capture_station.gd`) en `docs/evidence/PUL-097/`: `sandbox_bowl_{0,2,4}_1080.png` (cámara nativa), `_zoom.png` (mostrador) y `_bowl.png` (cuenco).
- Los 8 tests con `Tray` adaptados al flujo con la caja en la mano (la caja descansa en un `PassSlot`/`FreeSlot` mientras se corta, después va en la mano): `test_delivery_e2e`, `test_kitchen_flow`, `test_m1_flow`, `test_m2_flow`, `test_m2b_flow`, `test_m2b_station_selection`, `test_parity_smoke`, `test_station_level`. Mantienen lo que probaban (entrega completa, rechazos, barrido de `interactable`, selección del detector).

### Decisiones
- Dispensador: objetivo con cualquier `Box` en la mano (R3 exige rechazar la caja a medio cortar con sonido). Cuenco con caja: objetivo solo desde el lado de condimentar; con cachelos cocidos, desde los dos lados. R5 de `rediseno-estaciones.md` dice "con una caja, el cuenco no es objetivo" pero la ficha (Change) manda alternar cachelos con caja llena: desde el pase no es objetivo.
- Franjas continuas (R8): el cono del detector (30 grados) dejaba huecos de 0,25 m con el origen del dispensador en el anclaje (0,65 m de profundidad). El origen del objetivo (nodo raíz, colisión) se retrasa 0,45 m (dispensadores) y 0,25 m (cuenco) hacia el pase y el `Model` se compensa para que el arte quede exactamente en los anclajes de PUL-094 (-2,-1,0,1 / z 0,35; cuenco x 2, z 0,15; test `test_r7_anchors...`).
- Se elimina el `Sprite3D` Icon flotante del dispensador: los GLB nuevos traen los botones con iconos.
- Sandbox: el jugador empieza con la caja llena en la mano, con un cachelo en el cuenco (2 raciones).

### Pendiente fuera de `owns` (lo ve el coordinador; PUL-101)
1. `godot/tests/unit/test_data_integrity.gd` (`test_pul058_seasoning_station_values`): espera `cachelos_stock_max` 3 y `cachelos_portions_per_item` 1; pasan a 4 y 2.
2. `godot/tests/integration/test_level_01.gd` usa `station.get_tray()`/`get_box()` (`_station_access` y el recorrido AC4). Sustituir por el cuenco y un `PassSlot`.
Ambos parches mínimos están en `docs/evidence/PUL-097/fuera_de_owns.patch` (con ellos `test_level_01` pasa 18/18: la colisión de 5,2 m no rompe el alcance de ninguna estación en `level_01`).
