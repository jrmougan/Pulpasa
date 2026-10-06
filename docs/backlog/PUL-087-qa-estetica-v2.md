---
id: PUL-087
title: Pasar el QA visual y de rendimiento de la estética v2
status: draft
milestone: M3b
role: qa-tester
deps: [PUL-073, PUL-075, PUL-076, PUL-077, PUL-078, PUL-079, PUL-080, PUL-081, PUL-082, PUL-083, PUL-084, PUL-085, PUL-086]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-087/**, docs/design/m3b-gate.md, docs/art/style-refs/**]
touches_scenes: []
---

## Target
Cierre de la estética v2 frente a la referencia (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Capturas del mismo plano que `docs/art/style-refs/actual-2026-10-06/` (con `capture_style_refs.gd`) junto a la referencia; partida completa por modo con el MCP; medición de FPS y tiempo de frame a 1080p; lista de desajustes por asset; guía de revisión para el responsable (`m3b-gate.md`).

Notas de PUL-073: la energía del sol (1,34) la fija `test_level_01`; `scene-tree.md` no recoge aún los nodos `Bulbs` y `Vignette` de `environment.tscn` (pedir enmienda al arquitecto); costes de rendimiento estimados a medir aquí. Si el ambiente queda lejos de la referencia, proponer ajuste de `render_config.tres`.

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
- [ ] AC1 Comparativa referencia / antes / después
- [ ] AC2 60 fps a 1080p o lista de lo que lo impide
- [ ] AC3 Partidas sin errores en consola
- [ ] Captura antes/después desde la cámara del nivel y render del `.blend`
- [ ] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
