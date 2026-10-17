---
id: PUL-189
title: Pasar el QA visual y de rendimiento antes y después de la estética v3
status: draft
milestone: M3f
role: qa-tester
deps: [PUL-188]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-189/**, docs/backlog/PUL-189-qa-visual-y-rendimiento-v3.md]
touches_scenes: []
---

## Target
Ejecutar la validación final de QA visual y de rendimiento de la estética v3 «Feira Clara» (siguiendo el protocolo de `.claude/agents/qa-tester.md` y `docs/art/art-bible.md` §4.3, §6 y §9): comparativa antes/después con el **mismo script de captura y la misma cámara** a `1920×1080` y a `800×370` (móvil), verificación de contrastes ≥ 3:1 y deriva `0.0 px`, y medida de rendimiento/memoria antes y después con el mismo método.

## Change
1. **Capturas antes y después con el mismo script y la misma cámara (`docs/evidence/PUL-189/`)**:
   - Usar la pose y proyección ortográfica exacta de `level_01.tscn` (`CameraRig`, `size = 12.74`, pose `(0.7, 7.49, 5.86)`, pitch `-52.03°`) y el mismo estado de partida (ronda en curso con 4 comandas en los puestos 1..4, J1 con caja condimentada en mano, J2 en cocina, pulpo cociendo en `Kitchen` con vapor activo y comida en encimera, igual que en `docs/evidence/PUL-180/capture_minimal.gd`).
   - Generar en `docs/evidence/PUL-189/despues/` las 3 capturas de `level_01.tscn` tal como queda en el repositorio (sin overrides en caliente en el script):
     - `1920x1080_con_hud.png`
     - `1920x1080_sin_hud.png`
     - `800x370_movil.png`
   - Compararlas en `docs/evidence/PUL-189/` frente a las capturas `antes` de la v2 (`docs/evidence/PUL-180/partida/1920x1080_con_hud.png`, `1920x1080_sin_hud.png` y `800x370_movil.png`, tomadas con el mismo script y la misma cámara) y generar las láminas lado a lado `comparativa_1080p.png` y `comparativa_movil_800x370.png`.
2. **Verificación cuantitativa de deriva, luminancia, los 4 puntos de PUL-180 y contrastes §3.4**:
   - Comprobar en el script de captura que la proyección en pantalla (`camera.unproject_position`) de todas las estaciones, puestos, jugadores e ítems tiene **deriva `0.00 px`** entre `antes` (v2) y `después` (v3).
   - Medir la luminancia media del fotograma (`0.08 <= luma <= 0.95`, objetivo `0.30–0.45`) y verificar los 4 puntos corregidos de PUL-180 (sin cartel superior vacío sobre el toldo, números `#1..#4` y `1..4` macizos y legibles a `800×370`, `env_plate` limpia y SSAO suave sin `glow`/LUT/`Vignette`).
3. **Medida de rendimiento y memoria antes y después con el mismo método**:
   - Fijar el script de benchmark en `docs/evidence/PUL-189/measure_perf.gd`.
   - Ejecutar la medición de la línea base 'antes' (v2) sobre `main` (commit base `e86baf3`, previo al inicio de la oleada 1 / PUL-182) ejecutando el script en headless y guardando los resultados en `docs/evidence/PUL-189/antes/perf_v2.json`.
   - Tras la integración de PUL-188, ejecutar exactamente el mismo script sobre `level_01.tscn` (v3) guardando `docs/evidence/PUL-189/despues/perf_v3.json`.
   - Comparar ambas medidas en `docs/evidence/PUL-189/README.md` (`Performance.TIME_FPS`, `Performance.TIME_PROCESS`, `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `Performance.RENDER_TOTAL_OBJECTS_IN_FRAME`, `Performance.RENDER_VIDEO_MEM_USED`, `Performance.OBJECT_RESOURCE_COUNT`, materiales 3D únicos y texturas 3D cargadas, durante ≥ 120 frames tras el calentamiento).

## Constraints
- Solo evidencia y pruebas en `docs/evidence/PUL-189/**` y esta ficha: el script de captura de QA **no debe aplicar ningún override de material ni de luz en tiempo de ejecución**; debe capturar `level_01.tscn` tal como sale de `PUL-182..PUL-188`.
- Si algún criterio visual o de rendimiento falla, documentarlo y escalar antes de cerrar.

## Acceptance
- [ ] AC1 Given `level_01.tscn` sin overrides en tiempo de ejecución, When se ejecuta el script de captura en `docs/evidence/PUL-189/`, Then genera `1920x1080_con_hud.png`, `1920x1080_sin_hud.png` y `800x370_movil.png` con la misma cámara y escena que `antes`, y la deriva máxima de posición en pantalla de estaciones y `Marker3D` es **`0.00 px`**.
- [ ] AC2 Given las capturas `1920x1080_con_hud.png` y `800x370_movil.png`, When se verifican la luminancia media y los 4 puntos de PUL-180, Then la luma media está entre `0.25` y `0.50`, el cartel superior vacío (`env_sign`/`env_board`) no aparece, los números `#1..#4` y `1..4` son macizos (`11.24 : 1`) y legibles a `800×370`, `tent_plate` muestra PulpaSA y no hay viñeta ni brillos de `Bulbs`.
- [ ] AC3 Given los materiales activos de los 5 colores de §3.4 y sus soportes en `level_01.tscn`, When el script de QA mide sus contrastes WCAG 2.1 reales desde la escena instanciada, Then todos son **≥ 3.00 : 1** (mínimo ≥ `3.24 : 1`).
- [ ] AC4 Given la medición de rendimiento y memoria con `docs/evidence/PUL-189/measure_perf.gd` antes (en `main` previo a la oleada 1) y después (en `level_01.tscn` tras PUL-188), When se comparan en `docs/evidence/PUL-189/README.md`, Then el framerate medio a `1920×1080` es **≥ 60 fps**, los materiales 3D activos en escena bajan de `239` a **≤ 20** y la VRAM de texturas (`RENDER_VIDEO_MEM_USED`) se reduce respecto a la v2.
- [ ] AC5 `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

## Plan
(Lo escribe el worker antes de empezar.)

## Evidence
(Lo rellena el worker.)
