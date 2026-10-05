---
id: PUL-060
title: Ordenar los iconos del ticket y darles estilo de pegatina
status: ready
milestone: M2
role: ui-engineer
deps: [PUL-057]
orca_task: null
unity_sources: []
owns: [godot/ui/tickets/**, godot/tests/integration/test_order_tickets.gd, docs/evidence/PUL-060/**]
touches_scenes: [godot/ui/tickets/ticket_entry.tscn, godot/ui/tickets/order_ticket.tscn]
---

## Target
`docs/design/features/estacion-condimentos.md`, ficha 5.

## Change
`ticket_entry.gd` ordena por `sort_order` y dibuja cada condimento como pegatina con
`BoxBadgeStyle` (mismo icono y marca de llama que la caja).

## Constraints
- Sin tipos 3D en `ui/`. Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Feature AC14 → `test_order_tickets.gd`
- [ ] AC2 Captura del ticket junto a la caja de PUL-059 (o su sandbox) en `docs/evidence/PUL-060/`
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
