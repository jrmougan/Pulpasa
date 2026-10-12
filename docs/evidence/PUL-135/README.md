# PUL-135: zona de botones de la cámara con safe area derecha

Contrato: ADR-005 E4 (zonas reservadas) y E5 («Zona de botones como rectángulo tapado»). Solo tests: no
cambia código de producción ni datos. Ningún test ha revelado un botón fuera de la zona ni un fallo de
AC2 con safe area.

## Reproducir

```sh
cd godot
godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_touch_button_zone -glog=2 -gexit
godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_camera_button_zone -gexit
```

`test_touch_button_zone.gd` imprime con `gut.p` cada rectángulo de toque frente a la zona (tabla de
abajo). Los `TouchControls` reales (`touch_controls.tscn`, `touch_config.tres`) se montan en un
`SubViewport` del tamaño de la resolución (unidades de lienzo = px reales) y la safe area se inyecta con
`apply_safe_rect`, escalada por el alto (132 px a 1080 = 45 px a 370 tras el redondeo de
`SafeAreaMargin`). La zona se calcula como `CameraRig._button_zone` (`UiProfile` móvil +
`UiScale.px_to_units`): x ≥ ancho − 390, y ≥ 600 a 1080, sin descontar la safe area.

## AC1: zona táctil de los botones frente a la zona de la cámara (px reales)

Rectángulo de toque = centro ± `get_hit_radius()` (radio visible + margen de toque: 90 + 12 px la
acción, 60 + 0 px el cambio, a 1080). Holgura = borde del toque − borde de la zona (≥ 0 = dentro). Por
la derecha y por abajo los botones quedan dentro del lienzo (margen de 48 px), así que la zona los
encierra entera si las holguras izquierda y superior son ≥ 0.

| Resolución | Safe area (izq/arr/der/abajo a 1080) | Zona (x ≥, y ≥) | Acción: toque x, y | holgura izq / arriba | Cambio: toque x, y | holgura izq / arriba |
|---|---|---|---|---|---|---|
| 2340×1080 | nula | 1950, 600 | 2100, 840 | 150 / 240 | 2142, 708 | 192 / 108 |
| 2340×1080 | 0/0/132/0 | 1950, 600 | 1968, 840 | **18** / 240 | 2010, 708 | 60 / 108 |
| 2340×1080 | 132/0/132/63 | 1950, 600 | 1968, 777 | **18** / 177 | 2010, 645 | 60 / **45** |
| 1920×1080 | nula | 1530, 600 | 1680, 840 | 150 / 240 | 1722, 708 | 192 / 108 |
| 1920×1080 | 0/0/132/0 | 1530, 600 | 1548, 840 | **18** / 240 | 1590, 708 | 60 / 108 |
| 1920×1080 | 132/0/132/63 | 1530, 600 | 1548, 777 | **18** / 177 | 1590, 645 | 60 / **45** |
| 800×370 | nula | 666,4, 205,6 | 717,8, 287,8 | 51,4 / 82,2 | 732,2, 242,6 | 65,8 / 37,0 |
| 800×370 | 0/0/132/0 | 666,4, 205,6 | 672,8, 287,8 | **6,4** / 82,2 | 687,2, 242,6 | 20,8 / 37,0 |
| 800×370 | 132/0/132/63 | 666,4, 205,6 | 672,8, 265,8 | **6,4** / 60,2 | 687,2, 220,6 | 20,8 / **15,0** |

Con la safe area derecha de diseño la acción llega a ancho − 372 px (1968 a 2340), como dice E5: 18 px
de holgura a 1080 (6,4 px a 370, 18 × 370/1080 menos el redondeo del margen). Una safe area derecha de
más de 150 px a 1080 sacaría la acción de la zona. El botón más justo por arriba es el cambio con la
safe area inferior de diseño (45 px a 1080). La pausa (esquina superior derecha, banda superior de E4)
no pertenece a la zona: el test comprueba que su toque queda por encima de ella en los 9 casos.

## AC2: activo y widgets de su estación con safe area derecha 132 px

`test_camera_button_zone.gd` repite los dos tests de AC2 de PUL-134 con `set_safe_margins` nula y con
safe area derecha 132 px a 1080 (escalada al alto): activo en reposo en la plaza de cada estación con
widget (6 pasaplatos con caja y contador N/6, ambos lados; 2 ollas con sus anillos; cuenco con su
medidor, ambos lados) y activo en el borde este dentro de la franja de botones. **0 cruces** con la zona
a 2340×1080, 1920×1080 y 800×370 (421 asserts en verde). Es lo esperado: `CameraRig` solo usa la safe
area superior (banda tapada) y la de la flecha; la zona de botones no descuenta la derecha, así que el
encuadre no cambia y la garantía depende solo de que los botones quepan en la zona (AC1).
