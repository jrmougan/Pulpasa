---
id: PUL-175
title: Montar el tutorial en level_01 y el flujo de primera partida
status: draft
milestone: M4
role: gameplay-engineer
deps: [PUL-167, PUL-174]
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/level.gd*, godot/tests/integration/test_tutorial.gd*, godot/tests/integration/test_level_01*.gd*, docs/evidence/PUL-175/**, docs/backlog/PUL-175-montar-el-tutorial-en-level-01.md]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
Única ficha de integración de M4 que toca `level_01.tscn`. Flujo de `features/tutorial-breve.md` (PUL-162),
contrato de ADR-007 (PUL-163), núcleo (PUL-169), panel (PUL-174) y estado «tutorial hecho» en ajustes (PUL-167).
Recoge también los textos del mundo que PUL-168 haya anotado como pendientes de clave.

## Change
Instanciar el panel y el núcleo del tutorial en el nivel según `scene-tree.md`, configurar la fase de
tutorial, resaltar el objetivo de cada paso y lanzar el tutorial según el flujo aprobado (primera partida
y/o botón del menú).

## Constraints
- Sin rutas absolutas de nodos; comunicación por `EventBus`.
- Con el tutorial «hecho» o saltado, la partida es idéntica a la de antes (sin regresión de `test_level_01*`).

## Acceptance
- [ ] AC1 Given un perfil sin «tutorial hecho», When se empieza una partida Individual, Then arranca el tutorial
  con «Á feira» y 90 s de paciencia → `test_tutorial.gd`.
- [ ] AC2 Given el bot recorriendo los 6 pasos, Then el tutorial termina en ≤ 90 s y queda «hecho» → `test_tutorial.gd`.
- [ ] AC3 Given «tutorial hecho», Then la siguiente partida empieza normal en fase 1 a 300 s → `test_tutorial.gd`.
- [ ] AC4 Given el perfil táctil y Local 2P, Then se cumple el comportamiento de PUL-162 → `test_tutorial.gd` + capturas.
- [ ] AC5 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
