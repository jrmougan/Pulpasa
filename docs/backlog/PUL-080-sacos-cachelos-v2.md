---
id: PUL-080
title: Rehacer la cachelera como sacos de patatas
status: done
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-076]
orca_task: task_42b2e3304b84
unity_sources: []
owns: [art/blender/cachelos_storage.blend, godot/assets/models/stations/cachelos_storage/**, godot/entities/stations/cachelos_storage.tscn, docs/evidence/PUL-080/**]
touches_scenes: [godot/entities/stations/cachelos_storage.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Sacos de arpillera abiertos con patatas (las de PUL-076), quizá cesto; misma huella.

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
1. `art/blender/cachelos_storage.blend` rehecho desde `_template.blend` (materiales v2 enlazados) con el MCP de
   Blender por CLI (`execute_blender_code_for_cli`, sin el puerto 9876), reproducible con
   `docs/evidence/PUL-080/build_cachelos_storage.py` (copiado como Text dentro del `.blend`).
2. Dos sacos de arpillera abiertos (`mat_burlap`) con la boca enrollada hacia fuera, uno grande detrás y uno pequeño
   delante apoyado en él, llenos de las patatas crudas de PUL-076 (malla `cachelos_raw` de `cachelos.blend`,
   `mat_food_potato_raw` + `atlas_cachelos`, al 75 %); interior de la boca en sombra y franja impresa en el frente
   (atlas propio pequeño). Sin cesto: la huella no da para un tercer volumen legible.
3. Misma huella y contratos: raíz con `Anchor_Front`, todo dentro de la colisión 0,7 × 0,6 × 0,6; en la escena solo se
   añade `OutlineHull` (dos cilindros dentro de los sacos, la malla es abierta: nota de PUL-049) y `Highlightable.root`
   apunta a él. Colisión, script, `level_01` y tests intactos.
4. Export con `tools/blender_export.py --max-tris 6000`, import según `pipeline.md` §8.5, capturas antes/después
   desde la cámara del nivel y render Cycles del `.blend`.

## Evidence
- **Fuente**: `art/blender/cachelos_storage.blend`. Reproducible: copiar `_template.blend` → `cachelos_storage.blend` y
  ejecutar `build_all()` de [`build_cachelos_storage.py`](../evidence/PUL-080/build_cachelos_storage.py); export con
  [`export_cachelos_storage.sh`](../evidence/PUL-080/export_cachelos_storage.sh) (`--max-tris 6000`).
- **Triángulos** (§4.1, estación ≤ 6 000, objetivo ≈ 3 500): `cachelos_storage.glb` **2 840** (`sacks` 860,
  `potatoes` 1 980 = 9 patatas de PUL-076 de ≈ 220).
- **Texturas** (§4.2): biblioteca v2 `burlap` 512² (albedo + orm + normal) a 1 UV = 2 m (256 px/m, UV cilíndrica en
  los sacos); `atlas_cachelos` de PUL-076 (256², patatas); atlas propio `atlas_cachelos_storage` 64² (albedo + orm,
  celdas lisas: interior en sombra `#5E4B37`, fondo `#4A3B2C`, franja `#3D4A5C`). Embebidas en el `.glb`; Godot extrae
  7 PNG junto a él, todos con VRAM + mipmaps y `normal_map` en el `_normal`.
- **Medidas y contratos** (AC1, `test_assets_models.gd` en verde): conjunto 0,66 m de ancho × 0,55 de fondo × 0,58 de alto (saco grande 0,56 m
  de alto, pequeño 0,42; patatas hasta 0,65), dentro de la colisión de la v1 en planta; origen en la base, frente −Z
  (`Anchor_Front`), sin luces ni cámaras. Escena: solo `OutlineHull/SackBig` y `OutlineHull/SackSmall` (cilindros con
  `mat_burlap`, sin sombra) y `Highlightable.root = ../OutlineHull`; colisión, `ItemSpawner`, `level_01` y tests de
  selección/entrega sin cambios.
- **Legibilidad** (AC2, §6.5 «Sacos: patatas crudas visibles en la boca, del modelo de PUL-076»): las patatas asoman
  por encima del labio y se leen por la boca en sombra (≈ 1,7:1 de luminancia contra el interior; contra la arpillera
  `burlap` solo ≈ 1,3:1, por eso el interior oscuro y los ojos de la patata); silueta de dos sacos distinta de la olla
  de barro de la v1 y del resto de estaciones. Sin logo (§7 no lo pide en sacos) ni texto; la franja es marino apagado.
- **Resaltado** (§6.1-7): contorno fino amarillo en los costados de los dos sacos (`after_level_camera_hl*`); no llega
  al rulo de la boca, que es más ancho que el casco.
- **Capturas** (`docs/evidence/PUL-080/`, 1920×1080 desde la cámara de `level_01` con recorte `_zoom` ×3;
  [`capture_cachelos.gd`](../evidence/PUL-080/capture_cachelos.gd), `--audio-driver Dummy`):
  `before_level_camera_{plain,hl}` (olla de la v1) y `after_level_camera_{plain,hl}`. Render Cycles del `.blend`
  ([`render_cachelos_storage.py`](../evidence/PUL-080/render_cachelos_storage.py)): `blender_render_game.png` (vista de
  juego con el cocinero de referencia de 1,8 m) y `blender_render_detail.png` (bocas de los sacos).
- En las capturas, el arcón (PUL-079) y las encimeras (PUL-084) siguen en la v1 en esta rama.
- `tools/verify.sh` verde (726 tests) y `check_owns` limpio. Licencia propia (geometría y atlas procedurales; patatas de
  PUL-076): la registra el coordinador.
