# Comandas y tickets (Must, D12, D23)

**Slug:** comandas · **Prototipo:** `OrderSystem`, `OrderSO`, `RecipeSO`, `ActiveOrder`, `OrderTicketSpawner`, `OrderTicket`.

## Descripción
El sistema genera comandas a partir de plantillas (`OrderSO`): pulpo + condimentos + tiempo máximo.
Cada comanda activa se muestra como ticket con iconos y barra de tiempo.

Desde D23 (B-A y E-A de `rediseno-estaciones.md`) el ticket dice además **qué caja** y **a qué
puesto**: muestra el tamaño **S/M/L** con la misma silueta y letra que el rack y la caja, antes del
nombre de la receta, y una **franja del color del toldo** de su puesto, además del número. Así se
eligen bien la caja (E6 de PUL-090: tamaño equivocado = caja errónea, −2 €, D8) y el puesto (D12).

```
  ┌─[franja azul = toldo del puesto 2]─┐
  │ #2  (M) Pulpo Doble                │   ← silueta + letra de BoxData, antes del nombre
  │ (PIC)(SAL)(ACE)                    │   ← orden canónico (estacion-condimentos.md)
  │ ███████░░░░░░░  01:12              │
  └────────────────────────────────────┘
```

> **Sustituido por D23:** el ticket que solo decía «Pulpo Individual/Doble/Familiar» sin tamaño.

## Criterios de aceptación
- **AC1** Given una partida iniciada, When pasan 5 s (`first_order_delay`, dato), Then existe al menos 1 comanda activa y se emitió `order_generated`.
- **AC2** Given 4 comandas activas (`max_active_orders`, dato), When se pide otra, Then no se genera (el máximo se respeta, sin acumular en cola).
- **AC3** Given una comanda con `max_time` = 60 s, When pasan 60 s sin entregar, Then se elimina, se emite `order_expired` una vez, baja la recaudación en la penalización (ver `entrega-y-puntuacion.md`) y se pide otra comanda para ese puesto en el mismo frame (reposición inmediata, ver AC7).
- **AC4** Given una comanda generada, Then su ticket muestra los iconos de cada condimento pedido y una barra de tiempo que decrece linealmente de 100 % a 0 % en `max_time`.
- **AC5** Given el catálogo de la alpha, Then hay ≥ 4 plantillas distintas de comanda (p. ej. solo pulpo, pulpo+sal+aceite, pulpo+pimentón picante+cachelos, pulpo completo).
- **AC7** Given una entrega válida en el puesto N, When se emite `order_completed`, Then en ≤ 1 s (mismo frame esperado) el puesto N tiene una comanda nueva, si está activo en la fase actual.
- **AC8** Given 20 entregas válidas seguidas, Then ningún puesto activo queda vacío tras cada entrega y cada una suma exactamente +1 al contador de comandas completadas (nunca +0 ni +2).
- **AC9 (R10)** Given una comanda de caja M, Then su ticket muestra la silueta y la letra «M» del mismo recurso que el rack (`BoxData.icon`/`short_label`, nuevo) antes del nombre de la receta; igual con S y L. *Test:* `test_order_tickets.gd` + captura.
- **AC10 (R13)** Given 4 comandas vivas en los puestos 1–4, Then la franja de color de cada ticket es la del toldo de su puesto (`slot_id` 1–4 → rojo, azul, amarillo, verde, los de `mat_canvas_stand_1..4`), leída de un dato de nivel, y el número del ticket coincide con el del puesto. *Test:* `test_order_tickets.gd` + captura a 1280×720.
- **AC6** Given la partida terminada, When se reinicia, Then no quedan comandas activas (fallo del prototipo no portado: reset por búsqueda de nodos).

## Datos (`.tres`)
Plantillas de comanda, `max_active_orders` (4), `first_order_delay` (5 s), `max_time` por plantilla (40–90 s).
Nuevo con D23: `BoxData.short_label` e `icon` (`data/boxes/*.tres`) y el color por `slot_id` en un
dato de nivel (lo leen ticket y puesto; no en código).

## Verificación
GUT con reloj simulado para AC1–AC3, AC5–AC8; captura del ticket para AC4, AC9 y AC10.
