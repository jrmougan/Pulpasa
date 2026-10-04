---
id: PUL-037
title: Integrar dos personajes en level_01 y pasar el QA de M2
status: draft
milestone: M2
role: qa-tester
deps: [PUL-034, PUL-035, PUL-036]
orca_task: null
unity_sources: []
owns: [godot/scenes/levels/**, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_m2_flow.gd, godot/tests/integration/test_m2_flow.gd.uid, docs/evidence/PUL-037/**, docs/design/m2-gate.md]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
M2: cierre técnico del hito antes de la puerta humana de game feel. Features
`jugadores-y-cambio` (AC7, AC8), `menu-principal` (AC1–AC2) y `mando-y-reasignacion` (AC3, AC5).

## Change
1. `level_01.tscn`: `Player2` en `Characters` (`player_index = 2`, posición de salida sin solapar
   a J1 ni muebles) y `CharacterSwitcher` con `characters = [Player1/%Control, Player2/%Control]`,
   según `scene-tree.md` §2.
2. `test_m2_flow.gd`: SINGLE (cambio y entrega con cada personaje), COOP_2P (cada jugador mueve el
   suyo; recaudación compartida), y flujo menú → partida → game over → reintentar solo con eventos
   de mando simulados.
3. QA con el MCP: capturas de SINGLE con indicador, COOP_2P con los dos personajes y pausa por
   desconexión.
4. `docs/design/m2-gate.md`: guía breve para el playtest humano de game feel (qué probar con
   teclado + mando y con dos mandos, y qué anotar).

## Constraints
- Solo integración: si algo de PUL-034..036 falla, se reporta al coordinador, no se arregla fuera de `owns`.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 SINGLE: un jugador, dos personajes, el cambio funciona en el nivel real → `test_m2_flow.gd`
- [ ] AC2 COOP_2P: entrega de J2 suma a la misma recaudación que J1 → `test_m2_flow.gd`
- [ ] AC3 Con dos mandos simulados, cada uno mueve solo a su personaje → `test_m2_flow.gd`
- [ ] AC4 Menú → partida → game over → reintentar sin eventos de teclado → `test_m2_flow.gd`
- [ ] AC5 Capturas en `docs/evidence/PUL-037/` y guía `docs/design/m2-gate.md`
- [ ] AC6 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
