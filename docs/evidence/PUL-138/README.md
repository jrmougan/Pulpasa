# PUL-138: botones táctiles en fila y zona de botones de D27 (B-AC5)

Capturas del caso 09 con el código de PUL-138: `level_01` real, perfil táctil, safe area nula, una caja
con contador visible en cada pasaplatos 01-06 y el activo en reposo en la olla oeste, en su plaza
(z −3,1) y en el extremo norte (z −3,4). El contorno rojo es la zona de botones que usa `CameraRig`
(ADR-005 E4, D27.2), leída de `CameraRig._button_zone`.

```sh
for r in 2340x1080 1920x1080 800x370; do
  godot --path godot --resolution $r --position 0,0 -s ../docs/evidence/PUL-138/capture_boot.gd \
    -- --touch --out=$PWD/docs/evidence/PUL-138 --tag=$r
done
```

| Resolución | Zona (x, y, ancho, alto) px | Acción (centro) | Cambiar (centro) | Solape máx. z −3,1 | Solape máx. z −3,4 |
|---|---|---|---|---|---|
| 2340×1080 | 1950, 840, 390, 240 | 2202, 942 | 2028, 972 | 0 | 0 |
| 1920×1080 | 1530, 840, 390, 240 | 1782, 942 | 1608, 972 | 0 | 0 |
| 800×370 | 666, 287,8, 133,6, 82,2 | 752,3, 322,7 | 692,7, 333 | 0 | 6,4 (≤ 8, residuo aceptado en D27) |

Detalle por pasaplatos en `<res>-medidas.json`. Capturas: `<res>-caso09-z3_1.jpg` y `<res>-caso09-z3_4.jpg`.

## Tests
- B-AC1 `test_touch_layout.gd`: cambiar en (2028, 972) a 2340×1080 nula, bordes inferiores alineados,
  24 px de hueco; (1896, 909) con la safe de diseño; zonas táctiles sin solape; zona anclada con ambas
  safe areas.
- B-AC2 `test_touch_button_zone.gd`: 3 resoluciones × {nula, 132/0/132/63}; imprime la tabla de holguras.
  La holgura superior del botón de acción es 0 (la zona se definió en el borde de su margen de toque).
  Con la safe de diseño a 800×370 es −0,4: `SafeAreaMargin` redondea los márgenes a enteros
  (21,6 → 22) y la cámara no; el test admite 1 unidad de lienzo, como `test_touch_layout.gd`.
- B-AC3 `test_camera_button_zone.gd`: con safe area inferior nula (nula y derecha 132) 0 contadores en la
  zona en z −3,1 y z −3,4 en las 3 resoluciones (el test da 0 también a 800×370 en z −3,4: `_put` sin
  física coloca al activo en x de la olla; la captura en juego real mide 6,4). Con la safe de diseño se
  registra el solape (limitación D27.3, no se exige): 6,6 / 35,1 px a 2340 y 1920 (z −3,1 / −3,4) y
  2,2 / 12,0 px a 800×370.
- B-AC4: AC2 de PUL-134 (`test_bac4_ac2_*`) en verde con safe nula y la de diseño; escritorio sin
  `TouchControls` (`test_ac21_*` de `test_touch_layout.gd`).
