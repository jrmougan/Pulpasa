# Puerta humana de M3d: simplificación de mecánicas (D25)

Playtest de D25 tras PUL-111..PUL-115: caja única de 6 cortes, aliño de una pulsación con 2
dispensadores, 4 comandas por contenido, 2 cubos de basura y progresión por fases. Lo medible está
en `docs/evidence/PUL-116/` (README con tabla antes/después, JSON y capturas a 1920×1080). Esta sesión
la hace **el responsable**: juega y decide. Unos 25 minutos.

## Lo que ya sabías antes de jugar (medido por el bot, `docs/evidence/PUL-116/README.md`)
| Criterio | Resultado | Estado |
|---|---|---|
| R15 Individual sin cambio, pedido desde cero ≤ 50 m | **54,7 m** la mejor ruta del bot (caja soltada en el suelo junto a las ollas); **45,3 m** sin los 9,4 m de salir de la posición inicial; 60,7 m con la caja en el pasaplatos 04 y 69,6 m en el 01 (en PUL-102: 55,0 / 45,3 / 61,0 / 73,3) | **no cumple con el bot** si se cuenta la salida (por 4,7 m); igual que antes |
| R17 Coop, media de pedidos 2–4 ≤ 4,6 s | **3,05 s** con el flujo adelantado y pasaplatos del oeste (antes 4,09 s); 5,27 s con los del este; **6,17 s** con el protocolo secuencial (el pedido 3 espera 5 s de cocción) | cumple solo con el flujo adelantado y el oeste; pedido 2 secuencial de Coop 3,98 s (65 % de PUL-090) |
| Pulsaciones por comanda (Individual, pedido 1 / 2) | Á feira y Picante **14 / 11**; con cachelos **19 / 12** (antes 13 / 10 y 17 / 10) | +2 cortes y −1 de aliño |
| Recuperación con el cubo (T7) | funcional cumple; informativo: **13,2 s** (puesto 1) y **16,8 s** (puesto 4); con el otro aliño **1,3 s** sin cubo | sin límite fijado: ¿fijamos uno? |
| Umbrales de estrellas 30 / 60 / 90 € | Un bot Individual secuencial sin adelantar recauda **150–195 €** en 300 s (3 estrellas de sobra) | propuesta **40 / 90 / 150 €**, provisional |
| Coop, pedido 1 | 11,2 → **10,2 s** (Á feira); emplatador quieto 6,3 s de 10,2 s | mejora ligera |

Cosas que sabes antes de entrar y no tienes que descubrir:
- El **modelo del rack** sigue mostrando las etiquetas S, M y L (arte pendiente, la caja ya es una sola).
- Los **dos dispensadores de aliño comparten icono** (la guindilla, también en el ticket); solo cambia
  el color y el tapón.
- El **mostrador mide 5,2 m** y solo hay 3 objetivos en 2 m centrales (aliño dulce, aliño picante,
  cuenco).
- El HUD aún dice «Cajas / minuto».
- Con 4 tickets (fase 3) el panel tapa parte del cartel «Pulpa SA» a 1080p.

## Antes de empezar
1. Abre `docs/evidence/PUL-116/ac3-local2p-1080p-fase3-4-tickets-bravo-cachelos.png`,
   `ac3-estacion-mostrador-5-2m-x3-recorte.png` y `ac3-rack-modelo-S-M-L-recorte.png` para saber qué se
   ha visto a 1080p.
2. Juega una ronda en **Individual** y otra en **Local 2P** a pantalla completa (1080p) desde el menú,
   con audio. Una de ellas hasta la fase 3 (200 s) para ver los cachelos.
3. En Individual busca **tu ruta más corta** para una «Á feira» desde cero (incluido soltar la caja en el
   suelo de la cocina, que está permitido) y cuenta metros o pasos: el bot hace 54,7 m (45,3 m sin la
   salida inicial) y 14 pulsaciones. ¿Le ganas? ¿Te sale natural o es un truco?

## Qué mirar y qué responder
### Aliño de una pulsación y estación al paso
| Mira | Pregunta |
|---|---|
| Con la caja **llena** en la mano, pulsar un aliño y luego el otro | ¿Se entiende que la caja ya está lista tras **una** pulsación? ¿Y que el otro aliño **sustituye** y el mismo no hace nada? ¿Te falta una confirmación (sonido o gesto) para saber cuál lleva? |
| Los **iconos de aliño**: dulce y picante usan la misma guindilla (ticket, dispensador y pegatina de la caja) | ¿Distingues «Á feira» de «Picante» en el ticket sin leer el nombre? ¿Y los dos dispensadores? ¿Hace falta un icono distinto o basta el color? |
| El **largo del mostrador (5,2 m) con solo 3 objetivos** | ¿Sobra mostrador? ¿Te hace caminar de más entre aliño y cuenco, o te sobra espacio para dejar cajas? ¿Acortarlo o añadir piezas? |
| Aliño con una caja a medio cortar | El dispensador consume la pulsación y suena `season_error`. ¿Te dice por qué no pasa? |
| Cuenco: cachelos cocidos (una cocción da 2 raciones), con la caja llena alterna cachelos | ¿Distingues 2 de 4 raciones desde la cámara? (pregunta pendiente desde M3c) |

### Caja única
| Mira | Pregunta |
|---|---|
| Rack y caja: **6 cortes** (provisional) y 1 pulpo = 2 cajas | ¿Se corta cómodo o cansa? ¿Más o menos de 6? ¿Notas que el pulpo da para dos? |
| **Modelos del rack y de la caja con S, M y L** (arte aún por rehacer) | ¿Te despista ver tres tallas si solo hay una? Anota qué modelo esperarías |
| Pegatinas de la caja: 1 de aliño + la de cachelos | ¿Lees qué lleva sin acercarte? |

### Cubos de basura
| Mira | Pregunta |
|---|---|
| Un cubo en la cocina (x 2,6, z −3,1) y otro en el servicio junto al rack (x −5,4, z 4,3) | ¿Los encuentras cuando los necesitas? ¿Estorban o los pisas sin querer (con algo en la mano, son objetivo)? |
| Equivócate a propósito: caja con el aliño equivocado frente al puesto | Lo más rápido es pulsar **el otro aliño** (1,3 s, sin cubo). ¿Lo descubres solo? ¿Usas el cubo para otra cosa (pulpo equivocado, cachelos de más, un pulpo sobrante que te estorba)? El bot tarda 13–17 s si rehace la caja entera tirando |
| Tirar sin penalización | ¿Se nota que no cuesta puntos? ¿Te da pena o te parece barato? ¿Falta o sobra el sonido/gesto del cubo? |
| El cubo con la mano vacía no se resalta | ¿Te desconcierta? |

### Fases y comandas
| Mira | Pregunta |
|---|---|
| Fase 1 (0–100 s): 2 puestos y solo «Á feira» | ¿Es monótona o enseña bien? ¿El primer minuto aburre? |
| Fase 2 (100–200 s): 3 puestos y entra «Picante» (paciencia ×0,85) | ¿El salto se nota? ¿Hace falta aviso de cambio de fase? |
| Fase 3 (200–300 s): 4 puestos y entran los cachelos (×0,7) | ¿Quedan solo 100 s para disfrutarlos? ¿Llegan tarde? ¿Se te acumulan comandas caducadas? |
| Los nombres de los tickets («Á feira», «Picante», «Con cachelos», «Bravo cachelos») | ¿Se leen enteros a 1080p y se entiende cada uno? |

### Precios y estrellas
| Mira | Pregunta |
|---|---|
| Precios 8 / 9 / 12 / 13 € (+ hasta 5 € de bonus; −3 € por caducada) | ¿Compensa hacer cachelos (+4 € por ~5 pulsaciones y una olla más)? ¿Eliges las comandas por precio? |
| Estrellas hoy 30 / 60 / 90 € | ¿Con cuánto acabas en Individual y en Local 2P? El bot secuencial hace 150–195 €. Anota tu recaudación y las estrellas que te dieron |

### Recorrido y cooperativo
| Mira | Pregunta |
|---|---|
| Individual sin cambio frente a Individual con `Q` | ¿Cambias de personaje por gusto o por no caminar? |
| Coop (Local 2P): quién hace qué | El emplatador está quieto 6,3 s de los 10,2 s del pedido 1. ¿Alguien espera de más? ¿Descubrís solos «dos cajas por delante y dos pulpos al fuego»? |
| Las 6 marcas de pasaplatos, hueco de la barra y chevrones de entrega | No los toca D25; vuelve a mirarlos con los cubos colocados. ¿Algo nuevo? |

## Qué decidir
Para cada fila: **ok / cambiar / dudas**, y una línea si es «cambiar». Además:
- **R15**: aceptar 54,7 m (o tu ruta) o pedir cambio de nivel (rack, hueco o nevera). Es la tercera vez
  que sale este dato: 78,9 → 55,0 → 54,7.
- **R17**: aceptar el criterio con juego adelantado y el oeste (3,05 s) o pedir más margen (el
  secuencial da 6,17 s por la cocción del pulpo 2).
- **Cubo T7**: ¿fijamos un límite de segundos para rehacer (hoy 13–17 s, puesto 1 / 4)? ¿Mover el cubo? aceptar que el aliño
  equivocado se arregla sin cubo.
- **Umbrales de estrellas**: adoptar 40 / 90 / 150 € o los que salgan de tu recaudación.
- **Cortes de la caja**: dejar 6 o cambiar (`BoxData.presses_to_fill`).
- **Iconos de aliño**: icono distinto para el picante o dejar el color.
- **Mostrador**: acortar los 5,2 m o añadir piezas.
- **Arte**: rehacer el modelo del rack y de la caja sin S, M y L (ficha de arte).
- **Fases**: dejar 100 / 200 s o mover los cachelos antes.
