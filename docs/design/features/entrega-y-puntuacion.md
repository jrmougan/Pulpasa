# Entrega, validación y puntuación (Must, D2, D8, D12, D23, D24, D25, D26)

> **Modificada por D26 (2026-10-11):** entrega solo automática por zona iluminada; el puesto no es
> objetivo; la caja errónea no penaliza (modifica D8). Los AC que describen la entrega *por pulsación*
> (AC13, parte de AC5d) se conservan tachados o con nota. El núcleo `OrderBoard.try_deliver` (validación,
> D24) no cambia.

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
- si no coincide, la zona **se queda apagada**: el jugador sabe que no va a entregar.
  ~~Pulsar interactuar en el puesto con esa caja es una entrega errónea (D8, −2 €).~~ *(Superado por
  D26: la entrega es **solo automática por zona iluminada**. El puesto **deja de ser objetivo** de la
  pulsación: no se resalta ni muestra prompt. Una caja que no encaja no enciende la zona, no entrega
  y **no penaliza**; se tira o se rehace.)* Con la caja en la mano y sin objetivo, pulsar suelta
  al suelo como siempre (SOLTAR, `lenguaje-acciones.md`).

```
   Ticket #2 franja AZUL            Puesto 2, toldo AZUL
   ┌─[azul]────────────┐              ╔═══════╗
   │ #2 Bravo cachelos │              ║  #2   ║   ← placa clara detrás del número
   └───────────────────┘           ···║·······║···  ← zona en el suelo: encendida solo si
                                        ↑              la caja de la mano coincide
                                   J1 con la caja
```

> **Sustituido por D23:** la zona de entrega «muda» (sin señal hasta pulsar) y el puesto que solo
> se distinguía por el número.

## Reglas
- `time_bonus` = `floor(tiempo_restante / max_time × time_bonus_max)`, con `time_bonus_max` = 5 €.
- Penalización por comanda caducada = `expire_penalty` = 3 €; ~~por caja errónea entregada = `wrong_delivery_penalty` = 2 € (D8)~~ *(superado por D26: no existe entrega por pulsación, la caja errónea no se puede entregar y no penaliza; `wrong_delivery_penalty` pasa a 0 en `round_config.tres` y deja de usarse)*. La recaudación no baja de 0.
- Entregar en un puesto sin comanda, con la comanda ya caducada o cuya comanda **caduca en ese mismo tick** se rechaza **sin penalizar** (0; D24, 2026-10-10, `OrderBoard.try_deliver`). La comanda caducada solo cobra `expire_penalty`, no además `wrong_delivery_penalty`.
- Estrellas (provisional, pregunta abierta nº 1): 1★ ≥ 30 €, 2★ ≥ 60 €, 3★ ≥ 90 €.

## Criterios de aceptación
- **AC1** *(reescrito por D25)* Given una comanda «Á feira» (aliño dulce, sin cachelos) y una caja llena de pulpo con aliño dulce, When se entrega en su puesto, Then la validación es verdadera, se emite `order_completed` una vez y la comanda desaparece.
- **AC2** *(reescrito por D25)* Given la misma comanda y una caja llena sin aliño (o con aliño picante), When se entrega, Then la validación es falsa, `order_completed` no se emite y la comanda sigue activa.
- **AC3** *(reescrito por D25)* Given una caja con un elemento extra no pedido (cachelos en una caja para «Á feira»), When se entrega, Then es inválida (coincidencia exacta de aliño y cachelos).
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
- ~~**AC13** Given una recaudación de 10 € y una caja errónea, When se pulsa interactuar en el puesto, Then la entrega se rechaza (`delivery_rejected`), la recaudación pasa a 8 € (`wrong_delivery_penalty` = 2, D8), la caja sigue en la mano y la comanda sigue activa.~~ **Superado por D26.** Sustituido por AC13' y AC17.
- **AC13' (D26)** Given una recaudación de 10 € y una caja errónea (aliño o cachelos que no coinciden) en la mano de un jugador que entra en la zona del puesto, Then la zona no se enciende, no se emite `delivery_rejected` ni `order_completed`, la recaudación sigue en 10 € (sin penalización), la caja sigue en la mano y la comanda sigue activa. Given el dato `wrong_delivery_penalty`, Then vale 0. *Test:* `test_order_stand.gd` + test de datos.
- **AC8** Given dos comandas iguales en puestos distintos, When se entrega la caja en el puesto A, Then solo se completa la comanda del puesto A.
- **AC14 (R12)** Given el puesto 2 con una comanda viva y J1 con una caja que coincide, When J1 está a ≤ 2,0 m de la zona del puesto, Then la zona del suelo se ilumina en ≤ 0,1 s; Given una caja que no coincide (otro aliño o cachelos de más o de menos), Then se queda apagada; Given la mano vacía o el puesto sin comanda, Then apagada. *Test:* `test_order_stand.gd` (estado de resaltado) + captura.
- **AC15** Given J1 con una caja que coincide entrando en la zona encendida del puesto 2, Then se emite `order_completed` una vez sin pulsar; Given una caja que no coincide entrando en la zona, Then no se emite nada ni se penaliza (~~solo pulsar penaliza, AC13~~: desde D26 nada penaliza, AC13'). *Test:* `test_order_stand.gd`.
- **AC16 (R13)** Given los 4 puestos, Then el toldo del puesto N usa `mat_canvas_stand_N` (1 rojo `#D2473F`, 2 azul `#3F7CC8`, 3 amarillo `#E8C23A`, 4 verde `#4FA05A`) y el mismo color que la franja de su ticket (`comandas.md` AC10). *Test:* `test_order_stand_model.gd` + captura.

- **AC17 (D26, el puesto no es objetivo)** Given un jugador a ≤ 1,5 m de un puesto con cualquier mano (M0…M9 de `lenguaje-acciones.md`), Then el puesto no se resalta ni muestra prompt y no se publica como objetivo; pulsar con la mano llena suelta al suelo (SOLTAR) y con la mano vacía no hace nada. La entrega ocurre solo al entrar con una caja que coincide en la zona iluminada, con la respuesta de entrega correcta (sonido y efecto ≥ 0,3 s, `audio-y-fx.md`). *Test:* `test_order_stand.gd` + `test_action_matrix.gd` (fila A7).
- **AC18 (D26, HUD)** Given el HUD en cualquier perfil, Then muestra recaudación y tiempo (y la fase, si la muestra) y **ningún texto ni clave de traducción contiene «Cajas / minuto»** (métrica heredada del prototipo; D2). En el perfil táctil, su maquetación es la de `controles-tactiles.md` (bloque de 240 × 150 px arriba a la izquierda). *Test:* `test_hud.gd`.

## Datos (`.tres`)
`wrong_delivery_penalty` pasa a 0 (D26) y queda sin uso hasta que se retire en una limpieza de datos.
`base_points` por receta (8 / 9 / 12 / 13 €, tabla de `comandas.md`), `time_bonus_max`, `expire_penalty`, `wrong_delivery_penalty`, umbrales de estrellas. Color por `slot_id` en un dato de nivel (compartido con el ticket). Distancia de iluminación de la zona (2,0 m) en datos del puesto.

## Verificación
GUT para AC1–AC8 y AC13 (lógica pura); AC9–AC12 con UI instanciada y reloj simulado o captura del HUD;
AC14–AC16 con el puesto instanciado y captura en `docs/evidence/<ficha>/`.

## Preguntas abiertas
1. **Estrellas** (provisional): umbrales 30/60/90 €.
2. ~~Precio de la L~~ Superada por D25 (sin tamaños). Los precios de las 4 recetas (`comandas.md`) son
   provisionales y se re-miden en QA junto con los umbrales de estrellas.
3. **Entrega tras el cubo.** Sin cambios de reglas: tirar una caja no penaliza (`trash_penalty` = 0,
   `cubo-basura.md`) y la comanda del puesto sigue viva hasta que caduca.
