---
id: PUL-086
title: Adaptar HUD y tickets a la estética de referencia
status: ready
milestone: M3b
role: ui-engineer
deps: [PUL-072, PUL-088]
orca_task: null
unity_sources: []
owns: [godot/ui/**, godot/assets/fonts/**, godot/tests/integration/test_hud.gd, godot/tests/integration/test_order_tickets.gd, docs/evidence/PUL-086/**, godot/data/seasonings/salt.tres]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/ui/tickets/ticket_entry.tscn]
---

## Target
La referencia (`docs/art/style-refs/referencia-elegida-2026-10-06.png`) usa paneles oscuros con contador digital tipo display («00:05») en los tickets y un HUD compacto.

## Change
1. Tickets: panel oscuro con borde, título de comanda, pegatinas de condimento (mismas de PUL-060), barra de paciencia y tiempo restante en estilo display digital.
2. HUD (tiempo, cajas/minuto, recaudación) con el mismo lenguaje; menús de pausa/fin y principal coherentes.
3. Fuentes libres (OFL/CC0, D16) registradas por el coordinador.

Nota de PUL-082: el bote de sal es blanco y `salt.tres` tiene color turquesa (pegatinas/UI). Unifica el color de la sal en UI y pegatinas con la biblia v2 manteniéndolo distinguible.

## Constraints
- Referencia visual: `docs/art/style-refs/referencia-elegida-2026-10-06.png`; reglas en `docs/art/art-bible.md` v2 (PUL-072) y materiales de PUL-074.
- Modela con el MCP de Blender (por CLI; no uses el puerto 9876 si hay un Blender del responsable).
  Godot para capturas siempre con `--audio-driver Dummy`.
- No cambies la jugabilidad: colisiones, anclas, nodos de contrato (`scene-tree.md`), posiciones en
  `level_01` y los tests de selección/entrega deben seguir en verde. Resaltado con contorno fino
  (`OutlineHull` si el modelo es abierto, nota de PUL-049).
- Conserva la legibilidad (biblia §3): siluetas, crudo/cocido/quemado, pegatinas, colores por puesto.
- Capturas desde la cámara de `level_01` (antes/después, con resaltado) y render del `.blend` en
  `docs/evidence/<id>/`. La licencia propia la registra el coordinador.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Tests de HUD y tickets en verde
- [ ] AC2 Legible a 1280×720 y 1920×1080
- [ ] Captura antes/después desde la cámara del nivel y render del `.blend`
- [ ] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
