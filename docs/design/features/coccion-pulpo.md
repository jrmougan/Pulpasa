# Cocción del pulpo (Must)

**Slug:** coccion-pulpo · **Prototipo:** `Kitchen` (`KitchenStation`), `KitchenProgress`, `IngredientSO.cookTime`.

## Descripción
El pulpo cortado se deposita en el caldero; tras `cook_time` queda cocido. Solo el cocido es válido para entregar.

## Criterios de aceptación
- **AC1** Given un caldero libre y un jugador con pulpo cortado, When interactúa con el caldero,
  Then el caldero queda ocupado, la mano vacía y el progreso empieza en 0 %.
- **AC2** Given una cocción iniciada, When pasan 8,0 s (`cook_time`, dato) de juego, Then el pulpo
  pasa a `COOKED`, se emite `cooking_finished` una vez y el caldero queda libre.
- **AC3** Given una cocción en curso, When el juego está en pausa 5 s, Then el progreso no avanza.
- **AC4** Given un caldero ocupado, When otro jugador interactúa con otro pulpo, Then se rechaza y el pulpo sigue en su mano.
- **AC5** Given un pulpo ya cocido, When se intenta depositar de nuevo, Then se rechaza.

## Datos (`.tres`)
`cook_time` (8,0 s). Capacidad del caldero: 1 (pregunta abierta nº 5).

## Verificación
GUT con reloj simulado para AC2–AC3; AC1/AC4/AC5 por estado.
