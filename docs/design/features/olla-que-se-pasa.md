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

## Ampliado por D26 (2026-10-11): aviso legible
«Listo / quemándose» casi no tenía señal (barra pálida de 27×4 px a 720p). D26 §6 la hace legible;
AC2 y AC3 quedan **precisados** por los siguientes (los originales siguen vigentes):
- **AC2' (aviso claro)** Given un cocido que sigue en la olla (`warn_time` = 7 s, `burn_time` = 10 s), When pasan 7,0 s (±0,1) desde que quedó listo, Then el anillo de la plaza parpadea **ámbar ↔ rojo** a 3 Hz (±0,5), aparece el icono de llama con «!», suena `burn_warning` y se repite cada 1 s hasta quemarse; el aviso empieza **≥ 3,0 s antes** de quemarse (`burn_time − warn_time ≥ 3`, test de datos). When el jugador retira el cocido durante el aviso, Then el parpadeo y los cues cesan en ≤ 1 frame. *Test:* `test_burn.gd` + test de datos (= `lenguaje-acciones.md` AC16).
- **AC3' (tirar el quemado, verbo)** Given un quemado en la olla y la mano vacía, Then la olla muestra el verbo **TIRAR** (OK) antes de pulsar; When pulsa, Then se desecha el más antiguo (`discarded`), suena `discard` con sample propio (distinto de `trash`, `drop` y `pick_up`) y el icono salta; si queda un cocido listo, el siguiente verbo es COGER. *Test:* `test_burn.gd` + `test_action_matrix.gd`.
- **AC5 (anillo quemado)** Given un pulpo `BURNT`, Then el anillo de su plaza es rojo fijo con humo; no parpadea. *Test:* captura.

## Datos (`.tres`)
`burn_time` (10 s), `warn_time` (7 s; D26: `burn_time − warn_time ≥ 3 s`), parpadeo 3 Hz y colores en
`ActionLanguageData` (`lenguaje-acciones.md`).
