---
id: PUL-051
title: Modelar la estantería de cajas
status: review
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/box_shelf.blend, godot/assets/models/stations/box_shelf/**, godot/entities/stations/box_shelf.tscn, docs/evidence/PUL-051/**]
touches_scenes: [godot/entities/stations/box_shelf.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Estantería con los tres montones de cajas/platos identificables por tamaño.
2. Fuente en `art/blender/box_shelf.blend`; export `.glb` en `godot/assets/models/stations/box_shelf/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

Nota de PUL-049: si el modelo tiene mallas abiertas o huecas (cubas, cestos, baldas), el contorno inverted-hull del resaltado lo rellena entero. Solución usada: nodo `OutlineHull` con cajas cerradas ocultas y `Highlightable.root` apuntando a él; comprueba la captura resaltada.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-051/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Plantilla → `art/blender/box_shelf.blend`; `rack` (mueble) + tres montones de 3 platos con las medidas y aros de `box.blend`, centrados en los spawners.
2. Export con `tools/blender_export.py --category stations`; sustituir `Model` en `box_shelf.tscn`.
3. Resaltado: `OutlineHull` (tronco de cono cerrado oculto dentro del montón) por spawner con `Highlightable.root` apuntando a él (nota de PUL-049).
4. Capturas desde la cámara de `level_01`.

## Evidence
- `art/blender/box_shelf.blend`, `godot/assets/models/stations/box_shelf/box_shelf.glb` (+`.import`): 1 320 triángulos (≤ 1 500; objetivo 800 superado por los 9 platos), rack 1,84 × 1,64 × 1,66 m.
- **Desviación de medidas (art-bible §2.1: 1,2 × 1,6 × 0,5)**: los spawners (x −0,51/0/0,536, z −0,78) y su colisión son contrato y no se cambian, así que el mueble mide 1,8 de ancho y la balda de exposición (z = 0,31, donde apoyan los platos) llega hasta 1,08 m al frente; las baldas altas mantienen 1,6 de alto y 0,5 de fondo. La colisión del mueble (1,8 × 0,92 × 1,14) no se tocó y no cubre la balda delantera.
- Montones: platos de `box.blend` (0,34/0,42/0,49, alto 0,10) nidificados de 3 en 3 con aro azul/verde/rojo, centrados en cada spawner. Se retiran los `Model` placeholder (cubos) de los tres spawners; nodos, colisiones y scripts conservados.
- Resaltado: `OutlineHull` por spawner (cilindro/tronco cerrado oculto dentro del montón; material `wood_light`) y `Highlightable.root` apuntando a él; el contorno rodea solo el montón, no la balda.
- Capturas en `docs/evidence/PUL-051/`: `level_camera_plain|small|medium|large[_zoom].png` (Player2 al lado), `blender_render.png`; scripts `build_box_shelf.py`, `capture_shelf.gd`.
- `tools/verify.sh` OK (639 tests). Licencia (propia): la registra el coordinador en `docs/assets/licenses.md`.
