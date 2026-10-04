# Puerta humana de M2: game feel con dos personajes y mandos

Última comprobación de M2 (`roadmap.md`). Lo verificable por máquina ya está cubierto por
`godot/tests/integration/test_m2_flow.gd` y por las capturas de `docs/evidence/PUL-037/`
(cambio en SINGLE, COOP_2P, pausa por desconexión). Esta sesión la hace **el responsable**: juega,
anota sensaciones y decide si M2 se cierra o qué ajustar (los números viven en `.tres`).

Duración estimada: 30 min (tres partidas cortas y las pruebas sueltas).

## 1. Preparar

```sh
cd godot && godot            # escena principal: el menú
# o el build: tools/export.sh linux && build/linux/pulpasa.x86_64 --resolution 1280x720
```
Conecta los mandos **antes** de pulsar Individual o Local 2P (el reparto se hace al empezar).

### Controles
| Acción | J1 teclado | J2 teclado | Mando (Xbox) |
|---|---|---|---|
| Mover | WASD | Flechas | Stick izquierdo / cruceta |
| Interactuar / coger / soltar | E | Intro | A |
| Cambiar de personaje (solo Individual) | Q | – | Y |
| Pausa | Esc | Esc | Start |

## 2. Qué probar

### A. Individual con teclado + mando (un jugador, dos personajes)
1. Menú → **Individual** con el mando (cruceta + A). El aro amarillo marca el personaje activo y el
   HUD dice «Controlas: P1».
2. Cambia con Q y con Y varias veces seguidas, también pulsando muy rápido (cooldown 0,2 s,
   `input_config.tres`). Mueve con el teclado y con el mando alternando.
3. Deja algo en la mano de un personaje, cambia al otro y vuelve: lo que llevaba sigue ahí.
4. Prepara y entrega una comanda repartiendo el trabajo: uno vigila la olla, el otro corta y
   condimenta.

### B. Local 2P con dos mandos
1. Menú → **Local 2P**. Cada personaje tiene su color de aro (J1 amarillo, J2 azul).
2. Comprueba que cada mando mueve solo a su personaje y que A interactúa con el suyo.
3. Entregad cada uno al menos una comanda: la recaudación del HUD es la misma para los dos.
4. Desconecta el mando de J2 en mitad de la ronda: la partida se pausa con «Mando de J2
   desconectado». Vuelve a conectarlo y reanuda: J2 recupera su personaje.
5. Deja acabar la ronda (o sal y entra): game over → **Reintentar** con A, sin tocar el teclado;
   la partida vuelve a ser Local 2P.

### C. Local 2P con teclado + un mando
Teclado para J1 (WASD + E) y mando para J2. Repite B.2 y B.3. ¿Molesta compartir el teclado?

## 3. Qué anotar

Por cada bloque, una línea de «ok / ajustar / falla» y el porqué. En especial:

| Tema | Pregunta |
|---|---|
| Cambio de personaje | ¿Se entiende al instante quién está activo? ¿El cooldown se nota o estorba? |
| Indicador | ¿Se ve el aro sobre el suelo y bajo los muebles? ¿Se distinguen los dos colores? |
| Movimiento con mando | ¿Zona muerta (0,2) y velocidad (5 m/s) se sienten bien en stick y cruceta? |
| Choques | ¿Los dos personajes se estorban en la cocina? ¿Las salidas son buenas? |
| Cooperativo | ¿Merece la pena el reparto de tareas o uno solo lo hace todo? |
| Desconexión | ¿El aviso se lee bien? (QA: el título queda encima de la fila de tickets) |
| Menús con mando | ¿Se llega a todo sin teclado? ¿El foco inicial está donde se espera? |

Conclusión: **M2 cerrado** / **M2 con ajustes** (lista de `.tres` o fichas nuevas) / **bloqueado**.
Apúntala en `docs/design/decisions.md` si cambia algún número.
