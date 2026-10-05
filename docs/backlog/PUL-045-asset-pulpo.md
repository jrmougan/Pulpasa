---
id: PUL-045
title: Modelar el pulpo crudo, cocido y troceado
status: review
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/octopus.blend, godot/entities/items/ingredient.gd, godot/tests/integration/test_octopus.gd, godot/tests/integration/test_cooking_station.gd, godot/assets/models/food/octopus/**, godot/entities/items/octopus.tscn, docs/evidence/PUL-045/**]
touches_scenes: [godot/entities/items/octopus.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Pulpo entero crudo (rosado-grisáceo) y cocido (rojo-morado), legibles y distintos desde la cámara; trozos de pulpo «á feira» para el contenido de la caja.
2. Fuente en `art/blender/octopus.blend`; export `.glb` en `godot/assets/models/food/octopus/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): separar `octopus_pieces` (rodajas) para el contenido de la caja.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-045/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Copiar `_template.blend` → `art/blender/octopus.blend`; modelar con el MCP de Blender (`bpy`/`bmesh`)
   dos mallas hermanas bajo la raíz `octopus`: `octopus_raw` (patas lacias extendidas, manto caído)
   y `octopus_cooked` (cuerpo más pequeño, patas enroscadas hacia arriba), §3.2 de la biblia.
2. Rodajas `octopus_pieces` en `.glb` aparte, en tres capas `octopus_pieces_a/b/c` (relleno
   progresivo de PUL-047), colección `export_pieces` del mismo `.blend`.
3. Silueta distinta exige mallas distintas → preguntado al coordinador (opción A aprobada):
   `ingredient.gd` alterna la visibilidad de hijos `*_raw`/`*_cooked`(/`*_burnt`) bajo `Model`;
   sin ellos sigue el cambio de material (cachelos). `owns` ampliado con `ingredient.gd`,
   `test_octopus.gd` y `test_cooking_station.gd` (aprobado).
4. `octopus.tscn`: `Model` instancia `octopus.glb` (mismo nodo, transform y colisión).
5. Captura desde la cámara de `level_01` y render del `.blend`.

## Evidence
- **Modelos** (`docs/evidence/PUL-045/blender_render.png`): crudo `#C9B0BC`/`#9A8294`
  (roughness 0,9), cocido `#B8283D`/`#6E1A3A` (0,5), ojos `salt` + `iron_black`; 4 colores por
  variante. Rodajas con piel `#D4506A` y corte `#F4C6CC` (§3.2; materiales nuevos
  `mat_octopus_pieces[_cut]` con hex exacto, no estaban en la plantilla).
  | Malla | Triángulos | Medidas (ancho × fondo × alto, m) |
  |---|---|---|
  | `octopus_raw` | 440 (≤ 600) | 0,46 × 0,47 × 0,19 |
  | `octopus_cooked` | 568 (≤ 600) | 0,42 × 0,42 × 0,24 |
  | `octopus_pieces` (a+b+c: 7+5+3 rodajas Ø 0,06) | 420 (≤ 600) | 0,22 × 0,21 × 0,08 |
  Ventosas: cara ventral de cada pata en el tono oscuro; en el cocido quedan por fuera del rizo
  (visibles desde arriba), en el crudo asoman en las puntas giradas. Base en z = 0, frente +Y
  (ojos) → −Z en Godot. Geometría reproducible: `docs/evidence/PUL-045/build_octopus.py`.
- **Export**: `blender -b art/blender/octopus.blend --python tools/blender_export.py -- --category food --max-tris 1200`
  → `OK octopus.glb (4 objetos, 1008 triángulos)`. Rodajas (renombra en memoria la colección y el
  ancla, sin guardar): `blender -b art/blender/octopus.blend --python-expr "import bpy; D=bpy.data; D.collections['export'].name='export_whole'; D.collections['export_pieces'].name='export'; D.objects['Anchor_Front'].name='Anchor_Front_whole'; D.objects['Anchor_Front_pieces'].name='Anchor_Front'" --python tools/blender_export.py -- --out godot/assets/models/food/octopus/octopus_pieces.glb --max-tris 600`
  → `OK octopus_pieces.glb (5 objetos, 420 triángulos)`. `godot --headless --import` sin errores.
- **AC1**: `test_assets_models.gd` valida ambos `.glb` (escala aplicada, base y = 0, `Anchor_Front`
  en −Z, sin cámaras/luces).
- **AC2**: `level_camera_raw_cooked_pieces.png` (1920×1080, cámara de `level_01`; crudo en
  PassSlot01, cocido en PassSlot02, rodajas en PassSlot03) y `level_camera_zoom_crop.png`
  (recorte ×3). Crudo y cocido se distinguen por color, luminosidad (≈ 0,47 vs 0,12, 3,1:1) y
  silueta (estrella lacia vs. bola rizada).
- **Código**: `ingredient.gd::_apply_state_variants`; tests `test_octopus.gd` (malla por estado,
  quemado con/sin malla propia, cachelos mantiene el cambio de material) y
  `test_cooking_station.gd::test_ac2_cooked_octopus_shows_cooked_mesh` (visibilidad + el cocido
  usa `mat_octopus_cooked` y no `mat_octopus_raw`).
- **Observaciones**: el crudo sobre la encimera (`wood_light`, L ≈ 0,44) se separa por forma y
  sombreado más que por luminosidad (§3.1.3); si en la revisión se ve flojo, opción barata: borde
  oscuro o sombra de contacto. `ph_octopus_*.tres` y los placeholders `octopus_raw/cooked.tscn`
  siguen usados por `scale_check.tscn`, no se tocan. Pendiente del coordinador: licencia propia en
  `docs/assets/licenses.md` (Change 4).
