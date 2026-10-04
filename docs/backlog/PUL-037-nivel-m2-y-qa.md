---
id: PUL-037
title: Integrar dos personajes en level_01 y pasar el QA de M2
status: done
milestone: M2
role: qa-tester
deps: [PUL-034, PUL-035, PUL-036]
orca_task: task_245617a5688c
unity_sources: []
owns: [godot/scenes/levels/**, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_parity_smoke.gd, godot/tests/integration/test_m2_flow.gd, godot/tests/integration/test_m2_flow.gd.uid, docs/evidence/PUL-037/**, docs/design/m2-gate.md]
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
- Notas de PUL-034..036: `character_switcher.tscn` va en el nivel con `characters` = los `%Control` de
  Player1 y Player2 (player_index 1 y 2). Con el MCP, `simulate_input` de tipo `action` no dispara
  `p1_switch`: simula la tecla Q. Los tests que llamen a `start_level`/`restart_level` restauran el
  InputMap con `GameState.reset_input()` en `after_each`. La retirada de un mando en ronda emite
  `device_assigned(p, NONE)` y luego `device_disconnected(p)` (aclaración de ADR-004).
- Solo integración: si algo de PUL-034..036 falla, se reporta al coordinador, no se arregla fuera de `owns`.
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 SINGLE: un jugador, dos personajes, el cambio funciona en el nivel real → `test_m2_flow.gd`
- [x] AC2 COOP_2P: entrega de J2 suma a la misma recaudación que J1 → `test_m2_flow.gd`
- [x] AC3 Con dos mandos simulados, cada uno mueve solo a su personaje → `test_m2_flow.gd`
- [x] AC4 Menú → partida → game over → reintentar sin eventos de teclado → `test_m2_flow.gd`
- [x] AC5 Capturas en `docs/evidence/PUL-037/` y guía `docs/design/m2-gate.md`
- [x] AC6 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
1. `level_01.tscn`: `Player2` (instancia de `player.tscn`, salida en (−1,6; 0; 0), a 5,2 m de J1 y
   lejos de mesas y estaciones) con override de su `Control` (`player_index = 2`,
   `controlled_by = 0` inicial; `[editable path]` como en `spice_shelf.tscn`) y
   `CharacterSwitcher` con `characters = [Player1/Control, Player2/Control]`.
2. `test_m2_flow.gd` sobre el nivel real y los autoloads reales: input por `push_input` /
   `Input.parse_input_event` (teclas E, Q, D, Intro; stick y botones de mando simulados).
3. Ajustar las aserciones de «un solo personaje» de `test_level_01.gd` y `test_parity_smoke.gd`
   (este último fuera de owns: ampliado con permiso del coordinador).
4. QA con el MCP (capturas) y guía `docs/design/m2-gate.md`.

## Evidence
- `tools/verify.sh` verde: 504/504 tests GUT, gdformat/gdlint/import/smoke OK.
- `test_m2_flow.gd`:
  - AC1 `test_ac1_level_has_two_characters_and_switcher`,
    `test_ac1_single_switch_moves_and_delivers_with_each_character`: entrega con J1 (E), Q cambia a
    Player2 (`character_switched(1, 2)`, aros), D mueve solo a Player2, E entrega con Player2 y
    Player1 sin control conserva su caja; vuelta a Player1 tras el cooldown.
  - AC2 `test_ac2_coop_deliveries_of_both_players_share_revenue`: J1 (E) y J2 (Intro) entregan;
    `RoundState.get_revenue()` y la última `score_changed` suben con las dos; Q no hace nada en COOP.
  - AC3 `test_ac3_two_pads_each_moves_only_its_character`: `assign_devices(COOP_2P, [0, 1])`; el
    stick del mando 0 mueve solo a Player1 y el del 1 solo a Player2.
  - AC4 `test_ac4_menu_to_game_over_and_retry_with_joypad_only`: menú → cruceta abajo + A (Local 2P)
    → nivel → fin de ronda → A en Reintentar → nivel nuevo en COOP_2P, sin pausa.
- AC5 capturas (MCP, ventana real 1280×757):
  `docs/evidence/PUL-037/ac1-single-cambio-a-p2-indicador.png` (SINGLE tras Q: aro en Player2,
  HUD «Controlas: P2»), `ac3-coop-2p-dos-personajes.png` (COOP: aros amarillo y azul; D movió solo
  a J1 y ← solo a J2), `coop-pausa-desconexion-j2.png` (`handle_joy_connection(1, false)` con
  mandos 0 y 1 asignados: pausa y «Mando de J2 desconectado»). Sin errores en el log del MCP.
  Guía: `docs/design/m2-gate.md`.
- Cambio fuera de la ficha original (autorizado por el coordinador): `test_parity_smoke.gd`
  `test_ac2_play_loads_level_with_one_controllable_player` ahora espera 2 personajes, Player1 con
  `controlled_by = 1` y Player2 con 0. `owns` ampliado con esa ruta.
- Hallazgos de QA (no bloquean, fuera de owns): el título «Mando de J2 desconectado» del menú de
  pausa queda encima de la fila de tickets y se lee peor; `ActiveOrder` de `order_completed` no es
  la misma instancia que la de `get_active_orders()` (los tests comparan `id`). Sin fallos en
  PUL-034..036.
