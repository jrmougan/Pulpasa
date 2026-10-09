---
id: PUL-104
title: Contar cortes en enteros y agotar ingredientes con épsilon
status: review
milestone: M3c
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/resources/box_data.gd, godot/data/boxes/**, godot/entities/items/box.gd, godot/entities/items/ingredient.gd, godot/resources/ingredient_data.gd, godot/tests/unit/test_data_boxes.gd, godot/tests/integration/test_box*.gd, godot/tests/**/test_ingredient*.gd*, docs/evidence/PUL-104/**, docs/backlog/PUL-104-cortes-enteros-y-epsilon.md]
touches_scenes: []
---

## Target
`BoxData`, `Box`, `Ingredient` (hallazgo de la revisión de PUL-098).

## Change
Hoy la talla M tiene `fill_per_press = 0.16666667` y funciona porque redondea hacia arriba. Si alguien la escribe redondeando hacia abajo, dos cajas dejan el pulpo con ~1e-5 y no se libera, porque `Ingredient.take` compara `remaining <= 0.0` sin épsilon. Guardar `presses_to_fill: int` en `BoxData` (4/6/10 en los `.tres`) y derivar el llenado como `1.0 / presses_to_fill`, o gastar `(fill_nuevo - fill_anterior) * amount_per_full_box`; y añadir un épsilon a la comprobación de agotado.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`.
- El comportamiento visible no cambia: 4/6/10 pulsaciones y un pulpo = 2 cajas.

## Acceptance
- [x] AC1 Given cada talla, When se pulsa N veces (4/6/10), Then la caja está llena y no antes → test
- [x] AC2 Given un pulpo y dos cajas M, When se llenan, Then el pulpo se agota y se libera aunque el llenado por corte tenga error de redondeo → test con un valor redondeado a la baja

## Plan
Ficheros: `resources/box_data.gd` (+`presses_to_fill: int`, +`fill_after(presses)`, se quita `fill_per_press`), `data/boxes/*.tres` (4/6/10), `entities/items/box.gd` (cuenta `_presses`, llenado = `fill_after`, gasto = diferencia de llenado x `amount_per_full_box`; sin `FULL_EPSILON`), `entities/items/ingredient.gd` (`EMPTY_EPSILON = 0.001` en `take`). Sin señales nuevas.
Tests: AC1 `tests/unit/test_data_boxes.gd` (4/6/10, llena exacto y no antes) y `tests/integration/test_box.gd` (pulsaciones por talla). AC2 `tests/unit/test_ingredient_epsilon.gd` (12 cortes con 0.1666666, redondeado a la baja, agotan y liberan) y `test_box.gd` (dos cajas M gastan 100 exactos y liberan).

## Evidence
- `tools/verify.sh` completo en verde (gdformat, gdlint, import, GUT 783 tests, smoke).
- `fill_per_press` eliminado. Usos no tocados (fuera de `owns`): `docs/evidence/PUL-090/measure_flow.gd`, `docs/evidence/PUL-102/{measure_flow,finding2_fill_rounding}.gd` (scripts de evidencia historicos, ya no ejecutables) y docs de diseno/arch/backlog.
- `ingredient_data.gd` incorporado a `owns`: comentario de `amount_per_full_box` actualizado a `presses_to_fill`. Los scripts de evidencia historicos (`docs/evidence/PUL-090`, `PUL-102`) y los docs de contratos/diseno siguen nombrando `fill_per_press`; se actualizaran en otra ficha.
- Revision: `.uid` cubierto por `owns` (`test_ingredient*.gd*`); `Box._cut` resincroniza `_presses` desde `fill`; `presses_to_fill` con `@export_range(1, 20)`; test de mezcla S+L en `test_box.gd`.
