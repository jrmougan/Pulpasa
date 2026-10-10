---
id: PUL-108
title: Limpiar el diseño superado y registrar D24 (entrega en el tick de caducidad)
status: ready
milestone: M3c
role: game-designer
deps: [PUL-107]
orca_task: null
unity_sources: []
owns: [docs/design/decisions.md, docs/design/gdd.md, docs/design/features/paridad-unity.md, docs/design/features/olla-que-se-pasa.md, docs/design/features/entrega-y-puntuacion.md, docs/evidence/PUL-108/**, docs/backlog/PUL-108-limpieza-diseno-m3c.md]
touches_scenes: []
---

## Target
Restos de diseño superados que encontró PUL-107, y una decisión del responsable sin registrar.

## Change
- **D24** (decidido por el responsable el 2026-10-10): entregar en un puesto cuya comanda caduca en el mismo tick se rechaza **sin penalizar** (0), como hace hoy `OrderBoard.try_deliver`. Añadir la fila D24 a `decisions.md` y la regla a `entrega-y-puntuacion.md` y al GDD §9 (caja errónea).
- `gdd.md`: §6 Must 1 «Paridad con Unity» (D17: la paridad ya no es requisito); §6 Should «olla que se pasa» (implementada, ADR-006 §5); §11 pregunta 2 (respondida por D10) y 3 (respondida por D11).
- `features/paridad-unity.md`: marcarla como superada por D17 (cabecera de estado), sin borrar su contenido histórico.
- `features/olla-que-se-pasa.md` AC1: la señal es `burnt(ingredient)` (local, `signals.md`), no `octopus_burnt`; estado implementada.

## Constraints
Solo documentación de diseño; sin `docs/arch/` ni código. Citar decisión, ficha o ADR en cada cambio. Si aparece otra contradicción que requiera decisión, anotarla en Evidence.

## Acceptance
- [ ] AC1 D24 en `decisions.md` y reflejada en `entrega-y-puntuacion.md` y `gdd.md` §9
- [ ] AC2 Los cuatro restos de Change corregidos, con referencia
- [ ] AC3 `grep -n octopus_burnt docs/design` sin resultados fuera de menciones históricas

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
