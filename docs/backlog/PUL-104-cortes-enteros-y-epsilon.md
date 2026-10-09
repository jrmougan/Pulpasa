---
id: PUL-104
title: Contar cortes en enteros y agotar ingredientes con épsilon
status: ready
milestone: M3c
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/resources/box_data.gd, godot/data/boxes/**, godot/entities/items/box.gd, godot/entities/items/ingredient.gd, godot/tests/unit/test_data_boxes.gd, godot/tests/integration/test_box*.gd, godot/tests/**/test_ingredient*.gd, docs/evidence/PUL-104/**, docs/backlog/PUL-104-cortes-enteros-y-epsilon.md]
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
- [ ] AC1 Given cada talla, When se pulsa N veces (4/6/10), Then la caja está llena y no antes → test
- [ ] AC2 Given un pulpo y dos cajas M, When se llenan, Then el pulpo se agota y se libera aunque el llenado por corte tenga error de redondeo → test con un valor redondeado a la baja

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
