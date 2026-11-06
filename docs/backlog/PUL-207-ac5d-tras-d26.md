---
id: PUL-207
title: Decidir qué describe AC5d tras D26
status: ready
milestone: M4
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/entrega-y-puntuacion.md]
touches_scenes: []
---

## Target
AC5d de `docs/design/features/entrega-y-puntuacion.md:54`.

## Change
El cuerpo de AC5d sigue describiendo un rechazo por pulsación anterior a D26: «se emite `delivery_rejected(slot, id_de_la_caducada, 0)`». En el juego ya no se emite (`docs/arch/signals.md` §2): desde PUL-198 la zona espera al siguiente `advance` y la caja sigue en la mano. PUL-203 solo cambió su línea «Test:». **Decisión del responsable (2026-11-06):** AC5d describe lo que ve el jugador, no el núcleo. Reescribir su Given/When/Then: si la comanda caduca en el tick T y la caja entra en la zona antes del `advance` del tick siguiente, no hay rechazo ni `order_completed`, la caja sigue en la mano y la recaudación solo baja por `expire_penalty`; tras ese `advance`, la caja que coincide con la repuesta se entrega. El rechazo del núcleo (`OrderBoard`) queda en AC5b o en una nota, sin ser el criterio de AC5d.

## Constraints
Solo describe lo ya implementado (PUL-198) y decidido. No cambia valores ni `decisions.md` ni `docs/arch`. Si el comportamiento del juego no coincide con la frase nueva, status=blocked con la evidencia; no se cambia código en esta ficha.

## Acceptance
- [ ] AC1 Given el AC5d nuevo, When se contrasta con `godot/entities/stations/order_stand.gd` y con `test_pul198_entry_after_expiry_tick_before_advance_does_not_reject` y `test_pul198_entry_after_the_advance_delivers_replacement` (`godot/tests/integration/test_order_stand.gd`), Then cada afirmación coincide → tabla en docs/evidence/PUL-207/
- [ ] AC2 Given `entrega-y-puntuacion.md`, When se busca `delivery_rejected` en AC5d, Then solo aparece como comportamiento del núcleo, no como criterio del jugador → salida en docs/evidence/PUL-207/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
