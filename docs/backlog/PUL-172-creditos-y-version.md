---
id: PUL-172
title: Pantalla de créditos con licencias y versión visible
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-160, PUL-171]
orca_task: null
unity_sources: []
owns: [godot/ui/menus/credits_menu.gd*, godot/ui/menus/main_menu.gd*, godot/ui/menus/game_over.gd*, godot/data/credits/**, godot/data/i18n/credits.*, godot/tests/integration/test_credits.gd*, docs/evidence/PUL-172/**, docs/backlog/PUL-172-creditos-y-version.md]
touches_scenes: [godot/ui/menus/credits_menu.tscn, godot/ui/menus/main_menu.tscn, godot/ui/menus/game_over.tscn]
---

## Target
`features/creditos-y-version.md` (PUL-160). Atribuciones de `docs/assets/licenses.md` (assets CC BY y
OFL exigen atribución en la obra distribuida). Versión de `config/version` en `project.godot`.

## Change
Escena de créditos abierta desde el menú principal, con los datos en `.tres` (o el formato de PUL-160)
generados o cruzados con `licenses.md`; versión visible en el menú principal y en los resultados.

## Constraints
- Va en la oleada siguiente a PUL-171 porque comparte `main_menu.tscn`.
- Datos de créditos fuera del código (regla 3). Textos traducibles en `data/i18n/credits.*`.

## Acceptance
- [ ] AC1 Given `licenses.md`, Then cada asset con licencia de atribución tiene entrada (autor, licencia,
  enlace) en los créditos: 0 faltantes → `test_credits.gd` (lee y cruza ambos).
- [ ] AC2 Given el menú principal, When se elige «Créditos», Then se abren, se desplazan con mando y táctil y
  «Volver» devuelve el foco → `test_credits.gd`.
- [ ] AC3 Given el menú y los resultados, Then muestran `config/version` → `test_credits.gd` + capturas 1920×1080 y 2340×1080.
- [ ] AC4 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
