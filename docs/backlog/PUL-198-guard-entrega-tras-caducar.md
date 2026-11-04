---
id: PUL-198
title: Evitar delivery_rejected en el tick posterior a la caducidad de una comanda
status: ready
milestone: M4
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/tests/integration/test_order_stand.gd]
touches_scenes: []
---

## Target
`godot/entities/stations/order_stand.gd` y su test de integración.

## Change
Decisión del responsable en el gate de enmiendas (G22, G51). Una caja que entra en el tick posterior a la caducidad y coincide con la repuesta hace que el puesto llame a `try_deliver`, y el núcleo emite `delivery_rejected` con `penalty` 0. `signals.md` dice «sin emisión en el juego». Se extiende la protección del guard (`order_stand.gd:156`) hasta el siguiente `advance`. Reproducción: `docs/evidence/PUL-196/repro-entrega.txt`.

## Constraints
No toca el núcleo: `try_deliver`, D24, ADR-002 y los tests de `OrderBoard` quedan igual. Un simple «tick + 1» puede chocar con `test_order_stand.gd:272`: compruébalo.

## Acceptance
- [ ] AC1 Given una comanda que caduca, When una caja real entra por física en el tick siguiente antes de su `advance`, Then no se emite `delivery_rejected` → test en test_order_stand.gd
- [ ] AC2 Given el tick siguiente tras ese `advance`, When entra la caja que coincide con la repuesta, Then se entrega → test en test_order_stand.gd
- [ ] AC3 Given la suite, When `tools/verify.sh`, Then verde → salida en docs/evidence/PUL-198/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
