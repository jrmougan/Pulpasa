---
id: PUL-143
title: Cubrir con un test la posición de las plazas de la olla
status: in_progress
milestone: M4
role: gameplay-engineer
deps: []
orca_task: null
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
- [ ] AC1 Given capacidad N (la de `kitchen.tres` y 3) Then las anclas de las plazas están a
  `SLOT_SPACING` (0,3 m ± 0,001) entre sí en X, centradas en el ancla base (media de X = X base ± 0,001)
  y con la misma Y y Z → `test_cooking_slots_layout.gd`.
- [ ] AC2 Given dos pulpos metidos en orden Then cada uno queda sobre el ancla de su plaza
  (`AnchorPoint` del ingrediente sobre el ancla de la plaza i, `is_equal_approx`) → `test_cooking_slots_layout.gd`.
- [ ] AC3 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
