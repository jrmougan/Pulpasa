---
id: PUL-057
title: Implementar las reglas de condimento como núcleo
status: draft
milestone: M2
role: gameplay-engineer
deps: [PUL-056]
orca_task: null
unity_sources: []
owns: [godot/core/seasoning_rules.gd, godot/core/seasoning_rules.gd.uid, godot/resources/seasoning_data.gd, godot/data/seasonings/*.tres, godot/resources/box_badge_style.gd, godot/resources/box_badge_style.gd.uid, godot/data/config/box_badges.tres, godot/entities/items/box.gd, godot/tests/unit/test_seasoning_rules.gd, godot/tests/unit/test_seasoning_rules.gd.uid, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_box.gd, docs/evidence/PUL-057/**]
touches_scenes: []
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 2 de su tabla. Contratos de PUL-056.

## Change
1. `core/seasoning_rules.gd` (`RefCounted`, puro): alternar, intercambio de pimentón
   (`paprika_swap`), rechazo si la caja no está llena, orden canónico (`sort_order`).
2. `SeasoningData.sort_order` y valores en `data/seasonings/*.tres`.
3. `BoxBadgeStyle` (`resources/box_badge_style.gd` + `data/config/box_badges.tres`), para que
   PUL-059 y PUL-060 trabajen en paralelo.
4. `Box.toggle_seasoning()` / `remove_seasoning()` y señal `seasoning_removed`. **No quitar todavía**
   las rutas de bote y cachelos de `box.gd`: las retira PUL-061 junto con los tests de flujo.

## Constraints
- Datos en `.tres`. Capa común sin tipos 3D. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Feature AC2–AC5 y AC13 (lógica) en `test_seasoning_rules.gd`
- [ ] AC2 `Box.toggle_seasoning`/`remove_seasoning` con señales → `test_box.gd`
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
