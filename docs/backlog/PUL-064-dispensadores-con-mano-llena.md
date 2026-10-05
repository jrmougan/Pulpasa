---
id: PUL-064
title: Ignorar los dispensadores cuando el jugador lleva algo en la mano
status: review
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
- [x] AC1 Con caja en la mano, en el lado de condimentar y a 0–0,4 m lateral del centro de la bandeja, el objetivo es la bandeja (6/6 posiciones) → test con detector real
- [x] AC2 Con la mano vacía la selección de PUL-063 no cambia (sus tests en verde)
- [x] AC3 Contratos actualizados (signals.md, ADR-003 §8)
- [x] AC4 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `seasoning_dispenser.gd`: `is_reachable_from` devuelve `false` con la mano ocupada (el detector solo consulta este método, no `can_interact`); `can_interact` también `false`; se quita `HAND_BUSY` de `_toggle`.
- `seasoning_rules.gd`: `HAND_BUSY` se mantiene en el enum (sin renumerar) marcado en desuso.
- Tests: AC8 nuevo en `test_m2b_station_selection.gd` (detector real); los de `HAND_BUSY` en `test_seasoning_station.gd` pasan a «no es objetivo / sin rechazos».
- Contratos: `signals.md` (§1, §4, secuencia) y ADR-003 (§8.1, §8.2, §8.3) como enmienda PUL-064.

## Evidence
- AC1: `test_m2b_station_selection.gd::test_ac8_box_in_hand_no_dispenser_is_target_and_tray_wins_near_tray_centre`: caja en la mano, desplazamientos ±0,2/±0,3/±0,4/0 m, profundidades 0,8–1,2 m, ambos lados: objetivo = bandeja y ninguna es dispensador. Desde el pase a 0,8 m y ±0,4 m la bandeja queda fuera del alcance del detector (sin objetivo), por lo que esas dos posiciones se omiten.
- AC2: tests de PUL-063 en verde.
- AC3: `signals.md` y ADR-003 §8.1–8.3 con nota de enmienda aprobada por el responsable.
- Captura (caja en mano a +0,3 m de la bandeja, detector → Tray): `docs/evidence/PUL-064/caja-en-mano-resalta-bandeja.png`. Posición preparada con `run_script` (solo ilustración; el AC lo cubre el test).
- AC4: `tools/verify.sh` verde y `check_owns` limpio (ver cierre).
- Nota: `HAND_BUSY` sigue en el enum `SeasoningRules.Rejection` (en desuso) para no renumerar.
