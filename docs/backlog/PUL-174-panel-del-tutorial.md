---
id: PUL-174
title: Panel del tutorial con icono del verbo y «Saltar»
status: draft
milestone: M4
role: ui-engineer
deps: [PUL-168, PUL-169]
orca_task: null
unity_sources: []
owns: [godot/ui/tutorial/**, godot/data/i18n/tutorial.*, godot/tests/integration/test_tutorial_panel.gd*, docs/evidence/PUL-174/**, docs/backlog/PUL-174-panel-del-tutorial.md]
touches_scenes: [godot/ui/tutorial/tutorial_panel.tscn]
---

## Target
`features/tutorial-breve.md` AC2, AC3, AC7, AC8 y AC1' (PUL-162); núcleo de PUL-169; iconos de verbo de
`action_icons.tres` (PUL-123).

## Change
Escena del panel del tutorial: texto del paso, icono del verbo igual que el prompt del mundo, botón
«Saltar», versión táctil. Se prueba en un sandbox con el núcleo; el montaje en el nivel es PUL-175.

## Constraints
- Sin tipos 3D en `ui/`; el resaltado del objetivo en el mundo es de PUL-175.
- Textos con claves en `data/i18n/tutorial.*` (castellano; el gallego en PUL-173).

## Acceptance
- [ ] AC1 Given el núcleo en cada uno de los 6 pasos, When se refresca el panel, Then muestra su texto y el icono del verbo de `action_icons.tres` (paso 5
  sin verbo, paso 6 el botón de cambiar) → `test_tutorial_panel.gd`.
- [ ] AC2 Given un paso en curso, When el núcleo lo da por completado, Then el panel pasa al siguiente en ≤ 0,5 s → `test_tutorial_panel.gd`.
- [ ] AC3 Given el panel abierto, When se pulsa «Saltar» con teclado, mando o toque (3 casos), Then el núcleo queda «hecho» y el panel se cierra → `test_tutorial_panel.gd`.
- [ ] AC4 Given el perfil táctil a 2340×1080, When se muestra el panel, Then texto ≥ 36 px y «Saltar» ≥ 120 px de alto a 1080, fuera de la zona de
  botones de D27 → `test_tutorial_panel.gd` + capturas 1920×1080 y 2340×1080.
- [ ] AC5 Given la rama de la ficha, When se ejecutan `tools/verify.sh` y `python3 tools/check_owns.py <rama>`, Then ambos salen con código 0 y 0 rutas fuera de `owns` → salida pegada en `docs/evidence/PUL-174/README.md`.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
