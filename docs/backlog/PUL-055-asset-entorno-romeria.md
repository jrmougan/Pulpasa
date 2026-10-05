---
id: PUL-055
title: Modelar el entorno de romería
status: draft
milestone: M3
role: asset-pipeline
agent: claude + MCP de Blender (PUL-043)
deps: [PUL-042, PUL-043, PUL-041]
orca_task: null
unity_sources: []
owns: [art/blender/romeria.blend, godot/assets/models/environment/romeria/**, godot/entities/environment/environment.tscn, docs/evidence/PUL-055/**]
touches_scenes: [godot/entities/environment/environment.tscn]
---

## Target
D20: arte propio en Blender con un agente con MCP de Blender (pipeline de PUL-043), siguiendo la
biblia de arte (`docs/art/art-bible.md`, PUL-042).

## Change
1. Suelo (tierra/hierba/piedra), carpa o toldo de pulpería, bancos corridos, farolillos y banderines; decoración fuera de la zona jugable sin estorbar la cámara.
2. Fuente en `art/blender/romeria.blend`; export `.glb` en `godot/assets/models/environment/romeria/` con
   `tools/blender_export.py`.
3. Sustituir el placeholder en su escena (`Model`), sin cambiar colisiones ni nodos de contrato
   (`scene-tree.md` §3) salvo que se pida. Depende de la planta elegida (PUL-041).
4. Registrar la licencia (propia) en `docs/assets/licenses.md` → pedirlo al coordinador (fuera de `owns`).

## Ajustes de la biblia de arte (PUL-042)
Ajuste de la biblia (§4): dividir en 3 `.glb` (`ground`, `tent`, `decor`) dentro de `romeria/**`. Temática de la planta B: pulpeira de barra.

## Constraints
- Presupuesto de polígonos, escala, frente −Z y paleta de la biblia de arte.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Escala y frente correctos frente a `scale_check.tscn` → `test_assets_models.gd`
- [ ] AC2 Legible desde la cámara del nivel: captura en `docs/evidence/PUL-055/`
- [ ] AC3 `.blend` y `.glb` versionados; escena sin errores de import
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
