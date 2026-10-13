---
id: PUL-143
title: Cubrir con un test la posición de las plazas de la olla
status: done
milestone: M4
role: gameplay-engineer
deps: []
orca_task: task_61fdcfe3d6f4
unity_sources: []
owns: [godot/tests/integration/test_cooking_slots_layout.gd*, docs/evidence/PUL-143/**, docs/backlog/PUL-143-test-de-posicion-de-las-plazas-de-la-olla.md]
touches_scenes: []
---

## Target
Pendiente de M1 (PUL-029): «sin test de la posición de las plazas». `entities/stations/cooking_station.gd`
(líneas 106-139 en `ac249d1`) reparte las anclas de las plazas a lo ancho con `SLOT_SPACING = 0.3` y
coloca un anillo de progreso por plaza; hoy solo se comprueba el ancla de la plaza 0
(`test_ac2_octopus_anchor_point_sits_on_pot_anchor`). La separación de los **anillos** ya la cubre
`test_d26_cook_rings_follow_the_mobile_camera_zoom` (`tests/integration/test_level_01.gd`, PUL-131:
espaciado = 64 px × `RING_SPACING_RATIO` a la cámara móvil); falta la distribución de las **anclas**
(dónde queda cada ingrediente), que es lo que pide esta ficha.

## Change
Un fichero de test nuevo que fije la colocación de las plazas con la capacidad de `data/config/kitchen.tres`
y con una capacidad forzada de 3, sin tocar código de juego.

## Constraints
- Solo tests: no se cambia `cooking_station.gd`, `kitchen.tscn` ni datos. Si un test revela un fallo,
  se apunta en Evidence y se escala al coordinador (ficha aparte).
- Tipado estático; patrón de `tests/integration/test_cooking_station.gd` para instanciar la cocina.

## Acceptance
- [x] AC1 Given capacidad N (la de `kitchen.tres` y 3) Then las anclas de las plazas están a
  `SLOT_SPACING` (0,3 m ± 0,001) entre sí en X, centradas en el ancla base (media de X = X base ± 0,001)
  y con la misma Y y Z → `test_cooking_slots_layout.gd`.
- [x] AC2 Given dos pulpos metidos en orden Then cada uno queda sobre el ancla de su plaza
  (`AnchorPoint` del ingrediente sobre el ancla de la plaza i, `is_equal_approx`) → `test_cooking_slots_layout.gd`.
- [x] AC3 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
- Fichero nuevo `godot/tests/integration/test_cooking_slots_layout.gd` (patrón de `test_cooking_station.gd`:
  jugador + `kitchen.tscn` bajo un `Node3D`). Sin cambios de juego, escenas ni datos.
- Capacidad forzada: se instancia `kitchen.tscn`, se sustituye `data` por una copia (`duplicate()`) con
  `capacity = 3` antes de `add_child` (antes de `_ready`), sin tocar `kitchen.tres`.
- «Ancla base» = posición local de `AnchorPoint` en la escena, leída de una instancia que no entra en el árbol.
- Anclas de cada plaza: `_kitchen._slots[i].anchor` (mismo acceso que `test_ac1_pause_freezes_two_slots`).
- AC1 → `test_ac1_slot_spacing_constant_is_0_3_m`, `test_ac1_kitchen_data_capacity_is_spread_and_centered`, `test_ac1_forced_capacity_three_is_spread_and_centered`.
- AC2 → `test_ac2_two_octopuses_sit_on_their_slot_anchors` (+ variante con capacidad 3).
- AC3 → `tools/verify.sh` completo y `tools/check_owns.py`.

## Evidence
- `tools/verify.sh` completo en verde: 1341/1341 tests, smoke OK (`docs/evidence/PUL-143/gut.txt`).
  El único warning del run es ajeno (`FeedbackPlayer: cue desconocida no_existe`, test de feedback).
- Los 5 tests nuevos pasan; ninguno reveló fallo en `cooking_station.gd`.
- Notas para el responsable (no son fallos, no se cambia nada):
  - `_ready` sobrescribe la X del `%AnchorPoint` con `start_x + i·SLOT_SPACING` (centrado en 0, no en la X
    de la escena). Hoy coincide porque la X de la escena es 0; si alguien moviera el ancla en X en
    `kitchen.tscn`, AC1 fallaría (el test lo vigila).
  - `_reposition_anchors` solo recoloca las plazas ocupadas: con una sola pieza su ancla va al centro y
    las libres conservan su X anterior (pueden coincidir con la ocupada). Es el diseño documentado
    («con una sola pieza queda en el centro de la olla»); AC2 se comprueba con dos piezas.
- Revisión (Codex, P2): el esperado ya no reutiliza `CookingStation.SLOT_SPACING`; el test fija
  `EXPECTED_SPACING = 0.3` y comprueba la constante contra ese valor (`test_ac1_slot_spacing_constant_is_0_3_m`).
