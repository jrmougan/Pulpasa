---
id: PUL-084
title: Rehacer encimeras y suelo de la cocina
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-073]
orca_task: null
unity_sources: []
owns: [art/blender/counters.blend, godot/assets/models/furniture/counters/**, godot/entities/environment/kitchen_layout.tscn, docs/evidence/PUL-084/**]
touches_scenes: [godot/entities/environment/kitchen_layout.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Encimeras y pasaplatos de acero inoxidable con cajones/puertas, tablas y utensilios de atrezo encima (sin tapar huecos jugables), rejillas de desagüe en el suelo; mismas huellas, capa `world` y alturas de PUL-054.

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
1. `art/blender/counters.blend` rehecho desde `_template.blend` (materiales v2 enlazados) con el MCP de Blender por CLI
   (`execute_blender_code_for_cli`, sin tocar el puerto 9876) a partir de `docs/evidence/PUL-084/build_counters.py`.
   Mismas 11 piezas, nombres, huellas, alturas y `Anchor_Front` que PUL-054 → `kitchen_layout.tscn` no cambia de montaje.
2. Acero (biblia v2 §8): tablero `mat_steel_brushed_top` limpio (Z1), canto con tornillos, frentes (Z2) por metro con
   cajones y, alternando, puertas con rejilla o balda abierta con cajas de cartón; patas y pies de goma. Pasaplatos igual
   por las dos caras y marco fino oscuro en cada sitio de `Slot`. Atlas propio 256² (tornillo, rejilla de ventilación, rejilla de desagüe).
3. Piezas nuevas: `drain_grate` (Z0) y atrezo de franja trasera `counter_props_board` / `counter_props_crock` (Z1),
   colocados solo en encimeras sin `Slot`.
4. Suelo (acordado con el coordinador): material del `Floor` a `mat_ground_dirt` triplanar (`kitchen_floor_dirt.tres`) y
   tres rejillas; rodadas y charcos los pone PUL-085 en `environment.tscn`.
5. Export con `tools/blender_export.py`, import según `pipeline.md` §8.5, capturas antes/después y render del `.blend`.

## Evidence
- **Fuente**: `art/blender/counters.blend` (lleva el script como Text). Reproducible: copiar `_template.blend` →
  `counters.blend` y ejecutar `build_all()` de [`build_counters.py`](../evidence/PUL-084/build_counters.py); export con
  [`export_counters.sh`](../evidence/PUL-084/export_counters.sh) (presupuesto 1 500 por metro, atrezo 800).
- **Triángulos** (§4.1, encimera ≤ 1 500 por módulo de 1 m): `counter_1m` 422, `counter_2m` 662, `counter_3m` 926,
  `counter_half` 368, `counter_corner` 486, `counter_end` 510, `pass_1m` 706, `pass_2m` 1 210, `pass_3m` 1 714
  (571/m), `pass_end` 794, `rail_1m` 104, `drain_grate` 12, `counter_props_board` 218, `counter_props_crock` 232.
- **Texturas** (§4.2): solo biblioteca v2 (`steel_brushed`, `steel_brushed_top`, `cardboard`, `wood_used`, `wood_dark`,
  `clay`; `steel_brushed_mid`/`steel_dark`/`rubber` sin textura propia) a 1 UV = 2 m (256 px/m) y atlas propio
  `counters_atlas` 256² (empaquetado). Embebidas en los `.glb`; Godot extrae 115 PNG (3,9 MB en disco, todos VRAM +
  mipmaps, `normal_map` en los `_normal`); los 11 `.glb.import` antiguos pasan a `ensure_tangents=true`. Nota: el
  pipeline duplica la textura de biblioteca por cada `.glb` (14 piezas); en VRAM ≈ 40 MB, dentro de los 256 MB, pero
  PUL-087 puede querer compartirlas.
- **Jugabilidad sin cambios**: colisiones, capa `world`, huellas, alturas (1,00 / 1,10 / 0,60) y transformaciones de
  todos los módulos idénticas; `Slot` sin tocar (la retícula cae dentro del marco nuevo). Atrezo sin colisión, ≤ 0,25 m,
  en la franja trasera (z = +0,37 local, fondo ≤ 0,24 m) de `BackBetweenStoragePot`, `BackRight`, `WallLeftKitchen` y
  `WallRight` (ningún `Slot` ni ancla a menos de 0,15 m); nada imita comida ni condimento. Rejillas en
  `Floor/Grates` (delante de las ollas, paso inferior entre kioscos 2 y 3, hueco de la columna derecha), 0,5 cm sobre la
  tierra de `ground.glb` (y = 0,01), canaleta enterrada; sin colisión.
- **Suelo**: `Floor` usa `kitchen_floor_dirt.tres` (`mat_ground_dirt`, triplanar 1 UV = 4 m). Dentro del puesto lo
  tapa aún el `ground.glb` v1 de `environment.tscn` (PUL-085), así que el cambio se ve sobre todo fuera (antes verde).
- **Legibilidad (§5, §6)**: tablero liso; detalle (cajones, puertas, tornillos ≥ 0,06 m, cajas) solo en frentes (Z2).
  El marco de 4 cm del pasaplatos marca cada hueco de dejar sin tapar el apoyo. Resaltado: los `Slot` usan retícula
  (no hay `highlight_outline` sobre las encimeras), se ve limpia sobre el acero (`after_level_camera_highlight*`).
- **Capturas** (`docs/evidence/PUL-084/`, 1920×1080 desde la cámara de `level_01`, [`capture_counters.gd`](../evidence/PUL-084/capture_counters.gd),
  con recortes ×2 `_bar`, `_right`, `_front`): `before_level_camera_{plain,boxes,highlight}` (madera v1 de PUL-054) y
  `after_level_camera_{plain,boxes,highlight}`. Render Cycles del `.blend` ([`render_counters.py`](../evidence/PUL-084/render_counters.py)):
  `blender_render_kit.png` (kit completo, atrezo y rejilla) y `blender_render_detail.png`.
- **Luz**: la del nivel; el acero metálico se ve oscuro y verdoso en los frentes hasta que entre PUL-089 (reflejos), igual
  que la estación de condimentos y las ollas. La barrera del público se estira en X en la escena (como en PUL-054): su
  cepillado se alarga, sin detalles que se deformen.
- `tools/verify.sh` verde y `check_owns` limpio. Licencia (propia, atlas procedural sin terceros): la registra el coordinador.
