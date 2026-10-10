---
id: PUL-118
title: Estabilizar test_level_01_r16 (intermitente bajo carga)
status: done
milestone: M3d
role: gameplay-engineer
deps: [PUL-115]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_level_01_r16.gd, godot/tests/integration/level_walker.gd, docs/evidence/PUL-118/**, docs/backlog/PUL-118-estabilizar-test-r16.md]
touches_scenes: []
---

## Target
`godot/tests/integration/test_level_01_r16.gd`, en especial `test_r16_single_with_switch_two_s_orders_one_octopus_two_switches`: falla de forma intermitente (espera 2 `order_completed` y llega 1). Visto en el verify de un worker de PUL-105, en un merge gate de PUL-111 (2026-10-10) y en el verify de PUL-112; pasa al repetir.

## Change
Encontrar la causa (dependencia del tiempo real o de frames, esperas por tiempo de reloj, carga de CPU con varias instancias de Godot, orden de físicas, aleatoriedad sin semilla) y hacer el test determinista sin debilitar lo que comprueba (R16). Si la causa está en el juego y no en el test, no se arregla aquí: se documenta y se avisa al coordinador.

## Constraints
- No reducir el número de comandas ni quitar aserciones para que pase.
- Prueba de estabilidad: ejecutar el fichero ≥ 20 veces seguidas (y alguna vez con otro proceso de Godot cargando la CPU) sin fallos; dejar el comando y el resultado en Evidence.
- `tools/verify.sh` en verde.

## Acceptance
- [x] AC1 Causa documentada en Evidence
- [x] AC2 20 ejecuciones seguidas sin fallos
- [x] AC3 `tools/verify.sh` en verde

## Plan
- Fichero: `godot/tests/integration/test_level_01_r16.gd` (único cambio; `level_walker.gd` no necesita cambios).
- Sin señales nuevas ni cambios de contrato.
- AC1: reproducir en bucle (`docs/evidence/PUL-118/run_loop.sh`) e instrumentar la entrega para ver quién la completa.
- AC2: fijar la semilla del RNG de comandas del nivel en el test, con aserción de que las dos comandas son de recetas distintas; 25 ejecuciones seguidas y 3 bucles de 8 en paralelo (carga).
- AC3: `tools/verify.sh`.

## Evidence
**Causa (AC1).** No es tiempo de reloj, frames ni carga de CPU: es aleatoriedad sin semilla. El nivel
crea el RNG de comandas con `randomize()` (`OrderService.setup`, `rng_seed = 0`) y el test toma
las dos comandas iniciales del catálogo `[Á feira, Picante]` al azar. Con probabilidad 50 % las dos
son de la misma receta. Entonces `OrderStand` acepta la caja por la zona de entrega
(`%DeliveryZone.body_entered`, PUL-039: entrega sola si la caja coincide con la comanda viva del
puesto), y la caja 1 acaba en el puesto 2 (o en el que cruce primero). El puesto 1 sigue con su
comanda, el puesto 2 se repone con otra al azar y la entrega 2 llega con una caja que no coincide:
`delivery_rejected` y `order_completed` = 1 en vez de 2. Visto en la instrumentación: en las
ejecuciones que fallan `held=<Box>` en la segunda entrega y comanda viva del puesto 2 distinta a la
esperada, con `rejected=1 completed=1`. La carga solo cambia el recorrido exacto y por eso parecía
intermitente bajo carga; el fallo es 50 % de las combinaciones, ~30 % observado.
No es un bug del juego: la entrega automática por zona es el comportamiento diseñado (PUL-039).

**Arreglo.** En `_load_two_order_level` se duplica el `round_config` del nivel con `rng_seed = 1`
(`R16_SEED`; `OrderService.setup` ya lo usa). Con esa semilla salen Picante (puesto 1), Á feira
(puesto 2) y Picante (reposición del puesto 1), de modo que cada caja solo encaja en su puesto.
Se añade `assert_ne(active[0].data, active[1].data)` para que un cambio futuro del RNG falle claro.
No se reduce nada de R16: mismas dos comandas, 2 pulsaciones de `p1_switch`, todas las aserciones.

**Comando** (desde la raíz del repo; ~23 s por ejecución):
`bash docs/evidence/PUL-118/run_loop.sh N salida.log`, que ejecuta
`godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_level_01_r16.gd -gjunit_xml_file=` en `godot/`.

**Resultados (AC2).**
- Antes (sin semilla), 20 ejecuciones seguidas: 14 pasan, 6 fallan (`before.log`).
- Después, 25 ejecuciones seguidas: 25 pasan, 0 fallos (`after.log`).
- Después, con carga: 3 bucles simultáneos de 8 (24 ejecuciones, más otro worker de Godot en
  paralelo): 24 pasan, 0 fallos (`after_load.log`).

**AC3.** `tools/verify.sh` en verde (ver resultado final abajo).
