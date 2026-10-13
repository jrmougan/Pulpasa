---
id: PUL-139
title: Triar los pendientes sueltos del roadmap y crear sus fichas
status: in_progress
milestone: M4
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [docs/backlog/PUL-14[2-9]-*.md, docs/evidence/PUL-139/**, docs/backlog/PUL-139-triaje-de-pendientes-sueltos.md]
touches_scenes: []
---

## Target
Los pendientes de `docs/design/roadmap.md` que no tienen ficha: secciones «Pendientes detectados para la
fase 8», «en M1», «en M3» y «en M3b» (defectos D1–D9 del QA de PUL-087, `scene-tree.md` sin
`Bulbs`/`Vignette`, POP del puesto que tapa su número, test FIFO de PUL-029, cachelo crudo/cocido). Muchos
pueden estar ya resueltos por fichas posteriores (PUL-088..138, en especial M3c: PUL-090..103).

## Change
1. Para cada pendiente, comprobar en el código, las escenas, los tests, `docs/arch` y las fichas
   posteriores si sigue vivo (con captura vía MCP cuando sea visual). Resultado: **resuelto** (con la
   ficha o commit que lo resolvió), **vivo** o **obsoleto** (el diseño ya no lo tiene).
2. Por cada pendiente vivo, o grupo coherente, una ficha `draft` con el formato de `_TEMPLATE.md`
   (Target, Change, Constraints, Acceptance con números y test o captura; `owns` y `touches_scenes`
   mínimos y sin solaparse entre ellas), con ids **PUL-142 a PUL-149**. Hito `M4` salvo que proceda otro.
   Lo que sea balance o audio para escucha humana va como nota en la tabla, no como ficha.

## Constraints
- Solo documentación: no se toca código, escenas, datos ni contratos.
- **No edites** `docs/backlog/README.md` ni `docs/design/roadmap.md`: los actualiza el coordinador al
  mergear. Usa solo los ids PUL-142..149 (otros workers crean fichas en paralelo con otros rangos).
- Si un pendiente necesita una decisión de diseño o un cambio de contrato, la ficha lo dice y queda
  en `draft` con la pregunta explícita.

## Acceptance
- [ ] AC1 `docs/evidence/PUL-139/README.md` tiene una tabla con cada pendiente, su estado
  (resuelto/vivo/obsoleto) y la prueba (ficha, commit, fichero:línea o captura).
- [ ] AC2 Cada pendiente vivo tiene ficha `draft` PUL-142..149 o una nota de por qué no la lleva.
- [ ] AC3 `tools/verify.sh --quick` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
