---
id: PUL-017
title: Crear las estaciones - nevera, olla y estanterías de cajas y especias
status: review
milestone: M0
role: gameplay-engineer
deps: [PUL-016]
orca_task: null
unity_sources: [Assets/Scripts/Game/OctopusSwapner.cs, Assets/Scripts/Game/Kitchen.cs, Assets/Scripts/UI/KitchenProgress.cs, Assets/Scripts/Game/Box.cs, Assets/Prefabs/KitchenStations/**]
owns: [godot/entities/stations/item_spawner.gd, godot/entities/stations/item_spawner.gd.uid, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/cooking_station.gd, godot/entities/stations/cooking_station.gd.uid, godot/entities/stations/box_shelf.tscn, godot/entities/stations/spice_shelf.tscn, godot/tests/integration/test_item_spawner.gd, godot/tests/integration/test_item_spawner.gd.uid, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_cooking_station.gd.uid, godot/tests/integration/test_shelves.gd, godot/tests/integration/test_shelves.gd.uid, godot/entities/stations/sandbox/**, godot/entities/stations/slot.gd, godot/tests/integration/test_slot.gd, docs/evidence/PUL-017/**]
touches_scenes: [godot/entities/stations/octopus_storage.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/spice_shelf.tscn]
---

## Target
Fase 6 de M0, estaciones (`scene-tree.md` §3 `entities/stations/`).

## Change
1. `item_spawner.gd` genérico (`@export scene`, `@export data`): instancia el objeto **en la mano**
   del actor si está vacía (ADR-003 §6). Sustituye `OctopusSpawner` y el modo spawner de `Box`.
2. `octopus_storage.tscn` (nevera placeholder) con el spawner de pulpo.
3. `kitchen.tscn` (raíz en los grupos `interactable` y `kitchen`, ADR-003 §4) + `cooking_station.gd`: acepta un pulpo crudo de la mano, lo cuece en
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
- [x] AC1 Interactuar con la nevera con mano vacía pone un pulpo crudo en la mano; con mano llena no hace nada → `test_item_spawner.gd`.
- [x] AC2 Olla: pulpo crudo → tras 5,0 s de juego queda cocido; con el árbol en pausa no avanza; con mano vacía se recoge cocido; un pulpo cocido o una caja se rechazan → `test_cooking_station.gd`.
- [x] AC3 Cada spawner de la estantería da su caja S/M/L; las especias se cogen y se pueden devolver a su slot → `test_shelves.gd`.
- [x] AC4 Captura de la olla cociendo con su barra, en `docs/evidence/PUL-017/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan
- `item_spawner.gd` (`class_name ItemSpawner extends Node`, raíz de un cuerpo): `@export scene`,
  `@export data` (se asigna a `data` del objeto antes de entrar al árbol). Mano vacía →
  `holder.pick_up(instancia)`; mano llena → consume la pulsación sin efecto (paridad
  `OctopusSpawner`: no suelta). AC1 → `test_item_spawner.gd`.
- `cooking_station.gd` (`class_name CookingStation extends StaticBody3D`): señales locales
  `cooking_started`/`cooking_finished(ingredient: Ingredient)` (signals.md §4). Un solo reloj
  acumulado en `_physics_process` (la pausa lo congela), `%CookBar`, `%BoilAudio`, `%AnchorPoint`.
  El pulpo en la olla se congela y sale de la capa `interactable` (como `Slot`). AC2 →
  `test_cooking_station.gd`.
- Escenas `octopus_storage`, `kitchen`, `box_shelf`, `spice_shelf` generadas con un script tipado
  (`PackedScene.pack` con `GEN_EDIT_STATE_INSTANCE`). `spice_shelf` = 3 `slot.tscn` con
  `initial_item = seasoning.tscn` + `initial_item_data` (nuevo export opcional de `slot.gd`,
  aprobado por el coordinador). AC3 → `test_shelves.gd` (+ 2 tests nuevos en `test_slot.gd`).
- AC4: sandbox `entities/stations/sandbox/stations_sandbox.tscn` (owns ampliado, aprobado).

## Evidence
- `tools/verify.sh` en verde: 304 tests GUT, gdformat/gdlint/import/smoke OK.
- Tests: `test_item_spawner.gd` (8), `test_cooking_station.gd` (14, incluida la pausa real del árbol
  durante 30 frames de física), `test_shelves.gd` (7), `test_slot.gd` (+2 `test_pul017_*`).
- Capturas (MCP `run_project` background + `simulate_input` de movimiento/`p1_interact` con
  `mcp_bridge` activado en caliente, como en PUL-016), en `docs/evidence/PUL-017/`:
  `ac4-estaciones.png` (nevera, olla, estantería de cajas S/M/L y de especias),
  `ac4-olla-cociendo.png` + `-zoom` (pulpo crudo en la olla con la barra de cocción),
  `ac4-pulpo-cocido-en-mano.png` + `-zoom` (recogido cocido con la mano vacía). `get_debug_output`
  sin errores.
- Decisiones:
  - Mano con un objeto no válido (olla: pulpo cocido, caja, olla ocupada; nevera/estantería con la
    mano llena): se consume la pulsación sin efecto (paridad Unity: `detector.Current.Interact`
    nunca suelta). Los tests comprueban que el objeto sigue en la mano.
  - `scene-tree.md` §3 lista `%CookTimer (Timer)` en `kitchen.tscn`; no se añade: el reloj es un
    acumulador en `_physics_process` (un solo temporizador, pausable y testeable con `simulate`).
    Es un nodo interno, no API pública; si se quiere alinear el documento, lo hace el arquitecto.
  - Tolerancia `TIME_EPSILON = 1e-4` al acumular `delta` (50 × 0,1 s ≠ 5,0 exacto).
  - El aspecto cocido lo pone `Ingredient.set_cooked()` (material en datos), no el color literal.
  - Spawners de la estantería: `Highlightable` sin nombre único (hay tres en la misma escena);
    el detector lo busca como hijo directo.
- Pendiente para revisión visual: la posición de las cajas dentro del mueble está convertida de
  `Mueblecajas.prefab` (sobre el estante bajo, frente −Z); la del nivel es de la fase 8. La
  estantería de especias usa tres mesas cuadradas de `slot.tscn` (no hay modelo de mueble de
  especias).
