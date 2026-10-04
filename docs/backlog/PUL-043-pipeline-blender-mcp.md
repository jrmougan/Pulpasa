---
id: PUL-043
title: Preparar el MCP de Blender y el pipeline Blender → glTF → Godot
status: draft
milestone: M2
role: asset-pipeline
deps: [PUL-042]
orca_task: null
unity_sources: []
owns: [art/README.md, art/blender/_template.blend, tools/blender_export.py, docs/art/pipeline.md, godot/tests/unit/test_assets_models.gd, godot/tests/unit/test_assets_models.gd.uid, docs/evidence/PUL-043/**]
touches_scenes: []
---

## Target
D20. Requisito de todas las fichas de asset (PUL-044..PUL-055).

## Change
1. Documentar en `docs/art/pipeline.md` qué MCP de Blender se usa (versión fijada), cómo se lanza
   junto al agente y qué tools expone. **Su alta en `.mcp.json` la aprueba el responsable** (gate
   humano: `.mcp.json` no está en `owns`).
2. `art/blender/_template.blend` con unidades, escala de referencia (personaje de 1,8 m) y colección
   de export; `tools/blender_export.py` para exportar `.glb` en headless (`blender -b`).
3. Ajustes de import en Godot (`.glb.import`): escala, generación de colisiones (no), materiales.
4. `test_assets_models.gd`: cada `.glb` de `godot/assets/models/**` (salvo placeholders) importa,
   tiene escala dentro de rango y frente −Z.
5. Prueba de humo: exportar un cubo de la plantilla y verlo en Godot.

## Constraints
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Pipeline documentado y reproducible desde la raíz
- [ ] AC2 Plantilla y script de export funcionan en headless
- [ ] AC3 Test de modelos en verde con el cubo de prueba

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
