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
- [x] AC1 Given safe area derecha 132 px (y nula) When se montan los `TouchControls` reales a 2340×1080,
  1920×1080 y 800×370 Then cada botón (con margen de toque) queda dentro de la zona de botones de la
  cámara → test nuevo.
- [x] AC2 Given safe area derecha 132 px When el activo está en la plaza de cada estación Then ni él ni
  los widgets de su estación tocan la zona, en las 3 resoluciones → `test_camera_button_zone.gd`.
- [x] AC3 Medidas en px en `docs/evidence/PUL-135/README.md`; `tools/verify.sh` en verde; `check_owns`
  limpio.

## Plan
- `godot/tests/integration/test_touch_button_zone.gd` (nuevo, AC1): `TouchControls` reales
  (`touch_controls.tscn` con `touch_config.tres`) dentro de un `SubViewport` del tamaño de cada
  resolución (unidades de lienzo = px reales) con safe area nula, solo derecha de diseño (132 px a 1080)
  y la de diseño completa (132 / 0 / 132 / 63), inyectada con `apply_safe_rect`. El cuadrado de cada botón
  de la zona (acción y cambio: centro ± `get_hit_radius()`, margen de toque incluido) debe caer dentro de
  la zona de botones que usa la cámara, calculada como `CameraRig._button_zone` desde `UiProfile` móvil y
  `UiScale.px_to_units` (sin llamar al método privado). La pausa va en la esquina superior (banda de E4),
  no en la zona: se comprueba que queda por encima de ella.
- `godot/tests/integration/test_camera_button_zone.gd` (AC2): los dos tests de AC2 recorren también la
  safe area derecha de diseño (`set_safe_margins` con 132 px a 1080 escalados al alto); el resto igual.
- `docs/evidence/PUL-135/README.md` (AC3): medidas en px de cada botón frente a la zona.
- Sin código de producción ni datos; si algo falla, se pregunta al coordinador.

## Evidence
`docs/evidence/PUL-135/README.md`. AC1: `test_touch_button_zone.gd` (2 tests) con safe area nula,
derecha 132 px y la de diseño completa (132/0/132/63) a 2340×1080, 1920×1080 y 800×370: acción y cambio
(con margen de toque) dentro de la zona; la más justa, la acción con safe area derecha, a 18 px del borde
izquierdo de la zona a 1080 (6,4 px a 800×370); la pausa queda en la banda superior. AC2:
`test_camera_button_zone.gd` con safe area derecha 132 px, 0 cruces (421 asserts). No ha hecho falta
cambiar E4 ni `touch_config.tres`. `tools/verify.sh` en verde y `check_owns` limpio.
