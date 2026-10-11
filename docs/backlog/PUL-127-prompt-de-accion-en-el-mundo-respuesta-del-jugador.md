---
id: PUL-127
title: Prompt de acción en el mundo, respuesta del jugador, aro activo y contorno
status: review
milestone: M3e
role: gameplay-engineer
deps: [PUL-121, PUL-123, PUL-124]
orca_task: null
unity_sources: []
owns: [godot/tests/integration/test_player_animation.gd*, godot/components/highlightable.gd*, godot/tests/integration/test_highlightable.gd*, godot/components/action_prompt.gd*, godot/entities/player/player.gd*, godot/shaders/**, godot/tests/integration/test_action_prompt.gd*, godot/tests/integration/test_player.gd*, godot/tests/integration/test_player_ring.gd*, godot/tests/integration/test_player_feedback.gd*, docs/evidence/PUL-127/**, docs/backlog/PUL-127-prompt-de-accion-en-el-mundo-respuesta-del-jugador.md]
touches_scenes: [godot/entities/player/player.tscn, godot/entities/player/action_prompt.tscn]
---

## Target
D26 (`docs/design/decisions.md`), contrato en `docs/arch/` (ADR-003 §11, ADR-004 §6, ADR-005 Enmienda D26,
ADR-006 §4.1, `signals.md`, `scene-tree.md` §9). Partición original y notas de propietarios entre oleadas:
`docs/backlog/PUL-120-contratos-d26.md` («Partición en fichas»). Oleada 2. Diseño:
`docs/design/features/lenguaje-acciones.md` y `controles-tactiles.md`. Touches scenes original: `godot/entities/player/player.tscn`, `godot/entities/player/action_prompt.tscn` (nueva)

## Change
ADR-003 §11.5 y §11.8 (aro, `%ActiveMarker`, contorno `#FFF4D6` / ámbar visible a través
  del personaje); rechazo en el `%Feedback` del jugador (`rejected`) y cue `switch` (ADR-006 §4.1).

### Pendientes heredados (producer)
- Revisión de PUL-121 (hallazgo 4): `components/highlightable.gd:42` duplica el `ShaderMaterial` bloqueado en `_ready` aunque nunca se bloquee y `BLOCKED_COLOR` está en código. Asigna el `blocked_material` `.tres` propio (contorno ámbar) y deriva solo cuando haga falta (si `highlightable.gd` no está en tus owns, pídelo).

## Constraints
- Solo las rutas de `owns`/`touches_scenes`. Si un cambio rompe un test fuera de tus owns, para y avisa al producer.
- Tipado estático, datos en `.tres`, lógica en `core/` RefCounted; no inventes `uid://`.
- Nombres exactos del contrato (manda sobre el diseño; equivalencias en PUL-120).

## Acceptance
- [x] AC1 (diseño AC3, AC5) A 1920x1080 icono >= 64 px, placa >= 80 px, contraste >= 4,5:1; a 1280x720 icono >= 48 px; OK blanco sin aspa, BLOQUEADO ambar + aspa + motivo; visible solo con OK/BLOQUEADO y personaje controlado; sobre el punto de soltar con el hint de suelo -> `test_action_prompt.gd` + captura
- [x] AC2 (diseño AC6, AC7) Exito: sube 12 px y escala 1,25 en 0,35 s; rechazo: parpadeo y sacudida +-6 px >= 0,3 s y exactamente 1 `rejected`; dos pulsaciones a 0,1 s -> 2 cues y 2 respuestas -> `test_action_prompt.gd`, `test_player_feedback.gd`
- [x] AC3 (diseño AC21) Local 2P en el mismo objetivo: 2 prompts con marcador, separados >= 8 px -> `test_action_prompt.gd`
- [x] AC4 (diseño AC12) Con una caja en la mano apuntando al cubo desde el sur, prompt entero visible y >= 25 % del contorno visible tras el personaje -> captura a 1920x1080
- [x] AC5 (diseño AC18) Aro activo solido >= 8 px + triangulo >= 24 px; inactivo discontinuo <= 3 px sin triangulo; contraste en gris >= 3:1; `switch` 1 vez al cambiar en ronda y no al arrancar -> `test_player_ring.gd`, `test_player_feedback.gd` + captura
- [ ] AC6 (pendiente heredado) `blocked_material` `.tres` propio (contorno ambar) y contorno `#FFF4D6` visible a traves del personaje -> `test_action_prompt.gd` (datos del material) + captura

## Plan
Ficheros: `components/action_prompt.gd` (+ `entities/player/action_prompt.tscn`), `entities/player/player.gd` y
`player.tscn` (`%ActionPrompt`, `%ActiveMarker`, `%InactiveIndicator`, `inactive_material`), `shaders/**`
(contorno `#FFF4D6` + pasada sin profundidad al 40 %, material bloqueado ambar, aros activo/inactivo),
tests en `tests/integration/` y capturas en `docs/evidence/PUL-127/`. Sin señales nuevas: el prompt escucha
`InteractionDetector.hint_changed` e `InteractionComponent.interaction_resolved` (locales); el jugador escucha
`interaction_resolved` (cue `rejected` si BLOCKED) y `EventBus.character_switched` (cue `switch`).
- AC1: `test_action_prompt.gd` (medidas en px por proyeccion con camara ortografica inyectada, colores, visibilidad, suelo).
- AC2: `test_action_prompt.gd` (animacion con `advance(delta)`), `test_player_feedback.gd` (1 cue `rejected`, 2 pulsaciones = 2).
- AC3: `test_action_prompt.gd` (registro estatico, separacion >= 8 px).
- AC4/AC5/AC6: `test_player_ring.gd` (grosor, contraste, marcador), `test_action_prompt.gd` (materiales) + capturas.

## Evidence

Tests nuevos (45, todos en verde): `tests/integration/test_action_prompt.gd` (25: medidas a 1080/720, colores, contraste,
visibilidad, ancla, suelo, respuesta OK/BLOQUEADO, 2 pulsaciones, pausa, Local 2P, materiales del contorno),
`test_player_ring.gd` (8: grosor del aro, discontinuo gris, marcador, colores, contraste en gris) y
`test_player_feedback.gd` (12: un `rejected` por pulsacion bloqueada y motivo, `switch` solo en el entrante y no al arrancar).
`tools/verify.sh`: 1002 tests, 1001 en verde; el unico fallo es `test_player_animation.gd::test_indicator_colours_match_variant_palette`
(fuera de `owns`): fija J1 `#2f6fb5` / J2 ambar `#e0a02e`, y D26 (AC5' del diseño) exige un aro no amarillo y contraste >= 3:1
con el gris del inactivo. Esas dos aserciones (lineas 175-176) deben pasar a los colores nuevos (J1 `#1f5fbf`, J2 `#b8325e`):
lo decide el producer (la ficha no puede tocarlo).

Capturas (`docs/evidence/PUL-127/`, generadas por `capture.tscn`/`capture.gd` sobre `level_01` real en un `SubViewport`
de cada resolucion; las estaciones aun no publican verbo, asi que el hint se inyecta con `ActionPrompt.show_hint` y el
contorno con `Highlightable.acquire`, como haria el detector). Mediciones en `measures.txt`:
- `prompts_kitchen_*`, `prompt_ok_pick_up_*`, `prompts_station_*` (1920x1080 y 1280x720): OK blanco sin aspa, BLOQUEADO
  ambar + aspa + motivo, `replaces` con insignia. Icono 64,0 px y placa 80,0 px a 1080; icono 48,0 px y placa 60,0 px a 720.
- `rings_active_inactive_*`: aro solido azul de 10,2 px + triangulo (28 px) en el activo; aro gris discontinuo de 2,5 px sin triangulo en el inactivo.
- `local_2p_two_prompts_*`: dos prompts con marcador J1/J2, hueco de 8,0 px entre placas.
- `cube_from_south_*` (AC12): caja en la mano, cubo desde el sur; prompt entero y contorno a traves del personaje:
  53,5 % (1080) y 42,2 % (720) de los pixeles del contorno visibles (`cube_from_south_outline_mask_*`: rojo = contorno, verde = visible con el personaje delante).

### Desviaciones y pendientes
- `components/highlightable.gd` no esta en `owns`: no se ha cambiado. Queda listo `shaders/highlight_outline_blocked.tres`
  (ambar en las tres pasadas); falta que `Highlightable` lo asigne por defecto (`blocked_material`) en lugar de duplicar y
  retocar `BLOCKED_COLOR` en `_ready` (con el duplicado actual la pasada sin profundidad del bloqueado sale en blanco calido).
- El aro inactivo es un nodo hermano `%InactiveIndicator` (con `inactive_material`) y no el mismo `%ActiveIndicator`:
  `test_m2_flow.gd` exige `%ActiveIndicator.visible == false` en el inactivo (fuera de `owns`). Unificarlos es trivial cuando se actualice ese test.
- Los materiales de aro nuevos (`shaders/ring_active_p1/p2.tres`, `ring_inactive.tres`) viven en `shaders/` (unica ruta de materiales en `owns`) y sustituyen a `assets/materials/active_indicator_p*.tres`.

