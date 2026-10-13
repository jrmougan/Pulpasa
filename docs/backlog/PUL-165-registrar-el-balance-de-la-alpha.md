---
id: PUL-165
title: Registrar los valores de balance aprobados en el diseño
status: draft
milestone: M4
role: game-designer
deps: [PUL-164]
orca_task: null
unity_sources: []
owns: [docs/design/features/entrega-y-puntuacion.md, docs/design/features/dificultad-progresiva.md, docs/design/features/comandas.md, docs/design/gdd.md, docs/evidence/PUL-165/**, docs/backlog/PUL-165-registrar-el-balance-de-la-alpha.md]
touches_scenes: []
---

## Target
La propuesta de PUL-164 tras el gate humano de balance (el responsable aprueba o ajusta los valores; el
coordinador la registra en `decisions.md`).

## Change
1. Llevar a las features los valores aprobados: umbrales de estrellas (`entrega-y-puntuacion.md`), límites
   de fase y multiplicadores (`dificultad-progresiva.md`), precios y `presses_to_fill` (`comandas.md`).
2. Cerrar las preguntas 1, 5 y 7 del GDD §11 que queden respondidas; dejar abiertas las que dependan del
   playtest de la alpha.
3. Lista exacta de campos `.tres` que cambian, para PUL-166.

## Constraints
- Solo `docs/design/`, salvo `decisions.md` (lo edita el coordinador).
- No pasa a `ready` sin el gate de balance hecho.

## Acceptance
- [ ] AC1 Given el acta del gate G2, When se trasladan los valores, Then cada valor aprobado aparece en su feature con la fecha del gate
  (0 valores aprobados ausentes) → tabla valor → feature:línea en `docs/evidence/PUL-165/README.md`.
- [ ] AC2 Given las features y `gdd.md`, When se busca cada valor nuevo y el antiguo con `grep -rn` en `docs/design/`, Then el antiguo
  aparece 0 veces como vigente → salida de los `grep` en la evidencia.
- [ ] AC3 Given los `.tres` afectados, When se lista el cambio, Then hay tabla «fichero `.tres` → campo → valor actual → valor nuevo» con
  1 fila por campo → evidencia (entrada de PUL-166).
- [ ] AC4 Given la rama de la ficha, When se ejecutan `tools/verify.sh --quick` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-165/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
