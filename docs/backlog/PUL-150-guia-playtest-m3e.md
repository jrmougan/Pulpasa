---
id: PUL-150
title: Escribir la guía del playtest humano de M3e (m3e-gate.md)
status: review
milestone: M3e
role: game-designer
deps: [PUL-152]
orca_task: null
unity_sources: []
owns: [docs/design/m3e-gate.md, docs/evidence/PUL-150/**, docs/backlog/PUL-150-guia-playtest-m3e.md]
touches_scenes: []
---

## Target
Puerta humana de M3e (`roadmap.md`): «Playtest humano del lenguaje de acciones en PC y, cuando haya
export, en teléfono». No existe `docs/design/m3e-gate.md`; modelos: `m3c-gate.md` y `m3d-gate.md`.
Diseño vigente: D26 y D27 (`decisions.md`), `features/lenguaje-acciones.md`,
`features/controles-tactiles.md`. Medidas: `docs/evidence/PUL-132/README.md` (QA de D26, guía breve
para el responsable) y la recaptura de PUL-152 (cámara de PUL-133/134, botones en fila de PUL-138).

## Change
`docs/design/m3e-gate.md` con la estructura de `m3d-gate.md`, para que el responsable juegue y decida:
1. **Lo que ya sabías antes de jugar**: tabla de lo medido (PUL-132 + PUL-152) con valor y estado, y lo
   que se sabe de antemano (limitación D27.3, residuo de ≤ 8 px a 800×370, export pendiente).
2. **Antes de empezar**: capturas que abrir, cómo arrancar en PC (escritorio y `godot -- --touch`) y
   cómo manejar el perfil táctil en PC (ver Preguntas).
3. **Qué mirar y qué responder** en PC, por bloques: verbos y prompt (D26.1-2), ninguna pulsación muda
   (D26.3), objetivo estable (D26.4), simplificaciones (D26.5: cuenco que solo pone, entrega solo por
   zona, mantener para cortar), estado legible (D26.6), iconografía (D26.7), Local 2P con dos prompts y
   perfil táctil en PC (D26.8, D27).
4. **Parte de teléfono**, condicionada a PUL-151 (APK) o PUL-153 (build web en el teléfono): stick y
   acción a la vez, cámara que sigue, flecha de borde, ciclo de vida, legibilidad de 36 px, háptica y la
   comprobación de D27.3 (safe area inferior del teléfono y contador de los pasaplatos 04-06).
5. **Qué medir y cómo anotar**: plantilla de resultados (ok / cambiar / dudas + una línea), recaudación,
   estrellas, nº de pulsaciones que no entendió, nº de veces que soltó al suelo sin querer, tiempo de la
   sesión; sección vacía «Resultado del gate» como en `m3c-gate.md`.
6. **Qué decidir**: las preguntas abiertas de D26 con sus opciones (abajo, AC3).

## Constraints
- Solo documentación de diseño: no se toca código, escenas, datos ni contratos.
- No edites `roadmap.md`, `decisions.md` ni las features: si la guía destapa una incoherencia, va a
  Preguntas abiertas de esta ficha.
- No repetir lo que decide M4 (balance: umbrales de estrellas, R15/R17, fases; lo planifica PUL-141): la
  guía puede pedir anotar recaudación y estrellas, no decidirlas.
- Cada fila de «Qué mirar» enlaza una captura que exista en `docs/evidence/`.

## Acceptance
- [x] AC1 Given `docs/design/m3e-gate.md`, Then tiene las 6 secciones de Change en ese orden y la tabla
  «Lo que ya sabías» trae ≥ 10 medidas con valor numérico y estado (OK/KO/limitación) tomadas de PUL-132 y
  PUL-152. → listado de encabezados (`grep -n '^#'`) en `docs/evidence/PUL-150/README.md`.
- [x] AC2 Given los 8 puntos de D26 y D27 (botones en fila, zona de botones, D27.3), Then cada uno aparece
  en ≥ 1 fila de «Qué mirar»: tabla de trazabilidad punto → fila en `docs/evidence/PUL-150/README.md`
  (11 de 11).
- [x] AC3 Given «Qué decidir», Then incluye con opciones concretas: las 6 preguntas abiertas de
  `controles-tactiles.md` (zurdos, tamaño ajustable, háptica 20 / 20 + 20 ms, texto de 36 px, entrega por
  zona en móvil, notch superior), las preguntas 1 (soltar al suelo por accidente: mantener 0,3 s o no) y
  2 (dispensador desde el lado de pase: 7.º motivo o no) de `lenguaje-acciones.md`, y la limitación D27.3
  (mantener o pedir que la cámara descuente la safe area inferior). → tabla en la evidencia (9 de 9).
- [x] AC4 Given la guía, Then la parte de PC se estima en ≤ 30 min y la de teléfono en ≤ 15 min (suma
  por bloque en la evidencia), y todas las rutas de captura que cita existen (salida de un `ls` de cada
  ruta en la evidencia, 0 ausentes).
- [x] AC5 `tools/verify.sh --quick` en verde y `tools/check_owns.py` limpio.

## Preguntas abiertas
1. **Perfil táctil en PC sin pantalla táctil.** `emulate_touch_from_mouse` está desactivado en
   `project.godot` (lo exige la verificación de `controles-tactiles.md`), así que con ratón no se manejan
   el stick ni los botones. ¿El responsable tiene portátil o monitor táctil? Si no, ¿se juega la parte
   táctil solo en teléfono (PUL-151/153), o se pide una bandera de desarrollo que active la emulación con
   ratón (un solo contacto: sin multitáctil)? Lo segundo toca `project.godot` o código: otra ficha.
2. ¿Una sola sesión (PC y teléfono) o dos (PC ahora; teléfono cuando haya PUL-151 o PUL-153)? La ficha
   asume dos, con la parte de teléfono marcada como condicionada.

## Plan
1. Leer `m3c-gate.md` y `m3d-gate.md` (estructura), D26/D27, `lenguaje-acciones.md`,
   `controles-tactiles.md`, la Evidence de PUL-132 (ficha) y `docs/evidence/PUL-152/README.md` (cifras
   vigentes y H-05), y `docs/evidence/PUL-140/README.md` (preguntas para el responsable).
2. Escribir `docs/design/m3e-gate.md` con las 6 secciones de Change; bloques de PC A-G por punto de
   D26/D27 con tiempo estimado; parte de teléfono T1-T6 condicionada a PUL-151/153; cada fila con una
   captura existente (preferencia: PUL-152; si no hay escena equivalente, PUL-123/126/127/128/131/134/122).
3. «Qué decidir»: P1-P9 de AC3 + P10-P13 del brief (H-05 y PUL-140).
4. Evidencia: encabezados, trazabilidad 11/11, tabla 9/9, sumas de tiempo y `ls` de las rutas.
5. `tools/verify.sh --quick` y `tools/check_owns.py`.

## Evidence
`docs/evidence/PUL-150/README.md`.
- AC1 PASA: 6 secciones en orden; «Lo que ya sabías» con 17 medidas (16 OK, 1 limitación D27.3).
- AC2 PASA: trazabilidad 11 de 11 (D26.1-8, D27.1-3).
- AC3 PASA: P1-P9 con opciones (9 de 9); además P10-P13 (H-05 de PUL-152: corregir ADR-005 D27.3 y
  safe area del sistema en escritorio; PUL-140: web en el teléfono y perfil táctil sin pantalla táctil).
- AC4 PASA: PC 29 min, teléfono 15 min; 26 capturas citadas, 0 ausentes.
- AC5 PASA: `tools/verify.sh --quick` en verde; `tools/check_owns.py jrmougan/pul-150 main` limpio.

Notas para el coordinador: la guía asume dos sesiones (pregunta 2) y deja la pregunta 1 como P13 para el
responsable. No hay bandera de juego para simular la safe area de diseño en PC (solo en los scripts de
captura): D27.3 en PC se juzga por captura (fila G5) y de verdad en el teléfono (T6).
