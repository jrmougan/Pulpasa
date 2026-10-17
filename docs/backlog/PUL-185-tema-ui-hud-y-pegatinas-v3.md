---
id: PUL-185
title: Actualizar el tema UI, el HUD, los tickets y la tinta de pegatinas a la paleta v3
status: done
milestone: M3f
role: ui-engineer
deps: [PUL-181]
orca_task: task_713cff7cb854
unity_sources: []
owns: [godot/ui/theme/default_theme.tres, godot/ui/widgets/sticker_ink.gd, godot/entities/items/badge_row.gd, godot/ui/tickets/ticket_entry.gd, godot/ui/hud/hud.tscn, godot/ui/tickets/order_ticket.tscn, godot/tests/unit/test_ui_theme_v3.gd*, godot/tests/integration/test_order_tickets.gd*, godot/tests/integration/test_hud.gd*, docs/evidence/PUL-185/**, docs/backlog/PUL-185-tema-ui-hud-y-pegatinas-v3.md]
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
   - Llevar el anillo exterior delimitador de `INK` a **todos** los discos de pegatina (Finding 4), tanto en el billboard 3D sobre la caja (`badge_row.gd`) como en la pastilla del ticket (`ticket_entry.gd`). Esto garantiza que cuando la caja roja `#C8402F` o el suelo `#C4A882` sirven de fondo, el anillo oscuro `#2A2320` delimite la silueta con contrastes de **3.11 : 1** (sobre caja) y **6.82 : 1** (sobre suelo), mientras que en el interior el contraste disco/anillo es **≥ 3.24 : 1** para dulce (`3.24 : 1`), cachelos (`10.67 : 1`), aceite (`9.22 : 1`) y sal (`14.05 : 1`), y para el picante (`#8F1A14`, frontera `1.71 : 1`) la discriminación unívoca se garantiza mediante silueta octogonal D26 e icono/chispa interior crema `#F7F4EC` con contraste **8.21 : 1**.
3. En `godot/ui/hud/hud.tscn` y `godot/ui/tickets/order_ticket.tscn`:
   - Verificar que los contenedores usan los `StyleBoxFlat` del tema o colores exactos de la paleta v3 (`#1D3557`, `#2A2320`, `#EDE8DF`, `#F7F4EC`, `#F2C230`, `#4FA05A`, `#C8402F`), sin alterar tamaños, anclas ni posiciones de layout (`test_level_01.gd` comprueba los rectángulos de HUD y tickets).
4. Crear `godot/tests/unit/test_ui_theme_v3.gd` que compruebe los colores, opacidad `1.0`, bordes de `2 px` y razones de contraste WCAG 2.1 del tema, de `StickerInk.INK` y del anillo delimitador de pegatinas sobre caja y suelo.

## Constraints
- `godot/ui/**` no puede referenciar tipos 3D ni 2D de mundo (regla 4 de `CLAUDE.md`).
- No alterar las dimensiones ni la posición de `HUD` ni `OrderTicketsPanel` verificadas en `test_level_01.gd` (`panel.position.y == 8.0 ± 0.5`, `ticket.end.y <= 260.0`).

## Acceptance
- [ ] AC1 Given `godot/ui/theme/default_theme.tres`, When `test_ui_theme_v3.gd` inspecciona `UiPanel`, `UiHeader` y `DisplayWell`, Then `UiPanel.bg_color` es `#1D3557` con `a == 1.0` y borde de `2 px` en `#EDE8DF`, y `UiHeader`/`DisplayWell` usan `#2A2320`.
- [ ] AC2 Given los colores de texto `#F7F4EC` y `#F2C230` sobre `#1D3557` y `#2A2320`, When `test_ui_theme_v3.gd` calcula su contraste WCAG 2.1, Then todos son **≥ 7.37 : 1** (`11.24 : 1`, `14.05 : 1`, `7.38 : 1` y `9.22 : 1`).
- [ ] AC3 Given `StickerInk.INK`, `badge_row.gd` y `ticket_entry.gd`, When `test_ui_theme_v3.gd` los evalúa, Then `StickerInk.INK` es `#2A2320`, todos los discos de pegatina aplican el anillo exterior delimitador de `INK` con contraste frente a la caja roja `#C8402F` **≥ 3.10 : 1** (`3.11 : 1`) y frente al suelo `#C4A882` **≥ 6.80 : 1** (`6.82 : 1`), los contrastes disco/anillo son **≥ 3.24 : 1** en discos claros/medios, y el picante aplica silueta octogonal D26 con icono interior crema `#F7F4EC` (**8.21 : 1**).
- [ ] AC4 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
1. Tema (§7): `UiPanel` navy opaco con borde 2 px `#EDE8DF`, radio 4 y sombra 3 px; `UiHeader`
   y `DisplayWell` en `#2A2320` con borde 1 px y radio 3 (márgenes de contenido intactos: el
   layout no cambia). Texto `#F7F4EC`; cifras (`FigureLabel`, `DisplayLabel`, `digits_color`) en
   `#F2C230`; `CaptionLabel` en `#EDE8DF`; colores de barra/aviso/pista y `RoundHUD` a la paleta.
2. `StickerInk`: `INK = #2A2320`, `CREAM`, `HOT_RING` (único punto del anillo del picante, P4),
   `contrast()`/`luminance()` WCAG 2.1, `ring_color()`, `is_hot()`; el icono va en `INK` si
   contrasta ≥ 3 : 1 con el disco y en crema si no (solo el picante).
3. `ticket_entry.gd`: anillo `ring_color` en todos los discos; picante octogonal
   (`corner_detail = 1`, chaflán 1/(2+√2)). `badge_row.gd`: silueta blanca (círculo u
   octógono) rellena con el color del condimento y el anillo en un `Sprite3D` hijo `Ring` sin
   teñir, para que quede exactamente en `INK`.
4. Escenas: solo colores (aviso de mando en `#F2C230`; pista/barra de paciencia de
   `order_ticket.tscn` en `#2A2320`/`#4FA05A`), sin tocar tamaños ni anclas.
5. `test_ui_theme_v3.gd` (AC1–AC3) y actualización de los asserts v2 de dos tests (ver Evidence).

## Evidence
- `tools/verify.sh` completo en verde: 1350/1350 tests, 116 scripts, smoke OK
  (`test_ui_theme_v3.gd` 6/6). `tools/check_owns.py jrmougan/pul-185 main` limpio.
- **Owns ampliados** con aprobación del coordinador: `godot/tests/integration/test_order_tickets.gd*`
  y `godot/tests/integration/test_hud.gd*`. Solo se cambiaron los asserts que fijaban la paleta
  v2 (UiPanel `#13202f`/`#8e9494`, cifras `#5b8db8`, «solo la sal lleva anillo», icono blanco);
  ahora comprueban anillo en todos los discos, icono crema del picante, anillo 3D sin teñir y
  colores v3. No se quitó ninguna comprobación de comportamiento.
- Contrastes comprobados en el test (WCAG 2.1): crema 11.24 (navy) / 14.05 (burnt); ámbar
  7.38 / 9.22; anillo `INK` 3.11 sobre caja `#C8402F` y 6.82 sobre suelo `#C4A882`; disco/anillo
  ≥ 3.24 en dulce, cachelos, aceite y sal; icono crema sobre picante 8.21.
- Capturas (`xvfb-run -a`, `--audio-driver Dummy`, 1280×720; script
  `docs/evidence/PUL-185/capture_pul185.gd`):
  - [`v3_hud_tickets_pegatinas.png`](../evidence/PUL-185/v3_hud_tickets_pegatinas.png): HUD,
    dos tickets (dulce+cachelos, picante+cachelos) y las pegatinas 3D sobre las cajas en el suelo.
  - [`hud_v3.png`](../evidence/PUL-185/hud_v3.png): panel navy con pozos `#2A2320` y cifras ámbar.
  - [`pegatinas_zoom_picante_p4.png`](../evidence/PUL-185/pegatinas_zoom_picante_p4.png):
    **P4**, picante con la regla actual (anillo `INK`, disco/anillo 1.71 : 1, octógono e icono
    crema) junto a dulce y cachelos a 96 px.
- **Pendiente del responsable (P4)**: si se aprueba otro anillo para el picante basta con cambiar
  `StickerInk.HOT_RING` (`godot/ui/widgets/sticker_ink.gd`); el test lo lee de ahí.
- Fuera de alcance (sin cambio): `UiCard`, `BrandLabel` y botones del menú (no los nombra §7);
  la barra de paciencia sigue con dos estados (verde / rojo ≤ 25 %) porque la lógica está en
  `order_ticket.gd`, fuera de owns; el ámbar intermedio de §7.3 queda para otra ficha.
- El icono del dulce pasa a `INK` sobre `#D6361F` (3.24 : 1) según la tabla §6.2 («anillo e icono
  interior `StickerInk`»); antes era blanco.
