# Cocción del pulpo (Must)

**Slug:** coccion-pulpo · **Prototipo:** `Kitchen` (`KitchenStation`), `KitchenProgress`, `IngredientSO.cookTime`.

## Descripción
La olla recibe pulpo **crudo**; tras `cook_time` queda cocido y vuelve a ser recogible. Solo el
cocido se puede cortar sobre la caja (`corte-pulpo.md`).

## Criterios de aceptación
> La «variante de paridad (sin quemado)» queda **superada** por D17 y por ADR-006 §5 (olla que se pasa,
> implementada; PUL-108). Rigen AC2' y AC6' (abajo) en lugar de AC2 (liberación) y AC6, que se
> conservan tachados como histórico de M0.
- **AC1** Given una olla libre y un jugador con pulpo crudo, When interactúa con la olla, Then la olla queda ocupada, la mano vacía y el progreso empieza en 0 %.
- **AC2** Given una cocción iniciada, When pasan 5,0 s (`cook_time`, dato) de juego, Then el pulpo pasa a `COOKED`, se emite `cooking_finished` una vez y el pulpo cocido queda en la olla disponible para recoger. (~~la olla queda libre~~: sustituido por AC2'.)
- **AC3** Given una cocción en curso, When el juego está en pausa 5 s, Then el progreso no avanza.
- **AC4** Given una olla ocupada, When otro jugador interactúa con otro pulpo crudo, Then se rechaza y el pulpo sigue en su mano.
- **AC5** Given un pulpo ya cocido en la mano, When interactúa con la olla, Then se rechaza.
- ~~**AC6** Given una cocción terminada, When pasan 30 s sin recoger el pulpo, Then sigue `COOKED` y válido.~~ Superado por AC6' (histórico de M0).

## Quemado vigente (`olla-que-se-pasa`, ADR-006 §5)
Sustituye a AC2 (liberación) y AC6:
- **AC2'** Given una cocción terminada, Then el pulpo cocido sigue en la olla y esta permanece **ocupada** hasta que un jugador lo recoja o desecha; entonces queda libre.
- **AC6'** Given un pulpo cocido sin recoger, When pasan `burn_time` s, Then pasa a `BURNT` (ver `olla-que-se-pasa.md`).

## Verbo, estado legible y respuestas (D26)
Verbos de la olla (`lenguaje-acciones.md`, tabla C): COCER con pulpo o cachelos **crudos** y plaza libre;
COGER el cocido listo con la mano vacía; TIRAR el quemado con la mano vacía. Cada plaza muestra un
**anillo** de ≥ 64 px de diámetro y ≥ 8 px de grosor a 1080 de alto.
- **AC4' (precisa AC4, D26)** Given una olla sin plaza libre y un jugador con pulpo crudo, Then la olla muestra BLOQUEADO `ocupado` antes de pulsar y, al pulsar, 1 rechazo; el pulpo sigue en su mano. *Test:* `test_cooking_station.gd` + `test_action_matrix.gd`.
- **AC5' (precisa AC5, D26)** Given un pulpo o cachelos ya cocidos en la mano, Then la olla **no es objetivo** (sin contorno ni prompt; antes «consumía» la pulsación y lo rechazaba en silencio). *Test:* `test_action_matrix.gd`.
- **AC7 (D26, cocción lista)** Given una cocción que llega a `cook_time` (5,0 s), Then el anillo pasa a verde con ✓ y destello (≥ 0,3 s) y suena 1 cue `cook_done` con sample propio (distinto de cualquier otro cue de acción). *Test:* `test_burn.gd`/`test_cooking_station.gd` + `test_feedback_cues.gd`.
- **AC8 (D26, anillo legible)** Given una cocción en curso a 1920×1080 y a 2340×1080, Then el anillo mide ≥ 64 px de diámetro y ≥ 8 px de grosor (a 720 de alto, ≥ 43 px y ≥ 5 px). *Test:* medición del nodo + captura.

## Datos (`.tres`)
`cook_time` (5,0 s; valor del prototipo). Capacidad de la olla: `KitchenData.capacity` en `data/config/kitchen.tres` (D9, M1: 2 plazas, cada una con su progreso; devuelve lo cocido por orden de finalización). Acepta pulpo y cachelos crudos (D10).

## Verificación
GUT con reloj simulado para AC2–AC3, AC2' y AC6' (`test_burn.gd`); AC1/AC4/AC5 por estado.
