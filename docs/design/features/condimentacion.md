# Condimentación sí/no (Must, D4)

**Slug:** condimentacion · **Prototipo:** `SeasoningItem`, `SpicesSO`, `ISeasonable`.

## Descripción
Sobre la caja llena de pulpo (cortado) se aplican condimentos como decisiones binarias:
pimentón (dulce **o** picante, exclusivos), sal (sí/no), aceite (sí/no) y cachelos (sí/no).
Cada condimento aplicado queda registrado en la caja. No hay niveles de cantidad.

## Criterios de aceptación
- **AC1** Given una caja llena de pulpo, When se aplica pimentón dulce, Then `applied` contiene `PAPRIKA_SWEET` y se emite `seasoning_applied` una vez.
- **AC2** Given una caja con pimentón dulce, When se aplica pimentón picante, Then se rechaza (exclusivos) y `applied` no cambia.
- **AC3** Given una caja con sal, When se aplica sal otra vez, Then `applied` sigue con una sola sal (idempotente).
- **AC4** Given una caja vacía o a medio llenar, When se aplica cualquier condimento, Then se rechaza.
- **AC5** Given una caja con los 4 condimentos posibles (pimentón, sal, aceite, cachelos), When se serializa su estado, Then contiene exactamente 4 entradas.
- **AC6** Given condimentos disponibles, Then el almacén expone exactamente 6 fuentes: pimentón dulce, pimentón picante, sal, aceite, cachelos, pulpo.

## Datos (`.tres`)
Catálogo de condimentos (id, nombre, icono, exclusividad).

## Verificación
GUT para AC1–AC5; AC6 por inspección de escena.
