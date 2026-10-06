---
id: PUL-074
title: Crear la biblioteca de materiales estilizados
status: ready
milestone: M3b
role: asset-pipeline
deps: [PUL-072]
orca_task: null
unity_sources: []
owns: [art/blender/_materials_v2.blend, art/blender/_template.blend, godot/assets/materials/v2/**, godot/assets/textures/v2/**, docs/art/materials-v2.md, tools/blender_export.py, docs/evidence/PUL-074/**]
touches_scenes: []
---

## Target
Base común para que todos los assets v2 casen: materiales con textura pequeña y desgaste según la biblia v2.

## Change
1. `_materials_v2.blend` con los materiales de la biblia v2 (acero cepillado, metal pintado gastado, plástico rojo, madera usada, arpillera, tierra, lona, cobre si sigue, piel/tela de personaje…), con texturas pintadas/procedurales horneadas a resolución pequeña.
2. Plantilla `_template.blend` actualizada para enlazarlos; `tools/blender_export.py` exporta texturas embebidas o en `godot/assets/textures/v2/`.
3. `docs/art/materials-v2.md`: catálogo con muestra renderizada de cada material.

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
- [ ] AC1 Lámina con una esfera/cubo por material en Blender y en Godot (misma luz que PUL-073)
- [ ] AC2 Un asset de prueba exportado con dos materiales v2 importa sin errores
- [ ] Captura antes/después desde la cámara del nivel y render del `.blend`
- [ ] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
