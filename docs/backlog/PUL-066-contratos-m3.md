---
id: PUL-066
title: Enmendar los contratos para audio, quemado y fases
status: ready
milestone: M3
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [docs/arch/signals.md, docs/arch/scene-tree.md, docs/arch/ADR-002-eventbus-autoloads.md, docs/arch/ADR-006-audio-feedback.md]
touches_scenes: []
---

## Target
M3: `features/audio-y-fx.md` (Must 9), `olla-que-se-pasa.md` y `dificultad-progresiva.md` (Should).
Hoy coger, soltar, cortar y condimentar son señales locales (`signals.md` §4) y no hay buses de
audio, quemado ni fases en los contratos.

## Change
ADR-006 (audio y feedback) y enmiendas de `signals.md`/`scene-tree.md`/ADR-002:
1. Buses `Master/Music/Ambience/SFX` (`default_bus_layout.tres`) y quién reproduce BG/FOL y los FX
   (¿autoload nuevo `AudioDirector` o nodo del nivel?; justifica frente a ADR-002). Bajada de
   `Music`/`Ambience` ≥ 12 dB en pausa (AC3).
2. Qué señales locales se promueven a `EventBus` para el feedback global (coger, soltar, cortar,
   cocer, condimentar…) o si el feedback va en cada escena; mapa evento → sonido/FX en un `.tres`.
3. Quemado: estado `BURNT` ya existe en `IngredientData`; señal local `burnt` de la olla o del
   ingrediente, aviso previo (`warn_time`), datos `burn_time`/`warn_time`.
4. Fases: `phase_changed(phase: int)` en `EventBus` (emisor `RoundManager` reenviando `RoundState`),
   datos de fases en `RoundConfig`, cómo se activan/desactivan puestos y semilla (AC5).

## Constraints
- Solo documentación de contratos. **Gate humano** antes de PUL-069..071.
- Firmas del bus independientes de la dimensión (ADR-005).

## Acceptance
- [ ] AC1 ADR-006 con alternativas y decisión
- [ ] AC2 `signals.md` y `scene-tree.md` cubren todos los AC de las tres features
- [ ] AC3 Lista de decisiones para el responsable en Evidence

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
