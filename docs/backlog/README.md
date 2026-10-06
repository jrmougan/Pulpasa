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
| PUL-013 | M0·4 | asset-pipeline | superseded (→ PUL-044, D20) | Modelo y AnimationTree del jugador |
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
| PUL-027 | M1 | gameplay (antigravity → kimi) | done | Paciencia, recaudación, penalizaciones y estrellas |
| PUL-028 | M1 | gameplay (antigravity · flash) | done | Aceite, exclusividad de pimentones y validación exacta |
| PUL-029 | M1 | gameplay (antigravity → kimi) | done | Cachelos y olla con varias plazas |
| PUL-030 | M1 | ui (kimi → Claude) | done | Recaudación, estrellas, iconos y paciencia en la UI |
| PUL-031 | M1 | asset-pipeline (kimi) | done | Iconos y placeholders de aceite, cachelos y estrellas |
| PUL-032 | M1 | qa (Claude) | done | Novedades de M1 en level_01 y QA de M1 |
| PUL-033 | M1 | gameplay (Claude) | done | Comandas con cachelos y legibilidad de cachelos |
| PUL-034 | M2 | gameplay-engineer | done | Asignar mandos a jugadores y gestionar su conexión |
| PUL-035 | M2 | gameplay-engineer | done | Cambiar de personaje en modo individual y marcar el activo |
| PUL-036 | M2 | ui-engineer | done | Menú por modo, avisos de mando y UI navegable solo con mando |
| PUL-037 | M2 | qa-tester | done | Integrar dos personajes en level_01 y pasar el QA de M2 |
| PUL-038 | M2 | ui-engineer | done | Evitar que el aviso de mando desconectado tape los tickets |
| PUL-039 | M2 | gameplay-engineer | done | Reproducir y arreglar que no se pueda entregar en level_01 |
| PUL-040 | M2 | game-designer | done | Diseñar la estación de condimentos y los distintivos de la caja |
| PUL-041 | M2 | game-designer | done | Proponer dos o tres distribuciones de la cocina |
| PUL-042 | M2 | game-designer | done | Escribir la biblia de arte y la lista de assets |
| PUL-043 | M2 | asset-pipeline | done | Preparar el MCP de Blender y el pipeline Blender → glTF → Godot |
| PUL-044 | M3 | asset-pipeline | done | Modelar y animar el personaje (dos variantes) |
| PUL-045 | M3 | asset-pipeline | done | Modelar el pulpo crudo, cocido y troceado |
| PUL-046 | M3 | asset-pipeline | done | Modelar los cachelos crudos y cocidos |
| PUL-047 | M3 | asset-pipeline | done | Modelar las tres cajas/platos de madera y sus distintivos |
| PUL-048 | M3 | asset-pipeline | done | Modelar el caldero de cobre y el fogón |
| PUL-049 | M3 | asset-pipeline | done | Modelar el arcón de pulpo |
| PUL-050 | M3 | asset-pipeline | done | Modelar la cachelera (saco o cesto de patatas) |
| PUL-051 | M3 | asset-pipeline | done | Modelar la estantería de cajas |
| PUL-052 | M3 | asset-pipeline | done | Modelar la estación de condimentos |
| PUL-053 | M3 | asset-pipeline | done | Modelar el puesto de entrega |
| PUL-054 | M3 | asset-pipeline | done | Modelar las encimeras modulares |
| PUL-055 | M3 | asset-pipeline | done | Modelar el entorno de romería |
| PUL-056 | M2 | godot-architect | done | Enmendar los contratos para la estación de condimentos |
| PUL-057 | M2 | gameplay-engineer | done | Implementar las reglas de condimento como núcleo |
| PUL-058 | M2 | gameplay-engineer | done | Crear la escena de la estación de condimentos |
| PUL-059 | M2 | gameplay-engineer | done | Mostrar los distintivos de condimento sobre la caja |
| PUL-060 | M2 | ui-engineer | done | Ordenar los iconos del ticket y darles estilo de pegatina |
| PUL-061 | M2 | gameplay-engineer | done | Montar level_01 con la planta B y la estación, y retirar los botes |
| PUL-062 | M2 | qa-tester | done | Pasar el QA de la estación y la planta B y preparar el playtest |
| PUL-063 | M2 | gameplay-engineer | done | Hacer inequívoca la selección de dispensadores y bandeja en la estación |
| PUL-064 | M2 | gameplay-engineer | done | Ignorar los dispensadores cuando el jugador lleva algo en la mano |
| PUL-065 | M3 | gameplay-engineer | superseded | Encender fuego y vapor de la olla solo al cocinar |
| PUL-066 | M3 | godot-architect | done | Enmendar los contratos para audio, quemado y fases |
| PUL-067 | M3 | gameplay-engineer | done | Retirar placeholders y escalas heredadas tras el arte |
| PUL-068 | M3 | asset-pipeline | done | Conseguir música, ambiente y efectos libres para M3 |
| PUL-069 | M3 | gameplay-engineer | done | Quemar el pulpo que se deja en la olla y encender sus efectos |
| PUL-070 | M3 | gameplay-engineer | done | Subir la dificultad por fases |
| PUL-071 | M3 | gameplay-engineer | done | Integrar música, ambiente y feedback de las acciones |
