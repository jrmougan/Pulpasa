---
id: PUL-113
title: Quitar los tamaños de caja (caja única de 6 cortes)
status: done
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
- El catálogo nuevo de 4 comandas y las bajas de recetas/comandas viejas (ADR-003 §10.4) son de PUL-114 (aliño), que va después: aquí las recetas viejas solo pierden `box`. La posición nueva de `BoxSpawner` en `box_shelf.tscn` (§10.1/scene-tree) sí es de esta ficha.
- `tools/verify.sh` en verde. Quita los tests que solo probaban tamaños (deja constancia en Evidence) y adapta el resto.

## Acceptance
- [x] AC1 Una sola `BoxData` (`box.tres`, 6 cortes); `test_data_boxes`/integridad lo comprueban
- [x] AC2 `OrderValidator` acepta cualquier caja con el contenido correcto → test
- [x] AC3 El rack da una sola caja → test de estanterías
- [x] AC4 El ticket no muestra talla y el nombre de la receta no se recorta → test de tickets y captura en `docs/evidence/PUL-113/`
- [x] AC5 Cortar 6 veces llena la caja (AC8/AC9 de `corte-pulpo.md`) → test
- [x] AC6 `tools/verify.sh` en verde

## Plan
- Datos: `data/boxes/box.tres` (nuevo, `presses_to_fill` 6, sin `short_label`/`icon`); bajas de `small/medium/large.tres`; `BoxData` sin `short_label` ni `icon`; `RecipeData` sin `box` (las tres recetas viejas lo pierden, también las de `tests/helpers/m0_data/recipes/`, que se rehacen sin `box` en vez de darlas de baja: es lo mas simple); `box.tscn`, `box_shelf.tscn` y el sandbox de condimentos apuntan a `box.tres`.
- Nucleo: `OrderValidator.matches` ya no compara la caja (`BoxContents.box` se conserva, no se valida).
- Escena: `box_shelf.tscn` con un solo `BoxSpawner` en (0, 0,31, -0,78), colision de 1,8 m sobre el frente y `%Highlightable.root` = `Model/box_shelf/OutlineHull`.
- UI: `ticket_entry` sin `_show_size`, `%SizeBadge`, `%SizeIcon`, `%SizeLabel`.
- Tests: AC1 `test_data_boxes.gd` (+ integridad, `boxes` min 1); AC2 `test_order_validator.gd::test_pul113_any_box_with_right_contents_matches`; AC3 `test_shelves.gd` (un spawner, da la caja unica, mano llena, interactuable, resaltado del mueble); AC4 `test_order_tickets.gd` (sin nodos de talla, nombre de 14 caracteres no recortado, ancho 212); AC5 `test_box.gd::test_pul113_ac5_single_box_fills_in_6_presses` y `test_box_on_slot.gd::test_pul113_box_on_table_fills_in_6_presses`.

## Evidence
- Captura del ticket sin talla y con el nombre completo (Pulpo Individual / Pulpo Familiar): `docs/evidence/PUL-113/tickets_sin_talla.png` (level_01, MCP godot).
- Tests dados de baja (solo probaban tallas): `test_box.gd` (small 4 / medium 6 / large 10 y `_assert_one_octopus_two_sizes` S+L), `test_box_on_slot.gd` (small/medium/large en mesa), `test_order_tickets.gd` (insignia de talla, letra de respaldo, ancho por talla, talla viva = caja de la receta), `test_data_boxes.gd` (AC2 etiqueta/icono, reescrito a caja unica), `test_validator` (caja equivocada/ausente -> ahora cualquier caja vale), `test_data_catalog.gd` (nombres de caja de las recetas), `test_shelves.gd` (3 spawners -> 1).
- Adaptados: `test_box_model.gd` (la caja unica usa la variante `medium` del .glb: `BoxModel` no cambia), `test_level_01_r16.gd` (`BoxShelf/BoxSpawner`), y todos los tests que usaban `recipe.box` / `small|medium|large.tres` pasan a `box.tres`.
- `tools/verify.sh` en verde: gdformat, gdlint, import, GUT 782/782 y smoke. `test_level_01.gd` y `test_audio_feedback.gd` (de PUL-112) se arreglaron aquí con cambios mínimos (`box.tres`, `BoxSpawner` único, 1 objetivo de caja en el test de distancias). `BoxModel` fija la variante única `VARIANT = &"medium"` (sin mapeo por nombre de fichero).
