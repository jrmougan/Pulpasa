# Cocción del pulpo (Must)

**Slug:** coccion-pulpo · **Prototipo:** `Kitchen` (`KitchenStation`), `KitchenProgress`, `IngredientSO.cookTime`.

## Descripción
La olla recibe pulpo **crudo**; tras `cook_time` queda cocido y vuelve a ser recogible. Solo el
cocido se puede cortar sobre la caja (`corte-pulpo.md`).

## Criterios de aceptación (variante de paridad, sin quemado — la que rige)
- **AC1** Given una olla libre y un jugador con pulpo crudo, When interactúa con la olla, Then la olla queda ocupada, la mano vacía y el progreso empieza en 0 %.
- **AC2** Given una cocción iniciada, When pasan 5,0 s (`cook_time`, dato) de juego, Then el pulpo pasa a `COOKED`, se emite `cooking_finished` una vez, la olla queda libre y el pulpo cocido queda en la olla disponible para recoger.
- **AC3** Given una cocción en curso, When el juego está en pausa 5 s, Then el progreso no avanza.
- **AC4** Given una olla ocupada, When otro jugador interactúa con otro pulpo crudo, Then se rechaza y el pulpo sigue en su mano.
- **AC5** Given un pulpo ya cocido en la mano, When interactúa con la olla, Then se rechaza.
- **AC6** Given una cocción terminada, When pasan 30 s sin recoger el pulpo, Then sigue `COOKED` y válido (no hay quemado en esta variante).

## Variante con el Should `olla-que-se-pasa` activado
Solo si ese Should entra en la alpha, sustituye a AC2 (liberación) y AC6:
- **AC2'** Given una cocción terminada, Then el pulpo cocido sigue en la olla y esta permanece **ocupada** hasta que un jugador lo recoja o desecha; entonces queda libre.
- **AC6'** Given un pulpo cocido sin recoger, When pasan `burn_time` s, Then pasa a `BURNT` (ver `olla-que-se-pasa.md`).

## Datos (`.tres`)
`cook_time` (5,0 s; valor del prototipo). Capacidad de la olla: `KitchenData.capacity` en `data/config/kitchen.tres` (D9, M1: 2 plazas, cada una con su progreso; devuelve lo cocido por orden de finalización). Acepta pulpo y cachelos crudos (D10).

## Verificación
GUT con reloj simulado para AC2–AC3 y AC6; AC1/AC4/AC5 por estado.
