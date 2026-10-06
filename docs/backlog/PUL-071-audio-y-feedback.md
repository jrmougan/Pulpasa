---
id: PUL-071
title: Integrar música, ambiente y feedback de las acciones
status: done
milestone: M3
role: gameplay-engineer
deps: [PUL-066, PUL-068, PUL-069]
orca_task: task_a96cf3d7d628
unity_sources: []
owns: [godot/default_bus_layout.tres, godot/autoload/audio_director.gd, godot/autoload/audio_director.gd.uid, godot/project.godot, godot/data/audio/**, godot/resources/audio_*.gd, godot/entities/**/*.tscn, godot/components/**, godot/ui/menus/pause_menu.gd, godot/tests/integration/test_audio_feedback.gd, godot/tests/integration/test_audio_feedback.gd.uid, docs/evidence/PUL-071/**, godot/core/audio_mix.gd, godot/core/audio_mix.gd.uid, godot/entities/**/*.gd, godot/scenes/levels/level_01.tscn, godot/tests/unit/test_audio_mix.gd, godot/tests/unit/test_audio_mix.gd.uid, godot/tests/integration/test_order_stand.gd, godot/tests/integration/test_seasoning_station.gd, godot/tests/unit/test_data_integrity.gd, godot/resources/audio_*.gd.uid, godot/entities/**/*.gd.uid]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
`features/audio-y-fx.md` (AC1–AC5, Must 9) con ADR-006 (PUL-066) y el audio de PUL-068.
Owns provisional: el coordinador lo ajusta al cerrar PUL-066 (según dónde viva el director de audio).

## Change
Buses, BG/FOL en bucle, mapa evento → sonido y respuesta visual ≥ 0,3 s para coger, cocer,
condimentar, entrega correcta y errónea (distintas), bajada de buses en pausa.

## Constraints
- Antes de cerrar: `tools/verify.sh` verde y `tools/check_owns.py <tu-rama> jrmougan/agentica-migracion-godot-alpha` limpio.

## Acceptance
- [x] AC1–AC5 de la feature → `test_audio_feedback.gd`
- [x] AC6 Vídeo o capturas del feedback en `docs/evidence/PUL-071/`
- [x] AC7 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
- **Mezcla** (ADR-006 §1–2): `default_bus_layout.tres` (Master → Music, Ambience, SFX);
  `core/audio_mix.gd` (`AudioMix`, núcleo puro) + `resources/audio_mix_config.gd` /
  `data/audio/audio_mix.tres`; autoload `AudioDirector` (#5 en `project.godot`, `ALWAYS`), único
  escritor de `AudioServer.set_bus_volume_db`, oye `pause_changed` (AC3).
- **Datos de feedback** (§4): `resources/audio_cue.gd`, `resources/audio_feedback_map.gd`,
  `data/audio/feedback_map.tres` con las 16 claves cerradas.
- **`components/feedback_player.gd`** (`FeedbackPlayer extends AudioStreamPlayer3D`): `play_cue`,
  `played`, `delay` con cola que se congela en pausa, `POP`/`SHAKE` con `Tween` del nodo visual
  (`Model` del objetivo si lo tiene), `get_visual_tween(target)` para tests.
- **Escenas**: `%Feedback` en `player.tscn` (pick_up/drop), `box.tscn` (cut/season/unseason,
  sustituye `%CutAudio`/`%SeasonAudio`), `kitchen.tscn` (cook_start/cook_done/burn_warning/burnt/
  discard), `order_stand.tscn` (deliver_ok/deliver_error/order_new/order_expired, sustituye
  `%OkAudio`/`%ErrorAudio`), `seasoning_station.tscn` (season_error, sustituye `%ErrorAudio`; la
  sacudida pasa al `FeedbackPlayer`). `%BoilAudio` en `SFX`.
- **`entities/environment/level_audio.{tscn,gd}`** instanciado en `level_01.tscn`: BG/FOL al
  `round_started`; `phase_up` en `phase_changed(n ≥ 2)` conectándose solo si el bus declara la
  señal (la añade PUL-070; no se toca `event_bus.gd`).
- **Tests**: `tests/unit/test_audio_mix.gd` (aritmética AC3, datos), `tests/integration/
  test_audio_feedback.gd` (AC1 BG/FOL y buses, AC2 una `played` por señal, AC5 sonido + visual
  ≥ 0,3 s y ok ≠ error, AC3 buses en pausa con `AudioDirector`, ninguna escena en `Master`, mapa
  completo). Se adaptan `test_order_stand.gd` y `test_seasoning_station.gd` a `%Feedback.played`
  (owns ampliado por el coordinador).

## Evidence
- `tools/verify.sh` verde: 687/687 tests GUT, gdformat/gdlint limpios, smoke OK.
- **AC1** `test_audio_feedback.gd::test_ac1_*`: `LevelAudio` en `level_01.tscn`; tras `round_started`
  y 1 s suenan BG (`Music`) y FOL (`Ambience`) en bucle, y siguen en pausa (`ALWAYS`).
- **AC2** `test_ac2_*`: una `played` por señal: coger, soltar, corte, caldero, nueva comanda (tras
  0,5 s, congelado en pausa), entrega y caducada, solo para el `slot_id` propio.
- **AC5** `test_ac5_*`: sonido + `Tween` ≥ 0,3 s que vuelve a reposo en coger (`POP` del objeto),
  cocer (`POP` olla / ingrediente), condimentar (`POP` caja), entrega correcta (`POP`) y errónea
  (`SHAKE`, otro stream). Capturas: `docs/evidence/PUL-071/feedback_strips.png` y `feedback.gif`
  (6 instantes de `visual_time` por acción; `capture_feedback.gd` las reproduce).
- **AC3** `test_ac3_*` + `tests/unit/test_audio_mix.gd`: `AudioDirector` (autoload #5) baja
  `Music`/`Ambience` 12 dB en pausa (también vía `GameState.set_paused`) y los restaura; `SFX` igual.
- Ningún `AudioStreamPlayer*` de `entities/`, `scenes/`, `ui/` en `Master` (`test_no_scene_player_left_on_master`).
- Datos: `data/audio/feedback_map.tres` (16 cues de ADR-006 §4), `audio_mix.tres`,
  `default_bus_layout.tres`; generador reproducible en `docs/evidence/PUL-071/gen_audio_data.gd`.
- Notas para revisión:
  - `AudioCue` gana `shake_amplitude` (no estaba en la tabla del ADR): la sacudida de 0,04 m del
    dispensador no se ve en un puesto (deliver_error usa 0,12 m).
  - `phase_up`: tras mergear PUL-070, `LevelAudio` conecta `_bus.phase_changed` directamente;
    `test_round_manager_phase_two_plays_phase_cue` arranca `RoundManager` con las fases reales de
    `round_config.tres` y comprueba que `%PhaseCue` suena en la fase 2 y no en la 1.
  - Sin FX propio de PUL-068 para cocer: `cook_start` usa `fx_drop` y `cook_done` `fx_ui_click`;
    conviene escucha humana.
  - Owns ampliado por el coordinador: `test_order_stand.gd`, `test_seasoning_station.gd`
    (ahora cuentan `%Feedback.played`) y `test_data_integrity.gd` (sin recuento fijo de `.tres`:
    tipo por carpeta, mínimo por carpeta y lista de conocidos).
  - El POP del puesto tapa un instante su número (`StandNumber` no está bajo `Model`).
