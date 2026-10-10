---
id: PUL-109
title: Test de caja errónea entregada en el tick de caducidad (D24)
status: ready
milestone: M3c
role: gameplay-engineer
deps: [PUL-108]
orca_task: null
unity_sources: []
owns: [godot/tests/unit/test_order_board.gd, docs/design/features/entrega-y-puntuacion.md, docs/evidence/PUL-109/**, docs/backlog/PUL-109-test-caja-erronea-tick-caducidad.md]
touches_scenes: []
---

## Target
`godot/tests/unit/test_order_board.gd` (hueco de cobertura de AC5d en `entrega-y-puntuacion.md`, D24).

## Change
`test_ac5b_delivery_on_expiry_tick_rejected_not_redirected` cubre la entrega en el tick de caducidad solo con caja válida. Añadir el caso con **caja errónea** con `wrong_delivery_penalty` > 0 en el `OrderBoard`: en el tick de caducidad se rechaza contra la caducada con penalización **0** (no `wrong_delivery_penalty`), la recaudación solo cambia por `expire_penalty` y no se emite `order_completed`. Control: un tick después, la misma caja errónea sí penaliza contra la repuesta. Actualizar el *Test:* de AC5d.

## Constraints
- Solo tests y documentación; no cambia `order_board.gd`. Si el código no cumple D24 con caja errónea, no se arregla aquí: se reporta con el test fallando y pasos.
- GDScript tipado. `tools/verify.sh` en verde.

## Acceptance
- [ ] AC1 Given una comanda que caduca en el tick T y una caja errónea entregada en T, When se procesa, Then `delivery_rejected(slot, id_caducada, 0)` y la recaudación no baja por `wrong_delivery_penalty` → test
- [ ] AC2 Given el tick T+1, When se entrega la misma caja errónea, Then se penaliza con `wrong_delivery_penalty` contra la repuesta → test
- [ ] AC3 AC5d de `entrega-y-puntuacion.md` cita el test nuevo

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
