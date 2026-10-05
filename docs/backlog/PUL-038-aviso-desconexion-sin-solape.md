---
id: PUL-038
title: Evitar que el aviso de mando desconectado tape los tickets
status: ready
milestone: M2
role: ui-engineer
deps: [PUL-037]
orca_task: null
unity_sources: []
owns: [godot/ui/menus/pause_menu.gd, godot/ui/menus/pause_menu.tscn, godot/tests/integration/test_pause_menu.gd, docs/evidence/PUL-038/**]
touches_scenes: [godot/ui/menus/pause_menu.tscn]
---

## Target
Hallazgo del QA de PUL-037 (captura `docs/evidence/PUL-037/coop-pausa-desconexion-j2.png`): en la
pausa, el título del aviso «Mando de J<n> desconectado» queda encima de la fila de tickets.

## Change
Recolocar el aviso dentro del panel de pausa (o reservarle espacio) para que no se solape con
`OrderTicketsPanel` a 1280×720 y 1920×1080. Se agrupa con los ajustes que salgan del playtest de M2.

## Constraints
- Sin tipos 3D en `ui/`; no tocar firmas de `EventBus` ni otros menús.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py` limpio.

## Acceptance
- [ ] AC1 Con el aviso visible, su rectángulo no intersecta el de la fila de tickets → test en `test_pause_menu.gd`
- [ ] AC2 Captura a 1280×720 con el aviso en `docs/evidence/PUL-038/`
- [ ] AC3 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
