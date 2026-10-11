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

### Ampliado por D26 (2026-10-11): verbo, prompt y objetivo estable
> El contorno ya no basta: cada objetivo muestra **qué hará la pulsación** y el objetivo activo es
> **estable**. Especificación completa (verbos, tabla mano × objetivo, prompt, respuesta) en
> `lenguaje-acciones.md`; aquí solo los criterios de selección.
- **AC5 (reforzado por D26)** El «más cercano» sigue siendo la base, pero el cambio de objetivo activo
  pasa por la **histéresis** de AC6. El resaltado cambia en ≤ 0,1 s cuando el activo deja de ser
  válido; entre dos candidatos válidos solo cambia si el nuevo supera al activo en un 20 %.
- **AC6 (histéresis, D26)** Given un objetivo activo A con puntuación s y un candidato B, When B puntúa
  1,19·s, Then sigue A; When B puntúa 1,21·s, Then B pasa a activo en ≤ 1 frame; When A deja de ser
  válido, Then B pasa a activo aunque puntúe menos de 1,2·s. *Test:* `test_interaction_scoring.gd`
  (= `lenguaje-acciones.md` AC9).
- **AC7 (un objetivo con verbo, D26)** Given cualquier interactuable a ≤ `interact_range` dentro del
  cono, When la pulsación no cambiaría nada y no hay un motivo útil que mostrar, Then no es objetivo (sin
  contorno ni prompt). Given que sí es objetivo, Then muestra su verbo (OK) o su motivo (BLOQUEADO).
  Se acaban los `can_interact` que devuelven `true` y luego no hacen nada (Box, CookingStation, Slot,
  ItemSpawner). *Test:* `test_action_matrix.gd` (= `lenguaje-acciones.md` AC1, AC2 y AC20).
- **AC8 (mano llena sin objetivo, D26)** Given una mano llena y ningún objetivo, Then pulsar suelta al
  suelo delante del personaje (regla vigente de `InteractionComponent`) y el prompt SOLTAR lo anuncia
  antes; si no cabe (barra, pared) el prompt es BLOQUEADO (`ocupado`) y pulsar da 1 rechazo en vez de
  quedarse mudo. *Test:* `test_action_matrix.gd`.

AC4 («al intentar coger otro no ocurre nada») queda **precisado** por D26: con la mano llena un
objeto cogible **no es objetivo** (no se resalta), y pulsar suelta al suelo (AC8). El contorno pasa
a blanco cálido y se dibuja también detrás del personaje (`lenguaje-acciones.md`).

## Datos (`.tres`)
`move_speed`, `interact_range`, `highlight_color` (D26: blanco cálido `#FFF4D6`, antes amarillo),
`hysteresis_margin` (0,20, D26; ver `ActionLanguageData` en `lenguaje-acciones.md`).

## Verificación
GUT para AC2–AC4 y AC6–AC8 (señales y estado de mano); captura para AC5.
