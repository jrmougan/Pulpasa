---
id: PUL-073
title: Ajustar luz, sombras y post-proceso a la estética de referencia
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072]
orca_task: null
unity_sources: []
owns: [godot/entities/environment/environment.tscn, godot/entities/environment/environment.gd, godot/entities/environment/environment.gd.uid, godot/resources/render_config.gd, godot/resources/render_config.gd.uid, godot/tests/unit/test_render_config.gd, godot/tests/unit/test_render_config.gd.uid, godot/data/config/render*.tres, godot/assets/materials/env_*, godot/project.godot, docs/evidence/PUL-073/**]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
Iluminación y post-proceso de la referencia sobre el nivel actual: es la palanca más barata y se hace primero para que los modelos nuevos se juzguen con la luz final.

## Change
1. `WorldEnvironment`: luz ambiental más apagada, tonemapping filmic/AgX, ligero color grading cálido, SSAO, niebla suave de fondo si ayuda.
2. Luz principal cálida con sombras suaves; luces puntuales de bombillas sobre la zona jugable (sin reventar la lectura).
3. Profundidad de campo tilt-shift **opcional** (desactivada por defecto si resta legibilidad; dato en `.tres`).
4. Ajustes de calidad en `project.godot` documentados (sombras, MSAA/FXAA) con su coste.

## Constraints
- Referencia visual: `docs/art/style-refs/referencia-elegida-2026-10-06.png`; reglas en `docs/art/art-bible.md` v2 (PUL-072) y materiales de PUL-074.
- Modela con el MCP de Blender (por CLI; no uses el puerto 9876 si hay un Blender del responsable).
  Godot para capturas siempre con `--audio-driver Dummy`.
- No cambies la jugabilidad: colisiones, anclas, nodos de contrato (`scene-tree.md`), posiciones en
  `level_01` y los tests de selección/entrega deben seguir en verde. Resaltado con contorno fino
  (`OutlineHull` si el modelo es abierto, nota de PUL-049).
- Conserva la legibilidad (biblia §3): siluetas, crudo/cocido/quemado, pegatinas, colores por puesto.
- Capturas desde la cámara de `level_01` (antes/después, con resaltado) y render del `.blend` en
  `docs/evidence/<id>/`. La licencia propia la registra el coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Capturas del mismo plano: actual vs v2 con y sin tilt-shift
- [x] AC2 Ningún elemento jugable queda en sombra ilegible (pegatinas, números de puesto, aros)
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Capturar el estado actual con `capture_style_refs.gd` (mismo plano que `actual-2026-10-06`).
2. Sacar luz y post-proceso a datos: `RenderConfig` (`resources/render_config.gd`) con `Environment`,
   `CameraAttributesPractical` y `tilt_shift_enabled` en `data/config/render_config.tres`;
   `LevelEnvironment` (`environment.gd`) lo aplica al `WorldEnvironment` en `_ready` (owns ampliado
   por el coordinador: `test_data_integrity` exige `.tres` con `class_name` en `data/`).
3. Sol cálido a 55°, ambiente cubierto bajo, Filmic, SSAO, glow solo emisivos, gradación cálida,
   viñeta ligera; 5 `OmniLight3D` de bombilla sin sombra; MSAA 4× y sombras suaves en `project.godot`.
4. Tilt-shift como desenfoque lejano opcional, apagado por defecto.
5. Capturas antes/v2/v2+tilt-shift, chequeo de luminancia (AC2) y render de un `.blend` con la misma luz.
6. Test `test_render_config.gd`; `tools/verify.sh` y `check_owns`.

## Evidence
Todo en `docs/evidence/PUL-073/`. Resumen visual: `comparativa.png` (antes · v2 · v2+tilt-shift · referencia).

**Capturas** (1920×1080, cámara de `level_01`, J1 junto a la nevera con el resaltado activo, J2 con
plato y aro): `antes/`, `despues/`, `despues_tiltshift/` (00 sin HUD, 01 con HUD, 02–05 recortes).
Se regeneran con `capture_pul073.gd` (copia de `capture_style_refs.gd` con argumento `tiltshift`).

**Valores** (`data/config/render_config.tres` y `environment.tscn`):
- Sol `DirectionalLight3D` `#FFE9C8`, energía 1,34 (la fija `test_level_01`), elevación 55° desde
  arriba-izquierda de la cámara (los frentes jugables quedan iluminados; la v1 los dejaba en
  contraluz), sombra PCF suave (`shadow_blur` 2, sin PCSS: `light_angular_distance` > 0 daba ruido).
- Ambiente color `#9AA6A8` × 0,5; fondo color liso verde apagado; cielo procedural solo para reflejos.
- Tonemap **Filmic** (white 6): AgX apagaba la pegatina amarilla y el contorno de resaltado (biblia
  §1.3 permite Filmic en ese caso). Saturación 1,1, contraste 1,1, gradación cálida suave
  (`GradientTexture1D`), viñeta cálida ligera (`CanvasLayer` −1, por debajo del HUD).
- SSAO radio 0,8, intensidad 2,5; glow umbral HDR 1,2 (solo `mat_lantern_warm` emisivo).
- Bombillas: 5 `OmniLight3D` `#FFD58A` sin sombra (3 bajo el toldo, 1 por guirnalda lateral);
  ninguna con sombra. Total luces dinámicas 6 (≤ 8, §4.3).
- **Tilt-shift**: `tilt_shift_enabled = false`. Al activarlo solo se usa el desenfoque lejano
  (desde 12,8 m, transición 3 m, cantidad 0,3): emborrona muro, toldo y fondo y deja nítidos
  encimeras, kioscos y jugadores (diferencia media 0,0 en la mitad inferior). El desenfoque cercano
  queda siempre apagado: con la cámara ortográfica inclinada los carteles de los kioscos están más
  cerca que el borde inferior y se emborronaban.

**AC2** (`check_luminance.py`, luminancia relativa lineal, regla §6.1-6 < 0,08 / > 0,95 en la mediana
de cada zona): `ac2_luminancia.txt` y `ac2_luminancia_tiltshift.txt` sin fallos (mínimo 0,18 en olla
y frente de condimentos; máximo 0,70 en cartel del kiosco). Antes (`ac2_luminancia_antes.txt`) el
cartel del kiosco 1 salía quemado (0,999). Contraste número/disco de kiosco ≈ 4:1. El resaltado
amarillo de la nevera sigue visible (`despues/02_cocina.png`).

**Calidad en `project.godot`** (coste en la RTX 3090 a 1080p, estimado; lo mide PUL-087):
- `anti_aliasing/quality/msaa_3d = 2` (MSAA 4×): ~0,3–0,5 ms. Sin FXAA/TAA: emborronan pegatinas y números.
- `directional_shadow/soft_shadow_filter_quality = 3` (soft high): ~0,2 ms con una direccional.
- SSAO (calidad media por defecto, media resolución) ~0,3–0,5 ms; glow ~0,2 ms; DOF lejano si se
  activa ~0,3–0,6 ms. Primero en el orden de recorte de §4.3 es el tilt-shift.

**Blender**: `luz_v2.blend` y `blender_luz_v2.png` (EEVEE, MCP por CLI): maqueta con la misma
dirección y color de sol, ambiente `#9AA6A8` bajo, bombillas puntuales cálidas y cámara ortográfica a
38°, con colores de la paleta v2 (§2) para que PUL-074 juzgue materiales con esta luz. El Blender
instalado solo ofrece la vista «Standard» en segundo plano (sin AgX/Filmic).

**Cambios fuera de la luz**: ninguno en colisiones, anclas, nodos de contrato ni posiciones de
`level_01`. `Environment` gana script (`LevelEnvironment`), `Bulbs` y `Vignette`; `WorldEnvironment`
y `Sun` conservan nombre e id. `scene-tree.md` describe Environment como «WorldEnvironment +
DirectionalLight3D»: los nodos nuevos son internos (el coordinador decide si se anota).

**Verificación**: `tools/verify.sh` verde (725 tests, incluido `test_render_config.gd`: tilt-shift
apagado, solo lejano, entorno aplicado, ≤ 6 omni sin sombra, sol a 50–60°). `check_owns` limpio.
