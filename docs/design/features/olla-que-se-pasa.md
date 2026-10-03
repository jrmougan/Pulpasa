# Olla que se pasa (Should)

> Condicional: los AC de esta feature solo aplican si el Should se activa. Sin él rige la variante de paridad de `coccion-pulpo.md` (sin quemado).

**Slug:** olla-que-se-pasa

## Descripción
Si el pulpo cocido no se retira a tiempo, se quema y deja de ser válido.

## Criterios de aceptación
- **AC1** Given un pulpo cocido que sigue en la olla (olla ocupada hasta recogerlo, AC2' de cocción), When pasan 10 s (`burn_time`, dato) sin recogerlo, Then pasa a `BURNT` y se emite `octopus_burnt` una vez.
- **AC2** Given 7 s tras terminar la cocción, Then la barra/indicador avisa (parpadeo) con ≥ 3 s de antelación.
- **AC3** Given un pulpo `BURNT`, When se corta sobre una caja, Then se rechaza; When se desecha, Then la olla queda libre (y también al recogerlo cocido a tiempo).
- **AC4** Given la pausa, Then el temporizador no avanza.

## Datos (`.tres`)
`burn_time` (10 s), `warn_time` (7 s).
