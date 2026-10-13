---
id: PUL-164
title: Medir el balance de la alpha con el bot y proponer valores
status: review
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [godot/tests/tools/balance_*.gd*, docs/evidence/PUL-164/**, docs/backlog/PUL-164-medir-el-balance-de-la-alpha.md]
touches_scenes: []
---

## Target
Balance pendiente de M3/M3d: `order_2` en fase 3 (80 s × 0,7 = 56 s) frente a ~54 s de ruta óptima
(PUL-070); umbrales de estrellas 30/60/90 € con un bot que recauda 150–195 € (propuesta 40/90/150 €,
`m3d-gate.md`); límites de fase en tercios (`dificultad-progresiva.md`, pregunta 1); `presses_to_fill` = 6 y
precios de las 4 recetas provisionales (GDD §11, preguntas 1, 5, 7). Datos en `round_config.tres` y `data/orders/`.
Medidas previas en `docs/evidence/PUL-116/`.

## Change
1. Con el bot de rutas (`godot/tests/tools/`, `level_walker.gd`), medir con el estado actual (D26/D27) en
   Individual y Local 2P: tiempo por receta desde cero y en flujo, holgura de cada receta frente a su
   paciencia en cada fase, recaudación en 300 s y estrellas obtenidas.
2. Proponer una tabla de valores (umbrales, multiplicadores de paciencia, límites de fase, precios) con el
   efecto esperado de cada cambio, y lo que solo puede decidir un playtest humano.

## Constraints
- No se cambian datos (`.tres`) ni código de juego: la propuesta pasa por el responsable (gate) y la aplica PUL-166.
- Las herramientas de medida no entran en `verify.sh` (no son tests).

## Acceptance
- [x] AC1 Given el bot de rutas sobre el estado actual (D26/D27), When se mide cada receta (4) en cada fase donde existe, Then hay tabla
  con tiempo del bot (s), paciencia (s) y holgura (s), y toda holgura < 5 s aparece marcada → tabla + JSON en `docs/evidence/PUL-164/`.
- [x] AC2 Given 3 semillas por modo (Individual, Local 2P), When se juegan 300 s con el bot, Then se registran recaudación (€), entregas y
  estrellas con los umbrales actuales 30/60/90 → JSON y tabla en la evidencia.
- [x] AC3 Given la propuesta de valores, When se presenta al gate G2, Then cada valor (umbrales, multiplicadores, límites de fase, precios,
  `presses_to_fill`) tiene antes, después y efecto esperado numérico (holgura o € previstos) → tabla en la evidencia.
- [x] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-164/README.md`.

## Plan
1. Llevar el bot de PUL-116 (`measure_flow.gd`) a `godot/tests/tools/balance_measure.gd` + `balance_run.gd`
   con el flujo D26 (entrega solo por zona, caja al cubo si la zona no entrega; cuenco que solo pone).
2. Parte `recipes`: Individual y Local 2P × 4 comandas × pedido desde cero y en flujo, con dos rutas de pasaplatos.
3. Parte `round`: 300 s con fases reales y semilla en memoria (1–3); bot Individual secuencial y bot Local 2P
   nuevo (cocinero y emplatador en paralelo); registro por comanda (fase, paciencia, lo que le quedaba).
4. `balance_tables.py`: holgura por receta y fase (marca < 5 s), holgura de la cola llena, partidas, € por fase.
5. Propuesta: variante `proposal` del bot que aplica límites y multiplicadores en memoria para medir su
   efecto; umbrales y precios estimados sobre las partidas. Ningún `.tres` ni código de juego cambia.

## Evidence
`docs/evidence/PUL-164/README.md` (tablas completas en `tables.md`, datos en `summary.json` y `metrics_*.json`;
reproducible con `run_all.sh`, determinista).
- AC1: ninguna receta aislada baja de 20 s de holgura (Individual 04/05 «Con cachelos» fase 3: 23,6 s frente
  a 56 s; la duda de PUL-070 queda resuelta). Lo que aprieta es la cola: Individual en fase 3 con 4 puestos
  tiene holgura de cola −19,5 s ⚠ (por ciclo) y en partida el mínimo es 4,7 s ⚠ en la fase 2.
- AC2: Individual 184 / 188 / 195 € (20 entregas, 2–3 caducadas, 3★); Local 2P 641 / 665 / 692 € (54–59
  entregas, 0 caducadas, 3★). Con 30/60/90 los dos modos sacan 3★ de sobra.
- AC3: umbrales Individual 40/90/140 €, umbrales propios de Local 2P 130/300/490 € (campo nuevo: decide el
  responsable), fase 3 ×0,7 → ×0,8, límites 100/200 → 90/180 s; precios y `presses_to_fill` sin cambio. Medido
  con el bot: caducadas en Individual 8 → 5 y +5…+8 € por partida.
- AC4: salida de `verify.sh --quick` y `check_owns.py` pegada en el README.
- Corregido en el bot (no es bug del juego): el de PUL-116 entregaba en el puesto vecino al cruzar su zona.
