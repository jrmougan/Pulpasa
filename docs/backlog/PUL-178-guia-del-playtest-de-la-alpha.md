---
id: PUL-178
title: Escribir la guía del playtest y el criterio de publicación de la alpha
status: draft
milestone: M4
role: game-designer
deps: [PUL-165]
orca_task: null
unity_sources: []
owns: [docs/design/m4-gate.md, docs/evidence/PUL-178/**, docs/backlog/PUL-178-guia-del-playtest-de-la-alpha.md]
touches_scenes: []
---

## Target
Puerta humana «Publicar alpha» de M4 (`roadmap.md`). Modelos: `m3c-gate.md`, `m3d-gate.md` y la guía de
M3e (PUL-15x). Criterio de «alpha publicada»: pregunta P4 del plan de M4, que decide el responsable.

## Change
`docs/design/m4-gate.md`: (1) lista de comprobación de publicación (Must 1–11 de la alpha con su prueba:
test, evidencia de PUL-176/177 o playtest), (2) guion del playtest con jugadores (cuántos, con qué build,
qué modos, qué medir: estrellas, comandas por partida, momentos de confusión, uso del tutorial) y hoja de
notas, (3) qué decide el responsable al final (publicar, otra vuelta de balance, fichas nuevas).

## Constraints
- Solo `docs/design/`: no escribe resultados ni decide por el responsable.
- Lo que siga sin respuesta de P4 (dónde y para quién se publica) queda como pregunta en la guía.

## Acceptance
- [ ] AC1 Cada Must de la alpha tiene una fila con cómo se comprueba y dónde está la prueba.
- [ ] AC2 Guion del playtest ≤ 45 min por sesión, con preguntas cerradas y métricas numéricas.
- [ ] AC3 Sección de decisión con las salidas posibles y qué ficha dispara cada una.
- [ ] AC4 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
