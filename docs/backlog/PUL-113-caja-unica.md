---
id: PUL-113
title: Quitar los tamaños de caja (caja única de 6 cortes)
status: in_progress
milestone: M3d
role: gameplay-engineer
deps: [PUL-110, PUL-111]
orca_task: null
unity_sources: []
owns: [godot/resources/box_data.gd, godot/resources/recipe_data.gd, godot/resources/order_data.gd, godot/resources/ingredient_data.gd, godot/core/order_validator.gd, godot/data/boxes/**, godot/data/recipes/**, godot/data/orders/**, godot/data/config/box_badges.tres, godot/entities/items/**, godot/entities/stations/box_shelf.tscn, godot/entities/stations/sandbox/seasoning_station_sandbox.tscn, godot/entities/stations/sandbox/stations_sandbox.tscn, godot/scenes/sandbox/**, godot/ui/tickets/**, godot/tests/**, docs/design/features/corte-pulpo.md, docs/evidence/PUL-113/**, docs/backlog/PUL-113-caja-unica.md]
touches_scenes: [godot/entities/stations/box_shelf.tscn, godot/ui/tickets/ticket_entry.tscn, godot/entities/items/box.tscn]
---

## Target
Parte «caja única» de D25 con el contrato de ADR-003 §10 (PUL-111): `RecipeData.box` retirado, `OrderValidator` sin comparar caja, una `BoxData` en `data/boxes/box.tres` (`presses_to_fill` = 6), bajas de `small/medium/large.tres`, `BoxData.short_label` e `icon`, rack de un solo spawner, ticket sin talla (`_show_size`, `%SizeBadge`, `%SizeIcon`, `%SizeLabel`).

## Change
Implementar exactamente esa parte del contrato y adaptar los tests. **No** cambia todavía condimentos ni el catálogo de recetas (eso es PUL-114, después): las recetas actuales siguen existiendo sin `box`, y las comandas actuales siguen igual.

## Constraints
- Contratos de PUL-111 tal cual; si algo no encaja, para y pregunta al coordinador.
- `.uid` versionados; no inventes `uid://`; al borrar un recurso borra su `.uid` si lo tiene.
- En paralelo PUL-112 (cubo) es dueño de `level_01.tscn`, `test_level_01.gd`, `test_audio_feedback.gd` y `feedback_map.tres`: no los toques salvo que un test no compile; en ese caso avisa al coordinador antes.
- `tools/verify.sh` en verde. Quita los tests que solo probaban tamaños (deja constancia en Evidence) y adapta el resto.

## Acceptance
- [ ] AC1 Una sola `BoxData` (`box.tres`, 6 cortes); `test_data_boxes`/integridad lo comprueban
- [ ] AC2 `OrderValidator` acepta cualquier caja con el contenido correcto → test
- [ ] AC3 El rack da una sola caja → test de estanterías
- [ ] AC4 El ticket no muestra talla y el nombre de la receta no se recorta → test de tickets y captura en `docs/evidence/PUL-113/`
- [ ] AC5 Cortar 6 veces llena la caja (AC8/AC9 de `corte-pulpo.md`) → test
- [ ] AC6 `tools/verify.sh` en verde

## Plan

## Evidence
