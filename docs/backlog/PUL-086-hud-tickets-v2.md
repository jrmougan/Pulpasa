---
id: PUL-086
title: Adaptar HUD y tickets a la estética de referencia
status: done
milestone: M3b
role: ui-engineer
deps: [PUL-072, PUL-088]
orca_task: task_8a940123595b
unity_sources: []
owns: [godot/ui/**, godot/assets/fonts/**, godot/tests/integration/test_hud.gd, godot/tests/integration/test_order_tickets.gd, docs/evidence/PUL-086/**, godot/data/seasonings/salt.tres, godot/tests/unit/test_data_integrity.gd, godot/entities/items/badge_row.gd, godot/tests/unit/test_assets_audio_ui.gd]
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
- [x] AC1 Tests de HUD y tickets en verde
- [x] AC2 Legible a 1280×720 y 1920×1080
- [x] Captura antes/después desde la cámara del nivel y render del `.blend` (no aplica `.blend`: ficha solo de UI, sin modelo 3D)
- [x] `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. Fuentes OFL en `godot/assets/fonts/`: Montserrat Bold/Black/SemiBold (`montserrat/`, con su
   `OFL.txt`) para textos y DSEG7 Classic Bold (`dseg/`, con su `OFL.txt`) para el reloj de 7
   segmentos. El coordinador registra las licencias.
2. Tema `ui/theme/default_theme.tres` con la paleta de la biblia §2.6/§2.7: variaciones `UiPanel`
   (noche al 92 %, borde `ui_border`), `UiHeader` (marino), `UiCard`, `DisplayWell`/`DisplayLabel`
   (DSEG7 en `ui_digits`, con Montserrat de reserva), `FigureLabel`, `CaptionLabel`, `TitleLabel`,
   `BrandLabel`; botones primario pimentón y secundario marino con foco «papel»; colores de
   `OrderTicket` (barra `ui_bar`, aviso `ui_alert`, umbral 25 %).
3. Ticket: cabecera marina con insignia compacta, «Comanda #n», receta, pegatinas de PUL-060, barra
   de paciencia y reloj «MM:SS» en 7 segmentos con fantasma «88:88»; con paciencia ≤ 25 % barra y
   reloj pasan a neón y la barra parpadea (nunca solo color).
4. HUD compacto abajo a la izquierda con el mismo panel, cifras en `ui_digits`.
5. Escala de HUD y tickets por altura de ventana (`UiScale`, ×1,5 a 1080p): el proyecto no estira
   el lienzo y la UI ocupaba un tercio menos a 1080p.
6. Menús: panel compartido de pausa/fin con insignia, lema y botones de marca; menú principal con
   fondo noche y logotipo horizontal sobre placa papel con borde marino.
7. Sal (nota de PUL-082, propuesta A aprobada por el coordinador): `salt.tres` a `#F7F4EC` (biblia
   §2.5); en discos claros el icono va en `#6E4A2B` y el disco lleva anillo `#6E4A2B`, en ticket y
   en la pegatina 3D (`badge_row.gd`) con `StickerInk` compartido. Owns ampliado con
   `test_data_integrity.gd`, `badge_row.gd` y `test_assets_audio_ui.gd` (fuente por defecto).

## Evidence
- `tools/verify.sh` verde: gdformat, gdlint, import, GUT 734/734, smoke.
- Tests nuevos: `test_order_tickets.gd` (`test_pul086_*`: reloj «MM:SS» y fuente display, aviso de
  paciencia baja con parpadeo, panel/título de marca, sal con icono y anillo de tinta en ticket y
  en la fila 3D de la caja); `test_hud.gd` (`test_pul086_*`: cifras `FigureLabel` en `ui_digits`,
  escala 720p→1080p, HUD compacto). Actualizados: valor esperado de la sal en
  `test_data_integrity.gd`, fuente por defecto en `test_assets_audio_ui.gd`.
- Capturas desde la cámara de `level_01` (script reproducible `docs/evidence/PUL-086/capture_ui.gd`,
  `--audio-driver Dummy`), a 1280×720 y 1920×1080:
  - Antes: `docs/evidence/PUL-086/antes/before_{level,pause,gameover,menu}_<res>.png`.
  - Después: `docs/evidence/PUL-086/despues/after_{level,pause,gameover,menu,alert}_<res>.png` y
    `after_alert_<res>_zoom.png` (tickets en paciencia baja; pegatina de sal visible).
  - El resaltado del dispensador de sal se activa en el modo `level`; la UI no tapa el área jugable.
- Sin `.blend`: la ficha es de UI (no se modela nada en Blender).
- Decisión de diseño: el HUD no usa 7 segmentos porque DSEG7 dibuja «s» como «5» y el punto decimal
  apenas se ve («294.0s» se leía «29405»); el formato «%.1fs» lo fijan `test_hud` y `test_parity_smoke`.
  El 7 segmentos queda en los relojes de los tickets, como en la referencia.
- Fuentes para registrar (OFL 1.1): `godot/assets/fonts/montserrat/` (Julieta Ulanovsky y
  colaboradores, github.com/JulietaUla/Montserrat) y `godot/assets/fonts/dseg/` (keshikan,
  github.com/keshikan/DSEG v0.46). `LiberationSans.ttf` sigue en uso por `order_stand.tscn`.
- Escenas tocadas fuera de `touches_scenes` (dentro de `owns: godot/ui/**`): `menu_panel.tscn`,
  `main_menu.tscn`, `pause_menu.tscn`, `game_over.tscn` (punto 2 del Change). El generador antiguo
  `ui/menus/sandbox/build_scenes.gd` (PUL-021) ya estaba desfasado y no se usa: no ejecutarlo.
