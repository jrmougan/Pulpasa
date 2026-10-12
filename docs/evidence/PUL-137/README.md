# PUL-137: zona de botones en fila con safe area (ADR-005 Enmienda D27)

Solo documentación. La enmienda está en `docs/arch/ADR-005-dimension-3d-2d.md` («Enmienda D27»).

## Recálculo del caso 09 con la zona nueva

`zone_d27.py` toma los rectángulos de contador que midió PUL-136 (`docs/evidence/PUL-136/<res>-medidas.json`,
variante `actual`, activo en reposo en las dos ollas en z −3,1 y −3,4) y los cruza con:

- la zona de D27.2: `x ≥ ancho − (safe der. + 390)·k`, `y ≥ alto − (safe inf. + 240)·k`, `k = alto / 1080`;
- los discos táctiles en fila (D27.1): acción en (ancho − (safe der. + 138)·k, alto − (safe inf. + 138)·k),
  radio 102·k; cambiar a (−174, +30)·k de ella, radio 72·k (con margen de toque, el caso peor).

```sh
python3 docs/evidence/PUL-137/zone_d27.py docs/evidence/PUL-136   # salida en zone_d27.txt
```

Es válido reutilizar los rectángulos con otra safe area derecha o inferior porque `CameraRig` solo
descuenta la superior (0 en las dos safe areas probadas) y el activo en las ollas no entra en la franja
de botones (no actúa el recorte este). Con safe area nula reproduce las cifras de PUL-136 para la
zona B (0 a 1080, 6,4 px a 800×370 en z −3,4), lo que valida el cálculo.

| Resolución | Safe area | Zona (x ≥, y ≥) | Solape plaza z −3,1 (O · E) | Solape z −3,4 (O · E) | Bajo los discos |
|---|---|---|---|---|---|
| 2340×1080 | nula | 1950, 840 | 0 · 0 | 0 · 0 | — |
| 1920×1080 | nula | 1530, 840 | 0 · 0 | 0 · 0 | — |
| 800×370 | nula | 666,4, 287,8 | 0 · 0 | 6,4 · 6,4 | z −3,4: 05-06 · 06 |
| 2340×1080 | 132/0/132/63 | 1818, 777 | 20,8 · 22,6 | 51,0 · 51,0 | 04-05 · 05-06 |
| 1920×1080 | 132/0/132/63 | 1398, 777 | 20,8 · 22,6 | 51,0 · 51,0 | — · 04-05 |
| 800×370 | 132/0/132/63 | 621,2, 266,2 | 17,7 · 18,3 | 28,0 · 28,0 | 04-05 · 05-06 (04-06 en E z −3,4) |

Hallazgo: con safe area inferior (63 px de diseño) el caso 09 vuelve, porque los botones suben con la
safe area y el encuadre no. D27 aceptó ≤ 8 px medidos solo con safe area nula. Consultado al
coordinador antes de redactar: el responsable eligió la opción A (zona anclada a la safe area y este
residuo como limitación conocida en la ADR, D27.3; la cámara no descuenta la safe area inferior).
