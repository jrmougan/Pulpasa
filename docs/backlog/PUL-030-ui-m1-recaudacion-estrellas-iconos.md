---
id: PUL-030
title: Mostrar recaudación, estrellas, iconos y paciencia en la UI
status: ready
milestone: M1
role: ui-engineer
agent: kimi (fácil)
deps: [PUL-027, PUL-031]
orca_task: null
unity_sources: []
owns: [godot/ui/hud/**, godot/ui/tickets/**, godot/ui/menus/game_over.tscn, godot/ui/menus/game_over.gd, godot/ui/theme/**, godot/tests/integration/test_hud.gd, godot/tests/integration/test_order_tickets.gd, godot/tests/integration/test_game_over.gd, docs/evidence/PUL-030/**]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/ticket_entry.tscn, godot/ui/menus/game_over.tscn]
---

## Target
M1, `entrega-y-puntuacion.md` AC9–AC11, `comandas.md` AC4, `partida-5-min.md` AC2.

## Change
1. HUD: recaudación en € (empieza en 0, se actualiza con `score_changed` en ≤ 0,2 s).
2. Tickets: iconos de cada condimento (de PUL-031 / `SeasoningData.icon`) en vez de texto; `%PatienceBar`
   visible y decreciente con `order_patience_changed`.
3. Game over: recaudación y 0–3 estrellas del `RoundResult`.

## Constraints
- Desde M1 manda el diseño (`docs/design/gdd.md`, `features/`, `decisions.md`), no Unity (D17). Donde una feature cite «paridad», prevalecen D8–D10 y D17.
- Capa común (ADR-003 §0) y núcleos `RefCounted` con dependencias inyectadas (ADR-002). Datos de balance en `.tres`.
- Cambios de firma de señales: solo si la ficha lo dice; actualiza `docs/arch/signals.md` en ese caso.
- Antes de cerrar: `tools/verify.sh` en verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio (los hooks de Claude Code no corren en tu agente: el merge gate sí).
- La UI solo escucha señales; sin contadores propios. Navegación `ui_*` y `tr()` intactos.

## Acceptance
- [ ] AC1 Tests de HUD (0 €, +entrega, −caducidad sin bajar de 0), tickets (iconos, barra) y game over (estrellas).
- [ ] AC2 Capturas de HUD, ticket con iconos y barra, y game over con estrellas en `docs/evidence/PUL-030/`.
- [ ] AC3 `tools/verify.sh` en verde, `check_owns` limpio.

## Plan

## Evidence
