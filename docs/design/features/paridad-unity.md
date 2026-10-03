# Paridad con el prototipo Unity (Must)

**Slug:** paridad-unity · **Fuente:** `Assets/` y `docs/migration/inventory.md` (bugs que no se portan).

## Descripción
Antes de ampliar, el Godot reproduce el flujo del prototipo sin sus bugs. Se verifica con un smoke
checklist idéntico en builds Windows y Linux.

## Smoke checklist (criterios de aceptación)
- **AC1** Given el build, When se arranca, Then llega al menú principal en ≤ 5 s sin errores en consola.
- **AC2** Given el menú, When se pulsa «Individual», Then se carga el nivel con 1 personaje controlable.
- **AC3** Given el nivel, When se juega el flujo completo (nevera → olla → corte → condimentos → entrega), Then se completa 1 comanda y suma exactamente +1.
- **AC4** Given el flujo completo ejecutado 20 veces seguidas, Then no hay puestos vacíos, objetos duplicados ni fantasmas.
- **AC5** Given la pausa y reanudar, Then el estado es idéntico (±0,05 s).
- **AC6** Given el fin de partida y «Reintentar», Then el estado se reinicia (sin comandas, olla libre, reloj a 300 s).
- **AC7** Given la lista de bugs de `inventory.md`, Then cada uno tiene un test o una captura que demuestra que no se reproduce.
- **AC8** Given el mismo checklist en Windows y Linux, Then los 7 puntos anteriores pasan en ambos.

## Verificación
GUT/smoke automatizados (AC1–AC6); evidencia en `docs/evidence/` (AC7–AC8); partida lado a lado con Unity (puerta humana M0).
