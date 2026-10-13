# PUL-164 · Evidencia: balance de la alpha medido con el bot (estado D26/D27)

Rama `jrmougan/pul-164` sobre `main` en `039c737`. No se cambia ningún `.tres` ni código de juego: la
propuesta del § AC3 va al gate G2 del responsable y la aplica PUL-166. Medidas previas: `docs/evidence/PUL-116/`.

## Ficheros
| Fichero | Qué es |
|---|---|
| `godot/tests/tools/balance_measure.gd` + `balance_run.gd` | Bot de medida. Base: `PUL-116/measure_flow.gd` (teclado simulado y detector real de `tests/integration/level_walker.gd`, nunca `interact()`). No es un test (no empieza por `test_`): `verify.sh` solo le pasa el formato y el lint |
| `run_all.sh` | Lanza las 14 medidas en paralelo sin ventana (≈ 15 s en total con `--fixed-fps 60`) y regenera las tablas |
| `balance_tables.py` | Lee los JSON y los valores actuales de los `.tres` (no los copia a mano), escribe `tables.md` y `summary.json` |
| `tables.md` | Todas las tablas (AC1, AC2, colas, propuesta medida). **Las del README son extractos** |
| `summary.json` | Lo mismo en JSON: valores actuales, propuesta, holguras con marca `flag` (< 5 s), partidas, proyecciones |
| `metrics_recipes_PassSlot0N_PassSlot0M.json` | Recetas: Individual y Local 2P × 4 comandas × 2 pedidos (desde cero y en flujo). Sufijo = pasaplatos de la caja y del sobrante |
| `metrics_round_<modo>_seed<N>.json` | Partidas de 300 s con fases reales, semillas 1–3. `orders_log`: cada comanda con fase, paciencia, instante, € y segundos que le quedaban (o caducidad) |
| `metrics_round_<modo>_seed<N>_proposal.json` | Las mismas partidas con los límites de fase y multiplicadores propuestos aplicados **solo en memoria** |

## Reproducir (desde la raíz)
```
godot --headless --import --path godot     # solo si no hay godot/.godot (sin caché de clases falla el parseo)
docs/evidence/PUL-164/run_all.sh           # o una sola medida:
godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s res://tests/tools/balance_run.gd -- recipes PassSlot04 PassSlot05
godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s res://tests/tools/balance_run.gd -- round solo|coop <semilla> [proposal]
```
Todo es determinista: dos ejecuciones completas dieron las mismas cifras al céntimo (la semilla se
pone en memoria sobre `round_config.tres`, cuyo `rng_seed` = 0 sigue sin tocar).

## Método y diferencias con el bot de PUL-116
- **Individual** = un personaje (`GameMode.SINGLE`); **Local 2P** = `COOP_2P`, J1 emplata (WASD) y J2 cocina (flechas).
- **Recetas** (AC1): sin fases ni caducidad, 1 comanda viva. Pedido 1 «desde cero» (sale de la posición
  inicial, cuece el pulpo); pedido 2 «en flujo» (con el medio pulpo sobrante). Paciencia de cada fase =
  `max_time` × `patience_multiplier` de `round_config.tres`.
- **Partidas** (AC2): 300 s, fases reales. *Individual*: bot secuencial (caja al pasaplatos 04, cuece o usa el
  sobrante del 05, corta, aliña); decide si cuece cachelos por la comanda más urgente y, con la caja llena,
  sirve la comanda **más urgente que pueda** (con cachelos solo si el cuenco tiene). *Local 2P* (nuevo):
  cocinero y emplatador en paralelo; J1 mantiene cajas en los pasaplatos 01 y 03 y sirve la más urgente; J2
  adelanta un pulpo, corta en el pasaplatos con caja, deja el sobrante en el 02 y repone el cuenco cuando una
  comanda viva pide cachelos.
- **D26**: la entrega es solo por zona. Si la zona no entrega (la comanda caducó por el camino), la caja va
  al cubo más cercano; nunca se pulsa el puesto. El cuenco solo pone cachelos (D26) y el bot lo usa una vez por caja.
- **Corregido en el bot (no es bug del juego)**: el bot de PUL-116 iba en diagonal hasta el borde de la zona
  y **cruzaba la zona iluminada del puesto vecino**; con la misma receta en los dos, entregaba allí y la
  comanda del puesto 1 caducaba siempre (6 caducadas por partida, todas del puesto 1). Ahora entra por el
  norte de la zona (`Walker.ZONE_APPROACH`, como `walk_into_zone`).
- **Cota inferior**: el bot anda en línea recta, no duda y pulsa cada 4 frames (15 pulsaciones/s: los 6 cortes
  le cuestan 0,4 s; manteniendo pulsado, D26, son 1,2 s). Un humano tardará más; lo que solo resuelve el
  playtest está en § «Lo que decide el playtest».

## AC1 · Tiempo del bot, paciencia y holgura por receta y fase
Extracto con la mejor ruta de cada modo (Individual: caja en el pasaplatos 04 y sobrante en el 05;
Local 2P: 01/02). Las 56 filas (también 01/02 en Individual y 04/05 en Local 2P) están en `tables.md` y `summary.json` (`recipes`).
Holgura = paciencia − tiempo del bot. **Marca ⚠ si < 5 s: ninguna receta aislada baja de 20 s.**

| Modo | Receta | Fase | Paciencia (s) | Bot desde cero (s) | Holgura (s) | Bot en flujo (s) | Holgura (s) |
|---|---|---:|---:|---:|---:|---:|---:|
| Individual | Á feira | 1 / 2 / 3 | 60 / 51 / 42 | 19,8 | 40,2 / 31,2 / 22,2 | 8,9 | 51,1 / 42,1 / 33,1 |
| Individual | Picante | 2 / 3 | 51 / 42 | 19,8 | 31,2 / 22,2 | 8,9 | 42,1 / 33,1 |
| Individual | Con cachelos | 3 | 56 | 23,6 | 32,4 | 9,2 | 46,8 |
| Individual | Bravo cachelos | 3 | 56 | 23,6 | 32,4 | 9,2 | 46,8 |
| Local 2P | Á feira | 1 / 2 / 3 | 60 / 51 / 42 | 10,4 | 49,6 / 40,6 / 31,6 | 4,1 | 55,9 / 46,9 / 37,9 |
| Local 2P | Picante | 2 / 3 | 51 / 42 | 10,8 | 40,2 / 31,2 | 4,5 | 46,5 / 37,5 |
| Local 2P | Con cachelos | 3 | 56 | 15,1 | 40,9 | 5,2 | 50,8 |
| Local 2P | Bravo cachelos | 3 | 56 | 15,1 | 40,9 | 5,2 | 50,8 |

- **La duda de M3/M3d queda resuelta**: «Con cachelos» en fase 3 (80 s × 0,7 = 56 s) frente a ~54 s de ruta
  (PUL-070) es ahora **23,6 s desde cero en Individual con la ruta 04/05 (holgura 32,4 s)**; con la ruta
  01/02 son 26,3 s (holgura 29,7 s), lo mismo que PUL-116 (26,1 s): D26 no cambia el tiempo de la receta.
- Pulsaciones por pedido: 14 / 11 sin cachelos y 19 / 12 con cachelos (igual que PUL-116). Metros de P1
  en Individual 04/05: 61,5 / 34,9 (sin cachelos) y 74,5 / 35,2 (con cachelos).

### Lo que aprieta es la cola, no la receta
Con reposición inmediata hay tantas comandas vivas como puestos, así que la última espera a las demás:
holgura de cola = paciencia − puestos × t. Dos t: **flujo** (siempre con sobrante, cota optimista) y **ciclo**
(media de cero y flujo: 1 pulpo = 2 cajas). Extracto de `tables.md`:

| Modo | Fase (puestos) | Receta | Paciencia (s) | t flujo / ciclo (s) | Holgura de cola flujo / ciclo (s) |
|---|---|---|---:|---:|---:|
| Individual | 1 (2) | Á feira | 60 | 8,9 / 14,3 | 42,3 / 31,4 |
| Individual | 2 (3) | Á feira, Picante | 51 | 8,9 / 14,3 | 24,4 / 8,0 |
| Individual | 3 (4) | Á feira, Picante | 42 | 9,0 / 15,4 | 5,9 / **−19,5 ⚠** |
| Individual | 3 (4) | Con cachelos, Bravo | 56 | 9,0 / 15,4 | 19,9 / **−5,5 ⚠** |
| Local 2P | 3 (4) | Á feira, Picante | 42 | 4,8 / 8,8 | 23,0 / 6,8 |
| Local 2P | 3 (4) | Con cachelos, Bravo | 56 | 4,8 / 8,8 | 37,0 / 20,8 |

En partida (lo que le quedaba a cada comanda al entregarla, 3 semillas; tabla completa en `tables.md`) la única
holgura < 5 s es **Individual en fase 2: mínimo 4,7 s ⚠** en «Á feira» y «Picante» (mediana de «Picante» 5,1 s). Local 2P nunca baja
de 10,9 s y no caduca nada.

## AC2 · Partidas de 300 s, 3 semillas por modo, umbrales actuales 30 / 60 / 90 €
| Modo | Semilla | Recaudación (€) | Entregas | Caducadas | ★ | Servidas |
|---|---:|---:|---:|---:|---:|---|
| Individual | 1 | 195 | 20 | 2 | 3 | Á feira 10, Picante 8, Con cachelos 2 |
| Individual | 2 | 188 | 20 | 3 | 3 | Á feira 16, Picante 2, Con cachelos 1, Bravo 1 |
| Individual | 3 | 184 | 20 | 3 | 3 | Á feira 13, Picante 7 |
| Local 2P | 1 | 692 | 59 | 0 | 3 | Á feira 36, Picante 20, Con cachelos 1, Bravo 2 |
| Local 2P | 2 | 641 | 54 | 0 | 3 | Á feira 41, Picante 7, Con cachelos 3, Bravo 3 |
| Local 2P | 3 | 665 | 56 | 0 | 3 | Á feira 36, Picante 14, Con cachelos 4, Bravo 2 |

0 rechazos de estación y de entrega, 0 quemados y 0 cajas al cubo en las 6 partidas; 0–1 avisos del bot
(«objetivo no alcanzado», recupera solo). `balance_tables.py` recalcula cada recaudación desde el registro de
comandas (precio + bonus − caducadas) y coincide al euro con la del juego.

- **Individual: 184–195 € (media 189), 3★ con 2× el umbral.** Las caducadas son de la fase 3 y casi todas con
  cachelos (5 de 9 comandas con cachelos caducan): tienen más paciencia (56 s), así que el bot, que sirve
  la más urgente, las deja para el final.
- **Local 2P: 641–692 € (media 666), 3,5× el Individual y 7× el umbral de 3★.** Con dos bots el cuello de
  botella desaparece (≈ 5 s por entrega) y la paciencia no muerde: 0 caducadas. **Con un único
  `revenue_thresholds` para los dos modos no se pueden calibrar las estrellas.**
- € por segundo de cada fase (media de las semillas): Individual 0,61 / 0,75 / 0,53; Local 2P 2,28 / 2,42 / 1,96.
  La fase 3 rinde menos que la 2 en los dos modos (caducadas en Individual, cachelos en los dos).

## AC3 · Propuesta de valores para el gate G2 (la aplica PUL-166)
Cada valor con antes, después y efecto numérico. «Medido» = partidas del bot con la propuesta aplicada en
memoria (`*_proposal.json`, mismas semillas); «estimado» = cálculo sobre las tablas anteriores.

| Valor (fichero) | Antes | Después | Efecto esperado |
|---|---|---|---|
| `revenue_thresholds`, Individual (`round_config.tres`) | 30 / 60 / 90 € | **40 / 90 / 140 €** (≈ 20 / 45 / 75 % del bot) | Estimado. Jugador al 30 % del bot (57 €): 1★ → 1★; al 50 % (94 €): 3★ → **2★**; al 75 % (142 €): 3★ → 3★; bot (189 €): 3★ con 49 € de margen. Sustituye a la propuesta 40/90/150 de PUL-116 (con el bot de ahora, 150 € es el 79 %) |
| `revenue_thresholds`, Local 2P (**campo nuevo**: hoy los umbrales son comunes) | 30 / 60 / 90 € | **130 / 300 / 490 €** (mismas fracciones del bot Local 2P) | Estimado. Al 30 % del bot (200 €): 3★ → **1★**; al 50 % (333 €): 3★ → **2★**; al 75 % (500 €): 3★ → 3★. Sin esto, 3★ en Local 2P exigen el 14 % del bot. Requiere umbrales por modo en `RoundConfig` (código + datos): **decisión del responsable** |
| `patience_multiplier` fase 1 | ×1,0 (60 s) | ×1,0 | 0 s. Holgura de cola Individual 31,4 s por ciclo: la fase 1 no aprieta (mínimo en partida 31,8 s) |
| `patience_multiplier` fase 2 | ×0,85 (51 s) | ×0,85 | 0 s. Ya es la fase justa de Individual (mínimo en partida 4,7 s ⚠, cola por ciclo 8,0 s) |
| `patience_multiplier` fase 3 | ×0,7 (42 s; 56 s con cachelos) | **×0,8 (48 s; 64 s con cachelos)** | +6 s y +8 s de paciencia. Holgura de cola Individual por ciclo: −19,5 → −13,5 s (sin cachelos) y −5,5 → +2,5 s (con cachelos); en flujo 5,9 → 11,9 s. Medido (con los límites nuevos): **caducadas Individual 8 → 5** en 3 partidas y +5 / +8 / +6 €; Local 2P sin caducadas igual que antes |
| Límites de fase (`start_fraction`) | 0 / 100 / 200 s (0 / ⅓ / ⅔) | **0 / 90 / 180 s (0 / 0,3 / 0,6)** | La fase 3 (cachelos) pasa de 100 a 120 s (+20 %). Estimado con los €/s de cada fase: Individual −3 € (189 → 186), Local 2P −8 € (666 → 658). Medido junto con ×0,8: comandas con cachelos servidas Individual 4 → 6 y Local 2P 15 → 18 en 3 partidas; € Individual 189 → 195 de media, Local 2P 666 → 668 |
| Precios (`base_points` de `data/recipes/`) | 8 / 9 / 12 / 13 € | **8 / 9 / 12 / 13 € (sin cambio)** | 0 €. Ya crecen con el esfuerzo: € por segundo de ciclo del bot Individual (04/05) 0,56 / 0,63 / 0,73 / 0,79; con cachelos +4 € por +2,1 s de ciclo (+15 %). Cumplen AC12 de `comandas.md` (8–14 €, con cachelos > sin cachelos) |
| `presses_to_fill` (`data/boxes/box.tres`) | 6 | **6 (sin cambio)** | 0 s. Cada corte de más o de menos cambia ±0,2 s por caja manteniendo pulsado (`cut_repeat_interval`), ±0,8 s en una cola de 4 puestos: frente a holguras de cola de −19,5…+51,8 s no mueve el balance. Lo decide el tacto (playtest) |

No incluidos (sin señal en las medidas para cambiarlos): `time_bonus_max` = 5 (el bonus es ≈ 3–4 € por entrega),
`expire_penalty` = 3, `max_time` de las recetas (el ajuste por fase basta) y `active_slots` 2 / 3 / 4.

## Lo que decide el playtest (no el bot)
1. **Qué parte del bot hace un humano** en cada modo: las estrellas propuestas suponen 30 / 50 / 75 %. Anotar
   € y caducadas de las partidas del responsable en Individual y Local 2P y recolocar los umbrales con esas cifras.
2. **Umbrales por modo** (sí / no): con uno solo, Local 2P da 3★ trivialmente o Individual no llega nunca.
3. **Si la fase 3 en Individual debe desbordar**: aun con ×0,8 la cola por ciclo es negativa (−13,5 s). Que
   caduque alguna comanda puede ser el pico de tensión buscado o frustrar; con un humano más lento será peor.
4. **Si se disfrutan los cachelos** con 120 s de fase 3, y si dejarlos para el final (más paciencia) se siente bien.
5. **Tacto del corte** (6 cortes, pulsar o mantener) y del «aliño de una pulsación»: el bot no lo mide.
6. **Coordinación en Local 2P**: el bot no habla ni se estorba; el 3,5× sobre Individual es un techo.

## Hallazgos
1. **No se ha encontrado ningún bug del juego**: 0 rechazos, 0 quemados y 0 errores de script en 14 ejecuciones
   (≈ 460 comandas entregadas en las 12 partidas y 32 pedidos de recetas).
2. **Una caja que encaja se entrega en cualquier zona iluminada que se pisa** (D26), aunque se iba a otro
   puesto: con dos comandas iguales seguidas, un camino en diagonal entrega en la vecina. Es coherente con D26;
   vigilar en el playtest si sorprende al jugador (el bot de PUL-116 lo sufría, ver § Método).
3. **Local 2P no siente la paciencia** (0 caducadas, mínimo 10,9 s): la dificultad de las fases solo
   aprieta en Individual.

## AC4 · Verificación
Sobre el commit de la ficha (`check_owns.py` toma `HEAD` como base por defecto; desde la rama de la ficha
se pasa `main`, que es lo que hace el merge gate desde `main`):
```
$ tools/verify.sh --quick; echo "exit $?"
== gdformat --check
237 files would be left unchanged

== gdlint
Success: no problems found

== import

✓ verify OK
exit 0

$ python3 tools/check_owns.py jrmougan/pul-164 main; echo "exit $?"
check_owns: 24 rutas dentro de owns de PUL-164.
exit 0
```
