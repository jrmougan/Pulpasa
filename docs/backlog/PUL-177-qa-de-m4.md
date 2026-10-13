---
id: PUL-177
title: QA de M4 (opciones, gallego, tutorial y balance) y preparar el playtest
status: draft
milestone: M4
role: qa-tester
deps: [PUL-166, PUL-172, PUL-173, PUL-175]
orca_task: null
unity_sources: []
owns: [docs/evidence/PUL-177/**, docs/backlog/PUL-177-qa-de-m4.md]
touches_scenes: []
---

## Target
Lo hecho en M4 (PUL-166..175) en el editor y vía MCP: opciones, créditos, gallego, tutorial y balance,
en escritorio, mando y perfil táctil forzado (`--touch`). Regresión de D26/D27.

## Change
Recorrer cada AC de las features de M4 (`opciones-de-volumen.md`, `creditos-y-version.md`,
`textos-gallego.md`, `tutorial-breve.md`, balance de PUL-165) con captura o test, re-medir el balance con
el bot de PUL-164 sobre los datos nuevos y dejar listo el material para el playtest de la alpha (PUL-178).

## Constraints
- Solo evidencia y fichas de defecto propuestas (como lista en el README; el producer las crea).

## Acceptance
- [ ] AC1 Tabla feature × AC con estado (cumple / no cumple / no verificable) y su prueba.
- [ ] AC2 Recorrido menú → opciones → partida → resultados en gallego, solo con mando, con capturas 1920×1080.
- [ ] AC3 Re-medida de balance con los datos de PUL-166 frente a la tabla de PUL-164 (antes/después).
- [ ] AC4 `tools/verify.sh` completo en verde y 0 errores en consola en una partida de 300 s; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
