# Corte del pulpo cocido sobre la caja (Must, D1, D13, D23)

**Slug:** corte-pulpo · **Prototipo:** `PlayerInteractionController.TryCutPulpo`, `Box`, `Ingredient.Cut`.

## Descripción
No hay estación de corte (D1). El jugador lleva el pulpo **cocido** y lo corta sobre una caja que
está en un **pasaplatos marcado** de la barra: cada pulsación de interactuar (pulsación repetida,
D13) cuenta un corte entero: la caja pasa a `BoxData.fill_after(cortes)` = cortes / `presses_to_fill`
(por tipo de caja) y gasta del pulpo la subida de llenado × 50 unidades (el pulpo tiene 100). Con la
caja llena queda asignado su ingrediente. Cuando al pulpo le quedan `Ingredient.EMPTY_EPSILON`
(0,001) unidades o menos cuenta como agotado (resto de coma flotante), se libera y desaparece de la
mano (PUL-104).

Desde D23 la caja **ya no se corta en la bandeja de la estación** (no hay bandeja): el emplatador
deja cajas vacías en los pasaplatos, el cocinero las corta desde la cocina y el emplatador las
recoge llenas desde el servicio. Como 1 pulpo = 2 cajas, lo natural es dejar **dos cajas** y cortar
las dos seguidas: no queda sobrante que aparcar (E8 de PUL-090).

> **Sustituido por D23:** los cortes 5 / 10 / 20 (valores de Unity) pasan a **4 / 6 / 10** (G3 de
> PUL-090: la L era el 69 % de las pulsaciones del pedido). Sigue la pulsación repetida (D13; el
> «mantener pulsado», B-C, quedó descartado en el gate).

| Caja | Letra (ticket/rack) | `presses_to_fill` | Llenado por pulsación | Unidades de pulpo por pulsación |
|------|---------------------|-------------------|-----------------------|--------------------------------|
| Small | S | 4 | 25 % | 12,5 |
| Medium | M | 6 | 16,7 % (1/6) | 8,33 |
| Large | L | 10 | 10 % | 5 |

Cada caja llena consume 50 unidades: 1 pulpo = 2 cajas, sea cual sea el tamaño. Desde PUL-104 la
caja cuenta pulsaciones enteras y `fill_after(presses_to_fill)` devuelve 1,0 exacto, así que la
6.ª pulsación de la M llena sin tolerancia (`fill ≥ 1`). El gasto es telescópico (cada corte gasta
la diferencia de llenado × 50): la suma de una caja es 50 y la de dos, 100, salvo un resto de coma
flotante que absorbe `Ingredient.EMPTY_EPSILON`. Sustituye al antiguo `fill_per_press: float`
(0,25 / 0,1667 / 0,1), que dejaba la M a 0,99999 tras 6 cortes.

## Criterios de aceptación
- **AC1** Given un jugador con pulpo cocido (100 unidades) y una caja vacía de tipo T en un pasaplatos, When pulsa interactuar una vez, Then la caja pasa a `fill_after(1)` = 1 / `presses_to_fill(T)` (25 % S, 16,7 % M, 10 % L) y el pulpo pierde 50 / `presses_to_fill(T)` unidades. *Test:* `test_box.gd`.
- **AC2 (R9)** Given una caja vacía S/M/L y pulpo cocido de 100 unidades, When se pulsa N veces (N = `presses_to_fill` en `data/boxes/*.tres`: 4 S, 6 M, 10 L), Then la caja está llena (100 %), conserva el ingrediente `Octopus`, el pulpo en mano tiene 50 unidades y se emite `box_filled` una vez; con N − 1 pulsaciones la caja aún no está llena. *Test:* `test_box.gd` + `test_data_boxes.gd`.
- **AC3** Given una caja llena, When se pulsa interactuar con pulpo cocido, Then no cambia ni la caja ni el pulpo. *Test:* `test_box.gd`.
- **AC4** Given un pulpo de 100 unidades, When se llenan 2 cajas del mismo tipo (2N pulsaciones), Then el pulpo llega a 0 (resto ≤ `Ingredient.EMPTY_EPSILON`), se retira de la mano y no queda objeto fantasma. *Test:* `test_box.gd`.
- **AC5** Given que no existe estación de corte en la escena del nivel, When se carga, Then no hay ningún nodo del grupo `cut_station` ni `Tray`. *Test:* `test_level_01.gd`.
- **AC6** Given pulpo crudo (no cocido) en la mano, When se pulsa interactuar sobre la caja, Then no se corta (la caja no cambia). *Test:* `test_box.gd`.
- **AC7** Given una caja vacía en un pasaplatos de la barra, When el cocinero la corta desde el lado de cocina y el emplatador la recoge desde el de servicio, Then los dos lo consiguen sin rodear la barra (el pasaplatos se alcanza desde las dos caras). *Test:* `test_box_on_slot.gd` / `test_station_level.gd`.

## Datos (`.tres`)
`presses_to_fill: int` **por tipo de caja** en `data/boxes/{small,medium,large}.tres` (4 / 6 / 10;
PUL-104, sustituye a `fill_per_press`) y, en `data/ingredients/octopus.tres`, `total_capacity` (100)
y `amount_per_full_box` (50 por caja). Nuevo en `BoxData` (B-A):
`short_label` («S»/«M»/«L») e `icon` (silueta), que comparten ticket, rack y caja (ver
`comandas.md` AC9).

## Verificación
GUT para AC1–AC4, AC6 y AC7 (lógica de caja e ingrediente; AC7 en integración); AC5 por test de
escena.

## Preguntas abiertas
1. **Precio de la L.** Con 10 cortes, ¿baja `base_points` de 12 a 11? Lo decide el playtest de la
   ficha de QA (PUL-090 §4.4, ficha 7) con las medidas de R17 (`entrega-y-puntuacion.md`).
