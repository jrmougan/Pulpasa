# PUL-134: flecha de borde y zona de botones como zonas tapadas

Contrato: ADR-005 Enmienda D26 E5 («Banda superior tapada»). Decisión del responsable (vía coordinador)
para el punto 2: **opción C**. Se implementa la opción A (recorte este con la zona de botones cuando el
activo está en su franja) y AC2 se comprueba con el activo en la plaza de cada estación. El caso 09
queda como limitación para una ficha de diseño posterior (opción B, ver abajo).

## Reproducir

Desde la raíz, con pantalla (perfil táctil, sin safe area simulada):

```sh
godot --path godot --resolution 2340x1080 --position 0,0 -s ../docs/evidence/PUL-134/capture_boot.gd \
  -- --touch --out=$PWD/docs/evidence/PUL-134 --tag=2340x1080-despues
```

Las capturas «antes» usan el mismo script con `camera_rig.gd` y `camera_follow.gd` de la base
(`d269708`) puestos de forma temporal. Escenas: `01` flecha con el inactivo bajo la banda, `02` activo en
el borde este, `03` contador 3/6 en el pasaplatos 06 visto desde su plaza y `04` caso 09 (caja en el
pasaplatos 05 con el activo en las ollas). Las medidas están en `<tag>-medidas.json`, en px reales.

## Medidas (px reales)

Banda tapada: `top_band_max_px` = 200 a 1080 (68,5 px a 370). Zona de botones: x ≥ ancho − 390, y ≥ 600
(a 1080).

| Medida | 2340×1080 antes | después | 1920×1080 antes | después | 800×370 antes | después |
|---|---|---|---|---|---|---|
| M-2: centro del inactivo (y) | 2,0 (tapado) | 2,0 (tapado) | 2,0 | 2,0 | 3,1 | 3,1 |
| M-2: ¿flecha? | **no** | sí | **no** | sí | **no** | sí |
| M-2: borde superior de la flecha (y) | — | 232,0 (≥ 200) | — | 232,0 (≥ 200) | — | 100,5 (≥ 68,5) |
| Activo en (9,4, 3,0): borde derecho del cuerpo (x) | 2242,6 (**bajo los botones**) | 1913,0 (< 1950) | 1823,2 (**bajo**) | 1493,7 (< 1530) | 766,3 (**bajo**) | 653,4 (< 666) |
| Contador 3/6 en el pasaplatos 06 desde su plaza | fuera | fuera | fuera | fuera | fuera | fuera |
| Caso 09: contador en el pasaplatos 05, activo en las ollas | **bajo** | **bajo** (limitación) | fuera de pantalla | fuera de pantalla | **bajo** | **bajo** (limitación) |

Rectángulos completos en los JSON (`m2`, `east_edge`, `pass_slot_06_from_its_stand`,
`case_09_pass_slot_05_from_pots`).

## AC2 con test (`test_camera_button_zone.gd`)

Con el nivel real y el activo en reposo en la plaza de cada estación con widget (6 pasaplatos con caja
y contador N/6 visibles, ambos lados; 2 ollas con sus anillos, al sur y en la olla; cuenco con su
medidor, ambos lados), **0 cruces** con la zona de botones a 2340×1080, 1920×1080 y 800×370. El activo
en el borde este dentro de la franja de botones queda a su izquierda (sin el recorte este el test falla:
cuerpo en x 2131–2239 a 2340).

## Limitación: caso 09 (para una ficha de diseño, opción B)

Con el activo en las ollas (plaza z = −3,1), la banda empuja la cámara al norte y la fila de pasaplatos
(z = 0) cae en la franja de botones (y ≈ 604–784 px a 1080). Una caja con contador en los pasaplatos del
este queda bajo los botones aunque el activo no la esté usando. Sonda GUT (SubViewport, nivel real, en
reposo):

| Resolución | Pasaplatos con el contador bajo los botones |
|---|---|
| 2340×1080 | 04, 05 y 06 (contador hasta x = 2268 frente a la zona en x ≥ 1950) |
| 1920×1080 | 04 (05 y 06 quedan fuera de pantalla) |
| 800×370 | 04, 05 y 06 |

El recorte este no actúa aquí: el activo está arriba (fuera de la franja) y el foco está en el límite
oeste (x = −0,42 a 2340). Sesgar la cámara al este arreglaría 2340 y 800×370, pero a 1920 no se puede
despejar el pasaplatos 06 sin sacar al activo de la safe area cuando está en la nevera. Por eso se
propone resolverlo moviendo widgets o cambiando el diseño (opción B).
