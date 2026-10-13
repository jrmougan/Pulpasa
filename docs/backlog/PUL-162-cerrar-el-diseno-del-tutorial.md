---
id: PUL-162
title: Cerrar el diseño del tutorial breve para la alpha
status: done
milestone: M4
role: game-designer
deps: []
orca_task: task_9d0d38e3c103
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
- [x] AC1 Given `tutorial-breve.md`, When se lee la tabla de pasos, Then hay 6 filas con texto, verbo, objetivo resaltado, señal de
  `signals.md` (o propuesta para ADR-007) que lo completa y avance ≤ 0,5 s → tabla en la feature, enlazada desde la evidencia.
- [x] AC2 Given P5 (cómo se entra al tutorial), When G0 no la ha respondido, Then la feature describe las 3 opciones (a: automático en la
  primera partida, b: botón «Tutorial» en el menú, c: ambas) con sus AC y su coste, marcadas como **propuesta**; si G0 la ha respondido, solo
  la elegida → sección «Entrada y salida» revisada en la evidencia.
- [x] AC3 Given los perfiles Individual, Local 2P y táctil, When se cruzan con `controles-tactiles.md` (D26, D27), Then hay ≥ 1 AC numérico por
  perfil y 0 contradicciones (lista de los AC cruzados) → `docs/evidence/PUL-162/README.md`.
- [x] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-162/README.md`.

## Plan
1. Leer D25–D27, `signals.md` §2, `controles-tactiles.md`, `dificultad-progresiva.md`, P5 de PUL-141 y las
   fichas consumidoras (163, 169, 174, 175).
2. Reescribir `tutorial-breve.md`: estado inicial, tabla de 6 pasos con señal y objetivo, señal nueva
   propuesta (S1), «Entrada y salida» con las 3 opciones como propuesta (G0 no ha respondido P5),
   perfiles, AC por perfil y datos `.tres`.
3. Cruzar con `controles-tactiles.md` y dejar la tabla en la evidencia; `verify.sh --quick` y `check_owns.py`.

## Evidence
`docs/evidence/PUL-162/README.md`: tabla de pasos y señales (AC1), opciones de entrada como propuesta y
coste (AC2), AC por perfil y cruce con `controles-tactiles.md` sin contradicciones (AC3), salida de
`verify.sh --quick` y `check_owns.py` (AC4). Para el producer: (b)/(c) exigen enmendar `menu-principal.md`
AC6 y `controles-tactiles.md` AC1; PUL-175 AC1 limita (a) a Individual y la feature propone también Local 2P.

**Ronda 2 (revisión Codex, CHANGES):** paso 3 enseña a soltar o tirar las 50 u sobrantes antes de coger
la caja; paso 6 en Local 2P pasa a la señal propuesta S2 `item_handed_over` (hecho de transferencia del
`PassSlot`); E-c conserva solo la condición automática de E-a y la entrada manual de E-b; los aros de
AC8 se anclan al botón real con safe area nula y de diseño (ADR-005 D27.1), recogido en el cruce de AC3.
