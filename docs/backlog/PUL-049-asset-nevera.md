---
id: PUL-049
title: Modelar el arcón de pulpo
status: done
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043]
orca_task: task_ac3b6aa756ea
unity_sources: []
owns: [art/blender/octopus_storage.blend, godot/assets/models/stations/octopus_storage/**, godot/entities/stations/octopus_storage.tscn, docs/evidence/PUL-049/**]
touches_scenes: [godot/entities/stations/octopus_storage.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Arcón/nevera de feria o cubo con hielo del que se saca el pulpo crudo.
2. Fuente en `art/blender/octopus_storage.blend`; export `.glb` en `godot/assets/models/stations/octopus_storage/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. 
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): tapa separada (`Lid`).

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [x] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-049/`
- [x] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Partir de `_template.blend` → `octopus_storage.blend`; script reproducible `docs/evidence/PUL-049/build_octopus_storage.py` (MCP de Blender).
2. `chest_body` (arcón 1,6×0,9×0,8 con banda de feria, hielo y dos tentáculos) y `Lid` separada abierta, origen en la bisagra.
3. Export con `blender_export.py`, sustituir `Model` en `octopus_storage.tscn`, capturas desde la cámara de level_01.

## Evidence
- `art/blender/octopus_storage.blend` y `godot/assets/models/stations/octopus_storage/octopus_storage.glb` (+`.import`): 998 tris (presupuesto 1 500), 1,6 × 0,9 × 0,8 m (+ tapa abierta hasta 1,73 m y tentáculos hasta 1,3 m), frente +Y→−Z. Colores: steel_grey, iron_black, canvas_stripe, ice_blue, octopus_raw(+dark).
- `Lid` separada, abierta 105° (rotación cocida; origen en la bisagra trasera) para poder animarla.
- `octopus_storage.tscn`: solo cambia la instancia de `Model` (fridge.tscn → .glb). Colisión, `%Highlightable`, grupo `interactable` y script intactos: la huella en planta (1,61×0,91) no cambia, así que el acceso desde la planta B (navegación plana) no se ve afectado. La caja sigue siendo más alta (2,33 m) que el modelo; no se ha tocado para no alterar el contrato.
- Capturas en `docs/evidence/PUL-049/`: `blender_render.png`, `level_camera_plain*.png`, `level_camera_highlight*.png` (con personaje al lado), scripts `build_octopus_storage.py` y `capture_storage.gd`.
- Licencia (propia): pendiente de registrar por el coordinador en `docs/assets/licenses.md`.

### Corrección del resaltado (ronda del coordinador)
El inverted hull de `highlight_outline` rellenaba el arcón entero (cuba abierta, tapa fina, hielo). Sin tocar el shader ni `highlightable.gd`: la escena añade `OutlineHull` con dos cajas cerradas escondidas dentro del modelo (cuba y tapa) y `Highlightable.root` apunta a ese nodo, así el contorno sale de volúmenes cerrados. Capturas nuevas en `docs/evidence/PUL-049/level_camera_{plain,highlight}*.png`.
