---
id: PUL-171
title: Pantalla de opciones desde el menú principal y la pausa
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-167, PUL-168]
orca_task: null
unity_sources: []
owns: [godot/ui/menus/options_menu.gd*, godot/ui/menus/main_menu.gd*, godot/ui/menus/pause_menu.gd*, godot/data/i18n/options.*, godot/tests/integration/test_options_menu.gd*, docs/evidence/PUL-171/**, docs/backlog/PUL-171-pantalla-de-opciones.md]
touches_scenes: [godot/ui/menus/options_menu.tscn, godot/ui/menus/main_menu.tscn, godot/ui/menus/pause_menu.tscn]
---

## Target
`features/opciones-de-volumen.md` reescrita en PUL-160; núcleo de ajustes de PUL-167; claves de PUL-168.

## Change
Escena de opciones con los ajustes aprobados (como mínimo, 3 sliders de volumen y selector de idioma),
abierta desde el menú principal y desde la pausa, navegable con teclado, mando y táctil.

## Constraints
- Lee y escribe ajustes solo a través del núcleo de PUL-167; ninguna ruta absoluta de nodos.
- Textos con claves en `data/i18n/options.*` (fichero creado vacío por PUL-168); el gallego lo completa PUL-173.
- Perfil móvil: filas ≥ 120 px de alto y texto ≥ 36 px a 1080 (`controles-tactiles.md`).

## Acceptance
- [ ] AC1 Given el menú principal o la pausa, When se elige «Opciones», Then se abre y «Volver» devuelve al
  mismo menú con el foco en «Opciones» → `test_options_menu.gd`.
- [ ] AC2 Given un slider, When se mueve con mando (pasos del 10 %), Then el bus cambia en el mismo frame y el
  valor persiste al reabrir → `test_options_menu.gd`.
- [ ] AC3 Given el selector de idioma, When se cambia, Then la propia pantalla se actualiza en ≤ 0,5 s → `test_options_menu.gd`.
- [ ] AC4 Capturas a 1920×1080 (escritorio) y 2340×1080 (táctil) en `docs/evidence/PUL-171/`; recorrido
  completo sin teclado (solo mando).
- [ ] AC5 `tools/verify.sh` en verde; `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
