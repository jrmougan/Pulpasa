# Entrega, validación y puntuación (Must, D2)

**Slug:** entrega-y-puntuacion · **Prototipo:** `OrderStand`, `OrderSystem.ValidateBox`, `RecipeSO.basePoints`, `GameOverUI`.

## Descripción
La caja se entrega en un puesto. Se valida contra las comandas del puesto. La métrica es
**recaudación (€) + estrellas 0–3** (no cajas/minuto). Puntos por comanda =
`base_points` + `time_bonus` − penalización por caducada.

## Reglas
- `time_bonus` = `floor(tiempo_restante / max_time × time_bonus_max)`, con `time_bonus_max` = 5 €.
- Penalización por comanda caducada = `expire_penalty` = 3 €. La recaudación no baja de 0.
- Estrellas (provisional, pregunta abierta nº 1): 1★ ≥ 30 €, 2★ ≥ 60 €, 3★ ≥ 90 €.

## Criterios de aceptación
- **AC1** Given una comanda de pulpo+sal+aceite y una caja llena de pulpo con sal+aceite, When se entrega en su puesto, Then la validación es verdadera, se emite `order_completed` una vez y la comanda desaparece.
- **AC2** Given la misma comanda y una caja sin aceite, When se entrega, Then la validación es falsa, `order_completed` no se emite y la comanda sigue activa.
- **AC3** Given una caja con un condimento extra no pedido, When se entrega, Then es inválida (coincidencia exacta).
- **AC4** Given una receta con `base_points` = 10 y `max_time` = 60 s, When se entrega con 30 s restantes, Then se ingresan 10 + floor(0,5 × 5) = 12 €.
- **AC5** Given una receta con `base_points` = 10 y `max_time` = 60 s, When se entrega con 1 s restante, Then se ingresan 10 € (bonus floor(1/60 × 5) = 0).
- **AC5b** Given una comanda con `max_time` = 60 s, When la entrega llega con tiempo restante ≤ 0 (a los 60,0 s o después), Then se rechaza sin ingreso: la caducidad gana en el empate y la comanda ya se eliminó con `order_expired`.
- **AC5c** Given una comanda con 0,1 s restantes, When se entrega una caja válida antes de caducar, Then se ingresa `base_points` + 0 y no se emite `order_expired`.
- **AC6** Given una recaudación de 59 €, 60 € y 90 €, When acaba la partida, Then las estrellas son 1, 2 y 3 respectivamente; con 29 € son 0.
- **AC7** Given una comanda caducada con recaudación de 2 €, Then la recaudación queda en 0 € (no negativa).
- **AC9** Given una partida recién iniciada, Then el HUD muestra recaudación 0 €.
- **AC10** Given el HUD, When se completa una entrega por 12 €, Then el HUD muestra la recaudación anterior + 12 € en ≤ 0,2 s.
- **AC11** Given el HUD, When una comanda caduca con recaudación 20 €, Then el HUD pasa a 17 € en ≤ 0,2 s (nunca por debajo de 0).
- **AC12** Given 2 jugadores (Local 2P), When cada uno entrega una caja, Then un único contador compartido suma ambas.
- **AC13** Given una caja errónea entregada, Then se conserva sin penalización y la recaudación no cambia (regla de paridad, GDD §9).
- **AC8** Given dos comandas iguales en puestos distintos, When se entrega la caja en el puesto A, Then solo se completa la comanda del puesto A.

## Datos (`.tres`)
`base_points` por receta (8–14 €), `time_bonus_max`, `expire_penalty`, umbrales de estrellas.

## Verificación
GUT para AC1–AC8 y AC13 (lógica pura); AC9–AC12 con UI instanciada y reloj simulado o captura del HUD.
