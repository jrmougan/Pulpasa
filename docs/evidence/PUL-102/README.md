# PUL-102 · Evidencia: medición del rediseño de estaciones (M3c)

Rama de integración tras PUL-097..PUL-101. Referencia: `docs/evidence/PUL-090/` (`metrics.json`,
`measure_flow.gd`), `docs/design/rediseno-estaciones.md` (R15, R17) y D23.

## Ficheros
| Fichero | Qué es |
|---|---|
| `measure_flow.gd` + `run_measure.gd` | Adaptación de PUL-090 al flujo nuevo: estación al paso sin bandeja, caja en la mano, cortes 4/6/10, 6 pasaplatos 3+3, hueco a x 3,5 y entrega entrando en la zona (Z local 3,40). Mismo bot (teclado y detector reales, nunca `interact()`), mismas columnas, más `legs` (metros por tramo) y los escenarios `chain_seq` / `chain_pipe` de R17 |
| `metrics.json` | Un registro por escenario y variante, con el campo `slots` (`caja/sobrante`; `floor` y `floorgap` = caja en el suelo): los 12 escenarios de PUL-090 con `PassSlot01/02`; Solo también con `PassSlot04/05`, `PassSlot03/02`, `floor` y `floorgap`; Switch y Coop también con `PassSlot04/05`; `chain_seq` y `chain_pipe` con 01/02 y 04/05. Es la unión de las salidas por parte |
| `finding2_fill_rounding.gd` / `.log` | Hallazgo 2: redondeo de `fill_per_press` de la caja M |
| `ac1-cuenco-2-vs-4-raciones.png` | Hallazgo 1: recorte ×4 del cuenco con 2 y con 4 raciones (1280×720) |
| `ac3-individual-ticket-recortado-chevrones.png` | Partida Individual (MCP): ticket «Pulpo Individ…» recortado y chevrones de las zonas de entrega |
| `ac3-local2p-partida-corta.png` | Partida Local 2P (MCP): P1 con una caja, P2 con un pulpo, sin errores |

## Reproducir (desde la raíz; sin sonido)
```
godot --headless --audio-driver Dummy --path godot --import      # solo si no hay godot/.godot
timeout 300 godot --audio-driver Dummy --resolution 1920x1080 --fixed-fps 60 --path godot \
  -s "$PWD/docs/evidence/PUL-102/run_measure.gd" -- solo PassSlot04 PassSlot05
# partes: solo | switch | coop | chain | all ; después caja y sobrante: PassSlot0N, floor o floorgap
godot --headless --audio-driver Dummy --path godot -s "$PWD/docs/evidence/PUL-102/finding2_fill_rounding.gd"
```
Cada parte tarda 1–2 min (con ventana y `--fixed-fps 60`). Con pasaplatos se escribe
`metrics_<parte>_<caja>_<sobrante>.json`; `metrics.json` es la unión de esas salidas
(cada registro lleva `slots`). Los scripts no tocan `godot/`. Al salir, Godot avisa
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
Solo solo se mueve P1. Todos los pedidos se completaron, con 0 rechazos de estación, 0 de entrega y
ningún aviso «la zona no entregó» (en la tabla, Switch y Coop con pasaplatos 01/02; Solo con la
caja en el pasaplatos 01/02 y en el suelo). Las demás variantes, en `metrics.json`.

| Modo | Tipo | Caja en | s ped.1 | s ped.2 | Pulsaciones ped.1 / ped.2 | m P1 ped.1 | m P1 ped.2 | m P2 ped.1 | Quieto P1 ped.1 (s) |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| coop | S | 01/02 oeste | 10,52 → 11,2 | 6,08 → 4,85 | 14 → 13 / 11 → 10 | 26,2 → 23,3 | 19,7 → 15,6 | 12,4 → 11,6 | 5,1 → 6,47 |
| coop | M | 01/02 oeste | 10,88 → 11,33 | 6,35 → 5,12 | 19 → 15 / 16 → 12 | 26,4 → 23,7 | 19,4 → 16,3 | 12,4 → 11,6 | 5,45 → 6,55 |
| coop | L | 01/02 oeste | 11,53 → 11,6 | 6,97 → 5,53 | 29 → 19 / 26 → 16 | 26,3 → 23,9 | 19,1 → 17 | 12,4 → 11,6 | 6,1 → 6,75 |
| coop | S+cachelos | 01/02 oeste | 14,82 → 15,5 | 13,18 → 5,25 | 18 → 17 / 15 → 10 | 30 → 25,3 | 23,2 → 17,6 | 25,5 → 26,1 | 8,72 → 10,37 |
| solo | S | 01/02 oeste | 23,3 → 22,23 | 13,77 → 13,32 | 14 → 13 / 11 → 10 | 78,9 → 73,3 | 58,6 → 56,7 | 0 → 0 | 7,32 → 7,45 |
| solo | M | 01/02 oeste | 23,65 → 22,42 | 14,05 → 13,58 | 19 → 15 / 16 → 12 | 78,9 → 73,6 | 58,4 → 57,5 | 0 → 0 | 7,67 → 7,58 |
| solo | L | 01/02 oeste | 24,28 → 22,75 | 14,65 → 14,02 | 29 → 19 / 26 → 16 | 78,9 → 73,9 | 58,1 → 58,3 | 0 → 0 | 8,32 → 7,85 |
| solo | S+cachelos | 01/02 oeste | 27,35 → 26,55 | 22,42 → 13,72 | 18 → 17 / 15 → 10 | 94,6 → 89,8 | 72,7 → 58,8 | 0 → 0 | 8,15 → 8,32 |
| solo | S | 03/02 oeste | 23,3 → 20,92 | 13,77 → 11,98 | 14 → 13 / 11 → 10 | 78,9 → 66,7 | 58,6 → 50 | 0 → 0 | 7,32 → 7,47 |
| solo | M | 03/02 oeste | 23,65 → 21,03 | 14,05 → 12,17 | 19 → 15 / 16 → 12 | 78,9 → 66,6 | 58,4 → 50,4 | 0 → 0 | 7,67 → 7,6 |
| solo | L | 03/02 oeste | 24,28 → 21,38 | 14,65 → 12,55 | 29 → 19 / 26 → 16 | 78,9 → 67,1 | 58,1 → 51 | 0 → 0 | 8,32 → 7,87 |
| solo | S+cachelos | 03/02 oeste | 27,35 → 25,22 | 22,42 → 12,38 | 18 → 17 / 15 → 10 | 94,6 → 83,2 | 72,7 → 52,1 | 0 → 0 | 8,15 → 8,3 |
| solo | S | 04/05 este | 23,3 → 19,77 | 13,77 → 8,82 | 14 → 13 / 11 → 10 | 78,9 → 61 | 58,6 → 34,3 | 0 → 0 | 7,32 → 7,47 |
| solo | M | 04/05 este | 23,65 → 19,88 | 14,05 → 9,07 | 19 → 15 / 16 → 12 | 78,9 → 61 | 58,4 → 34,9 | 0 → 0 | 7,67 → 7,58 |
| solo | L | 04/05 este | 24,28 → 20,17 | 14,65 → 9,38 | 29 → 19 / 26 → 16 | 78,9 → 61 | 58,1 → 35,1 | 0 → 0 | 8,32 → 7,87 |
| solo | S+cachelos | 04/05 este | 27,35 → 23,58 | 22,42 → 8,82 | 18 → 17 / 15 → 10 | 94,6 → 75,2 | 72,7 → 34,3 | 0 → 0 | 8,15 → 8,28 |
| solo | S | suelo (ollas) | 23,3 → 20,1 | 13,77 → 11 | 14 → 13 / 11 → 10 | 78,9 → 55 | 58,6 → 41,3 | 0 → 0 | 7,32 → 8,72 |
| solo | M | suelo (ollas) | 23,65 → 20,2 | 14,05 → 11,22 | 19 → 15 / 16 → 12 | 78,9 → 55 | 58,4 → 41,4 | 0 → 0 | 7,67 → 8,85 |
| solo | L | suelo (ollas) | 24,28 → 20,62 | 14,65 → 11,55 | 29 → 19 / 26 → 16 | 78,9 → 55,1 | 58,1 → 42 | 0 → 0 | 8,32 → 9,1 |
| solo | S+cachelos | suelo (ollas) | 27,35 → 24 | 22,42 → 10,93 | 18 → 17 / 15 → 10 | 94,6 → 69,3 | 72,7 → 41,2 | 0 → 0 | 8,15 → 9,55 |
| solo | S | suelo (hueco) | 23,3 → 27,65 | 13,77 → 15,45 | 14 → 13 / 11 → 10 | 78,9 → 61,4 | 58,6 → 41,1 | 0 → 0 | 7,32 → 8,68 |
| solo | M | suelo (hueco) | 23,65 → 30,68 | 14,05 → 15,73 | 19 → 15 / 16 → 12 | 78,9 → 58,1 | 58,4 → 38,5 | 0 → 0 | 7,67 → 13,47 |
| solo | L | suelo (hueco) | 24,28 → 28,93 | 14,65 → 16,03 | 29 → 19 / 26 → 16 | 78,9 → 64 | 58,1 → 44,9 | 0 → 0 | 8,32 → 9,1 |
| solo | S+cachelos | suelo (hueco) | 27,35 → 31,65 | 22,42 → 15,47 | 18 → 17 / 15 → 10 | 94,6 → 79,1 | 72,7 → 44 | 0 → 0 | 8,15 → 9,53 |
| switch | S | 01/02 oeste | 15,85 → 15,17 | 7,27 → 6,03 | 14 → 13 / 11 → 10 | 26,2 → 23,3 | 19,7 → 15,6 | 12,4 → 11,6 | 10,43 → 10,43 |
| switch | M | 01/02 oeste | 16,2 → 15,35 | 7,53 → 6,3 | 19 → 15 / 16 → 12 | 26,4 → 23,7 | 19,4 → 16,3 | 12,4 → 11,6 | 10,77 → 10,57 |
| switch | L | 01/02 oeste | 16,87 → 15,68 | 8,15 → 6,72 | 29 → 19 / 26 → 16 | 26,3 → 23,9 | 19,1 → 17 | 12,4 → 11,6 | 11,43 → 10,83 |
| switch | S+cachelos | 01/02 oeste | 20,13 → 19,47 | 16,33 → 6,43 | 18 → 17 / 15 → 10 | 30 → 25,3 | 23,2 → 17,6 | 25,5 → 26,1 | 14,03 → 14,33 |

Lectura:
- **Pulsaciones**: L 29 → 19 y M 19 → 15 (−10 y −4 cortes, como estimaba el diseño); S 14 → 13.
- **Cuenco con 2 raciones por cachelo**: pedido 2 con cachelos 22,4 → 13,7 s (Solo), 16,3 → 6,4 s
  (cambio) y 13,2 → 5,3 s (Coop).
- **Coop pedido 1 va más lento** que en PUL-090 (S 10,52 → 11,2 s; M, L y cachelos +0,1…+0,7 s) y el
  emplatador está más tiempo quieto (5,1 → 6,5 s). No se ha investigado la causa; dato para el playtest.
- **Coop pedido 2** con el protocolo de PUL-090: S 6,08 → 4,85 s (−20 %), M 6,35 → 5,12, L 6,97 → 5,53.

## R15 · Individual sin cambio, pedido S sal+aceite desde cero (≤ 50 m): NO CUMPLE con el bot
Metros de P1 en el pedido 1 (incluye los 9,7 m de salir de la posición inicial hasta el rack, como en
PUL-090) y en el 2 (con el pulpo sobrante):

| Dónde se deja la caja | PUL-090 | Pedido 1 | Pedido 2 |
|---|---:|---:|---:|
| Pasaplatos 01 (oeste, junto al rack) | 78,9 | 73,3 | 56,7 |
| Pasaplatos 03 (oeste, lado cocina) | 78,9 | 66,7 | 50 |
| Pasaplatos 04 (este del hueco) | 78,9 | 61 | 34,3 |
| **Suelo de la cocina junto a las ollas (x −1,3)** | 78,9 | **55** | 41,3 |
| Suelo de la cocina junto al hueco (x 2,6) | 78,9 | 61,4 | 41,1 |

> La variante «suelo junto al hueco» (`floorgap`) no es determinista: para la misma ruta, el tramo de aceite del pedido 1 da 14,4 / 11,2 / 17,3 m en S / M / L, probablemente porque el bot choca con la caja o el pulpo soltados en x 2,6, z −1,6, en el camino al hueco. Sus 61,4 m no son un dato fiable; la conclusión se apoya en `floor`, que es estable (55,0 / 55,0 / 55,1 m).


La ruta que el revisor estimó óptima (caja al suelo junto a la olla: rack → hueco con la caja → suelo →
nevera → olla → cortar en el suelo → sobrante al suelo → coger la caja → hueco → dispensadores → zona)
está medida: **55,0 m** (la mejor del bot). Tramos (m): SmallSpawner:9.7, Drop:16.3, OctopusStorage:3.2, Kitchen:3.1, Kitchen:0.3, Box:1.8, Drop:0.5, Box:0.5, Oil:11.1, Salt:1.1, Zone:3.4. Sin los 9,7 m
iniciales son 45,3 m, que sí caben en 50. Por tanto R15 depende de si el criterio cuenta o no la salida
desde la posición inicial; con el criterio de PUL-090 (que sí la cuenta) **no cumple por 5 m**, y solo el
suelo la acerca. Los pasaplatos 04 (61,0 m) y 03 (66,7 m) van detrás. Es un bot de líneas rectas con
puntos calibrados: un humano puede ahorrar o perder metros; el gate pide que el responsable busque su
ruta.

Cambios del bot en esta revisión: los dispensadores se pulsan en el orden (ascendente o descendente en
x) que menos recorre hasta la zona, y la entrega va directa al punto más cercano de la zona
(tramo `Zone` en `legs`).

## R17 · Coop, 4 pedidos S sal+aceite seguidos (media de los pedidos 2–4 ≤ 4,6 s)
Referencia PUL-090: pedido 2 de Coop S = 6,08 s; 75 % = 4,56 s.

| Escenario | Pedidos 1 / 2 / 3 / 4 (s) | Media 2–4 | Pulsaciones | m P1 / P2 | R17 |
|---|---|---:|---:|---|---|
| `chain_pipe`, pasaplatos oeste 01-03 | 11,25 / 4,42 / 4,23 / 3,62 | 4,09 s | 42 | 73,1 / 28,6 | cumple (4,09 ≤ 4,6) |
| `chain_pipe`, pasaplatos este 04-06 | 11,85 / 6,27 / 6,27 / 3,98 | 5,51 s | 42 | 118,8 / 40,1 | no cumple |
| `chain_seq`, oeste (protocolo de PUL-090 ×4) | 11,2 / 4,85 / 11,53 / 4,85 | 7,08 s | 46 | 70 / 28,4 | no cumple |
| `chain_seq`, este | 11,02 / 6,07 / 12,85 / 6,07 | 8,33 s | 46 | 94,3 / 40,3 | no cumple |

La comparación no es homogénea: PUL-090 solo midió el protocolo secuencial y el diseño (§4.2) estima
el flujo adelantado, que PUL-090 nunca midió. El pedido 2 secuencial (Coop S) da 4,85 s (80 % de
6,08 s, no el 75 % que pide R17) y `chain_seq` 7,08 s, porque el pedido 3 necesita un pulpo nuevo (5 s
de cocción). Solo cumple el bot adelantado (dos cajas por delante, dos pulpos al fuego). No se ha medido
el flujo antiguo con ese mismo bot adelantado, así que no se puede atribuir la mejora al rediseño: **AC2
queda pendiente del gate humano**.

## Hallazgos de revisión
1. **Cuenco con 2 y con 4 raciones**: confirmado (`ac1-cuenco-2-vs-4-raciones.png`). A 1280×720 son 2
   bloques amarillos frente a 4 apiñados en el mismo cuenco naranja; hay que mirar de cerca. Pasa al
   playtest.
2. **`fill_per_press` 0.16666667 de M**: no se reproduce con los datos actuales.
   `finding2_fill_rounding.gd` corta dos cajas con un pulpo de 100 con la `Box` y el `Ingredient` reales
   e imprime el `fill` de cada caja (`finding2_fill_rounding.log`): con 0.16666667 (y 0.1666667,
   0.166666667) el pulpo se libera tras la 2.ª caja (6 + 6 cortes, ambas llenas, resto 0). **Sí falla si
   el valor se redondea a la baja**: 0.16666666 deja un resto de 0,000004, 0.1666666 de 0,00004 y
   0.166666 de 0,0004, y el pulpo no se libera (`take` compara `remaining <= 0.0` sin épsilon) aunque
   las dos cajas salen llenas a los 6 cortes. Con 0.1666 y 0.16 el pulpo se agota pero **no llena dos
   cajas M**: la 2.ª queda en 0,9996 y 0,96 tras 7 + 6 cortes. Latente: corregir en PUL-104 (épsilon en
   `take`) antes de tocar el dato.
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
