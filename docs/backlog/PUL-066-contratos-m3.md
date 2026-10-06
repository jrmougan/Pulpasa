---
id: PUL-066
title: Enmendar los contratos para audio, quemado y fases
status: done
milestone: M3
role: godot-architect
deps: []
orca_task: task_4191fa76efc9
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
- [x] AC1 ADR-006 con alternativas y decisión
- [x] AC2 `signals.md` y `scene-tree.md` cubren todos los AC de las tres features
- [x] AC3 Lista de decisiones para el responsable en Evidence

## Plan
1. Leer las tres features (y `opciones-de-volumen`), `signals.md`, `scene-tree.md`, ADR-002..005 y
   cómo suenan hoy `kitchen`/`box`/`order_stand`/`seasoning_station`, `cooking_station.gd`,
   `RoundState`/`OrderBoard`/`OrderService`.
2. ADR-006: buses, reparto mezcla (autoload `AudioDirector` + núcleo `AudioMix`) / reproducción
   (escenas con `FeedbackPlayer`, `LevelAudio` para BG/FOL), mapa de cues en `.tres`, quemado
   (reloj de la plaza, señales locales, desechar) y fases (`PhaseData`, `phase_changed`, puestos
   activos, `max_time`, semilla), con alternativas.
3. Enmiendas: ADR-002 (Enmienda 1: quinto autoload, fases en el reloj), `signals.md` (§2
   `phase_changed`, §3 secuencias, §4 señales locales nuevas y receptores, §5 cobertura de AC),
   `scene-tree.md` (§1–§3, §5, §6, §8).
4. Lista de decisiones para el responsable en `docs/evidence/PUL-066/decisiones.md`.

## Evidence
- AC1: `docs/arch/ADR-006-audio-feedback.md` (8 alternativas, decisión por apartado).
- AC2: `signals.md` §5 mapea cada AC de `audio-y-fx` (AC1, AC2, AC3, AC5), `olla-que-se-pasa`
  (AC1–AC4) y `dificultad-progresiva` (AC1–AC6) a su señal y escena; `scene-tree.md` recoge nodos y
  datos (`AudioDirector`, `LevelAudio`, `%Feedback`, quemado en `kitchen.tscn`, `PhaseData`, buses).
  Única señal nueva del bus: `phase_changed(phase: int)`.
- AC3: `docs/evidence/PUL-066/decisiones.md` (R1–R15 y ajustes de owns de PUL-070/071).
- `tools/verify.sh` verde (645/645 tests, smoke OK; `docs/evidence/PUL-066/verify.log`). Una
  primera pasada falló en GUT sin cambios de código (solo docs): probable intermitencia de
  temporización en los flujos integrados; la segunda, verde. `check_owns` limpio (solo docs).
