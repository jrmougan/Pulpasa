---
id: PUL-063
title: Hacer inequívoca la selección de dispensadores y bandeja en la estación
status: review
milestone: M2
role: gameplay-engineer
deps: [PUL-061]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_station.tscn, godot/entities/stations/seasoning_station.gd, godot/entities/stations/seasoning_dispenser.tscn, godot/entities/stations/seasoning_dispenser.gd, godot/core/interaction_scoring.gd, godot/components/interaction_detector.gd, godot/tests/unit/test_interaction_scoring.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_interaction_detector.gd, godot/tests/integration/test_m2b_station_selection.gd, godot/tests/integration/test_m2b_station_selection.gd.uid, godot/tests/integration/*flow*.gd, godot/tests/integration/test_level_01.gd, godot/tests/integration/level_walker.gd, godot/tests/integration/test_station_level.gd, godot/tests/integration/test_delivery_e2e.gd, godot/scenes/levels/level_01.tscn, docs/evidence/PUL-063/**]
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
- [x] AC1 Test con detector real en `level_01`: desde una posición frontal a cada dispensador (4) y al cuenco, con caja en la bandeja, se selecciona ese objetivo → `test_m2b_station_selection.gd`
- [x] AC2 Desde frente a la bandeja: mano vacía → caja; caja en mano → bandeja; desde ambos lados → mismo test
- [x] AC3 Sin posiciones en diagonal en los tests de flujo
- [x] AC4 Captura del resaltado de cada caso en `docs/evidence/PUL-063/`
- [x] AC5 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
Simulé `InteractionScoring` con la geometría real (jugador a 0,76–1,5 m del centro del mostrador,
±0,15 m de lado, ±10°). **Solo redistribuir no basta**: con la mano vacía la caja gana a cualquier
dispensador en cuyo cono de 30° caiga (prioridad de cogible), y con 4 dispensadores a ≥ 0,9 m y el
cuenco en 4 m siempre queda alguno con la bandeja dentro. Solución A+B, aprobada por el
coordinador (2026-10-05):

- **A · `InteractionScoring` / `InteractionDetector`**: un objeto **guardado en un slot** compite
  por puntuación (`dot·2 + 1/dist`), sin la prioridad de cogible; los objetos sueltos la conservan y
  con la mano llena nada cambia. Campo nuevo `Candidate.in_slot`, que pone el detector al sustituir
  el slot por su objeto. Fuera de la estación solo cambia que un objeto en un pasaplatos ya no roba
  el objetivo a algo mejor apuntado (el «pulpo en un pasaplatos vecino» de PUL-061).
- **B · `seasoning_station.tscn`** (dentro de scene-tree §3): bandeja en x = +0,3 (centro, hacia el
  pase); dispensadores en fila en z = +0,45 (borde de condimentar) a x = −1,25 / −0,35 / +0,95 /
  +1,85 (≥ 0,9 m; hueco de 1,3 m delante de la bandeja, sin flanquearla de cerca); cuenco en −1,8.
- Tests: `test_m2b_station_selection.gd` (AC1, AC2; falla antes del cambio:
  `docs/evidence/PUL-063/repro-antes.txt`); unit de `in_slot` en `test_interaction_scoring.gd` y de
  integración en `test_interaction_detector.gd`; `level_walker.gd` pierde `dispenser_stand` y
  `DISPENSER_SIDESTEP` y los flujos (`test_station_level.gd`, `test_delivery_e2e.gd`) usan
  `station_stand` de frente (AC3); capturas con un script en `docs/evidence/PUL-063/` (AC4).
- owns ampliado con `level_walker.gd`, `test_station_level.gd` y `test_delivery_e2e.gd`.

## Evidence
**Reproducción antes del cambio.** `test_m2b_station_selection.gd` sobre la rama base: 2 de 3 tests
en rojo (147/215 asserts); con caja en la bandeja, de frente a Pimentón picante y Sal el detector
elige la caja, y con la caja en la mano, desde el servicio, gana un dispensador vecino a la bandeja
(`docs/evidence/PUL-063/repro-antes.txt`). Coincide con el hallazgo y la captura de PUL-061.

**Solución (A+B, aprobada por el coordinador).**
- A · `core/interaction_scoring.gd`: `Candidate.in_slot` (nuevo, por defecto `false`). Con la mano
  vacía, un cogible `in_slot` no entra en el cubo de prioridad de cogibles: compite por puntuación
  con los interactuables (con el bonus de cocina igual que antes). Los cogibles sueltos conservan la
  prioridad (`test_ac1_double_pickable_interactable_beats_better_scored_interactable` intacto) y con
  la mano llena nada cambia. `components/interaction_detector.gd` marca `in_slot` al sustituir un
  slot ocupado por su objeto. Documentado en los docstrings de ambos. Ningún test existente cambió.
- B · `seasoning_station.tscn` (dentro de scene-tree §3): bandeja en x = +0,3, z = −0,25;
  dispensadores en z = +0,45 a x = −1,25 / −0,35 / +0,95 / +1,85 (≥ 0,9 m; 1,3 m de hueco delante
  de la bandeja); cuenco sin cambios (−1,8). Por qué hacen falta los dos: con solo B la caja sigue
  robando el objetivo a picante y sal (prioridad de cogible); con solo A, la bandeja a 0,45 m de dos
  dispensadores pierde contra ellos de frente (el término `1/dist` favorece al dispensador, más cerca
  del jugador). Simulación previa: con A+B pasan todos los casos a 0,76–1,2 m del centro del
  mostrador y ±0,1 m de lado, y de frente exacto hasta 1,5 m.

**AC1 y AC2** · `godot/tests/integration/test_m2b_station_selection.gd` (detector real en
`level_01`, personaje colocado de frente a 0,8 / 1,0 / 1,2 m del centro del mostrador y −0,1 / 0 /
+0,1 m de lado; también comprueba que solo el objetivo esté resaltado):
`test_ac1_front_of_each_dispenser_and_bowl_selects_it_with_box_on_tray`,
`test_ac2_front_of_tray_with_empty_hand_selects_the_box_from_both_sides`,
`test_ac2_front_of_tray_with_box_in_hand_selects_the_tray_from_both_sides`. Más:
`test_interaction_scoring.gd::test_pul063_*` (6, regla `in_slot`) y
`test_interaction_detector.gd::test_pul063_*` (2: el objeto guardado pierde contra lo que hay delante;
el suelto conserva la prioridad). Los que prueban el cambio fallan sin él.

**AC3** · `level_walker.gd` pierde `dispenser_stand` y `DISPENSER_SIDESTEP`;
`test_station_level.gd` (AC16/AC17 de la feature) y `test_delivery_e2e.gd` pulsan los
dispensadores de frente con `station_stand` (1,0 m). Ya no queda ninguna posición en diagonal.

**AC4** · `docs/evidence/PUL-063/01…09-*.png` (recorte ×2 a 1280×720, detector real, a 1,0 m de
frente), generadas con `capture_selection.gd` (`xvfb-run -a godot --path godot -s …`):
01–04 cada dispensador y 05 el cuenco, con la caja en la bandeja (resaltado en el objetivo, no en la
caja); 06/07 mano vacía → caja desde condimentar / pase; 08/09 caja en la mano → bandeja (retícula)
desde condimentar / pase.

**AC5** · `tools/verify.sh` en verde (600 tests) y `tools/check_owns.py jrmougan/pul-063
jrmougan/agentica-migracion-godot-alpha` limpio.

**Límites.** Más allá de ~1,5 m del centro del mostrador por el servicio, la bandeja pierde contra
el dispensador más cercano si el jugador no la mira de frente; y girado ≥ 10° hacia un vecino a la
vez que desplazado hacia él, gana ese vecino (es a lo que apunta).
