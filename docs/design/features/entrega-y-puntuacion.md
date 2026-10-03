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
- **AC5** Given una receta con `base_points` = 10, When se entrega con 0 s restantes, Then se ingresan 10 €.
- **AC6** Given una recaudación de 59 €, 60 € y 90 €, When acaba la partida, Then las estrellas son 1, 2 y 3 respectivamente; con 29 € son 0.
- **AC7** Given una comanda caducada con recaudación de 2 €, Then la recaudación queda en 0 € (no negativa).
- **AC8** Given dos comandas iguales en puestos distintos, When se entrega la caja en el puesto A, Then solo se completa la comanda del puesto A.

## Datos (`.tres`)
`base_points` por receta (8–14 €), `time_bonus_max`, `expire_penalty`, umbrales de estrellas.

## Verificación
GUT para AC1–AC8 (lógica pura; sin escena).
