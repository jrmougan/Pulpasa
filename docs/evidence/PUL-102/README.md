# PUL-102 · Evidencia: medición del rediseño de estaciones (M3c)

Rama de integración tras PUL-097..PUL-101. Referencia: `docs/evidence/PUL-090/` (`metrics.json`,
`measure_flow.gd`), `docs/design/rediseno-estaciones.md` (R15, R17) y D23.

## Ficheros
| Fichero | Qué es |
|---|---|
| `measure_flow.gd` + `run_measure.gd` | Adaptación de PUL-090 al flujo nuevo: estación al paso sin bandeja, caja en la mano, cortes 4/6/10, 6 pasaplatos 3+3, hueco a x 3,5 y entrega entrando en la zona (Z local 3,40). Mismo bot (teclado y detector reales, nunca `interact()`), mismas columnas, más `legs` (metros por tramo) y los escenarios `chain_seq` / `chain_pipe` de R17 |
| `metrics.json` | Un registro por escenario y variante de pasaplatos (`slots`): los 12 escenarios de PUL-090 en «oeste» (`PassSlot01` caja / `02` sobrante) y los 4 Solo también en «este» (`PassSlot04` / `05`); más `chain_seq` y `chain_pipe` en las dos variantes |
| `finding2_fill_rounding.gd` / `.log` | Hallazgo 2: redondeo de `fill_per_press` de la caja M |
| `ac1-cuenco-2-vs-4-raciones.png` | Hallazgo 1: recorte ×4 del cuenco con 2 y con 4 raciones (1280×720) |
| `ac3-individual-ticket-recortado-chevrones.png` | Partida Individual (MCP): ticket «Pulpo Individ…» recortado y chevrones de las zonas de entrega |
| `ac3-local2p-partida-corta.png` | Partida Local 2P (MCP): P1 con una caja, P2 con un pulpo, sin errores |

## Reproducir (desde la raíz; sin sonido)
```
godot --headless --audio-driver Dummy --path godot --import      # solo si no hay godot/.godot
timeout 300 godot --audio-driver Dummy --resolution 1920x1080 --fixed-fps 60 --path godot \
  -s "$PWD/docs/evidence/PUL-102/run_measure.gd" -- solo PassSlot04 PassSlot05
# partes: solo | switch | coop | chain | all ; par de pasaplatos opcional (caja, sobrante)
godot --headless --audio-driver Dummy --path godot -s "$PWD/docs/evidence/PUL-102/finding2_fill_rounding.gd"
```
Cada parte tarda 1–2 min (con ventana y `--fixed-fps 60`). Con pasaplatos se escribe
`metrics_<parte>_<caja>_<sobrante>.json`; `metrics.json` es la unión de las ocho ejecuciones
(solo, switch, coop y chain, en oeste y este). Los scripts no tocan `godot/`. Al salir, Godot avisa
de «ObjectDB instances leaked» y «resources still in use»: ocurre también al final de
`tools/verify.sh` y no viene de las mediciones.

## Cómo juega el bot (diferencias con PUL-090)
- **Pedido 1 (desde cero)**: rack → caja a un pasaplatos (lado de condimentar, z +1); nevera → olla →
  espera → pulpo cocido en la mano; corta la caja **en el pasaplatos** por el lado de pase (z −1); el
  sobrante se deja en otro pasaplatos; coge la caja del pasaplatos y la lleva en la mano a los
  dispensadores (ordenados por x) y entra en la zona de entrega del puesto con comanda.
- **Pedido 2**: igual con el pulpo sobrante. El cuenco da ahora 2 raciones por cachelo cocido: el
  pedido 2 con cachelos ya no vuelve a cocer.
- Individual, Individual con cambio y Coop usan el mismo protocolo de 2 pedidos que PUL-090 (comparable
  fila a fila). R17 pide 4 pedidos seguidos: `chain_seq` repite ese protocolo (los pares con el
  sobrante), `chain_pipe` juega el flujo adelantado del diseño (§4.2): dos cajas por delante en
  pasaplatos, dos pulpos al fuego a la vez, el cocinero conserva el sobrante en la mano y corta la caja
  N+1 mientras el emplatador condimenta la N. En `chain_pipe` el tiempo de un pedido es el intervalo
  desde la entrega anterior.
- La elección de pasaplatos cambia mucho el recorrido (ver R15): «oeste» = `PassSlot01/02` (junto al
  rack y a la nevera), «este» = `PassSlot04/05` (al este del hueco).

## Antes (PUL-090) → ahora (PUL-102)
Pedido 1 = desde cero, pedido 2 = con pulpo sobrante. P1 empieza en el servicio, P2 en la cocina; en
Solo solo se mueve P1. Todos los pedidos se completaron, con 0 rechazos de estación, 0 de entrega,
0 recolocaciones del detector y ningún aviso «objetivo no alcanzado» ni «la zona no entregó».

| Modo | Tipo | Pasaplatos | s ped.1 | s ped.2 | Pulsaciones ped.1 / ped.2 | m P1 ped.1 | m P1 ped.2 | m P2 ped.1 | Quieto P1 ped.1 (s) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| solo | S | 01/02 (oeste) | 23,3 → 22,55 | 13,77 → 13,53 | 14 → 13 / 11 → 10 | 78,9 → 74,4 | 58,6 → 57,3 | 0 → 0 | 7,32 → 7,55 |
| solo | M | 01/02 (oeste) | 23,65 → 22,73 | 14,05 → 13,8 | 19 → 15 / 16 → 12 | 78,9 → 74,7 | 58,4 → 58,1 | 0 → 0 | 7,67 → 7,68 |
| solo | L | 01/02 (oeste) | 24,28 → 23,07 | 14,65 → 14,23 | 29 → 19 / 26 → 16 | 78,9 → 75 | 58,1 → 58,9 | 0 → 0 | 8,32 → 7,95 |
| solo | S+cachelos | 01/02 (oeste) | 27,35 → 26,87 | 22,42 → 13,93 | 18 → 17 / 15 → 10 | 94,6 → 90,9 | 72,7 → 59,4 | 0 → 0 | 8,15 → 8,42 |
| switch | S | 01/02 (oeste) | 15,85 → 15,48 | 7,27 → 6,25 | 14 → 13 / 11 → 10 | 26,2 → 24,4 | 19,7 → 16,1 | 12,4 → 11,6 | 10,43 → 10,53 |
| switch | M | 01/02 (oeste) | 16,2 → 15,67 | 7,53 → 6,52 | 19 → 15 / 16 → 12 | 26,4 → 24,7 | 19,4 → 16,9 | 12,4 → 11,6 | 10,77 → 10,67 |
| switch | L | 01/02 (oeste) | 16,87 → 16 | 8,15 → 6,93 | 29 → 19 / 26 → 16 | 26,3 → 25 | 19,1 → 17,6 | 12,4 → 11,6 | 11,43 → 10,93 |
| switch | S+cachelos | 01/02 (oeste) | 20,13 → 19,78 | 16,33 → 6,65 | 18 → 17 / 15 → 10 | 30 → 26,4 | 23,2 → 18,1 | 25,5 → 26,1 | 14,03 → 14,43 |
| coop | S | 01/02 (oeste) | 10,52 → 11,52 | 6,08 → 5,07 | 14 → 13 / 11 → 10 | 26,2 → 24,4 | 19,7 → 16,1 | 12,4 → 11,6 | 5,1 → 6,57 |
| coop | M | 01/02 (oeste) | 10,88 → 11,65 | 6,35 → 5,33 | 19 → 15 / 16 → 12 | 26,4 → 24,7 | 19,4 → 16,9 | 12,4 → 11,6 | 5,45 → 6,65 |
| coop | L | 01/02 (oeste) | 11,53 → 11,92 | 6,97 → 5,75 | 29 → 19 / 26 → 16 | 26,3 → 25 | 19,1 → 17,6 | 12,4 → 11,6 | 6,1 → 6,85 |
| coop | S+cachelos | 01/02 (oeste) | 14,82 → 15,82 | 13,18 → 5,47 | 18 → 17 / 15 → 10 | 30 → 26,4 | 23,2 → 18,1 | 25,5 → 26,1 | 8,72 → 10,47 |
| solo | S | 04/05 (este) | 23,3 → 20,42 | 13,77 → 9,42 | 14 → 13 / 11 → 10 | 78,9 → 63,7 | 58,6 → 36,8 | 0 → 0 | 7,32 → 7,57 |
| solo | M | 04/05 (este) | 23,65 → 20,53 | 14,05 → 9,62 | 19 → 15 / 16 → 12 | 78,9 → 63,7 | 58,4 → 37,2 | 0 → 0 | 7,67 → 7,68 |
| solo | L | 04/05 (este) | 24,28 → 20,82 | 14,65 → 9,93 | 29 → 19 / 26 → 16 | 78,9 → 63,7 | 58,1 → 37,4 | 0 → 0 | 8,32 → 7,97 |
| solo | S+cachelos | 04/05 (este) | 27,35 → 24,23 | 22,42 → 9,42 | 18 → 17 / 15 → 10 | 94,6 → 77,9 | 72,7 → 36,8 | 0 → 0 | 8,15 → 8,38 |

Switch y Coop con pasaplatos este se midieron también (están en `metrics.json`) y son peores que oeste
(p. ej. switch S 17,5 / 7,8 s, coop S 11,7 / 6,7 s): no se tabulan.

Lectura:
- **Pulsaciones**: L 29 → 19 y M 19 → 15 (−10 y −4 cortes, como estimaba el diseño); S 14 → 13.
- **Cuenco con 2 raciones por cachelo**: pedido 2 con cachelos 22,4 → 13,9 s (Solo, oeste), 16,3 → 6,7 s
  (cambio) y 13,2 → 5,5 s (Coop).
- **Coop pedido 1 va más lento** que en PUL-090 (S 10,52 → 11,52 s; M, L y cachelos +0,4…+1,0 s) y el
  emplatador está más tiempo quieto (5,1 → 6,6 s). No se ha investigado la causa; dato para el playtest.
- **Coop pedido 2** con el protocolo de PUL-090: S 6,08 → 5,07 s (−17 %), M −16 %, L −18 %.

## R15 · Individual sin cambio, pedido S sal+aceite desde cero (≤ 50 m): NO CUMPLE
| Variante | PUL-090 | Ahora | R15 |
|---|---:|---:|---|
| Pasaplatos 01/02 (oeste, junto al rack) | 78,9 m | 74,4 m | no cumple |
| Pasaplatos 04/05 (este del hueco) | 78,9 m | 63,7 m | no cumple |
| Pedido 2 (sobrante), este | 58,6 m | 36,8 m | (referencia) |

Tramos del mejor caso (este; `legs` de `metrics.json`, metros): inicio → rack 9,7 · rack → `PassSlot04`
10,1 · `PassSlot04` → nevera (por el hueco) 12,8 · nevera → olla 3,1 · olla → `PassSlot04` lado cocina 6,9 ·
sobrante 1,1 · volver al servicio y coger la caja 6,3 · sal 4,5 · aceite 0,9 · ir a la zona ≈ 7,9 (resto
hasta 63,7). Sin los 9,7 m de salir de la posición inicial quedan 54,0 m: sigue por encima de 50. Los dos
tramos de ≈ 10 m entre el rack (oeste) y el hueco (este) y los dos cruces del hueco son estructurales en
Individual sin cambio; con los pasaplatos del oeste el rodeo hasta el hueco cuesta lo mismo en el sentido
contrario (74,4 m).

## R17 · Coop, 4 pedidos S sal+aceite seguidos (media de los pedidos 2–4 ≤ 4,6 s)
Referencia PUL-090: pedido 2 de Coop S = 6,08 s; 75 % = 4,56 s.

| Escenario | Pedidos 1 / 2 / 3 / 4 (s) | Media 2–4 | Pulsaciones | m P1 / P2 | R17 |
|---|---|---:|---:|---|---|
| `chain_pipe`, pasaplatos oeste 01-03 | 11,58 / 4,63 / 4,47 / 3,83 | **4,31 s** | 42 | 76,0 / 28,6 | cumple |
| `chain_pipe`, pasaplatos este 04-06 | 12,53 / 6,82 / 6,85 / 4,77 | 6,15 s | 42 | 129,7 / 40,1 | no cumple |
| `chain_seq`, oeste (protocolo de PUL-090 ×4) | 11,52 / 5,07 / 11,85 / 5,07 | 7,33 s | 46 | 72,8 / 28,4 | no cumple |
| `chain_seq`, este | 11,72 / 6,65 / 13,55 / 6,65 | 8,95 s | 46 | 104,6 / 40,3 | no cumple |

R17 se cumple solo con el bot que adelanta el trabajo y con los pasaplatos del oeste (junto al rack).
Con el protocolo secuencial el pedido 3 necesita un pulpo nuevo (5 s de cocción) y la media sube a 7,33 s.

## Hallazgos de revisión
1. **Cuenco con 2 y con 4 raciones**: confirmado (`ac1-cuenco-2-vs-4-raciones.png`). A 1280×720 son 2
   bloques amarillos frente a 4 apiñados en el mismo cuenco naranja; hay que mirar de cerca. Pasa al
   playtest.
2. **`fill_per_press` 0.16666667 de M**: no se reproduce con los datos actuales.
   `finding2_fill_rounding.gd` corta dos cajas con un pulpo de 100 con la `Box` y el `Ingredient` reales
   (`finding2_fill_rounding.log`): con 0.16666667 (y 0.1666667, 0.166666667) el pulpo se libera tras la
   2.ª caja (6 + 6 cortes, resto 0). **Sí falla si el valor se redondea a la baja**: 0.16666666 deja un
   resto de 0,000004, 0.1666666 de 0,00004 y 0.166666 de 0,0004, y el pulpo no se libera (`take` compara
   `remaining <= 0.0` sin épsilon) aunque la caja sale llena a los 6 cortes. 0.1666 y 0.16 dan 7 cortes
   por caja. Latente: corregir en PUL-104 (épsilon en `take`) antes de tocar el dato.
3. **`user://` compartido entre worktrees**: confirmado que hay una sola carpeta
   `%APPDATA%/Godot/app_userdata/Pulpasa` (el proyecto no define `custom_user_dir`) y que ningún script de
   `tools/`, `.claude/`, `CLAUDE.md` ni `docs/arch` mata procesos Godot por nombre. No se reproduce la
   caída sin matar procesos ajenos y no se ha intentado. Durante la ficha corrieron hasta 6 Godot en
   paralelo (mediciones) y un `tools/verify.sh` completo sin interferirse; solo se pararon PIDs propios.
4. **Ticket recortado**: confirmado (`ac3-individual-ticket-recortado-chevrones.png`): «Pulpo Individ…» a
   1280×720; «Pulpo Familiar» y «Pulpo Doble» caben. Decisión de playtest.

## Regresión y partidas
- `tools/verify.sh` completo: verde (gdformat, gdlint, import, GUT 69 scripts / 779 tests / 24139 asserts
  en 385 s, smoke).
- Partidas cortas con el MCP godot (menú → modo): Individual (mover, interactuar, cambio con `Q`) y Local
  2P (P1 coge una caja, P2 un pulpo): 0 errores en `get_debug_output`. Además, el bot ha jugado de
  extremo a extremo más de 60 pedidos en Individual, Individual con cambio y Coop sin errores.
