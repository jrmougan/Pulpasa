# Entrega, validación y puntuación (Must, D2, D8, D12, D23, D24)

**Slug:** entrega-y-puntuacion · **Prototipo:** `OrderStand`, `OrderSystem.ValidateBox`, `RecipeSO.basePoints`, `GameOverUI`.

## Descripción
La caja se entrega en un puesto. Se valida contra las comandas del puesto. La métrica es
**recaudación (€) + estrellas 0–3** (no cajas/minuto). Puntos por comanda =
`base_points` + `time_bonus` − penalización por caducada.

### Entrega con la caja en la mano (D23, E-A)
La caja llena y condimentada se lleva en la mano desde la línea de condimentos hasta el puesto
(≈ 4–5 m). Cada puesto tiene **número y color de toldo** (rojo, azul, amarillo, verde para 1–4) que
casan con la franja del ticket (`comandas.md` AC10). Delante de cada puesto hay una **zona de
entrega pintada en el suelo** (`DeliveryZone`):
- si el portador lleva una caja que **coincide** con la comanda viva del puesto, la zona **se
  ilumina** y, al entrar, entrega sola (regla de PUL-039, sin pulsar);
- si no coincide, la zona **se queda apagada**: el jugador sabe antes de pulsar que no va a entregar.
  Pulsar interactuar en el puesto con esa caja es una entrega errónea (D8, −2 €).

```
   Ticket #2 franja AZUL            Puesto 2, toldo AZUL
   ┌─[azul]────────────┐              ╔═══════╗
   │ #2 (M) Pulpo Doble│              ║  #2   ║   ← placa clara detrás del número
   └───────────────────┘           ···║·······║···  ← zona en el suelo: encendida solo si
                                        ↑              la caja de la mano coincide
                                   J1 con la caja
```

> **Sustituido por D23:** la zona de entrega «muda» (sin señal hasta pulsar) y el puesto que solo
> se distinguía por el número.

## Reglas
- `time_bonus` = `floor(tiempo_restante / max_time × time_bonus_max)`, con `time_bonus_max` = 5 €.
- Penalización por comanda caducada = `expire_penalty` = 3 €; por caja errónea entregada = `wrong_delivery_penalty` = 2 € (D8). La recaudación no baja de 0.
- Entregar en un puesto sin comanda, con la comanda ya caducada o cuya comanda **caduca en ese mismo tick** se rechaza **sin penalizar** (0; D24, 2026-10-10, `OrderBoard.try_deliver`). La comanda caducada solo cobra `expire_penalty`, no además `wrong_delivery_penalty`.
- Estrellas (provisional, pregunta abierta nº 1): 1★ ≥ 30 €, 2★ ≥ 60 €, 3★ ≥ 90 €.

## Criterios de aceptación
- **AC1** Given una comanda de pulpo+sal+aceite y una caja llena de pulpo con sal+aceite, When se entrega en su puesto, Then la validación es verdadera, se emite `order_completed` una vez y la comanda desaparece.
- **AC2** Given la misma comanda y una caja sin aceite, When se entrega, Then la validación es falsa, `order_completed` no se emite y la comanda sigue activa.
- **AC3** Given una caja con un condimento extra no pedido, When se entrega, Then es inválida (coincidencia exacta).
- **AC4** Given una receta con `base_points` = 10 y `max_time` = 60 s, When se entrega con 30 s restantes, Then se ingresan 10 + floor(0,5 × 5) = 12 €.
- **AC5** Given una receta con `base_points` = 10 y `max_time` = 60 s, When se entrega con 1 s restante, Then se ingresan 10 € (bonus floor(1/60 × 5) = 0).
- **AC5b** Given una comanda con `max_time` = 60 s, When la entrega llega con tiempo restante ≤ 0 (a los 60,0 s o después), Then se rechaza sin ingreso: la caducidad gana en el empate y la comanda ya se eliminó con `order_expired`.
- **AC5d (D24)** Given una comanda que caduca en el tick T y una entrega en el mismo tick T (válida o errónea), When se procesa, Then se emite `delivery_rejected(slot, id_de_la_caducada, 0)` aunque el puesto ya tenga la comanda repuesta, la recaudación solo baja por `expire_penalty` (3 €), no se emite `order_completed` y la caja sigue en la mano. *Test:* `test_order_board.gd` (`test_ac5b_delivery_on_expiry_tick_rejected_not_redirected`) y `test_order_stand.gd` (`_assert_expiry_tick`), ambos con caja válida; y `test_order_board.gd` (`test_ac5d_wrong_box_on_expiry_tick_rejected_with_zero_penalty`) con caja errónea (penalización 0, no `wrong_delivery_penalty`) y control en T+1 que sí penaliza contra la repuesta.
- **AC5c** Given una comanda con 0,1 s restantes, When se entrega una caja válida antes de caducar, Then se ingresa `base_points` + 0 y no se emite `order_expired`.
- **AC6** Given una recaudación de 59 €, 60 € y 90 €, When acaba la partida, Then las estrellas son 1, 2 y 3 respectivamente; con 29 € son 0.
- **AC7** Given una comanda caducada con recaudación de 2 €, Then la recaudación queda en 0 € (no negativa).
- **AC9** Given una partida recién iniciada, Then el HUD muestra recaudación 0 €.
- **AC10** Given el HUD, When se completa una entrega por 12 €, Then el HUD muestra la recaudación anterior + 12 € en ≤ 0,2 s.
- **AC11** Given el HUD, When una comanda caduca con recaudación 20 €, Then el HUD pasa a 17 € en ≤ 0,2 s (nunca por debajo de 0).
- **AC12** Given 2 jugadores (Local 2P), When cada uno entrega una caja, Then un único contador compartido suma ambas.
- **AC13** Given una recaudación de 10 € y una caja errónea (contenido o tamaño que no coincide), When se pulsa interactuar en el puesto, Then la entrega se rechaza (`delivery_rejected`), la recaudación pasa a 8 € (`wrong_delivery_penalty` = 2, D8; nunca por debajo de 0), la caja sigue en la mano y la comanda sigue activa. *Corregido en PUL-092: la versión anterior («sin penalización», paridad de M0) contradecía D8.*
- **AC8** Given dos comandas iguales en puestos distintos, When se entrega la caja en el puesto A, Then solo se completa la comanda del puesto A.
- **AC14 (R12)** Given el puesto 2 con una comanda viva y J1 con una caja que coincide, When J1 está a ≤ 2,0 m de la zona del puesto, Then la zona del suelo se ilumina en ≤ 0,1 s; Given una caja que no coincide (otro condimento u otro tamaño), Then se queda apagada; Given la mano vacía o el puesto sin comanda, Then apagada. *Test:* `test_order_stand.gd` (estado de resaltado) + captura.
- **AC15** Given J1 con una caja que coincide entrando en la zona encendida del puesto 2, Then se emite `order_completed` una vez sin pulsar; Given una caja que no coincide entrando en la zona, Then no se emite nada ni se penaliza (solo pulsar penaliza, AC13). *Test:* `test_order_stand.gd`.
- **AC16 (R13)** Given los 4 puestos, Then el toldo del puesto N usa `mat_canvas_stand_N` (1 rojo `#D2473F`, 2 azul `#3F7CC8`, 3 amarillo `#E8C23A`, 4 verde `#4FA05A`) y el mismo color que la franja de su ticket (`comandas.md` AC10). *Test:* `test_order_stand_model.gd` + captura.

## Datos (`.tres`)
`base_points` por receta (8–14 €), `time_bonus_max`, `expire_penalty`, `wrong_delivery_penalty`, umbrales de estrellas. Color por `slot_id` en un dato de nivel (compartido con el ticket). Distancia de iluminación de la zona (2,0 m) en datos del puesto.

## Verificación
GUT para AC1–AC8 y AC13 (lógica pura); AC9–AC12 con UI instanciada y reloj simulado o captura del HUD;
AC14–AC16 con el puesto instanciado y captura en `docs/evidence/<ficha>/`.

## Preguntas abiertas
1. **Estrellas** (provisional): umbrales 30/60/90 €.
2. **Precio de la L** (PUL-090 §7.1). Con el corte de la L a 10 pulsaciones (`corte-pulpo.md`),
   ¿baja `base_points` de 12 a 11? Lo decide el playtest de la ficha de QA con las medidas de R17
   (`level-layouts.md`); hasta entonces no cambia.
