---
id: PUL-017
title: Crear las estaciones - nevera, olla y estanterías de cajas y especias
status: done
milestone: M0
role: gameplay-engineer
deps: [PUL-016]
orca_task: task_b75490e607aa
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
  aprobado por el coordinador). AC3 → `test_shelves.gd` (+ 2 tests nuevos en `test_slot.gd`). Tras la revisión, sobre el mueble `Mueblecajas`.
- AC4: sandbox `entities/stations/sandbox/stations_sandbox.tscn` (owns ampliado, aprobado).

## Evidence
- `tools/verify.sh` en verde: 326 tests GUT (tras rebase y revisión), gdformat/gdlint/import/smoke OK.
- Tests: `test_item_spawner.gd` (8), `test_cooking_station.gd` (16, incluida la pausa real del árbol
  durante 30 frames de física), `test_shelves.gd` (10), `test_slot.gd` (+2 `test_pul017_*`).
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
  `Mueblecajas.prefab` (frente −Z); la colocación en el nivel es de la fase 8.
- Revisión (hallazgos 1, 3, 4):
  - `spice_shelf.tscn`: `Model` = `Mueblecajas.tscn` (como `MuebleEspecias.prefab`) + `CollisionShape3D`
    igual que `box_shelf`; slots a x −0,6/0/0,6, z −0,78 con el bote a y 0,15 sobre el mueble
    (slot a y −0,99 porque su `%Anchor` está a 1,14). La mesa de cada slot se oculta y se desactiva
    (`visible = false`, `process_mode = DISABLED`, quita también su colisión) con override en la
    instancia (`[editable path]`), sin tocar `slot.tscn`. La caja de colisión `interactable` del
    slot (1,37 m) sigue y para al jugador ~0,7 m delante del mueble; el detector llega bien.
    Tests: `test_ac3_spice_shelf_uses_box_furniture_model`, `..._hide_and_disable_their_tables`,
    `test_ac3_spices_sit_on_the_shelf_in_order`. Capturas `ac3-especia-cogida(-zoom).png` y
    `ac3-especia-devuelta(-zoom).png` (pimentón cogido y devuelto con `p1_interact`) y
    `ac4-estaciones.png` renovada. En el sandbox se giró la estantería de cajas para que su frente
    mire al jugador.
  - `Slot.anchor_offset()` (estática, cálculo global) la usan `slot.gd` y `cooking_station.gd`.
  - `test_ac2_cooked_octopus_uses_cooked_material` y `test_ac2_octopus_anchor_point_sits_on_pot_anchor`.
  - Hallazgo 2 (doc del reloj) lo cerró el producer en `c6075f0`; código del reloj sin cambios.
