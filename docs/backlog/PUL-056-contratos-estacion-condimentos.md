---
id: PUL-056
title: Enmendar los contratos para la estación de condimentos
status: done
milestone: M2
role: godot-architect
deps: [PUL-040]
orca_task: task_f8eea586e3ef
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
- [x] AC1 `signals.md` y `scene-tree.md` cubren todo lo que nombra la feature (AC1–AC18)
- [x] AC2 Decisión sobre el lado del dispensador explicada (común vs. específico)
- [x] AC3 Lista de lo que se da de baja

## Plan
1. ADR-003: enmienda «Estación de condimentos» con (a) el lado del dispensador resuelto en dos
   piezas: geometría pura común (`core/station_side.gd`, `Vector2` del suelo) + método opcional
   `is_reachable_from(floor_position, holder)` del contrato `interactable` que el detector
   (específico) consulta antes de puntuar; (b) patrón «consumir y rechazar» para que una pulsación
   rechazada no suelte lo que se lleva; (c) dispensadores como una escena + `SeasoningData`
   (§1); (d) bajas de `seasoning.tscn`, `SeasoningItem` y del condimento en el contrato `pickable`.
2. `signals.md` §4: `Box.seasoning_removed`, `seasoned` emitida por `toggle_seasoning`, orden en el
   intercambio, `rejected` de dispensador y cuenco, `stock_changed` del cuenco; justificación de
   que nada se promueve a `EventBus`. Tipos nuevos de §1 (`SeasoningRules.Rejection`,
   `StationSide.Side`).
3. `scene-tree.md`: árbol de `level_01.tscn` con la planta B, escenas `seasoning_station.tscn`,
   `seasoning_dispenser.tscn`, `cachelos_bowl.tscn`, `Tray` (slot de caja), `BadgeRow` en
   `box.tscn`, datos nuevos y tabla de bajas con la ficha que las ejecuta.
4. Lista de rutas que las fichas PUL-057..061 necesitan añadir a su `owns` (para el coordinador).

## Evidence
Solo documentación. `tools/verify.sh` verde (504/504 GUT, smoke OK); `check_owns` limpio.

- **AC1** Cobertura de la feature:
  - AC1–AC4 (alternar, antirrebote, intercambio): `signals.md` §4 (`seasoned`,
    `seasoning_removed` con orden en el intercambio, secuencia del dispensador) y API de la caja
    (`scene-tree.md` §3, ADR-003 §8.3).
  - AC5, AC6, AC8, AC10, AC11 (rechazos y cuenco): `rejected(SeasoningRules.Rejection)` y
    `stock_changed` (`signals.md` §1 y §4); patrón «consumir y rechazar» (ADR-003 §8.2).
  - AC7: ADR-003 §8.1. AC9: `Slot.accepted_group` y grupo `box` (ADR-003 §4 y §8.2).
  - AC12: la caja ya no condimenta en `interact()` (ADR-003 §4; `scene-tree.md` §3).
  - AC13–AC15: `%BadgeRow` en `box.tscn`, `SeasoningRules.canonical_order()`,
    `BoxBadgeStyle` compartido con `ticket_entry` (`scene-tree.md` §3, §4, §5).
  - AC16–AC18: árbol de `level_01.tscn` con la planta B, sin `SpiceShelf` (`scene-tree.md` §2).
- **AC2** ADR-003 §8.1: regla geométrica común (`core/station_side.gd`, `Vector2` del suelo) +
  método opcional `is_reachable_from(floor_position, holder)` del contrato `interactable` que
  consulta el detector (específico); 5 alternativas descartadas con su motivo.
- **AC3** `scene-tree.md` §7: bajas, con la ficha que ejecuta cada una (PUL-061) y lo que se mantiene.

**Para el gate humano** (decisiones que aprueba el responsable):
1. El contrato `interactable` gana un método **opcional** `is_reachable_from` y el detector lo
   consulta (ADR-003 §8.1).
2. Grupo marca nuevo `box` y `Slot.accepted_group` para la bandeja (ADR-003 §4 y §8.2).
3. Dispensador y cuenco consumen siempre la pulsación; los rechazos son la señal local `rejected`
   (nada sube a `EventBus`).
4. Escenas propias `seasoning_dispenser.tscn` y `cachelos_bowl.tscn` (no solo la de la estación).
5. Estación de 4 celdas (cols 5–8) en lugar de las 2 de la planta B, con el mismo centro; 9
   `Slot` de pasaplatos. Posiciones de inicio de J1 (servicio) y J2 (cocina) según
   `level-layouts.md` (la feature dice J1 en cocina: es solo ejemplo de reparto).

**Rutas que faltan en el `owns` de las fichas siguientes** (las asigna el coordinador):
- PUL-057: `godot/core/station_side.gd(.uid)` y `godot/tests/unit/test_station_side.gd(.uid)`
  (o en PUL-058); el grupo `box` en `godot/entities/items/box.tscn` (o en PUL-059, pero PUL-058 lo
  necesita para la bandeja).
- PUL-058: `godot/entities/stations/seasoning_dispenser.tscn`, `godot/entities/stations/cachelos_bowl.tscn`,
  `godot/entities/stations/slot.gd` (`accepted_group`), `godot/components/interaction_detector.gd`,
  `godot/components/interaction_contract.gd` y sus tests (`test_interaction_detector.gd`,
  `test_interaction_contract.gd`, `test_slot.gd`). `interaction_detector.gd` lo tiene hoy PUL-039:
  PUL-058 va detrás.
- PUL-061: `godot/assets/models/placeholders/condiment_jar.tscn` (baja) y `godot/scenes/scale_check.tscn`
  / `godot/scenes/sandbox/**` (instancias de botes).
