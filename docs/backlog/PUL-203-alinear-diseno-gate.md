---
id: PUL-203
title: Alinear los documentos de diseño con el gate de enmiendas
status: ready
milestone: M4
role: game-designer
deps: [PUL-198, PUL-202]
orca_task: null
unity_sources: []
owns: [docs/design/features/corte-pulpo.md, docs/design/gdd.md, docs/design/features/audio-y-fx.md, docs/design/features/entrega-y-puntuacion.md, docs/design/features/cubo-basura.md, docs/backlog/PUL-066-*.md]
touches_scenes: []
---

## Target
Documentos de diseño que contradicen lo decidido en el gate del 2026-11-04.

## Change
- `presses_to_fill` = 6 ya no es provisional (G11): `corte-pulpo.md:19` y `:68`, `gdd.md:155` y `:187`; los precios de D25 siguen provisionales.
- AC5 de `audio-y-fx`: la entrega errónea ya no suena (`signals.md`, ADR-006).
- «Test:» de AC5d en `entrega-y-puntuacion.md`: cita `_assert_expiry_tick`, que comprueba lo contrario; apuntar a los tests vigentes tras PUL-198.
- T6 de `cubo-basura.md`: citar el test que lo prueba tras PUL-202.
- PUL-066: registrar la respuesta a R2 (G45).

## Constraints
Solo describe lo ya decidido: no decide ni cambia valores. Si algo necesita decisión, status=blocked y pregúntalo. Sin tocar `decisions.md` ni `docs/arch`.

## Acceptance
- [ ] AC1 Given esas líneas, When se contrastan con `decisions.md`, `signals.md` y los tests citados, Then coinciden → tabla en docs/evidence/PUL-203/

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker: salida de verify.sh, capturas, notas.)
