---
id: PUL-183
title: Configurar la luz, el entorno y el post-proceso v3 en environment.tscn
status: draft
milestone: M3f
role: asset-pipeline
deps: [PUL-181]
orca_task: null
unity_sources: []
owns: [godot/data/config/render_config.tres, godot/entities/environment/environment.tscn, godot/tests/unit/test_render_config.gd, godot/tests/integration/test_level_01.gd, docs/evidence/PUL-183/**, docs/backlog/PUL-183-luz-entorno-y-postproceso-v3.md]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
Aplicar la configuración de luz diurna, `WorldEnvironment`, post-proceso (SSAO suave activo, 0 `glow`, 0 LUT, 0 `Vignette`, 0 `Bulbs`) y poda de atrezo de entorno (Z1/Z3) definida en `docs/art/art-bible.md` §4 y §5.1 (D28, «Feira Clara»). Absorbe y sustituye a `PUL-145`.

## Change
1. Actualizar `godot/data/config/render_config.tres` (`Environment` de `WorldEnvironment` y propiedades de `RenderConfig`):
   - `background_mode = Environment.BG_COLOR`, `background_color = Color("#4FA05A")` (`meadow_green`).
   - `ambient_light_source = Environment.AMBIENT_SOURCE_COLOR`, `ambient_light_color = Color("#EDE8DF")`, `ambient_light_energy = 0.72`, `ambient_light_sky_contribution = 0.0`.
   - `reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED`.
   - `tonemap_mode = Environment.TONEMAPPER_FILMIC`, `tonemap_exposure = 1.0`, `tonemap_white = 6.0`.
   - **SSAO de contacto activo (§4.2)**: `ssao_enabled = true`, `ssao_radius = 0.45`, `ssao_intensity = 1.1`, `ssao_power = 1.3`, `ssao_detail = 0.0`, `ssao_light_affect = 0.1`.
   - **Post-procesos desactivados (§4.2)**: `glow_enabled = false`, `adjustment_enabled = true`, `adjustment_brightness = 1.0`, `adjustment_contrast = 1.05`, `adjustment_saturation = 1.05`, `adjustment_color_correction = null`, `tilt_shift_enabled = false`.
2. Actualizar `godot/entities/environment/environment.tscn`:
   - `Sun` (`DirectionalLight3D`): `light_color = Color("#FFF4E0")`, `light_energy = 1.18`, `shadow_enabled = true`, `shadow_opacity = 0.75`, `shadow_blur = 3.2`.
   - `Bulbs`: mantener el nodo `Bulbs` y sus 5 hijos `OmniLight3D` en el árbol (para cumplir `docs/arch/scene-tree.md` §3), pero poner `visible = false` en `Bulbs` y en cada `OmniLight3D`.
   - `Vignette`: mantener el nodo en el árbol con `visible = false`.
   - Ocultar (`visible = false` mediante hijos editables o overrides en `environment.tscn`) las 11 sub-mallas ruidosas de Z1/Z3 (§5.1): `ground_w_decals`, `ground_e_decals`, `back_w_props`, `back_e_props`, `back_w_fence`, `back_e_fence`, `tent_bulbs`, `props_w_garlands`, `props_e_garlands`, `props_w_props` y `props_e_props`.
3. Actualizar `godot/tests/unit/test_render_config.gd` y la aserción de `sun.light_energy` en `godot/tests/integration/test_level_01.gd` (`1.18` en lugar de `1.34`), añadiendo la comprobación de 0 `OmniLight3D` visibles y de las sub-mallas de atrezo ocultas.

## Constraints
- No eliminar del árbol los nodos `Bulbs` ni `Vignette` de `environment.tscn` (están en `docs/arch/scene-tree.md` §3; se desactivan con `visible = false`).
- No modificar en `test_level_01.gd` nada ajeno a las comprobaciones de `Environment` / `Sun`.

## Acceptance
- [ ] AC1 Given `godot/data/config/render_config.tres`, When se ejecuta `test_render_config.gd`, Then `background_mode == BG_COLOR`, `background_color` es `#4FA05A`, `ambient_light_energy` es `0.72 ± 0.01`, `ssao_enabled == true` (`ssao_radius == 0.45 ± 0.01`, `ssao_intensity == 1.1 ± 0.05`), `glow_enabled == false`, `adjustment_color_correction == null` y `tilt_shift_enabled == false`.
- [ ] AC2 Given `godot/entities/environment/environment.tscn`, When se instancia en `test_level_01.gd`, Then `Sun.light_energy` es `1.18 ± 0.01`, `Sun.shadow_blur` es `3.2 ± 0.1`, `Bulbs.visible == false` (0 `OmniLight3D` visibles en el subárbol) y `Vignette.visible == false`.
- [ ] AC3 Given `environment.tscn`, When se inspeccionan los nodos `ground_*_decals`, `back_*_props`, `back_*_fence`, `tent_bulbs`, `props_*_garlands` y `props_*_props`, Then los 11 tienen `is_visible_in_tree() == false`, mientras que `tent_canopy`, `tent_plate`, `back_*_wall` y `props_*_tables` siguen visibles.
- [ ] AC4 Given una captura de `environment.tscn` en `docs/evidence/PUL-183/`, When se inspecciona, Then no hay viñeta perimetral ni manchas de luz puntual sobre el suelo.
- [ ] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
