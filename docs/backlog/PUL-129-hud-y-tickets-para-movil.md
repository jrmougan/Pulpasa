---
id: PUL-129
title: HUD y tickets para móvil
status: in_progress
milestone: M3e
role: ui-engineer
deps: [PUL-122, PUL-123]
orca_task: null
unity_sources: []
owns: [godot/ui/hud/**, godot/ui/tickets/**, godot/ui/sandbox/**, godot/tests/integration/test_hud.gd*, godot/tests/integration/test_order_tickets.gd*, godot/tests/integration/test_touch_hud_layout.gd*, docs/evidence/PUL-129/**, docs/backlog/PUL-129-hud-y-tickets-para-movil.md]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_tickets_panel.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/ticket_entry.tscn, godot/ui/sandbox/hud_sandbox.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/ui/hud/hud.tscn`, `godot/ui/tickets/order_tickets_panel.tscn`,
  `godot/ui/tickets/order_ticket.tscn`, `godot/ui/tickets/ticket_entry.tscn`,
  `godot/ui/sandbox/hud_sandbox.tscn`

## Change
ADR-005 E3–E4 en HUD y tickets: `SafeAreaMargin`, banda superior en `MOBILE` con la
  maquetación del diseño, zonas reservadas, sin «Cajas / minuto» (D26.7), icono del aliño =
  `SeasoningData.icon`, textos ≥ 36 px a 1080 en móvil; escritorio sin cambios.

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance


## Plan

## Evidence
