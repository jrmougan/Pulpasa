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
| PUL-006 | M0·2 | gameplay-engineer | done | Núcleos OrderBoard y RoundState |
| PUL-007 | M0·2 | gameplay-engineer | done | Autoloads OrderService y RoundManager |
| PUL-008 | M0·3 | asset-pipeline | done | Placeholders 3D, muebles propios y escena de escala |
| PUL-009 | M0·3 | asset-pipeline | done | Audio, fuentes e iconos libres (CC0/OFL) |
| PUL-010 | M0·3 | godot-architect | done | Exportación Linux, Windows y Web |
| PUL-011 | M0·4 | gameplay-engineer | done | Componentes comunes: Control, Holder, PlayerInput |
| PUL-012 | M0·4 | gameplay-engineer | done | Escena del jugador, HoldComponent y cámara |
| PUL-013 | M0·4 | asset-pipeline | blocked (licencia del modelo) | Modelo y AnimationTree del jugador |
| PUL-014 | M0·5 | gameplay-engineer | done | Interacción común: scoring, componente y contrato |
| PUL-015 | M0·5 | gameplay-engineer | done | Detector 3D, resaltado por shader y slots |
| PUL-016 | M0·6 | gameplay-engineer | done | Objetos: pulpo, caja y condimento |
| PUL-017 | M0·6 | gameplay-engineer | done | Estaciones: nevera, olla y estanterías |
| PUL-018 | M0·6 | gameplay-engineer | done | Puesto de entrega conectado a OrderService |
| PUL-019 | M0·6 | qa-tester | done | Sandbox de cocina y flujo completo |
| PUL-020 | M0·7 | ui-engineer | done | HUD y panel de tickets |
| PUL-021 | M0·7 | ui-engineer | done | Menú de pausa y fin de partida |
| PUL-022 | M0·7 | ui-engineer | done | Menú principal y flujo de escenas |
| PUL-023 | M0·7 | ui-engineer | done | Pulido de UI con hallazgos de revisión |
| PUL-024 | M0·8 | gameplay-engineer | done | Montaje de level_01 con UI integrada |
| PUL-025 | M0·8 | qa-tester | done | Smoke de paridad M0 y guía de la puerta humana |
| PUL-026 | M0·8 | ui-engineer | done | Layout de HUD y tickets como Unity + menores de level_01 |
| PUL-027 | M1 | gameplay (antigravity · pro) | ready (dep. 028) | Paciencia, recaudación, penalizaciones y estrellas |
| PUL-028 | M1 | gameplay (antigravity · flash) | ready | Aceite, exclusividad de pimentones y validación exacta |
| PUL-029 | M1 | gameplay (antigravity · pro) | ready (dep. 028, 031) | Cachelos y olla con varias plazas |
| PUL-030 | M1 | ui (kimi) | ready (dep. 027, 031) | Recaudación, estrellas, iconos y paciencia en la UI |
| PUL-031 | M1 | asset-pipeline (kimi) | done | Iconos y placeholders de aceite, cachelos y estrellas |
