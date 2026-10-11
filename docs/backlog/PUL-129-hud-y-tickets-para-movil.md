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
- [x] AC1 (diseño AC15) 4 tickets de 330-380 px (342 a 1920x1080), separación 16 +-1, sin recortar nombres («Bravo cachelos»), banda <= 200 px, sin tocar HUD ni pausa -> `test_touch_hud_layout.gd`
- [x] AC2 (AC16) HUD y tickets fuera de las zonas del stick y de los botones a 2340x1080, 1920x1080 y 1600x720 -> `test_touch_hud_layout.gd`
- [x] AC3 (AC17) Todo dentro de la safe area simulada (132/0/132/63); sin safe area, anclado con 48 px -> `test_touch_hud_layout.gd`
- [x] AC4 (AC14) Texto >= 36 px a 1080 y >= 24 px a 720 en HUD y tickets -> `test_touch_hud_layout.gd`
- [x] AC5 HUD sin «Cajas / minuto» (D26.7); recaudación y tiempo en dos líneas -> `test_hud.gd`, `test_touch_hud_layout.gd`
- [x] AC6 Iconos de aliño = `SeasoningData.icon` a 48 px; barra de paciencia de 12 px -> `test_touch_hud_layout.gd`
- [x] AC7 Escritorio sin cambios (esquina inferior izquierda, tarjetas de 212, cabecera «Comanda») -> `test_hud.gd`, `test_order_tickets.gd`

## Plan
1. `HUD` y `OrderTicketsPanel` pasan a ser `SafeAreaMargin` (raíz), con los anclajes de escritorio por defecto.
2. `TouchHudLayout` (puro) con las medidas de la banda; `_apply_layout()` solo en `MOBILE`.
3. Ticket móvil: receta arriba; pegatinas, id y reloj en una fila (`TicketEntry.extras`); barra de 12 px; `TextFloor`.
4. Sandbox con anclajes de nivel y, en `--touch`, zonas reservadas y marcador de pausa. Tests y capturas.

## Evidence
- Tests: `test_touch_hud_layout.gd` (13), `test_hud.gd` (17), `test_order_tickets.gd` (25); `tools/verify.sh` en verde.
- Capturas en `docs/evidence/PUL-129/`: `hud_touch_2340x1080.png` (safe area simulada, 4 tickets, zonas azules = stick y botones, círculo = pausa), `hud_touch_1920x1080.png`, `hud_touch_1600x720.png`, `hud_desktop_1280x720.png`, `hud_desktop_1920x1080.png`. Generadas con un script `SceneTree` sobre `hud_sandbox.tscn` (`--resolution WxH -s capture.gd -- png [--safe] [--touch]`).
- Desviaciones (lo que queda en código): `TOP_PX` (24) y `BLOCK_GAP_PX` (24) son constantes de `TouchHudLayout` sin dato propio; el margen de 48 y la pausa de 120 px salen de `touch_config.tres`. `order_ticket.gd` crea en código los stylebox compactos del ticket móvil (márgenes 6/8, pozo del reloj a 0/4) y fija la franja a 4 unidades y la separación a 2. En MOBILE `margin_bottom` de las raíces es 0. `%BoxesPerMinute` sigue como `Label` oculto porque `test_parity_smoke.gd` (fuera de owns) lo lee; PUL-131 debe retirarlo con ese test. En MOBILE se ocultan `ActiveCharacter` y `DeviceNotice` del HUD (no caben en 2 líneas). El separador de tickets usa `floori` (la maquetación del `HBox` redondea y daba 17,5 px). Nada de «fase» en el HUD: no existe como dato en la UI.
