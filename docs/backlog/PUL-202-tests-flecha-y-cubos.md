---
id: PUL-202
title: Probar la flecha contra la zona anclada y la distancia de los cubos a los puestos
status: ready
milestone: M4
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_camera_follow.gd, godot/tests/unit/test_camera_follow_math.gd, godot/tests/integration/test_trash_bin.gd]
touches_scenes: []
---

## Target
Tests de cámara y de `TrashBin`. Solo tests (G37, G13, G57).

## Change
- `test_arrow_keeps_16px_from_button_zone` compara con un rectángulo fijo (x ≥ 1950, y ≥ 600), y la zona anclada real empieza en (1818, 777) con esos márgenes: comparar con la zona que usa `camera_rig.gd`.
- `test_camera_follow_math.gd:129` pasa `gap` 16 pero comprueba con `avoid.grow(15.0)`: exigir los 16 px o decir por qué no.
- `test_t6_trash_bins_are_far_from_every_target_and_the_gap` recorre el grupo `interactable`, del que `OrderStand` salió por D26: incluir los puestos, para que la regla de colocación de los cubos (≥ 1,5 m) quede probada.

## Constraints
No toques código de juego. Si un test revela un fallo real, no lo tapes: status=blocked con la evidencia.

## Acceptance
- [ ] AC1 Given la zona anclada real, When la flecha se acerca, Then el test falla si entra en ella → prueba con un error inyectado y revertido en docs/evidence/PUL-202/
- [ ] AC2 Given `level_01.tscn`, When corre T6, Then mide la distancia a cada `OrderStand` → salida en docs/evidence/PUL-202/
- [ ] AC3 Given la suite, When `tools/verify.sh`, Then verde → docs/evidence/PUL-202/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
