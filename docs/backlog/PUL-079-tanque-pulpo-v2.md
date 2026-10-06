---
id: PUL-079
title: Convertir el arcón en tanque de pulpos
status: ready
milestone: M3b
role: asset-pipeline
deps: [PUL-072, PUL-074, PUL-076]
orca_task: null
unity_sources: []
owns: [art/blender/octopus_storage.blend, godot/assets/models/stations/octopus_storage/**, godot/entities/stations/octopus_storage.tscn, docs/evidence/PUL-079/**]
touches_scenes: [godot/entities/stations/octopus_storage.tscn]
---

## Target
Adaptar este asset a la estética elegida por el responsable (`docs/art/style-refs/referencia-elegida-2026-10-06.png`).

## Change
Tanque/acuario azul con agua, burbujas y pulpos dentro (lectura «de aquí sale el pulpo crudo»), mangueras; misma huella y acceso.

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
- [ ] AC1 Escala, frente y presupuesto de la biblia v2 → `test_assets_models.gd`
- [ ] AC2 Legible y coherente con la referencia junto a los assets v2 ya hechos
- [ ] Captura antes/después desde la cámara del nivel y render del `.blend`
- [ ] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
