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
- [ ] AC1 Given las features de M4 (`opciones-de-volumen.md`, `creditos-y-version.md`, `textos-gallego.md`, `tutorial-breve.md` y el
  balance de PUL-165), When se recorre cada AC en el editor con MCP, Then el 100 % tiene estado (cumple / no cumple / no verificable) y prueba
  (test GUT o captura) → tabla en `docs/evidence/PUL-177/README.md`.
- [ ] AC2 Given el idioma gallego y solo un mando, When se recorre menú → opciones → partida de 300 s → resultados → créditos, Then se
  completa sin teclado, con 0 textos cortados y 0 errores en consola → ≥ 6 capturas a 1920×1080 + log en la evidencia.
- [ ] AC3 Given los datos de PUL-166, When se repite la medida de PUL-164 (mismas 3 semillas por modo), Then hay tabla antes/después de
  holgura por receta y recaudación, y toda holgura < margen aprobado en G2 se marca como defecto → tabla + JSON en la evidencia.
- [ ] AC4 Given los defectos encontrados, When se listan, Then cada uno tiene pasos para reproducir, gravedad y propuesta de ficha; si hay
  alguno bloqueante, la evidencia lo dice y PUL-176 no puede empezar → lista en la evidencia.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-177/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
