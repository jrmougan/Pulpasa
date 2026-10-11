---
id: PUL-121
title: Núcleo del lenguaje de acciones, histéresis y bus
status: in_progress
milestone: M3e
role: gameplay-engineer
deps: [PUL-119, PUL-120]
orca_task: null
unity_sources: []
owns: [godot/core/action_verb.gd*, godot/core/action_reason.gd*, godot/core/action_hint.gd*, godot/core/action_rules.gd*, godot/core/hold_repeat.gd*, godot/core/interaction_scoring.gd*, godot/core/player_input.gd*, godot/components/interaction_component.gd*, godot/components/interaction_detector.gd*, godot/components/interaction_contract.gd*, godot/components/highlightable.gd*, godot/components/hold_component.gd*, godot/entities/items/held_kind.gd*, godot/resources/player_config.gd*, godot/resources/input_config.gd*, godot/data/config/player_config.tres, godot/data/config/input_config.tres, godot/autoload/event_bus.gd*, godot/tests/fixtures/action_matrix.csv, godot/tests/unit/test_action_hint.gd*, godot/tests/unit/test_action_rules.gd*, godot/tests/unit/test_hold_repeat.gd*, godot/tests/unit/test_interaction_scoring.gd*, godot/tests/unit/test_interaction_component.gd*, godot/tests/unit/test_event_bus.gd*, godot/tests/unit/test_player_input.gd*, godot/tests/unit/test_interaction_contract.gd*, godot/tests/integration/test_interaction_detector.gd*, godot/tests/integration/test_held_kind.gd*, godot/tests/integration/test_highlightable.gd*, godot/tests/integration/test_hold_component.gd*, godot/tests/integration/test_m2b_station_selection.gd*, godot/tests/integration/test_level_01_r16.gd*, godot/tests/helpers/fake_*.gd*, docs/backlog/PUL-121-nucleo-del-lenguaje-de-acciones-histeresis-y-bus.md]
touches_scenes: [godot/entities/player/player.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 1. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/player/player.tscn` (solo `%InteractionDetector.actor = %InteractionComponent`)

## Change
ADR-003 §11.1–§11.4: tipos, `ActionRules` con la tabla completa (§11.6, fixture CSV
  transcrito de `lenguaje-acciones.md` A–F), `HeldKind`, detector (filtro, sin control, hint de suelo,
  histéresis, `hint_changed`, `set_blocked`), `InteractionComponent` (respuesta, suelo, mantener, bus),
  `HoldComponent.get_drop_position()`, `Highlightable.set_blocked()` + `@export var blocked_material`,
  `InteractionContract.HINT_METHOD` (sin hacerlo obligatorio), señales en `event_bus.gd`. Equivalencia
  transitoria para entidades sin `get_action_hint`. Los dos tests de nivel solo se ajustan a la
  histéresis y al filtro de control.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
