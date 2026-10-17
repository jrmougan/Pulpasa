---
id: PUL-182
title: Crear la biblioteca de materiales planos v3
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-181]
orca_task: null
unity_sources: []
owns: [godot/assets/materials/v3/**, godot/tests/unit/test_materials_v3.gd*, docs/evidence/PUL-182/**, docs/backlog/PUL-182-biblioteca-materiales-planos-v3.md]
touches_scenes: []
---

## Target
Crear en `godot/assets/materials/v3/` la biblioteca cerrada de **18 recursos `StandardMaterial3D`** (≤ 20 `.tres`) definida en `docs/art/art-bible.md` §3.1 (D28, «Feira Clara»), junto con su test unitario de contrato `godot/tests/unit/test_materials_v3.gd`.

## Change
1. Crear los 16 materiales opacos de color plano en `godot/assets/materials/v3/` con los valores exactos de `docs/art/art-bible.md` §3.1:
   - `mat_ground_sand.tres` (`#C4A882`, `roughness = 0.95`)
   - `mat_wall_granite.tres` (`#9A948C`, `roughness = 0.92`)
   - `mat_meadow_green.tres` (`#4FA05A`, `roughness = 0.95`)
   - `mat_surface_top.tres` (`#EDE8DF`, `roughness = 0.85`)
   - `mat_brand_navy.tres` (`#1D3557`, `roughness = 0.90`)
   - `mat_brand_red.tres` (`#C8402F`, `roughness = 0.80`)
   - `mat_ui_cream.tres` (`#F7F4EC`, `roughness = 0.90`)
   - `mat_octopus_raw.tres` (`#E0AFB2`, `roughness = 0.88`)
   - `mat_octopus_cooked.tres` (`#B8283D`, `roughness = 0.65`)
   - `mat_potato_raw.tres` (`#8E6B47`, `roughness = 0.92`)
   - `mat_cachelos_cooked.tres` (`#F2D56B`, `roughness = 0.80`)
   - `mat_state_burnt.tres` (`#2A2320`, `roughness = 0.95`)
   - `mat_paprika_sweet.tres` (`#D6361F`, `roughness = 0.75`)
   - `mat_paprika_hot.tres` (`#8F1A14`, `roughness = 0.75`)
   - `mat_p1_blue.tres` (`#2F6FB5`, `roughness = 0.75`)
   - `mat_p2_amber.tres` (`#F2C230`, `roughness = 0.75`)
   Todos con `metallic = 0.0`, `specular_mode = BaseMaterial3D.SPECULAR_DISABLED` (`2`), `albedo_texture = null`, `normal_enabled = false` y `ao_enabled = false`.
2. Crear los 2 materiales técnicos de la biblioteca (§3.1 y §3.2):
   - `mat_tent_plate.tres`: `StandardMaterial3D` con `albedo_color = Color("#F7F4EC")`, `albedo_texture = ExtResource("res://assets/textures/brand/pulpasa_horizontal.png")` (o la textura limpia del cartel `tent_env_plate`), `roughness = 0.90`, `metallic = 0.0`, `specular_mode = SPECULAR_DISABLED` y 0 mapas ORM/normal.
   - `mat_hidden_alpha.tres`: `StandardMaterial3D` con `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, `albedo_color = Color(0.0, 0.0, 0.0, 0.0)`, `roughness = 1.0`, `metallic = 0.0`, `specular_mode = SPECULAR_DISABLED`.
3. Añadir `godot/tests/unit/test_materials_v3.gd` que cargue todos los `.tres` de `res://assets/materials/v3/` y verifique el catálogo cerrado, sus colores hex, `roughness`, `metallic == 0.0`, `specular_mode == SPECULAR_DISABLED` y la ausencia de mapas ORM/normal.

## Constraints
- No tocar `.glb`, escenas `.tscn` ni materiales de `godot/assets/materials/v2/` (se limpian en `PUL-188`).
- No inventar `uid://`; dejar que Godot genere o mantenga los UIDs al importar.

## Acceptance
- [ ] AC1 Given `res://assets/materials/v3/`, When se listan sus recursos `.tres` en `test_materials_v3.gd`, Then hay exactamente 18 archivos (≤ 20) y todos cargan como `StandardMaterial3D` sin errores.
- [ ] AC2 Given los 16 materiales opacos de `res://assets/materials/v3/`, When `test_materials_v3.gd` inspecciona sus propiedades, Then cada `albedo_color` coincide con su hex de `docs/art/art-bible.md` §3.1 (tolerancia ≤ `0.005` por canal), `metallic == 0.0`, `specular_mode == BaseMaterial3D.SPECULAR_DISABLED`, `albedo_texture == null`, `normal_enabled == false` y `ao_enabled == false`.
- [ ] AC3 Given `mat_tent_plate.tres` y `mat_hidden_alpha.tres`, When `test_materials_v3.gd` los valida, Then `mat_tent_plate.tres` tiene `normal_enabled == false` y `ao_enabled == false`, y `mat_hidden_alpha.tres` tiene `transparency == BaseMaterial3D.TRANSPARENCY_ALPHA` y `albedo_color.a == 0.0`.
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
