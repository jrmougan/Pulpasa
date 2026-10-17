---
id: PUL-187
title: Asignar materiales planos v3 a entorno, comida, cajas y personajes
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-182, PUL-183]
orca_task: null
unity_sources: []
owns: [godot/assets/models/environment/romeria_v2/*.glb.import, godot/assets/models/characters/cook/*.glb.import, godot/assets/models/food/**/*.glb.import, godot/assets/models/items/box/*.glb.import, godot/assets/models/_pipeline/*.glb.import, godot/entities/items/box.tscn, godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn, godot/entities/player/player.tscn, godot/entities/player/materials/**, godot/tests/unit/test_items_and_env_v3.gd*, docs/evidence/PUL-187/**, docs/backlog/PUL-187-materiales-entorno-comida-y-personajes-v3.md]
touches_scenes: [godot/entities/items/box.tscn, godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn, godot/entities/player/player.tscn]
---

## Target
Vincular los materiales planos de `godot/assets/materials/v3/` al entorno de la romería (`environment/romeria_v2/**`, resolviendo el cartel superior vacío `env_sign`/`env_board` y la regla de `env_plate` de `docs/art/art-bible.md` §3.2 y §5.2), a los ingredientes (`octopus`, `cachelos`), a las cajas (`box`) y a los cocineros (`player`), garantizando los contrastes de estado y de §3.4.

## Change
1. En `godot/assets/models/environment/romeria_v2/*.glb.import` (§3.1, §3.2 y §5.2):
   - Mantener `materials/extract=0` y mapear `_subresources["materials"]` a `res://assets/materials/v3/`:
     - `env_ground` → `mat_ground_sand.tres` (`#C4A882`)
     - `env_foliage` → `mat_meadow_green.tres` (`#4FA05A`)
     - `mat_granite_masonry` y `mat_paint_worn_grey` → `mat_wall_granite.tres` (`#9A948C`)
     - `mat_wood_raw` (mesas/bancos) → `mat_potato_raw.tres` (`#8E6B47`)
     - `env_atlas` (carpa principal) → `mat_brand_red.tres` (`#C8402F`)
     - **`env_plate` (`tent_plate` en `tent.glb.import`) → `mat_tent_plate.tres`** (conserva el logotipo **PulpaSA** en el faldón delantero del toldo, §3.2).
     - **`env_sign` y `env_board` (`tent_structure` en `tent.glb.import`) → `mat_hidden_alpha.tres`** (oculta con alfa `0.0` el cartel superior vacío sobre el toldo y las dos pizarras traseras sin remodelar `tent.glb`, §5.2).
2. En `godot/assets/models/food/**/*.glb.import`, `godot/entities/items/octopus.tscn` y `godot/entities/items/cachelos.tscn` (§6.1):
   - Pulpo crudo (`octopus_raw.glb.import`) → `mat_octopus_raw.tres` (`#E0AFB2`); cocido (`octopus_cooked.glb.import`) → `mat_octopus_cooked.tres` (`#B8283D`, contraste crudo/cocido **3.21 : 1**); estado `BURNT` → `mat_state_burnt.tres` (`#2A2320`, contraste crudo/quemado **8.05 : 1**).
   - Cachelo crudo (`cachelos_raw.glb.import`) → `mat_potato_raw.tres` (`#8E6B47`); cocido (`cachelos_cooked.glb.import`) → `mat_cachelos_cooked.tres` (`#F2D56B`, contraste crudo/cocido **3.34 : 1**); estado `BURNT` → `mat_state_burnt.tres` (`#2A2320`, contraste cocido/quemado **10.67 : 1**).
3. En `godot/assets/models/items/box/*.glb.import` y `godot/entities/items/box.tscn` (§6.1 y §6.2):
   - Exterior de caja (`box_outside`, `mat_tray_plastic_red`) → `mat_brand_red.tres` (`#C8402F`).
   - Interior de caja (`box_inside`) → `mat_surface_top.tres` (`#EDE8DF`, contraste con el exterior **4.07 : 1**).
   - Capas de pulpo cortado (`FillHalf`, `FillFull`, `octopus_pieces`) → `mat_octopus_cooked.tres` (`#B8283D`, contraste **5.05 : 1** sobre el fondo `#EDE8DF`).
   - Capa de cachelos (`CachelosLayer`) → `mat_cachelos_cooked.tres` (`#F2D56B`, contraste **4.26 : 1** sobre la cama de pulpo `#B8283D`).
4. En `godot/assets/models/characters/cook/*.glb.import`, `godot/entities/player/player.tscn` y `godot/entities/player/materials/**`:
   - Delantal/pañuelo y aro `ring_active_p1.tres` de J1 en `#2F6FB5` (`mat_p1_blue.tres`); delantal/pañuelo y aro `ring_active_p2.tres` de J2 en `#F2C230` (`mat_p2_amber.tres`); camisa/gorro en `#F7F4EC` (`mat_ui_cream.tres`); pantalón en `#1D3557` (`mat_brand_navy.tres`); piel en `#E0AFB2` (`mat_octopus_raw.tres`).
5. Añadir `godot/tests/unit/test_items_and_env_v3.gd` que verifique `tent.glb` (`env_sign` y `env_board` con `mat_hidden_alpha.tres` y `env_plate` con `mat_tent_plate.tres`), los contrastes ≥ 3:1 de los estados de `octopus.tscn`, `cachelos.tscn` y `box.tscn`, y los colores de J1/J2.

## Constraints
- No remodelar ningún `.glb` ni alterar `Marker3D` (`Anchor_Hold`, `Anchor_Sticker_*`).
- Mantener `materials/extract=0` en todos los `.glb.import`.

## Acceptance
- [ ] AC1 Given `tent.glb` instanciado en `test_items_and_env_v3.gd`, When se inspeccionan los materiales de `tent_structure` y `tent_plate`, Then las superficies `env_sign` y `env_board` usan `mat_hidden_alpha.tres` (`albedo_color.a == 0.0`) y `tent_plate` usa `mat_tent_plate.tres` con la textura de marca PulpaSA.
- [ ] AC2 Given `octopus.tscn` y `cachelos.tscn` en sus 3 estados (`RAW`, `COOKED`, `BURNT`), When `test_items_and_env_v3.gd` mide sus albedos, Then coinciden con `#E0AFB2`/`#B8283D`/`#2A2320` (pulpo) y `#8E6B47`/`#F2D56B`/`#2A2320` (cachelos), con contraste crudo/cocido **≥ 3.20 : 1** (`3.21 : 1` y `3.34 : 1`).
- [ ] AC3 Given `box.tscn`, When `test_items_and_env_v3.gd` inspecciona el exterior, el interior, `FillFull` y `CachelosLayer`, Then usan `#C8402F`, `#EDE8DF`, `#B8283D` y `#F2D56B`, todos con contraste **≥ 4.0 : 1** frente a la capa inmediatamente inferior.
- [ ] AC4 Given `player.tscn` para J1 y J2, When `test_items_and_env_v3.gd` comprueba el delantal y el aro activo, Then J1 usa `#2F6FB5` y J2 usa `#F2C230` sin texturas PBR.
- [ ] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
