---
id: PUL-202
title: Probar la flecha contra la zona anclada y la distancia de los cubos a los puestos
status: review
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
Ficheros: solo los tres tests de `owns`; sin señales nuevas ni código de juego.
- AC1: `test_arrow_keeps_16px_from_button_zone` (test_camera_follow.gd) compara con `_rig._button_zone(canvas)`
  (la zona real de `camera_rig.gd`) crecida `ARROW_GAP_PX`; `test_edge_point_avoids_button_zone`
  (test_camera_follow_math.gd) exige 16 px (antes 15). Error inyectado y revertido en `camera_follow.gd`
  y `camera_rig.gd`.
- AC2: `test_t6_trash_bins_are_far_from_every_target_and_the_gap` (test_trash_bin.gd) añade los
  `OrderStand` hallados por clase con `find_children` (no dependen de grupos) y exige que coincidan en
  número con `Level.stands`. Error inyectado: mover el cubo de servicio a <1,5 m de `OrderStand1`.
- AC3: `tools/verify.sh` completo.

## Evidence
- AC1: docs/evidence/PUL-202/ac1-injected-failure.txt (dos errores inyectados y revertidos: `camera_follow.gd` con hueco 15 px y `camera_rig.gd` sin zona; fallan test_edge_point_avoids_button_zone y test_arrow_keeps_16px_from_button_zone; zona real medida (1818, 777)).
- AC2: ac2-distances.txt (8 distancias cubo-puesto, minima 2,552 m) y ac2-injected-failure.txt (cubo movido a 1,33 m de OrderStand1: falla T6).
- AC3: ac3-verify.txt, verify OK, 1378/1378 tests.
- Nota: el `print` de distancias en T6 es deliberado (AC2). Los puestos se hallan por clase (`find_children`) y se exige que coincidan en numero con `Level.stands`.
