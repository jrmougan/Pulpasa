# Estación de condimentos y distintivos de la caja (Must, D18)

**Slug:** estacion-condimentos · **Prototipo:** ninguno (sustituye a `SpiceShelf` y los botes,
`SeasoningItem`). **Reglas de condimento:** `condimentacion.md` (D4, sí/no).

## Descripción
Los botes sueltos desaparecen (playtest de M2, D18). Toda la condimentación se hace en **una
estación fija**: un mostrador de pase con una **bandeja** para una caja, cuatro **dispensadores**
(pimentón dulce, pimentón picante, sal, aceite) y un **cuenco de cachelos**. La caja llena se deja en
la bandeja; cada dispensador **alterna** su condimento sobre esa caja (pulsar pone, volver a pulsar
quita). La caja lleva encima una fila de **distintivos** (pegatinas) con lo que tiene, en el mismo
orden e iconos que el ticket: si las dos filas son iguales, la caja es correcta.

### Por qué un mostrador de pase con dos lados
El responsable pide que la estación **fuerce la coordinación**. La estación tiene dos lados
distintos (ver boceto):

- **Lado de pase** (mira a la zona de olla y corte): se deja y se recoge la caja en la bandeja y se
  reponen cachelos en el cuenco. **Desde aquí no se pueden usar los dispensadores.**
- **Lado de condimentar** (mira a los puestos de entrega): se usan los dispensadores, se sirven
  cachelos y también se recoge o deja la caja.

La caja atraviesa el mostrador: entra cortada por el pase y sale condimentada hacia la entrega. El
mostrador no se puede cruzar; para cambiar de lado hay que **rodearlo** (rodeo de 6–10 m, unos 1,2–2
s a 5 m/s; la distancia exacta la fija la planta elegida en PUL-041).

| Modo | Cómo se juega | Por qué |
|------|---------------|---------|
| **Coop 2P** | Reparto natural: J1 en la cocina (olla, corte, cachelos) deja la caja en el pase; J2 la condimenta y la entrega. Hay que hablar: qué tamaño de caja, qué lleva, si hay cachelos en el cuenco. | La caja cambia de manos en un punto fijo, que es el momento de coordinación que buscaba D18. Los dos trabajan a la vez sin pisarse: una persona sola por lado. |
| **Individual (D3)** | Se aparca un personaje en cada lado. El activo deja la caja en el pase, pulsa «cambiar» (< 0,2 s, D11) y el otro condimenta y entrega. También se puede rodear el mostrador con un solo personaje: más lento, nunca imposible. | El cambio de personaje es la herramienta del modo Individual: la estación premia usarlo bien, como el pase de Overcooked. Nada exige que dos personajes actúen **a la vez**, porque el inactivo está quieto (D3). |

Se descartó la estación «a cuatro manos» (uno sujeta la caja y otro echa el condimento): en
Individual sería imposible, porque el personaje inactivo no puede actuar. También se descartó que
un jugador elija con un cursor: hay una sola tecla de acción (`pN_interact`) y añadir otra cambia el
InputMap (contrato).

### Interacción (una sola tecla, `interactuar`)
- **Bandeja** (`Tray`, un `Slot` de caja): coger o dejar la caja, desde cualquier lado. Solo cabe
  una caja. Se puede seguir cortando sobre la caja en la bandeja (D1: el corte es sobre la caja).
- **Dispensador** (4): con la **mano vacía** y desde el **lado de condimentar**, alterna su
  condimento en la caja de la bandeja. Pimentón dulce y picante son exclusivos (D4): pulsar uno
  cuando la caja lleva el otro los **intercambia** (sale el que estaba y entra el nuevo) en una sola
  pulsación. Para dejar la caja sin pimentón se pulsa el que lleva.
- **Cuenco de cachelos**: con cachelos **cocidos** en la mano y desde cualquier lado, se echan al
  cuenco (+1 ración, hasta `cachelos_stock_max`). Con la mano vacía y desde el lado de condimentar,
  alterna cachelos en la caja: ponerlos gasta 1 ración; quitarlos la devuelve al cuenco (no se
  pierde el trabajo de la olla, D10). Los cachelos crudos o quemados se rechazan.
- **Rechazos** (sonido de error y sacudida del objetivo, sin cambiar nada): bandeja vacía, caja sin
  llenar, mano ocupada en un dispensador, dispensador usado desde el pase, cuenco vacío o lleno.
- **Antirrebote**: el mismo dispensador ignora una segunda pulsación durante `toggle_guard` s
  (0,25 s), para que un doble toque no ponga y quite a la vez.
- Fuera de la estación ya **no se condimenta**: la caja no acepta botes ni cachelos en ninguna otra
  parte.

### Boceto de la estación (vista cenital, cámara ortográfica)
Un carácter ≈ 0,25 m. Boceto vectorial en `docs/evidence/PUL-040/boceto-estacion.svg`.

```
                 COCINA (olla, nevera, corte)
                         J1 ↓ deja la caja / repone cachelos
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de PASE
  ┌──────────────────────────────────────────────────────┐
  │  ┌────┐                                     ┌──────┐ │
  │  │Cue-│   ┌─────────────────────────────┐   │      │ │
  │  │nco │   │   BANDEJA  [ caja ]         │   │ (re- │ │
  │  │CAC │   └─────────────────────────────┘   │ serva│ │
  │  │×2/3│                                     │ PUL- │ │
  │  └────┘   (DUL)    (PIC)    (SAL)   (ACE)   │ 041) │ │
  └──────────────────────────────────────────────────────┘
   ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·   ← lado de CONDIMENTAR
                         J2 ↑ condimenta y recoge
                 PUESTOS DE ENTREGA 1–4

   Largo ≈ 4,5 m · fondo ≈ 1,2 m · dispensadores separados ≥ 0,9 m (centro a centro)
   para que el más cercano sea inequívoco con interact_range = 1,5 m.
   El hueco de la derecha es opcional (segunda bandeja si el balance lo pide, ver preguntas).
```

### Distintivos (pegatinas) de la caja
- **Qué**: una pegatina por condimento aplicado: círculo de color (`SeasoningData.color`) con el
  icono en blanco encima (`SeasoningData.icon`). El picante lleva además la marca de llama
  (`small-fire.svg`), igual que en el ticket: la diferencia dulce/picante no depende solo del color.
- **Orden y posición**: fila horizontal centrada sobre la caja, `badge_height` (0,35 m) por encima
  de la tapa, en **orden canónico** `pimentón (dulce o picante) → sal → aceite → cachelos`
  (`SeasoningData.sort_order`) y compactada (sin huecos). El ticket usa **el mismo orden y los mismos
  iconos**, así que comprobar una caja es comparar dos filas.
- **Legibilidad**: a 1280×720 la cámara (`size` 12,74 m) da ≈ 56,5 px/m; la caja mide ≈ 0,4 m
  (≈ 22 px), demasiado poco para pegatinas sobre la tapa. Por eso la fila **flota** encima, en
  billboard y sin test de profundidad (no la tapa la mano ni el personaje). Cada pegatina mide
  `badge_icon_px` = 24 px en pantalla (≈ 0,42 m) con `badge_gap_px` = 3 px; la fila completa (4)
  ocupa ≈ 105 px. La fila se ve igual con la caja en la mano, en la bandeja o en una mesa.
- **Sin condimentos** no hay fila. Las pegatinas en la propia tapa (decorativas, no informativas)
  son cosa del arte de las cajas (PUL-047).

```
  Ticket (HUD)                      Caja en el mundo (lleva lo mismo: correcta)
  ┌────────────────────────┐            (PIC)(SAL)(ACE)     ← fila de pegatinas, 24 px
  │ #2  Pulpo · caja media │              ^                   (^ = marca de llama del picante)
  │ (PIC)(SAL)(ACE)        │            ┌──────┐
  │   ^                    │            │ caja │ ≈ 22 px
  │ ███████████░░░░  paci. │            └──────┘
  └────────────────────────┘
  Orden fijo en los dos: pimentón → sal → aceite → cachelos.
```

## Criterios de aceptación
Los AC de reglas puras (toggle, intercambio, rechazo con caja sin llenar, orden canónico) se testean
contra el núcleo `RefCounted` de `core/`; los de interacción, con la escena de la estación
instanciada en un test de integración.

- **AC1** Given una caja llena en la bandeja y un jugador con la mano vacía en el lado de condimentar, When interactúa con el dispensador de sal, Then la caja lleva sal, se emite `seasoned(sal)` una vez y aparece 1 pegatina de sal.
- **AC2** Given la caja anterior con sal, When el jugador vuelve a interactuar con el dispensador de sal pasados ≥ 0,25 s, Then la caja ya no lleva sal, se emite `seasoning_removed(sal)` una vez y la fila de pegatinas desaparece.
- **AC3** Given una caja con sal en la bandeja, When se pulsa el dispensador de sal dos veces con 0,1 s de separación, Then la segunda pulsación se ignora (`toggle_guard` = 0,25 s) y la caja sigue con sal.
- **AC4** Given una caja llena con pimentón dulce en la bandeja, When se interactúa con el dispensador de picante, Then la caja lleva picante y no dulce (exactamente 1 condimento del grupo `paprika`), y se emiten `seasoning_removed(dulce)` y `seasoned(picante)` una vez cada una.
- **AC5** Given una caja a medio llenar (fill 0,6) o vacía en la bandeja, When se interactúa con cualquier dispensador, Then se rechaza: el contenido no cambia, no se emite `seasoned` y suena el error.
- **AC6** Given la bandeja vacía, When se interactúa con un dispensador, Then se rechaza sin errores en consola.
- **AC7** Given un jugador en el lado de pase con la mano vacía y una caja llena en la bandeja, When intenta usar un dispensador, Then el dispensador no se resalta ni responde (la caja no cambia).
- **AC8** Given un jugador en el lado de condimentar con algo en la mano, When interactúa con un dispensador, Then se rechaza y la mano no cambia.
- **AC9** Given una caja en la bandeja, When un jugador con la mano vacía interactúa con ella desde cualquiera de los dos lados, Then la coge; Given un jugador con una caja en la mano y la bandeja libre, When interactúa con la bandeja desde cualquier lado, Then la caja queda en la bandeja. Con la bandeja ocupada, dejar otra se rechaza.
- **AC10** Given un cuenco con 0 raciones y un jugador con cachelos cocidos en la mano, When interactúa con el cuenco (cualquier lado), Then el cuenco tiene 1 ración y la mano queda vacía; con cachelos crudos o quemados, se rechaza y siguen en la mano; con el cuenco en `cachelos_stock_max` (3), se rechaza.
- **AC11** Given un cuenco con 2 raciones y una caja llena en la bandeja, When se alterna cachelos desde el lado de condimentar, Then la caja lleva cachelos y el cuenco queda en 1; When se alterna otra vez, Then la caja no lleva cachelos y el cuenco vuelve a 2. Con el cuenco a 0 y la caja sin cachelos, poner cachelos se rechaza.
- **AC12** Given una caja llena fuera de la estación (en una mesa o en la mano), When un jugador interactúa con ella llevando cachelos cocidos, Then no se condimenta (la caja no cambia y los cachelos siguen en la mano).
- **AC13** Given una caja con cachelos, aceite, sal y pimentón picante aplicados en ese orden, Then su fila de pegatinas muestra exactamente 4 iconos en el orden picante → sal → aceite → cachelos, y el picante lleva la marca de llama.
- **AC14** Given una comanda de pulpo + picante + sal + aceite + cachelos (seasonings en cualquier orden en su `.tres`), Then su ticket muestra los iconos en el mismo orden canónico que AC13.
- **AC15** Given una captura a 1280×720 del nivel con una caja de 4 condimentos en la bandeja y otra en la mano de un personaje, Then cada pegatina mide ≥ 22 px, ninguna queda tapada por el personaje ni por el mostrador y se distinguen dulce y picante sin color (marca de llama).
- **AC16** Given el modo Individual con el personaje A en el lado de pase y B en el de condimentar, When A deja una caja llena en la bandeja, se cambia a B, B pone sal y aceite y entrega en el puesto de la comanda pulpo+sal+aceite, Then se emite `order_completed` una vez, sin que ningún personaje rodee el mostrador.
- **AC17** Given el modo Individual con un solo personaje usado, When hace la misma comanda que AC16 rodeando el mostrador, Then también se completa (la estación nunca exige dos personajes a la vez).
- **AC18** Given el nivel con la estación, Then no existe ninguna `SpiceShelf` ni ningún `SeasoningItem` en la escena, y los únicos puntos donde cambia el condimento de una caja son los 4 dispensadores y el cuenco.

## Datos (`.tres`)
- **Nuevo `SeasoningStationData`** (`resources/seasoning_station_data.gd`,
  `data/config/seasoning_station.tres`): `toggle_guard` (0,25 s), `cachelos_stock_max` (3),
  `cachelos_initial_stock` (0), `cachelos_portions_per_item` (1), `paprika_swap` (true; con false,
  pulsar el otro pimentón se rechaza como en la regla antigua), `operator_side_only` (true; válvula
  de balance: con false los dispensadores funcionan desde los dos lados, por si el playtest de
  Individual lo pide).
- **Nuevo `BoxBadgeStyle`** (`resources/box_badge_style.gd`, `data/config/box_badges.tres`):
  `badge_icon_px` (24), `badge_gap_px` (3), `badge_height` (0,35 m), `hot_mark` (textura de llama,
  hoy `small-fire.svg`). Lo leen la caja (mundo) y el ticket (HUD) para que el tamaño relativo y la
  marca sean los mismos.
- **`SeasoningData`**: campo nuevo `sort_order: int` (pimentón dulce 0, picante 0, sal 1, aceite 2,
  cachelos 3). `color` e `icon` ya existen y se reutilizan para la pegatina.
- Cada dispensador de la escena apunta a su `SeasoningData` (`@export`), como hoy los slots de
  `SpiceShelf`. El cuenco apunta a `data/seasonings/cachelos.tres` y acepta el `IngredientData` de
  cachelos cocidos.

## Qué desaparece
- `entities/stations/spice_shelf.tscn` (estantería de botes) y su instancia en `level_01.tscn` y en
  los sandboxes.
- `entities/items/seasoning.tscn`, `seasoning_item.gd` (`SeasoningItem`, botes que se cogen y se
  sueltan) y el placeholder `assets/models/placeholders/condiment_jar.tscn`.
- Los slots de bote (`SaltSlot`, `PaprikaSlot`, …) y su `initial_item`/`initial_item_data`.
- En `box.gd`, las dos rutas de condimentar al interactuar con la caja (bote en la mano y cachelos
  cocidos en la mano). La caja conserva el corte (D1) y el coger/soltar.
- Tests que dependen de botes (`test_seasoning.gd`, `test_shelves.gd`, partes de `test_box.gd`,
  `test_cachelos.gd`, `test_m1_flow.gd`, `test_m2_flow.gd`, `test_kitchen_flow.gd`,
  `test_items_contract.gd`): se reescriben contra la estación en las fichas de abajo.
- Se mantienen: `SeasoningData` y los cinco `.tres` de `data/seasonings/`, `BoxContents`,
  `OrderValidator` (coincidencia exacta) y la señal local `seasoned`.

## Contratos afectados (necesitan enmienda y gate humano)
- `docs/arch/signals.md`: señal local nueva `Box.seasoning_removed(seasoning: SeasoningData)`; las
  señales de la estación (`rejected`, cambio de raciones del cuenco) son locales a su escena.
  Ninguna señal nueva en `EventBus`.
- `docs/arch/scene-tree.md`: contrato de nodos de `seasoning_station.tscn` (`Tray`, `Dispensers/*`,
  `CachelosBowl`, `PassSide`/`OperatorSide`, `Model`) y de `BadgeRow` en `box.tscn`; baja de
  `SpiceShelf` y `SeasoningItem`.
- La fila de pegatinas es 3D de mundo (`Sprite3D`): vive en `entities/items/`, no en `ui/` (regla
  4). Lo que comparten ticket y caja es dato (`BoxBadgeStyle`, `SeasoningData`), no nodos.

## Fichas de implementación propuestas (en orden)
Numeración provisional; la asigna el producer.

| Orden | Ficha | Rol | Deps | Qué |
|-------|-------|-----|------|-----|
| 1 | Enmienda de contratos de la estación | godot-architect | PUL-040 | `signals.md` (`seasoning_removed`), `scene-tree.md` (estación, `BadgeRow`, bajas). **Gate humano.** |
| 2 | Reglas de condimento como núcleo | gameplay-engineer | 1 | `core/seasoning_rules.gd` (`RefCounted`): alternar, intercambio de pimentón, rechazo si no está llena, orden canónico; `SeasoningData.sort_order`; `Box.toggle_seasoning()`/`remove_seasoning()`; quitar de `box.gd` las rutas de bote y cachelos. GUT para AC2–AC5, AC12, AC13 (lógica). |
| 3 | Escena de la estación de condimentos | gameplay-engineer | 2 | `entities/stations/seasoning_station.tscn` con placeholder de primitivas, `SeasoningStationData` + `.tres`, dispensadores con lado, cuenco con raciones, antirrebote, sonidos de error; sandbox propio. GUT para AC1, AC3, AC6–AC11. |
| 4 | Distintivos en la caja | gameplay-engineer | 2 | `BadgeRow` en `box.tscn` (billboard, sin test de profundidad), `BoxBadgeStyle` + `.tres`. Captura para AC13/AC15. Puede ir en paralelo con 3 (escenas distintas). |
| 5 | Ticket en orden canónico y estilo de pegatina | ui-engineer | 2 | `ticket_entry.gd` ordena por `sort_order` y dibuja la pegatina con `BoxBadgeStyle`. AC14 y captura comparando ticket y caja. Paralelo a 3 y 4. |
| 6 | Estación en el nivel y baja de los botes | gameplay-engineer (nivel) | 3, 4, 5, PUL-041 elegida | Sustituir `SpiceShelf` en `level_01.tscn` por la estación según la planta elegida; borrar botes, slots y placeholder; reescribir los tests de flujo. AC16–AC18. |
| 7 | QA y playtest de la estación | qa-tester | 6 | Regresión completa y guía de playtest (coop e Individual): tiempo medio por comanda con condimentos, nº de pulsaciones de error, ¿se usa el cambio de personaje? Decide `paprika_swap`, `operator_side_only` y el rodeo. |
| — | Modelo de la estación (ya existe, PUL-052) | asset-pipeline | 3, PUL-042, PUL-043 | Sustituye el `Model` placeholder respetando `Tray`, dispensadores y lados. |

## Verificación
GUT para AC1–AC14 y AC16–AC18 (reglas en unit, estación y nivel en integración con input simulado
por señales, sin `await` de tiempo real: el antirrebote con reloj inyectado). Captura en
`docs/evidence/<ficha>/` para AC15 y para el par ticket/caja de AC13–AC14.

## Preguntas abiertas
1. **Una o dos bandejas.** Con una, el pase es un cuello de botella deliberado (coordinación); con
   tres o cuatro comandas activas puede atascar. Se propone empezar con una y dejar el hueco de la
   segunda en el modelo; lo decide el playtest de la ficha 7.
2. **Intercambio de pimentón** (`paprika_swap`). Se propone intercambiar en una pulsación (menos
   frustración); la regla antigua rechazaba. Cambia el AC2 de `condimentacion.md`.
3. **Rodeo del mostrador** (6–10 m). Más largo fuerza más la coordinación en coop pero castiga al
   Individual que no cambia de personaje. Depende de la planta de PUL-041.
4. **Raciones por cachelos cocidos** (`cachelos_portions_per_item` = 1). Con 2, los cachelos
   compiten menos con el pulpo en la olla (D10).
