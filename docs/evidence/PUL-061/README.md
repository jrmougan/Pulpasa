# PUL-061 · Evidencia: level_01 con la planta B y la estación

## AC1 · Feature AC16–AC18 en el nivel real
`godot/tests/integration/test_station_level.gd` (teclado y detector reales, `level_walker.gd`):
- `test_ac16_single_pass_with_switch_completes_order_without_going_around`: A (cocina) deja la caja
  llena en la bandeja por el pase, Q, B pone sal y aceite y entrega; `order_completed` ×1 y ningún
  personaje cambia de lado de la barra.
- `test_ac17_single_character_going_around_the_counter_also_completes`: un solo personaje rodea la
  barra por el hueco de la col. 14 (ida y vuelta) y completa la comanda; el otro no se mueve.
- `test_ac18_no_spice_shelf_nor_jars_in_the_level` y
  `test_ac18_only_dispensers_and_bowl_change_a_box_seasoning` (barrido de todos los `interactable`
  del nivel con la mano vacía y con cachelos cocidos; solo dispensadores y cuenco cambian la caja).

## AC2 · Distancias de la planta B (±1 m)
`test_level_01.gd::test_ac2_planta_b_distances_match_pul041_within_one_metre`: Dijkstra (8 vecinos,
sin cortar esquinas) sobre las celdas de 0,2 m libres para la cápsula real del jugador, entre las
celdas de acceso de cada estación.

| Tramo | Medido | Planta B (`PUL-041/distancias.md`) |
|---|---:|---:|
| Cajas → pasaplatos | 1,2 | 1,0 |
| Nevera → olla | 3,2 | 3,0 |
| Cachelera → olla | 2,0 | 2,0 |
| Olla → pasaplatos | 2,4 | 2,0 |
| Pasaplatos → estación | 0,6 | 1,0 |
| Olla → estación (cachelos) | 2,0 | 2,0 |
| Estación → puestos 1/2/3/4 | 4,5 / 4,0 / 3,9 / 4,5 | 5 / 4 / 4 / 5 |
| Salida J2 → salida J1 | 17,6 | 18,2 |

La estación ocupa 4 celdas (cols 5–8) con el mismo centro, como fija scene-tree §2.

## AC3 · Partidas con el MCP a ritmo humano
Con `simulate_input` (teclas mantenidas, ~60 FPS; en modo background hubo que desactivar vsync en
caliente porque la ventana oculta iba a 1 FPS).
- **Individual** (cambio con Q): J1 deja la caja en PassSlot03, Q, el cocinero cuece, corta, suelta
  el sobrante en otro pasaplatos y pasa la caja a la bandeja por el pase, Q, J1 condimenta y
  entrega. La primera comanda (79 s de paciencia) caducó por lentitud; la caja se rehízo para la
  comanda #3 (quitar sal, poner aceite) y se entregó entrando en la zona: **+8 €**.
  `ac3-individual-01…04-*.png`.
- **Local 2P** (J1 WASD+E, J2 flechas+Intro, a la vez): caja mediana + aceite para la #2;
  **+17 €** en ~1 min. `ac3-local2p-01…02-*.png`.

## Hallazgo para PUL-063 (acordado con el coordinador)
Con una caja en la bandeja, desde el lado de condimentar el detector elige la **caja** (prioridad de
cogibles de `InteractionScoring`) al mirar de frente a **Sal** y **Pimentón picante**: la bandeja está
a 0,45 m en x de ellos y cae en el cono de 30°. Con la caja en la mano, desde el servicio la bandeja
pierde contra los dispensadores (captura `hallazgo-pul063-caja-en-mano-apunta-a-picante.png`). Un
pulpo en un pasaplatos vecino también roba el objetivo al deslizarse por la barra.
Sonda: `sonda-detector-dispensadores.txt` (posición final y objetivo para desplazamientos de 0–0,7 m,
z 1,0/1,3 y 2/4/8 frames de giro). Con 0,7 m hacia la bandeja y z = 1,0 funcionan los cuatro; los
tests usan `level_walker.gd::dispenser_stand` (`DISPENSER_SIDESTEP`) y dejan la caja por el pase.

## AC4
`tools/verify.sh` en verde (584 tests) y `tools/check_owns.py jrmougan/pul-061
jrmougan/agentica-migracion-godot-alpha` limpio.
