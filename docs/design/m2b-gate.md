# Puerta humana de M2b: estación de condimentos y planta B

Playtest de los rediseños de M2 (D18): estación de condimentos con pase y lado de condimentar
(`features/estacion-condimentos.md`), pegatinas en caja y ticket, planta B (PUL-061), selección en
la estación (PUL-063) y entrega con paciencia de 80–180 s (PUL-039). Lo verificable por máquina ya
está en `godot/tests/integration/test_m2b_flow.gd` (tres entregas por modo con teclado y detector
reales) y en `docs/evidence/PUL-062/` (partidas con el MCP). Esta sesión la hace **el responsable**:
juega, anota y decide los números abiertos (viven en `.tres`).

Duración estimada: 40 min (cuatro partidas de 5 min y las anotaciones).

## 1. Preparar

```sh
# Desde la raíz del repo:
godot --path godot           # escena principal: el menú
# o el build: tools/export.sh linux && build/linux/pulpasa.x86_64 --resolution 1280x720
```
Conecta los mandos **antes** de pulsar Individual o Local 2P (el reparto se hace al empezar).
Ten a mano un cronómetro o el móvil para el tiempo por comanda.

### Controles
| Acción | J1 teclado | J2 teclado | Mando (Xbox) |
|---|---|---|---|
| Mover | WASD | Flechas | Stick izquierdo / cruceta |
| Interactuar (coger, soltar, cortar, dispensar, entregar) | E | Intro | A |
| Cambiar de personaje (solo Individual) | Q | – | Y |
| Pausa | Esc | Esc | Start |

### La cocina en 30 s
- **Cocina** (arriba, detrás de la barra): nevera, cachelera y dos ollas. **Servicio** (abajo):
  estantería de cajas (pared izquierda) y los cuatro puestos.
- La **estación** es el tramo central de la barra. Desde la cocina (**pase**) se deja/recoge la
  caja en la bandeja, se corta el pulpo sobre ella y se echan cachelos cocidos al cuenco. Desde el
  servicio (**condimentar**) y con la mano vacía se usan los cuatro dispensadores (dulce, picante,
  sal, aceite) y el cuenco; pulsar otra vez quita, y un pimentón sustituye al otro.
- La barra solo se cruza por el hueco de la derecha (rodeo de ~6 m).
- Comprueba la caja comparando su fila de pegatinas con la del ticket: mismo orden y mismos iconos.

## 2. Qué probar

### A. Individual con teclado y luego con mando
1. Menú → **Individual**. Empiezas con el personaje del servicio; el de la cocina está quieto.
2. Juega una partida completa **usando el cambio**: el de la cocina cuece y corta sobre la caja de
   la bandeja; Q/Y; el del servicio coge cajas, condimenta y entrega.
3. Segunda partida **sin cambiar de personaje**, rodeando la barra por el hueco. ¿Cuánto peor?
4. Repite una de las dos con el mando (cruceta + A + Y).

### B. Local 2P con teclado + mando
J1 teclado (WASD + E) en el servicio y J2 mando en la cocina. Una partida completa hablando:
qué caja, qué lleva, si hay cachelos en el cuenco.

### C. Local 2P con dos mandos
Repite B con dos mandos, cambiando los papeles (el que condimentaba ahora cocina).

## 3. Qué anotar

Por partida: entregas, recaudación final, estrellas y comandas caducadas (HUD y game over).
Por comanda (al menos tres por partida): **tiempo** desde que aparece el ticket hasta la entrega.
**Pulsaciones de error**: cada vez que suena el error o algo se sacude en la estación, una raya.

| Tema | Pregunta |
|---|---|
| Tiempo por comanda | ¿Cuántos segundos? ¿Da tiempo con la paciencia de 80–180 s o caducan muchas? |
| Pulsaciones de error | ¿Cuántas y dónde? En especial: al **dejar la caja en la bandeja** desde el servicio, ¿se resalta un dispensador en vez de la bandeja? (hallazgo de esta QA, ver abajo) |
| Cambio de personaje | En Individual, ¿lo usas para el pase o acabas rodeando? ¿Se entiende quién está activo? |
| Pegatinas | ¿Se lee de un vistazo si la caja coincide con el ticket? ¿Se distingue dulce de picante? |
| Coordinación | En Local 2P, ¿el pase obliga a hablar? ¿Alguno se queda esperando sin nada que hacer? |
| Abierta 1: una o dos bandejas | ¿La bandeja única atasca con 3–4 comandas activas? ¿Pedirías la segunda (hueco de la derecha)? |
| Abierta 2: intercambio de pimentón | ¿Se entiende que pulsar el otro pimentón lo sustituye? ¿Molesta? (`paprika_swap`) |
| Abierta 3: rodeo de la barra | En Individual sin cambio, ¿el rodeo castiga demasiado? En Local 2P, ¿se cruza alguien? |
| Abierta 4: raciones de cachelos | ¿Faltan cachelos en el cuenco? ¿Pedirías 2 raciones por olla? (`cachelos_portions_per_item`) |
| `operator_side_only` | ¿Echas de menos condimentar desde el pase? Con `false` los dispensadores funcionan por los dos lados |

### Datos de referencia de la QA (PUL-062)
- **Test automático** (jugador perfecto, sin esperas de reacción): 7–10 s por comanda de caja
  pequeña con el pulpo ya cocido y 15–16 s si hay que cocer otro (5 s de olla), en los dos modos;
  cero pulsaciones de error.
- **Partidas con el MCP** (ritmo lento: cada orden tarda varios segundos en llegar al juego):
  Individual 3 entregas en 207 s, 22 € al final, 4 comandas caducadas mientras se jugaba,
  13 cambios de personaje; Local 2P 3 entregas en 137 s con 1 caducada (luego se dejó correr el
  reloj). Comandas entregadas entre 50 y 140 s desde el ticket.
- **Hallazgo**: con una caja en la mano, delante de la estación por el lado de condimentar y
  desviado 0,2–0,4 m del centro de la bandeja, el detector resalta un dispensador (picante o sal)
  en vez de la bandeja; pulsar da un rechazo (`HAND_BUSY`). Pasó en 5 de 6 intentos de dejar la
  caja (captura `docs/evidence/PUL-062/hallazgo-caja-en-mano-apunta-a-picante.png`). Mira si a
  ritmo humano molesta.

### Números que se pueden tocar sin código
| Qué | Dónde |
|---|---|
| Paciencia de cada comanda (80–180 s) | `data/orders/order_*.tres` (`max_time`) |
| Comandas activas a la vez (4) | `data/orders/order_catalog.tres` (`max_active_orders`) |
| `paprika_swap`, `operator_side_only`, raciones y stock del cuenco, antirrebote | `data/config/seasoning_station.tres` |
| Tiempo de cocción (5 s) | `data/ingredients/octopus.tres`, `cachelos.tres` (`cook_time`) |

Conclusión: **M2b cerrado** / **M2b con ajustes** (lista de `.tres` o fichas nuevas) /
**bloqueado**. Apunta en `docs/design/decisions.md` cada pregunta abierta que quede decidida.
