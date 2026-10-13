---
id: PUL-153
title: Probar el perfil táctil en un teléfono con el build web (antes del APK)
status: draft
milestone: M3e
role: qa-tester
deps: []
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-153/**, docs/backlog/PUL-153-perfil-tactil-en-telefono-via-web.md]
touches_scenes: []
---

**Pregunta para el responsable antes de pasar a `ready`:** ¿se hace la parte de teléfono del playtest de
M3e con el build web abierto en el navegador del teléfono, mientras PUL-151 (APK) sigue bloqueada? Es
la vía que ya prevé `docs/arch/export.md` (sección Móvil). Necesita que el responsable tenga el teléfono
en la misma red que el PC y haga él las pruebas en el teléfono; el agente exporta, sirve y anota.

## Target
`docs/arch/export.md` («el perfil `MOBILE` se prueba [...] en el build web abierto desde un teléfono
(Compatibility, ya vigente)»). `PlatformProfile.detect` da `MOBILE` con la feature `web_android` o
`web_ios` (ADR-005 E1). Preset Web existente (Compatibility, sin hilos) y `tools/export.sh web`.
Diseño: `features/controles-tactiles.md`.

## Change
1. Exportar con `tools/export.sh web` y servir `build/web` en la red local (`python3 -m http.server`).
2. El responsable abre la URL en Chrome para Android (y en Safari si tiene iPhone) y juega una ronda; el
   agente anota resultados, capturas del teléfono y medidas.
3. Tabla de lo que el web **no** puede comprobar y queda para PUL-151.

## Constraints
- Solo red local: nada se publica en Internet (itch.io o similar es publicar: gate aparte).
- Sin cambios en presets, `project.godot`, código ni tests. Si el web necesita un ajuste (p. ej.
  pantalla completa u orientación forzada), se anota como hallazgo para PUL-151 o una ficha nueva.
- No sustituye a PUL-151: el renderizador del web es Compatibility, no el que se elija para Android.

## Acceptance
- [ ] AC1 When `tools/export.sh web`, Then sale con 0 y sin `ERROR`; el tamaño de `build/web` y del
  `.pck` se anota (comparado con los 39 MB de `export.md`). → salida en `docs/evidence/PUL-153/`.
- [ ] AC2 Given la URL abierta en el teléfono en apaisado, Then el menú solo muestra «Individual»
  (perfil `MOBILE` sin `--touch`) y una ronda de 300 s se juega solo con toques (stick, acción con
  mantener para cortar, cambiar y pausa), con ≥ 1 comanda entregada. → ≥ 4 capturas del teléfono (menú,
  vista general, prompt BLOQUEADO en el botón de acción, game over).
- [ ] AC3 Given la fase 3 (4 tickets) en el teléfono, Then se anota el FPS medio de 60 s (Performance de
  `chrome://inspect` o el contador del navegador) y si baja de 30 FPS se registra como hallazgo para la
  elección de renderizador de PUL-151.
- [ ] AC4 Given lo que el navegador no expone, Then `docs/evidence/PUL-153/README.md` tiene una tabla de
  **5 filas exactas**, una por criterio de teléfono de PUL-151: (1) safe area real y D27.3, (2) botón Atrás,
  (3) pantalla encendida 5 min, (4) háptica 20 / 20 + 20 ms, (5) muesca superior. Cada fila trae estado
  (`sí` / `no` / `a medias`), la prueba hecha en el teléfono (paso y resultado observado, o valor leído,
  p. ej. `DisplayServer.get_display_safe_area()` en el log del navegador) y, si no es `sí`, el AC de
  PUL-151 que lo conserva. 5 de 5 filas con prueba.
- [ ] AC5 (respuestas del responsable, plantilla propia) Given la ronda de AC2, Then
  `docs/evidence/PUL-153/respuestas-telefono.md` tiene las **8 preguntas** siguientes respondidas con
  `ok` / `cambiar` / `dudas` y una línea si no es `ok` (8 de 8): (1) stick y acción a la vez, (2) el dedo
  del stick que pasa sobre el botón de acción no lo pulsa, (3) la cámara sigue al activo sin marear,
  (4) la flecha de borde encuentra al inactivo, (5) se leen tickets y HUD (texto de 36 px a 1080),
  (6) el botón de acción no tapa demasiado mundo, (7) veces que se soltó algo al suelo sin querer (número),
  (8) ¿hace falta el layout de zurdos? Si PUL-150 ya está mergeada, las preguntas de la parte de teléfono
  de `m3e-gate.md` que no estén en esta lista se añaden al mismo fichero; no es requisito.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
