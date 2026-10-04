# Condimentación sí/no (Must, D4, D18)

**Slug:** condimentacion · **Prototipo:** `SeasoningItem`, `SpicesSO`, `ISeasonable` (los botes ya
no se portan, D18).

## Descripción
Sobre la caja llena de pulpo (cortado) se aplican condimentos como decisiones binarias:
pimentón (dulce **o** picante, exclusivos), sal (sí/no), aceite (sí/no) y cachelos (sí/no, cocidos
en la olla, D10). Cada condimento aplicado queda registrado en la caja. No hay niveles de cantidad.

Desde D18 (playtest de M2) los condimentos se aplican **solo en la estación de condimentos** y se
pueden **quitar**: cada condimento se alterna (sí ↔ no). La interacción, la coordinación en coop e
Individual y los distintivos de la caja están en `estacion-condimentos.md`. Esta feature fija las
reglas de datos, que viven en un núcleo `RefCounted` de `core/`.

## Criterios de aceptación
- **AC1** Given una caja llena de pulpo, When se aplica pimentón dulce, Then `applied` contiene `PAPRIKA_SWEET` y se emite `seasoned` una vez.
- **AC2** Given una caja con pimentón dulce, When se aplica pimentón picante, Then la caja lleva picante y no dulce (intercambio, `paprika_swap` = true en `SeasoningStationData`): nunca hay dos condimentos del mismo grupo de exclusividad. Con `paprika_swap` = false se rechaza y `applied` no cambia.
- **AC3** Given una caja con sal, When se alterna la sal, Then la caja deja de llevar sal y se emite `seasoning_removed` una vez; When se alterna otra vez, Then vuelve a llevar una sola sal (nunca dos).
- **AC4** Given una caja vacía o a medio llenar, When se aplica cualquier condimento, Then se rechaza.
- **AC5** Given una caja con los 4 condimentos posibles (pimentón, sal, aceite, cachelos), When se serializa su estado (`BoxContents`), Then contiene exactamente 4 entradas.
- **AC6** Given el nivel, Then los condimentos solo se aplican en la estación: 4 dispensadores (pimentón dulce, pimentón picante, sal, aceite) y un cuenco de cachelos; no hay botes (`SeasoningItem`) ni `SpiceShelf`. El pulpo sale de la nevera, no de la estación.
- **AC7** Given una caja con condimentos aplicados en cualquier orden, When se piden en orden canónico, Then salen como pimentón → sal → aceite → cachelos (`SeasoningData.sort_order`).

## Datos (`.tres`)
Catálogo de condimentos (`data/seasonings/*.tres`: id, nombre, icono, color, grupo de exclusividad
y, nuevo, `sort_order`). Parámetros de la estación en `SeasoningStationData` (ver
`estacion-condimentos.md`).

## Verificación
GUT para AC1–AC5 y AC7 (núcleo); AC6 por inspección de escena (test de nivel).
