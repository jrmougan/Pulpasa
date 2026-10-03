# Comandas y tickets (Must)

**Slug:** comandas · **Prototipo:** `OrderSystem`, `OrderSO`, `RecipeSO`, `ActiveOrder`, `OrderTicketSpawner`, `OrderTicket`.

## Descripción
El sistema genera comandas a partir de plantillas (`OrderSO`): pulpo + condimentos + tiempo máximo.
Cada comanda activa se muestra como ticket con iconos y barra de tiempo.

## Criterios de aceptación
- **AC1** Given una partida iniciada, When pasan 5 s (`first_order_delay`, dato), Then existe al menos 1 comanda activa y se emitió `order_generated`.
- **AC2** Given 4 comandas activas (`max_active_orders`, dato), When se pide otra, Then no se genera (el máximo se respeta, sin acumular en cola).
- **AC3** Given una comanda con `max_time` = 60 s, When pasan 60 s sin entregar, Then se elimina, se emite `order_expired` una vez, baja la recaudación en la penalización (ver `entrega-y-puntuacion.md`) y se pide otra comanda para ese puesto en el mismo frame (reposición inmediata, ver AC7).
- **AC4** Given una comanda generada, Then su ticket muestra los iconos de cada condimento pedido y una barra de tiempo que decrece linealmente de 100 % a 0 % en `max_time`.
- **AC5** Given el catálogo de la alpha, Then hay ≥ 4 plantillas distintas de comanda (p. ej. solo pulpo, pulpo+sal+aceite, pulpo+pimentón picante+cachelos, pulpo completo).
- **AC7** Given una entrega válida en el puesto N, When se emite `order_completed`, Then en ≤ 1 s (mismo frame esperado) el puesto N tiene una comanda nueva, si está activo en la fase actual.
- **AC8** Given 20 entregas válidas seguidas, Then ningún puesto activo queda vacío tras cada entrega y cada una suma exactamente +1 al contador de comandas completadas (nunca +0 ni +2).
- **AC6** Given la partida terminada, When se reinicia, Then no quedan comandas activas (fallo del prototipo no portado: reset por búsqueda de nodos).

## Datos (`.tres`)
Plantillas de comanda, `max_active_orders` (4), `first_order_delay` (5 s), `max_time` por plantilla (40–90 s).

## Verificación
GUT con reloj simulado para AC1–AC3, AC5–AC8; captura del ticket para AC4.
