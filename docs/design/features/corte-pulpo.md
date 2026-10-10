# Corte del pulpo cocido sobre la caja (Must, D1, D13, D23, D25)

**Slug:** corte-pulpo · **Prototipo:** `PlayerInteractionController.TryCutPulpo`, `Box`, `Ingredient.Cut`.

## Descripción
No hay estación de corte (D1). El jugador lleva el pulpo **cocido** y lo corta sobre una caja que
está en un **pasaplatos marcado** de la barra: cada pulsación de interactuar (pulsación repetida,
D13) cuenta un corte entero: la caja pasa a `BoxData.fill_after(cortes)` = cortes / `presses_to_fill`
y gasta del pulpo la subida de llenado × 50 unidades (el pulpo tiene 100). Con la caja llena queda
asignado su ingrediente. Cuando al pulpo le quedan `Ingredient.EMPTY_EPSILON` (0,001) unidades o
menos cuenta como agotado (resto de coma flotante), se libera y desaparece de la mano (PUL-104).

Desde D23 la caja **ya no se corta en la bandeja de la estación** (no hay bandeja): el emplatador
deja cajas vacías en los pasaplatos, el cocinero las corta desde la cocina y el emplatador las
recoge llenas desde el servicio. Como 1 pulpo = 2 cajas, lo natural es dejar **dos cajas** y cortar
las dos seguidas: no queda sobrante que aparcar (E8 de PUL-090).

> **Sustituido por D25 (2026-10-10):** ya no hay tamaños S/M/L (ni los cortes 5/10/20 de Unity ni los
> 4/6/10 de D23). Hay **una sola caja** y `presses_to_fill` = **6** (provisional: se re-mide en QA).
> El rack da una sola caja y el ticket no muestra talla. Siguen la pulsación repetida (D13), el
> pasaplatos como mesa de corte y 1 pulpo = 2 cajas.

| Caja | `presses_to_fill` | Llenado por pulsación | Unidades de pulpo por pulsación |
|------|-------------------|-----------------------|--------------------------------|
| Única | 6 | 16,7 % (1/6) | 8,33 |

Cada caja llena consume 50 unidades (`amount_per_full_box`): 1 pulpo = 2 cajas. Desde PUL-104 la
caja cuenta pulsaciones enteras y `fill_after(presses_to_fill)` devuelve 1,0 exacto, así que la
6.ª pulsación llena sin tolerancia (`fill ≥ 1`). El gasto es telescópico (cada corte gasta la
diferencia de llenado × 50): la suma de una caja es 50 y la de dos, 100, salvo un resto de coma
flotante que absorbe `Ingredient.EMPTY_EPSILON`.

## Criterios de aceptación
- **AC1** *(reescrito por D25)* Given un jugador con pulpo cocido (100 unidades) y una caja vacía en un pasaplatos, When pulsa interactuar una vez, Then la caja pasa a `fill_after(1)` = 1 / 6 (16,7 %) y el pulpo pierde 50 / 6 = 8,33 unidades. *Test:* `test_box.gd`.
- **AC2 (R9, reescrito por D25)** Given una caja vacía y pulpo cocido de 100 unidades, When se pulsa N veces (N = `presses_to_fill` en `data/boxes/box.tres`, = 6), Then la caja está llena (100 %), conserva el ingrediente `Octopus`, el pulpo en mano tiene 50 unidades y se emite `box_filled` una vez; con N − 1 = 5 pulsaciones la caja aún no está llena. *Test:* `test_box.gd` + `test_data_boxes.gd`.
- **AC3** Given una caja llena, When se pulsa interactuar con pulpo cocido, Then no cambia ni la caja ni el pulpo. *Test:* `test_box.gd`.
- **AC4** Given un pulpo de 100 unidades, When se llenan 2 cajas (2N = 12 pulsaciones), Then el pulpo llega a 0 (resto ≤ `Ingredient.EMPTY_EPSILON`), se retira de la mano y no queda objeto fantasma. *Test:* `test_box.gd`.
- **AC5** Given que no existe estación de corte en la escena del nivel, When se carga, Then no hay ningún nodo del grupo `cut_station` ni `Tray`. *Test:* `test_level_01.gd`.
- **AC6** Given pulpo crudo (no cocido) en la mano, When se pulsa interactuar sobre la caja, Then no se corta (la caja no cambia). *Test:* `test_box.gd`.
- **AC7** Given una caja vacía en un pasaplatos de la barra, When el cocinero la corta desde el lado de cocina y el emplatador la recoge desde el de servicio, Then los dos lo consiguen sin rodear la barra (el pasaplatos se alcanza desde las dos caras). *Test:* `test_box_on_slot.gd` / `test_station_level.gd`.
- **AC8 (D25)** Given `data/boxes/`, Then existe un único recurso de caja (`box.tres`), no existen `small/medium/large.tres` y `BoxData` no tiene `size`, `short_label` ni `icon` de talla. *Test:* `test_data_boxes.gd`.
- **AC9 (D25)** Given el rack de cajas, When un jugador con la mano vacía pulsa interactuar a ≤ 1,0 m, Then recibe 1 caja vacía (`fill` = 0, sin condimentos); no hay pilas por talla (el rack tiene un solo objetivo). *Test:* `test_box_rack.gd`.

*Superados por D25:* el cuadro S/M/L (4/6/10), la letra de ticket y rack, y el AC2/R9 «N = 4 / 6 / 10».

## Datos (`.tres`)
`presses_to_fill: int` en `data/boxes/box.tres` (6; PUL-104, sustituye a `fill_per_press`) y, en
`data/ingredients/octopus.tres`, `total_capacity` (100) y `amount_per_full_box` (50 por caja). Se
retiran `short_label` e `icon` de talla de `BoxData` (D25).

## Verificación
GUT para AC1–AC4, AC6, AC8 y AC9 (lógica de caja e ingrediente, datos y rack); AC7 en integración;
AC5 por test de escena.

## Preguntas abiertas
1. **Valor de `presses_to_fill`.** 6 es provisional (D25); QA lo re-mide con el flujo de una caja
   única (¿cansa o aburre?). Es un dato: cambiarlo no exige código.
