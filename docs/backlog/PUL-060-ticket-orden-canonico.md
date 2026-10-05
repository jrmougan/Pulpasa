---
id: PUL-060
title: Ordenar los iconos del ticket y darles estilo de pegatina
status: done
milestone: M2
role: ui-engineer
deps: [PUL-057]
orca_task: task_430b1b1e1cdc
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
- [x] AC1 Feature AC14 → `test_order_tickets.gd`
- [x] AC2 Captura del ticket junto a la caja de PUL-059 (o su sandbox) en `docs/evidence/PUL-060/`
- [x] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `ticket_entry.gd`: ordenar con `SeasoningRules.canonical_order` (copia; no muta la comanda).
2. Pegatina = disco con `SeasoningData.color` + icono blanco + `HotMark` (de `BoxBadgeStyle.hot_mark`), lado `badge_icon_px`.
3. Reescribir los tests de iconos del ticket y añadir AC14.

## Evidence
- `test_order_tickets.gd`: `test_ac14_ticket_orders_stickers_canonically_whatever_the_tres_order` (cachelos, aceite, sal, picante en el `.tres` → picante, sal, aceite, cachelos; solo el picante lleva llama) y `test_ac4_sticker_uses_box_badge_style_and_seasoning_color`.
- Captura: `docs/evidence/PUL-060/ticket-pegatinas.png` (ticket con las 4 pegatinas). PUL-059 aún no está mergeada, así que la comparación lado a lado con la caja queda para cuando exista `BadgeRow`; el orden y el estilo vienen de los mismos datos (`SeasoningRules`, `BoxBadgeStyle`).
- `tools/verify.sh` verde, `check_owns` limpio.
