---
id: PUL-186
title: Asignar materiales planos v3 y podar atrezo en encimeras y estaciones
status: done
milestone: M3f
role: asset-pipeline
deps: [PUL-182]
orca_task: task_bc9316a466ee
unity_sources: []
owns: [godot/assets/models/furniture/counters/*.glb.import, godot/assets/models/stations/**/*.glb.import, godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/cachelos_storage.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/trash_bin.tscn, godot/entities/stations/slot.tscn, godot/entities/stations/seasoning_dispenser.gd*, godot/tests/integration/test_stations_v3.gd*, docs/evidence/PUL-186/**, docs/backlog/PUL-186-encimeras-suelo-y-estaciones-v3.md]
touches_scenes: [godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/cachelos_storage.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/trash_bin.tscn, godot/entities/stations/slot.tscn]
---

## Target
Vincular los materiales planos de `godot/assets/materials/v3/` a los módulos de encimera (`furniture/counters/**`) y a todas las estaciones de cocina (`stations/**`), ocultando el atrezo decorativo de Z1 y Z2 según `docs/art/art-bible.md` §3, §5.1 y §5.3, y reforzando la visibilidad del vapor `Steam` en `kitchen.tscn` (absorbiendo la parte de escena de `PUL-144`).

## Change
1. En los `.glb.import` de `godot/assets/models/furniture/counters/*.glb.import` y `godot/assets/models/stations/**/*.glb.import`:
   - Configurar explícitamente `gltf/embedded_image_handling = 0` (para evitar la re-extracción de texturas PNG) y `materials/extract = 0`.
   - Mapear cada slot real de `_subresources["materials"]` a su recurso externo de `res://assets/materials/v3/mat_*.tres` (`use_external/enabled = true`, `use_external/path = "res://assets/materials/v3/..."`) derivando estrictamente de la tabla normativa de `docs/evidence/PUL-181/slots_reales.md` §1 y §2 (única fuente de verdad) y `docs/art/art-bible.md` §3.1:
     - Tableros superiores (`mat_steel_brushed_top`) → `mat_surface_top.tres` (`#EDE8DF`).
     - Estructuras metálicas y perfiles (`mat_steel_brushed`, `mat_steel_brushed_mid`) → `mat_wall_granite.tres` (`#9A948C`).
     - Zócalos, faldones y elementos oscuros (`mat_steel_dark`) → `mat_brand_navy.tres` (`#1D3557`).
     - Atlas de encimeras (`counters_atlas`) → `mat_wall_granite.tres` (`#9A948C`), aplicando en su escena `.tscn` `surface_material_override` a `mat_brand_navy.tres` (`#1D3557`) en los frentes que requieran faldón azul marino corporativo.
     - Estructura de estación de sazonado (`seasoning_station_atlas`) → `mat_surface_top.tres` (`#EDE8DF`).
     - Almacenes y estaciones de trabajo:
       - `box_shelf.glb`: `mat_cardboard` (`mat_ground_sand.tres`), `atlas_box` (`mat_surface_top.tres`), `mat_steel_brushed_mid` (`mat_wall_granite.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_steel_brushed_top` (`mat_surface_top.tres`), `mat_plastic_blue` (`mat_p1_blue.tres`), `mat_plastic_red` (`mat_brand_red.tres`), conservando el shader técnico `mat_outline_hull`.
       - `cachelos_storage.glb`: `mat_food_potato_raw` (`mat_potato_raw.tres`), `atlas_cachelos` (`mat_cachelos_cooked.tres`), `mat_burlap` (`mat_ground_sand.tres`), `atlas_cachelos_storage` (`mat_potato_raw.tres`).
       - `octopus_storage.glb`: `mat_food_octopus_raw` (`mat_octopus_raw.tres`), `atlas_octopus` (`mat_octopus_cooked.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_rubber` (`mat_state_burnt.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`), `mat_plastic_blue` (`mat_p1_blue.tres`), `mat_glass_water` (`mat_p1_blue.tres`), `mat_plastic_red` (`mat_brand_red.tres`), `mat_canvas_paper` (`mat_ui_cream.tres`).
       - `pot.glb`: `mat_plastic_blue` (`mat_p1_blue.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`), `mat_rubber_hose_red` (`mat_brand_red.tres`), `mat_rubber_hose_green` (`mat_meadow_green.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_rubber` (`mat_state_burnt.tres`), `mat_steel_brushed_mid` (`mat_wall_granite.tres`), `mat_plastic_red` (`mat_brand_red.tres`), `pot_water` (`mat_p1_blue.tres`), `mat_emissive_bulb` (`mat_p2_amber.tres`).
       - `order_stand.glb`: `mat_canvas_stand_1` (`mat_brand_red.tres`), `mat_canvas_paper` (`mat_ui_cream.tres`), `mat_canvas_stand_2` (`mat_p1_blue.tres`), `mat_canvas_stand_3` (`mat_p2_amber.tres`), `mat_canvas_stand_4` (`mat_meadow_green.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_rubber` (`mat_state_burnt.tres`), `mat_steel_brushed_top` (`mat_surface_top.tres`), `mat_steel_brushed_mid` (`mat_wall_granite.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`), `order_stand_atlas` (`mat_brand_navy.tres`), `mat_emissive_screen` (`mat_surface_top.tres`), conservando los slots funcionales `delivery_zone_off` y `kiosk_delivery_signs`.
       - `trash_bin.glb`: `mat_plastic_red` (`mat_brand_red.tres`), `mat_rubber` (`mat_state_burnt.tres`), `mat_plastic_blue` (`mat_p1_blue.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`), `mat_food_tray_liner` (`mat_surface_top.tres`), `mat_cloth_pants` (`mat_brand_navy.tres`).
       - `seasoning_station/`: `cachelos_bowl.glb` con `mat_clay` (`mat_potato_raw.tres`) y `mat_food_potato_cooked` (`mat_cachelos_cooked.tres`); `seasoning_dispenser.glb` con `mat_steel_dark` (`mat_brand_navy.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`) y `seasoning_signs` (funcional).
     - Sacos de arpillera (`mat_burlap`) y embalaje (`mat_cardboard`) → `mat_ground_sand.tres` (`#C4A882`).
     - Gomas y juntas (`mat_rubber`) → `mat_state_burnt.tres` (`#2A2320`).
     - Pasaplatos (`counter_pass_signs`) → `mat_p2_amber.tres` (`#F2C230`).
2. En `godot/entities/environment/kitchen_layout.tscn`:
   - Sustituir `Floor/Mesh.material_override` (`kitchen_floor_dirt.tres`) por `res://assets/materials/v3/mat_ground_sand.tres` (`#C4A882`).
   - Ocultar (`visible = false`) los 5 nodos de atrezo sobre encimeras (§5.1): `BackCounter/BackBetweenStoragePot/Model/props_crock`, `BackCounter/BackRight/Model/props_board`, `BackCounter/BackRight/Model/props_crock`, `Walls/WallLeftKitchen/Model/props_crock` y `Walls/WallRight/Model/props_board`.
3. En las escenas de estaciones (`godot/entities/stations/*.tscn`):
   - `kitchen.tscn`: ocultar `Model/Pot/pot/gas_bottle` (`visible = false`) y ajustar el `GPUParticles3D` `Steam` para que al cocer sea nítidamente visible desde la cámara ortográfica sobre el cuerpo `#9A948C` y la boca `#2A2320` (absorbiendo D2 de `PUL-144`).
   - `octopus_storage.tscn`: ocultar `Model/octopus_storage/pump` (`visible = false`).
   - `cachelos_storage.tscn`: sustituir la referencia a `res://assets/materials/v2/mat_burlap.tres` por `res://assets/materials/v3/mat_ground_sand.tres`.
   - `box_shelf.tscn`: poner `visible = false` en `cartons`, `SizePanel_large`, `SizePanel_medium`, `SizePanel_small` y `labels` (**sin borrar los nodos `SizePanel_*` del árbol** para cumplir `test_rack_panels_cannot_be_walked_into` en `test_level_01.gd`).
   - `seasoning_station.tscn`, `seasoning_dispenser.tscn` y `cachelos_bowl.tscn` (§5.3 y §6.2):
     - Ocultar (`visible = false`) las 15 sub-mallas pre-D25 `CounterArrow_*`, `Label_*` y `ServiceArrow_*` (`sweet`, `hot`, `salt`, `oil`, `potato`).
     - Asignar `ServiceMat` a `mat_surface_top.tres` (`#EDE8DF`) y `ServiceFascia` a `mat_brand_navy.tres` (`#1D3557`).
     - Asignar mediante `surface_material_override` en las instancias de los nodos de malla el cuerpo de `SweetDressing` (`paprika_sweet`) a `mat_paprika_sweet.tres` (`#D6361F`, contraste **3.91 : 1** sobre `#EDE8DF`), el de `HotDressing` (`paprika_hot`) a `mat_paprika_hot.tres` (`#8F1A14`, contraste **7.40 : 1** sobre `#EDE8DF`), su collar superior a `mat_surface_top.tres` (`#EDE8DF`) y el cuenco de `CachelosBowl` a `mat_brand_navy.tres` (`#1D3557`) con cachelos en `mat_cachelos_cooked.tres` (`#F2D56B`, contraste **8.54 : 1**).
4. Añadir `godot/tests/integration/test_stations_v3.gd` que verifique la poda de atrezo (`is_visible_in_tree() == false`), la permanencia de `SizePanel_*` en el árbol, los materiales planos v3 sin texturas PBR y la emisión visible de `Steam` al cocer.

## Constraints
- No borrar del árbol los nodos `SizePanel_large`, `SizePanel_medium` ni `SizePanel_small` en `box_shelf.tscn` (solo `visible = false`).
- No modificar posiciones de estaciones, colisiones ni `Marker3D`.

## Acceptance
- [x] AC1 Given los `.glb.import` de `furniture/counters/` y `stations/`, When se ejecutan `test_assets_models.gd` y `test_stations_v3.gd`, Then todos tienen `gltf/embedded_image_handling == 0`, `materials/extract == 0` y ningún `MeshInstance3D` visible de encimeras o estaciones usa recursos de `res://assets/materials/v2/` ni `kitchen_floor_dirt.tres`.
- [x] AC2 Given `kitchen_layout.tscn`, `kitchen.tscn`, `octopus_storage.tscn` y `box_shelf.tscn`, When `test_stations_v3.gd` inspecciona sus sub-mallas de atrezo (`props_board`, `props_crock`, `gas_bottle`, `pump`, `cartons`, `SizePanel_*`, `labels`), Then todas tienen `is_visible_in_tree() == false` y `box_shelf.find_children("SizePanel_*", "MeshInstance3D", true, false).size() == 3`.
- [x] AC3 Given `seasoning_station.tscn`, When `test_stations_v3.gd` comprueba los soportes y dispensadores, Then las 15 sub-mallas `CounterArrow_*`/`Label_*`/`ServiceArrow_*` están ocultas, y los contrastes de `SweetDressing` (`#D6361F`) y `HotDressing` (`#8F1A14`) frente a `ServiceMat` (`#EDE8DF`) y de los cachelos (`#F2D56B`) frente al cuenco (`#1D3557`) son todos **≥ 3.90 : 1** (`3.91 : 1`, `7.40 : 1` y `8.54 : 1`).
- [x] AC4 Given `kitchen.tscn` cociendo un ingrediente, When `test_stations_v3.gd` inspecciona `Steam`, Then `Steam.emitting == true` con partículas visibles sobre la boca `#2A2320`.
- [x] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
1. Volcar el árbol real (nodos, superficies y slots) de los 25 `.glb` de `furniture/counters/` y `stations/` y de las escenas dueñas, contra `slots_reales.md` §1–§2.
2. `.glb.import`: `gltf/embedded_image_handling = 0`, `materials/extract = 0` y `_subresources["materials"]` con `use_external` a `res://assets/materials/v3/` para cada slot real; los funcionales (`mat_outline_hull`, `delivery_zone_off`, `kiosk_delivery_signs`, `seasoning_signs`) quedan embebidos.
3. Escenas: suelo `mat_ground_sand`, poda de atrezo con `visible = false` (sin borrar nodos), `counters_atlas` → navy por `surface_material_override`, estación de condimentos (15 señales ocultas, `ServiceMat`/`ServiceFascia`, cuerpos y collar de dispensadores, cuenco navy) y vapor `Steam` reforzado.
4. `test_stations_v3.gd` (AC1–AC4), capturas con `xvfb-run` y `tools/verify.sh`.

## Evidence
- **Owns ampliados** (decisión del coordinador, opción C): `godot/entities/stations/seasoning_dispenser.gd*`. El cuerpo entero de `paprika_sweet`/`paprika_hot` en `seasoning_dispenser.glb` *es* la superficie `seasoning_signs`, y `_show_own_icon` la volvía transparente para poner la placa D26.7. Ahora el dispensador exporta `body_material`: si lo tiene, pinta esa superficie con él (`mat_paprika_sweet`/`mat_paprika_hot`, asignados por instancia en `seasoning_station.tscn`) y saca la placa `FrontPlate`+`FrontIcon` fuera del cuerpo (lado × 0,55, desplazada a lo largo de la normal del cartel); sin `body_material` se comporta como antes.
- **Imports** (25 `.glb.import`): `embedded_image_handling = 0`, `materials/extract = 0` y slots mapeados según `slots_reales.md` §2 y la tabla de la ficha. Tras `godot --import` ningún PNG se re-extrae ni cambia (`git status` limpio fuera de owns).
- **Faldón de encimeras** (decisión del coordinador, opción A): `counters_atlas` → `mat_wall_granite` en el import y `surface_material_override/2` → `mat_brand_navy` en los 22 módulos `counter_*`/`pass_*` de `kitchen_layout.tscn`. En la geometría real `counters_atlas` son solo tiradores y listones del frente; el panel frontal es `mat_steel_brushed` (granito), como el prototipo A aprobado (`docs/art/minimal/direccion-a-color-plano.png`). **§0.1 y §5.1 del art-bible hablan de un faldón navy completo que no corresponde ni a la geometría ni al prototipo**: lo corregirá el coordinador.
- **Collar del dispensador**: solo `paprika_sweet` tiene superficie de collar (s1, `mat_steel_dark`) → `mat_surface_top` en `seasoning_dispenser.tscn`. `paprika_hot` tiene una sola superficie (sin collar que pintar sin tocar el `.glb`, D28).
- **Cuenco**: `bowl` y la base `mat_clay` de `Portions0..4` → `mat_brand_navy`; cachelos (`mat_food_potato_cooked`) → `mat_cachelos_cooked` desde el import.
- **Vapor** (`kitchen.tscn`, D2 de PUL-144): 18 partículas (antes 8), radio 0,11 m (antes 0,07), escala 1,0–1,5, crema `#F7F4EC` con alfa pico 0,9 (antes 0,4). Contraste sobre la boca `#2A2320` ≥ 3,90 : 1 (comprobado en el test).
- **`trash_bin.tscn` y `slot.tscn`**: sin cambios de escena; les basta el import (no usan v2).
- **Tests**: `godot/tests/integration/test_stations_v3.gd`, 9 tests: imports (AC1), mallas visibles sin v2/`kitchen_floor_dirt` ni mapas PBR (AC1), suelo, atrezo oculto y `SizePanel_*` = 3 (AC2), 15 señales ocultas y contrastes 3,91 / 7,40 / 8,54 : 1 (AC3), cuerpo v3 + placa D26.7 visible fuera del cuerpo, y `Steam.emitting` al cocer con partículas visibles (AC4).
- **`tools/verify.sh`**: verde — 118 scripts, 1366/1366 tests, smoke OK.
- **Capturas** (1920×1080, `cd godot && xvfb-run -a godot --audio-driver Dummy --resolution 1920x1080 -s res://../docs/evidence/PUL-186/capture_boot.gd`): `level_01.png` (nivel completo), `seasoning_station.png` (dispensadores rojo/granate con placa e icono, cuenco navy, alfombrilla crema, zócalo navy), `kitchen_steam.png` (olla cociendo con vapor visible; sin bombona) y `box_shelf.png` (estantería sin cartones ni paneles).
- **Fuera de alcance, visto en las capturas**: el suelo y el muro moteados son de `romeria_v2` (PUL-187); la tapa abierta de la olla es la geometría de D3 de PUL-144 (pospuesta).
