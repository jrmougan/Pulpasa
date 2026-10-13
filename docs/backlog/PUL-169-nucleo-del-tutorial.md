---
id: PUL-169
title: Núcleo del tutorial y su fase en datos
status: draft
milestone: M4
role: gameplay-engineer
deps: [PUL-163]
orca_task: null
unity_sources: []
owns: [godot/core/tutorial_steps.gd*, godot/resources/tutorial_data.gd*, godot/data/config/tutorial.tres, godot/tests/unit/test_tutorial_steps.gd*, godot/tests/unit/test_data_tutorial.gd*, docs/evidence/PUL-169/**, docs/backlog/PUL-169-nucleo-del-tutorial.md]
touches_scenes: []
---

## Target
`features/tutorial-breve.md` (cerrada en PUL-162) y ADR-007 (PUL-163), parte de tutorial. Rutas de `owns`
provisionales hasta ADR-007.

## Change
Núcleo `RefCounted` con los 6 pasos, su condición de avance por señal, «Saltar» y el estado «hecho»; datos
del tutorial (receta «Á feira», paciencia 90 s, sin penalización) en `.tres`.

## Constraints
- Sin UI ni escena: el panel es PUL-174 y el montaje PUL-175.
- Solo señales del catálogo de `signals.md` (ADR-007).

## Acceptance
- [ ] AC1 Given los 6 pasos, When llega la señal de cada uno en orden, Then avanza al siguiente en el mismo
  frame (≤ 0,5 s con la UI) y uno fuera de orden no avanza → `test_tutorial_steps.gd`.
- [ ] AC2 Given el paso de aliñar, When se aplica el picante, Then no avanza y expone el texto de ayuda (AC6) → `test_tutorial_steps.gd`.
- [ ] AC3 Given «Saltar» o el paso 6 completo, Then el estado queda «hecho» para el núcleo de ajustes → `test_tutorial_steps.gd`.
- [ ] AC4 Given `tutorial.tres`, Then solo genera «Á feira» con 90 s y penalización 0 (AC4–AC5) → `test_data_tutorial.gd`.
- [ ] AC5 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
