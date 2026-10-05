---
id: PUL-063
title: Hacer inequívoca la selección de dispensadores y bandeja en la estación
status: ready
milestone: M2
role: gameplay-engineer
deps: [PUL-061]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/seasoning_dispenser.gd, godot/core/interaction_scoring.gd, godot/components/interaction_detector.gd, godot/tests/unit/test_interaction_scoring.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_interaction_detector.gd, godot/tests/integration/test_m2b_station_selection.gd, godot/tests/integration/test_m2b_station_selection.gd.uid, godot/tests/integration/*flow*.gd, godot/tests/integration/test_level_01.gd, godot/scenes/levels/level_01.tscn, docs/evidence/PUL-063/**]
touches_scenes: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_dispenser.tscn, godot/scenes/levels/level_01.tscn]
---

## Target
Hallazgo de PUL-061 (ver su Evidence): con una caja en la bandeja de la estación, desde el lado de
condimentar el detector elige la **caja** en vez de los dispensadores de sal y pimentón picante al
mirarlos de frente (`InteractionScoring` prioriza cogibles con la mano vacía; la bandeja queda a
0,45 m en x y entra en el cono de 30°). Solo se usan colocándose en diagonal. Con caja en la mano,
desde el servicio la bandeja solo gana en una franja estrecha. Es justo la incomodidad que D18
quería quitar.

## Change
Que, a distancia y ángulo naturales (de frente, a ~0,8–1,2 m), el jugador seleccione siempre lo que
tiene delante:
- de frente a un dispensador (mano vacía, lado de condimentar) → ese dispensador, aunque haya caja
  en la bandeja;
- de frente a la bandeja (mano vacía) → la caja; con caja en la mano → la bandeja.
Elige y justifica la solución (redistribuir la estación —p. ej. bandeja hacia el pase y
dispensadores en fila sin flanquearla—, prioridad por objetivo en `InteractionScoring`, o ambas).
Si tocas `InteractionScoring`, que no cambie la selección en el resto de estaciones (tests
existentes en verde). Quita los workarounds de posición en diagonal de los tests de PUL-061.

## Constraints
- Contratos de ADR-003 §8 y feature `estacion-condimentos` (AC7, AC9). Si la solución cambia un
  contrato, pregunta al coordinador antes.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Test con detector real en `level_01`: desde una posición frontal a cada dispensador (4) y al cuenco, con caja en la bandeja, se selecciona ese objetivo → `test_m2b_station_selection.gd`
- [ ] AC2 Desde frente a la bandeja: mano vacía → caja; caja en mano → bandeja; desde ambos lados → mismo test
- [ ] AC3 Sin posiciones en diagonal en los tests de flujo
- [ ] AC4 Captura del resaltado de cada caso en `docs/evidence/PUL-063/`
- [ ] AC5 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
