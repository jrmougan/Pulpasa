# Olla que se pasa (Should)

**Estado: implementada** (ADR-006 §5; `cooking_station.gd`, `test_burn.gd`). Verificada en PUL-108 contra el código.

**Slug:** olla-que-se-pasa

## Descripción
Si el pulpo cocido no se retira a tiempo, se quema y deja de ser válido.

## Criterios de aceptación
- **AC1** Given un pulpo cocido que sigue en la olla (olla ocupada hasta recogerlo, AC2' de cocción), When pasan 10 s (`burn_time`, dato) sin recogerlo, Then pasa a `BURNT` y se emite `burnt(ingredient)` una vez (señal local de `cooking_station.gd`, `signals.md`; antes `octopus_burnt`, generalizada a cualquier ingrediente cocido, PUL-066 y PUL-108).
- **AC2** Given 7 s tras terminar la cocción, Then la barra/indicador avisa (parpadeo) con ≥ 3 s de antelación.
- **AC3** Given un pulpo `BURNT`, When se corta sobre una caja, Then se rechaza; When se desecha, Then la olla queda libre (y también al recogerlo cocido a tiempo).
- **AC4** Given la pausa, Then el temporizador no avanza.

## Datos (`.tres`)
`burn_time` (10 s), `warn_time` (7 s).
