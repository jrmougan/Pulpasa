---
id: PUL-162
title: Cerrar el diseño del tutorial breve para la alpha
status: draft
milestone: M4
role: game-designer
deps: []
orca_task: null
unity_sources: []
owns: [docs/design/features/tutorial-breve.md, docs/evidence/PUL-162/**, docs/backlog/PUL-162-cerrar-el-diseno-del-tutorial.md]
touches_scenes: []
---

## Target
Should «tutorial breve» (`features/tutorial-breve.md`, AC1–AC8 con D25/D26). Falta decidir cómo se entra y
sale de él y cómo se comporta en Local 2P y en el perfil táctil con D27 (botones en fila).

## Change
1. Flujo: ¿se lanza solo en la primera partida, desde un botón del menú, o ambos? ¿Qué pasa al terminar
   (partida normal desde 0 s o vuelta al menú)? ¿Se puede volver a ver (opción «repetir tutorial»)?
2. Local 2P: qué jugador hace cada paso y cómo avanza el paso «cooperar».
3. Paso a paso con su condición de avance (señal de `signals.md` que lo dispara) y el objetivo que se
   resalta, para que PUL-163 fije el contrato sin adivinar.
4. Datos: configuración de la fase de tutorial (receta, paciencia, sin penalización) en `.tres`.

## Constraints
- Solo `docs/design/`. Las señales nuevas, si hacen falta, se proponen aquí y las decide PUL-163.
- Si el responsable deja el tutorial fuera de la alpha (pregunta P5), la ficha se cierra registrándolo.

## Acceptance
- [ ] AC1 Tabla de los 6 pasos: texto, verbo, objetivo resaltado, señal que lo completa, ≤ 0,5 s al siguiente.
- [ ] AC2 Flujo de entrada/salida y persistencia de «tutorial hecho» con AC numéricos y su test.
- [ ] AC3 Comportamiento en Individual, Local 2P y táctil (D26, D27) sin contradicciones con `controles-tactiles.md`.
- [ ] AC4 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
