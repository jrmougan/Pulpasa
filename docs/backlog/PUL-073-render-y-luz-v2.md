---
id: PUL-073
title: Ajustar luz, sombras y post-proceso a la estética de referencia
status: draft
milestone: M3b
role: asset-pipeline
deps: [PUL-072]
orca_task: null
unity_sources: []
owns: [godot/entities/environment/environment.tscn, godot/data/config/render*.tres, godot/assets/materials/env_*, godot/project.godot, docs/evidence/PUL-073/**]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
Iluminación y post-proceso de la referencia sobre el nivel actual: es la palanca más barata y se hace primero para que los modelos nuevos se juzguen con la luz final.

## Change
1. `WorldEnvironment`: luz ambiental más apagada, tonemapping filmic/AgX, ligero color grading cálido, SSAO, niebla suave de fondo si ayuda.
2. Luz principal cálida con sombras suaves; luces puntuales de bombillas sobre la zona jugable (sin reventar la lectura).
3. Profundidad de campo tilt-shift **opcional** (desactivada por defecto si resta legibilidad; dato en `.tres`).
4. Ajustes de calidad en `project.godot` documentados (sombras, MSAA/FXAA) con su coste.

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
- [ ] AC1 Capturas del mismo plano: actual vs v2 con y sin tilt-shift
- [ ] AC2 Ningún elemento jugable queda en sombra ilegible (pegatinas, números de puesto, aros)
- [ ] Captura antes/después desde la cámara del nivel y render del `.blend`
- [ ] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
