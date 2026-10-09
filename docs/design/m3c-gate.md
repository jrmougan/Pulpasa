# Puerta humana de M3c: rediseño de estaciones

Playtest del rediseño de D23 (línea de condimentos al paso, cortes 4/6/10, 6 pasaplatos, zona de
entrega iluminada, hueco a x 3,5, cuenco de 2 raciones por cachelo) tras PUL-097..PUL-101. Lo medible
está en `docs/evidence/PUL-102/` (tabla antes/después, hallazgos y capturas). Esta sesión la hace **el
responsable**: juega y decide. Unos 25 minutos.

## Lo que ya sabes antes de jugar (medido por el bot, `docs/evidence/PUL-102/README.md`)
| Criterio | Resultado | Estado |
|---|---|---|
| R15 Individual sin cambio, pedido S desde cero ≤ 50 m | 78,9 m → **63,7 m** (pasaplatos al este del hueco) o 74,4 m (junto al rack) | **no cumple** |
| R17 Coop, media de pedidos 2–4 ≤ 4,6 s | **4,31 s** con el bot que adelanta cajas y ollas; 7,33 s con el protocolo secuencial de PUL-090 | cumple solo con juego adelantado |
| Pulsaciones del pedido L (desde cero) | 29 → 19 | cumple (estimado 19) |
| Pedido 2 con cachelos (Coop) | 13,2 s → 5,5 s | mejora fuerte |
| Coop, pedido 1 | 10,5 s → 11,5 s (S) | empeora ligeramente (+1 s) |

Dos decisiones que te tocan por esos números:
- **R15**: ¿se acepta 63,7 m (−19 %) como suficiente para Individual sin cambio, o se mueve el rack,
  el hueco o la nevera? La mayor parte son dos tramos de ≈ 10 m (rack ↔ hueco) y dos cruces del hueco.
- **R17**: ¿basta que se cumpla con juego adelantado (dos cajas por delante, dos pulpos al fuego)? Un
  jugador nuevo hará el protocolo secuencial (7,3 s de media, el pedido 3 espera 5 s de cocción).

## Antes de empezar
1. Abre `docs/evidence/PUL-102/ac1-cuenco-2-vs-4-raciones.png` y
   `docs/evidence/PUL-102/ac3-individual-ticket-recortado-chevrones.png` para saber qué se ha visto
   a 1280×720.
2. Juega una ronda en **Individual** y otra en **Local 2P** a pantalla completa (1080p) desde el menú,
   con audio.
3. Juega con la misma prueba que el bot: un pedido S desde cero (rack → pasaplatos → nevera → olla →
   cortar en el pasaplatos → dispensadores con la caja en la mano → zona de entrega) y luego otro con
   el pulpo sobrante.

## Qué mirar y qué responder
### Estación al paso y cuenco
| Mira | Pregunta |
|---|---|
| Cuenco con **2** y con **4** raciones (hazlo con cachelos cocidos: una cocción da 2) | ¿Distingues 2 de 4 desde la cámara sin acercarte? ¿Sabes cuántas raciones quedan antes de pulsar? Si no, ¿prefieres un contador, otro modelo por ración o aceptar la diferencia pequeña? |
| Dispensadores con la caja en la mano | ¿Se entiende que ya no hay bandeja y que hay que quedarse delante de cada bote con la caja? ¿Pulsas el bote que quieres a la primera? |
| Cuenco sin cachelos en la mano y sin caja | ¿Te desconcierta que no se resalte (no es objetivo)? |
| Alternar cachelos en la caja con el cuenco vacío o lleno | ¿El rechazo (`season_error`, sacudida) te dice por qué no pasa? |

### Cortar en el pasaplatos y R11
| Mira | Pregunta |
|---|---|
| Cortar 4 / 6 / 10 veces (S / M / L) | ¿La diferencia de cortes se nota como diferencia de pedido o solo cansa (la L)? |
| **R11 soltar frente a la barra**: con una caja o un pulpo en la mano, pulsa interactuar frente a la barra, fuera de los 6 pasaplatos y de la estación | La pulsación se consume y la mano no cambia. ¿Entiendes por qué no suelta? ¿Esperabas que se soltara al suelo? ¿Echas de menos un aviso (sonido o sacudida) al intentarlo? |
| Las 6 marcas de pasaplatos (3 al oeste, 3 al este del hueco) | ¿Las reconoces a primera vista como «sitio para dejar»? ¿Usas los del lado de la nevera o los del lado del hueco? ¿Te estorban en el camino? |
| Dejar el sobrante de pulpo en un pasaplatos | ¿Lo encuentras luego sin buscar? ¿O preferirías llevarlo en la mano? |

### Recorrido y hueco
| Mira | Pregunta |
|---|---|
| Rodear la barra por el hueco (x 3,5, 1,4 m) | ¿Se siente 6–10 m o largo? ¿Se entiende por dónde pasar o dudas? ¿Te engancha con los pasaplatos del este? |
| Individual sin cambio frente a Individual con `Q` | ¿Cambias de personaje por gusto o por no caminar? ¿El cambio sigue siendo mejor que rodear? |

### Ticket y tamaño de caja
| Mira | Pregunta |
|---|---|
| **Ticket recortado**: «Pulpo Individ…» (212 px; «Pulpo Familiar» y «Pulpo Doble» caben) | ¿Se entiende cuál es la comanda sin ver el nombre entero? ¿Te basta la silueta y la letra S/M/L? ¿Hace falta un nombre corto en `RecipeData` (p. ej. «Individual»)? |
| Silueta y letra de talla en ticket y en el rack | ¿Coges la caja del tamaño correcto sin mirar dos veces? |

### Entrega y zona iluminada
| Mira | Pregunta |
|---|---|
| **Chevrones de la zona de entrega**: apuntan hacia la cocina (arriba en pantalla) | La zona está entre la barra y el kiosco. ¿Entiendes que hay que entrar en la marca, o esperarías que apuntara al kiosco? ¿Te parecen una flecha de «ve allí» o de «vuelve a la cocina»? Decisión: dejar como está o girar los chevrones hacia el kiosco (PUL-096) |
| La zona se enciende con el color del puesto a ≤ 2 m con la caja correcta | ¿Se enciende cuando esperas? ¿Lo ves con otra comanda delante? |
| Entregar entrando en la zona sin pulsar y también con E frente al puesto | ¿Cuál usas? ¿Entregas sin querer al cruzar la zona de otro puesto con la caja correcta? |
| Color del toldo, franja del ticket y zona | ¿Casas comanda, puesto y zona sin pensar? |

### Cooperativo (Local 2P)
| Mira | Pregunta |
|---|---|
| Emplatador y cocinero a la vez | ¿Sabéis quién hace qué? ¿Alguien espera más de lo que le toca? El bot mide al emplatador quieto el 57 % del pedido 1 (6,6 s de 11,5 s). |
| Pasaplatos del medio entre los dos | ¿Os pisáis en la barra o en el hueco? |
| Dos cajas por delante y dos pulpos al fuego | ¿Lo descubrís solos? Si no, ¿qué indicación lo diría? |

## Qué anotar
Para cada fila: **ok / cambiar / dudas**, y una línea si es «cambiar». Además:
- R15: aceptar 63,7 m o pedir cambio de nivel (rack, hueco o nevera).
- R17: aceptar el criterio con juego adelantado o pedir más margen.
- Cuenco 2 vs 4: contador, otro modelo o dejar.
- Ticket: nombre corto en `RecipeData` o dejar el recorte.
- Chevrones de entrega: dejar o girarlos hacia el kiosco.
- R11: añadir aviso al soltar frente a la barra o dejar como está.
- Hallazgo 2 (`fill_per_press` 0.16666667, latente): confirmar que lo cubre PUL-104 antes de alpha.

