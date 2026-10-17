---
id: PUL-187
title: Asignar materiales planos v3 a entorno, comida, cajas y personajes
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-182, PUL-183]
orca_task: null
unity_sources: []
owns: [godot/assets/models/environment/romeria_v2/*.glb.import, godot/assets/models/characters/cook/*.glb.import, godot/assets/models/food/**/*.glb.import, godot/assets/models/items/box/*.glb.import, godot/assets/models/_pipeline/**/*.glb.import, godot/entities/items/box.tscn, godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn, godot/entities/player/player.tscn, godot/tests/unit/test_items_and_env_v3.gd*, docs/evidence/PUL-187/**, docs/backlog/PUL-187-materiales-entorno-comida-y-personajes-v3.md]
touches_scenes: [godot/entities/items/box.tscn, godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn, godot/entities/player/player.tscn]
---

## Target
Vincular los materiales planos de `godot/assets/materials/v3/` al entorno de la romería (`environment/romeria_v2/**`, resolviendo el cartel superior vacío `env_sign`/`env_board` y la regla de `env_plate` de `docs/art/art-bible.md` §3.2 y §5.2), a los ingredientes (`octopus`, `cachelos`), a las cajas (`box`) y a los cocineros (`player`), garantizando los contrastes de estado y de §3.4.

## Change
1. En `godot/assets/models/environment/romeria_v2/*.glb.import` (§3.1, §3.2 y §5.2):
   - Configurar explícitamente `gltf/embedded_image_handling = 0` (no extraer PNGs) y `materials/extract = 0`, mapeando cada slot real de `_subresources["materials"]` a su recurso externo de `res://assets/materials/v3/mat_*.tres` derivando estrictamente de `docs/evidence/PUL-181/slots_reales.md` §1 y §2 (tabla normativa única):
     - `back_e.glb` y `back_w.glb`: `mat_paint_worn_grey` (`mat_wall_granite.tres`), `env_fence` (`mat_wall_granite.tres`), `mat_ground_dirt` (`mat_ground_sand.tres`), `mat_grass` (`mat_meadow_green.tres`), `mat_steel_brushed` (`mat_wall_granite.tres`), `mat_plastic_red` (`mat_brand_red.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_paint_worn_beige` (`mat_ground_sand.tres`), `env_atlas` (`mat_wall_granite.tres`), `mat_plastic_blue` (`mat_p1_blue.tres`), `mat_rubber` (`mat_state_burnt.tres`), `mat_burlap` (`mat_ground_sand.tres`), `mat_cardboard` (`mat_ground_sand.tres`), `mat_wood_dark` (`mat_potato_raw.tres`), `mat_wood_used` (`mat_potato_raw.tres`), `env_foliage` (`mat_meadow_green.tres`), `env_fern` (`mat_meadow_green.tres`), `mat_granite` (`mat_wall_granite.tres`).
     - `ground_e.glb` y `ground_w.glb`: `mat_ground_dirt` (`mat_ground_sand.tres`), `mat_grass` (`mat_meadow_green.tres`), `env_fern` (`mat_meadow_green.tres`), `env_atlas` (`mat_wall_granite.tres`), `mat_steel_dark` (`mat_brand_navy.tres`), podando en escena `env_track` y `env_puddle` (`visible = false`).
     - `props_e.glb` y `props_w.glb` (mesas, bancos y atrezo): `mat_wood_dark` (`mat_potato_raw.tres`), `mat_wood_used` (`mat_potato_raw.tres`), `mat_rubber` (`mat_state_burnt.tres`), `env_atlas` (`mat_wall_granite.tres`), `mat_emissive_bulb` (`mat_p2_amber.tres`/oculto), `mat_steel_dark` (`mat_brand_navy.tres`), `mat_burlap` (`mat_ground_sand.tres`), `mat_cardboard` (`mat_ground_sand.tres`), `mat_skin_dark` (`mat_potato_raw.tres`), `mat_food_octopus_pieces` (`mat_octopus_cooked.tres`), `mat_skin_light` (`mat_octopus_raw.tres`), `mat_clay` (`mat_potato_raw.tres`), `env_fern` (`mat_meadow_green.tres`).
     - `tent.glb`: `mat_canvas_red` (`mat_brand_red.tres`), `mat_canvas_paper` (`mat_ui_cream.tres`), `mat_cloth_pants` (`mat_brand_navy.tres`), `mat_rubber` (`mat_state_burnt.tres`), `env_atlas` (`mat_wall_granite.tres`), `mat_emissive_bulb` (`mat_p2_amber.tres`/oculto), `mat_paint_worn_grey` (`mat_wall_granite.tres`).
     - **Placa de marca PulpaSA**: `env_plate` (`tent_plate` en `tent.glb.import`) → `mat_tent_plate.tres`, con textura albedo `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` (§3.2).
     - **Carteles podados**: `env_sign` y `env_board` (`tent_structure` en `tent.glb.import`) → `mat_hidden_alpha.tres` (oculta con alfa `0.0` el cartel superior vacío sobre el toldo y las dos pizarras traseras sin remodelar `tent.glb`, §5.2).
2. En `godot/assets/models/food/**/*.glb.import`, `godot/entities/items/octopus.tscn` y `godot/entities/items/cachelos.tscn` (§6.1):
   - Configurar explícitamente `gltf/embedded_image_handling = 0` y `materials/extract = 0` en `octopus.glb.import`, `octopus_pieces.glb.import`, `cachelos.glb.import` y `cachelos_pieces.glb.import`.
   - En `octopus.glb.import`: slots reales `mat_food_octopus_raw` (`mat_octopus_raw.tres`), `mat_food_octopus_cooked` (`mat_octopus_cooked.tres`), `mat_food_octopus_burnt` (`mat_state_burnt.tres`) y `atlas_octopus` (`mat_octopus_cooked.tres`, según `slots_reales.md` §2 y §4.2). En `octopus.tscn`: conmutación de estado mediante visibilidad de los nodos de malla `octopus_raw` (`mat_octopus_raw.tres` `#E0AFB2`), `octopus_cooked` (`mat_octopus_cooked.tres` `#B8283D`, contraste crudo/cocido **3.21 : 1**) y `octopus_burnt` (`mat_state_burnt.tres` `#2A2320`, contraste crudo/quemado **8.05 : 1**).
   - En `octopus_pieces.glb.import`: slots reales `mat_food_octopus_pieces` (`mat_octopus_cooked.tres`) y `atlas_octopus` (`mat_octopus_cooked.tres`).
   - En `cachelos.glb.import`: slots reales `mat_food_potato_raw` (`mat_potato_raw.tres`), `mat_food_potato_cooked` (`mat_cachelos_cooked.tres`), `mat_food_potato_burnt` (`mat_state_burnt.tres`) y `atlas_cachelos` (`mat_cachelos_cooked.tres`). En `cachelos.tscn`: conmutación de estado mediante visibilidad de los nodos de malla `cachelos_raw` (`mat_potato_raw.tres` `#8E6B47`), `cachelos_cooked` (`mat_cachelos_cooked.tres` `#F2D56B`, contraste crudo/cocido **3.34 : 1**) y `cachelos_burnt` (`mat_state_burnt.tres` `#2A2320`, contraste cocido/quemado **10.67 : 1**).
   - En `cachelos_pieces.glb.import`: slots reales `mat_food_potato_cooked` (`mat_cachelos_cooked.tres`) y `atlas_cachelos` (`mat_cachelos_cooked.tres`).
3. En `godot/assets/models/items/box/*.glb.import` y `godot/entities/items/box.tscn` (§6.1 y §6.2):
   - Configurar explícitamente `gltf/embedded_image_handling = 0` y `materials/extract = 0` en `box.glb.import`.
   - Mapear el slot real exterior `mat_plastic_red` → `mat_brand_red.tres` (`#C8402F`).
   - Mapear el slot `atlas_box` / interior de caja en `box.tscn` → `mat_surface_top.tres` (`#EDE8DF`, contraste con el exterior **4.07 : 1**).
   - Conservar los slots funcionales `mat_outline_hull` (shader selección/outline) y `mat_sticker_atlas` (pegatinas 3D).
   - Capas de pulpo cortado (`FillHalf`, `FillFull`, `octopus_pieces`) → `mat_octopus_cooked.tres` (`#B8283D`, contraste **5.05 : 1** sobre el fondo `#EDE8DF`).
   - Capa de cachelos (`CachelosLayer`) → `mat_cachelos_cooked.tres` (`#F2D56B`, contraste **4.26 : 1** sobre la cama de pulpo `#B8283D`).
4. En `godot/assets/models/characters/cook/*.glb.import`, `godot/entities/player/player.tscn` y `godot/assets/models/_pipeline/**/*.glb.import`:
   - Configurar `gltf/embedded_image_handling = 0` y `materials/extract = 0` en `cook.glb.import` (slots reales exhaustivos de `slots_reales.md`: `mat_cloth_player_1` a `mat_p1_blue.tres`, `mat_cloth_player_2` a `mat_p2_amber.tres`, `mat_cloth_shirt` a `mat_ui_cream.tres`, `mat_cloth_pants` a `mat_brand_navy.tres`, `mat_skin_light` a `mat_octopus_raw.tres`, `mat_skin_dark` a `mat_potato_raw.tres`, `mat_rubber` a `mat_state_burnt.tres`, `mat_wood_dark` a `mat_potato_raw.tres`, `mat_canvas_red` a `mat_brand_red.tres`, `mat_cook_atlas` a `mat_brand_navy.tres`).
   - Configurar `gltf/embedded_image_handling = 0` y `materials/extract = 0` en los modelos de prueba de `_pipeline/` (`materials_v2_test.glb`: `mat_steel_brushed`, `mat_plastic_red`, `mat_wood_used`; `test_cube.glb`: `mat_wood_light`, `mat_canvas_stripe`).
   - En `player.tscn`: delantal/pañuelo y aro `ring_active_p1.tres` de J1 en `#2F6FB5` (`mat_p1_blue.tres`); delantal/pañuelo y aro `ring_active_p2.tres` de J2 en `#F2C230` (`mat_p2_amber.tres`); camisa/gorro en `#F7F4EC` (`mat_ui_cream.tres`); pantalón en `#1D3557` (`mat_brand_navy.tres`); piel en `#E0AFB2` (`mat_octopus_raw.tres`).
5. Añadir `godot/tests/unit/test_items_and_env_v3.gd` que verifique `tent.glb` (`env_sign` y `env_board` con `mat_hidden_alpha.tres` y `env_plate` con `mat_tent_plate.tres`), los contrastes ≥ 3:1 de los estados de `octopus.tscn`, `cachelos.tscn` y `box.tscn`, y los colores de J1/J2.

## Constraints
- No remodelar ningún `.glb` ni alterar `Marker3D` (`Anchor_Hold`, `Anchor_Sticker_*`).
- Configurar `gltf/embedded_image_handling = 0` y `materials/extract = 0` en todos los `.glb.import` modificados.

## Acceptance
- [ ] AC1 Given `tent.glb` instanciado en `test_items_and_env_v3.gd`, When se inspeccionan los materiales de `tent_structure` y `tent_plate`, Then las superficies `env_sign` y `env_board` usan `mat_hidden_alpha.tres` (`albedo_color.a == 0.0`) y `tent_plate` usa `mat_tent_plate.tres` con textura albedo `res://assets/models/environment/romeria_v2/tent_plate_albedo.png`.
- [ ] AC2 Given `octopus.tscn` y `cachelos.tscn` en sus 3 estados (`RAW`, `COOKED`, `BURNT`), When `test_items_and_env_v3.gd` mide sus albedos, Then coinciden con `#E0AFB2`/`#B8283D`/`#2A2320` (pulpo) y `#8E6B47`/`#F2D56B`/`#2A2320` (cachelos), con contraste crudo/cocido **≥ 3.20 : 1** (`3.21 : 1` y `3.34 : 1`).
- [ ] AC3 Given `box.tscn`, When `test_items_and_env_v3.gd` inspecciona el exterior, el interior, `FillFull` y `CachelosLayer`, Then usan `#C8402F`, `#EDE8DF`, `#B8283D` y `#F2D56B`, todos con contraste **≥ 4.0 : 1** frente a la capa inmediatamente inferior.
- [ ] AC4 Given `player.tscn` para J1 y J2, When `test_items_and_env_v3.gd` comprueba el delantal y el aro activo, Then J1 usa `#2F6FB5` y J2 usa `#F2C230` sin texturas PBR.
- [ ] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
