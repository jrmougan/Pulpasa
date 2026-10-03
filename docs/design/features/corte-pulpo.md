# Corte del pulpo sobre la caja (Must, D1)

**Slug:** corte-pulpo · **Prototipo:** `Box`, `Ingredient`, `OctopusSwapner`.

## Descripción
No hay estación de corte. El jugador con una caja (que contiene pulpo crudo) mantiene la acción de
cortar y el pulpo pasa a estado *cortado* tras `cut_time`. El pulpo debe estar cortado antes de cocerse.

## Criterios de aceptación
- **AC1** Given una caja con pulpo crudo en la mano, When el jugador mantiene «cortar» 2,0 s
  (`cut_time`, dato), Then el pulpo pasa a `CUT`, se emite `ingredient_cut` una vez y la barra de progreso llega al 100 %.
- **AC2** Given un corte al 50 %, When el jugador suelta «cortar», Then el progreso se conserva
  (no se reinicia) y no se emite `ingredient_cut`.
- **AC3** Given una caja vacía o con pulpo ya cortado, When se pulsa «cortar», Then no hay barra ni cambio de estado.
- **AC4** Given que no existe estación de corte en la escena del nivel, When se carga el nivel,
  Then el árbol no contiene ningún nodo de grupo `cut_station`.
- **AC5** Given un pulpo crudo (sin cortar), When se intenta meter en el caldero, Then se rechaza (ver `coccion-pulpo.md`).

## Datos (`.tres`)
`cut_time` (2,0 s).

## Verificación
GUT para AC1–AC3 y AC5 (máquina de estados del ingrediente); AC4 por test de escena.
