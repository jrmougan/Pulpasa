---
id: PUL-003
title: Redactar ADR-001..004 y contratos de arquitectura
status: ready
milestone: F0
role: godot-architect
deps: [PUL-001]
orca_task: null
unity_sources: [Assets/Scripts/Architecture/**, Assets/Scripts/Systems/**, Assets/Scripts/Interfaces/**]
owns: [docs/arch/**]
touches_scenes: []
---

## Target
`docs/arch/` a partir de `docs/migration/inventory.md` y `docs/design/decisions.md`.

## Change
- ADR-001 Lenguaje y convenciones GDScript (tipado, nombres, estructura de carpetas).
- ADR-002 Bus de eventos y autoloads (`EventBus`, `OrderService`, `GameState`), qué sustituye a QFramework.
- ADR-003 Árbol de escenas y composición (escenas pequeñas, `level_01.tscn` solo instancia).
- ADR-004 Input para coop local y cambio de personaje (InputMap por dispositivo).
- `docs/arch/signals.md`: catálogo de señales con firma tipada.
- `docs/arch/scene-tree.md`: árbol objetivo de M0.

## Constraints
No crear código ni escenas. Cada ADR: contexto, decisión, alternativas, consecuencias.

## Acceptance
- [ ] AC1 Los 4 ADR existen con estado «propuesto».
- [ ] AC2 Cada señal de signals.md tiene emisor, receptores y tipos.
- [ ] AC3 Gate humano: el responsable aprueba los ADR (estado → «aceptado»).

## Plan

## Evidence
