---
id: PUL-077
title: Rehacer platos/cajas como bandejas de la referencia
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-076, PUL-088]
orca_task: task_0a32db6b333f
unity_sources: []
owns: [art/blender/box.blend, godot/assets/models/items/box/**, godot/entities/items/box.tscn, godot/entities/items/box_model.gd, godot/tests/integration/test_box_model.gd, docs/evidence/PUL-077/**]
touches_scenes: [godot/entities/items/box.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
La referencia sirve en bandejas/recipientes rojos de plástico: tres tamaños distinguibles por forma además de color, relleno visible por capas, sitio para las pegatinas (fila billboard de PUL-059). Mantén `box_model.gd`, colisión por talla y grupo `box`.

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
- [x] AC1 Escala, frente y presupuesto de la biblia v2 → `test_assets_models.gd`
- [x] AC2 Legible y coherente con la referencia junto a los assets v2 ya hechos
- [x] Captura antes/después desde la cámara del nivel y render del `.blend`
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Capturas «antes» desde la cámara de `level_01` (tres tallas vacías, a medias y llenas, con y sin
   resaltado; J1 con una bandeja) con un script reproducible (`capture_boxes.gd`).
2. `box.blend` desde una copia de `_template.blend` (materiales v2 enlazados) con un script
   reproducible (`build_box_v2.py`) ejecutado con el MCP de Blender por CLI. Mismo contrato que
   PUL-047: raíz `box`, `box_small/medium/large`, `Anchor_Fill_<talla>`, `Anchor_Sticker_<talla>_0..3`,
   `sticker` oculto, `Anchor_Front` en +Y; ancho en X = diámetro v1 y alto ≈ 0,10 (lo fija
   `test_box_model.gd`), base en z = 0.
3. Biblia v2 §6.4: plástico `mat_plastic_red` con papel salvamanteles (símbolo de la marca al 15 %),
   pequeña redonda, mediana ovalada, grande rectangular con asas; aro de talla en el canto; símbolo
   en el canto frontal-inferior. Atlas propio de 512² (albedo + ORM) generado con `build_box_atlas.py`.
4. Resaltado: la bandeja es abierta, así que `OutlineHull` (nota de PUL-049) con un volumen cerrado
   invisible por talla; `box_model.gd` lo enciende con su talla (owns ampliado con aprobación del
   coordinador, con su test).
5. Export con `blender_export.py`, import VRAM/mipmaps, `fill_scale` por talla en `box.tscn`,
   capturas «después» y render del `.blend`.

## Evidence
- **Fuente reproducible** (todo en [`docs/evidence/PUL-077/`](../evidence/PUL-077/)):
  [`build_box_atlas.py`](../evidence/PUL-077/build_box_atlas.py) (atlas, PIL),
  [`build_box_v2.py`](../evidence/PUL-077/build_box_v2.py) (geometría; MCP de Blender por CLI sobre
  una copia de `_template.blend`), [`render_box.py`](../evidence/PUL-077/render_box.py) (render) y
  [`capture_boxes.gd`](../evidence/PUL-077/capture_boxes.gd) (capturas, `--audio-driver Dummy`).
- **Forma** (biblia v2 §6.4): tres tallas distinguibles por silueta — pequeña **redonda** (Ø 0,34),
  mediana **ovalada** (0,42 × 0,32), grande **rectangular redondeada con dos asas** de lengüeta con
  ranura (0,50 × 0,38, cuerpo 0,44); alto 0,098 m, pared con pie de contacto oscuro, labio enrollado
  con canto claro (roce), papel salvamanteles a 0,024 m con pliegue en el borde. Aro de talla de
  0,016 m bajo el labio: **azul / verde / papel**. *Desvío*: la biblia dice rojo para la grande, pero
  rojo sobre la bandeja roja no se ve; va en `brand_paper` (la grande ya se distingue por forma y asas).
  Símbolo de la marca (de `pulpasa_simbolo.png`, sin modificarlo) en papel sobre rojo, 0,044 m, en el
  canto frontal-inferior **del lado de la cámara (−Y de Blender, +Z de Godot)**; el arco de anclas de
  pegatina sigue en +Y (el `Anchor_Front` del contrato), así que nunca coinciden. La fila real de
  pegatinas sigue siendo el billboard `%BadgeRow` de PUL-059 (no se toca `badge_row.gd`).
- **Materiales y texturas**: `mat_plastic_red` enlazado de la biblioteca (UV de caja, 1 unidad = 2 m)
  más `atlas_box` (512², albedo + ORM, empaquetado en el `.blend` y embebido en el `.glb`): papel
  `#F4EFE6` con el símbolo en `#5B8DB8` **al 15 %** (≈ 560 px/m), símbolo del canto y celdas lisas de
  64 px (pie `#7E271D`, canto `#D65845`, pared interior `#B5392A`, aros, borde del papel). Sin ruido.
  Godot extrae 4 PNG junto al `.glb` (≈ 80 KB, todos 512²), con VRAM + mipmaps; el atlas de pegatinas
  de PUL-047 se conserva con el mismo nombre (`box_box_stickers.png`, sin cambios).
- **Triángulos** (`blender_export.py --max-tris 6000`, 2 126 en el `.glb`):

  | Malla | Tris | Medidas (m, x × y × z) | Antes (plato v1) |
  |---|---|---|---|
  | `box_small` | 558 | 0,34 × 0,34 × 0,098 | 0,34 × 0,34 × 0,10 |
  | `box_medium` | 558 | 0,42 × 0,32 × 0,098 | 0,42 × 0,42 × 0,10 |
  | `box_large` | 622 | 0,50 × 0,38 × 0,098 | 0,49 × 0,49 × 0,10 |
  | `hull_<talla>` (invisible) | 124 c/u | = contorno exterior | — |
  | `sticker` (oculto) | 16 | Ø 0,10 | igual |

  Con el relleno de pulpo al máximo (rodajas de PUL-076, 960) cada talla queda en ≤ 1 706 (≤ 2 000 de
  §4.1). Si además lleva cachelos (720 más, piezas de PUL-076) llega a ≈ 2 430: el exceso es de las
  piezas de comida, no de la bandeja (≈ 560–620 tris); lo anoto para PUL-087.
- **Relleno por capas**: mismas capas de `octopus_pieces`/`cachelos_pieces` y mismo `box_model.gd`;
  `Anchor_Fill_<talla>` sobre el papel. `fill_scale` se fija por talla en `box.tscn`
  (0,9 / 1,0 / 1,15, antes 0,95 / 1,15 / 1,35 en el script) para que el montón quepa en el papel.
- **Resaltado** (`OutlineHull`, nota de PUL-049): el inverted hull sobre la bandeja abierta (y sobre la
  comida) rellenaba de amarillo todo el interior, ya con los platos v1
  ([antes](../evidence/PUL-077/level_camera_before_highlight_zoom.png)). Ahora `%Highlightable.root`
  apunta a `Model/Plate/box/OutlineHull` del `.glb`, con un volumen cerrado invisible (alfa 0) por
  talla, y `box_model.gd` enseña solo `hull_<talla>`: contorno fino alrededor de la bandeja y la comida
  se ve dentro ([después](../evidence/PUL-077/level_camera_after_highlight_zoom.png)). Con
  aprobación del coordinador se amplió `owns` a `box_model.gd` (3 líneas) y `test_box_model.gd`
  (`test_outline_hull_follows_the_size`).
- **Capturas** (1920×1080, cámara de `level_01`; barra: pequeña vacía/llena con sal, mediana vacía/a
  medias/llena con cachelos, grande a un tercio/llena con cachelos; J1 con una mediana llena): antes
  [`plain`](../evidence/PUL-077/level_camera_before_plain.png) /
  [`zoom`](../evidence/PUL-077/level_camera_before_plain_zoom.png) /
  [`resaltado zoom`](../evidence/PUL-077/level_camera_before_highlight_zoom.png); después
  [`plain`](../evidence/PUL-077/level_camera_after_plain.png) /
  [`zoom`](../evidence/PUL-077/level_camera_after_plain_zoom.png) /
  [`resaltado`](../evidence/PUL-077/level_camera_after_highlight.png) /
  [`resaltado zoom`](../evidence/PUL-077/level_camera_after_highlight_zoom.png). El papel separa las
  rodajas del rojo, las tres siluetas se distinguen sobre el acero de las encimeras v2 (PUL-084, integrada la rama base antes de la captura «después»; la «antes» es con las encimeras v1) y en la mano.
  La estantería (`box_shelf`) sigue con sus pilas v1: la rehace PUL-081.
- **Render del `.blend`** (Cycles, encimera `mat_steel_brushed_top`, ortográfica a 38°; vacías detrás,
  llenas delante con la escala de `fill_scale`): [`blender_render.png`](../evidence/PUL-077/blender_render.png).
- **Jugabilidad intacta**: mismas colisiones por talla, anclas (`%AnchorPoint`, `Anchor_Fill_*`,
  `Anchor_Sticker_*`), nodos de contrato, grupo `box` y posiciones; `test_box_model.gd`,
  `test_assets_models.gd` y los de selección/entrega en verde. `tools/verify.sh` verde y
  `check_owns` limpio. Licencia: modelo y atlas propios (la registra el coordinador).
