---
id: PUL-112
title: Implementar el cubo de basura y colocar 2 en level_01
status: in_progress
milestone: M3d
role: gameplay-engineer
deps: [PUL-110, PUL-111]
orca_task: null
unity_sources: []
owns: [godot/core/trash_rules.gd, godot/core/trash_rules.gd.uid, godot/resources/trash_bin_data.gd, godot/resources/trash_bin_data.gd.uid, godot/data/config/trash_bin.tres, godot/entities/stations/trash_bin.gd, godot/entities/stations/trash_bin.gd.uid, godot/entities/stations/trash_bin.tscn, godot/entities/stations/sandbox/**, godot/data/audio/feedback_map.tres, godot/tests/unit/test_trash_rules.gd, godot/tests/integration/test_trash_bin.gd, godot/tests/integration/test_level_01.gd, godot/tests/integration/test_audio_feedback.gd, docs/design/features/cubo-basura.md, docs/evidence/PUL-112/**, docs/backlog/PUL-112-cubo-basura.md]
touches_scenes: [godot/scenes/levels/level_01.tscn]
---

## Target
Cubo de basura de D25 (`docs/design/features/cubo-basura.md`) con el contrato de ADR-003 §10 (cubo), `signals.md` (señal local `trashed`), `scene-tree.md` (2 instancias en `level_01`) y ADR-006 (cue `trash`).

## Change
- `core/trash_rules.gd` (`RefCounted`, `can_trash`), `resources/trash_bin_data.gd` + `data/config/trash_bin.tres` (`trash_penalty` = 0), `entities/stations/trash_bin.tscn/.gd` (contrato `interactable`, `Holder.drop()` + `trashed` + `queue_free`, `%Feedback`).
- Cue `trash` en `feedback_map.tres` (puede reutilizar un stream existente; el sonido definitivo va aparte).
- 2 instancias en `level_01.tscn` en las posiciones del contrato (`TrashBinKitchen` x −5,45 z −3,15; `TrashBinService` x −5,45 z 3,9).
- Modelo provisional (malla primitiva o un `.glb` existente de `assets/`) con colisión; el arte definitivo es otra ficha.

## Constraints
- Contratos tal cual (PUL-111); sin señales nuevas en `EventBus`. Datos en `.tres`. GDScript tipado. No inventes `uid://`.
- En paralelo PUL-113 (caja única) toca muchos tests y datos de cajas/recetas: no los toques. Si necesitas una ruta fuera de owns, pregunta al coordinador.

## Acceptance
- [ ] AC1–AC6: T1–T6 de `cubo-basura.md` con tests (`test_trash_rules.gd`, `test_trash_bin.gd`, `test_level_01.gd`, `test_audio_feedback.gd`)
- [ ] AC7 Captura de `level_01` con los 2 cubos en `docs/evidence/PUL-112/`
- [ ] AC8 `tools/verify.sh` en verde

## Plan

## Evidence
