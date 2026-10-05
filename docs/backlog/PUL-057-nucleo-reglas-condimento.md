---
id: PUL-057
title: Implementar las reglas de condimento como núcleo
status: review
milestone: M2
role: gameplay-engineer
deps: [PUL-056, PUL-039]
orca_task: null
unity_sources: []
owns: [godot/core/seasoning_rules.gd, godot/core/seasoning_rules.gd.uid, godot/resources/seasoning_data.gd, godot/data/seasonings/*.tres, godot/resources/box_badge_style.gd, godot/resources/box_badge_style.gd.uid, godot/data/config/box_badges.tres, godot/entities/items/box.gd, godot/tests/unit/test_seasoning_rules.gd, godot/tests/unit/test_seasoning_rules.gd.uid, godot/tests/unit/test_data_*.gd, godot/tests/integration/test_box.gd, docs/evidence/PUL-057/**, godot/core/station_side.gd, godot/core/station_side.gd.uid, godot/tests/unit/test_station_side.gd, godot/tests/unit/test_station_side.gd.uid, godot/entities/items/box.tscn]
touches_scenes: [godot/entities/items/box.tscn]
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
- [x] AC1 Feature AC2–AC5 y AC13 (lógica) en `test_seasoning_rules.gd`
- [x] AC2 `Box.toggle_seasoning`/`remove_seasoning` con señales → `test_box.gd`
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `core/seasoning_rules.gd` (`SeasoningRules`, `RefCounted`, estático y puro): `enum Rejection`
  (ADR-003 §8.3), `toggle(current, seasoning, is_full, swap_exclusive) -> SeasoningRules.Toggle`
  (resultado: `rejection`, `removed`, `added`, `seasonings`), `remove(current, seasoning)`,
  `canonical_order(seasonings)` (inserción estable por `sort_order`).
- `core/station_side.gd` (`StationSide`): `enum Side`, `classify(point, pass_point, operator_point)`
  (ADR-003 §8.1). Test `test_station_side.gd`.
- `SeasoningData.sort_order: int` + valores en los cinco `.tres` (pimentón 0, sal 1, aceite 2,
  cachelos 3). Test en `test_data_integrity.gd` (y recuento de `.tres` 25 → 26).
- `resources/box_badge_style.gd` (`BoxBadgeStyle`: `badge_icon_px` 24, `badge_gap_px` 3,
  `badge_height` 0,35, `hot_mark` = `small-fire.svg`, `has_hot_mark(seasoning)`) +
  `data/config/box_badges.tres`. Test en `test_data_integrity.gd`.
- `Box`: `toggle_seasoning(seasoning, swap_exclusive) -> Rejection` y `remove_seasoning() -> bool`
  delegando en `SeasoningRules`; señal `seasoning_removed` (antes del `seasoned` del nuevo en el
  intercambio). Las ramas de bote y cachelos de `interact()` se quedan (las quita PUL-061).
  `box.tscn` entra en el grupo `box` (scene-tree §3, bandeja con `accepted_group = &"box"`).
- Tests: `test_seasoning_rules.gd` → feature AC2 (quitar), AC3 (repetir sobre el mismo condimento
  es la regla del toggle; el antirrebote temporal es de PUL-058), AC4 (intercambio y, con
  `swap_exclusive` = false, `EXCLUSIVE_TAKEN`), AC5 (`BOX_NOT_FULL` vacía o a 0,6), AC13 (orden
  canónico estable). `test_box.gd` → `toggle_seasoning`/`remove_seasoning` con `seasoned` /
  `seasoning_removed` y su orden.

## Evidence
- `tools/verify.sh` verde (547/547 tests, gdlint y gdformat limpios, smoke OK):
  `docs/evidence/PUL-057/verify.log`. `tools/check_owns.py` limpio contra
  `jrmougan/agentica-migracion-godot-alpha`.
- AC1 → `tests/unit/test_seasoning_rules.gd` (18 tests): `test_feature_ac2_*` (quitar),
  `test_feature_ac3_*` (alternar dos veces vuelve al inicio; el antirrebote temporal es de PUL-058),
  `test_feature_ac4_*` (intercambio en los dos sentidos, exactamente 1 del grupo `paprika`,
  `EXCLUSIVE_TAKEN` sin `paprika_swap`), `test_feature_ac5_*` (`BOX_NOT_FULL`),
  `test_feature_ac13_*` (picante → sal → aceite → cachelos, compacto y estable).
  `StationSide` (ADR-003 §8.1) → `tests/unit/test_station_side.gd`.
- AC2 → `tests/integration/test_box.gd` `test_pul057_*`: `seasoned`/`seasoning_removed` una vez
  cada una, `seasoning_removed` antes que `seasoned` en el intercambio, rechazo sin señales con caja
  vacía o a 0,6, `remove_seasoning`, caja en el grupo `box`.
- Datos: `sort_order` en los cinco `.tres` y `data/config/box_badges.tres` →
  `tests/unit/test_data_integrity.gd` `test_pul057_*`.
- Notas para las fichas siguientes: las ramas de bote y cachelos de `Box.interact()` siguen (las
  quita PUL-061). `BoxBadgeStyle.has_hot_mark()` decide la marca de llama (tipo `HOT_PAPRIKA`) para
  `BadgeRow` y el ticket. Revisión: `data/seasonings/oil.tres` pasa de `Color(0,0,0,0)` a
  `#F2C230` (art-bible §2.6) y `test_pul057_every_seasoning_color_is_opaque` exige color opaco en
  todo `SeasoningData`; `test_order_tickets.gd` no dependía del transparente.
