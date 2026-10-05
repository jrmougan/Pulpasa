---
id: PUL-061
title: Montar level_01 con la planta B y la estación, y retirar los botes
status: done
milestone: M2
role: gameplay-engineer
deps: [PUL-039, PUL-058, PUL-059, PUL-060]
orca_task: task_c66fb073bab5
unity_sources: []
owns: [godot/scenes/levels/**, godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/spice_shelf.tscn, godot/entities/items/seasoning.tscn, godot/entities/items/seasoning_item.gd, godot/entities/items/seasoning_item.gd.uid, godot/entities/items/box.gd, godot/entities/stations/slot.gd, godot/entities/items/sandbox/**, godot/entities/stations/sandbox/stations_sandbox.*, godot/entities/player/sandbox/**, godot/tests/integration/*.gd, godot/tests/integration/*.gd.uid, docs/evidence/PUL-061/**, godot/assets/models/placeholders/condiment_jar.tscn, godot/scenes/scale_check.tscn, godot/scenes/sandbox/**]
touches_scenes: [godot/scenes/levels/level_01.tscn, godot/entities/environment/kitchen_layout.tscn, godot/scenes/scale_check.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 6, y planta **B · barra partida** de `docs/design/level-layouts.md` (D19, elegida por
el responsable el 2026-10-05).

## Change
1. `kitchen_layout.tscn` y `level_01.tscn` según la planta B: barra con pasaplatos que separa
   cocina (nevera, cachelera, 2 ollas) y servicio (estantería de cajas, puestos 1–4); estación de
   condimentos en la barra; salidas de J1/J2. Placeholders de primitivas (el arte llega en M3).
2. Retirar `SpiceShelf`, `seasoning.tscn`, `SeasoningItem` y las rutas de bote/cachelos de `box.gd`.
3. Reescribir los tests de integración afectados (flujos M1/M2, kitchen_flow, parity_smoke,
   level_01, cachelos, seasoning, shelves, slot, items_contract, delivery_e2e) al nuevo flujo.

## Constraints
- Contratos de PUL-056. No cambiar firmas de `EventBus`. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Feature AC16–AC18 → tests de integración en el nivel real
- [x] AC2 Distancias de la planta B (±1 m) frente a `docs/evidence/PUL-041/distancias.md`
- [x] AC3 Captura del nivel en Individual y Local 2P en `docs/evidence/PUL-061/`
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
`slot.gd` entra en owns por decisión del coordinador (2026-10-05): §7 de scene-tree le asigna a
esta ficha quitar `Slot.initial_item_data`.

**Geometría (planta B, cuadrícula de scene-tree §2: col `c` → x = c − 6,3; fila `r` → z = r − 4,0).**
- `kitchen_layout.tscn`: suelo; barra de la fila 4 (z ∈ [−0,5; 0,5], tablero a 1,1 m, capa world)
  en cols 1–4 y 9–13, con hueco en la col. 14; mostrador trasero en los `#` de la fila 0; paredes
  laterales (cols 0 y 15, con el hueco de la estantería en la col. 0, filas 6–7) y barandilla
  baja del público detrás de los puestos. Primitivas (BoxMesh + BoxShape3D), sin arte.
- `level_01.tscn`: OctopusStorage (2,0), CachelosStorage (3,0), Kitchen (5,0), Kitchen2 (7,0) de
  cara al servicio; PassSlot01–04 (cols 1–4) y PassSlot05–09 (cols 9–13) sobre la barra
  (`slot.tscn` con su mesa oculta y sin colisión: la barra es el mostrador);
  SeasoningStation en cols 5–8 (centro x 0,2; pase hacia −z); BoxShelf en (0, 6–7) mirando a +x;
  OrderStand1–4 en (3/5/8/10, 10); Player1 en (11,7) y Player2 en (2,2). Cámara sin cambios (D14).

**Pasos (verify verde entre ellos).**
1. Planta B + estación en el nivel, con `SpiceShelf` aún presente (aparcada en el servicio);
   `test_level_01.gd` con las posiciones nuevas, AC2 de distancias y alcance físico de todo.
2. Tests de flujo al camino por la estación: `test_m1_flow`, `test_m2_flow`, `test_kitchen_flow`
   (+ `kitchen_sandbox` con estación), `test_parity_smoke`, `test_delivery_e2e` (rutas por el
   hueco de la barra), `test_cachelos`, `test_order_stand`, `test_box_on_slot`.
   Nuevo `test_station_level.gd` para AC16–AC18 de la feature en el nivel real, con detector y
   teclado reales.
3. Bajas: `spice_shelf.tscn`, `seasoning.tscn`, `seasoning_item.gd(.uid)`, `condiment_jar.tscn`,
   sus instancias en sandboxes/`scale_check`, `Slot.initial_item_data`, ramas de bote y cachelos
   en `Box.interact()` (+ `can_season`/`_season`); fuera `test_seasoning.gd`, `test_shelves.gd`
   (estantería de cajas pasa a otro test), partes de `test_box`, `test_slot`, `test_items_contract`,
   `test_scale_check`.

**AC → test.**
- AC1: `test_station_level.gd` (AC16 cambio de personaje sin rodear, AC17 un personaje rodeando
  por el hueco, AC18 sin `SpiceShelf`/`SeasoningItem` y únicos cambios de condimento en los 4
  dispensadores y el cuenco).
- AC2: `test_level_01.gd::test_ac2_planta_b_distances_match_pul041` (Dijkstra sobre las celdas
  libres para la cápsula real, entre puntos de acceso de cada estación) frente a la columna B de
  `docs/evidence/PUL-041/distancias.md`, ±1 m.
- AC3: capturas con el MCP en `docs/evidence/PUL-061/` (Individual con cambio, Local 2P).
- AC4: `tools/verify.sh` y `tools/check_owns.py`.

## Evidence
Detalle en `docs/evidence/PUL-061/README.md`.
- AC1: `tests/integration/test_station_level.gd` (AC16 con cambio y sin rodear, AC17 rodeando por el
  hueco, AC18 sin botes y barrido de todos los `interactable`).
- AC2: `test_level_01.gd::test_ac2_planta_b_distances_match_pul041_within_one_metre`; todos los
  tramos dentro de ±1 m (p. ej. nevera → olla 3,2/3,0; salida J2 → J1 17,6/18,2).
- AC3: partidas con el MCP en Individual (cambio con Q, +8 €) y Local 2P (+17 €), capturas
  `ac3-*.png`.
- AC4: `tools/verify.sh` verde (584 tests); `check_owns` limpio.
- Hallazgo para PUL-063: con caja en la bandeja, Sal y Pimentón picante no se pueden usar de frente
  (el detector elige la caja); con caja en la mano, la bandeja pierde contra los dispensadores
  desde el servicio. Tests con posiciones en diagonal (`level_walker.gd::dispenser_stand`) y caja
  por el pase; sonda en `sonda-detector-dispensadores.txt`.
- Pasos: 1) planta B y estación (commit e8f2f9a), 2) tests de flujo (53b3584), 3) bajas (último).
  Los pasos 1–2 se verificaron por fichero de test; verify completo en verde tras el paso 3.
