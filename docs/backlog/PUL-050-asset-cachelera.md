---
id: PUL-050
title: Modelar la cachelera (saco o cesto de patatas)
status: review
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: null
unity_sources: []
owns: [art/blender/cachelos_storage.blend, godot/assets/models/stations/cachelos_storage/**, godot/entities/stations/cachelos_storage.tscn, godot/assets/models/placeholders/cachelera*, docs/evidence/PUL-050/**]
touches_scenes: [godot/entities/stations/cachelos_storage.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Saco de arpillera o cesto de patatas crudas.
2. Fuente en `art/blender/cachelos_storage.blend`; export `.glb` en `godot/assets/models/stations/cachelos_storage/` con
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
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-050/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Plantilla → `art/blender/cachelos_storage.blend`; saco de arpillera (`mat_burlap`) con boca enrollada y cuerda, más 6 patatas crudas con la misma función `add_potato` de PUL-046 (mismo `mat_potato_raw`).
2. Export con `tools/blender_export.py --category stations --max-tris 1500`; sustituir `Model` en `cachelos_storage.tscn` sin tocar colisión, `%Highlightable`, grupos ni script.
3. Capturas desde la cámara de level_01 y render del .blend.

## Evidence
- `art/blender/cachelos_storage.blend`, `godot/assets/models/stations/cachelos_storage/cachelos_storage.glb` (1 064 triángulos, ≈ 0,56 × 0,49 × 0,46 m: ancho × alto × fondo, base en y = 0, frente +Y→−Z).
- Capturas en `docs/evidence/PUL-050/`: `level_camera_plain*.png`, `level_camera_highlight*.png` (con Player2 al lado), `blender_render.png`; scripts reproducibles `build_cachelos_storage.py` y `capture_storage.gd`.
- Resaltado: el saco es casi macizo (la boca queda llena de patatas), el contorno inverted-hull no rellena nada raro; no hace falta `OutlineHull`.
- `tools/verify.sh` verde; `check_owns` limpio.
- **Placeholder `cachelera.tscn` NO retirado**: `godot/tests/unit/test_assets_m1.gd` (fuera de `owns`) lo exige. Ya no lo usa ninguna escena; retirarlo requiere quitarlo de ese test (coordinador).
- Licencia propia: pendiente de registrar por el coordinador en `docs/assets/licenses.md`.
