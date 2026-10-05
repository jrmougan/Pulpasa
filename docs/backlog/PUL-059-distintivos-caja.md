---
id: PUL-059
title: Mostrar los distintivos de condimento sobre la caja
status: draft
milestone: M2
role: gameplay-engineer
deps: [PUL-057]
orca_task: null
unity_sources: []
owns: [godot/entities/items/box.tscn, godot/entities/items/badge_row.gd, godot/entities/items/badge_row.gd.uid, godot/tests/integration/test_box_badges.gd, godot/tests/integration/test_box_badges.gd.uid, docs/evidence/PUL-059/**]
touches_scenes: [godot/entities/items/box.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 4 (sección «Distintivos»).

## Change
`BadgeRow` en `box.tscn`: fila flotante en billboard sin test de profundidad, pegatinas con
`SeasoningData.color` + `icon`, marca de llama en el picante, orden canónico, tamaño de
`BoxBadgeStyle`. Escucha `seasoned` / `seasoning_removed` de la caja.

## Constraints
- No editar `box.gd` (PUL-057). Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Feature AC13 (orden y llama) → `test_box_badges.gd`
- [ ] AC2 Feature AC15: captura a 1280×720 con pegatinas ≥ 22 px en `docs/evidence/PUL-059/`
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
