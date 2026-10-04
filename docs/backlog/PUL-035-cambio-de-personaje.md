---
id: PUL-035
title: Cambiar de personaje en modo individual y marcar el activo
status: ready
milestone: M2
role: gameplay-engineer
deps: []
orca_task: null
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
- [ ] AC1 Con 2 jugadores (COOP), input de J1 mueve solo al personaje 1 → `test_player.gd`
- [ ] AC2 SINGLE: `p1_switch` pasa el control en el mismo frame (< 0,2 s) y emite `character_switched` una vez; respeta el cooldown → `test_character_switcher.gd` (sin escena: dos `ControlComponent` sueltos)
- [ ] AC3 El no controlado tiene velocidad 0 y no se mueve en 5 s simulados → `test_player.gd`
- [ ] AC4 El no controlado conserva el objeto en la mano tras el cambio → `test_player.gd`
- [ ] AC5 Indicador visible y distinto entre activo e inactivo → captura en `docs/evidence/PUL-035/`
- [ ] AC6 10 cambios en 2 s: sin errores y siempre exactamente 1 personaje con `controlled_by == 1` → `test_character_switcher.gd`
- [ ] AC7 COOP: `p1_switch` no cambia nada; tras `round_finished` tampoco → `test_character_switcher.gd`
- [ ] AC8 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
