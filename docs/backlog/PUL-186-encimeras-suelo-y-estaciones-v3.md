---
id: PUL-186
title: Asignar materiales planos v3 y podar atrezo en encimeras y estaciones
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-182, PUL-184]
orca_task: null
unity_sources: []
owns: [godot/assets/models/furniture/counters/*.glb.import, godot/assets/models/stations/**/*.glb.import, godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/cachelos_storage.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/trash_bin.tscn, godot/entities/stations/slot.tscn, godot/tests/integration/test_stations_v3.gd*, docs/evidence/PUL-186/**, docs/backlog/PUL-186-encimeras-suelo-y-estaciones-v3.md]
touches_scenes: [godot/entities/environment/kitchen_layout.tscn, godot/entities/stations/kitchen.tscn, godot/entities/stations/octopus_storage.tscn, godot/entities/stations/cachelos_storage.tscn, godot/entities/stations/box_shelf.tscn, godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/entities/stations/trash_bin.tscn, godot/entities/stations/slot.tscn]
---

## Target
Vincular los materiales planos de `godot/assets/materials/v3/` a los módulos de encimera (`furniture/counters/**`) y a todas las estaciones de cocina (`stations/**`), ocultando el atrezo decorativo de Z1 y Z2 según `docs/art/art-bible.md` §3, §5.1 y §5.3, y reforzando la visibilidad del vapor `Steam` en `kitchen.tscn` (absorbiendo la parte de escena de `PUL-144`).

## Change
1. En los `.glb.import` de `godot/assets/models/furniture/counters/*.glb.import` y `godot/assets/models/stations/**/*.glb.import`:
   - Mantener `materials/extract=0` y mapear cada slot de `_subresources["materials"]` a su recurso externo de `res://assets/materials/v3/mat_*.tres` (`use_external/enabled = true`, `use_external/path = "res://assets/materials/v3/..."`) según la tabla de `docs/art/art-bible.md` §3.1:
     - Tableros superiores y tablas de corte (`mat_wood_varnished`, `mat_wood_cut`, `mat_steel_brushed_top`) → `mat_surface_top.tres` (`#EDE8DF`).
     - Faldones/frentes de encimera, zócalos y marco de puestos → `mat_brand_navy.tres` (`#1D3557`).
     - Cuerpos metálicos de olla, tanque, estantería y cubo (`mat_steel_brushed`, `mat_alu_cast`, `mat_galvanized`, `mat_chrome`, `mat_paint_worn_grey`, `mat_brass`) → `mat_wall_granite.tres` (`#9A948C`).
     - Muros (`mat_granite_masonry`) → `mat_wall_granite.tres` (`#9A948C`).
     - Sacos de arpillera (`mat_burlap`, `mat_twine_rope`) → `mat_ground_sand.tres` (`#C4A882`).
     - Boca interior de olla y cubo (`mat_iron_cast`) → `mat_state_burnt.tres` (`#2A2320`).
     - Agua del tanque (`water_surface`) → `mat_p1_blue.tres` (`#2F6FB5`) y espuma (`water_foam`) → `mat_ui_cream.tres` (`#F7F4EC`).
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
     - Asignar el cuerpo de `SweetDressing` a `mat_paprika_sweet.tres` (`#D6361F`, contraste **3.91 : 1** sobre `#EDE8DF`), el de `HotDressing` a `mat_paprika_hot.tres` (`#8F1A14`, contraste **7.40 : 1** sobre `#EDE8DF`), su collar superior a `mat_surface_top.tres` (`#EDE8DF`) y el cuenco de `CachelosBowl` a `mat_brand_navy.tres` (`#1D3557`) con cachelos en `mat_cachelos_cooked.tres` (`#F2D56B`, contraste **8.54 : 1**).
4. Añadir `godot/tests/integration/test_stations_v3.gd` que verifique la poda de atrezo (`is_visible_in_tree() == false`), la permanencia de `SizePanel_*` en el árbol, los materiales planos v3 sin texturas PBR y la emisión visible de `Steam` al cocer.

## Constraints
- No borrar del árbol los nodos `SizePanel_large`, `SizePanel_medium` ni `SizePanel_small` en `box_shelf.tscn` (solo `visible = false`).
- No modificar posiciones de estaciones, colisiones ni `Marker3D`.

## Acceptance
- [ ] AC1 Given los `.glb.import` de `furniture/counters/` y `stations/`, When se ejecutan `test_assets_models.gd` y `test_stations_v3.gd`, Then todos tienen `materials/extract == 0` y ningún `MeshInstance3D` visible de encimeras o estaciones usa recursos de `res://assets/materials/v2/` ni `kitchen_floor_dirt.tres`.
- [ ] AC2 Given `kitchen_layout.tscn`, `kitchen.tscn`, `octopus_storage.tscn` y `box_shelf.tscn`, When `test_stations_v3.gd` inspecciona sus sub-mallas de atrezo (`props_board`, `props_crock`, `gas_bottle`, `pump`, `cartons`, `SizePanel_*`, `labels`), Then todas tienen `is_visible_in_tree() == false` y `box_shelf.find_children("SizePanel_*", "MeshInstance3D", true, false).size() == 3`.
- [ ] AC3 Given `seasoning_station.tscn`, When `test_stations_v3.gd` comprueba los soportes y dispensadores, Then las 15 sub-mallas `CounterArrow_*`/`Label_*`/`ServiceArrow_*` están ocultas, y los contrastes de `SweetDressing` (`#D6361F`) y `HotDressing` (`#8F1A14`) frente a `ServiceMat` (`#EDE8DF`) y de los cachelos (`#F2D56B`) frente al cuenco (`#1D3557`) son todos **≥ 3.90 : 1** (`3.91 : 1`, `7.40 : 1` y `8.54 : 1`).
- [ ] AC4 Given `kitchen.tscn` cociendo un ingrediente, When `test_stations_v3.gd` inspecciona `Steam`, Then `Steam.emitting == true` con partículas visibles sobre la boca `#2A2320`.
- [ ] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
