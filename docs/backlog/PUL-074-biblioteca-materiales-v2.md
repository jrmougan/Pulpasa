---
id: PUL-074
title: Crear la biblioteca de materiales estilizados
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072]
orca_task: task_cbd1d6f496dd
unity_sources: []
owns: [art/blender/_materials_v2.blend, art/blender/_template.blend, godot/assets/materials/v2/**, godot/assets/textures/v2/**, godot/assets/models/_pipeline/materials_v2_test/**, docs/art/materials-v2.md, docs/art/pipeline.md, tools/blender_export.py, docs/evidence/PUL-074/**]
touches_scenes: []
---

## Target
Base común para que todos los assets v2 casen: materiales con textura pequeña y desgaste según la biblia v2.

## Change
1. `_materials_v2.blend` con los materiales de la biblia v2 (acero cepillado, metal pintado gastado, plástico rojo, madera usada, arpillera, tierra, lona, cobre si sigue, piel/tela de personaje…), con texturas pintadas/procedurales horneadas a resolución pequeña.
2. Plantilla `_template.blend` actualizada para enlazarlos; `tools/blender_export.py` exporta texturas embebidas o en `godot/assets/textures/v2/`.
3. `docs/art/materials-v2.md`: catálogo con muestra renderizada de cada material.

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
- [x] AC1 Lámina con una esfera/cubo por material en Blender y en Godot (luz neutra provisional: PUL-073 va en paralelo; el coordinador la repite con la luz final)
- [x] AC2 Un asset de prueba exportado con dos materiales v2 importa sin errores
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Texturas procedurales propias (numpy, tileables, deterministas) a 512² (suelo 1024²), 256 px/m con
   1 UV = 2 m: albedo sRGB + ORM (G rough, B metal) + normal donde hay relieve grande. Texturas neutras
   teñidas por factor para las familias con variantes (acero, plástico, lona, ropa, madera); color
   medio ajustado al hex de la biblia (≤ 10 %).
2. `_materials_v2.blend` generado por script desde un manifiesto (nodos que el exportador glTF traduce
   1:1: Mix MULTIPLY → baseColorFactor, Separate G/B × factor, Normal Map), imágenes con ruta relativa
   a `godot/assets/textures/v2/`, escena `lamina` y render Cycles.
3. `.tres` de Godot equivalentes en `godot/assets/materials/v2/`; PNG con VRAM + mipmaps.
4. Plantilla: fuera los 32 colores v1, enlaza los 45 `mat_*` v2. `blender_export.py`: tangentes,
   comprobación de texturas (existen, ≤ 1024 px), `--materials-test` (taburete con 3 materiales v2) y
   el cubo de humo pasa a materiales v2. Decisión §3.3: texturas **embebidas** en el `.glb`.
5. Docs (`materials-v2.md`, `pipeline.md` §8) y capturas (láminas, antes/después en `level_01`).
   Ampliación de `owns` (`models/_pipeline/materials_v2_test/**`, `docs/art/pipeline.md`) aprobada por
   el coordinador.

## Evidence
- **Biblioteca**: 45 materiales (catálogo de art-bible v2 §3.1 con variantes por color: 4 aceros +
  cobre, 2 pinturas, 2 plásticos, 2 maderas, arpillera, cartón, barro, 6 lonas, granito, 3 gomas,
  tierra, hierba, follaje con alfa, agua, 3 emisivos, 4 telas, 2 pieles, 8 comidas). 18 juegos de
  texturas, 50 PNG, 3,2 MB en disco, ≈ 20 MB en VRAM. Color medio = hex salvo `mat_canvas_paper`
  (ΔL 7,8 %) y `mat_cloth_shirt` (8,3 %), dentro del 10 %. Catálogo: [`docs/art/materials-v2.md`](../art/materials-v2.md).
- **AC1**: [`blender_lamina.png`](../evidence/PUL-074/blender_lamina.png) (Cycles, luz neutra) y
  [`godot_lamina.png`](../evidence/PUL-074/godot_lamina.png) (Forward+, AgX, cielo gris neutro, escena
  temporal construida en memoria por [`capture_pul074.gd`](../evidence/PUL-074/capture_pul074.gd),
  sin versionar en `godot/`). Hay que repetir la de Godot con la luz final de PUL-073.
- **AC2**: `materials_v2_test.glb` (152 tris; `mat_steel_brushed`, `mat_plastic_red`, `mat_wood_used`
  enlazados desde la plantilla) exporta con `baseColorFactor`, `metallicRoughnessTexture`,
  `roughnessFactor` y `normalTexture`; Godot lo importa sin errores, extrae 8 texturas y pasa
  `test_assets_models.gd`. Visible en la última fila de la lámina de Godot.
- **Antes/después**: [`level_before.png`](../evidence/PUL-074/level_before.png) /
  [`level_after.png`](../evidence/PUL-074/level_after.png), cámara de `level_01`, con resaltado en
  cocina, condimentos y puesto 1. El «después» solo **sustituye en memoria** los materiales v1 por
  los v2 equivalentes (triplanar) sobre los modelos actuales: es una vista previa del grano y el color,
  no el arte v2 (lo rehacen PUL-075..085). El contorno sigue viéndose sobre madera, acero y tierra.
  Primera prueba: un charco dentro de la tierra tileable se repetía cada 4 m → quitado (charcos y
  rodadas, como decal).
- **Render del `.blend`** y muestras por material: [`swatches/`](../evidence/PUL-074/swatches/).
- Blender: generación por CLI (`blender -b`, fallback de `pipeline.md`) y plantilla editada e
  inspeccionada con el MCP de Blender en modo CLI (`execute_blender_code_for_cli`,
  `get_blendfile_summary_missing_files_for_cli`: 0 ficheros perdidos en ambos `.blend`). El Blender de
  Fedora no carga el OCIO 2.5: el render lineariza las sRGB solo para Cycles (no afecta al `.blend`
  ni al glTF).
- Jugabilidad intacta: no se toca ninguna escena, colisión, ancla ni posición. `tools/verify.sh` verde
  (720/720 tests), `check_owns` limpio. Licencia: texturas y materiales propios (procedurales), la
  registra el coordinador.
- Pendiente fuera de la ficha: `test_cube.glb` no se reexporta (sigue con su copia de materiales v1;
  el `--smoke-cube` actual usaría `mat_wood_used`/`mat_plastic_red`).
