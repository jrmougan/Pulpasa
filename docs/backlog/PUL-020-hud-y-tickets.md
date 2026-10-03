---
id: PUL-020
title: Crear el HUD y el panel de tickets de comandas
status: ready
milestone: M0
role: ui-engineer
deps: []
orca_task: null
unity_sources: [Assets/Scripts/UI/ProductivityUIDisplay.cs, Assets/Scripts/UI/OrderTicket.cs, Assets/Scripts/UI/BoxEntryUI.cs, Assets/Scripts/Game/OrderTicketUIController.cs, Assets/Prefabs/UI/**, Assets/Scenes/Levels/Level_01.unity]
owns: [godot/ui/hud/**, godot/ui/tickets/**, godot/ui/sandbox/hud_sandbox.tscn, godot/tests/integration/test_hud.gd, godot/tests/integration/test_hud.gd.uid, godot/tests/integration/test_order_tickets.gd, godot/tests/integration/test_order_tickets.gd.uid, docs/evidence/PUL-020/**]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_tickets_panel.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/ticket_entry.tscn, godot/ui/sandbox/hud_sandbox.tscn]
---

## Target
Fase 7 de M0, `scene-tree.md` §4 (HUD y tickets). Paridad M0 con el HUD y los tickets del prototipo.

## Change
1. `ui/hud/hud.tscn` + `hud.gd`: tiempo restante (`round_time_changed`) y cajas/minuto
   (`score_changed`), como `ProductivityUIDisplay`, sin reloj propio (B2) ni arrancar la ronda (B11).
   La recaudación es M1: deja el hueco, no la implementes.
2. `ui/tickets/order_tickets_panel.tscn` + `order_ticket.tscn` + `ticket_entry.tscn`: un ticket por
   comanda activa con `#id`, receta y condimentos (texto, como el prototipo; los iconos son M1).
   Escucha `orders_reset` / `order_generated` / `order_completed` / `order_expired`; reconstruye una
   vez con `OrderService.get_active_orders()` al cargar. `%PatienceBar` presente pero oculta mientras
   `max_time = 0` (paridad M0); solo se pinta con `order_patience_changed` de su `order_id`.
3. `ui/sandbox/hud_sandbox.tscn`: escena mínima con `OrderService.setup` + `RoundManager.start_round` y
   la UI encima, para pruebas y capturas.

## Constraints
- Capa común (ADR-003 §0): nada de tipos 3D en `ui/`. La UI escucha señales de `EventBus` y llama métodos de los autoloads; nunca consulta sistemas por ruta (B16). Sin contadores propios (B2).
- Navegable con teclado y mando: `Button` con foco nativo, `focus_neighbor_*`, `grab_focus()` al abrir y acciones `ui_*` (ADR-004; sustituye B13/B14).
- Textos con `tr()` y claves (preparado para gallego, Should de la alpha). Tema `ui/theme/default_theme.tres` (PUL-009).
- `.tscn` con un script tipado propio o el editor; las tools headless del MCP fallan por `untyped_declaration=error`. No inventes uid.

## Acceptance
- [ ] AC1 El HUD muestra el tiempo restante y se actualiza solo con señales; en pausa no cambia; al terminar la ronda marca 0 → `test_hud.gd`.
- [ ] AC2 Hay exactamente un ticket por comanda activa; al completarse desaparece el suyo y aparece el de la repuesta; tras `orders_reset` se vacía → `test_order_tickets.gd`.
- [ ] AC3 Un panel creado con la ronda en marcha muestra las comandas activas (`get_active_orders`) → `test_order_tickets.gd`.
- [ ] AC4 Captura del sandbox con HUD y tickets en `docs/evidence/PUL-020/`. `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
