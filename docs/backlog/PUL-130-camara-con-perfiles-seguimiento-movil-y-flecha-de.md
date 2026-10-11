---
id: PUL-130
title: Cámara con perfiles, seguimiento móvil y flecha de borde
status: in_progress
milestone: M3e
role: gameplay-engineer
deps: [PUL-122, PUL-123]
orca_task: null
unity_sources: []
owns: [godot/entities/camera/camera_rig.gd*, godot/resources/camera_profile.gd*, godot/core/camera_follow.gd*, godot/data/config/camera_desktop.tres, godot/data/config/camera_mobile.tres, godot/tests/unit/test_camera_follow_math.gd*, godot/tests/integration/test_camera_profile.gd*, godot/tests/integration/test_camera_follow.gd*, docs/evidence/PUL-130/**, docs/backlog/PUL-130-camara-con-perfiles-seguimiento-movil-y-flecha-de.md]
touches_scenes: [godot/entities/camera/camera_rig.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/camera/camera_rig.tscn`

## Change
ADR-005 E5.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
