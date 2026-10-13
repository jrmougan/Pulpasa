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
tutorial y resaltar el objetivo de cada paso. Cómo se entra **depende de G0** (P5, opciones de PUL-162):
(a) automático en la primera partida, (b) solo desde el botón «Tutorial» del menú (el botón es de PUL-171; aquí
solo se atiende la petición por la API de ADR-007) o (c) ambos. Esta ficha implementa la opción aprobada; las
otras no se hacen.

## Constraints
- Sin rutas absolutas de nodos; comunicación por `EventBus`. `main_menu.tscn` no se toca (es de PUL-171/172).
- Con el tutorial «hecho», saltado o no pedido, la partida es idéntica a la de antes (sin regresión de `test_level_01*`).

## Acceptance
- [ ] AC1 Given la opción de entrada aprobada en G0, When se cumple su disparador (a: perfil sin «tutorial hecho» y partida Individual;
  b: petición del botón del menú; c: cualquiera de los dos), Then arranca el tutorial con «Á feira» y 90 s de paciencia en ≤ 3 s; y Given
  un disparador **no** aprobado, Then la partida empieza normal → `test_tutorial.gd`.
- [ ] AC2 Given el bot recorriendo los 6 pasos, When completa el último, Then el tutorial termina en ≤ 90 s y queda «hecho» en ajustes → `test_tutorial.gd`.
- [ ] AC3 Given «tutorial hecho» (o la opción b sin petición), When empieza una partida, Then está en fase 1 con el reloj a 300 s y 2 puestos activos → `test_tutorial.gd`.
- [ ] AC4 Given el perfil táctil y Local 2P, When se lanza el tutorial, Then se cumplen los AC por perfil de PUL-162 → `test_tutorial.gd` + capturas a 1920×1080 y 2340×1080.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-175/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
