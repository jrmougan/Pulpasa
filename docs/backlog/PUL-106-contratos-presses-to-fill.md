---
id: PUL-106
title: Enmendar contratos y diseño con presses_to_fill
status: review
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
- Sustituir `fill_per_press` por `presses_to_fill: int` (4/6/10) y `BoxData.fill_after(presses)` en ADR-001, ADR-003 (tabla de §9.3), `scene-tree.md`, `corte-pulpo.md`, `gdd.md` y `rediseno-estaciones.md`, citando PUL-104. Mencionar `Ingredient.EMPTY_EPSILON` donde se describa el agotado del pulpo.
- `order_stand.gd:11`: el comentario nombra `%DeliveryMark`; debe decir `DeliveryFrame` (dentro de `Model`). Solo el comentario.
- `m3c-gate.md` y los scripts de evidencia de PUL-090/PUL-102 quedan como registro histórico: no se tocan.

## Constraints
Solo documentación y un comentario; sin cambios de comportamiento. `tools/verify.sh` en verde.

## Acceptance
- [x] AC1 `grep -rn fill_per_press docs/arch docs/design` solo aparece en `m3c-gate.md` o como referencia histórica explícita
- [x] AC2 `grep -n DeliveryMark godot/` no devuelve nada

## Plan
1. Contrastar con el código tras PUL-104: `BoxData.presses_to_fill: int` (`@export_range(1, 20)`, 4/6/10 en `data/boxes/*.tres`) y `fill_after(presses) = clampf(presses / presses_to_fill, 0, 1)`; `Box._cut` cuenta `_presses` enteros (resincroniza desde `fill`) y gasta `(fill - previous) × amount_per_full_box` (telescópico); `Ingredient.EMPTY_EPSILON = 0.001` da por agotado el resto; `is_full()` es `fill >= 1.0` sin tolerancia.
2. Sustituir `fill_per_press` en ADR-001 (Datos), ADR-003 §9.3 (fila `presses_to_fill` + fila `fill_after`), `scene-tree.md` §5 y bloque M3c, `corte-pulpo.md` (descripción, tabla, AC1/AC2/AC4, Datos), `gdd.md` §9 y `rediseno-estaciones.md` (B-A y R9), citando PUL-104; dejar `fill_per_press` solo como referencia histórica explícita.
3. Comentario de `order_stand.gd`: `DeliveryFrame` dentro de `Model` (PUL-103). Sin tocar código.
4. `tools/verify.sh --quick` y greps de AC.

## Evidence
- AC1: `grep -rn fill_per_press docs/arch docs/design` devuelve `m3c-gate.md:85` (histórico, sin tocar) y menciones explícitas «sustituye a / antes / eliminado en PUL-104» en ADR-003:298, scene-tree.md:419, corte-pulpo.md:33 y :47, gdd.md:123 y rediseno-estaciones.md:256.
- AC2: `grep -rn DeliveryMark godot/` sin resultados (solo estaba en `order_stand.gd:11`).
- Corregido de paso en `corte-pulpo.md`: la tolerancia `fill ≥ 1 − ε` ya no existe (PUL-104 llena exacto); los campos `octopus_units`/`units_per_fill` no existen: son `IngredientData.total_capacity`/`amount_per_full_box` en `octopus.tres`. ADR-003 §9.3: `BoxData` usa también `int`.
- `gdd.md` §9 y `scene-tree.md` §5 (M0) decían 0,2/0,1/0,05 (5/10/20 de Unity): ahora citan los dos juegos (prototipo y D23).
- `tools/verify.sh --quick` en verde (gdformat, gdlint, import).
- No tocados: `m3c-gate.md`, `docs/evidence/PUL-090/measure_flow.gd`, `docs/evidence/PUL-102/*.gd`.
