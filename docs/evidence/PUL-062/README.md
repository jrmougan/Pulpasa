# PUL-062 · Evidencia: QA de la estación y la planta B

## AC1 · Una partida completa por modo, ≥ 3 entregas, consola limpia
**MCP** (`godot-mcp-runtime`, ventana oculta, vsync desactivado en caliente; teclas mantenidas con
`simulate_input`, sin tocar estado: los `run_script` solo leen y conectan un grabador de señales).
Registro completo en `registro-partidas-mcp.txt`.

| Modo | Entregas | Recaudación final | Caducadas | Rechazos de la estación | Errores de consola |
|---|---:|---:|---:|---|---:|
| Individual (Q, cocinero en el pase y servidor en condimentar) | 3 (+8, +14, +12) | 22 € | 4 jugando + 2 al final | 1 (`HAND_BUSY`, picante con la caja en la mano) | 0 |
| Local 2P (J1 WASD+E servicio, J2 flechas+Intro cocina, a la vez) | 3 (+14, +8, +8) | 17 € | 1 jugando + 5 al final | 1 (`HAND_BUSY`, picante con la caja en la mano) | 0 |

Las dos partidas llegaron al game over (`individual-04-*`, `local2p-05-*`). Los únicos
`SCRIPT ERROR` del log son del primer script de grabación del QA (lambdas sin tipo), antes de jugar.
Las caducidades se deben al ritmo del MCP (cada orden tarda segundos en llegar), no son un fallo.

**GUT** `godot/tests/integration/test_m2b_flow.gd` (teclado y detector reales, `level_walker.gd`):
- `test_ac1_single_three_deliveries_through_the_pass_switching_characters`: nevera → olla, tres
  raciones de cachelos al cuenco por el pase, cortes sobre la caja de la bandeja, Q, dispensadores
  (pimentón intercambiado en la estación) y entrega; 3 comandas, ningún personaje cruza la barra.
- `test_ac1_coop_three_deliveries_cook_and_server_each_on_their_side`: lo mismo con J2 cocinando y
  J1 sirviendo.
- En los dos: `order_completed` ×3, sin `delivery_rejected`, sin `order_expired`, cero `rejected` de
  dispensadores y cuenco. Ritmo de referencia (bot sin errores): 7–10 s por comanda pequeña con pulpo
  cocido, 15–16 s si hay que cocer otro.

## AC2 · Guía de playtest y capturas
- Guía: `docs/design/m2b-gate.md`.
- Capturas: `individual-01…04-*.png`, `local2p-01…05-*.png` (cajas condimentadas en la bandeja con
  su ticket, entregas y game over) y `hallazgo-caja-en-mano-apunta-a-picante.png`.

## Hallazgo (reportado al coordinador, no se arregla en esta ficha)
Con una caja en la mano, en el lado de condimentar y desviado 0,2–0,4 m del centro de la bandeja
(x 0,12–0,21 o 0,70 frente al centro 0,5), el detector elige un dispensador (picante o sal) en vez de
la bandeja. Pulsar ahí da `HAND_BUSY`. Pasó en 5 de 6 veces que se dejó una caja desde el servicio;
solo funciona de primeras alineado con la bandeja (±0,05 m). PUL-063 cubre la posición frontal
exacta (`test_m2b_station_selection.gd`), no un desvío realista. Opción a valorar: que los
dispensadores no sean objetivo con algo en la mano (`SeasoningDispenser.is_reachable_from` recibe el
`Holder`), para que la bandeja gane siempre que se lleva una caja; choca con el AC8 de la feature
(rechazo audible con la mano ocupada), así que es decisión de diseño.

## AC3
`tools/verify.sh` en verde y `tools/check_owns.py jrmougan/pul-062
jrmougan/agentica-migracion-godot-alpha` limpio (ver ficha).
