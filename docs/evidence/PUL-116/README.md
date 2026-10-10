# PUL-116 · Evidencia: re-medición tras D25 (M3d)

Rama de integración con PUL-111..PUL-115 mergeados. Referencias: `docs/evidence/PUL-102/` (tabla
«antes»), `docs/design/decisions.md` D25, `docs/design/features/cubo-basura.md` (T7) y
`docs/design/m3c-gate.md`. Guía para el responsable: `docs/design/m3d-gate.md`.

## Ficheros
| Fichero | Qué es |
|---|---|
| `measure_flow.gd` + `run_measure.gd` | Adaptación de PUL-102 al flujo D25: una sola caja del rack (`BoxShelf/BoxSpawner`), 6 cortes, aliño con una pulsación (`SweetDressing` / `HotDressing`), cuenco de cachelos igual que en D23, las 4 comandas reales de `data/orders/`. Mismo bot (teclado y detector reales de `level_walker.gd`, nunca `interact()`), mismas columnas. Partes nuevas: `recover` (T7: caja errónea y cubo) y `round` (partida completa de 300 s con las fases reales) |
| `metrics_solo_*.json`, `metrics_coop_*.json`, `metrics_chain_*.json` | Un registro por escenario y comanda. Sufijo = pasaplatos de la caja y del sobrante (`floor` = caja en el suelo junto a las ollas, x −1,3) |
| `metrics_recover.json` | T7: `recover_bin` (cubo más cercano, puesto 1), `recover_bin4` (puesto 4, el más lejos del cubo del servicio) y `recover_swap` (volver a la estación y pulsar el otro aliño) |
| `metrics_round_*.json` | 4 partidas completas de un bot Individual secuencial (aleatorias: la semilla de `round_config.tres` es 0 = sin fijar) |
| `ac3-local2p-1080p-fase1-tickets-a-feira.png` | Local 2P a 1920×1080 (MCP): fase 1, 2 tickets «Á feira», estación al paso y rack |
| `ac3-local2p-1080p-fase3-4-tickets-bravo-cachelos.png` | Lo mismo con la fase 3 forzada (`round_state.advance`): 4 tickets, «Bravo cachelos» cabe entero |
| `ac3-estacion-mostrador-5-2m-x3-recorte.png` | Recorte ×3 del mostrador: 2 dispensadores con el mismo icono y el cuenco |
| `ac3-rack-modelo-S-M-L-recorte.png` | Recorte ×3 del rack: el modelo sigue mostrando las etiquetas S, M y L |

## Reproducir (desde la raíz; sin sonido)
```
godot --headless --audio-driver Dummy --path godot --import      # solo si no hay godot/.godot
godot --audio-driver Dummy --resolution 1920x1080 --fixed-fps 60 --path godot \
  -s "$PWD/docs/evidence/PUL-116/run_measure.gd" -- solo PassSlot04 PassSlot05
# partes: solo | coop | chain | recover | round | all ; después caja y sobrante: PassSlot0N o floor
```
Cada parte tarda 1–2 min con ventana y `--fixed-fps 60` (`round` ≈ 6 min). Sin argumentos de pasaplatos
se usa `PassSlot01/02` y el fichero es `metrics_<parte>.json`. Godot avisa al salir de «ObjectDB
instances leaked» y «resources still in use»: ocurre también al final de `tools/verify.sh`.

## Antes (PUL-102) → ahora (PUL-116)
Comparación pedido «S sal+aceite» (4 cortes, 13 pulsaciones) → «Á feira» (6 cortes, aliño de una
pulsación). Pedido 1 = desde cero; pedido 2 = con el pulpo sobrante. 0 rechazos de estación y 0 de
entrega en todos los escenarios de las tablas.

| Modo | Caja en | s ped.1 | s ped.2 | Pulsaciones ped.1 / ped.2 | m P1 ped.1 | m P1 ped.2 | m P2 ped.1 | Quieto P1 ped.1 (s) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| solo | 01/02 oeste | 22,23 → 21,4 | 13,32 → 12,48 | 13 → 14 / 10 → 11 | 73,3 → 69,6 | 56,7 → 53,2 | 0 | 7,45 → 7,4 |
| solo | 03/02 oeste | 20,92 → 19,97 | 11,98 → 11,07 | 13 → 14 / 10 → 11 | 66,7 → 62,5 | 50 → 46,1 | 0 | 7,47 → 7,37 |
| solo | 04/05 este | 19,77 → 19,58 | 8,82 → 8,77 | 13 → 14 / 10 → 11 | 61 → 60,7 | 34,3 → 34,7 | 0 | 7,47 → 7,35 |
| solo | suelo (ollas) | 20,1 → 19,9 | 11 → 10,93 | 13 → 14 / 10 → 11 | 55 → **54,7** | 41,3 → 41,3 | 0 | 8,72 → 8,62 |
| coop | 01/02 oeste | 11,2 → 10,2 | 4,85 → 3,98 | 13 → 14 / 10 → 11 | 23,3 → 19,3 | 15,6 → 11,9 | 11,6 → 11,6 | 6,47 → 6,32 |
| coop | S+cachelos → «Con cachelos» | 15,5 → 14,93 | 5,25 → 5,08 | 17 → 19 / 10 → 12 | 25,3 → 23,5 | 17,6 → 16,1 | 26,1 → 24,7 | 10,37 → 10,18 |
| solo | «Picante», 01/02 | = «Á feira» +0,4 s | +0,4 s | 14 / 11 | 71,6 | 55,2 | 0 | 7,4 |
| solo | «Con cachelos» = «Bravo cachelos», 01/02 | 26,55 → 26,07 | 13,72 → 13,6 | 17 → 19 / 10 → 12 | 89,8 → 86,8 | 58,8 → 57,5 | 0 | 8,32 → 8,47 |

Las comandas con aliño picante y dulce dan lo mismo salvo los metros (el dispensador picante está 1 m
más a la derecha). «Con cachelos» y «Bravo cachelos» dan idénticas. Los demás escenarios en los JSON.

Lectura:
- **La caja única cuesta 2 cortes y el aliño ahorra pulsaciones**: pedido 1 pasa de 13 a 14 pulsaciones
  (+2 cortes, −1 pulsación de aliño); con cachelos de 17 a 19. El tiempo baja un poco porque el aliño
  era 2 paradas y ahora es 1.
- **Pulsaciones del pedido 1 «Á feira» (14)**: rack 1, pasaplatos 1, nevera 1, olla 2 (meter y sacar), 6
  cortes, sobrante al pasaplatos 1, coger la caja 1, aliño 1. Pedido 2 (11): sin nevera ni olla (−3).
  Con cachelos (19): +5 (nevera de cachelos, olla 2 ×2, cuenco, alternar cachelos en la caja).
- **Coop** mejora en pedido 2 (4,85 → 3,98 s) porque el cocinero ya no recorre nada (1,7 m) y
  el emplatador solo para en 1 dispensador.

## R15 · Individual sin cambio, pedido desde cero (≤ 50 m): NO CUMPLE con el bot (igual que PUL-102)
Metros de P1 en el pedido 1 (incluyen los 9,4 m de salir de la posición inicial hasta el rack; en
PUL-102 eran 9,7 m) y en el 2 (con el pulpo sobrante):

| Dónde se deja la caja | PUL-090 | PUL-102 ped. 1 | PUL-116 ped. 1 | PUL-116 ped. 2 |
|---|---:|---:|---:|---:|
| Pasaplatos 01 (oeste, junto al rack) | 78,9 | 73,3 | 69,6 | 53,2 |
| Pasaplatos 03 (oeste, lado cocina) | 78,9 | 66,7 | 62,5 | 46,1 |
| Pasaplatos 04 (este del hueco) | 78,9 | 61,0 | 60,7 | 34,7 |
| **Suelo de la cocina junto a las ollas (x −1,3)** | 78,9 | 55,0 | **54,7** | 41,3 |

La mejor ruta honesta es la misma que en PUL-102: rack → hueco con la caja → suelo de la cocina → nevera
→ olla → cortar en el suelo → sobrante al suelo → coger la caja → hueco → aliño → zona. Tramos (m):
BoxSpawner 9,4 · Drop 16,4 · OctopusStorage 3,2 · Kitchen 3,1 + 0,3 · Box 1,8 · Drop 0,4 · Box 0,5 ·
SweetDressing 13,1 · Zone 2,3. Sin los 9,4 m iniciales son **45,3 m (≤ 50 si no cuenta la salida; 54,7 si
cuenta)**: idéntico a PUL-102 (45,3). Mínimo estructural: la caja sale del rack (servicio), el pulpo y
la olla están en la cocina y el aliño y los puestos en el servicio, así que son 2 cruces del hueco
(≈ 16 m + 13 m). Un solo aliño en vez de 2 paradas no recorta metros (de «Oil» 11,1 + «Salt» 1,1 a
«SweetDressing» 13,1). Con el criterio de PUL-090 **no cumple por 4,7 m**; las variantes con pasaplatos
(60,7–69,6 m) tampoco.

## R17 · Coop, 4 pedidos «Á feira» seguidos (media de los pedidos 2–4 ≤ 4,6 s)
Referencia PUL-090: pedido 2 de Coop S = 6,08 s; 75 % = 4,56 s.

| Escenario | Pedidos 1 / 2 / 3 / 4 (s) | Media 2–4 PUL-102 → ahora | Pulsaciones | m P1 / P2 | R17 |
|---|---|---:|---:|---|---|
| `chain_pipe`, pasaplatos oeste 01–03 | 10,28 / 3,37 / 3,25 / 2,52 | 4,09 → **3,05 s** | 42 → 46 | 58,6 / 28,6 | cumple |
| `chain_pipe`, pasaplatos este 04–06 | 11,63 / 6,03 / 6,07 / 3,70 | 5,51 → 5,27 s | 42 → 46 | 119,4 / 40,3 | no cumple |
| `chain_seq`, oeste (protocolo secuencial ×4) | 10,2 / 3,98 / 10,53 / 4,0 | 7,08 → 6,17 s | 46 → 50 | 54,9 / 28,4 | no cumple |
| `chain_seq`, este | 10,85 / 5,97 / 12,68 / 5,97 | 8,33 → 8,21 s | 46 → 50 | 94,6 / 40,3 | no cumple |

- **Pedido 2 secuencial de Coop: 3,98 s = 65 % de los 6,08 s de PUL-090** (antes 80 %): ya cumple
  el 75 % por sí solo (≤ 4,56 s).
- La media secuencial 2–4 (6,17 s) falla por estructura: el pedido 3 necesita un pulpo nuevo
  (5 s de cocción) porque 1 pulpo = 2 cajas. Solo cumple el flujo adelantado (dos pulpos al fuego y cajas por
  delante) y con los pasaplatos del oeste.
- Seguimos sin medir el flujo antiguo con el bot adelantado, así que la mejora respecto a PUL-090 no es
  homogénea (igual que en PUL-102).

## T7 · Recuperación con el cubo (tiempos informativos)
Protocolo (`_recover` de `measure_flow.gd`): el bot hace la caja 1 con el aliño **picante** para una
comanda «Á feira» (el pulpo sobrante queda en el pasaplatos 02), la lleva a la zona del puesto sin
entregar y desde ahí cronometra hasta `order_completed`. Siempre: 0 `delivery_rejected`, recaudación sin
bajar (+12 € al final: 8 + 4 de bonus) y la comanda sigue viva: **T7 funcional cumple** (`rejections_during` 0, `completed_after` 1). Los
tiempos son informativos: `cubo-basura.md` no fija un límite de segundos (el «≤ 15 s» salió de la ficha).
`revenue_delta` se mide tras la entrega; que tirar no baja la recaudación lo cubren `trash_penalty` = 0 y
los GUT T1/T5.

| Escenario | Segundos desde la caja errónea | Metros P1 (total) | Pulsaciones (total) | Cubo usado |
|---|---:|---:|---:|---|
| `recover_bin`, comanda en el puesto 1 (cubo a 0,8 s) | **13,23** | 128,0 | 26 | `TrashBinService` |
| `recover_bin4`, comanda en el puesto 4 (cubo a 1,55 s) | **16,78** | 145,1 | 26 | `TrashBinKitchen` (el bot elige el de camino más corto; registrado en `bin`, rerun con el mismo resultado) |
| `recover_swap`: volver a la estación y pulsar el aliño dulce (sin cubo) | **1,3** | 77,3 | 15 | ninguno |

- Con el aliño de una pulsación **se corrige sin cubo**: pulsar el otro aliño sustituye (D25). El cubo
  solo compite cuando hace falta rehacer algo (pulpo equivocado, cachelos de más, caja a medias que
  estorba). El tiempo de 13–17 s lleva incluido que el pulpo sobrante esté ya en un pasaplatos; sin él
  habría que cocer otro (+5 s de cocción y los cruces del hueco). Eso **no se ha medido**.

## Pulsaciones por comanda (Individual, pedido 1 / pedido 2)
| Comanda | Pedido 1 | Pedido 2 | Desglose del pedido 1 |
|---|---:|---:|---|
| Á feira / Picante | 14 | 11 | 6 cortes + 8 (rack, pasaplatos, nevera, olla ×2, sobrante, coger caja, aliño) |
| Con cachelos / Bravo cachelos | 19 | 12 | lo anterior + 5 (nevera de cachelos, olla 2 ×2, cuenco, alternar cachelos); el pedido 2 con cachelos ya repuestos no vuelve a cocer |

## Umbrales de estrellas (AC2): propuesta 40 / 90 / 150 € (hoy 30 / 60 / 90 €)
No hay un bot humano: se usa como referencia un bot Individual secuencial sin adelantar que sirve siempre la comanda
con menos paciencia (`round` de `measure_flow.gd`, fases reales de `round_config.tres`, 300 s):

| Ruta de pasaplatos | Recaudación | Entregadas | Caducadas | Estrellas con 30/60/90 | Servidas |
|---|---:|---:|---:|---:|---|
| 01/02 (1.ª, `metrics_round.json`; las partidas son aleatorias, semilla 0 = sin fijar) | 150 € | 16 | 9 | 3 | Á feira 12, Picante 2, Con cachelos 1, Bravo 1 |
| 01/02 (2.ª) | 159 € | 17 | 10 | 3 | Á feira 11, Picante 5, Bravo 1 |
| 03/02 | 158 € | 17 | 7 | 3 | Á feira 14, Picante 3 |
| 04/05 | 195 € | 19 | 6 | 3 | Á feira 10, Picante 7, Con cachelos 1, Bravo 1 |

- Cada pedido entregado rinde ≈ 9–10 € netos (8–13 € + 3–4 de bonus − las −3 € por caducada).
- **Con 30/60/90 el bot saca 3 estrellas con 1,7–2,2 veces el umbral (150–195 € frente a 90 €); un jugador
  al 40 % de este bot (60 €) ya saca 2★ y al 60 % (90 €) 3★**. Un coop competente va por encima del bot secuencial: 3 estrellas serían
  triviales.
- Propuesta: **1★ ≥ 40 €** (≈ 4 comandas), **2★ ≥ 90 €** (≈ 55 % del bot secuencial), **3★ ≥ 150 €** (el
  bot secuencial de menor resultado; para un humano en Individual exige ruta eficiente y pocas
  caducadas). **Provisional**: se calibra con las partidas del responsable (Individual y Local 2P).
  `revenue_thresholds` es común a Individual y Local 2P y **Coop no está medido**: 40/90/150 es
  provisional. Los umbrales están en `godot/data/config/round_config.tres` (`revenue_thresholds`), no se han tocado.
- Limitaciones del bot de `round`: no es determinista (la semilla de `round_config.tres` es 0), no cocina
  por adelantado y se desincroniza alguna vez (3–5 avisos «objetivo … no alcanzado» o «la zona no entregó» por partida;
  el bot sigue y completa la comanda, pero pierde segundos), con lo que 150–195 € es indicativo, no exacto. No hay medición de Coop completo.

## Hallazgos (sin arreglar; ninguno bloquea)
1. **No se ha encontrado ningún bug del juego**: 0 rechazos, 0 errores en `get_debug_output`; más de 100
   comandas jugadas de extremo a extremo con el bot (solo, coop, cadenas, recuperación y 4 partidas
   completas).
2. **Modelo del rack con S, M y L** (`ac3-rack-modelo-S-M-L-recorte.png`): el modelo sigue apilando tres
   tipos de caja con las letras S, M y L aunque la caja es única (pendiente de arte, conocido).
3. **Los dos dispensadores de aliño usan el mismo icono** (`pepper-hot-solid.svg` en
   `sweet_dressing.tres` y `hot_dressing.tres`) en el mostrador y en el ticket; solo cambia el
   color y el tapón (`ac3-estacion-mostrador-5-2m-x3-recorte.png` y el ticket «Bravo cachelos»).
4. **El mostrador mide 5,2 m y solo usa 2 m con 3 objetivos** (aliño dulce x −0,8, aliño picante x 0,2 y cuenco x 1,2):
   la zona de x −2,4…−1 y x 1,8…2,8 queda vacía.
5. Con 4 tickets a 1920×1080 el panel cubre el cartel «Pulpa SA» del fondo (captura de la fase 3). Cosmético.
6. El HUD sigue mostrando «Cajas / minuto» (heredado; la métrica es la recaudación).

## No comprobado
- Juego humano (rutas, dudas, lectura de iconos): lo hace el responsable con `m3d-gate.md`.
- Coop completo de 300 s, Individual con cambio (`Q`) y el flujo de R16 (PUL-118 lo estabiliza).
- Recuperación sin pulpo sobrante en el pasaplatos.
- Cubo en Local 2P con dos jugadores a la vez (T9 está cubierto por GUT).
- Chevrones de zona, pasaplatos del este y hueco: no cambian con D25; no se han vuelto a mirar.
