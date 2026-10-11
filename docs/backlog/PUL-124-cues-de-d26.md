---
id: PUL-124
title: Cues de D26
status: in_progress
milestone: M3e
role: asset-pipeline
deps: [PUL-119, PUL-120]
orca_task: null
unity_sources: []
owns: [godot/assets/audio/sfx/**, godot/data/audio/feedback_map.tres, godot/assets/CREDITS.md, godot/tests/unit/test_assets_audio_ui.gd*, godot/tests/unit/test_feedback_distinct.gd*, godot/tests/integration/test_audio_feedback.gd*, docs/evidence/PUL-124/**, docs/backlog/PUL-124-cues-de-d26.md]
touches_scenes: []
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 1. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: ninguna

## Change
claves nuevas `cook_ready`, `box_full`, `switch`, `rejected` y sample propio para
  `trash`, `discard` y `burn_warning` (ADR-006 §4.1). **Sin quitar** `cook_done`, `season_error` ni
  `deliver_error` (las retira PUL-131). `rejected` con `SHAKE` de ±6 px y `visual_time` 0,35.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
