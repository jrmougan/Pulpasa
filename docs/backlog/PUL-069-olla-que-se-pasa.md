---
id: PUL-069
title: Quemar el pulpo que se deja en la olla y encender sus efectos
status: draft
milestone: M3
role: gameplay-engineer
deps: [PUL-066]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/cooking_station.gd, godot/entities/stations/kitchen.tscn, godot/entities/items/ingredient.gd, godot/resources/ingredient_data.gd, godot/resources/kitchen_data.gd, godot/data/config/kitchen.tres, godot/data/ingredients/*.tres, godot/assets/models/food/**, art/blender/octopus.blend, art/blender/cachelos.blend, godot/tests/integration/test_cooking_station.gd, godot/tests/integration/test_octopus.gd, godot/tests/integration/test_burn.gd, godot/tests/integration/test_burn.gd.uid, docs/evidence/PUL-069/**]
touches_scenes: [godot/entities/stations/kitchen.tscn]
---

## Target
`features/olla-que-se-pasa.md` (AC1–AC4) con los contratos de PUL-066. Absorbe PUL-065 (fuego y
vapor solo al cocinar).

## Change
Quemado tras `burn_time` con aviso visual desde `warn_time` (parpadeo de la barra), estado `BURNT`
con malla `*_burnt` (modelado con el MCP de Blender en los `.blend` de pulpo/cachelos, estilo
aprobado) y rechazo al cortarlo; desechable para liberar la plaza (define dónde, p. ej. al
interactuar con la olla con la mano vacía o un cubo). Vapor solo con plazas cociendo y fuego vivo
al cocer; se congela en pausa.

## Constraints
- Datos en `.tres`. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1–AC4 de la feature → `test_burn.gd`
- [ ] AC5 Vapor/fuego según estado y congelados en pausa → test
- [ ] AC6 Capturas cocido, aviso y quemado en `docs/evidence/PUL-069/`
- [ ] AC7 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
