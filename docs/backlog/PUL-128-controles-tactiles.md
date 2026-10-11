---
id: PUL-128
title: Controles táctiles
status: in_progress
milestone: M3e
role: ui-engineer
deps: [PUL-121, PUL-122, PUL-123]
orca_task: null
unity_sources: []
owns: [godot/ui/touch/**, godot/core/touch_input.gd*, godot/resources/touch_config.gd*, godot/data/config/touch_config.tres, godot/tests/unit/test_touch_input_rules.gd*, godot/tests/integration/test_touch_input.gd*, godot/tests/integration/test_virtual_stick.gd*, godot/tests/integration/test_touch_multitouch.gd*, godot/tests/integration/test_action_button.gd*, godot/tests/integration/test_touch_layout.gd*, docs/evidence/PUL-128/**, docs/backlog/PUL-128-controles-tactiles.md]
touches_scenes: [godot/ui/touch/touch_controls.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/ui/touch/touch_controls.tscn` (nueva) y su sandbox en `godot/ui/touch/sandbox/`

## Change
ADR-004 §6.1–§6.4 con las medidas de `controles-tactiles.md`.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
