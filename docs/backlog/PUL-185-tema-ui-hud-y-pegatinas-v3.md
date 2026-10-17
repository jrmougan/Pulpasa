---
id: PUL-185
title: Actualizar el tema UI, el HUD, los tickets y la tinta de pegatinas a la paleta v3
status: draft
milestone: M3f
role: ui-engineer
deps: [PUL-181]
orca_task: null
unity_sources: []
owns: [godot/ui/theme/default_theme.tres, godot/ui/widgets/sticker_ink.gd, godot/entities/items/badge_row.gd, godot/ui/tickets/ticket_entry.gd, godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/tests/unit/test_ui_theme_v3.gd*, docs/evidence/PUL-185/**, docs/backlog/PUL-185-tema-ui-hud-y-pegatinas-v3.md]
touches_scenes: [godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn]
---

## Target
Alinear el tema de UI (`godot/ui/theme/default_theme.tres`), la tinta de pegatinas D26 (`godot/ui/widgets/sticker_ink.gd`), los componentes de pegatinas (`badge_row.gd` en 3D y `ticket_entry.gd` en 2D), el HUD (`godot/ui/hud/hud.tscn`) y los tickets (`godot/ui/tickets/order_ticket.tscn`) con la paleta cerrada y las reglas de contraste de `docs/art/art-bible.md` §6.2, §6.2.1 y §7.

## Change
1. En `godot/ui/theme/default_theme.tres` (§7):
   - `UiPanel` (`StyleBoxFlat`): `bg_color = Color("#1D3557")` (opacidad `1.0`, sin transparencia), borde de `2 px` en `Color("#EDE8DF")`, radio de esquina `4 px` en las 4 esquinas y sombra `Color(0.07, 0.13, 0.22, 0.35)` de `3 px`.
   - `UiHeader` y `DisplayWell` (`StyleBoxFlat`): `bg_color = Color("#2A2320")`, borde de `1 px` en `Color("#EDE8DF")`, radio `3 px`.
   - Colores de texto por defecto en `Label` y contadores: texto principal en `Color("#F7F4EC")` (contraste **11.24 : 1** sobre `#1D3557` y **14.05 : 1** sobre `#2A2320`) y cifras resaltadas en `Color("#F2C230")` (contraste **7.38 : 1** sobre `#1D3557` y **9.22 : 1** sobre `#2A2320`).
2. En `godot/ui/widgets/sticker_ink.gd`, `godot/entities/items/badge_row.gd` y `godot/ui/tickets/ticket_entry.gd` (§6.2.1):
   - Fijar `const INK: Color = Color("#2A2320")` (`state_burnt` de la paleta v3, $L = 0.0180$).
   - Llevar el anillo exterior delimitador de `INK` a **todos** los discos de pegatina (Finding 4), tanto en el billboard 3D sobre la caja (`badge_row.gd`) como en la pastilla del ticket (`ticket_entry.gd`). Esto garantiza que cuando la caja roja `#C8402F` o el suelo `#C4A882` sirven de fondo, el anillo oscuro `#2A2320` delimite la silueta con contrastes de **3.11 : 1** (sobre caja) y **6.82 : 1** (sobre suelo), mientras que en el interior el contraste disco/anillo es **≥ 3.24 : 1** (dulce), **10.67 : 1** (cachelos), **9.22 : 1** (aceite) y **14.05 : 1** (sal).
3. En `godot/ui/hud/hud.tscn` y `godot/ui/tickets/order_ticket.tscn`:
   - Verificar que los contenedores usan los `StyleBoxFlat` del tema o colores exactos de la paleta v3 (`#1D3557`, `#2A2320`, `#EDE8DF`, `#F7F4EC`, `#F2C230`, `#4FA05A`, `#C8402F`), sin alterar tamaños, anclas ni posiciones de layout (`test_level_01.gd` comprueba los rectángulos de HUD y tickets).
4. Crear `godot/tests/unit/test_ui_theme_v3.gd` que compruebe los colores, opacidad `1.0`, bordes de `2 px` y razones de contraste WCAG 2.1 del tema, de `StickerInk.INK` y del anillo delimitador de pegatinas sobre caja y suelo.

## Constraints
- `godot/ui/**` no puede referenciar tipos 3D ni 2D de mundo (regla 4 de `CLAUDE.md`).
- No alterar las dimensiones ni la posición de `HUD` ni `OrderTicketsPanel` verificadas en `test_level_01.gd` (`panel.position.y == 8.0 ± 0.5`, `ticket.end.y <= 260.0`).

## Acceptance
- [ ] AC1 Given `godot/ui/theme/default_theme.tres`, When `test_ui_theme_v3.gd` inspecciona `UiPanel`, `UiHeader` y `DisplayWell`, Then `UiPanel.bg_color` es `#1D3557` con `a == 1.0` y borde de `2 px` en `#EDE8DF`, y `UiHeader`/`DisplayWell` usan `#2A2320`.
- [ ] AC2 Given los colores de texto `#F7F4EC` y `#F2C230` sobre `#1D3557` y `#2A2320`, When `test_ui_theme_v3.gd` calcula su contraste WCAG 2.1, Then todos son **≥ 7.37 : 1** (`11.24 : 1`, `14.05 : 1`, `7.38 : 1` y `9.22 : 1`).
- [ ] AC3 Given `StickerInk.INK`, `badge_row.gd` y `ticket_entry.gd`, When `test_ui_theme_v3.gd` los evalúa, Then `StickerInk.INK` es `#2A2320`, todos los discos de pegatina aplican el anillo delimitador de `INK`, y el contraste frente a la caja roja `#C8402F` es **≥ 3.10 : 1** (`3.11 : 1`), frente al suelo `#C4A882` es **≥ 6.80 : 1** (`6.82 : 1`) y los contrastes disco/anillo son **≥ 3.24 : 1**.
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
