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
- [ ] AC1 Given los 11 Must de la alpha (`roadmap.md`), When se escribe la lista de publicación, Then hay 11 filas con cómo se comprueba y
  dónde está la prueba (test, evidencia de PUL-176/177 o playtest), 0 filas sin prueba → tabla en `docs/design/m4-gate.md`.
- [ ] AC2 Given el guion del playtest, When se cronometra sobre el papel, Then cada sesión dura ≤ 45 min, usa los `.zip` cuyo SHA-256 figura en
  el manifiesto de PUL-176 y pide ≥ 5 métricas numéricas (estrellas, entregas, caducadas, tiempo del tutorial, nº de dudas) → guion y hoja de notas en `m4-gate.md`.
- [ ] AC3 Given la sección de decisión, When se lee, Then lista ≥ 3 salidas (publicar, otra vuelta de balance, fichas nuevas) con la ficha que
  dispara cada una, y P4 figura como pregunta si sigue abierta → sección en `m4-gate.md`, comprobación en `docs/evidence/PUL-178/README.md`.
- [ ] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-178/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
