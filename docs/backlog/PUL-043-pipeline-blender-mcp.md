---
id: PUL-043
title: Preparar el MCP de Blender y el pipeline Blender → glTF → Godot
status: review
milestone: M2
role: asset-pipeline
deps: [PUL-042]
orca_task: null
unity_sources: []
owns: [art/README.md, godot/assets/models/_pipeline/**, art/blender/_template.blend, tools/blender_export.py, docs/art/pipeline.md, godot/tests/unit/test_assets_models.gd, godot/tests/unit/test_assets_models.gd.uid, docs/evidence/PUL-043/**, tools/blender_mcp.sh]
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
- [x] AC1 Pipeline documentado y reproducible desde la raíz
- [x] AC2 Plantilla y script de export funcionan en headless
- [x] AC3 Test de modelos en verde con el cubo de prueba

## Plan
1. Lanzador `tools/blender_mcp.sh start|stop|status` del Blender headless con el add-on MCP
   (puerto `$BLENDER_MCP_PORT`, estado fuera del repo) y comprobar las tools `mcp__blender__*`.
2. Crear `art/blender/_template.blend` vía MCP: unidades métricas (1 u = 1 m), colección `export`
   con raíz `asset` + `Anchor_Front` en +Y, colección `reference` (personaje 1,8 m, encimera 1 m) y
   los 32 materiales `mat_*` de la paleta §2.6 con hex exacto.
3. `tools/blender_export.py`: valida (colección, raíz única, escala/rotación aplicadas, sin
   cámaras/luces/sufijos de colisión, `Anchor_Front` delante, `--max-tris`) y exporta `.glb`
   (+Y Up, modificadores aplicados); siembra el `.glb.import` (root_scale 1, sin sufijos → sin
   colisiones, materiales embebidos). Modo `--smoke-cube` para el cubo de prueba.
4. `test_assets_models.gd` sobre `godot/assets/models/**` salvo `placeholders/`.
5. Exportar el cubo a `godot/assets/models/_pipeline/test_cube/` (ruta añadida a `owns` con
   aprobación del coordinador) y capturarlo junto a `scale_check` con una escena temporal sin versionar.
6. Documentar todo en `docs/art/pipeline.md` y `art/README.md`.

## Evidence
- MCP: `tools/blender_mcp.sh start` → «escuchando en 127.0.0.1:9876»; `mcp__blender__get_objects_summary`
  y `execute_blender_code` responden; la plantilla se construyó y guardó con ellas.
- AC2: `blender -b art/blender/_template.blend --python tools/blender_export.py -- --smoke-cube`
  → `blender_export: OK godot/assets/models/_pipeline/test_cube/test_cube.glb (3 objetos, 24 triángulos, 3 KiB)`.
  Caso negativo (escala 2 y `Anchor_Front` en −Y) → sale con 1 y lista ambos errores.
- Import: `godot --headless --import` conserva los `[params]` sembrados (root_scale 1,
  use_name_suffixes false, materials/extract 0) y añade uid.
- AC3: `test_assets_models.gd` 3/3 (28 asserts); `tools/verify.sh` verde (608/608 tests, smoke OK).
- Captura: [`docs/evidence/PUL-043/test_cube_scale_check.png`](../evidence/PUL-043/test_cube_scale_check.png):
  `scale_check.tscn` con dos cubos de prueba (madera clara) delante de la fila de placeholders; miden
  lo mismo que el `ScaleCube` morado de 1 m y la cápsula azul del personaje (1,8 m) les dobla en alto.
  El de la izquierda está sin rotar: su «nariz» roja (frente) queda oculta detrás (−Z, hacia el fondo);
  el de la derecha está girado 90° y la nariz asoma hacia −X, como corresponde.
- Avisos de Blender 5.2.2 de Fedora (OCIO 2.5 vs 2.4, sin Draco/MeshOptimizer) inocuos; anotados en
  `docs/art/pipeline.md` §1.
