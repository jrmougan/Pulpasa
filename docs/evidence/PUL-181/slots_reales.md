# Inventario real de slots de material de los archivos .glb y mapeo normativo v3

Fecha: 2026-10-17 · Tarea: PUL-181 (Ronda 2) · Autor: `game-designer` / `asset-pipeline`

Este documento extrae directamente del glTF JSON de los 40 archivos `.glb` existentes en `godot/assets/models/` la lista exhaustiva de nombres reales de mallas, nodos y slots de material. Sustituye las suposiciones y nombres inventados de la ronda 1 y fija la tabla normativa para `docs/art/art-bible.md` v3 y las fichas `PUL-182` a `PUL-189`.

---

## 1. Inventario por archivo .glb (40 archivos reales)

| # | Archivo `.glb` | Slots de material reales | Nodos / Mallas principales | Regla de asignación en v3 |
|---:|---|---|---|---|
| 1 | `assets/models/_pipeline/materials_v2_test/materials_v2_test.glb` | `mat_steel_brushed`, `mat_plastic_red`, `mat_wood_used` | Anchor_Front, materials_v2_test_frame... | Mapeo en `.glb.import` (`_subresources`) |
| 2 | `assets/models/_pipeline/test_cube/test_cube.glb` | `mat_wood_light`, `mat_canvas_stripe` | Anchor_Front, test_cube_body, test_cube | Mapeo en `.glb.import` (`_subresources`) |
| 3 | `assets/models/characters/cook/cook.glb` | `mat_cloth_player_1`, `mat_cloth_shirt`, `mat_cloth_pants`, `mat_skin_light`, `mat_rubber`, `mat_wood_dark`, `mat_canvas_red`, `mat_cook_atlas`, `mat_cloth_player_2`, `mat_skin_dark` | Anchor_Front, Anchor_Hold, head, fore... | Mapeo en `.glb.import` (`_subresources`) |
| 4 | `assets/models/environment/romeria_v2/back_e.glb` | `mat_paint_worn_grey`, `env_fence`, `mat_ground_dirt`, `mat_grass`, `mat_steel_brushed`, `mat_plastic_red`, `mat_steel_dark`, `mat_paint_worn_beige`, `env_atlas`, `mat_plastic_blue`, `mat_rubber`, `mat_burlap`, `mat_wood_dark`, `mat_wood_used`, `env_foliage`, `env_fern`, `mat_granite` | Anchor_Front, back_e_fence, back_e_gr... | Mapeo en `.glb.import` (`_subresources`) |
| 5 | `assets/models/environment/romeria_v2/back_w.glb` | `mat_paint_worn_grey`, `env_fence`, `mat_ground_dirt`, `mat_grass`, `mat_steel_brushed`, `mat_plastic_red`, `mat_steel_dark`, `mat_wood_dark`, `mat_cardboard`, `mat_wood_used`, `mat_burlap`, `mat_plastic_blue`, `env_atlas`, `env_foliage`, `env_fern`, `mat_granite` | Anchor_Front, back_w_fence, back_w_gr... | Mapeo en `.glb.import` (`_subresources`) |
| 6 | `assets/models/environment/romeria_v2/ground_e.glb` | `env_track`, `env_puddle`, `mat_ground_dirt`, `mat_grass`, `env_fern`, `env_atlas`, `mat_steel_dark` | Anchor_Front, ground_e_decals, ground... | Mapeo en `.glb.import` (`_subresources`) |
| 7 | `assets/models/environment/romeria_v2/ground_w.glb` | `env_track`, `env_puddle`, `mat_ground_dirt`, `mat_grass`, `env_fern`, `env_atlas`, `mat_steel_dark` | Anchor_Front, ground_w_decals, ground... | Mapeo en `.glb.import` (`_subresources`) |
| 8 | `assets/models/environment/romeria_v2/props_e.glb` | `mat_wood_dark`, `mat_rubber`, `env_atlas`, `mat_emissive_bulb`, `mat_steel_dark`, `mat_wood_used`, `mat_burlap`, `mat_cardboard`, `mat_skin_dark`, `mat_food_octopus_pieces`, `mat_skin_light`, `mat_clay`, `env_fern` | Anchor_Front, props_e_garlands, props... | Mapeo en `.glb.import` (`_subresources`) |
| 9 | `assets/models/environment/romeria_v2/props_w.glb` | `mat_wood_dark`, `mat_rubber`, `env_atlas`, `mat_emissive_bulb`, `mat_steel_dark`, `mat_wood_used`, `mat_burlap`, `mat_cardboard`, `mat_skin_light`, `mat_food_octopus_pieces`, `mat_skin_dark`, `mat_clay`, `env_fern` | Anchor_Front, props_w_garlands, props... | Mapeo en `.glb.import` (`_subresources`) |
| 10 | `assets/models/environment/romeria_v2/tent.glb` | `mat_canvas_red`, `mat_canvas_paper`, `mat_cloth_pants`, `mat_rubber`, `env_atlas`, `mat_emissive_bulb`, `env_plate`, `mat_paint_worn_grey`, `env_sign`, `env_board` | Anchor_Front, tent_awning, tent_bulbs... | Mapeo en `.glb.import` (`_subresources`) |
| 11 | `assets/models/food/cachelos/cachelos.glb` | `mat_food_potato_burnt`, `atlas_cachelos`, `mat_food_potato_cooked`, `mat_food_potato_raw` | Anchor_Front, cachelos_burnt, cachelo... | Mapeo en `.glb.import` (`_subresources`) |
| 12 | `assets/models/food/cachelos/cachelos_pieces.glb` | `mat_food_potato_cooked`, `atlas_cachelos` | Anchor_Front, cachelos_pieces_a, cach... | Mapeo en `.glb.import` (`_subresources`) |
| 13 | `assets/models/food/octopus/octopus.glb` | `mat_food_octopus_burnt`, `atlas_octopus`, `mat_food_octopus_cooked`, `mat_food_octopus_raw` | Anchor_Front, octopus_burnt, octopus_... | Mapeo en `.glb.import` (`_subresources`) |
| 14 | `assets/models/food/octopus/octopus_pieces.glb` | `mat_food_octopus_pieces`, `atlas_octopus` | Anchor_Front, octopus_pieces_a, octop... | Mapeo en `.glb.import` (`_subresources`) |
| 15 | `assets/models/furniture/counters/counter_1m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark` | Anchor_Front, counter_1m_body, counte... | Mapeo en `.glb.import` (`_subresources`) |
| 16 | `assets/models/furniture/counters/counter_2m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, counter_2m_body, counte... | Mapeo en `.glb.import` (`_subresources`) |
| 17 | `assets/models/furniture/counters/counter_3m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, counter_3m_body, counte... | Mapeo en `.glb.import` (`_subresources`) |
| 18 | `assets/models/furniture/counters/counter_corner.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, counter_corner_body, co... | Mapeo en `.glb.import` (`_subresources`) |
| 19 | `assets/models/furniture/counters/counter_end.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark` | Anchor_Front, counter_end_body, count... | Mapeo en `.glb.import` (`_subresources`) |
| 20 | `assets/models/furniture/counters/counter_half.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark` | Anchor_Front, counter_half_body, coun... | Mapeo en `.glb.import` (`_subresources`) |
| 21 | `assets/models/furniture/counters/counter_props_board.glb` | `mat_wood_used`, `mat_steel_brushed`, `mat_wood_dark`, `mat_clay` | Anchor_Front, counter_props_board_bod... | Mapeo en `.glb.import` (`_subresources`) |
| 22 | `assets/models/furniture/counters/counter_props_crock.glb` | `mat_steel_brushed`, `mat_steel_dark`, `mat_wood_dark`, `mat_clay` | Anchor_Front, counter_props_crock_bod... | Mapeo en `.glb.import` (`_subresources`) |
| 23 | `assets/models/furniture/counters/drain_grate.glb` | `mat_steel_dark`, `counters_atlas` | Anchor_Front, drain_grate_body, drain... | Mapeo en `.glb.import` (`_subresources`) |
| 24 | `assets/models/furniture/counters/pass_1m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, pass_1m_body, pass_1m | Mapeo en `.glb.import` (`_subresources`) |
| 25 | `assets/models/furniture/counters/pass_2m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, pass_2m_body, pass_2m | Mapeo en `.glb.import` (`_subresources`) |
| 26 | `assets/models/furniture/counters/pass_3m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, pass_3m_body, pass_3m | Mapeo en `.glb.import` (`_subresources`) |
| 27 | `assets/models/furniture/counters/pass_end.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `counters_atlas`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_steel_dark`, `mat_cardboard` | Anchor_Front, pass_end_body, pass_end | Mapeo en `.glb.import` (`_subresources`) |
| 28 | `assets/models/furniture/counters/pass_mark.glb` | `counter_pass_signs` | Anchor_Front, CornerX, CornerX.001, C... | Mapeo en `.glb.import` (`_subresources`) |
| 29 | `assets/models/furniture/counters/pass_threshold.glb` | `counter_pass_signs`, `mat_rubber` | Anchor_Front, ThresholdArrow, Thresho... | Mapeo en `.glb.import` (`_subresources`) |
| 30 | `assets/models/furniture/counters/rail_1m.glb` | `mat_steel_brushed_top`, `mat_steel_brushed_mid`, `mat_steel_brushed`, `mat_steel_dark` | Anchor_Front, rail_1m_body, rail_1m | Mapeo en `.glb.import` (`_subresources`) |
| 31 | `assets/models/items/box/box.glb` | `mat_plastic_red`, `atlas_box`, `mat_outline_hull`, `mat_sticker_atlas` | Anchor_Front, Anchor_Fill_large, Anch... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 32 | `assets/models/stations/box_shelf/box_shelf.glb` | `mat_cardboard`, `atlas_box`, `mat_outline_hull`, `mat_steel_brushed_mid`, `mat_steel_dark`, `mat_steel_brushed_top`, `mat_plastic_blue`, `mat_plastic_red` | Anchor_Front, cartons, labels, hull_l... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 33 | `assets/models/stations/cachelos_storage/cachelos_storage.glb` | `mat_food_potato_raw`, `atlas_cachelos`, `mat_burlap`, `atlas_cachelos_storage` | Anchor_Front, potatoes, sacks, cachel... | Mapeo en `.glb.import` (`_subresources`) |
| 34 | `assets/models/stations/octopus_storage/octopus_storage.glb` | `mat_food_octopus_raw`, `atlas_octopus`, `mat_steel_dark`, `mat_rubber`, `mat_steel_brushed`, `mat_plastic_blue`, `mat_glass_water`, `mat_plastic_red`, `mat_canvas_paper` | Anchor_Front, octopus_0, octopus_1, o... | Mapeo en `.glb.import` (`_subresources`) |
| 35 | `assets/models/stations/order_stand/order_stand.glb` | `mat_canvas_stand_1`, `mat_canvas_paper`, `mat_canvas_stand_2`, `mat_canvas_stand_3`, `mat_canvas_stand_4`, `mat_steel_dark`, `mat_rubber`, `mat_steel_brushed_top`, `mat_steel_brushed_mid`, `mat_steel_brushed`, `order_stand_atlas`, `delivery_zone_off`, `kiosk_delivery_signs`, `mat_emissive_screen` | Anchor_DeliveryZone, Anchor_Front, An... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 36 | `assets/models/stations/pot/pot.glb` | `mat_plastic_blue`, `mat_steel_brushed`, `mat_rubber_hose_red`, `mat_rubber_hose_green`, `mat_steel_dark`, `mat_rubber`, `mat_steel_brushed_mid`, `mat_plastic_red`, `pot_water`, `mat_emissive_bulb` | Anchor_Front, gas_bottle, lid, Anchor... | Mapeo en `.glb.import` (`_subresources`) |
| 37 | `assets/models/stations/seasoning_station/cachelos_bowl.glb` | `mat_clay`, `mat_food_potato_cooked` | Anchor_Front, Anchor_Portions, bowl, ... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 38 | `assets/models/stations/seasoning_station/seasoning_dispenser.glb` | `seasoning_signs`, `mat_steel_dark`, `mat_steel_brushed` | Anchor_Front, oil, paprika_hot, papri... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 39 | `assets/models/stations/seasoning_station/seasoning_station.glb` | `mat_steel_brushed_top`, `mat_steel_brushed`, `mat_steel_brushed_mid`, `mat_rubber`, `mat_cardboard`, `seasoning_station_atlas`, `seasoning_signs` | Anchor_Bowl, Anchor_Dispenser_HotPapr... | Mapeo en `.glb.import` (`_subresources`) + overrides en `.tscn` |
| 40 | `assets/models/stations/trash_bin/trash_bin.glb` | `mat_plastic_red`, `mat_rubber`, `mat_plastic_blue`, `mat_steel_brushed`, `mat_food_tray_liner`, `mat_cloth_pants` | Anchor_Front, Lid, trash_bin_bag, tra... | Mapeo en `.glb.import` (`_subresources`) |

---

## 2. Los 68 slots reales encontrados y su asignación normativa a la v3

| # | Slot real en `.glb` | Destino normativo v3 | Color hex / Tipo | Tipo de slot |
|---:|---|---|---|---|
| 1 | `atlas_box` | `mat_surface_top.tres` (`#EDE8DF`) | — | Atlas multicolor |
| 2 | `atlas_cachelos` | `mat_cachelos_cooked.tres` (`#F2D56B`) | — | Atlas multicolor |
| 3 | `atlas_cachelos_storage` | `mat_potato_raw.tres` (`#8E6B47`) | — | Atlas multicolor |
| 4 | `atlas_octopus` | `mat_octopus_cooked.tres` (`#B8283D`) | — | Atlas multicolor |
| 5 | `counter_pass_signs` | Slot funcional / `mat_p2_amber.tres` (`#F2C230`) | — | Funcional / Escena |
| 6 | `counters_atlas` | `mat_wall_granite.tres` (`#9A948C`) / override navy en faldón | — | Atlas multicolor |
| 7 | `delivery_zone_off` | Slot funcional (`delivery_zone_off.tres`) | — | Funcional / Escena |
| 8 | `env_atlas` | `mat_wall_granite.tres` (`#9A948C`) | — | Atlas multicolor |
| 9 | `env_board` | `mat_hidden_alpha.tres` (`#00000000`) | — | Plano compartido |
| 10 | `env_fence` | `mat_wall_granite.tres` (`#9A948C`) | — | Plano compartido |
| 11 | `env_fern` | `mat_meadow_green.tres` (`#4FA05A`) | — | Plano compartido |
| 12 | `env_foliage` | `mat_meadow_green.tres` (`#4FA05A`) | — | Plano compartido |
| 13 | `env_plate` | `mat_tent_plate.tres` (marca PulpaSA) | — | Plano compartido |
| 14 | `env_puddle` | Sub-malla podada (`visible = false`) | — | Funcional / Escena |
| 15 | `env_sign` | `mat_hidden_alpha.tres` (`#00000000`) | — | Plano compartido |
| 16 | `env_track` | Sub-malla podada (`visible = false`) | — | Funcional / Escena |
| 17 | `kiosk_delivery_signs` | Slot funcional / override en `order_stand.tscn` | — | Funcional / Escena |
| 18 | `mat_burlap` | `mat_ground_sand.tres` (`#C4A882`) | — | Plano compartido |
| 19 | `mat_canvas_paper` | `mat_ui_cream.tres` (`#F7F4EC`) | — | Plano compartido |
| 20 | `mat_canvas_red` | `mat_brand_red.tres` (`#C8402F`) | — | Plano compartido |
| 21 | `mat_canvas_stand_1` | `mat_brand_red.tres` (`#C8402F`) | — | Plano compartido |
| 22 | `mat_canvas_stand_2` | `mat_p1_blue.tres` (`#2F6FB5`) | — | Plano compartido |
| 23 | `mat_canvas_stand_3` | `mat_p2_amber.tres` (`#F2C230`) | — | Plano compartido |
| 24 | `mat_canvas_stand_4` | `mat_meadow_green.tres` (`#4FA05A`) | — | Plano compartido |
| 25 | `mat_canvas_stripe` | Modelo de test de pipeline (`_pipeline/`) | — | Pipeline Test |
| 26 | `mat_cardboard` | `mat_ground_sand.tres` (`#C4A882`) | — | Plano compartido |
| 27 | `mat_clay` | `mat_potato_raw.tres` (`#8E6B47`) | — | Plano compartido |
| 28 | `mat_cloth_pants` | `mat_brand_navy.tres` (`#1D3557`) | — | Plano compartido |
| 29 | `mat_cloth_player_1` | `mat_p1_blue.tres` (`#2F6FB5`) | — | Plano compartido |
| 30 | `mat_cloth_player_2` | `mat_p2_amber.tres` (`#F2C230`) | — | Plano compartido |
| 31 | `mat_cloth_shirt` | `mat_ui_cream.tres` (`#F7F4EC`) | — | Plano compartido |
| 32 | `mat_cook_atlas` | `mat_brand_navy.tres` (`#1D3557`) | — | Atlas multicolor |
| 33 | `mat_emissive_bulb` | `mat_p2_amber.tres` (`#F2C230`) / oculto | — | Plano compartido |
| 34 | `mat_emissive_screen` | `mat_surface_top.tres` (`#EDE8DF`) / funcional | — | Funcional / Escena |
| 35 | `mat_food_octopus_burnt` | `mat_state_burnt.tres` (`#2A2320`) | — | Plano compartido |
| 36 | `mat_food_octopus_cooked` | `mat_octopus_cooked.tres` (`#B8283D`) | — | Plano compartido |
| 37 | `mat_food_octopus_pieces` | `mat_octopus_cooked.tres` (`#B8283D`) | — | Plano compartido |
| 38 | `mat_food_octopus_raw` | `mat_octopus_raw.tres` (`#E0AFB2`) | — | Plano compartido |
| 39 | `mat_food_potato_burnt` | `mat_state_burnt.tres` (`#2A2320`) | — | Plano compartido |
| 40 | `mat_food_potato_cooked` | `mat_cachelos_cooked.tres` (`#F2D56B`) | — | Plano compartido |
| 41 | `mat_food_potato_raw` | `mat_potato_raw.tres` (`#8E6B47`) | — | Plano compartido |
| 42 | `mat_food_tray_liner` | `mat_surface_top.tres` (`#EDE8DF`) | — | Plano compartido |
| 43 | `mat_glass_water` | `mat_p1_blue.tres` (`#2F6FB5`) | — | Plano compartido |
| 44 | `mat_granite` | `mat_wall_granite.tres` (`#9A948C`) | — | Plano compartido |
| 45 | `mat_grass` | `mat_meadow_green.tres` (`#4FA05A`) | — | Plano compartido |
| 46 | `mat_ground_dirt` | `mat_ground_sand.tres` (`#C4A882`) | — | Plano compartido |
| 47 | `mat_outline_hull` | Slot funcional (shader `mat_outline_hull`) | — | Funcional / Escena |
| 48 | `mat_paint_worn_beige` | `mat_ground_sand.tres` (`#C4A882`) | — | Plano compartido |
| 49 | `mat_paint_worn_grey` | `mat_wall_granite.tres` (`#9A948C`) | — | Plano compartido |
| 50 | `mat_plastic_blue` | `mat_p1_blue.tres` (`#2F6FB5`) | — | Plano compartido |
| 51 | `mat_plastic_red` | `mat_brand_red.tres` (`#C8402F`) | — | Plano compartido |
| 52 | `mat_rubber` | `mat_state_burnt.tres` (`#2A2320`) | — | Plano compartido |
| 53 | `mat_rubber_hose_green` | `mat_meadow_green.tres` (`#4FA05A`) | — | Plano compartido |
| 54 | `mat_rubber_hose_red` | `mat_brand_red.tres` (`#C8402F`) | — | Plano compartido |
| 55 | `mat_skin_dark` | `mat_potato_raw.tres` (`#8E6B47`) | — | Plano compartido |
| 56 | `mat_skin_light` | `mat_octopus_raw.tres` (`#E0AFB2`) | — | Plano compartido |
| 57 | `mat_steel_brushed` | `mat_wall_granite.tres` (`#9A948C`) | — | Plano compartido |
| 58 | `mat_steel_brushed_mid` | `mat_wall_granite.tres` (`#9A948C`) | — | Plano compartido |
| 59 | `mat_steel_brushed_top` | `mat_surface_top.tres` (`#EDE8DF`) | — | Plano compartido |
| 60 | `mat_steel_dark` | `mat_brand_navy.tres` (`#1D3557`) | — | Plano compartido |
| 61 | `mat_sticker_atlas` | Slot funcional (billboard pegatinas) | — | Funcional / Escena |
| 62 | `mat_wood_dark` | `mat_potato_raw.tres` (`#8E6B47`) | — | Plano compartido |
| 63 | `mat_wood_light` | Modelo de test de pipeline (`_pipeline/`) | — | Pipeline Test |
| 64 | `mat_wood_used` | `mat_potato_raw.tres` (`#8E6B47`) | — | Plano compartido |
| 65 | `order_stand_atlas` | `mat_brand_navy.tres` (`#1D3557`) | — | Atlas multicolor |
| 66 | `pot_water` | `mat_p1_blue.tres` (`#2F6FB5`) | — | Plano compartido |
| 67 | `seasoning_signs` | Slot funcional (iconos D26 condimentos) | — | Funcional / Escena |
| 68 | `seasoning_station_atlas` | `mat_surface_top.tres` (`#EDE8DF`) | — | Atlas multicolor |

---

## 3. Comparativa con el prototipo probado (capture_minimal.gd:499-558)

El prototipo aprobado en PUL-180 (`capture_minimal.gd`) utilizó la siguiente tabla que sirvió de base probada en ejecución:

```gdscript
# capture_minimal.gd:499-560
var common: Dictionary = {
    "mat_food_octopus_raw": _flat("#E0AFB2", 0.65),
    "mat_food_octopus_cooked": _flat("#B8283D", 0.55),
    "mat_food_octopus_pieces": _flat("#B8283D", 0.55),
    "mat_food_octopus_burnt": _flat("#2A2320", 0.95),
    "mat_food_potato_raw": _flat("#8E6B47", 0.85),
    "mat_food_potato_cooked": _flat("#F2D56B", 0.65),
    "mat_food_potato_burnt": _flat("#2A2320", 0.95),
    "atlas_octopus": _flat("#B8283D", 0.60),
    "atlas_cachelos": _flat("#F2D56B", 0.65),
    "mat_cloth_player_1": _flat("#2F6FB5", 0.85),
    "mat_cloth_player_2": _flat("#F2C230", 0.85),
    "mat_cloth_shirt": _flat("#F7F4EC", 0.90),
    "mat_cloth_pants": _flat("#1D3557", 0.90),
    "mat_skin_light": _flat("#E0AFB2", 0.80),
    "mat_skin_dark": _flat("#8E6B47", 0.80),
    "mat_cook_atlas": _flat("#1D3557", 0.85),
}

# dir_a:
    "kitchen_floor_dirt": _flat("#C4A882", 0.92),
    "mat_ground_dirt": _flat("#C4A882", 0.92),
    "mat_grass": _flat("#4FA05A", 0.92),
    "env_fern": _flat("#4FA05A", 0.90),
    "env_foliage": _flat("#4FA05A", 0.90),
    "mat_granite": _flat("#8C96A0", 0.88),
    "mat_steel_brushed_top": _flat("#EDE8DF", 0.82),
    "mat_steel_brushed": _flat("#8C96A0", 0.82),
    "mat_steel_brushed_mid": _flat("#8C96A0", 0.85),
    "mat_steel_dark": _flat("#1D3557", 0.88),
    "counters_atlas": _flat("#8C96A0", 0.85),
    "order_stand_atlas": _flat("#1D3557", 0.88),
    "seasoning_station_atlas": _flat("#EDE8DF", 0.82),
    "mat_plastic_red": _flat("#C8402F", 0.65),
    "mat_plastic_blue": _flat("#2F6FB5", 0.65),
    "mat_canvas_red": _flat("#C8402F", 0.88),
    "mat_canvas_paper": _flat("#F7F4EC", 0.90),
    "mat_canvas_stand_1": _flat("#C8402F", 0.85),
    "mat_canvas_stand_2": _flat("#2F6FB5", 0.85),
    "mat_canvas_stand_3": _flat("#F2C230", 0.85),
    "mat_canvas_stand_4": _flat("#4FA05A", 0.85),
    "mat_food_tray_liner": _flat("#EDE8DF", 0.90),
    "atlas_box": _flat("#EDE8DF", 0.90),
    "mat_burlap": _flat("#8E6B47", 0.90),
    "atlas_cachelos_storage": _flat("#8E6B47", 0.90),
    "mat_clay": _flat("#8E6B47", 0.82),
    "mat_wood_used": _flat("#8E6B47", 0.85),
    "mat_wood_dark": _flat("#8E6B47", 0.88),
    "mat_cardboard": _flat("#C4A882", 0.90),
    "mat_rubber": _flat("#2A2320", 0.90),
    "mat_rubber_hose_red": _flat("#C8402F", 0.85),
    "mat_rubber_hose_green": _flat("#4FA05A", 0.85),
    "mat_glass_water": _flat("#2F6FB5", 0.30, 0.0, 0.45),
    "pot_water": _flat("#2F6FB5", 0.35),
    "mat_emissive_bulb": _flat("#F2C230", 0.50, 0.0, 1.0, "#F2C230", 0.8),
    "mat_emissive_screen": _flat("#EDE8DF", 0.50),
    "env_board": _flat("#1D3557", 0.88),
    "env_sign": _flat("#1D3557", 0.88),
    "env_atlas": _flat("#8C96A0", 0.88),
    "counter_pass_signs": _flat("#F2C230", 0.80),
```

---

## 4. Reglas explícitas para slots compartidos, atlas y slots funcionales

### 4.1 Slots compartidos entre mallas con función distinta
1. **`seasoning_dispenser.glb`**: contiene los nodos `paprika_sweet`, `paprika_hot`, `salt`, `oil`. Sus slots son `seasoning_signs`, `mat_steel_dark` y `mat_steel_brushed`. Los colores de aliño dulce (`#D6361F`) y picante (`#8F1A14`) se asignan en las instancias correspondientes en `seasoning_dispenser.tscn` / `seasoning_station.tscn` mediante `surface_material_override` (o cuerpo cilíndrico en escena), sin esperar que existan slots llamados `SweetDressing` ni `HotDressing` en el `.glb`.
2. **`octopus.glb` y `cachelos.glb`**: cada uno contiene 3 nodos para sus estados (`octopus_raw`, `octopus_cooked`, `octopus_burnt`; `cachelos_raw`, `cachelos_cooked`, `cachelos_burnt`). Los slots base en el `.glb.import` se mapean a los `.tres` planos (`mat_octopus_cooked.tres`, `mat_cachelos_cooked.tres`), y la visibilidad de cada estado se conmuta por nodo (`MeshInstance3D`) en `octopus.tscn` y `cachelos.tscn`, garantizando el cambio de silueta + salto de color.
3. **`box.glb`**: contiene los nodos `box_large`, `box_medium`, `box_small`. Sus slots son `mat_plastic_red` (exterior) y `atlas_box` (interior). Se mapean a `mat_brand_red.tres` y `mat_surface_top.tres` respectivamente en `box.glb.import`.

### 4.2 Atlas multicolor
- **`env_atlas`**: en `capture_minimal.gd:558` se mapea a `#8C96A0` (`mat_wall_granite.tres`). Se aplica a suelos, fondos y atrezo exterior en `back_e/w`, `ground_e/w`, `props_e/w` y `tent`. Prohibido mapearlo a rojo en el import global.
- **`counters_atlas`**: se mapea a `mat_wall_granite.tres` (`#9A948C`) en `furniture/counters/*.glb.import`. Donde una encimera o estación requiera faldón navy, se aplica `surface_material_override` en su `.tscn` a `mat_brand_navy.tres`.
- **`atlas_box`**: se mapea a `mat_surface_top.tres` (`#EDE8DF`), dando el interior claro a las cajas de reparto.
- **`atlas_octopus`**: se mapea a `mat_octopus_cooked.tres` (`#B8283D`).
- **`atlas_cachelos`**: se mapea a `mat_cachelos_cooked.tres` (`#F2D56B`).
- **`atlas_cachelos_storage`**: se mapea a `mat_potato_raw.tres` (`#8E6B47`).
- **`order_stand_atlas`**: se mapea a `mat_brand_navy.tres` (`#1D3557`).
- **`seasoning_station_atlas`**: se mapea a `mat_surface_top.tres` (`#EDE8DF`).
- **`mat_cook_atlas`**: se mapea a `mat_brand_navy.tres` (`#1D3557`).

### 4.3 Slots funcionales y excepciones de escena
Los siguientes slots tienen funciones técnicas, shaders o interacción de juego y no se sustituyen por los 18 planos generales:
1. **`mat_outline_hull`**: material shader de contorno para el feedback de selección en `box.glb` y `box_shelf.glb`.
2. **`mat_sticker_atlas`**: atlas para la generación y renderizado dinámico de pegatinas 3D en `box.glb` (`badge_row.gd`).
3. **`delivery_zone_off` / `delivery_zone_on`**: materiales dinámicos de contrato (`delivery_zone_off.tres`) en `order_stand.glb`, alternados por código según estado de entrega.
4. **`seasoning_signs`**: textura funcional de iconos para los dispensadores.
5. **`counter_pass_signs`**: señalética plana de pasaplatos (amarillo `#F2C230`).
6. **`kiosk_delivery_signs`**: en `order_stand.tscn`, `OrderPlatePaper` y `OrderPlateFrame` se sobreescriben en la escena a `mat_ui_cream.tres` y `mat_brand_navy.tres`.
7. **`mat_emissive_screen`**: pantalla de TPV en `order_stand.glb` (color plano `#EDE8DF`).

### 4.4 Modelos de pipeline test (`_pipeline/**`)
- `materials_v2_test.glb` y `test_cube.glb` son activos de prueba de importación del pipeline y no forman parte de `level_01.tscn` ni del mundo de juego.
