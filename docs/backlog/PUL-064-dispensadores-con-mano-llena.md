---
id: PUL-064
title: Ignorar los dispensadores cuando el jugador lleva algo en la mano
status: ready
milestone: M2
role: gameplay-engineer
deps: [PUL-062]
orca_task: null
unity_sources: []
owns: [godot/entities/stations/seasoning_dispenser.gd, godot/core/seasoning_rules.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/integration/test_m2b_station_selection.gd, godot/tests/unit/test_seasoning_rules.gd, docs/arch/signals.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/evidence/PUL-064/**]
touches_scenes: []
---

## Target
Hallazgo del QA de PUL-062 (`docs/evidence/PUL-062/README.md`): con una caja en la mano en el lado
de condimentar, a 0,2–0,4 m del centro de la bandeja, el detector resalta Picante o Sal en vez de la
bandeja y al pulsar sale `HAND_BUSY` (5 de 6 intentos al dejar la caja desde el servicio).
Decisión del responsable (2026-10-05): con algo en la mano, los dispensadores **no son objetivo**.
AC8 de `features/estacion-condimentos.md` ya actualizado.

## Change
1. `SeasoningDispenser.can_interact` devuelve `false` con la mano ocupada (el detector no lo
   resalta ni lo elige). El cuenco no cambia (acepta cachelos cocidos en la mano).
2. Quitar o dejar sin uso `HAND_BUSY` en el dispensador; actualizar `signals.md` (§1 y §4, filas de
   `rejected` y secuencia del dispensador) y ADR-003 §8 donde citan `HAND_BUSY`/AC8, como nota de
   enmienda aprobada por el responsable.
3. Tests: AC8 nuevo (con caja en la mano, ningún dispensador es objetivo y la bandeja gana desde
   posiciones a 0,0–0,4 m del centro de la bandeja, desde ambos lados) en `test_m2b_station_selection.gd`
   con el detector real; ajustar los tests de `HAND_BUSY`.

## Constraints
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Con caja en la mano, en el lado de condimentar y a 0–0,4 m lateral del centro de la bandeja, el objetivo es la bandeja (6/6 posiciones) → test con detector real
- [ ] AC2 Con la mano vacía la selección de PUL-063 no cambia (sus tests en verde)
- [ ] AC3 Contratos actualizados (signals.md, ADR-003 §8)
- [ ] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
