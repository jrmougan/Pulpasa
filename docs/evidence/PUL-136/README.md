# PUL-136: contadores del pasaplatos bajo los botones (caso 09)

Propuesta de diseño en `docs/design/features/controles-tactiles.md`, sección «Contadores del pasaplatos
bajo los botones». Aquí están las medidas que la sostienen. Ningún cambio de código, escenas ni datos:
las alternativas se simulan en tiempo de ejecución sobre la escena real.

## Reproducir

Desde la raíz, con pantalla (perfil táctil, safe area nula como en PUL-134):

```sh
godot --path godot --resolution 2340x1080 --position 0,0 -s ../docs/evidence/PUL-136/probe_boot.gd \
  -- --touch --out=$PWD/docs/evidence/PUL-136 --tag=2340x1080
# alcance al norte (reach.json):
godot --path godot --resolution 1280x720 --position 0,0 -s ../docs/evidence/PUL-136/probe_boot.gd \
  -- --touch --reach --out=$PWD/docs/evidence/PUL-136
```

`probe_pul136.gd` pone una caja con contador visible en cada pasaplatos (01-06), deja al activo en
reposo en cada olla (x −1,3 y 0,7) y mide el rectángulo del contador en px reales frente a:

- `zone_now`: la zona de botones de E4 (x ≥ ancho − 390, y ≥ 600 a 1080);
- `discs_now`: los discos táctiles reales (radio visible + 12 px de margen) de acción y cambiar;
- `zone_b`: la zona con los botones en fila (alternativa B: y ≥ alto − 240 px a 1080).

Variantes del contador (alternativa A): `actual`, `A1_oeste` (−0,85 m en x, −0,3 m en y),
`A2_arriba_0_6`, `A3_arriba_1_2`. Capturas por resolución: `01-actual`, `02-A1-contador-al-oeste`,
`03-A3-contador-1-2-m-mas-alto`, `04-B-botones-en-fila` (botón de cambiar movido a mano). Todas con el
activo en la plaza de la olla oeste (−1,3, −3,1).

## Plazas medidas

- z −3,1: plaza de la olla (la de `test_camera_button_zone.gd`).
- z −3,4: lo más al norte que llega el activo caminando en las ollas (`reach.json`: −3,40 en las dos
  ollas, −3,49 como máximo en x −3,0). El centro de la olla (z −4,0, cota del test de PUL-134) no es
  alcanzable: la colisión de la olla ocupa z −4,39…−3,61 y el personaje sale despedido a z −4,6.

## Resultados (px reales)

Borde inferior del contador más bajo de 04-06 y pasaplatos que cruzan cada zona. «O» = olla oeste
(x −1,3), «E» = olla este (x 0,7).

| Res. | Plaza | Variante | Borde inf. | Zona E4 | Discos actuales | Zona B (y ≥) |
|---|---|---|---|---|---|---|
| 2340×1080 | O −3,1 | actual | 797,8 | 04-06 | 05-06 | — (840) |
| | O −3,4 | actual | 828,0 | 04-06 | 05-06 | — |
| | E −3,1 | actual | 799,6 | 05-06 | 06 | — |
| | E −3,4 | actual | 828,0 | 05-06 | 06 | — |
| | O −3,4 | A1 oeste | 864,4 | 05-06 | 06 | 05-06 |
| | O −3,4 | A2 +0,6 | 755,0 | 04-06 | 05-06 | — |
| | O −3,4 | A3 +1,2 | 682,1 | 04-06 | — | — |
| 1920×1080 | O −3,1 | actual | 797,8 | 04 | 04 | — (840) |
| | O −3,4 | actual | 828,0 | 04 | 04 | — |
| | E −3,1 | actual | 799,6 | 04-06 | 05-06 | — |
| | E −3,4 | actual | 828,0 | 04-06 | 05-06 | — |
| | O −3,4 | A1 oeste | 864,4 | 04-05 | 04-05 | 04-05 |
| | E −3,4 | A3 +1,2 | 682,1 | 04-06 | — | — |
| 800×370 | O −3,1 | actual | 283,9 | 04-06 | 05-06 | — (287,8) |
| | O −3,4 | actual | 294,2 | 04-06 | 05-06 | **04-06** (6,4 px) |
| | E −3,1 | actual | 284,5 | 05-06 | 06 | — |
| | E −3,4 | actual | 294,2 | 05-06 | 06 | **05-06** (6,4 px) |
| | O −3,4 | A2 +0,6 | 269,2 | 04-06 | 05-06 | — |
| | O −3,4 | A3 +1,2 | 244,2 | 04-06 | 05-06 | — |

Con B, el botón de cambiar queda en (2028, 972) a 2340×1080, (1608, 972) a 1920×1080 y (692,7, 333,0)
a 800×370 (radio táctil 72 px a 1080); su margen de toque empieza en x = ancho − 384 px (dentro de los
390 de la zona con safe area nula). Con la safe area derecha de diseño (132 px) llegaría a ancho − 516
px: la zona tiene que medirse desde la safe area o ensancharse (contrato E4, ver la feature).

Rectángulos completos en `<res>-medidas.json` (`stands.<x,z>.<variante>.<PassSlot>`); `box_body` es
el cuerpo de la caja sin el contador.

## Lectura

- **A** no resuelve: al oeste el contador sigue bajo los botones y se monta con el vecino; subido
  1,2 m sale de los botones visibles en la plaza pero no de la zona de E4 ni a 800×370 en z −3,4.
- **B** deja los contadores fuera en la plaza (z −3,1) en las 3 resoluciones y en z −3,4 a 1080 de alto
  (12 px de margen); a 800×370 en z −3,4 quedan 6,4 px de solape con el margen de toque (2,3 px con el
  botón visible).
- **B + A2** (contador +0,6 m) es 0 en todos los casos, a costa de cambiar la caja en escritorio.
