---
id: PUL-106
title: Enmendar contratos y diseño con presses_to_fill
status: ready
milestone: M3c
role: godot-architect
deps: [PUL-104]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-001-gdscript-convenciones.md, docs/arch/ADR-003-arbol-escenas-composicion.md, docs/arch/scene-tree.md, docs/design/features/corte-pulpo.md, docs/design/gdd.md, docs/design/rediseno-estaciones.md, godot/entities/stations/order_stand.gd, docs/evidence/PUL-106/**, docs/backlog/PUL-106-contratos-presses-to-fill.md]
touches_scenes: []
---

## Target
Documentos que siguen nombrando `BoxData.fill_per_press`, eliminado en PUL-104; comentario de `order_stand.gd` que nombra `%DeliveryMark` (hallazgo de PUL-103). Gate humano: los contratos no cambian sin el visto bueno del responsable.

## Change
- Sustituir `fill_per_press` por `presses_to_fill: int` (4/6/10) y `BoxData.fill_after(presses)` en ADR-001, ADR-003 (tabla de §8), `scene-tree.md`, `corte-pulpo.md`, `gdd.md` y `rediseno-estaciones.md`, citando PUL-104. Mencionar `Ingredient.EMPTY_EPSILON` donde se describa el agotado del pulpo.
- `order_stand.gd:11`: el comentario nombra `%DeliveryMark`; debe decir `DeliveryFrame` (dentro de `Model`). Solo el comentario.
- `m3c-gate.md` y los scripts de evidencia de PUL-090/PUL-102 quedan como registro histórico: no se tocan.

## Constraints
Solo documentación y un comentario; sin cambios de comportamiento. `tools/verify.sh` en verde.

## Acceptance
- [ ] AC1 `grep -rn fill_per_press docs/arch docs/design` solo aparece en `m3c-gate.md` o como referencia histórica explícita
- [ ] AC2 `grep -n DeliveryMark godot/` no devuelve nada

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
