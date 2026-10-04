---
id: PUL-039
title: Reproducir y arreglar que no se pueda entregar en level_01
status: review
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
- [x] AC1 Causa raíz documentada con capturas en `docs/evidence/PUL-039/`
- [x] AC2 Entrega correcta jugando con teclado en `level_01` (captura antes/después con recaudación)
- [x] AC3 `test_delivery_e2e.gd` entrega en el nivel real con input simulado y detector real
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Reproducir con MCP en `level_01` (teclas reales) y con un e2e headless que prepara la caja
   solo con teclado y el detector real.
2. Si la causa está en `owns` (detector, puesto, zona, validación, caja), arreglarla con test.
   Si es de diseño/balance, preguntar al coordinador antes de tocar nada.
3. `test_delivery_e2e.gd`: dos casos en el `level_01` real (E delante del puesto; entrar en
   `%DeliveryZone`), preparación completa con WASD/E, sin `interact()` ni `target_changed` a mano.

## Evidence
Detalle, tabla de tiempos y capturas: `docs/evidence/PUL-039/README.md`.

- **AC1 — causa raíz: balance de paciencia, no código.** Detector, física, zona y validación
  funcionan (MCP: entrega por zona 0 → 18 € y con E 0 → 8 €). La preparación con teclado por la
  ruta óptima de un bot tarda 33–54 s desde la primera comanda, y `max_time` del catálogo es de
  40–90 s (order_2 = 40 s, order_6 = 50 s). Las 4 comandas iniciales salen a la vez: a ritmo
  humano todas caducan antes de la primera entrega, el puesto se repone con otra receta y la caja
  correcta se rechaza (`delivery_rejected` + penalización D8). El e2e con la paciencia real fallaba
  de forma intermitente por esto (caja con `OrderValidator.matches` = true contra la comanda
  elegida, rechazada tras caducar). Capturas `ac1-01`, `ac1-02` (la #2 caduca a los 40 s y la
  sustituye la #5; 0 €).
- Secundarios (no bloquean): cruzar la zona de un puesto vecino con la caja la rechaza y
  penaliza; zona + E penalizan dos veces; el puesto no tiene `Highlightable`; E alcanza el puesto
  desde ~2,0–2,2 m y la zona empieza a ~2,0 m.
- **Sin cambio de código de juego:** el arreglo es de datos (`data/orders/order_*.tres`,
  `round_config.tres`, fuera de `owns`) y de diseño (zona solo con caja correcta, resaltado del
  puesto). Preguntado al coordinador (msg_500b3be1b1ca) sin respuesta tras más de 1 h; queda
  para su decisión.
- **AC2:** `ac2-01` (caja de la #1 delante del puesto 1, 0 €) → `ac2-02` (E, 8 €). Recorrido y E
  con teclas reales por MCP; la caja se montó con `run_script` (la preparación con teclado está
  cubierta por el e2e).
- **AC3:** `test_delivery_e2e.gd`, 2 tests, 6/6 ejecuciones en verde. Prepara la caja de la
  comanda con más condimentos solo con WASD/E (estantería, nevera, olla, cortes, condimentos o
  cachelos cocidos) y entrega con E delante del puesto y entrando en `%DeliveryZone`. Reinicia la
  ronda con una copia del catálogo real con `max_time = 0` para probar la entrega y no el balance.
- **AC4:** `tools/verify.sh` verde (506/506); `check_owns` limpio.
