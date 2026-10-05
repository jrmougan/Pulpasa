---
id: PUL-039
title: Reproducir y arreglar que no se pueda entregar en level_01
status: review
milestone: M2
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/entities/stations/order_stand.gd, godot/entities/stations/order_stand.tscn, godot/components/interaction_detector.gd, godot/components/interaction_component.gd, godot/core/interaction_scoring.gd, godot/entities/items/box.gd, godot/core/order_validator.gd, godot/tests/integration/test_delivery_e2e.gd, godot/tests/integration/test_delivery_e2e.gd.uid, godot/tests/integration/test_order_stand.gd, godot/tests/unit/test_interaction_scoring.gd, godot/tests/unit/test_order_validator.gd, godot/data/orders/order_1.tres, godot/data/orders/order_2.tres, godot/data/orders/order_3.tres, godot/data/orders/order_4.tres, godot/data/orders/order_5.tres, godot/data/orders/order_6.tres, godot/tests/unit/test_data_catalog.gd, godot/tests/unit/test_data_integrity.gd, docs/evidence/PUL-039/**]
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
- [x] AC1 Causa raíz documentada con capturas en `docs/evidence/PUL-039/`
- [x] AC2 Entrega correcta jugando con teclado en `level_01` (captura antes/después con recaudación)
- [x] AC3 `test_delivery_e2e.gd` entrega en el nivel real con input simulado y detector real
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Reproducir con MCP en `level_01` (teclas reales) y con un e2e headless que prepara la caja
   solo con teclado y el detector real.
2. Si la causa está en `owns` (detector, puesto, zona, validación, caja), arreglarla con test.
   Si es de diseño/balance, preguntar al coordinador antes de tocar nada.
3. `test_delivery_e2e.gd`: el `level_01` real, preparación completa con WASD/E, sin
   `interact()` ni `target_changed` a mano.
4. (2.ª ronda, decisión del coordinador) `max_time` ×2; la zona solo entrega la caja correcta de
   su puesto (comanda seguida por señales + `OrderValidator.matches`, sin método nuevo en
   `OrderService`); `Highlightable` en el puesto; e2e con la paciencia real, zona errónea y
   resaltado. Tests: `test_order_stand.gd` (zona errónea/otro puesto/caducada = nada, E rechaza,
   resaltado), `test_delivery_e2e.gd` (3 casos), `test_data_*` (rango 80–180 s).

## Evidence
Detalle, tablas y capturas: `docs/evidence/PUL-039/README.md`.

- **AC1 — causa raíz: balance de paciencia.** Detector, física, zona y validación funcionaban.
  La ruta óptima con teclado tardaba 33–54 s y `max_time` era 40–90 s; las 4 comandas iniciales
  salen a la vez y a ritmo humano caducaban todas: el puesto se reponía con otra receta y la caja
  correcta se rechazaba con penalización (doble con zona + E; también al cruzar la zona de un
  puesto vecino). Capturas `ac1-01`, `ac1-02`.
- **Arreglo (decisión del coordinador):** `max_time` ×2 (80–180 s, provisional hasta M4); la zona
  solo entrega una caja que coincide con la comanda viva de ese puesto y, si no, no hace nada
  (sin `delivery_rejected` ni penalización); E sigue rechazando con penalización (D8); el puesto
  se resalta con `Highlightable` y su propio material de contorno (el FBX tiene escalas de nodo
  ×60–×79 y el contorno compartido salía de metros).
- **AC2:** `ac2-03` → `ac2-04`: partida completa con teclas reales por MCP (sin preparar nada por
  script), comanda #3 (antes 40 s, ahora 80 s) entregada con ~4 s de margen, 0 → 8 €. 80 s queda
  justo para la receta más exigente: a revisar en el balance de M4. `ac3-resaltado-puesto-3`:
  solo el puesto apuntado se resalta.
- **AC3:** `test_delivery_e2e.gd` con la paciencia REAL: entrega con E (puesto resaltado, los
  demás no) y entrando en la zona, sin caducar la comanda; y caja errónea cruzando las cuatro zonas
  = nada, E = un rechazo. 6/6 ejecuciones en verde.
- **AC4:** `tools/verify.sh` verde (511/511); `check_owns` limpio.
