---
id: PUL-039
title: Reproducir y arreglar que no se pueda entregar en level_01
status: ready
milestone: M2
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand.tscn, godot/components/interaction_detector.gd, godot/components/interaction_component.gd, godot/core/interaction_scoring.gd, godot/entities/items/box.gd, godot/core/order_validator.gd, godot/tests/integration/test_delivery_e2e.gd, godot/tests/integration/test_delivery_e2e.gd.uid, godot/tests/integration/test_order_stand.gd, godot/tests/unit/test_interaction_scoring.gd, godot/tests/unit/test_order_validator.gd, docs/evidence/PUL-039/**]
touches_scenes: [godot/entities/stations/order_stand.tscn]
---

## Target
Bug del playtest de M2 (2026-10-05): el responsable **no logra entregar ningún pedido** en
`level_01` jugando. Los tests actuales (`test_m1_flow`, `test_m2_flow`) llaman a `interact()` o a
`OrderService.try_deliver` directamente y se saltan detector, física y zona de entrega.

## Change
1. **Reproducir primero** con el MCP (`run_project` + `simulate_input` con teclas reales; ver
   skill `godot-verify`): preparar una caja correcta de la comanda de un puesto y entregarla
   andando hasta el puesto y pulsando E, y también entrando en `%DeliveryZone`. Anotar en Evidence
   qué falla exactamente (detector que no elige el puesto, zona inalcanzable por colisión, puesto
   equivocado, validación que rechaza, caja no llena, etc.) con capturas.
2. Arreglar la causa raíz dentro de `owns`. Si es de diseño (p. ej. el jugador no puede saber a qué
   puesto va su comanda o por qué se rechaza), **pregunta al coordinador** antes de cambiar nada.
3. `test_delivery_e2e.gd`: entrega en el `level_01` real moviendo al personaje con input simulado
   y el detector real (sin llamar a `interact()` a mano), en verde.

## Constraints
- No cambiar firmas de `EventBus` ni D12 (cada comanda va a su puesto) sin gate.
- No editar `level_01.tscn`; si la causa es de colocación, pregunta al coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Causa raíz documentada con capturas en `docs/evidence/PUL-039/`
- [ ] AC2 Entrega correcta jugando con teclado en `level_01` (captura antes/después con recaudación)
- [ ] AC3 `test_delivery_e2e.gd` entrega en el nivel real con input simulado y detector real
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
