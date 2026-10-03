# Hoja de ruta

Propuesta completa (privada): https://claude.ai/artifact/PstRxmwwgejjsphmEXCkJe

| Hito | Contenido | Puerta humana |
|------|-----------|---------------|
| B | Bootstrap de entorno y sistema agéntico | MCP funciona (hecho) |
| F0 | Inventario (PUL-001), GDD de trabajo (PUL-002), ADRs (PUL-003) | Aprobar ADRs y alcance |
| M0 | Migración hasta paridad con Unity, sin sus bugs | Partida lado a lado; archivar Unity |
| M1 | Paciencia, puntuación y estrellas, aceite y cachelos, iconos en tickets | — |
| M2 | Coop local 2P, mando, cambio de personaje, menú por modo | Playtest de game feel |
| M3 | Audio completo, feedback, olla que se pasa, dificultad por fases | — |
| M4 | Balanceo, opciones, gallego, builds Win/Linux, playtests | Publicar alpha |

## Fases de M0

| # | Contenido | Verificación |
|---|-----------|--------------|
| 0 | Esqueleto: InputMap, autoloads, GUT, CI | Import y tests en verde |
| 1 | Datos: Resources + `.tres` de los ScriptableObjects | Test que carga las 3 comandas |
| 2 | Lógica pura: OrderService, RoundManager | Tests de todas las ramas de validación |
| 3 | Assets: FBX, materiales, audio, fuentes; escena de escala | Captura + revisión humana |
| 4 | Jugador: movimiento, AnimationTree, coger/soltar | Integración con input simulado |
| 5 | Interacción: detector, slots, resaltado | Tests de selección de objetivo |
| 6 | Estaciones: spawner, olla, caja, especias, entrega | Flujo completo = comanda completada una vez |
| 7 | UI: tickets, HUD, pausa, game over, menú | Tests de UI + prueba con teclado y mando |
| 8 | `level_01.tscn`, iluminación, export Linux/Web | Partida lado a lado con Unity |

Coop, audio completo y pulido no son M0.
