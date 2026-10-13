---
id: PUL-173
title: Completar la traducción al gallego y el cambio de idioma en caliente
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-161, PUL-171, PUL-172, PUL-174]
orca_task: null
unity_sources: []
owns: [godot/data/i18n/**, godot/tests/unit/test_translation_coverage.gd*, godot/tests/integration/test_locale_switch.gd*, godot/tests/integration/test_text_fit.gd*, docs/evidence/PUL-173/**, docs/backlog/PUL-173-traduccion-al-gallego.md]
touches_scenes: []
---

## Target
`features/textos-gallego.md` AC1–AC5 (puesta al día en PUL-161) con el glosario `docs/design/glosario-gl.md`.
Va después de todas las fichas que crean claves (PUL-168, 171, 172, 174).

## Change
Rellenar la columna gallega de todos los ficheros de `data/i18n/`, comprobar el cambio de idioma en caliente
en todas las pantallas y que ningún texto se corta.

## Constraints
- Términos según el glosario; lo que no esté se añade como propuesta en la evidencia para la revisión humana
  (pregunta P9 del plan).
- Si un texto no cabe, se arregla con el ajuste de fuente del tema o se escala; no se cambia la escena
  (sus dueños ya cerraron).

## Acceptance
- [ ] AC1 Given el gallego, Then 0 claves sin traducir en el informe → `test_translation_coverage.gd` + informe en evidencia.
- [ ] AC2 Given el cambio de idioma en opciones, Then menú, pausa, HUD, tickets, tutorial, créditos y
  resultados se actualizan en ≤ 0,5 s sin reiniciar → `test_locale_switch.gd`.
- [ ] AC3 Given 1920×1080, 1280×720 y 2340×1080 (táctil, texto ≥ 36 px), Then ningún texto se corta ni
  desborda en ningún idioma → `test_text_fit.gd` + capturas.
- [ ] AC4 Given el idioma por defecto, Then es el que fije PUL-161 (hoy castellano) → `test_locale_switch.gd`.
- [ ] AC5 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
