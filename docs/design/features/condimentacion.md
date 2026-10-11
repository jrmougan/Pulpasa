# Aliño y cachelos sí/no (Must, D4, D18 y D23 modificadas por D25)

**Slug:** condimentacion · **Prototipo:** `SeasoningItem`, `SpicesSO`, `ISeasonable` (los botes ya
no se portan, D18).

## Descripción
Sobre la caja llena de pulpo (cortado) se decide un **aliño** y, opcionalmente, **cachelos**:

- **Aliño** (obligatorio en las 4 recetas, D25): *aliño dulce* = sal gorda + aceite + pimentón dulce, o
  *aliño picante* = sal gorda + aceite + pimentón picante. Es **una sola decisión de una pulsación**:
  la sal gorda y el aceite ya no se eligen sueltos (D4 sigue siendo sí/no: qué aliño, y cachelos sí/no).
- **Cachelos** (opcionales, cocidos en la olla, D10): sí/no, con el cuenco de D23.

El aliño es **exclusivo** (la caja lleva a lo sumo uno): aplicar el otro lo **sustituye**; aplicar el
mismo **no hace nada** en la caja (desde D26 la pulsación da un rechazo visible `ya aplicado`, sin
penalizar). No hay quitar el aliño: una caja mal aliñada se tira al cubo (`cubo-basura.md`).
~~Los cachelos sí se alternan (poner/quitar, con la caja llena, devolviendo la ración al cuenco, D23).~~
*(Superado por D26: los cachelos solo se **ponen**; si ya los lleva, rechazo `ya aplicado`; lo mal hecho
va al cubo.)* No hay niveles de cantidad. Interacción, lados y pegatinas en
`estacion-condimentos.md`. Esta feature fija las reglas de datos, que viven en el núcleo
`RefCounted` `core/seasoning_rules.gd`, y no dependen de dónde esté la caja.

> **Sustituido por D25 (2026-10-10):** los 4 condimentos sueltos (pimentón dulce, pimentón picante,
> sal, aceite), el alternar de cada uno, `paprika_swap` como regla aparte (ahora es el comportamiento
> del único grupo de aliño) y las 4 pegatinas. La regla «solo caja llena» se mantiene (G2 de PUL-090).

## Criterios de aceptación
- **AC1** *(reescrito)* Given una caja llena de pulpo sin aliño, When se aplica el aliño dulce, Then `applied` contiene `SWEET_DRESSING` (y nada más), se emite `seasoned` una vez y no se emite `seasoning_removed`. *Test:* `test_seasoning_rules.gd`.
- **AC2** *(reescrito, sustituye a `paprika_swap`)* Given una caja con aliño dulce, When se aplica el aliño picante, Then `applied` contiene `HOT_DRESSING` y no `SWEET_DRESSING`, se emiten `seasoning_removed(sweet_dressing)` y después `seasoned(hot_dressing)`, una vez cada una y en la misma llamada; nunca hay dos aliños. *Test:* `test_seasoning_rules.gd`.
- **AC3** *(reescrito, sustituye al toggle de sal)* Given una caja con aliño dulce, When se vuelve a aplicar el aliño dulce, Then `applied` no cambia, el resultado es `ALREADY_APPLIED`, no se emite ninguna señal de condimento (silencioso, sin `season_error`) y no hay penalización (no hay quitar). *Test:* `test_seasoning_rules.gd`.
- **AC4 (R3, núcleo)** Given una caja vacía o a medio llenar (fill 0,6), When se aplica cualquier aliño o cachelos, Then se rechaza con `BOX_NOT_FULL` y `applied` no cambia, esté la caja en la mano o en un pasaplatos. *Test:* `test_seasoning_rules.gd`.
- **AC5** *(reescrito)* Given una caja con aliño y cachelos, When se serializa su estado (`BoxContents`), Then contiene exactamente 2 entradas (1 aliño + cachelos); con solo aliño, 1; sin nada, 0. Nunca hay `sal`, `aceite` ni pimentón sueltos. *Test:* `test_box.gd`.
- **AC6** *(reescrito)* Given el nivel, Then el aliño solo se aplica en la estación: 2 dispensadores (aliño dulce, aliño picante) y un cuenco de cachelos; no hay botes (`SeasoningItem`), `SpiceShelf`, bandeja (`Tray`) ni dispensadores sueltos de sal, aceite o pimentón. El pulpo sale de la nevera, no de la estación. *Test:* `test_level_01.gd`.
- **AC7** *(reescrito)* Given una caja con aliño y cachelos aplicados en cualquier orden, When se piden en orden canónico, Then salen como aliño → cachelos (`SeasoningData.sort_order`). *Test:* `test_seasoning_rules.gd`.
- **AC8 (R6, núcleo)** Given el cuenco con 0 raciones, When se repone con 1 cachelo cocido, Then tiene 2 raciones (`cachelos_portions_per_item` = 2); When se repone hasta superar `cachelos_stock_max` (4), Then la reposición que no cabe entera se rechaza y el cuenco no pasa de 4. *Test:* `test_cachelos.gd`. (Sin cambios.)
- **AC10 (D26, cachelos solo se ponen)** Given una caja llena que ya lleva cachelos, When el núcleo recibe «poner cachelos» otra vez, Then el resultado es `ALREADY_APPLIED` (sin quitar, sin señales, el cuenco no recupera la ración); `SeasoningRules.toggle` ya no se usa para cachelos (se retira o queda solo para tests heredados). *Test:* `test_seasoning_rules.gd` + `test_cachelos.gd`.
- **AC9 (D25)** Given el catálogo `data/seasonings/`, Then hay exactamente 3 `SeasoningData` (aliño dulce, aliño picante, cachelos); los dos aliños (`sweet_dressing.tres`, `hot_dressing.tres`, tipos `SWEET_DRESSING` y `HOT_DRESSING`) comparten el grupo de exclusividad `dressing`; y no quedan `.tres` de sal, aceite ni pimentón sueltos. *Test:* test de datos de `data/seasonings/`.

## Datos (`.tres`)
Catálogo de condimentos (`data/seasonings/*.tres`: id, nombre, icono, color, grupo de exclusividad,
`sort_order`; D25: `sweet_dressing.tres`, `hot_dressing.tres` y `cachelos.tres`). Parámetros de la estación en `SeasoningStationData` (ver `estacion-condimentos.md`):
`cachelos_portions_per_item` = 2 y `cachelos_stock_max` = 4 (D23). Se retiran `paprika_swap` y
`salt.tres`, `oil.tres`, `paprika.tres` y `hot_paprika.tres` sueltos.

## Verificación
GUT para AC1–AC5, AC7, AC8 y AC9 (núcleo y datos); AC6 por inspección de escena (test de nivel).

## Preguntas abiertas
1. **Reposición que no cabe entera** (cuenco en 3 con `cachelos_portions_per_item` = 2): se propone
   rechazar (AC8) para no perder media ración en silencio; alternativa, aceptar y topar en 4. Lo
   confirma la ficha de estación «al paso» (PUL-090 §4.4, ficha 2).
2. ~~**Aplicar el mismo aliño sin respuesta.** D25 dice «no hace nada»; si el playtest muestra
   confusión se añade un cue suave, sin penalizar (decisión de gate).~~ **Cerrada por D26**: el
   núcleo sigue devolviendo `ALREADY_APPLIED` sin cambiar la caja ni emitir señales de condimento, pero
   la estación lo traduce en un rechazo visible y sonoro (BLOQUEADO `ya aplicado`, `lenguaje-acciones.md`).
