---
id: PUL-137
title: Enmendar ADR-005 E4 para los botones en fila y la zona de botones con safe area
status: in_progress
milestone: M3e
role: godot-architect
deps: [PUL-136]
orca_task: null
unity_sources: []
owns: [docs/arch/ADR-005-dimension-3d-2d.md, docs/arch/scene-tree.md, docs/evidence/PUL-137/**, docs/backlog/PUL-137-adr-005-e4-botones-en-fila.md]
touches_scenes: []
---

## Target
Decisión D27 (`docs/design/decisions.md`, gate de PUL-136): botones táctiles en fila y zona de botones
más baja. Diseño y medidas: `docs/design/features/controles-tactiles.md` «Contadores del pasaplatos bajo
los botones» y `docs/evidence/PUL-136/README.md`. Contrato afectado: ADR-005 Enmienda D26 E4 (zona
reservada de botones) y la nota «Zonas tapadas de la flecha y de los botones» de E5.

## Change
Enmienda a E4 (y referencia en E5) que fije:
1. Colocación: botón de cambiar a la izquierda del de acción, borde inferior alineado y hueco horizontal
   de 24 px a 1080 (sustituye «sobre el de acción»).
2. Zona de botones: y ≥ alto − 240 px a 1080 (`UiProfile.button_zone_top_px` 600 → 840 en el perfil
   móvil, o expresado desde abajo si es más robusto) y su relación con la safe area derecha (la duda de
   PUL-135): con safe area derecha los botones en fila llegan a ancho − 516 px, así que la zona debe
   descontarla o ensancharse. Decide la forma y deja escrito qué lee la cámara (`GameState.ui_profile`
   y safe area) sin que conozca `TouchControls`.
3. La limitación del caso 09 de E5 pasa a resuelta, con el residuo aceptado (≤ 8 px a 800×370 con el
   activo en z −3,4).
4. Qué ficheros y campos cambian para la ficha de implementación PUL-138 (datos en `.tres`).

## Constraints
- Solo documentación de arquitectura (tus owns). Sin código ni datos.
- Escritorio y Local 2P sin cambios. Sin señales nuevas salvo que sea imprescindible (`signals.md` es
  catálogo cerrado: si hiciera falta, avisa al coordinador).
- Gate humano: el coordinador presenta la enmienda al responsable antes del merge.

## Acceptance
- [x] AC1 ADR-005 E4/E5 recogen los puntos 1-4 con valores numéricos a 1080 y su escala.
- [x] AC2 Lista exacta de ficheros/campos a cambiar en PUL-138 en la Evidence de esta ficha.
- [x] AC3 `tools/verify.sh` en verde y `check_owns` limpio.

## Plan
1. Leer D27, la propuesta de `controles-tactiles.md`, las medidas de PUL-135/136 y el código actual
   (`touch_controls.gd`, `ui_profile.gd`, `.tres`, `CameraRig._button_zone`).
2. Decidir la forma de la zona con safe area: anclada a la esquina inferior derecha de la safe area,
   alto expresado desde abajo (`button_zone_height_px` 240 sustituye a `button_zone_top_px`).
3. Recalcular el caso 09 con la zona nueva y las dos safe areas a partir de los JSON de PUL-136
   (`docs/evidence/PUL-137/zone_d27.py`). Hallazgo (safe area inferior) consultado al coordinador.
4. Redactar ADR-005 «Enmienda D27» (D27.1-D27.4), referencias en E3, E4 y E5, y `scene-tree.md` §9.3/§9.5.
5. `tools/verify.sh`, `check_owns`, commit.

## Evidence
- ADR-005: cabecera, E3 (campo), E4 (zona y remisión), E5 («Zona de botones como rectángulo tapado» y
  caso 09 resuelto) y sección nueva **Enmienda D27** (D27.1 colocación, D27.2 zona con safe area y qué
  lee la cámara, D27.3 caso 09 con residuos, D27.4 qué no cambia). `scene-tree.md` §9.3 y §9.5.
- Recálculo: `docs/evidence/PUL-137/README.md`, `zone_d27.py`, `zone_d27.txt`. Con safe area nula
  reproduce PUL-136 (0 a 1080; 6,4 px a 800×370 en z −3,4). **Con safe area inferior de diseño (63 px)
  el caso 09 vuelve** (21-23 px en la plaza, 51 px en z −3,4 a 1080; 18 / 28 px a 800×370): por decisión
  del responsable (opción A, vía coordinador) queda como limitación conocida en D27.3.
- Fuera de mis owns, para el coordinador: ADR-004 §6.2 (árbol de `touch_controls.tscn`, «encima del de
  acción») y `controles-tactiles.md` AC3 quedan sustituidos por D27.1 y conviene alinearlos.

### Ficheros y campos para PUL-138 (AC2)
Datos (`.tres`):
- `godot/resources/ui_profile.gd`: quitar `button_zone_top_px: float = 600.0`; añadir
  `button_zone_height_px: float = 240.0` (alto de la zona desde el borde inferior de la safe area) y
  actualizar el comentario de zonas (botones: x ≥ ancho − safe der. − width, y ≥ alto − safe inf. − height).
- `godot/data/config/ui_profile_mobile.tres`: `button_zone_top_px = 600.0` → `button_zone_height_px = 240.0`;
  `button_zone_width_px = 390.0` sin cambios.
- `godot/data/config/ui_profile_desktop.tres`: mismo renombrado (`button_zone_height_px = 240.0`); sin uso
  en escritorio.
- `godot/data/config/touch_config.tres` y `godot/resources/touch_config.gd`: **sin cambios** (el hueco
  horizontal usa `button_gap_px_1080` = 24).

Código:
- `godot/ui/touch/touch_controls.gd` `refresh_layout`: `switch_center = action_center +
  Vector2(-(big / 2.0 + gap + small / 2.0), big / 2.0 - small / 2.0)` (antes encima). Acción y pausa igual.
- `godot/entities/camera/camera_rig.gd` `_button_zone(canvas)`: `m := _safe_margins(canvas)`;
  `left = canvas.x - m.z - px_to_units(ui.button_zone_width_px)`, `top = canvas.y - m.w -
  px_to_units(ui.button_zone_height_px)`; `Rect2(left, top, canvas.x - left, canvas.y - top)`. Lo usan
  `_in_button_strip`, `east_cover_m` en `_target_focus` y `_place_arrow` sin más cambios.
- `godot/ui/hud/hud_sandbox.gd` (l. 43-49): dibujo de la zona con la misma fórmula.

Tests:
- `godot/tests/unit/test_game_state.gd` (l. 265-267): `button_zone_height_px == 240.0`.
- `godot/tests/integration/test_touch_layout.gd`: `test_ac3_switch_button_is_120_px_and_24_px_above_…` →
  B-AC1 (centro (2028, 972) ± 2 a 2340×1080 nula, borde inferior alineado ± 2, hueco horizontal 24 ± 2);
  `_assert_touch_rects_in_button_zone` con la zona anclada (y ambas safe areas); `test_layout_scales_…`.
- `godot/tests/integration/test_touch_button_zone.gd`: `_zone` con la fórmula de D27.2, docstring, tabla
  de holguras; B-AC2 con safe nula y 132/0/132/63 en las 3 resoluciones (y = alto − safe inf. − 240·k).
- `godot/tests/integration/test_camera_button_zone.gd` (l. 52-53 `_zone`): fórmula nueva; caso 09 (B-AC3)
  con caja en 01-06 y activo en cada olla (z −3,1 y −3,4); AC2 de PUL-134 (B-AC4) con las dos safe areas.
  Con safe area inferior B-AC3 no se exige (limitación conocida D27.3); se puede registrar el solape.
- `godot/tests/integration/test_touch_hud_layout.gd` (l. 185-189): zona de botones con la fórmula nueva.
- `godot/tests/integration/test_camera_follow.gd` (l. 121, margen este): `east_cover` = ancho de la zona
  incluida la safe der. (sin cambio con safe nula).
- Escenas: ninguna (`touch_controls.tscn` no cambia; la colocación es código). Capturas del caso 09
  (B-AC5) en `docs/evidence/PUL-138/`.
