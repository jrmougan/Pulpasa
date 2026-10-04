---
id: PUL-035
title: Cambiar de personaje en modo individual y marcar el activo
status: done
milestone: M2
role: gameplay-engineer
deps: []
orca_task: task_bb9b52a4fed0
unity_sources: []
owns: [godot/entities/player/**, godot/components/control_component.gd, godot/assets/materials/active_indicator*, godot/tests/unit/test_character_switcher.gd, godot/tests/unit/test_character_switcher.gd.uid, godot/tests/unit/test_control_component.gd, godot/tests/integration/test_player.gd, docs/evidence/PUL-035/**]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/player/character_switcher.tscn]
---

## Target
M2, Must 6 (D3, D11). Feature `jugadores-y-cambio` AC1–AC6. Contrato: ADR-004 §3–§4,
`scene-tree.md` §2–§3 (`CharacterSwitcher`, `%ActiveIndicator`) y `signals.md`
(`character_switched`, `control_changed`).

## Change
1. `entities/player/character_switcher.gd` + `character_switcher.tscn` (raíz `Node`, común):
   `@export var characters: Array[ControlComponent]`, `@export var config: InputConfig`.
   - Al `round_started`: en `SINGLE` controla J1 el primer personaje y el resto `controlled_by = 0`;
     en `COOP_2P` asigna `controlled_by = 1` y `2`. Emite `character_switched` por cada asignación.
   - En `SINGLE`, `p1_switch` (en `_unhandled_input`) pasa el control al siguiente en el mismo frame
     si pasó `switch_cooldown` y la ronda está en curso; emite `character_switched(1, idx)` una vez.
   - En `COOP_2P` ignora `p1_switch`. Tras `round_finished` no cambia.
   - El modo se lee de `GameState.mode` por defecto, inyectable para tests (como `set_bus`).
2. `player.tscn`: `%ActiveIndicator` (aro bajo el personaje, color por jugador que controla: J1 y J2
   distinguibles; oculto o atenuado si `controlled_by == 0`). `player.gd` lo actualiza con
   `control_changed`. El no controlado: velocidad horizontal 0, sin input, conserva el objeto en la
   mano; el corte en curso se pausa (no recibe pulsaciones).
3. Sandbox de jugador actualizado con dos personajes para la captura.

## Constraints
- El switcher es común: solo ve `ControlComponent`, nunca `Player` ni clases 3D (ADR-004 §4).
- No cambiar firmas de `EventBus`. No editar `level_01.tscn` (lo hace PUL-037) ni `GameState`
  (PUL-034).
- Datos en `.tres` (`switch_cooldown` ya está en `InputConfig`).
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1 Con 2 jugadores (COOP), input de J1 mueve solo al personaje 1 → `test_player.gd`
- [x] AC2 SINGLE: `p1_switch` pasa el control en el mismo frame (< 0,2 s) y emite `character_switched` una vez; respeta el cooldown → `test_character_switcher.gd` (sin escena: dos `ControlComponent` sueltos)
- [x] AC3 El no controlado tiene velocidad 0 y no se mueve en 5 s simulados → `test_player.gd`
- [x] AC4 El no controlado conserva el objeto en la mano tras el cambio → `test_player.gd`
- [x] AC5 Indicador visible y distinto entre activo e inactivo → captura en `docs/evidence/PUL-035/`
- [x] AC6 10 cambios en 2 s: sin errores y siempre exactamente 1 personaje con `controlled_by == 1` → `test_character_switcher.gd`
- [x] AC7 COOP: `p1_switch` no cambia nada; tras `round_finished` tampoco → `test_character_switcher.gd`
- [x] AC8 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- `entities/player/character_switcher.gd` (`class_name CharacterSwitcher`, `extends Node`, común) +
  `character_switcher.tscn` (raíz `Node`, `config = input_config.tres`). Solo ve `ControlComponent`.
  - `set_bus(bus)` y `set_mode(mode)` inyectables (por defecto `EventBus` y `GameState.mode`, leído al
    `round_started`).
  - `round_started` → asigna (`SINGLE`: J1 al primero, resto 0; `COOP_2P`: 1 y 2, resto 0) y emite
    `EventBus.character_switched(jugador, player_index_del_personaje)` por asignación; reinicia el cooldown.
  - `_unhandled_input` (`p1_switch`) → `switch_pressed() -> bool`: solo en `SINGLE`, ronda en curso y
    cooldown cumplido; pone 0 al actual y 1 al siguiente en la misma llamada y emite una vez.
  - Cooldown con reloj propio: `advance(delta)` desde `_process` (se para en pausa; testeable sin esperar).
- `player.gd` + `player.tscn`: `%ActiveIndicator` (`MeshInstance3D`, `TorusMesh` plano a ras de suelo);
  `@export var indicator_materials: Array[Material]` (J1 y J2, `assets/materials/active_indicator_p1/p2.tres`).
  `player.gd` escucha `control_changed`: visible con el material de quien controla, oculto si 0. El no
  controlado ya queda a velocidad 0 y sin input (`ControlComponent.get_player_input()` = `null`, que también
  usa `InteractionComponent`: el corte, que es por pulsación, queda en pausa). La mano no se toca.
- Sandbox: `scenes/sandbox/player_sandbox.tscn` no está en `owns`; `player_sandbox.gd` (sí en owns) añade en
  `_ready` un segundo `Player` y un `CharacterSwitcher` antes de arrancar la ronda.
- Tests:
  - `tests/unit/test_character_switcher.gd` (dos `ControlComponent` sueltos, bus propio): AC2 (cambio inmediato,
    una emisión, cooldown), AC6 (10 cambios en 2 s, siempre 1 con `controlled_by == 1`), AC7 (COOP ignora
    `p1_switch`; tras `round_finished` no cambia), asignación al empezar ronda.
  - `tests/integration/test_player.gd`: AC1 (COOP: `p1_move_right` mueve solo al 1), AC3 (no controlado, 5 s
    con input pulsado: velocidad 0 y misma posición), AC4 (conserva el objeto tras el cambio y no lo suelta con
    `p1_interact`), indicador según `controlled_by`.
  - `tests/unit/test_control_component.gd`: sin cambios previstos.
  - AC5: captura del sandbox con MCP en `docs/evidence/PUL-035/`.

## Evidence
- `tests/unit/test_character_switcher.gd` (14 tests, sin escena: `CharacterSwitcher` + dos `ControlComponent`
  sueltos y bus propio): asignación al empezar ronda en `SINGLE`/`COOP_2P` con su `character_switched`;
  AC2 (cambio en la misma llamada, el nuevo ya tiene `PlayerInput`, una emisión `(1, 2)`, `p1_switch` por
  `_unhandled_input`, cooldown 0,2 s de `input_config.tres` y configurable); AC6 (10 cambios a 0,2 s: siempre
  1 con `controlled_by == 1`, 10 emisiones; y 40 pulsaciones a 0,05 s); AC7 (COOP ignora `p1_switch`; tras
  `round_finished` no cambia; antes de `round_started` tampoco).
- `tests/integration/test_player.gd` (+6): AC1 (COOP: `p1_move_right` mueve 5 m al 1 y 0 al 2; `p2_move_right`
  solo al 2), AC3 (no controlado 5 s con input pulsado: velocidad máx. 0 y misma posición; el que sale del
  control a mitad de movimiento se para y el nuevo se mueve en el siguiente tick), AC4 (conserva el objeto
  tras el cambio y `p1_interact` no lo suelta), indicador (visible con material J1/J2 distinto; oculto con 0).
- AC5 (MCP, `scenes/sandbox/player_sandbox.tscn`, modo `SINGLE`): `docs/evidence/PUL-035/ac5_j1_activo_personaje1.png`
  (aro amarillo bajo el personaje activo, el otro sin aro) y `ac5_tras_cambio_personaje2.png` (tras pulsar Q y
  mover: el aro pasa al segundo; el primero quieto donde se quedó). Sin errores en la salida de depuración.
  J2 tiene aro cian (`active_indicator_p2.tres`), cubierto por test en COOP.
- AC8: `tools/verify.sh` verde (451 tests) y `tools/check_owns.py` limpio.
- Notas: `scenes/sandbox/player_sandbox.tscn` no está en `owns`; el segundo personaje y el switcher los añade
  `player_sandbox.gd` en `_ready`. El `type: action` de `simulate_input` del MCP no dispara `p1_switch`
  (ni `interact`, mismo patrón `is_action_pressed(..., exact_match)`); con la tecla Q sí. Para PUL-037: el
  nivel debe instanciar `character_switcher.tscn` con `characters = [Player1/%Control, Player2/%Control]` y
  `player_index` 1 y 2.
