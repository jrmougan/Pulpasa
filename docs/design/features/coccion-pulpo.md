# Cocción del pulpo (Must)

**Slug:** coccion-pulpo · **Prototipo:** `Kitchen` (`KitchenStation`), `KitchenProgress`, `IngredientSO.cookTime`.

## Descripción
La olla recibe pulpo **crudo**; tras `cook_time` queda cocido y vuelve a ser recogible. Solo el
cocido se puede cortar sobre la caja (`corte-pulpo.md`).

## Criterios de aceptación
- **AC1** Given una olla libre y un jugador con pulpo crudo, When interactúa con la olla, Then la olla queda ocupada, la mano vacía y el progreso empieza en 0 %.
- **AC2** Given una cocción iniciada, When pasan 5,0 s (`cook_time`, dato) de juego, Then el pulpo pasa a `COOKED`, se emite `cooking_finished` una vez y la olla queda libre.
- **AC3** Given una cocción en curso, When el juego está en pausa 5 s, Then el progreso no avanza.
- **AC4** Given una olla ocupada, When otro jugador interactúa con otro pulpo crudo, Then se rechaza y el pulpo sigue en su mano.
- **AC5** Given un pulpo ya cocido, When se intenta meter en la olla, Then se rechaza.
- **AC6** Given una cocción terminada, When pasan 30 s sin recoger el pulpo, Then sigue `COOKED` (el quemado es Should: `olla-que-se-pasa.md`).

## Datos (`.tres`)
`cook_time` (5,0 s; valor del prototipo). Capacidad de la olla: 1 (pregunta abierta nº 4).

## Verificación
GUT con reloj simulado para AC2–AC3 y AC6; AC1/AC4/AC5 por estado.
