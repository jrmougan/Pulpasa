---
id: PUL-071
title: Integrar música, ambiente y feedback de las acciones
status: ready
milestone: M3
role: gameplay-engineer
deps: [PUL-066, PUL-068, PUL-069]
orca_task: null
unity_sources: []
owns: [godot/default_bus_layout.tres, godot/autoload/audio_director.gd, godot/autoload/audio_director.gd.uid, godot/project.godot, godot/data/audio/**, godot/resources/audio_*.gd, godot/entities/**/*.tscn, godot/components/**, godot/ui/menus/pause_menu.gd, godot/tests/integration/test_audio_feedback.gd, godot/tests/integration/test_audio_feedback.gd.uid, docs/evidence/PUL-071/**, godot/core/audio_mix.gd, godot/core/audio_mix.gd.uid, godot/entities/**/*.gd, godot/scenes/levels/level_01.tscn, godot/tests/unit/test_audio_mix.gd, godot/tests/unit/test_audio_mix.gd.uid]
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
- [ ] AC1–AC5 de la feature → `test_audio_feedback.gd`
- [ ] AC6 Vídeo o capturas del feedback en `docs/evidence/PUL-071/`
- [ ] AC7 `tools/verify.sh` verde, `check_owns` limpio.

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
