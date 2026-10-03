# Movimiento e interacción (Must)

**Slug:** movimiento-e-interaccion · **Prototipo:** `PlayerController`, `PlayerHoldSystem`,
`PlayerInteractionController`, `InteractionDetector`, `HighlightController`.

## Descripción
Un personaje se mueve en plano, detecta el objeto interactuable más cercano (resaltado), lo coge,
lo suelta o lo usa. Lleva como máximo un objeto.

## Criterios de aceptación
- **AC1** Given un personaje parado, When se mantiene la dirección derecha durante 1 s, Then se
  desplaza a velocidad `move_speed` (dato, valor inicial 5 m/s ± 0,1) y no atraviesa colisiones.
- **AC2** Given un interactuable a ≤ `interact_range` (dato, 1,5 m) y ninguno más cerca, When el
  jugador pulsa interactuar sin nada en la mano, Then el objeto pasa a la mano en ≤ 1 frame y
  `EventBus.object_picked_up` se emite una vez.
- **AC3** Given un jugador con un objeto en la mano, When pulsa interactuar sobre un espacio libre
  (mesa), Then el objeto queda en la mesa y `object_dropped` se emite una vez.
- **AC4** Given un jugador con un objeto, When intenta coger otro, Then no ocurre nada y la mano no cambia.
- **AC5** Given varios interactuables en rango, When se mueve el personaje, Then solo el más cercano
  está resaltado y el resaltado cambia en ≤ 0,1 s al cambiar el más cercano.

## Datos (`.tres`)
`move_speed`, `interact_range`, `highlight_color`.

## Verificación
GUT para AC2–AC4 (señales y estado de mano); captura para AC5.
