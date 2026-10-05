---
id: PUL-056
title: Enmendar los contratos para la estación de condimentos
status: ready
milestone: M2
role: godot-architect
deps: [PUL-040]
orca_task: null
unity_sources: []
owns: [docs/arch/signals.md, docs/arch/scene-tree.md, docs/arch/ADR-003-arbol-escenas-composicion.md]
touches_scenes: []
---

## Target
D18 y `docs/design/features/estacion-condimentos.md` (aprobada por el responsable el 2026-10-05, con `paprika_swap` = intercambiar).
Planta B de `docs/design/level-layouts.md` (D19).

## Change
1. `signals.md` §4: señal local `seasoning_removed(seasoning: SeasoningData)` de `box.gd`; las
   señales de la estación (si alguna cruza escenas, justificar promoción a `EventBus`; si no, local).
2. `scene-tree.md`: escena `entities/stations/seasoning_station.tscn` (bandeja `Tray`, 4
   dispensadores con lado, cuenco de cachelos, `%Highlightable`s), `BadgeRow` en `box.tscn`, árbol
   de `level_01.tscn` con la planta B (barra con pasaplatos, 2 ollas, estación en la barra) y bajas
   (`spice_shelf.tscn`, `seasoning.tscn`, `SeasoningItem`).
3. Cómo sabe un dispensador desde qué lado se le usa sin tipos 3D en la capa común (ADR-003 §0).

## Constraints
- Solo documentación de contratos. El responsable aprueba la enmienda (gate humano) antes de que
  empiecen PUL-057..PUL-062.

## Acceptance
- [ ] AC1 `signals.md` y `scene-tree.md` cubren todo lo que nombra la feature (AC1–AC18)
- [ ] AC2 Decisión sobre el lado del dispensador explicada (común vs. específico)
- [ ] AC3 Lista de lo que se da de baja

## Plan
(Lo escribe el worker antes de implementar.)

## Evidence
(Lo rellena el worker.)
