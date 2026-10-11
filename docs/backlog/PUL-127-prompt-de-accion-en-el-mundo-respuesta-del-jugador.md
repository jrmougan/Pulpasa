---
id: PUL-127
title: Prompt de acción en el mundo, respuesta del jugador, aro activo y contorno
status: todo
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-123, PUL-124]
orca_task: null
unity_sources: []
owns: [godot/components/action_prompt.gd*, godot/entities/player/player.gd*, godot/shaders/**, godot/tests/integration/test_action_prompt.gd*, godot/tests/integration/test_player.gd*, godot/tests/integration/test_player_ring.gd*, godot/tests/integration/test_player_feedback.gd*, docs/evidence/PUL-127/**, docs/backlog/PUL-127-prompt-de-accion-en-el-mundo-respuesta-del-jugador.md]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/player/action_prompt.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/player/player.tscn`, `godot/entities/player/action_prompt.tscn` (nueva)

## Change
ADR-003 §11.5 y §11.8 (aro, `%ActiveMarker`, contorno `#FFF4D6` / ámbar visible a través
  del personaje); rechazo en el `%Feedback` del jugador (`rejected`) y cue `switch` (ADR-006 §4.1).

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
