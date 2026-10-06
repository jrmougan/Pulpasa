---
id: PUL-076
title: Rehacer pulpo, cachelos y raciones con la estética de referencia
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074]
orca_task: null
unity_sources: []
owns: [art/blender/octopus.blend, art/blender/cachelos.blend, godot/assets/models/food/**, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_cachelos.gd, godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn, docs/evidence/PUL-076/**]
touches_scenes: [godot/entities/items/octopus.tscn, godot/entities/items/cachelos.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Pulpo (crudo/cocido/quemado), rodajas, cachelos (crudo/cocido/quemado) y trozos con más detalle y material v2; mismos nombres de malla `*_raw/*_cooked/*_burnt` y piezas por capas.

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
1. Partir de `_template.blend` v2 (materiales enlazados de `_materials_v2.blend`) para `octopus.blend`
   y `cachelos.blend`; geometría con un script reproducible
   (`docs/evidence/PUL-076/build_food_v2.py`) ejecutado con el MCP de Blender por CLI
   (`execute_blender_code_for_cli`, sin el puerto 9876).
2. Mismos nombres y jerarquía que PUL-045/046/069: `<asset>_raw/_cooked/_burnt` bajo la raíz,
   `<asset>_pieces_a/b/c` en `*_pieces.glb` (y `Anchor_Front_pieces` donde estaba), mismas huellas y
   alturas (±1–3 cm), así colisiones, anclas, `box_model.gd` y `cachelos_bowl.tscn` no cambian. No
   se tocan `octopus.tscn` ni `cachelos.tscn`.
3. Cuerpo de cada estado con el `mat_food_*` de la biblioteca; detalle que no se repite (ventosas,
   ojos, corte de rodaja, borde y piel del cachelo, brasas) en un atlas propio de 256² por asset
   (albedo + ORM, celdas lisas, empaquetado en el `.blend`, embebido en el `.glb`).
4. Más detalle sin ruido: tentáculos de 6 lados con franja ventral y ventosas en relieve, manto en
   forma de saco con ojos hacia la cámara, puntas rotas en el quemado; patatas con hoyuelos, trozos
   gruesos con piel, borde de 0,011 m y cara de corte abombada; rodajas con corona de piel y corte.
5. Export con `blender_export.py` (todo + piezas), import con texturas VRAM/mipmaps, capturas
   antes/después desde la cámara de `level_01` (sin y con resaltado) y render del `.blend`.

## Evidence
- **Fuente reproducible**: [`build_food_v2.py`](../evidence/PUL-076/build_food_v2.py) (ejecutado con el
  MCP de Blender por CLI sobre una copia de `_template.blend`), render
  [`render_food.py`](../evidence/PUL-076/render_food.py) y capturas
  [`capture_food.gd`](../evidence/PUL-076/capture_food.gd) (`--audio-driver Dummy`).
- **Export** (`blender_export.py`, `--max-tris` 4500 el entero = 3 × 1 500 y 1 500 las piezas):

  | Malla | Tris (≤ biblia §4.1) | Medidas (m, x × y × z) | Antes (tris / medidas) |
  |---|---|---|---|
  | `octopus_raw` | 1 172 (≤ 1 500) | 0,64 × 0,65 × 0,27 | 440 / 0,65 × 0,66 × 0,26 |
  | `octopus_cooked` | 1 252 | 0,61 × 0,61 × 0,34 | 568 / 0,59 × 0,59 × 0,33 |
  | `octopus_burnt` | 832 | 0,55 × 0,55 × 0,27 | 568 / 0,53 × 0,53 × 0,27 |
  | `octopus_pieces` a + b + c (7 + 5 + 3 rodajas) | 448 + 320 + 192 = 960 | 0,28 × 0,27 × 0,11 | 420 |
  | `cachelos_raw` (2 patatas) | 440 | 0,41 × 0,28 × 0,17 | 200 / 0,40 × 0,27 × 0,17 |
  | `cachelos_cooked` (4 trozos) | 480 | 0,42 × 0,36 × 0,22 | 312 / 0,41 × 0,35 × 0,19 |
  | `cachelos_burnt` | 480 | 0,36 × 0,31 × 0,17 | 312 / 0,37 × 0,32 × 0,15 |
  | `cachelos_pieces` a + b + c (3 + 2 + 1) | 360 + 240 + 120 = 720 | 0,33 × 0,29 × 0,21 | 468 |

  Las tallas siguen dentro de la esfera de 0,26 m de las escenas; base en z = 0 (±1 mm), frente
  `Anchor_Front` en +Y, sin luces ni cámaras.
- **Materiales**: `mat_food_octopus_{raw,cooked,burnt,pieces}` y `mat_food_potato_{raw,cooked,burnt}`
  enlazados de la biblioteca (el quemado con su textura de grietas, UV de caja a 1 unidad = 2 m) más
  `atlas_octopus` / `atlas_cachelos` (256², albedo + ORM, celdas lisas de 64 px por color: ventosas
  `#9A6E7A`/`#6E1A3A`, boca de ventosa, ojos, corte de rodaja `#F4C6CC`, borde del cachelo `#D8A93C`,
  piel cocida, brasas `#5A2A1E`/`#4A2E1E`). Godot extrae 14 PNG (≈ 464 KB en disco, todos ≤ 512²) junto
  a los `.glb`, importados con VRAM + mipmaps (normales con `normal_map=1`). Sin ruido en la comida:
  el único grano es el de las grietas grandes del quemado de la biblioteca.
- **Forma por estado** (biblia §6.2/§6.3): crudo con patas lacias, puntas retorcidas que enseñan
  ventosas y contorno ventral oscuro (separa el rosa del acero); cocido con patas enroscadas y
  ventosas crema por fuera del rizo; quemado encogido, arrugado y con las puntas rotas (corte de
  brasa). Patata cruda entera con hoyuelos; cocida partida en trozos gruesos inclinados hacia la
  cámara (cara clara con borde de 0,011 m y piel en el canto); quemada encogida y agrietada.
  Los ojos del pulpo miran a −Y de Blender (+Z de Godot, el lado de la cámara del nivel); antes miraban
  al lado contrario y no se veían. `Anchor_Front` no cambia.
- **Capturas** (1920×1080, cámara de `level_01`; barra: pulpo crudo/cocido/quemado, caja llena con
  rodajas y cachelos, cachelos crudos/cocidos/quemados; J1 con un pulpo crudo en la mano):
  antes [`plain`](../evidence/PUL-076/level_camera_before_plain.png) /
  [`zoom`](../evidence/PUL-076/level_camera_before_plain_zoom.png) /
  [`resaltado`](../evidence/PUL-076/level_camera_before_highlight_zoom.png); después
  [`plain`](../evidence/PUL-076/level_camera_after_plain.png) /
  [`zoom`](../evidence/PUL-076/level_camera_after_plain_zoom.png) /
  [`resaltado`](../evidence/PUL-076/level_camera_after_highlight.png) /
  [`resaltado zoom`](../evidence/PUL-076/level_camera_after_highlight_zoom.png). El contorno
  `highlight_outline` se ve completo en los seis estados y en la mano (los modelos son cerrados: no
  hace falta `OutlineHull`). **Luz**: la actual del nivel (v1); PUL-073 trae la final en paralelo, hay
  que repetir la captura con ella. El resto del nivel sigue en v1, así que la coherencia con la
  referencia se juzga sobre todo en el render.
- **Render del `.blend`** (Cycles, encimera `mat_steel_brushed_top`, cámara ortográfica a 38°):
  [`blender_render_octopus.png`](../evidence/PUL-076/blender_render_octopus.png),
  [`blender_render_cachelos.png`](../evidence/PUL-076/blender_render_cachelos.png).
- **Jugabilidad intacta**: no cambian `octopus.tscn`, `cachelos.tscn`, colisiones, anclas, nodos de
  contrato ni posiciones; los nombres de malla y de capa son los mismos. Dos tests fijaban los
  nombres de material v1 (`mat_octopus_*`, `mat_potato_*`): con aprobación del coordinador se amplió
  `owns` a `test_cooking_station.gd` y `test_cachelos.gd` y solo cambian los nombres esperados a
  `mat_food_*` (misma intención: material del estado; cocido más luminoso que crudo).
  `tools/verify.sh` verde (720/720 tests, smoke OK) y `check_owns` limpio. Licencia: modelos y atlas
  propios (la registra el coordinador).
- **Para PUL-079/080**: el pulpo crudo y la patata cruda de este `.blend` son los que deben ir dentro
  del tanque y en la boca de los sacos.
