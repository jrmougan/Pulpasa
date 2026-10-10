# Línea de aliño «al paso» y pegatinas de la caja (Must, D18 modificada por D23 y D25)

**Slug:** estacion-condimentos · **Prototipo:** ninguno (sustituye a `SpiceShelf` y los botes,
`SeasoningItem`). **Reglas de aliño:** `condimentacion.md` (D4, D25). **Rediseño:**
`docs/design/rediseno-estaciones.md` (PUL-090), paquete C-B + B-A + E-A + N-A + cachelos ×2,
aprobado el 2026-10-07 (D23). **Arte:** `docs/art/rediseno-estaciones-arte.md` (PUL-091,
dirección A · Señalética de pase).

> **Sustituido por D23.** La versión de D18 (2026-10-05) dejaba la caja en una **bandeja** (`Tray`)
> de la estación. Desde D23 **no hay bandeja**: la caja llena se lleva **en la mano**.
>
> **Sustituido por D25 (2026-10-10).** Los **4 dispensadores** (pimentón dulce, pimentón picante,
> sal, aceite) y su alternar se reemplazan por **2 dispensadores de aliño completo** de una
> pulsación: *aliño dulce* (sal gorda + aceite + pimentón dulce) y *aliño picante* (sal gorda +
> aceite + pimentón picante). Pulsar el otro aliño lo **sustituye**; pulsar el mismo **no hace
> nada**; no hay quitar (lo mal hecho va al cubo, `cubo-basura.md`). Se van el toggle,
> `paprika_swap` como regla aparte y la sal y el aceite sueltos. El **cuenco de cachelos no cambia**
> (D10, D23). Siguen de D18/D23: la estación en la barra que separa cocina y servicio, los dos
> lados, el antirrebote (ahora solo para cachelos) y las pegatinas en el orden del ticket.

## Descripción
Los botes sueltos no existen (D18). Toda la condimentación se hace en **una línea fija** en la
barra: dos **dispensadores de aliño** (dulce, picante) y un **cuenco de cachelos**, en ese orden de
izquierda a derecha, que es el orden del ticket (aliño → cachelos). El emplatador pasa por delante
**con la caja llena en la mano** y pulsa interactuar frente al aliño que pide la comanda: el aliño
queda aplicado en la caja que lleva, con un **gesto visual breve** (una pizca de sal gorda, un
chorrito de aceite y una nube de pimentón, ≥ 0,3 s). Si la comanda pide cachelos, pulsa además el
cuenco. La caja nunca se deja en la estación. Lleva encima una fila de **pegatinas** con lo que
tiene: **1 de aliño** y, si los lleva, la de cachelos. Si la fila es igual a la del ticket, la caja es correcta.

Cada pieza tiene **un único verbo** con la caja en la mano: pasaplatos = soltar, dispensador de
aliño = aliñar, cuenco = poner/quitar cachelos, cubo = tirar, puesto = entregar. Por eso basta una
tecla (`pN_interact`, D3/InputMap intactos) y no compiten objetivos: en el tramo de la estación no
hay pasaplatos.

### Por qué sigue habiendo dos lados
D18 pide que la estación **fuerce la coordinación**; D23 conserva la barra que separa cocina y servicio.

- **Lado de pase** (cocina: nevera, cachelera, ollas): solo se **reponen cachelos** en el cuenco.
  Los dispensadores no responden desde aquí (`operator_side_only` = true, se mantiene). La caja se
  pasa por los **pasaplatos marcados** de la barra (`level-layouts.md`).
- **Lado de aliñar** (servicio: rack de cajas, puestos): con la caja llena en la mano se aplica el
  aliño y se alternan los cachelos; también se reponen cachelos.

Para cambiar de lado se rodea la barra por el **hueco de x ≈ 3,2** (N-A): rodeo de 6–10 m.

| Modo | Cómo se juega | Por qué |
|------|---------------|---------|
| **Coop 2P** | El emplatador (servicio) deja cajas vacías en los pasaplatos; el cocinero (cocina) cuece y corta sobre ellas; el emplatador recoge cada caja llena, la aliña al paso y la entrega. Mientras se aliña la caja N, el cocinero corta la N+1. | Corte y aliño van **en paralelo**, no en serie (P1 de PUL-090). |
| **Individual (D3)** | Un personaje vive en cada lado. El emplatador deja **dos cajas** en los pasaplatos, cambia (Q), el cocinero cuece un pulpo y corta las dos (1 pulpo = 2 cajas), cambia, el emplatador recoge, aliña y entrega las dos: **1 cambio por pedido**. También se puede hacer todo con un personaje rodeando la barra. | El cambio de personaje sigue siendo la herramienta de Individual. Nada exige dos personajes a la vez (D3). |

Descartado: la estación «a cuatro manos», un cursor de selección y una segunda tecla; llevar dos
cajas en la mano (rompe «un objeto en la mano», `movimiento-e-interaccion.md`).

### Interacción (una sola tecla, `interactuar`)
- **Dispensador de aliño** (2): objetivo solo con **una caja en la mano** y desde el **lado de aliñar**.
  - Caja **llena** sin aliño: aplica el aliño (la caja sigue en la mano), 1 `seasoned`, gesto visual.
  - Caja llena con **el otro aliño**: lo **sustituye** (`seasoning_removed` del anterior y `seasoned` del
    nuevo, mismo frame). Es el único «quitar» que existe.
  - Caja llena con **el mismo aliño**: no hace nada (sin señal, sin sonido de error, sin penalización).
  - Caja **sin llenar**: se rechaza (`BOX_NOT_FULL`), suena `season_error` y se sacude el dispensador.
  - Con la mano vacía, con pulpo o con cachelos, **no es objetivo** ni se resalta.
- **Cuenco de cachelos** (sin cambios respecto a D23). Es objetivo solo en dos casos:
  - **(a) reponer:** con cachelos **cocidos** en la mano, desde **cualquier lado**: +2 raciones
    (`cachelos_portions_per_item`), hasta `cachelos_stock_max` (4); lleno, se rechaza.
  - **(b) alternar:** con una caja **llena** en la mano, solo desde el **lado de aliñar**:
    ponerlos gasta 1 ración; quitarlos la devuelve al cuenco (D10). Con 0 raciones, ponerlos se rechaza.
  - Con cualquier otra cosa en la mano, con la mano vacía o con una caja desde el lado de pase, **no
    es objetivo**.
- **Rechazos** (sonido `season_error` y sacudida del objetivo, sin cambiar nada): caja sin llenar en
  un dispensador, cuenco vacío al poner cachelos, cuenco lleno al reponer.
- **Antirrebote**: el cuenco ignora una segunda pulsación durante `toggle_guard` s (0,25 s) medidos
  con el **reloj de juego**. Los aliños no lo necesitan (repetir no hace nada).
- Fuera de la estación **no se aliña**: la caja no acepta aliño ni cachelos en ninguna otra parte.

### Boceto de la línea (vista cenital, cámara ortográfica)
Un carácter ≈ 0,25 m. Posiciones aproximadas; las fija la ficha de nivel (±0,5 m).

```
                 COCINA (nevera, cachelera, ollas)          J2 repone cachelos ↓ (solo el cuenco)
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de PASE (sin dispensadores)
 ▭ ┌─────────────────────────────────────┐ ░░░░ ┌──── ▭  ▭  ▭
   │   (DULCE)     (PICANTE)    (CUENCO)  │ hueco│ barra  pasaplatos
   │   aliño       aliño        cachelos  │ x≈3,2│
   └─────────────────────────────────────┘ ░░░░ └────
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de ALIÑAR
   J1 → pasa con la caja llena en la mano y pulsa en cada uno     →  puestos 1–4

   Largo ≈ 3,5 m · fondo ≈ 1,2 m · 3 objetivos separados ≥ 1,0 m entre centros
   (franja de objetivo ≥ 0,6 m a 1,0 m del eje). Sin Tray ni Slot en el tramo.
```

### Pegatinas de la caja
- **Qué**: una pegatina por elemento aplicado: círculo de color (`SeasoningData.color`) con el icono
  en blanco (`SeasoningData.icon`). **Aliño** = 1 pegatina (el dulce y el picante tienen icono y color
  propios; el picante lleva además la marca de llama `small-fire.svg`, igual que en el ticket, para no
  depender del color). **Cachelos** = 1 pegatina. Máximo 2 pegatinas.
- **Orden y posición**: fila horizontal centrada, `badge_height` (0,35 m) por encima de la tapa, en
  orden canónico `aliño → cachelos` (`SeasoningData.sort_order`). El ticket usa el mismo orden.
- **Legibilidad**: billboard sin test de profundidad; `badge_icon_px` = 24 px con `badge_gap_px` = 3 px
  a 1280×720. Con la caja en la mano, la fila sigue por encima del personaje. Sin aliño ni cachelos no hay fila.

```
  Ticket (HUD)                      Caja en la mano (lleva lo mismo: correcta)
  ┌─[azul]─────────────────┐            (PIC)(CAC)     ← fila de pegatinas, 24 px
  │ #2  Bravo cachelos     │              ^
  │ (PIC)(CAC)             │             ┌──┐
  │ ███████████░░░░  paci. │             │  │ ← caja única en la mano del emplatador
  └────────────────────────┘            ( J1 )
```

## Criterios de aceptación
Los AC de reglas puras se testean contra `core/seasoning_rules.gd`; los de interacción, con la
escena de la estación instanciada y el detector real (`level_walker.gd`), sin `await` de tiempo
real (reloj de juego inyectado). **R*n*** = criterio de `rediseno-estaciones.md` §4.3.

- **AC1 (R1, reescrito)** Given un jugador en el lado de aliñar con una caja llena sin aliño en la mano, When pulsa interactuar frente al dispensador de aliño dulce, Then la caja sigue en la mano, lleva `SWEET_DRESSING`, se emite `seasoned(sweet_dressing)` 1 vez y su fila de pegatinas muestra 1 icono. *Test:* `test_seasoning_station.gd` (integración).
- **AC2 (reescrito, sustituye al alternar)** Given la caja de AC1, When pulsa otra vez el mismo dispensador (a 0,1 s o a 5 s), Then el resultado es `ALREADY_APPLIED` (silencioso: sin `rejected` ni cue), la caja sigue con `SWEET_DRESSING`, no se emite ninguna señal y la fila sigue con 1 icono. *Test:* `test_seasoning_station.gd`.
- **AC3** *(superado por D25: el antirrebote ya no afecta al aliño)* Given el juego en pausa durante 1 s entre dos pulsaciones del cuenco separadas 0,1 s de juego, Then la segunda se ignora (el antirrebote del cuenco usa el reloj de juego, no el de pared). *Test:* `test_seasoning_station.gd`.
- **AC4 (reescrito, sustituye a `paprika_swap`)** Given una caja llena con aliño dulce en la mano, When se pulsa el dispensador de aliño picante, Then la caja lleva `HOT_DRESSING` y no `SWEET_DRESSING` y se emiten `seasoning_removed(sweet_dressing)` y, después, `seasoned(hot_dressing)`, 1 vez cada una, en la misma llamada. *Test:* `test_seasoning_rules.gd` + `test_seasoning_station.gd`.
- **AC5 (R3)** Given una caja a medio cortar (fill 0,6) en la mano, en el lado de aliñar, When pulsa un dispensador, Then se rechaza (`BOX_NOT_FULL`), la caja no cambia, no se emite `seasoned` y suena `season_error`. *Test:* `test_seasoning_station.gd`.
- **AC6 (R4)** Given un jugador con la mano vacía, con pulpo o con cachelos en el lado de aliñar, frente a cualquier dispensador, Then ningún dispensador es objetivo ni se resalta y pulsar no cambia nada. *Test:* `test_seasoning_station.gd` (candidatos del detector).
- **AC7** Given un jugador en el lado de pase con una caja llena en la mano frente a un dispensador, Then el dispensador no es objetivo ni se resalta (`operator_side_only` = true). *Test:* `test_seasoning_station.gd`.
- **AC8 (R5)** Given un jugador con pulpo, con una caja sin llenar o con cachelos crudos o quemados en la mano, en cualquier punto a ≤ 1,5 m del cuenco (los dos lados), Then el cuenco no es objetivo; Given cachelos cocidos en la mano, Then sí lo es desde los dos lados; Given una caja llena en la mano, Then lo es solo desde el lado de aliñar. *Test:* `test_seasoning_station.gd` + mapa de objetivos.
- **AC9 (R6)** Given el cuenco con 0 raciones y un jugador con cachelos cocidos en la mano (cualquier lado), When interactúa con el cuenco, Then el cuenco tiene **2** raciones y la mano queda vacía; Given el cuenco con 2 raciones, When se repone, Then queda en 4; Given 3 o 4 raciones, Then reponer se rechaza y los cachelos siguen en la mano. *Test:* `test_cachelos.gd`. (Sin cambios.)
- **AC10** Given el cuenco con 2 raciones y una caja llena en la mano en el lado de aliñar, When pulsa el cuenco, Then la caja lleva cachelos (sigue en la mano) y el cuenco queda en 1; When pulsa otra vez a ≥ 0,25 s, Then la caja no lleva cachelos y el cuenco vuelve a 2. Con 0 raciones y la caja sin cachelos, poner se rechaza con `season_error`. *Test:* `test_cachelos.gd`. (Sin cambios.)
- **AC11 (R7, reescrito)** Given `seasoning_station.tscn`, Then no tiene nodo `Tray` ni ningún `Slot`, tiene exactamente 2 dispensadores de aliño y 1 cuenco, y con una caja en la mano los únicos objetivos del tramo de la estación (≈ 3,5 m de barra) son esos 3: el barrido de `target_map.gd` da 0 `_` (pasaplatos) y 0 `T` en el tramo. *Test:* `test_station_level.gd` + `target_map.txt` en evidencia.
- **AC12 (R8, reescrito)** Given el mapa de objetivos con una caja llena en la mano, a 1,0 m del eje en el lado de aliñar, Then cada dispensador de aliño y el cuenco son objetivo en una franja continua ≥ 0,6 m y no hay ningún punto sin objetivo (`.`) entre el primero y el último. *Test:* `test_station_level.gd` (barrido de 0,25 m).
- **AC13** Given una caja llena fuera de la estación (en un pasaplatos o en la mano lejos de la línea), When un jugador interactúa con ella llevando cachelos cocidos, Then no se condimenta (la caja no cambia y los cachelos siguen en la mano). *Test:* `test_box.gd`.
- **AC14 (reescrito)** Given una caja con aliño picante y cachelos aplicados en ese orden o en el inverso, Then su fila de pegatinas muestra exactamente 2 iconos en el orden aliño → cachelos y el aliño picante lleva la marca de llama. *Test:* `test_box_badges.gd`.
- **AC15 (reescrito)** Given una captura a 1280×720 del nivel con una caja con aliño y cachelos en la mano de un personaje frente a la línea, Then cada pegatina mide ≥ 22 px, ninguna queda tapada por el personaje ni por la barra y se distinguen dulce y picante sin color. *Test:* captura en `docs/evidence/<ficha>/`.
- **AC16 (R16)** Given Individual con el emplatador en el servicio y el cocinero en la cocina, When se hacen 2 pedidos con un solo pulpo (el emplatador deja 2 cajas vacías en pasaplatos, cambio, el cocinero cuece y corta las dos, cambio, el emplatador recoge, aliña al paso y entrega las dos), Then se emiten 2 `order_completed` con exactamente **2** pulsaciones de `p1_switch` en total y ningún personaje rodea la barra. *Test:* `test_station_level.gd` con `level_walker.gd` (input simulado).
- **AC17** Given Individual con un solo personaje, When hace una comanda «Á feira» rodeando la barra por el hueco, Then también se completa (la estación nunca exige dos personajes a la vez). *Test:* `test_station_level.gd`.
- **AC18** Given el nivel, Then no existe `SpiceShelf`, `SeasoningItem` ni `Tray`, y los únicos puntos donde cambia el contenido de una caja son los 2 dispensadores de aliño y el cuenco (y el cubo, que la destruye entera). *Test:* `test_level_01.gd`.
- **AC19 (D25)** Given una caja llena y un jugador frente al dispensador de aliño dulce, When pulsa interactuar, Then se lanza el gesto visual (≥ 0,3 s, partículas de sal gorda, aceite y pimentón del color del aliño) y suena 1 cue de condimentar; con el aliño picante el gesto usa el pimentón picante. *Test:* `test_seasoning_station.gd` (estado del efecto) + captura.
- **AC20 (D25)** Given una comanda «Á feira» y una caja con aliño picante, When se entrega, Then se rechaza como caja errónea (D8) y la caja sigue en la mano; When el jugador pulsa el aliño dulce, Then la caja pasa a dulce y la entrega se acepta sin pasar por el cubo. *Test:* `test_seasoning_station.gd` + `test_order_stand.gd`.

*Retirados por D25:* el alternar de sal/aceite/pimentón (AC2/AC3 originales), los 4 dispensadores y
sus pegatinas (AC14/AC15 originales), `paprika_swap` y el S/M/L de la caja. *Retirados por D23:* el
AC9 de D18 (coger/dejar en la bandeja), el AC6 (bandeja vacía) y el AC8 de PUL-064.

## Datos (`.tres`)
- **`SeasoningStationData`** (`data/config/seasoning_station.tres`): `toggle_guard` (0,25 s, reloj
  de juego, solo cuenco), `cachelos_stock_max` (4), `cachelos_initial_stock` (0),
  `cachelos_portions_per_item` (2), `operator_side_only` (true; válvula de balance). Se retira
  `paprika_swap`. El gesto visual del aliño (≥ 0,3 s) es un nodo de la escena del dispensador, no un dato.
- **`BoxBadgeStyle`** (`data/config/box_badges.tres`): sin cambios (`badge_icon_px` 24,
  `badge_gap_px` 3, `badge_height` 0,35 m, `hot_mark`).
- **`SeasoningData`**: 3 recursos (`sweet_dressing.tres`, `hot_dressing.tres`, `cachelos.tres`) con
  `sort_order`, `color`, `icon` y, los dos aliños, el grupo de exclusividad `dressing`.
- Cada dispensador apunta a su `SeasoningData` (`@export`); el cuenco a `cachelos.tres` y al
  `IngredientData` de cachelos cocidos.

## Qué desaparece con D23 y D25
- D23: el nodo `Tray` de `seasoning_station.tscn` y la regla «dejar/recoger la caja en la estación».
- D25: 2 de los 4 dispensadores (pasan a ser 2 aliños completos), el alternar de aliño, `paprika_swap`
  y las pegatinas de sal, aceite y pimentón sueltos.
- Se mantienen: `SeasoningData`, `BoxContents`, `OrderValidator` (coincidencia exacta),
  `seasoned`/`seasoning_removed` y la fila de pegatinas.

## Contratos afectados
Los gestiona la enmienda de arquitectura paralela (PUL-111): árbol de escena de la estación (dos
dispensadores de aliño en vez de cuatro, sin `Tray`) y semántica de `seasoned`/`seasoning_removed`
con aliños exclusivos. Esta feature no cambia el InputMap ni añade señales por sí misma.

## Verificación
GUT para AC1–AC14 y AC16–AC20 (reglas en unit; estación y nivel en integración con el detector
real y reloj de juego inyectado). Mapa de objetivos (`docs/evidence/PUL-090/target_map.gd`
adaptado) para AC8, AC11 y AC12. Captura para AC15 y AC19.

## Preguntas abiertas
1. **Lado de los dispensadores** (`operator_side_only`): se mantiene en true. Si el playtest de
   Individual pide aliñar desde la cocina, se libera en datos sin tocar código.
2. **Raciones visibles en el cuenco.** PUL-090 §5 pedía ver 0–4 raciones; lo decide el playtest
   posterior a D25.
