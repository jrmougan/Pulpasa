---
id: PUL-152
title: Recapturar medidas y capturas de D26 con el estado final de M3e
status: draft
milestone: M3e
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-152/**, docs/backlog/PUL-152-recaptura-d26-para-el-gate.md]
touches_scenes: []
---

## Target
Las capturas y la tabla de medidas de `docs/evidence/PUL-132/` son anteriores a PUL-133 (cámara móvil
bajo la banda superior, aro inactivo fino, game over sin cajas/minuto), PUL-134 (flecha y zona de botones
tapadas) y PUL-138 (botones en fila, D27). PUL-133 y PUL-138 solo recapturaron sus casos (5 escenas
táctiles y el caso 09 con safe area nula). La guía del playtest (PUL-150) necesita un juego completo y
vigente. Scripts de partida: `docs/evidence/PUL-132/capture_boot.gd`, `capture_d26.gd`, `run_all.sh`, y
`docs/evidence/PUL-138/capture_pul138.gd` (caso 09).

## Change
Copiar los scripts a `docs/evidence/PUL-152/` (sin tocar los de PUL-132 ni PUL-138), ejecutarlos contra
el código actual y dejar capturas, JSON de medidas y un README con la tabla OK/KO por AC y los hallazgos.
Añadir el caso 09 con la safe area de diseño (132 / 0 / 132 / 63), que hoy solo está calculado (ADR-005
D27.3) y no capturado.

## Constraints
- Solo evidencia: no se toca código, escenas, datos, tests ni contratos. Un defecto nuevo se anota con
  gravedad y captura; no se arregla.
- Repositorio ligero: JPG, y a 1920×1080 táctil solo el JSON de medidas (como PUL-132), también en el
  caso 09 (AC4).
- Las 800×370 sirven para composición y solapes, no para tamaños (fuera del rango soportado, nota de
  PUL-132).

## Acceptance
- [ ] AC1 Given el código actual, When se ejecuta `docs/evidence/PUL-152/run_all.sh`, Then hay las 14
  escenas de PUL-132 a 1280×720 y 1920×1080 escritorio, 2340×1080 táctil con safe area 132 / 0 / 132 / 63
  y 800×370 táctil, más los JSON de medidas de esas 4 y de 1920×1080 táctil. → `docs/evidence/PUL-152/`.
- [ ] AC2 Given los JSON, Then el README tiene la tabla de medidas de PUL-132 rehecha con OK/KO por AC de
  `controles-tactiles.md` y `lenguaje-acciones.md`, con los valores de D27: a 2340×1080 con safe nula
  acción en (2202 ± 2, 942 ± 2) y cambiar en (2028 ± 2, 972 ± 2); con la safe de diseño acción en
  (2070 ± 2, 879 ± 2) y cambiar en (1896 ± 2, 909 ± 2); 24 ± 2 px de hueco horizontal, bordes inferiores
  alineados ± 2 px.
- [ ] AC3 Given los hallazgos H-01..H-03 de PUL-132, Then siguen corregidos: anillo de olla dentro de
  pantalla y bajo la banda superior (y ≥ 200 px a 1080) con el activo en la fila trasera; aro inactivo ≤ 3
  px a 1080 en móvil; game over sin «cajas/minuto». → filas en la tabla y capturas 07, 09, 10 y 13.
- [ ] AC4 (caso 09, medida en juego real) Given una caja con contador en cada pasaplatos 01-06 y el activo
  en reposo en cada olla (oeste y este) en su plaza (z −3,1) y en el extremo norte (z −3,4), con safe nula y
  con la de diseño (132 / 0 / 132 / 63), a 2340×1080, 1920×1080 y 800×370, Then el JSON
  `<res>-caso09-medidas.json` trae las **24 vistas** (3 resoluciones × 2 safe areas × 2 ollas × 2
  posiciones) con el solape máximo en px reales por pasaplatos; con safe nula, 0 px a 2340×1080 y
  1920×1080 y ≤ 8 px a 800×370 (residuo aceptado por D27). Con la safe de diseño **no hay umbral** (es la
  limitación aceptada D27.3): el README pone, para cada vista, el valor medido junto a las dos referencias
  previas, la estimación de ADR-005 D27.3 (20,8-22,6 / 51,0 px a 1080; 17,7-18,3 / 28,0 a 800×370) y el
  registro de `test_camera_button_zone.gd` en PUL-138 (6,6 / 35,1 px a 1080; 2,2 / 12,0 a 370, con el
  activo colocado sin física), y explica cada diferencia > 2 px con cualquiera de ellas (posición real del
  activo, recorte este de la cámara, redondeo de `SafeAreaMargin`, rectángulo del contador usado).
  Capturas: **16 JPG**, solo a 2340×1080 y 800×370 (1920×1080 táctil queda en JSON, como en Constraints),
  con el nombre `<res>-caso09-<nula|diseno>-<oeste|este>-<z3_1|z3_4>.jpg`.
- [ ] AC5 `tools/verify.sh` completo en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
