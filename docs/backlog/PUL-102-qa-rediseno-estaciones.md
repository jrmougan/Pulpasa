---
id: PUL-102
title: Medir el rediseño de estaciones y preparar el playtest
status: review
milestone: M3c
role: qa-tester
deps: [PUL-101]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-102/**, docs/design/m3c-gate.md, docs/backlog/PUL-102-qa-rediseno-estaciones.md]
touches_scenes: []
---

## Target
Rama de integración tras PUL-097..PUL-101.

## Change
Adapta `docs/evidence/PUL-090/measure_flow.gd` (copia en tu evidencia) al flujo nuevo y compara con `PUL-090/metrics.json`. Regresión con `tools/verify.sh` y partida corta en Individual y Local 2P sin errores. Escribe `docs/design/m3c-gate.md` con qué probar en el playtest humano.

Hallazgos de revisión a comprobar en QA: (1) el cuenco con 2 y con 4 raciones casi no se distingue desde la cámara (arte de PUL-094); (2) `fill_per_press` de M es 0.16666667: si se redondea a la baja, el pulpo no llega a 0 y no se libera, porque `Ingredient.take` compara `remaining <= 0.0` sin épsilon. Lo corrige PUL-104; (3) los Godot de varios worktrees comparten `user://` (`app_userdata/Pulpasa`); la caída de un `verify.sh` en paralelo la causó un `taskkill /IM godot.exe` de otro worker, así que no hay que matar Godot por nombre de imagen; (4) el ticket mantiene 212 px y recorta nombres largos («Pulpo Individ…»): validar en el playtest si se entiende o hace falta un nombre corto en `RecipeData`.

## Constraints
No cambies código del juego; los fallos se reportan con pasos. Godot con `--audio-driver Dummy` (MCP: silencia los buses).

## Acceptance
- [ ] AC1 R15: Individual sin cambio, pedido S desde cero ≤ 50 m (NO CUMPLE con el bot: 55,0 m la mejor ruta, 45,3 m sin la salida inicial; ver Evidence)
- [ ] AC2 R17: Coop, media de pedidos 2–4 ≤ 4,6 s del bot; tabla antes/después (pendiente del gate humano: 4,09 s solo con el bot adelantado, que PUL-090 nunca midió; ver Evidence)
- [x] AC3 Partidas sin errores y `m3c-gate.md` listo

## Plan
1. Copiar `PUL-090/measure_flow.gd` a `docs/evidence/PUL-102/` y reescribir el flujo: caja del rack a un
   pasaplatos, corte en el pasaplatos por el lado de pase, caja en la mano a los dispensadores (orden
   por x), entrega entrando en la zona (Z local 3,40), cuenco de 2 raciones. Mismos escenarios y
   columnas que PUL-090, más `chain_seq` y `chain_pipe` para R17 y tramos por pieza (`legs`) para R15.
2. Medir Solo / cambio / Coop (S, M, L, S+cachelos) y las cadenas de 4 pedidos, con los pasaplatos del
   oeste (junto al rack) y del este (tras el hueco); `metrics.json` nuevo y tabla antes/después.
3. Hallazgo 2 con un script de evidencia sobre la `Box` y el `Ingredient` reales.
4. `tools/verify.sh` completo y partidas cortas Individual y Local 2P con el MCP godot.
5. `docs/design/m3c-gate.md` con las preguntas del playtest humano.

## Evidence
Detalle, tablas completas y reproducción: `docs/evidence/PUL-102/README.md`. Todo medido con el bot
(teclado y detector reales, tiempos de cota inferior), sin tocar código del juego ni escenas.

**AC1 R15: NO se cumple con el bot.** Individual sin cambio, S sal+aceite desde cero, metros de P1 en el
pedido 1 (PUL-090: 78,9 m; incluye 9,7 m de salir de la posición inicial hasta el rack): caja en el
pasaplatos 01 73,3 m, en el 03 66,7 m, en el 04 61,0 m, y **caja soltada en el suelo de la cocina junto a
las ollas 55,0 m** (la ruta que estimó el revisor, medida; suelo junto al hueco 61,4 m). Tramos de los 55,0
m: rack 9,7 · llevar la caja al suelo (por el hueco) 16,3 · nevera 3,2 · olla 3,1 · cortar 1,8 · sobrante 0,5
· coger caja 0,5 · aceite 11,1 · sal 1,1 · zona 3,4. Sin los 9,7 m iniciales son 45,3 m (≤ 50), por lo que
el veredicto depende de si el criterio cuenta la salida inicial; con el criterio de PUL-090 no cumple, por
5 m. El bot ordena ahora los dispensadores por menor recorrido y entra directo a la zona. Pasos:
`run_measure.gd -- solo floor`, escenario `solo` / `S`, pedido 1, `meters_p1` y `legs`.

**AC2 R17: pendiente del gate humano.** Coop, 4 pedidos S sal+aceite: `chain_pipe` (bot adelantado, pasaplatos
oeste) 4,09 s de media en los pedidos 2–4 (11,25 / 4,42 / 4,23 / 3,62), bajo el límite 4,6 s. La
comparación no es homogénea: PUL-090 solo midió el protocolo secuencial, y el flujo adelantado nunca se
midió con el flujo antiguo; con el protocolo secuencial el pedido 2 da 4,85 s (80 %, no el 75 % de R17) y
la cadena `chain_seq` 7,08 s. Por eso no se marca. Pulsaciones L 29 → 19, M 19 → 15, S 14 → 13; cuenco:
pedido 2 con cachelos 13,2 → 5,3 s (Coop); Coop pedido 1 empeora (10,52 → 11,2 s).

**AC3: se cumple.** `tools/verify.sh` completo en verde (GUT 69 scripts, 779 tests, 24139 asserts).
Partidas cortas Individual y Local 2P con el MCP godot: 0 errores (`ac3-*.png`); el bot jugó más de 60
pedidos sin errores. `docs/design/m3c-gate.md` escrito (preguntas de legibilidad del cuenco 2 vs 4,
ticket recortado, chevrones de entrega hacia la cocina, R11 y las decisiones de R15/R17).

**Hallazgos de revisión**
1. Cuenco 2 vs 4: confirmado, diferencia mínima a 1280×720 (`ac1-cuenco-2-vs-4-raciones.png`).
2. `fill_per_press` 0.16666667: con el dato actual el pulpo SÍ se libera tras 2 cajas (6 + 6 cortes,
   resto 0). Falla si se redondea a la baja: 0.16666666 deja 0,000004 y 0.166666 deja 0,0004 y el pulpo
   no se libera; con 0.1666 y 0.16 el pulpo no llena dos cajas M (0,9996 y 0,96). Latente, para PUL-104
   (`finding2_fill_rounding.gd` / `.log`).
3. `user://` compartido: una sola carpeta `app_userdata/Pulpasa`; ningún script del repo mata Godot por
   nombre. No se reproduce sin matar procesos ajenos (no se intentó); 6 Godot en paralelo + verify sin
   interferencia, solo PIDs propios.
4. Ticket recortado: confirmado «Pulpo Individ…» (`ac3-individual-ticket-recortado-chevrones.png`);
   decisión en el playtest.
