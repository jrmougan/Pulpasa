# Línea de condimentos «al paso» y distintivos de la caja (Must, D18 modificada por D23)

**Slug:** estacion-condimentos · **Prototipo:** ninguno (sustituye a `SpiceShelf` y los botes,
`SeasoningItem`). **Reglas de condimento:** `condimentacion.md` (D4, sí/no). **Rediseño:**
`docs/design/rediseno-estaciones.md` (PUL-090), paquete C-B + B-A + E-A + N-A + cachelos ×2,
aprobado el 2026-10-07 (D23). **Arte:** `docs/art/rediseno-estaciones-arte.md` (PUL-091,
dirección A · Señalética de pase).

> **Sustituido por D23.** La versión de D18 (2026-10-05) dejaba la caja en una **bandeja** (`Tray`)
> de la estación y la caja «atravesaba» el mostrador. Desde D23 **no hay bandeja**: la caja llena
> se lleva **en la mano** y se pulsa cada dispensador al pasar. Siguen de D18: la estación en la barra
> que separa cocina y servicio, los dos lados (dispensadores solo desde el de condimentar),
> el alternar, `paprika_swap`, el antirrebote y las pegatinas en el orden del ticket.

## Descripción
Los botes sueltos no existen (D18). Toda la condimentación se hace en **una línea fija** en la
barra: cuatro **dispensadores** (pimentón dulce, pimentón picante, sal, aceite) y un **cuenco de
cachelos**, en ese orden de izquierda a derecha, que es el orden del ticket. El emplatador pasa por
delante **con la caja llena en la mano** y pulsa interactuar frente a cada dispensador: el condimento
se **alterna** en la caja que lleva (pulsar pone, volver a pulsar quita). La caja nunca se deja en la
estación. Lleva encima una fila de **distintivos** (pegatinas) con lo que tiene, en el mismo orden e
iconos que el ticket: si las dos filas son iguales, la caja es correcta.

Cada pieza tiene **un único verbo** con la caja en la mano: pasaplatos = soltar, dispensador/cuenco
= echar o quitar, puesto = entregar. Por eso basta una tecla (`pN_interact`, D3/InputMap intactos) y
no compiten objetivos: en el tramo de la estación no hay pasaplatos.

### Por qué sigue habiendo dos lados
D18 pide que la estación **fuerce la coordinación**; D23 conserva la barra que separa cocina y
servicio. La línea está en la barra (ver boceto):

- **Lado de pase** (cocina: nevera, cachelera, ollas): solo se **reponen cachelos** en el cuenco.
  Los dispensadores no responden desde aquí (`operator_side_only` = true, se mantiene: el cocinero
  no condimenta). La caja **no** se pasa por la estación, sino por los **pasaplatos marcados** de la
  barra (`level-layouts.md`).
- **Lado de condimentar** (servicio: rack de cajas, puestos): con la caja llena en la mano se
  alternan los cuatro condimentos y los cachelos; también se reponen cachelos.

Para cambiar de lado se rodea la barra por el **hueco de x ≈ 3,2** (N-A): rodeo de 6–10 m
(≈ 1,5 s a 5 m/s).

| Modo | Cómo se juega | Por qué |
|------|---------------|---------|
| **Coop 2P** | El emplatador (servicio) deja cajas vacías en los pasaplatos; el cocinero (cocina) cuece y corta sobre ellas; el emplatador recoge cada caja llena, la condimenta al paso y la entrega. Mientras se condimenta la caja N, el cocinero corta la N+1. | El traspaso sigue siendo un punto fijo (el pasaplatos), pero ya no hay una bandeja única: corte y condimento van **en paralelo**, no en serie (P1 de PUL-090). |
| **Individual (D3)** | Un personaje vive en cada lado. El emplatador deja **dos cajas** en los pasaplatos, cambia (Q), el cocinero cuece un pulpo y corta las dos (1 pulpo = 2 cajas), cambia, el emplatador recoge, condimenta y entrega las dos: **1 cambio por pedido**. También se puede hacer todo con un personaje rodeando la barra: más lento, nunca imposible. | El cambio de personaje sigue siendo la herramienta de Individual. Nada exige que dos personajes actúen **a la vez** (D3). |

Descartado (sigue de D18): la estación «a cuatro manos», un cursor de selección y una segunda tecla
(G9 de PUL-090: cambiaría el InputMap). Fuera de alcance: llevar dos cajas en la mano (rompe «un
objeto en la mano», `movimiento-e-interaccion.md`).

### Interacción (una sola tecla, `interactuar`)
- **Dispensador** (4): objetivo solo con **una caja en la mano** y desde el **lado de condimentar**.
  Con la caja llena, alterna su condimento en esa caja, que sigue en la mano. Pimentón dulce y
  picante son exclusivos (D4): pulsar uno cuando la caja lleva el otro los **intercambia** en una
  sola pulsación (`paprika_swap`). Con la caja sin llenar se rechaza (`BOX_NOT_FULL`). Con la mano
  vacía, con pulpo o con cachelos, **no es objetivo** ni se resalta.
- **Cuenco de cachelos** (concreción de D23/R5 acordada con el coordinador el 2026-10-07; D23 decía
  «solo es objetivo con cachelos cocidos», lo que impedía poner cachelos en una caja). Es objetivo
  solo en dos casos:
  - **(a) reponer:** con cachelos **cocidos** en la mano, desde **cualquier lado**: +2 raciones
    (`cachelos_portions_per_item`), hasta `cachelos_stock_max` (4); lleno, se rechaza.
  - **(b) alternar:** con una caja **llena** en la mano, solo desde el **lado de condimentar**:
    ponerlos gasta 1 ración; quitarlos la devuelve al cuenco (no se pierde el trabajo de la olla,
    D10). Con 0 raciones, ponerlos se rechaza.
  - Con cualquier otra cosa en la mano (pulpo, caja sin llenar, cachelos crudos o quemados), con la
    mano vacía o con una caja desde el lado de pase, **no es objetivo** (quita E1 de PUL-090: el
    cocinero que pasa con pulpo ya no choca con el cuenco).
- **Rechazos** (sonido `season_error` y sacudida del objetivo, sin cambiar nada): caja sin llenar en
  un dispensador, cuenco vacío al poner cachelos, cuenco lleno al reponer.
- **Antirrebote**: el mismo dispensador ignora una segunda pulsación durante `toggle_guard` s
  (0,25 s) medidos con el **reloj de juego** (no el de pared: en pausa no corre; pregunta 4 de
  PUL-090 §7, cerrada).
- Fuera de la estación **no se condimenta**: la caja no acepta cachelos ni condimentos en ninguna
  otra parte.

### Boceto de la línea (vista cenital, cámara ortográfica)
Un carácter ≈ 0,25 m. Posiciones aproximadas; las fija la ficha de nivel (±0,5 m).

```
                 COCINA (nevera, cachelera, ollas)          J2 repone cachelos ↓ (solo el cuenco)
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de PASE (sin dispensadores)
 ▭ ┌────────────────────────────────────────────────────────┐ ░░░░ ┌──── ▭  ▭  ▭
   │   (DUL)      (PIC)      (SAL)      (ACE)      (CUENCO) │ hueco│ barra  pasaplatos
   │   pimentón  pimentón     sal       aceite     cachelos  │ x≈3,2│
   └────────────────────────────────────────────────────────┘ ░░░░ └────
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de CONDIMENTAR
   J1 → pasa con la caja llena en la mano y pulsa en cada uno     →  puestos 1–4
   x ≈ −2,3                                            x ≈ +2,7

   Largo ≈ 5 m · fondo ≈ 1,2 m · 5 objetivos separados ≥ 1,0 m entre centros
   (franja de objetivo ≥ 0,6 m a 1,0 m del eje, R8). Sin Tray ni Slot en el tramo.
```

### Distintivos (pegatinas) de la caja
Sin cambios de D18 salvo que la caja se mira **en la mano**, que es donde se condimenta.
- **Qué**: una pegatina por condimento aplicado: círculo de color (`SeasoningData.color`) con el
  icono en blanco (`SeasoningData.icon`). El picante lleva además la marca de llama
  (`small-fire.svg`), igual que en el ticket: dulce/picante no dependen solo del color.
- **Orden y posición**: fila horizontal centrada sobre la caja, `badge_height` (0,35 m) por encima
  de la tapa, en **orden canónico** `pimentón (dulce o picante) → sal → aceite → cachelos`
  (`SeasoningData.sort_order`), compactada. El ticket usa el mismo orden e iconos.
- **Legibilidad**: billboard sin test de profundidad; `badge_icon_px` = 24 px con `badge_gap_px`
  = 3 px a 1280×720. Con la caja en la mano, la fila sigue por encima del personaje. Sin
  condimentos no hay fila.

```
  Ticket (HUD)                      Caja en la mano (lleva lo mismo: correcta)
  ┌─[azul]─────────────────┐            (PIC)(SAL)(ACE)     ← fila de pegatinas, 24 px
  │ #2  (M) Pulpo Doble    │              ^
  │ (PIC)(SAL)(ACE)        │             ┌──┐
  │   ^                    │             │M │ ← caja en la mano del emplatador
  │ ███████████░░░░  paci. │            ( J1 )
  └────────────────────────┘
```

## Criterios de aceptación
Los AC de reglas puras se testean contra `core/seasoning_rules.gd`; los de interacción, con la
escena de la estación instanciada y el detector real (`level_walker.gd`), sin `await` de tiempo
real (reloj de juego inyectado). **R*n*** = criterio de `rediseno-estaciones.md` §4.3.

- **AC1 (R1)** Given un jugador en el lado de condimentar con una caja llena sin condimentos en la mano, When pulsa interactuar frente al dispensador de sal, Then la caja sigue en la mano, lleva sal, se emite `seasoned(sal)` 1 vez y su fila de pegatinas muestra 1 icono. *Test:* `test_seasoning_station.gd` (integración).
- **AC2 (R2)** Given la caja de AC1, When pulsa otra vez el mismo dispensador a ≥ 0,25 s de juego (`toggle_guard`), Then la caja ya no lleva sal, se emite `seasoning_removed(sal)` 1 vez y no hay fila de pegatinas; When las dos pulsaciones van a 0,1 s, Then la segunda se ignora y la caja sigue con sal. *Test:* `test_seasoning_station.gd`, reloj de juego inyectado.
- **AC3** Given el juego en pausa durante 1 s entre dos pulsaciones del mismo dispensador separadas 0,1 s de juego, Then la segunda se ignora (el antirrebote usa el reloj de juego, no el de pared). *Test:* `test_seasoning_station.gd`.
- **AC4** Given una caja llena con pimentón dulce en la mano, When se pulsa el dispensador de picante, Then la caja lleva picante y no dulce (1 solo condimento del grupo `paprika`) y se emiten `seasoning_removed(dulce)` y `seasoned(picante)` 1 vez cada una. *Test:* `test_seasoning_rules.gd` + `test_seasoning_station.gd`.
- **AC5 (R3)** Given una caja a medio cortar (fill 0,6) en la mano, en el lado de condimentar, When pulsa un dispensador, Then se rechaza (`BOX_NOT_FULL`), la caja no cambia, no se emite `seasoned` y suena `season_error`. *Test:* `test_seasoning_station.gd`.
- **AC6 (R4)** Given un jugador con la mano vacía, con pulpo o con cachelos en el lado de condimentar, frente a cualquier dispensador, Then ningún dispensador es objetivo ni se resalta y pulsar no cambia nada. *Test:* `test_seasoning_station.gd` (candidatos del detector).
- **AC7** Given un jugador en el lado de pase con una caja llena en la mano frente a un dispensador, Then el dispensador no es objetivo ni se resalta (`operator_side_only` = true). *Test:* `test_seasoning_station.gd`.
- **AC8 (R5)** Given un jugador con pulpo, con una caja sin llenar o con cachelos crudos o quemados en la mano, en cualquier punto a ≤ 1,5 m del cuenco (los dos lados), Then el cuenco no es objetivo; Given cachelos cocidos en la mano, Then sí lo es desde los dos lados; Given una caja llena en la mano, Then lo es solo desde el lado de condimentar. *Test:* `test_seasoning_station.gd` + mapa de objetivos.
- **AC9 (R6)** Given el cuenco con 0 raciones y un jugador con cachelos cocidos en la mano (cualquier lado), When interactúa con el cuenco, Then el cuenco tiene **2** raciones y la mano queda vacía; Given el cuenco con 2 raciones, When se repone, Then queda en 4 (`cachelos_stock_max`); Given 3 o 4 raciones, Then reponer se rechaza (no cabe la reposición entera, `condimentacion.md` AC8) y los cachelos siguen en la mano. *Test:* `test_cachelos.gd`.
- **AC10** Given el cuenco con 2 raciones y una caja llena en la mano en el lado de condimentar, When pulsa el cuenco, Then la caja lleva cachelos (sigue en la mano) y el cuenco queda en 1; When pulsa otra vez a ≥ 0,25 s, Then la caja no lleva cachelos y el cuenco vuelve a 2. Con 0 raciones y la caja sin cachelos, poner se rechaza con `season_error`. *Test:* `test_cachelos.gd`.
- **AC11 (R7)** Given `seasoning_station.tscn`, Then no tiene nodo `Tray` ni ningún `Slot`, y con una caja en la mano los únicos objetivos del tramo de la estación (≈ 5 m de barra) son los 4 dispensadores y el cuenco: el barrido de `target_map.gd` da 0 `_` (pasaplatos) y 0 `T` en el tramo. *Test:* `test_station_level.gd` + `target_map.txt` en evidencia.
- **AC12 (R8)** Given el mapa de objetivos (`target_map.gd`) con una caja llena en la mano, a 1,0 m del eje en el lado de condimentar, Then cada dispensador y el cuenco son objetivo en una franja continua ≥ 0,6 m y no hay ningún punto sin objetivo (`.`) entre el primero y el último. *Test:* `test_station_level.gd` (barrido de 0,25 m).
- **AC13** Given una caja llena fuera de la estación (en un pasaplatos o en la mano lejos de la línea), When un jugador interactúa con ella llevando cachelos cocidos, Then no se condimenta (la caja no cambia y los cachelos siguen en la mano). *Test:* `test_box.gd`.
- **AC14** Given una caja con cachelos, aceite, sal y pimentón picante aplicados en ese orden, Then su fila de pegatinas muestra exactamente 4 iconos en el orden picante → sal → aceite → cachelos y el picante lleva la marca de llama. *Test:* `test_box_badges.gd`.
- **AC15** Given una captura a 1280×720 del nivel con una caja de 4 condimentos en la mano de un personaje frente a la línea, Then cada pegatina mide ≥ 22 px, ninguna queda tapada por el personaje ni por la barra y se distinguen dulce y picante sin color. *Test:* captura en `docs/evidence/<ficha>/`.
- **AC16 (R16)** Given Individual con el emplatador en el servicio y el cocinero en la cocina, When se hacen 2 pedidos S con un solo pulpo (el emplatador deja 2 cajas vacías en pasaplatos, cambio, el cocinero cuece y corta las dos, cambio, el emplatador recoge, condimenta al paso y entrega las dos), Then se emiten 2 `order_completed` con exactamente **2** pulsaciones de `p1_switch` en total y ningún personaje rodea la barra. *Test:* `test_station_level.gd` con `level_walker.gd` (input simulado).
- **AC17** Given Individual con un solo personaje, When hace una comanda pulpo+sal+aceite rodeando la barra por el hueco, Then también se completa (la estación nunca exige dos personajes a la vez). *Test:* `test_station_level.gd`.
- **AC18** Given el nivel, Then no existe `SpiceShelf`, `SeasoningItem` ni `Tray`, y los únicos puntos donde cambia el condimento de una caja son los 4 dispensadores y el cuenco. *Test:* `test_level_01.gd`.

*Retirados por D23:* el AC9 de D18 (coger/dejar en la bandeja), el AC6 (bandeja vacía) y el AC8 de
PUL-064 (dispensador con algo en la mano no es objetivo): ahora es al revés, el dispensador solo es
objetivo con una caja en la mano.

## Datos (`.tres`)
- **`SeasoningStationData`** (`data/config/seasoning_station.tres`): `toggle_guard` (0,25 s, reloj
  de juego), `cachelos_stock_max` (3 → **4**, D23), `cachelos_initial_stock` (0),
  `cachelos_portions_per_item` (1 → **2**, D23), `paprika_swap` (true), `operator_side_only`
  (true, **se mantiene**; válvula de balance si el playtest de Individual pide condimentar desde la
  cocina).
- **`BoxBadgeStyle`** (`data/config/box_badges.tres`): sin cambios (`badge_icon_px` 24,
  `badge_gap_px` 3, `badge_height` 0,35 m, `hot_mark`).
- **`SeasoningData`**: sin cambios (`sort_order`, `color`, `icon`).
- Cada dispensador apunta a su `SeasoningData` (`@export`); el cuenco a `cachelos.tres` y al
  `IngredientData` de cachelos cocidos.

## Qué desaparece con D23
- El nodo `Tray` (`Slot` de caja) de `seasoning_station.tscn` y la regla «dejar/recoger la caja en
  la estación desde los dos lados».
- El objetivo del cuenco con la mano vacía o con cualquier objeto que no sean cachelos cocidos o una
  caja llena (lado de condimentar).
- Se mantienen: `SeasoningData`, `BoxContents`, `OrderValidator` (coincidencia exacta),
  `seasoned`/`seasoning_removed` y la fila de pegatinas.

## Contratos afectados (enmienda con gate, ficha 1 de PUL-090 §4.4)
- `docs/arch/scene-tree.md`: baja de `Tray` en `seasoning_station.tscn`; los dispensadores actúan
  sobre la caja de la mano del actor (ADR-003 §8).
- `docs/arch/signals.md`: **sin señales nuevas** (`seasoned`/`seasoning_removed` ya existen).
- InputMap: sin cambios.

## Verificación
GUT para AC1–AC14 y AC16–AC18 (reglas en unit; estación y nivel en integración con el detector
real y reloj de juego inyectado). Mapa de objetivos (`docs/evidence/PUL-090/target_map.gd`
adaptado) para AC8, AC11 y AC12. Captura para AC15.

## Preguntas abiertas
1. **Lado de los dispensadores** (`operator_side_only`): se mantiene en true (PUL-090 §7.3). Si el
   playtest de Individual pide condimentar desde la cocina, se libera en datos sin tocar código.
2. **Raciones visibles en el cuenco.** PUL-090 §5 pedía ver 0–4 raciones; la dirección de arte A
   (PUL-091) no simula stock. Lo decide el playtest de la ficha 7 (¿se pulsa el cuenco vacío?).
