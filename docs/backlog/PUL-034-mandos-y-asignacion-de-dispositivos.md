---
id: PUL-034
title: Asignar mandos a jugadores y gestionar su conexión
status: ready
milestone: M2
role: gameplay-engineer
deps: []
orca_task: null
unity_sources: []
owns: [godot/core/device_assignment.gd, godot/core/device_assignment.gd.uid, godot/autoload/game_state.gd, godot/project.godot, godot/data/config/input_config.tres, godot/resources/input_config.gd, godot/tests/unit/test_device_assignment.gd, godot/tests/unit/test_device_assignment.gd.uid, godot/tests/unit/test_game_state.gd, godot/tests/unit/test_input_map.gd, godot/tests/integration/test_device_input.gd, godot/tests/integration/test_device_input.gd.uid, docs/evidence/PUL-034/**]
touches_scenes: []
---

## Target
M2, Must 5 (coop local 2P y mando Xbox). Feature `mando-y-reasignacion` (AC1–AC4) y
`jugadores-y-cambio` AC8. Contrato: ADR-004 §1–§2 y `docs/arch/signals.md` (`device_assigned`,
`device_disconnected`, ya declaradas en `event_bus.gd`).

## Change
1. `core/device_assignment.gd` (`class_name DeviceAssignment`, `RefCounted`, funciones `static`):
   constantes `ANY = -1` y `NONE = -2`; reparto inicial por modo y mandos conectados (tabla de
   ADR-004 §2) y reglas de hot-plug (desconexión → `NONE`; conexión en `COOP_2P` → al jugador que
   lo perdió si sigue en `NONE`, si no al primero en `NONE`). Sin árbol ni `Input`.
2. `GameState`: en `_ready` copia la plantilla de eventos de mando de cada acción `p<n>_*`;
   `apply_devices()` reescribe solo los eventos de mando según la asignación;
   `start_level(mode)` reparte con `Input.get_connected_joypads()`; escucha
   `Input.joy_connection_changed` (desconexión de un mando asignado durante la ronda →
   `set_paused(true)` + `device_disconnected`; conexión → `device_assigned`);
   `reset_input()` restaura el InputMap de plantilla (para tests). Getter de la asignación actual
   para la UI (`get_device(player_index) -> int`).
3. Zona muerta de `InputConfig.tres` (0,2) aplicada a las acciones de movimiento al arrancar.
4. `project.godot`: completar el InputMap si falta algún binding de mando de ADR-004 §1
   (stick + cruceta, A, Y para `p1_switch`, Start). No renombrar acciones.

## Constraints
- ADR-004 manda: los eventos de teclado no se tocan nunca; `ANY` solo en `SINGLE`; en `COOP_2P`
  un id de mando está como mucho en un jugador.
- No cambiar firmas de `EventBus`. `GameState` sigue siendo adaptador fino (ADR-002): la regla vive
  en `DeviceAssignment`.
- Los tests que toquen el InputMap lo restauran en `after_each` con `GameState.reset_input()`.
- No tocar escenas ni UI (PUL-036 muestra los avisos; PUL-037 integra).
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [ ] AC1 Casos puros de `DeviceAssignment`: SINGLE (J1 `ANY`, J2 `NONE`), COOP con 0, 1 y 2+ mandos (tabla ADR-004 §2), desconexión y reconexión (vuelve a J2, nunca a ambos) → `test_device_assignment.gd`
- [ ] AC2 Integración InputMap: COOP con teclado + 1 mando, un `InputEventJoypadMotion` del mando de J2 activa `p2_move_*` y no `p1_move_*`; con 2 mandos cada uno mueve solo a su jugador; los eventos de teclado siguen intactos → `test_device_input.gd`
- [ ] AC3 Desconexión de un mando asignado en ronda: pausa + `device_disconnected(player_index)` una vez y el jugador conserva su teclado; conexión emite `device_assigned` → `test_game_state.gd`
- [ ] AC4 Toda acción `p<n>_*` (salvo `p2_switch`, que no existe) y `pause` tiene binding de teclado y de mando → `test_input_map.gd`
- [ ] AC5 La zona muerta de movimiento sale de `input_config.tres` → test
- [ ] AC6 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
