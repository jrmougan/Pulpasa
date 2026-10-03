# Backlog

Una ficha por tarea: `PUL-<nnn>-<slug>.md`, a partir de `_TEMPLATE.md`.

- **Ciclo:** draft → ready (la marca el producer) → in_progress → review → done.
- **owns / touches_scenes** limitan lo que el worker puede editar. Un `.tscn` tiene un solo
  dueño por oleada.
- Cada criterio de aceptación enlaza con un test o con una captura en `docs/evidence/<id>/`.
- El cuerpo sigue el contrato de Orca (Target, Change, Constraints, Ownership, Acceptance),
  así que la ficha se pasa tal cual a `worker-start --spec`.

## Fichas actuales

| Id | Hito | Rol | Estado | Título |
|----|------|-----|--------|--------|
| PUL-001 | F0 | migration-analyst | done | Inventario Unity → Godot |
| PUL-002 | F0 | game-designer | done | GDD de trabajo y backlog de la alpha |
| PUL-003 | F0 | godot-architect | done | ADR-001..004 y contratos |
| PUL-004 | M0·0 | godot-architect | done | Esqueleto: EventBus, GameState, InputMap |
| PUL-005 | M0·1 | gameplay-engineer | done | Resources y .tres del prototipo |
| PUL-006 | M0·2 | gameplay-engineer | ready (dep. 004, 005) | Núcleos OrderBoard y RoundState |
| PUL-007 | M0·2 | gameplay-engineer | ready (dep. 006) | Autoloads OrderService y RoundManager |
| PUL-008 | M0·3 | asset-pipeline | ready | Placeholders 3D, muebles propios y escena de escala |
| PUL-009 | M0·3 | asset-pipeline | done | Audio, fuentes e iconos libres (CC0/OFL) |
| PUL-010 | M0·3 | godot-architect | ready (tras PUL-007: comparte project.godot) | Exportación Linux, Windows y Web |
