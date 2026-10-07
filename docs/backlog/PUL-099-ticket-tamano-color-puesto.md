---
id: PUL-099
title: Mostrar el tamaño y el color del puesto en el ticket
status: ready
milestone: M3c
role: ui-engineer
deps: [PUL-093, PUL-096, PUL-098]
orca_task: null
unity_sources: []
owns: [godot/ui/tickets/**, godot/resources/stand_palette.gd, godot/data/config/stand_palette.tres, godot/tests/integration/test_order_tickets.gd, docs/evidence/PUL-099/**, docs/backlog/PUL-099-ticket-tamano-color-puesto.md]
touches_scenes: [godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/order_tickets_panel.tscn]
---

## Target
Tickets de comanda (D23, B-A y E-A).

## Change
Crea `StandPalette` (`slot_id` 1–4 → color, hex de PUL-096). El ticket muestra el icono y la letra del tamaño (`BoxData.icon/short_label`) antes del nombre de la receta y una franja del color de su puesto.

## Constraints
- `tools/verify.sh` en verde; GDScript tipado; datos en `.tres`. Godot con `--audio-driver Dummy`; con el MCP, silencia los buses.
- Diseño: D23 en `docs/design/decisions.md` y `docs/design/rediseno-estaciones.md` (R1–R17). Las features reescritas (PUL-092) y los contratos (PUL-093) mandan.

## Acceptance
- [ ] AC1 R10: comanda de caja M → ticket con icono y «M» → test
- [ ] AC2 R13: 4 comandas vivas → franja de cada ticket = color de su puesto → test
- [ ] AC3 Captura del HUD con 4 tickets a 1080p

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
