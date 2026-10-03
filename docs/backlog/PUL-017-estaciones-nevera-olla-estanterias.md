---
id: PUL-017
title: Crear las estaciones - nevera, olla y estanterías de cajas y especias
status: ready
milestone: M0
role: gameplay-engineer
deps: [PUL-016]
orca_task: null
unity_sources: [Assets/Scripts/Game/OctopusSwapner.cs, Assets/Scripts/Game/Kitchen.cs, Assets/Scripts/UI/KitchenProgress.cs, Assets/Scripts/Game/Box.cs, Assets/Prefabs/KitchenStations/**]
owns: [godot/entities/stations/item_spawner.gd, godot/entities/stations/item_spawner.gd.uid, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/cooking_station.gd, godot/entities/stations/cooking_station.gd.uid, godot/entities/stations/box_shelf.tscn, godot/entities/stations/spice_shelf.tscn, godot/tests/integration/test_item_spawner.gd, godot/tests/integration/test_item_spawner.gd.uid, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_cooking_station.gd.uid, godot/tests/integration/test_shelves.gd, godot/tests/integration/test_shelves.gd.uid, docs/evidence/PUL-017/**]
touches_scenes: [godot/entities/stations/octopus_storage.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/spice_shelf.tscn]
---

## Target
Fase 6 de M0, estaciones (`scene-tree.md` §3 `entities/stations/`).

## Change
1. `item_spawner.gd` genérico (`@export scene`, `@export data`): instancia el objeto **en la mano**
   del actor si está vacía (ADR-003 §6). Sustituye `OctopusSpawner` y el modo spawner de `Box`.
2. `octopus_storage.tscn` (nevera placeholder) con el spawner de pulpo.
3. `kitchen.tscn` + `cooking_station.gd`: acepta un pulpo crudo de la mano, lo cuece en
   `cook_time` (`IngredientData`, 5 s), barra de progreso y bucle de hervor (PUL-009), y lo devuelve
   cocido al interactuar con mano vacía. Capacidad 1 (D9 es M1). Sin quemado (M1). Pausa congela el temporizador.
4. `box_shelf.tscn` (Mueblecajas de PUL-008) con tres spawners S/M/L y `spice_shelf.tscn` con tres
   slots (PUL-015) precargados con sal, pimentón y pimentón picante.

## Constraints
- `.tscn` con el MCP o el editor; no inventes uid. Escenas pequeñas: una por entidad (ADR-003 §1).
- La lógica contextual vive en el **receptor** (ADR-003 §4): la caja decide si el objeto en la mano la llena o la condimenta.
- Datos de balance solo en `.tres` (ADR-001). Paridad M0: valores de Unity; D8–D10 son M1.
- No portes el doble temporizador ni el color literal de `Kitchen.cs:60-63`.

## Acceptance
- [ ] AC1 Interactuar con la nevera con mano vacía pone un pulpo crudo en la mano; con mano llena no hace nada → `test_item_spawner.gd`.
- [ ] AC2 Olla: pulpo crudo → tras 5,0 s de juego queda cocido; con el árbol en pausa no avanza; con mano vacía se recoge cocido; un pulpo cocido o una caja se rechazan → `test_cooking_station.gd`.
- [ ] AC3 Cada spawner de la estantería da su caja S/M/L; las especias se cogen y se pueden devolver a su slot → `test_shelves.gd`.
- [ ] AC4 Captura de la olla cociendo con su barra, en `docs/evidence/PUL-017/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
