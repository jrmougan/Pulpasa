---
id: PUL-152
title: Recapturar medidas y capturas de D26 con el estado final de M3e
status: review
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
- [x] AC1 Given el código actual, When se ejecuta `docs/evidence/PUL-152/run_all.sh`, Then hay las 14
  escenas de PUL-132 a 1280×720 y 1920×1080 escritorio, 2340×1080 táctil con safe area 132 / 0 / 132 / 63
  y 800×370 táctil, más los JSON de medidas de esas 4 y de 1920×1080 táctil. → `docs/evidence/PUL-152/`.
- [x] AC2 Given los JSON, Then el README tiene la tabla de medidas de PUL-132 rehecha con OK/KO por AC de
  `controles-tactiles.md` y `lenguaje-acciones.md`, con los valores de D27: a 2340×1080 con safe nula
  acción en (2202 ± 2, 942 ± 2) y cambiar en (2028 ± 2, 972 ± 2); con la safe de diseño acción en
  (2070 ± 2, 879 ± 2) y cambiar en (1896 ± 2, 909 ± 2); 24 ± 2 px de hueco horizontal, bordes inferiores
  alineados ± 2 px.
- [x] AC3 Given los hallazgos H-01..H-03 de PUL-132, Then siguen corregidos: anillo de olla dentro de
  pantalla y bajo la banda superior (y ≥ 200 px a 1080) con el activo en la fila trasera; aro inactivo ≤ 3
  px a 1080 en móvil; game over sin «cajas/minuto». → filas en la tabla y capturas 07, 09, 10 y 13.
- [x] AC4 (caso 09, medida en juego real) Given una caja con contador en cada pasaplatos 01-06 y el activo
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
- [x] AC5 `tools/verify.sh` completo en verde y `tools/check_owns.py` limpio.

## Plan
1. Copiar `capture_boot.gd`, `capture_d26.gd` y `run_all.sh` de PUL-132 y `capture_pul138.gd` de PUL-138
   (como `capture_caso09.gd`, con su `capture_caso09_boot.gd`) a `docs/evidence/PUL-152/`; los
   originales no se tocan.
2. Adaptar `capture_d26.gd` al estado de M3e sin cambiar las 14 escenas: la safe area simulada llega
   también a `CameraRig` (`set_safe_margins`, como la leería de `DisplayServer`); botones en fila (hueco
   horizontal y bordes inferiores, D27.1) y zona de botones de la cámara; anillo de la olla con su borde
   superior real, dentro de pantalla y a ≥ 200 px a 1080 (H-01); textos del game over (H-03).
3. Ampliar el caso 09 a 2 safe areas × 2 ollas × 2 posiciones por resolución con el activo en reposo con
   física real; solape con la zona de `CameraRig._button_zone` y, aparte, con las cajas de los discos.
4. `run_all.sh`: 1280×720 y 1920×1080 escritorio, 2340×1080 táctil con safe, 1920×1080 táctil (solo
   JSON), 800×370 táctil y el caso 09 a 2340×1080, 1920×1080 (solo JSON) y 800×370.
5. README con la tabla de medidas OK/KO, H-01..H-03, el caso 09 frente a las dos referencias y los
   hallazgos nuevos. `tools/verify.sh --quick` (solo docs y scripts de evidencia, fuera de `godot/`) y
   `tools/check_owns.py`.

## Evidence
Detalle, tabla de medidas, caso 09 y hallazgos: `docs/evidence/PUL-152/README.md`. Código de `main` en `039c737`.

| AC | Resultado | Evidencia |
|---|---|---|
| AC1 | **PASA** | `bash docs/evidence/PUL-152/run_all.sh` (~4 min): 14 escenas a 2340×1080 táctil con safe 132/0/132/63 y 800×370 táctil, 13 a 1280×720 y 1920×1080 PC (la 02 es solo táctil) y JSON de esas 4 y de 1920×1080 táctil. |
| AC2 | **PASA** | Tabla rehecha, todo OK en táctil a 1080. Acción (2202, 942) / cambiar (2028, 972) con safe nula; (2070, 879) / (1896, 909) con la de diseño; hueco 24; bordes inferiores alineados (0 px). |
| AC3 | **PASA** | H-01: anillo dentro de pantalla, borde superior a 267,2 px a 1080 con el activo en la fila trasera. H-02: aro inactivo 2,5 px. H-03: game over sin «cajas/minuto». Capturas 07, 09, 10, 13. |
| AC4 | **PASA** | 24 vistas en `<res>-caso09-medidas.json`. Safe nula: 0 px en todas (también a 800×370). Safe de diseño: 6,6 / 35,0 px a 1080 y 2,2 / 12,0 a 800×370, = test de PUL-138 (≤ 0,1 px); ~16 px menos que la estimación de D27.3, por H-05. 16 JPG a 2340×1080 y 800×370. |
| AC5 | **PASA** | `tools/verify.sh` completo en verde y `tools/check_owns.py` limpio (informe de entrega). |

Hallazgos nuevos (no corregidos, fuera de owns):
- **H-05 (media)**: en un escritorio Linux con panel, `DisplayServer.get_display_safe_area()` devuelve el área de
  trabajo (top 32 px) y `UiScale.safe_margins` la aplica a la ventana: la UI y `CameraRig` meten 32 px arriba. Las
  cifras del caso 09 de PUL-136/137 (ADR-005 D27.3: 20,8-51,0 px) y el residuo de 6,4 px a 800×370 de D27/PUL-138
  llevan ese margen; con safe nula real son 0 y 2,2-35,0 px (`<res>-host-caso09-medidas.json` los reproduce al
  décimo). **Pregunta para el responsable:** ¿solo corregir las cifras de D27.3/D27 (documental) o, además, ignorar
  la safe area del sistema en el perfil de escritorio (ficha de código)?
- **H-06 (baja)**: con V-Sync y la ventana sin foco (Wayland) el juego va a 1 FPS; `run_all.sh` usa `--disable-vsync`.
- Observación: el solape de 35 px con la safe de diseño es del rectángulo del contador (AABB del numeral); la barra
  visible acaba hacia y ≈ 740, sobre la zona (777) y el disco de acción (789).
