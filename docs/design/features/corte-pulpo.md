# Corte del pulpo cocido sobre la caja (Must, D1)

**Slug:** corte-pulpo · **Prototipo:** `PlayerInteractionController.TryCutPulpo`, `Box`, `Ingredient.Cut`.

## Descripción
No hay estación de corte. El jugador lleva el pulpo **cocido** y lo corta sobre una caja: cada
pulsación de interactuar llena la caja `fill_per_press` y gasta `fill_per_press × 50` de pulpo
(el pulpo tiene 100 unidades). Con la caja llena queda asignado su ingrediente. Cuando el pulpo
llega a 0 desaparece de la mano.

## Criterios de aceptación
- **AC1** Given un jugador con pulpo cocido (100 unidades) mirando una caja vacía, When pulsa interactuar una vez, Then la caja pasa a 5 % (`fill_per_press` = 0,05) y el pulpo a 97,5 unidades.
- **AC2** Given una caja vacía, When se pulsa 20 veces, Then la caja está llena (100 %), conserva el ingrediente `Octopus`, el pulpo en mano tiene 50 unidades y se emite `box_filled` una vez.
- **AC3** Given una caja llena, When se pulsa interactuar con pulpo cocido, Then no cambia ni la caja ni el pulpo.
- **AC4** Given un pulpo de 100 unidades, When se llenan 2 cajas (40 pulsaciones), Then el pulpo llega a 0, se retira de la mano y no queda objeto fantasma.
- **AC5** Given que no existe estación de corte en la escena del nivel, When se carga, Then no hay ningún nodo del grupo `cut_station`.
- **AC6** Given pulpo crudo (no cocido) en la mano, When se pulsa interactuar sobre la caja, Then no se corta (la caja no cambia).

## Datos (`.tres`)
`fill_per_press` (0,05), `octopus_units` (100), `units_per_fill` (50 por caja).

## Verificación
GUT para AC1–AC4 y AC6 (lógica de caja e ingrediente); AC5 por test de escena.
Cambiar «pulsar» por «mantener»: pregunta abierta nº 6 del GDD, no es AC.
