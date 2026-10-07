---
id: PUL-081
title: Rehacer la estantería como rack de bandejas
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-077]
orca_task: task_44988ff309a6
unity_sources: []
owns: [art/blender/box_shelf.blend, godot/assets/models/stations/box_shelf/**, godot/entities/stations/box_shelf.tscn, docs/evidence/PUL-081/**]
touches_scenes: [godot/entities/stations/box_shelf.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Rack metálico con pilas de bandejas rojas por tamaño delante de cada spawner (formas de PUL-077).

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
1. Capturas «antes» desde la cámara de `level_01` (sin nadie, spawner mediano resaltado con J1 delante y los
   tres resaltados) con un script reproducible (`capture_box_shelf.gd`, `--audio-driver Dummy`).
2. `art/blender/box_shelf.blend` rehecho desde una copia de `_template.blend` (materiales v2 enlazados) con el
   MCP de Blender por CLI (`execute_blender_code_for_cli`, sin el puerto 9876), reproducible con
   `docs/evidence/PUL-081/build_box_shelf.py` (copiado como Text dentro del `.blend`).
3. Misma huella que la v1 (PUL-051): rack de acero de cuatro baldas al fondo (cuerpo 1,8 × 1,14 m) y banco bajo
   de acero delante con el tablero a 0,31 m (la altura de los spawners); encima, una pila de cuatro bandejas
   de PUL-077 (mallas de `box.blend`) en la posición de cada spawner; etiqueta de talla con el color del aro en
   el faldón. Cajas de cartón de atrezo en las baldas.
4. Resaltado (nota de PUL-049): la pila es abierta, así que un volumen cerrado invisible `hull_<talla>` por pila
   dentro del `.glb` (como PUL-077) y el `Highlightable.root` de cada spawner apunta a su hull; se retiran los
   cilindros de la escena. Colisiones, spawners, `level_01` y tests sin cambios.
5. Export con `tools/blender_export.py --max-tris 6000`, import según `pipeline.md` §8.5, capturas «después» y
   render Cycles del `.blend`.

## Evidence
- **Fuente**: `art/blender/box_shelf.blend`. Reproducible: copiar `_template.blend` → `box_shelf.blend` y ejecutar
  `build_all()` de [`build_box_shelf.py`](../evidence/PUL-081/build_box_shelf.py) (MCP de Blender por CLI); export
  con [`export_box_shelf.sh`](../evidence/PUL-081/export_box_shelf.sh) (`--max-tris 6000`).
- **Forma** (biblia v2 §1.2, §5 regla 2, §6.4, §8): rack de acero de 1,8 × 0,54 × 1,45 m al fondo (postes y
  largueros `mat_steel_brushed_mid`, baldas de cinco varillas `mat_steel_dark`, seis cajas `mat_cardboard`) y
  banco bajo delante (1,8 × 1,04 m, tablero `mat_steel_brushed_top` a 0,31 m, patas, faldón y balda baja). Sobre
  el banco, en la posición exacta de cada spawner (Godot x = −0,51 / 0 / 0,536, z = −0,78), una **pila de cuatro
  bandejas rojas** de PUL-077 encajadas (paso 0,035 m, giro de ±3° a mano, símbolo del canto hacia el frente):
  pequeña redonda, mediana ovalada, grande rectangular con asas, con su aro azul / verde / papel y papel
  salvamanteles en la de arriba. De las bandejas de abajo se borran las caras que tapa la de encima (papel,
  pared interior, pie): ≈ 1 330 tris por pila en vez de ≈ 2 300. En el faldón (Z2), una etiqueta por talla del
  color del aro, más ancha cuanto mayor la talla (celdas `band_<talla>` de `atlas_box`).
- **Triángulos** (§4.1, estación ≤ 6 000 sin contar las bandejas): `box_shelf.glb` **5 876** en total, contando
  las pilas: `rack` 1 012, `cartons` 264, `labels` 6, `stack_small` 1 326, `stack_medium` 1 326, `stack_large`
  1 570, `hull_*` 3 × 124 (invisibles). Sin las bandejas, la estación son 1 282.
- **Texturas** (§4.2): solo biblioteca v2 (`steel_brushed`, `steel_brushed_top`, `cardboard`, `plastic`, 512², UV
  de caja a 1 UV = 2 m → 256 px/m) y el atlas de PUL-077 (`box_atlas` 512², albedo + ORM) que traen las bandejas;
  sin atlas propio. Embebidas en el `.glb`; Godot extrae 12 PNG junto a él (≈ 360 KB en disco), todos con VRAM +
  mipmaps y `normal_map` en los `_normal`. `.glb.import` con `ensure_tangents=true` (normal maps v2).
- **Medidas y contratos** (AC1, `test_assets_models.gd` en verde): 1,80 m de ancho × 1,62 de fondo × 1,45 de alto
  (la v1 medía 1,84 × 1,66 × 1,64), cuerpo dentro de la colisión de la v1 y banco bajo los spawners como antes;
  origen en la base, frente −Z (`Anchor_Front`), sin luces ni cámaras, sin escala ni giro en ningún nodo. En la
  escena solo cambian los resaltados: se quitan los tres `OutlineHull/Body` (cilindros de madera) y cada
  `Highlightable.root` apunta a `Model/box_shelf/OutlineHull/hull_<talla>`. Colisiones, `ItemSpawner`, datos,
  `level_01` y los tests de selección/entrega (`test_shelves`, `test_level_01`, flujos e2e) sin cambios.
- **Resaltado** (§6.1-7, nota de PUL-049): `hull_<talla>` es un volumen cerrado de pie a labio de la pila (alfa 0,
  `mat_outline_hull` de PUL-077) con el **origen en la base de su pila**: `highlight_outline` crece radialmente
  desde el origen de la malla y, con el origen en la raíz del rack, el contorno salía desplazado hacia el frente
  (lo vi en la primera captura y lo corregí). Ahora es un contorno fino alrededor de cada pila
  (`after_level_camera_hl*`, `after_level_camera_hl_all*`).
- **Legibilidad** (AC2): desde la cámara del nivel se ven las tres siluetas distintas (redonda, oval, rectangular)
  con el papel claro y los aros de talla en el canto, rojo `plastic_red` sobre el acero del banco como las pilas
  de bandejas de la referencia sobre racks metálicos; mismo acero y cartón que las encimeras v2 (PUL-084). Sin
  logo nuevo (el símbolo es el del canto de la bandeja, §7) ni texto.
- **Capturas** (`docs/evidence/PUL-081/`, 1920×1080 desde la cámara de `level_01` con recorte `_zoom` ×3;
  [`capture_box_shelf.gd`](../evidence/PUL-081/capture_box_shelf.gd), `--audio-driver Dummy`):
  `before_level_camera_{plain,hl,hl_all}` (mueble de madera de la v1) y `after_level_camera_{plain,hl,hl_all}`.
  Render Cycles del `.blend` ([`render_box_shelf.py`](../evidence/PUL-081/render_box_shelf.py)):
  `blender_render_front.png` (frente con el cocinero de referencia de 1,8 m), `blender_render_level.png` (desde el
  costado +X, como lo ve la cámara del nivel) y `blender_render_detail.png` (pilas y etiquetas).
- El panel del HUD tapa parte de la columna izquierda en la captura completa (igual antes y después).
- `tools/verify.sh` verde (735 tests) y `check_owns` limpio. Licencia propia (geometría procedural; bandejas de
  PUL-077): la registra el coordinador.
