# Comandas y tickets (Must, D12, D23, D25)

**Slug:** comandas · **Prototipo:** `OrderSystem`, `OrderSO`, `RecipeSO`, `ActiveOrder`, `OrderTicketSpawner`, `OrderTicket`.

## Descripción
El sistema genera comandas a partir de plantillas (`OrderSO`): pulpo + aliño + cachelos sí/no +
tiempo máximo. Cada comanda activa se muestra como ticket con iconos y barra de tiempo.

Desde D23 el ticket dice además **a qué puesto** va: una **franja del color del toldo** de su
puesto, además del número (E-A de `rediseno-estaciones.md`). Desde D25 **no hay tamaños de caja**: el
ticket muestra el **nombre corto de la receta** y la fila de iconos de lo que pide (1 de aliño +
cachelos si los lleva), en el mismo orden que las pegatinas de la caja.

```
  ┌─[franja azul = toldo del puesto 2]─┐
  │ #2  Bravo cachelos                 │   ← nombre corto de la receta (≤ 14 caracteres)
  │ (PIC)(CAC)                         │   ← aliño → cachelos (estacion-condimentos.md)
  │ ███████░░░░░░░  01:12              │
  └────────────────────────────────────┘
```

> **Sustituido por D25:** el ticket con silueta y letra S/M/L (D23) y las recetas «Pulpo
> Individual/Doble/Familiar». El tamaño equivocado ya no existe como causa de caja errónea (D8).

### Recetas (D25)
Cuatro recetas por contenido (dulce/picante × con/sin cachelos). Nombres ≤ 14 caracteres para que
quepan en el ticket de 212 px sin recortarse; precios (`base_points`) crecientes con el esfuerzo
(con cachelos paga más: olla + cuenco). Todos los valores van a datos y son **provisionales** (QA los re-mide).

| Receta (nombre del ticket) | Aliño | Cachelos | `base_points` | `max_time` | Fase en que aparece |
|---|---|---|---:|---:|---|
| Á feira | dulce | no | 8 € | 60 s | 1 |
| Picante | picante | no | 9 € | 60 s | 2 |
| Con cachelos | dulce | sí | 12 € | 80 s | 3 |
| Bravo cachelos | picante | sí | 13 € | 80 s | 3 |

«Á feira» es el pulpo á feira clásico (aliño dulce); «Bravo» alude al pimentón picante, como en las
patatas bravas. «Con cachelos» y «Bravo cachelos» miden 12 y 14 caracteres.

## Criterios de aceptación
- **AC1** Given una partida iniciada, When pasan 5 s (`first_order_delay`, dato), Then existe al menos 1 comanda activa y se emitió `order_generated`.
- **AC2** Given 4 comandas activas (`max_active_orders`, dato), When se pide otra, Then no se genera (el máximo se respeta, sin acumular en cola).
- **AC3** Given una comanda con `max_time` = 60 s, When pasan 60 s sin entregar, Then se elimina, se emite `order_expired` una vez, baja la recaudación en la penalización (ver `entrega-y-puntuacion.md`) y se pide otra comanda para ese puesto en el mismo frame (reposición inmediata, ver AC7).
- **AC4** Given una comanda generada, Then su ticket muestra los iconos de cada elemento pedido (1 de aliño, y cachelos si los lleva) y una barra de tiempo que decrece linealmente de 100 % a 0 % en `max_time`.
- **AC5** *(reescrito por D25)* Given el catálogo de la alpha, Then hay exactamente **4** plantillas de comanda, con los nombres, aliños, cachelos y precios de la tabla de recetas, leídas de `.tres`. *Test:* `test_order_catalog.gd`.
- **AC6** Given la partida terminada, When se reinicia, Then no quedan comandas activas (fallo del prototipo no portado: reset por búsqueda de nodos).
- **AC7** Given una entrega válida en el puesto N, When se emite `order_completed`, Then en ≤ 1 s (mismo frame esperado) el puesto N tiene una comanda nueva, si está activo en la fase actual.
- **AC8** Given 20 entregas válidas seguidas, Then ningún puesto activo queda vacío tras cada entrega y cada una suma exactamente +1 al contador de comandas completadas (nunca +0 ni +2).
- **AC9** *(superado por D25: sin tamaños; sustituye a R10)* Given cualquier ticket, Then no muestra silueta ni letra de talla y `BoxData` no tiene `short_label` ni `icon`. *Test:* `test_order_tickets.gd`.
- **AC10 (R13)** Given 4 comandas vivas en los puestos 1–4, Then la franja de color de cada ticket es la del toldo de su puesto (`slot_id` 1–4 → rojo, azul, amarillo, verde, los de `mat_canvas_stand_1..4`), leída de un dato de nivel, y el número del ticket coincide con el del puesto. *Test:* `test_order_tickets.gd` + captura a 1280×720.
- **AC11 (D25)** Given las 4 recetas, Then el nombre más largo mide ≤ 14 caracteres y ningún ticket recorta el nombre (sin «…») a 212 px de ancho de ticket, a 1280×720 y 1920×1080. *Test:* `test_order_tickets.gd` + captura.
- **AC12 (D25)** Given la tabla de recetas, Then el precio es no decreciente con el esfuerzo: cada receta con cachelos paga estrictamente más que su equivalente sin cachelos (12 > 8 y 13 > 9) y `base_points` está entre 8 y 14. *Test:* `test_order_catalog.gd`.
- **AC14 (D26, iconos distinguibles)** Given los tickets de «Á feira» y «Picante», Then el icono de aliño del dulce (pimentonera) y el del picante (guindilla con llama) tienen siluetas distintas (IoU ≤ 0,6 en gris a 48 px) y son los mismos que en el dispensador y en la pegatina de la caja, de modo que la receta se distingue sin leer el nombre ni depender del color. *Test:* `test_icons_silhouettes.gd` + `test_order_tickets.gd`.
- **AC15 (D26, ticket en móvil)** Given el perfil táctil con 4 comandas, Then el ticket mide entre 330 y 380 px de ancho y 150 px de alto a 1080 de alto, el nombre se lee a ≥ 36 px sin recortar, los iconos miden ≥ 48 px y la barra de paciencia ≥ 12 px de grosor (`controles-tactiles.md` AC14 y AC15). *Test:* `test_touch_hud_layout.gd`.
- **AC13 (D25)** Given la fase 1, When se generan 20 comandas, Then todas son «Á feira»; en fase 2, solo «Á feira» y «Picante»; en fase 3, las 4 (ver `dificultad-progresiva.md`). *Test:* `test_order_catalog.gd` con semilla fija.

## Datos (`.tres`)
Una `RecipeData` (nombre ≤ 14 caracteres, `base_points`) y una `OrderData` (aliño `sweet_dressing`/`hot_dressing`, cachelos, `max_time`) por receta (4, listadas en el catálogo de comandas), `max_active_orders`
(4), `first_order_delay` (5 s) y el color por `slot_id` en un dato de nivel (lo leen ticket y puesto;
no en código). Comandas permitidas por fase en `PhaseData.orders` (`dificultad-progresiva.md`).

## Verificación
GUT con reloj simulado para AC1–AC3, AC5–AC8, AC12 y AC13; captura del ticket para AC4, AC10 y AC11.

## Preguntas abiertas
1. **Precios y paciencias** de las 4 recetas: provisionales (D25); se re-miden con QA. Los umbrales
   de estrellas (30/60/90 €) pueden necesitar ajuste porque la comanda media baja de ~10 € a ~8–13 €.
2. **Fase 1 con una sola receta.** Todas las comandas iniciales son «Á feira» (por diseño, para
   enseñar); si el playtest la nota monótona se puede añadir variación de paciencia, no de receta.
