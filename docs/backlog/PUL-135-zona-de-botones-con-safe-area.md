---
id: PUL-135
title: Comprobar la zona de botones de la cámara con safe area derecha
status: in_progress
milestone: M3e
role: gameplay-engineer
deps: [PUL-134]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_camera_button_zone*, godot/tests/integration/test_touch_button_zone*, docs/evidence/PUL-135/**, docs/backlog/PUL-135-zona-de-botones-con-safe-area.md]
touches_scenes: []
---

## Target
Pendiente de la revisión de PUL-134 (nota del arquitecto). `CameraRig._button_zone` usa la zona reservada
de E4 (x ≥ ancho − `UiProfile.button_zone_width_px`, y ≥ `button_zone_top_px`) sin descontar la safe area
derecha, mientras que `TouchControls` coloca los botones dentro de ella. Por cálculo caben (con los 132 px
de diseño llegan a ancho − 372 px), pero ningún test lo cubre: `test_camera_button_zone.gd` usa safe area
cero. Contrato: ADR-005 E4 y E5 (nota «Zonas tapadas de la flecha y de los botones»).

## Change
1. Test que, con los `TouchControls` reales (`touch_config.tres`) y safe area derecha de diseño (132 px a
   2340×1080) y nula, compruebe que el rectángulo de cada botón, con su margen de toque, cae dentro de la
   zona de botones que usa la cámara, a 2340×1080, 1920×1080 y 800×370.
2. Repetir la garantía de AC2 de PUL-134 (activo y widgets de su estación fuera de la zona, desde la plaza
   de cada estación) con safe area derecha no nula.

## Constraints
- Solo tests y evidencia: no se cambia código de producción ni datos. Si un test revela que un botón sale
  de la zona o que AC2 falla con safe area, **no lo arregles**: pregunta al coordinador (sería cambio de
  E4 o de `touch_config.tres`, con su ficha).
- Lectura de `TouchControls`, `UiProfile` y `CameraRig` por API pública o `set_safe_margins`; nada de
  rutas absolutas de nodos. Tipado estático.

## Acceptance
- [ ] AC1 Given safe area derecha 132 px (y nula) When se montan los `TouchControls` reales a 2340×1080,
  1920×1080 y 800×370 Then cada botón (con margen de toque) queda dentro de la zona de botones de la
  cámara → test nuevo.
- [ ] AC2 Given safe area derecha 132 px When el activo está en la plaza de cada estación Then ni él ni
  los widgets de su estación tocan la zona, en las 3 resoluciones → `test_camera_button_zone.gd`.
- [ ] AC3 Medidas en px en `docs/evidence/PUL-135/README.md`; `tools/verify.sh` en verde; `check_owns`
  limpio.

## Plan

## Evidence
