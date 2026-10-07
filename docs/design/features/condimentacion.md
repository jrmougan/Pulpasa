# Condimentación sí/no (Must, D4, D18 modificada por D23)

**Slug:** condimentacion · **Prototipo:** `SeasoningItem`, `SpicesSO`, `ISeasonable` (los botes ya
no se portan, D18).

## Descripción
Sobre la caja llena de pulpo (cortado) se aplican condimentos como decisiones binarias:
pimentón (dulce **o** picante, exclusivos), sal (sí/no), aceite (sí/no) y cachelos (sí/no, cocidos
en la olla, D10). Cada condimento aplicado queda registrado en la caja. No hay niveles de cantidad.

Desde D18 los condimentos se aplican **solo en la estación de condimentos** y se pueden **quitar**:
cada condimento se alterna (sí ↔ no). **Desde D23** la caja no se deja en la estación: se lleva
**llena en la mano** y se pulsa cada dispensador (línea «al paso»). Interacción, lados y
distintivos en `estacion-condimentos.md`. Esta feature fija las reglas de datos, que viven en el
núcleo `RefCounted` `core/seasoning_rules.gd`, y no dependen de dónde esté la caja.

> **Sustituido por D23:** «la caja se deja en la estación» (D18). La regla «solo caja llena» (AC4)
> se mantiene: G2 de PUL-090 eligió «no» a condimentar cajas a medio cortar.

## Criterios de aceptación
- **AC1** Given una caja llena de pulpo, When se aplica pimentón dulce, Then `applied` contiene `PAPRIKA_SWEET` y se emite `seasoned` una vez. *Test:* `test_seasoning_rules.gd`.
- **AC2** Given una caja con pimentón dulce, When se aplica pimentón picante, Then la caja lleva picante y no dulce (`paprika_swap` = true en `SeasoningStationData`): nunca hay dos condimentos del mismo grupo de exclusividad. Con `paprika_swap` = false se rechaza y `applied` no cambia. *Test:* `test_seasoning_rules.gd`.
- **AC3** Given una caja con sal, When se alterna la sal, Then la caja deja de llevar sal y se emite `seasoning_removed` una vez; When se alterna otra vez, Then vuelve a llevar una sola sal (nunca dos). *Test:* `test_seasoning_rules.gd`.
- **AC4 (R3, núcleo)** Given una caja vacía o a medio llenar (fill 0,6), When se aplica cualquier condimento, Then se rechaza con `BOX_NOT_FULL` y `applied` no cambia, esté la caja en la mano o en un pasaplatos. *Test:* `test_seasoning_rules.gd`.
- **AC5** Given una caja con los 4 condimentos posibles (pimentón, sal, aceite, cachelos), When se serializa su estado (`BoxContents`), Then contiene exactamente 4 entradas. *Test:* `test_box.gd`.
- **AC6** Given el nivel, Then los condimentos solo se aplican en la estación: 4 dispensadores (pimentón dulce, pimentón picante, sal, aceite) y un cuenco de cachelos; no hay botes (`SeasoningItem`), `SpiceShelf` ni bandeja (`Tray`). El pulpo sale de la nevera, no de la estación. *Test:* `test_level_01.gd`.
- **AC7** Given una caja con condimentos aplicados en cualquier orden, When se piden en orden canónico, Then salen como pimentón → sal → aceite → cachelos (`SeasoningData.sort_order`). *Test:* `test_seasoning_rules.gd`.
- **AC8 (R6, núcleo)** Given el cuenco con 0 raciones, When se repone con 1 cachelo cocido, Then tiene 2 raciones (`cachelos_portions_per_item` = 2); When se repone hasta superar `cachelos_stock_max` (4), Then la reposición que no cabe entera se rechaza y el cuenco no pasa de 4. *Test:* `test_cachelos.gd`.

## Datos (`.tres`)
Catálogo de condimentos (`data/seasonings/*.tres`: id, nombre, icono, color, grupo de exclusividad
y `sort_order`). Parámetros de la estación en `SeasoningStationData` (ver
`estacion-condimentos.md`): con D23, `cachelos_portions_per_item` = 2 y `cachelos_stock_max` = 4.

## Verificación
GUT para AC1–AC5, AC7 y AC8 (núcleo); AC6 por inspección de escena (test de nivel).

## Preguntas abiertas
1. **Reposición que no cabe entera** (cuenco en 3 con `cachelos_portions_per_item` = 2): se propone
   rechazar (AC8) para no perder media ración en silencio; alternativa, aceptar y topar en 4. Lo
   confirma la ficha de estación «al paso» (PUL-090 §4.4, ficha 2).
