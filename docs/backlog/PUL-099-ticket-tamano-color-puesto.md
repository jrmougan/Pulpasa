---
id: PUL-099
title: Mostrar el tamaño y el color del puesto en el ticket
status: review
milestone: M3c
role: ui-engineer
deps: [PUL-093, PUL-096, PUL-098]
orca_task: null
unity_sources: []
owns: [godot/ui/tickets/**, godot/resources/stand_palette.gd, godot/resources/stand_palette.gd.uid, godot/data/config/stand_palette.tres, godot/tests/integration/test_order_tickets.gd, docs/evidence/PUL-099/**, docs/backlog/PUL-099-ticket-tamano-color-puesto.md]
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
- [x] AC1 R10: comanda de caja M → ticket con icono y «M» → test
- [x] AC2 R13: 4 comandas vivas → franja de cada ticket = color de su puesto → test
- [x] AC3 Captura del HUD con 4 tickets a 1080p

## Plan
1. `StandPalette` (`Resource`, capa común, solo `Color`): `colors: Array[Color]` (índice `slot_id - 1`), `fallback: Color`, `color_for(slot_id) -> Color` (única lectura; fuera de rango devuelve `fallback`). Instancia `data/config/stand_palette.tres` con #D2473F, #3F7CC8, #E8C23A, #4FA05A. API pensada para PUL-100: `palette.color_for(slot_id)` sirve tanto de `albedo_color` como de `emission`.
2. Tests primero en `test_order_tickets.gd`: paleta (4 colores, fallback), AC1 (caja M: icono = `BoxData.icon`, letra «M», antes de la receta), AC2 (4 comandas: `Stripe.color` = `color_for(slot_id)`).
3. `TicketEntry`: fila `RecipeRow` con `%SizeIcon` (TextureRect), `%SizeLabel` (letra, grande) y `%Recipe`; se rellenan desde `data.recipe.box`. El icono ya trae la letra; la letra aparte garantiza lectura inequívoca.
4. `OrderTicket`: `%Stripe` (ColorRect, banda superior) coloreada en `setup()` con `palette.color_for(order.slot_id)`; el ticket no escucha al puesto.
5. Captura con CLI de 4 tickets a 1080p (S/M/L mezclados) en `docs/evidence/PUL-099/`; verify y check_owns.

## Evidence
- `tools/verify.sh` OK: 743 tests, 0 fallos (log en `verify.log`).
- AC1: `test_pul099_ac1_r10_medium_box_ticket_shows_icon_and_letter_before_recipe` (+ `..._every_live_ticket_size_matches_its_recipe_box`, `..._ticket_without_box_hides_size`).
- AC2: `test_pul099_ac2_r13_four_live_orders_stripe_is_stand_color` (+ `test_pul099_palette_has_the_four_awning_colors_and_fallback`).
- AC3: `tickets_1080.png` (HUD completo, 4 tickets S/S/L/S con franjas rojo/azul/amarillo/verde) y `tickets_zoom.png`; reproducible con `capture_tickets.gd` (cabecera con el comando).
- API para PUL-100: `StandPalette.color_for(slot_id: int) -> Color` (1-4; fuera de rango = `fallback`), instancia `res://data/config/stand_palette.tres`; sirve igual para `albedo_color` y `emission`.
- Nota de diseno: el icono ya lleva la letra grabada; se muestra ademas la letra en texto grande, de modo que talla (silueta redonda/cuadrada + letra) es inequivoca.

- Revisión (CHANGES): la letra en texto solo sale sin icono; `%Recipe` con `clip_text` + elipsis, ancho del ticket fijo a 212 (test con todas las recetas y tallas); test de `box == null` real; captura `level_tickets_1080.png` en `level_01` con 4 comandas vivas (los tickets solo tapan toldo/rótulo superior, no puestos ni estaciones). «Pulpo Individual» se trunca con elipsis a 212 px.
