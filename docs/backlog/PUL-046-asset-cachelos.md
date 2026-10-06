---
id: PUL-046
title: Modelar los cachelos crudos y cocidos
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: task_b72ed73011bd
unity_sources: []
owns: [art/blender/cachelos.blend, godot/assets/models/food/cachelos/**, godot/entities/items/cachelos.tscn, godot/entities/stations/cachelos_bowl.tscn, godot/tests/integration/test_cachelos.gd, godot/tests/integration/test_octopus.gd, docs/evidence/PUL-046/**]
touches_scenes: [godot/entities/items/cachelos.tscn, godot/entities/stations/cachelos_bowl.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Patatas crudas (con piel) y cocidas (cachelos partidos), distinguibles a distancia.
2. Fuente en `art/blender/cachelos.blend`; export `.glb` en `godot/assets/models/food/cachelos/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): variantes de cantidad (1, 2, 3 piezas) o piezas sueltas para montones en caja, olla y cuenco.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-046/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Copiar `_template.blend` → `art/blender/cachelos.blend`; modelar con el MCP de Blender (`bpy`/`bmesh`,
   estilo y convenciones del pulpo de PUL-045) dos mallas hermanas bajo la raíz `cachelos`:
   `cachelos_raw` (2 patatas enteras, ovaladas e irregulares, con piel) y `cachelos_cooked` (montón
   de 4 medios cachelos con la cara de corte clara hacia arriba), art-bible §3.3. `ingredient.gd`
   ya alterna `*_raw`/`*_cooked`: no se toca.
2. Ajuste §4 (cantidad / piezas sueltas): `cachelos_pieces.glb` hermano con tres capas
   `cachelos_pieces_a/b/c` (una ración cada una: 3, +2, +1 trozos), colección `export_pieces`.
3. `cachelos.tscn`: `Model` instancia `cachelos.glb` (mismo nodo, colisión y nodos de contrato);
   sin `raw_material`/`cooked_material`.
4. Ampliación de `owns` aprobada por el coordinador (opción A): `cachelos_bowl.tscn` (sustituir
   `Portion1..3` por las capas de trozos, mismos nodos, sin tocar el `.gd`), `test_cachelos.gd` y
   `test_octopus.gd` (el test del cambio de material usaba cachelos como modelo de un solo estado;
   pasa a un `Ingredient` sintético).
5. Capturas desde la cámara de `level_01` (mesa, mano, olla, cuenco) y render del `.blend`.

## Evidence
- **Modelos** (`docs/evidence/PUL-046/blender_render.png`, sobre `wood_light`; de izquierda a
  derecha: crudo, cocido, trozos a, a+b, a+b+c). Solo materiales de la paleta de la plantilla:
  crudo `mat_potato_raw` `#8E6B47` con banda inferior y «ojos» en `mat_wood_dark` `#6E4A2B`
  (borde/sombra de contacto, §3.1.3); cocido piel `mat_potato_cooked_dark` `#D8A93C` y cara de
  corte `mat_potato_cooked` `#F2D56B` con un borde del 20 % en el tono oscuro (separa trozos
  vecinos). Roughness 0,8 de la plantilla. Luminancia crudo 0,17 / cocido 0,68 → 3,3:1 (§3.3),
  además de entero frente a partido.
  | Malla | Triángulos | Medidas (ancho × fondo × alto, m) |
  |---|---|---|
  | `cachelos_raw` (2 patatas de 0,26 y 0,22 m) | 200 (≤ 600, objetivo ≈ 300) | 0,40 × 0,27 × 0,17 |
  | `cachelos_cooked` (4 medios cachelos) | 312 | 0,41 × 0,35 × 0,19 |
  | `cachelos_pieces` a (3) + b (2) + c (1) | 234 + 156 + 78 = 468 | 0,34 × 0,29 × 0,18 (a+b+c) |
  Tamaño: patata de 0,135 m (§2.1) ×1,9. Con ×1,4 (como el pulpo) el montón medía 0,30 m y en la
  captura del nivel se perdía junto al pulpo de 0,65 m; con ×1,9 (≈ 0,40 m) se lee sin competir con
  él. Escala aplicada a los vértices (`SCALE`/`PIECES_SCALE` en `build_cachelos.py`); objetos y
  nodos en (1, 1, 1). Base en z = 0, frente +Y → −Z. Geometría reproducible:
  `docs/evidence/PUL-046/build_cachelos.py`.
- **Export**: `blender -b art/blender/cachelos.blend --python tools/blender_export.py -- --category food --max-tris 600`
  → `OK cachelos.glb (4 objetos, 512 triángulos)`. Trozos (renombra en memoria colección y ancla,
  sin guardar, como PUL-045): `blender -b art/blender/cachelos.blend --python-expr "import bpy; D=bpy.data; D.collections['export'].name='export_whole'; D.collections['export_pieces'].name='export'; D.objects['Anchor_Front'].name='Anchor_Front_whole'; D.objects['Anchor_Front_pieces'].name='Anchor_Front'" --python tools/blender_export.py -- --out godot/assets/models/food/cachelos/cachelos_pieces.glb --max-tris 600`
  → `OK cachelos_pieces.glb (5 objetos, 468 triángulos)`. `godot --headless --import` sin errores.
  En `cachelos_pieces` el `Anchor_Front` cuelga de la capa `a` para que los hijos directos de la
  raíz sean solo las tres capas.
- **Escenas**: `cachelos.tscn` → `Model` = `cachelos.glb` en y = −0,26 (base en el fondo de la
  esfera de colisión, como `octopus.tscn`); colisión, `AnchorPoint`, `Highlightable` y
  `AmountBar` sin cambios. `cachelos_bowl.tscn` → `Portions` (y = 0,16, sobre el cuenco) con
  `Portion1..3` = instancias de `cachelos_pieces.glb` con hijos editables que muestran solo la capa
  a, b o c; `cachelos_bowl.gd` sigue alternando la visibilidad de `Portion1..3` según el stock, así
  que el montón crece por capas (`level_camera_bowl_stock_0_3.png`). Godot añadió `unique_id` a
  los nodos del cuenco al guardarla.
- **AC1**: `test_assets_models.gd` valida `cachelos.glb` y `cachelos_pieces.glb` (escala, base
  y = 0, `Anchor_Front` en −Z, sin cámaras/luces).
- **AC2** (cámara de `level_01`, 1920×1080, Forward+): `level_camera_cachelos.png` (crudo en
  PassSlot01, cocido en PassSlot02, pulpo cocido en PassSlot03 como referencia de tamaño; J1 de
  frente con crudos, J2 de lado con cocidos; cuenco con stock 3), `level_camera_zoom_crop.png`
  (×2), `level_camera_bowl_stock_0_3.png` (cuenco con 0–3 raciones, ×4) y
  `level_camera_pots_open.png` (crudo cociendo en Kitchen y cocido terminado en Kitchen2, con la
  malla `Pot` del placeholder oculta solo para la captura: el cilindro placeholder es macizo y tapa
  el contenido; el caldeiro abierto es PUL-048).
- **Tests**: `test_cachelos.gd::test_pul046_state_meshes_and_palette` (malla por estado, materiales
  `mat_potato_*`, luminancia cocido − crudo > 0,3) sustituye a la prueba de material del
  placeholder; `test_octopus.gd::test_model_without_state_meshes_keeps_material_swap` usa un
  `Ingredient` sintético de una malla. `test_seasoning_station.gd::test_ac10_portions_visual_follows_stock`
  sigue verde con las nuevas porciones. `tools/verify.sh` verde (618/618 antes de las capturas).
- **Observaciones**: `ph_cachelo_*.tres` y `placeholders/cachelos_*.tscn` siguen usados por
  `test_assets_m1.gd`/`scale_check`; no se tocan. En la mano el objeto queda a la altura del
  `HoldPoint` placeholder (igual que el pulpo, PUL-045): lo resuelve el `Anchor_Hold` de PUL-044.
  Pendiente del coordinador: licencia propia en `docs/assets/licenses.md` (Change 4).
