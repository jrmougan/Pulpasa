# Corte del pulpo cocido sobre la caja (Must, D1)

**Slug:** corte-pulpo · **Prototipo:** `PlayerInteractionController.TryCutPulpo`, `Box`, `Ingredient.Cut`.

## Descripción
No hay estación de corte. El jugador lleva el pulpo **cocido** y lo corta sobre una caja: cada
pulsación de interactuar llena la caja `fill_per_press` (por tipo de caja) y gasta
`fill_per_press × 50` unidades de pulpo (el pulpo tiene 100). Con la caja llena queda asignado su
ingrediente. Cuando el pulpo llega a 0 desaparece de la mano.

| Caja | `fill_per_press` | Pulsaciones | Unidades de pulpo por pulsación |
|------|------------------|-------------|--------------------------------|
| Small | 0,2 | 5 | 10 |
| Medium | 0,1 | 10 | 5 |
| Large | 0,05 | 20 | 2,5 |

Cada caja llena consume 50 unidades: 1 pulpo = 2 cajas, sea cual sea el tamaño.

## Criterios de aceptación
- **AC1** Given un jugador con pulpo cocido (100 unidades) y una caja vacía de tipo T, When pulsa interactuar una vez, Then la caja pasa a `fill_per_press(T)` × 100 % (20 % Small, 10 % Medium, 5 % Large) y el pulpo pierde `fill_per_press(T) × 50` unidades.
- **AC2** Given una caja vacía de tipo T, When se pulsa N veces (N = 5 Small, 10 Medium, 20 Large), Then la caja está llena (100 %), conserva el ingrediente `Octopus`, el pulpo en mano tiene 50 unidades y se emite `box_filled` una vez.
- **AC3** Given una caja llena, When se pulsa interactuar con pulpo cocido, Then no cambia ni la caja ni el pulpo.
- **AC4** Given un pulpo de 100 unidades, When se llenan 2 cajas del mismo tipo (2N pulsaciones), Then el pulpo llega a 0, se retira de la mano y no queda objeto fantasma.
- **AC5** Given que no existe estación de corte en la escena del nivel, When se carga, Then no hay ningún nodo del grupo `cut_station`.
- **AC6** Given pulpo crudo (no cocido) en la mano, When se pulsa interactuar sobre la caja, Then no se corta (la caja no cambia).

## Datos (`.tres`)
`fill_per_press` **por tipo de caja** (Small 0,2 / Medium 0,1 / Large 0,05, valores de los prefabs de Unity), `octopus_units` (100), `units_per_fill` (50 por caja).

## Verificación
GUT para AC1–AC4 y AC6 (lógica de caja e ingrediente); AC5 por test de escena.
Cambiar «pulsar» por «mantener»: propuesta para gate humano (GDD §10), no es AC.
