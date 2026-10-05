---
id: PUL-062
title: Pasar el QA de la estación y la planta B y preparar el playtest
status: done
milestone: M2
role: qa-tester
deps: [PUL-061, PUL-063]
orca_task: task_ece2c63d3ea4
unity_sources: []
owns: [docs/design/m2b-gate.md, godot/tests/integration/test_m2b_flow.gd, godot/tests/integration/test_m2b_flow.gd.uid, docs/evidence/PUL-062/**]
touches_scenes: []
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 7. Cierre de los rediseños del playtest de M2.

## Change
Regresión completa con el MCP (Individual y Local 2P, a ritmo humano), `test_m2b_flow.gd` y guía de
playtest `docs/design/m2b-gate.md`: tiempo medio por comanda con condimentos, pulsaciones de error,
uso del cambio de personaje y preguntas abiertas de la feature (una o dos bandejas, rodeo,
raciones de cachelos, `operator_side_only`).

## Constraints
- Solo QA: lo que falle se reporta al coordinador. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Una partida completa por modo sin errores en consola y con al menos 3 entregas
- [x] AC2 Guía de playtest y capturas
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `tools/verify.sh` de partida (base verde antes de tocar nada).
2. Regresión con el MCP sobre `level_01.tscn` desde el menú, a ritmo humano (teclas mantenidas,
   esperas reales): **Individual** (cambio con Q, cocinero en el pase y servidor en condimentar) y
   **Local 2P** (J1 WASD+E cocina, J2 flechas+Intro condimenta y entrega), ≥ 3 entregas por modo
   y consola sin errores. Anoto tiempos por comanda, rechazos (pulsaciones de error) y cambios de
   personaje; capturas en `docs/evidence/PUL-062/`.
3. `tests/integration/test_m2b_flow.gd`: partida real de `level_01.tscn` con el catálogo real, el
   teclado y el detector reales (`level_walker.gd`): nevera → olla → cortes sobre la caja de la
   bandeja por el pase → dispensadores/cuenco por el lado de condimentar → entrega; 3 comandas en
   Individual (con cambio) y 3 en Local 2P (cada jugador en su lado), sin rechazos.
4. Guía `docs/design/m2b-gate.md` para el responsable: controles, qué probar en Individual y
   Local 2P (teclado+mando, dos mandos), qué anotar (tiempo por comanda, errores, cambio de
   personaje, preguntas abiertas 1–4, `operator_side_only`, paciencia 80–180 s) con los datos de
   referencia de esta QA.
5. Fallos: se reportan al coordinador, sin arreglar fuera de owns.

## Evidence
Detalle en `docs/evidence/PUL-062/README.md`.
- AC1: partidas con el MCP hasta el game over, sin errores de consola del juego: Individual 3
  entregas (22 €, 13 cambios de personaje) y Local 2P 3 entregas en 137 s (registro en
  `registro-partidas-mcp.txt`). `tests/integration/test_m2b_flow.gd`: 3 entregas por modo con
  teclado y detector reales, nevera → olla → cuenco y cortes por el pase → dispensadores (pimentón
  intercambiado) → puesto; sin rechazos, sin caducidades, nadie cruza la barra (≈ 49 s por test).
- AC2: guía `docs/design/m2b-gate.md` (controles, Individual con y sin cambio, Local 2P teclado+mando
  y dos mandos, qué anotar, preguntas abiertas 1–4, `operator_side_only`, paciencia) y capturas
  `individual-*`, `local2p-*`.
- AC3: `tools/verify.sh` verde; `check_owns` limpio.
- Hallazgo para el coordinador: con la caja en la mano y 0,2–0,4 m fuera del centro de la bandeja,
  el detector apunta a Picante/Sal y pulsar da `HAND_BUSY` (5 de 6 veces al dejar la caja desde el
  servicio). Captura `hallazgo-caja-en-mano-apunta-a-picante.png`. No arreglado (fuera de owns).
