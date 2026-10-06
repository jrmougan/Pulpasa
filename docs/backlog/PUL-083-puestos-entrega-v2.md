---
id: PUL-083
title: Rehacer los puestos de entrega como kioscos
status: review
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-088]
orca_task: null
unity_sources: []
owns: [art/blender/order_stand.blend, godot/assets/models/stations/order_stand/**, godot/entities/stations/order_stand.tscn, docs/evidence/PUL-083/**]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Kiosco con caja registradora/TPV y bandeja de entrega, toldillo de su color (1–4) y número visible; `%OrderLabel`, `%DeliveryZone` y colisión intactos.

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
1. `art/blender/order_stand.blend` nuevo desde `_template.blend` (materiales v2 enlazados), generado con el MCP de
   Blender por CLI (`execute_blender_code_for_cli`, sin tocar el puerto 9876) y reproducible con
   `docs/evidence/PUL-083/build_order_stand.py` (copiado como Text dentro del `.blend`).
2. Kiosco de la referencia (biblia v2 §1.2, §6.5, §8): cuerpo `mat_steel_dark` con tablero `mat_steel_brushed_top`,
   marco y tornillos en el frente (Z2), disco blanco del número de 0,34 m; TPV pequeño (pantalla `mat_emissive_screen`,
   teclado de colores); bandeja de entrega de acero con la caja de llevar blanca, faja `brand_red` e insignia compacta
   PulpaSA (más pequeña que el número, §7); toldillo a rayas `mat_canvas_stand_k`/`mat_canvas_paper` con festón y sin
   logo (§2.7), sobre dos postes traseros.
3. Mismos contratos: mallas `counter` y `awning_1..4` (las usa `OrderStandModel`), anclas `Anchor_Front`,
   `Anchor_Number`, `Anchor_Sign`; en la escena solo se recolocan `StandNumber` sobre el disco y los cascos de
   `OutlineHull` dentro de la geometría nueva. Colisiones, `%DeliveryZone`, `%OrderLabel`, `%Highlightable` y
   posiciones de `level_01` sin cambios.
4. Export con `tools/blender_export.py`, import con `pipeline.md` §8.5, capturas antes/después y render Cycles.

## Evidence
- **Fuente**: `art/blender/order_stand.blend`. Reproducible: copiar `_template.blend` → `order_stand.blend` y ejecutar
  `build_all()` de [`build_order_stand.py`](../evidence/PUL-083/build_order_stand.py); export con
  [`export_order_stand.sh`](../evidence/PUL-083/export_order_stand.sh) (`--max-tris 6000`).
- **Triángulos** (§4.1, kiosco ≤ 6 000): `order_stand.glb` 2 924 en total (`counter` 528, `tpv` 92, `tray` 288,
  `awning_1..4` 504 c/u); **visibles por puesto: 1 412** (×4 en el nivel: 5 648).
- **Texturas** (§4.2): biblioteca v2 (`steel_brushed`, `steel_brushed_top`, `canvas`; `steel_dark`,
  `steel_brushed_mid`, `rubber`, `emissive_screen` y los `canvas_stand_1..4`/`canvas_paper` por factor) a 1 UV = 2 m
  (256 px/m) y el atlas propio `order_stand_atlas` 512² (disco del número, insignia compacta de
  `pulpasa_compacta.png`, teclado, faja de la caja, tornillos; ≈ 365 px/m). Embebidas en el `.glb`; Godot extrae
  10 PNG junto a él, todos con VRAM + mipmaps y `normal_map` en los `_normal`.
- **Medidas y contratos** (AC1, `test_assets_models.gd` y `test_order_stand_model.gd` en verde): mostrador
  1,44 × 0,95 × 0,47 m (`counter` 1,44 de ancho), toldillo hasta 1,81 m, origen en la base, frente −Z
  (`Anchor_Front` en z = −0,235). Escena: `StandNumber` pasa a (0; 0,50; −0,232) sobre el disco y `pixel_size`
  0,0058; `OutlineHull/Counter` 1,36 × 0,93 × 0,40 y `OutlineHull/Awning` 1,46 × 0,02 × 0,61 con la inclinación
  del toldillo (18,4°), ambos dentro de la malla. Colisiones, `%DeliveryZone`, `%OrderLabel` y `level_01` intactos.
- **Legibilidad** (AC2, §6.5): número negro en disco blanco de 0,34 m en el frente (lo más llamativo del frente); el
  TPV (pantalla 0,19 × 0,12 m) y la insignia (0,095 m) son menores; color del puesto en el toldillo (rayas de los
  bordes en `stand_k`) y en el festón; la caja de llevar y el TPV se ven bajo el toldillo desde la cámara del nivel.
- **Resaltado** (§6.1-7): contorno fino amarillo en cuerpo y toldillo del puesto 2 (`after_level_camera_hl*`).
- **Capturas** (`docs/evidence/PUL-083/`, 1920×1080 desde la cámara de `level_01` con recorte `_zoom` ×2;
  [`capture_stands.gd`](../evidence/PUL-083/capture_stands.gd), `--audio-driver Dummy`): `before_level_camera_{plain,hl}`
  (v1 de PUL-053) y `after_level_camera_{plain,hl}`. Render Cycles del `.blend`
  ([`render_order_stand.py`](../evidence/PUL-083/render_order_stand.py)): `blender_render_row.png` (los cuatro
  puestos) y `blender_render_detail.png` (puesto 2 de cerca).
- **Luz**: en las capturas el acero metálico (`steel_dark`) sale oscuro y algo verdoso porque aún no hay reflejos del
  entorno; se revisará cuando entre PUL-089 (va en paralelo). Las encimeras vecinas siguen en madera v1 hasta PUL-084.
- `tools/verify.sh` verde (725 tests) y `check_owns` limpio. Licencia propia (geometría y atlas procedurales; la
  insignia es de PUL-088): la registra el coordinador.
