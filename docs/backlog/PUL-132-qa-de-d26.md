---
id: PUL-132
title: QA de D26
status: todo
milestone: M3e
role: qa-tester
deps: [PUL-131]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-132/**, godot/tests/integration/test_d26_no_mute_press.gd*, godot/tests/integration/test_d26_touch_flow.gd*, docs/backlog/PUL-132-qa-de-d26.md]
touches_scenes: []
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 4. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: ninguna

## Change
verificación de D26 en `level_01` contra `lenguaje-acciones.md` y
  `controles-tactiles.md`; guía de playtest para el responsable.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
