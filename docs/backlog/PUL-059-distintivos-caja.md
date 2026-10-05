---
id: PUL-059
title: Mostrar los distintivos de condimento sobre la caja
status: done
milestone: M2
role: gameplay-engineer
deps: [PUL-057]
orca_task: task_29e1047a4d55
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
- [x] AC1 Feature AC13 (orden y llama) → `test_box_badges.gd`
- [x] AC2 Feature AC15: captura a 1280×720 con pegatinas ≥ 22 px en `docs/evidence/PUL-059/`
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `badge_row.gd` (`BadgeRow`, Node3D `top_level`): hijos `Sprite3D` billboard sin test de profundidad (disco + icono + llama), tamaño en px de `BoxBadgeStyle` convertido a metros con la cámara ortográfica (fallback 12,74 m / 720 px); orden `SeasoningRules.canonical_order`.
- `box.tscn`: nodo `%BadgeRow`. Sin tocar `box.gd`.
- AC1 → `test_box_badges.gd`; AC2 → captura con script temporal; AC3 → verify + check_owns.

## Evidence
- `docs/evidence/PUL-059/box_badges_1280x720.png`: 1280×720, caja con 4 condimentos (picante con llama → sal → aceite → cachelos) y otra con 2; pegatinas de 24 px (≥ 22). Captura hecha con la caja suelta, sin personaje ni mostrador; la caja en mano usa la misma fila (top_level, sin depth test).
- `tools/verify.sh` verde (GUT 553/553 en la pasada previa; gdformat corregido después).

### Revisión del coordinador
- `BadgeRow._follow` proyecta las 8 esquinas de la colisión de la caja y sube la fila por el eje «arriba» de la cámara hasta dejar ≥ 8 px (mínimo exigido 6) entre su borde inferior y lo más alto de la caja; vale en mesa, en mano y con la caja grande.
- La llama (0,34 × lado, centrada a 0,2 × lado) queda dentro del disco.
- La fila se rehace al cambiar `size_changed` del viewport, o el tamaño/orientación de la cámara.
- Captura nueva `docs/evidence/PUL-059/box_badges_1280x720.png` (sandbox de items): caja pequeña sobre mesa, mediana en la mano del personaje y grande en el suelo, las tres con 4 condimentos; huecos medidos 8,0 / 8,0 / 9,1 px. La caja en mano queda tapada por el propio personaje en esa vista, pero la fila se ve entera.
- Tests nuevos: hueco ≥ 6 px (`unproject_position`) a dos alturas y recálculo al cambiar `camera.size`.
