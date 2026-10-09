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
- [ ] AC1 R15: Individual sin cambio, pedido S desde cero ≤ 50 m (NO CUMPLE: 63,7 m el mejor caso, 74,4 m con los pasaplatos del oeste; ver Evidence)
- [x] AC2 R17: Coop, media de pedidos 2–4 ≤ 4,6 s del bot; tabla antes/después (4,31 s con el bot que adelanta el trabajo; 7,33 s con el protocolo secuencial, ver Evidence)
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

**AC1 R15: NO se cumple.** Individual sin cambio, S sal+aceite desde cero, metros de P1: PUL-090 78,9 m;
ahora 74,4 m con `PassSlot01/02` (junto al rack) y **63,7 m** con `PassSlot04/05` (este del hueco), el
mejor caso del bot. Tramos del mejor caso: inicio → rack 9,7 · rack → pasaplatos 10,1 · pasaplatos →
nevera por el hueco 12,8 · olla 3,1 · olla → pasaplatos 6,9 · sobrante 1,1 · volver y coger la caja 6,3 ·
dispensadores 5,4 · zona ≈ 7,9. Sin los 9,7 m iniciales son 54,0 m. Pasos: `run_measure.gd -- solo
PassSlot04 PassSlot05`, escenario `solo` / `S`, pedido 1, campo `meters_p1` y `legs`. Pedido 2: 36,8 m.

**AC2 R17: se cumple con matiz.** Coop, 4 pedidos S sal+aceite, media de los pedidos 2–4: `chain_pipe`
(oeste) **4,31 s** (11,58 / 4,63 / 4,47 / 3,83 s) frente al límite 4,6 s (75 % de los 6,08 s de PUL-090).
El matiz: solo con el bot que adelanta cajas y ollas y con los pasaplatos del oeste; con el protocolo
secuencial de PUL-090 repetido (`chain_seq`) la media es **7,33 s** (el pedido 3 espera 5 s de cocción)
y con pasaplatos al este 6,15 s (pipe) / 8,95 s (seq). Con el protocolo de 2 pedidos, Coop S pedido 2
6,08 → 5,07 s (−17 %); pedido 1 empeora 10,52 → 11,52 s. Pulsaciones L 29 → 19, M 19 → 15, S 14 → 13;
cuenco: pedido 2 con cachelos 13,2 → 5,5 s (Coop).

**AC3: se cumple.** `tools/verify.sh` completo en verde (GUT 69 scripts, 779 tests, 24139 asserts).
Partidas cortas Individual y Local 2P con el MCP godot: 0 errores (`ac3-*.png`); el bot jugó más de 60
pedidos sin errores. `docs/design/m3c-gate.md` escrito (preguntas de legibilidad del cuenco 2 vs 4,
ticket recortado, chevrones de entrega hacia la cocina, R11 y las dos decisiones de R15/R17).

**Hallazgos de revisión**
1. Cuenco 2 vs 4: confirmado, diferencia mínima a 1280×720 (`ac1-cuenco-2-vs-4-raciones.png`).
2. `fill_per_press` 0.16666667: con el dato actual el pulpo SÍ se libera tras 2 cajas (6 + 6 cortes,
   resto 0). Falla si se redondea a la baja: 0.16666666 deja 0,000004 y 0.166666 deja 0,0004 y el pulpo
   no se libera. Latente, para PUL-104 (`finding2_fill_rounding.gd` / `.log`).
3. `user://` compartido: una sola carpeta `app_userdata/Pulpasa`; ningún script del repo mata Godot por
   nombre. No se reproduce sin matar procesos ajenos (no se intentó); 6 Godot en paralelo + verify sin
   interferencia, solo PIDs propios.
4. Ticket recortado: confirmado «Pulpo Individ…» (`ac3-individual-ticket-recortado-chevrones.png`);
   decisión en el playtest.
