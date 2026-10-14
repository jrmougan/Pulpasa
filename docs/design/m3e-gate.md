# Puerta humana de M3e: lenguaje de acciones y móvil (D26, D27)

Playtest de D26 (verbos, prompt, ninguna pulsación muda, simplificaciones, estado legible, iconografía,
perfil móvil) y D27 (botones táctiles en fila y zona de botones anclada a la safe area), tras PUL-121..138.
Puerta de `roadmap.md`: «Playtest humano del lenguaje de acciones en PC y, cuando haya export, en
teléfono». Lo medible está en `docs/evidence/PUL-152/README.md` (recaptura vigente, `main` en `039c737`)
y en la QA de D26 (`docs/backlog/PUL-132-qa-de-d26.md`, sección Evidence: 58 combinaciones sin
pulsación muda y la guía breve de la que parte esta; capturas en `docs/evidence/PUL-132/`). Esta sesión la hace
**el responsable**: juega y decide.

Dos sesiones (pregunta 2 de PUL-150): **PC ahora** (unos 30 min) y **teléfono** cuando haya APK
(PUL-151, bloqueada) o build web en el teléfono (PUL-153, pendiente de tu sí; unos 15 min).

## Lo que ya sabías antes de jugar
Medido por el bot. Cifras de PUL-152 (vigentes) salvo la primera fila (PUL-132 AC1). «A 1080» = px a
1080 de alto; «táctil» = perfil móvil a 2340×1080 con la safe area de diseño (132 / 0 / 132 / 63).

| # | Medida | Valor | Estado |
|---|---|---|---|
| 1 | Pulsaciones mudas (mano × objetivo en `level_01` real, `test_d26_no_mute_press.gd`) | **0 de 58** combinaciones; 1 respuesta y 1 cue por pulsación, también con 2 rechazos a ~0,1 s | OK |
| 2 | Icono / placa del prompt | 64 / 80 px a 1080 (48 / 60 a 720) | OK |
| 3 | Icono de motivo / aspa | 32 / 24 px a 1080 | OK |
| 4 | Botón de acción, diámetro / zona táctil / centro | 180 / 204 px; (2070, 879) en táctil | OK |
| 5 | Botón de cambiar en fila (D27.1): diámetro / hueco / bordes inferiores | 120 px / 24 px / 0 px de diferencia; centro (1896, 909) | OK |
| 6 | Zona de botones de la cámara (D27.2) | x ≥ 1818, y ≥ 777 en táctil (x ≥ 1530, y ≥ 840 a 1920×1080 sin safe) | OK |
| 7 | Stick: base / radio | 300 / 150 px | OK |
| 8 | Texto mínimo | 36 px en táctil; en PC el HUD sigue en 19,5 px a 1080 (sin cambios por diseño, CT AC21) | OK en táctil |
| 9 | Escala de cámara (px por metro / personaje de 1,6 m) | 121,6 / 194,5 en táctil; 66,8 / 106,9 en PC | OK |
| 10 | Anillo de cocción: trazo / diámetro; borde superior con el activo en la fila trasera (H-01) | 8 / 64 px; 267,2 px en táctil (en PUL-132: −65, fuera de pantalla) | OK |
| 11 | Aro del activo / del inactivo (H-02) | 10 / 2,5 px a 1080 en táctil y PC (en PUL-132: 4,6 en móvil) | OK |
| 12 | Contador de corte: barra / numeral | 16,7 / 68,9 px en táctil; 9,2 / 37,8 en PC | OK |
| 13 | Muesca del cuenco | 24 px a 1080 | OK |
| 14 | 4 tickets: ancho / hueco / banda superior; solapes con stick y botones | 380 / 16 / 174 px; 0 solapes | OK |
| 15 | Caso 09 (contador del pasaplatos bajo los botones) con safe area **nula** | **0 px** en las 12 vistas, también a 800×370 (umbral ≤ 8) | OK |
| 16 | Caso 09 con la safe area **de diseño** (63 px abajo) | **6,6 px** (activo en z −3,1) y **35,0 px** (z −3,4) a 1080; 2,2 / 12,0 a 800×370; pasaplatos 04-06 | Limitación (D27.3) |
| 17 | Game over sin «cajas/minuto» (H-03) | ningún texto | OK |

Cosas que sabes antes de entrar y no tienes que descubrir:
- **D27.3 es una limitación aceptada**: con safe area inferior, el contador de los pasaplatos 04-06 entra
  en la zona de botones si el activo está pegado al norte de las ollas. Los 35 px son del rectángulo
  conservador del contador; la barra que se ve acaba hacia y ≈ 740, por encima de la zona (777) y del
  disco de acción (789). Con los discos visibles: 0 px en z −3,1 y 23 px en z −3,4.
- **Las cifras de ADR-005 D27.3 (21-51 px) y el «residuo de 6,4 px» de D27 están inflados** (H-05 de
  PUL-152): se midieron con la safe area del sistema de un escritorio Linux con panel de 32 px. Las de
  verdad son las filas 15 y 16. Corregir la ADR es pregunta tuya (P10).
- **H-05 en tu propia partida**: si juegas en ventana en Linux con panel, el juego aplica la safe area
  del sistema: en escritorio los tickets bajan ~31,5 px y en `--touch` la pausa baja y la banda superior
  mide 205,5 px. No es un fallo nuevo: anótalo si te molesta, no lo cuentes como KO del lenguaje.
- **No hay export a teléfono**: PUL-151 (APK) bloqueada por toolchain; PUL-153 (web en el teléfono)
  espera tu respuesta. En PC el perfil táctil se fuerza con `--touch` y la safe area es la del sistema
  (no hay bandera para simular la de diseño: solo la usan los scripts de captura).
- **Con ratón no se maneja el perfil táctil**: `emulate_touch_from_mouse` está desactivado (lo exige la
  verificación de `controles-tactiles.md`). En `--touch` el teclado sigue funcionando y no oculta los
  controles: sirve para ver cámara, UI escalada y el icono del botón de acción, no para tocar.
- **Local 2P sigue siendo de PC/mando** (D26.8): el menú táctil solo ofrece Individual.
- Las capturas no tienen sonido: los cues (D26.3) solo se juzgan jugando.

## Antes de empezar
1. Abre estas capturas para saber qué se ha visto:
   `docs/evidence/PUL-152/1920x1080-desktop-01-vista-general.jpg`,
   `docs/evidence/PUL-152/2340x1080-touch-02-stick-activo-y-botones.jpg` y
   `docs/evidence/PUL-152/2340x1080-caso09-diseno-oeste-z3_4.jpg` (D27.3).
2. **Escritorio**: `godot --path godot --fullscreen` desde la raíz del repositorio, con audio. Juega
   desde el menú una ronda en **Individual** (300 s, hasta la fase 3 para ver los cachelos) y otra en
   **Local 2P**. Teclas: J1 WASD + `E` (interactuar) + `Q` (cambiar de personaje, solo en Individual);
   J2 flechas + `Intro` (interactuar; J2 no cambia de personaje); pausa `Esc`.
3. **Perfil táctil en PC**: `godot --path godot --resolution 1920x1080 -- --touch` (los argumentos tras
   `--` son del juego). Unos minutos con teclado: menú solo con Individual, cámara que sigue al activo,
   botones en fila, icono del botón de acción. Si tienes portátil o monitor **táctil**, juega aquí la
   ronda táctil; si no, esa parte espera al teléfono (P13).
4. Ten a mano la plantilla de «Qué medir y cómo anotar» y un cronómetro.

## Qué mirar y qué responder (PC, ~29 min)
Cada fila: **ok / cambiar / dudas** y una línea si no es ok. Entre corchetes, el punto de D26/D27.

### A. Verbos y prompt [D26.1, D26.2] (~5 min)
| Mira | Captura | Pregunta |
|---|---|---|
| El icono sobre el objetivo **antes** de pulsar en una comanda completa (coger, cocer, cortar, aliñar, entregar) | `docs/evidence/PUL-152/1920x1080-desktop-03-prompt-ok-coger.jpg` | ¿Sabes qué va a pasar antes de pulsar? ¿Algún verbo te sobra o no lo reconoces? |
| Las 8 siluetas (COGER, SOLTAR, COCER, CORTAR, ALIÑAR DULCE, ALIÑAR PICANTE, CACHELOS, TIRAR) | `docs/evidence/PUL-123/contact_sheet_64px_gray.png` | ¿Las distingues sin color a 64 px? ¿Confundes alguna pareja (COGER/SOLTAR, los dos aliños)? |
| Prompt BLOQUEADO: ámbar, aspa y motivo (aliña con la caja a medias) | `docs/evidence/PUL-152/1920x1080-desktop-04-prompt-bloqueado-caja-a-medias.jpg` | ¿Entiendes el motivo sin leer nada? ¿Qué motivo no entendiste? Cuéntalos (plantilla) |
| SOLTAR al suelo con la mano llena y sin objetivo | `docs/evidence/PUL-131/desktop_1920x1080_2_suelo_soltar.png` | ¿Ves dónde caerá? ¿Te ha pasado soltar sin querer cerca de una estación que no admite lo que llevas? Cuéntalo (P7) |
| Dispensador desde el **lado de pase** (al otro lado de la barra) | `docs/evidence/PUL-152/1920x1080-desktop-01-vista-general.jpg` | Hoy no es objetivo: no sale nada. ¿Lo intentaste? ¿Echaste de menos un BLOQUEADO «otro lado»? (P8) |

### B. Ninguna pulsación muda [D26.3] (~5 min)
| Mira | Captura | Pregunta |
|---|---|---|
| Provoca rechazos: cortar con pulpo crudo, 7.º corte, el mismo aliño dos veces, caja a medias en el cuenco, pulpo en una olla llena | `docs/evidence/PUL-152/1920x1080-desktop-04-prompt-bloqueado-caja-a-medias.jpg` | ¿Cada pulsación hace algo (salto o sacudida)? ¿Suena siempre el mismo cue de error, una vez? ¿Alguna te pareció muda? |
| Cues propios: tirar (cubo), desechar quemado, cocción lista, aviso de quemado, caja llena, cambio de personaje | `docs/evidence/PUL-152/1920x1080-desktop-09-aviso-de-quemado.jpg` | ¿Distingues los sonidos sin mirar? ¿Alguno molesta o se repite de más? |

### C. Objetivo estable [D26.4] (~2 min)
| Mira | Captura | Pregunta |
|---|---|---|
| Entre dos objetivos cercanos (los dos dispensadores, olla y pasaplatos), muévete despacio y pulsa | `docs/evidence/PUL-127/prompts_station_1920x1080.png` | ¿El prompt salta de uno a otro sin que te muevas? ¿Pulsaste el que no querías? |

### D. Simplificaciones [D26.5] (~5 min)
| Mira | Captura | Pregunta |
|---|---|---|
| El **cuenco solo pone** cachelos; con la caja que ya los lleva sale BLOQUEADO «ya lleva» | `docs/evidence/PUL-152/1920x1080-desktop-05-cuenco-2-raciones.jpg` | ¿Echas de menos quitar? ¿Vas al cubo cuando te equivocas? |
| **Entrega solo por zona**: entra en la zona del puesto con la caja que coincide; prueba también con una que no | `docs/evidence/PUL-152/1920x1080-desktop-11-zona-de-entrega-encendida.jpg` | ¿Entiendes que no hay que pulsar? ¿Intentaste pulsar en el puesto? ¿Entregaste sin querer al cruzar otra zona? |
| **Mantener `E` para cortar**: 6 cortes cada 0,2 s y para; contador N/6 sobre la caja | `docs/evidence/PUL-152/1920x1080-desktop-06-contador-3-de-6.jpg` | ¿Lo descubres solo o sigues pulsando? ¿El ritmo de 0,2 s es cómodo? |

### E. Estado legible en el mundo [D26.6] (~4 min)
| Mira | Captura | Pregunta |
|---|---|---|
| Anillo de cocción: cociendo, listo (check) y aviso de quemado (ámbar/rojo, ≥ 3 s antes) | `docs/evidence/PUL-152/1920x1080-desktop-08-anillo-listo.jpg` | ¿Sabes cuándo sacar sin mirar fijamente la olla? ¿Te da tiempo con el aviso? |
| Raciones del cuenco (muescas, 2 frente a 4) | `docs/evidence/PUL-126/bowl_stock_2.png` | ¿Distingues 2 de 4 raciones desde la cámara? (pendiente desde M3c) |
| Aro del activo (sólido, ▼) frente al del inactivo | `docs/evidence/PUL-152/1920x1080-desktop-10-aros-activo-e-inactivo.jpg` | En Individual, tras pulsar `Q`, ¿sabes al instante a quién mueves? |

### F. Iconografía [D26.7] (~2 min)
| Mira | Captura | Pregunta |
|---|---|---|
| Picante (guindilla con llama) y dulce (pimentonera) en dispensador, ticket y pegatina | `docs/evidence/PUL-126/tickets_stickers.png` | ¿Distingues «Á feira» de «Picante» sin leer el nombre ni fiarte del color? |
| Rack y caja sin S/M/L; HUD sin «Cajas / minuto» | `docs/evidence/PUL-123/rack_in_game.png` | ¿Te falta o sobra algo en el HUD? |

### G. Local 2P y perfil táctil en PC [D26.8, D27.1, D27.2, D27.3] (~6 min)
| Mira | Captura | Pregunta |
|---|---|---|
| Local 2P: dos prompts con marcador de jugador; apuntad los dos al mismo objetivo | `docs/evidence/PUL-127/local_2p_two_prompts_1920x1080.png` | ¿Cada uno sabe cuál es su prompt? ¿Os estorban lado a lado? |
| `--touch`: menú solo con Individual, UI escalada (texto ≥ 36 px), tickets y HUD | `docs/evidence/PUL-152/2340x1080-touch-01-vista-general.jpg` | ¿Se lee todo? El tamaño real se juzga en el teléfono (T4); aquí mira composición y que nada se tape |
| `--touch`: botones **en fila** (cambiar a la izquierda de acción, bordes inferiores alineados) y el icono del botón de acción cambiando con el objetivo (gris, blanco, ámbar) | `docs/evidence/PUL-152/2340x1080-touch-02-stick-activo-y-botones.jpg` | ¿El botón de acción enseña el mismo verbo que el prompt del mundo? ¿Los botones tapan demasiado mundo? |
| `--touch`: la cámara sigue al activo y no deja contadores ni anillos bajo la zona de botones (safe nula) | `docs/evidence/PUL-152/2340x1080-caso09-nula-oeste-z3_4.jpg` | Corta en los pasaplatos 04-06 con el activo al norte de las ollas: ¿ves el contador? |
| D27.3 (solo captura en PC): el mismo caso con la safe area de diseño | `docs/evidence/PUL-152/2340x1080-caso09-diseno-oeste-z3_4.jpg` | ¿Te parece aceptable que la barra del contador quede pegada a la zona de botones? (P9; la prueba real es en el teléfono, bloque T6) |
| Si tienes pantalla táctil: stick y acción a la vez | `docs/evidence/PUL-128/1920x1080_stick_and_press.png` | Como el bloque T1 del teléfono. Si no la tienes, deja «dudas: sin pantalla táctil» |

## Parte de teléfono (condicionada a PUL-151 o PUL-153, ~15 min)
Solo cuando haya APK (PUL-151) o build web servido en red local (PUL-153). Una ronda de 300 s en
Individual, en apaisado, solo con toques. El web no comprueba safe area real, botón Atrás, pantalla
encendida, háptica ni muesca (tabla de PUL-153 AC4): con web, esas filas quedan «dudas: web».

| Bloque | Mira | Captura de referencia | Pregunta |
|---|---|---|---|
| T1 Stick y acción a la vez [D26.8] (~3 min) | Pulgar izquierdo en el stick y derecho en acción; pasa el dedo del stick por encima del botón; mantén acción para cortar | `docs/evidence/PUL-152/2340x1080-touch-02-stick-activo-y-botones.jpg` | ¿Los dos a la vez sin perder ninguno? ¿El dedo del stick pulsa el botón? ¿El stick nace donde tocas? |
| T2 Cámara que sigue y flecha de borde [D26.8] (~3 min) | Cambia de personaje con el botón; aléjate del inactivo hasta que salga de cuadro | `docs/evidence/PUL-134/2340x1080-despues-01-flecha-inactivo-bajo-la-banda.jpg` | ¿La cámara marea o llega tarde (0,35 s)? ¿La flecha te lleva al otro? |
| T3 Ciclo de vida [D26.8] (~2 min) | Bloquea la pantalla, cambia de app y pulsa Atrás en plena ronda; deja la partida 2 min sin tocar | `docs/evidence/PUL-122/pause_touch_2340x1080.png` | ¿Queda en pausa y no se reanuda sola? ¿Se apagó la pantalla? |
| T4 Legibilidad a 36 px [D26.8] (~3 min) | Tickets, HUD, pausa y game over a distancia de uso | `docs/evidence/PUL-152/2340x1080-touch-12-pausa.jpg` | ¿Lees los tickets sin acercarte? ¿El texto se queda pequeño? (P4) |
| T5 Háptica [D26.8] (~1 min) | Un éxito y un rechazo seguidos | `docs/evidence/PUL-152/2340x1080-touch-04-prompt-bloqueado-caja-a-medias.jpg` | ¿Notas la diferencia entre 20 ms y 20 + 20 ms? ¿Molesta? (P3) |
| T6 D27.3 en el teléfono [D27.2, D27.3] (~3 min) | Anota la safe area inferior de tu teléfono (PUL-151 la registra); corta en los pasaplatos 04-06 con el activo pegado al norte de las ollas | `docs/evidence/PUL-152/2340x1080-caso09-diseno-este-z3_4.jpg` | ¿El contador queda bajo el pulgar o el botón? ¿Te impidió saber cuántos cortes llevabas? (P9). Mira también el borde superior si tu teléfono tiene muesca (P6) |

## Qué medir y cómo anotar
Copia esta plantilla en `docs/evidence/PUL-150/resultados-pc.md` (se crea en la sesión; `resultados-telefono.md` para la
parte de teléfono) o dicta las respuestas al coordinador.

```
Sesión: PC | teléfono (APK / web, modelo, safe area inferior en px si se conoce)
Fecha:            Duración total (min):
Ronda Individual: recaudación __ €, estrellas __ / 3
Ronda Local 2P:   recaudación __ €, estrellas __ / 3
Pulsaciones que no entendí (no supe qué iba a pasar o por qué no pasó): __
Veces que solté algo al suelo sin querer: __
Bloque A..G / T1..T6, fila: ok | cambiar | dudas — una línea si no es ok
```

Recaudación y estrellas solo se anotan: los umbrales y el balance son de M4 (PUL-141).

### Resultado del gate
(Lo rellena el coordinador tras la sesión: frase del responsable, tabla «Fila del gate | Resultado» y
decisiones que salgan a `decisions.md`.)

## Qué decidir
Además de ok / cambiar / dudas por fila, estas preguntas (P1-P9 son las abiertas de las features; P10-P13
salen de PUL-152 y PUL-140). Opción por defecto = lo que hay hoy.

| # | Pregunta (origen) | Opciones |
|---|---|---|
| P1 | Zurdos (`controles-tactiles.md` 1, Could) | (a) dejar sin layout espejado; (b) ficha Could para M4: opción de ajustes que espeja stick y botones |
| P2 | Tamaño de controles ajustable (`controles-tactiles.md` 2, Could) | (a) dejar fijo (180 / 120 px a 1080); (b) deslizador 0,8–1,3 del `ui_scale` de los controles |
| P3 | Háptica (`controles-tactiles.md` 3) | (a) 20 ms éxito y 20 + 20 ms rechazo; (b) solo en rechazo; (c) otro patrón tras PUL-151; siempre desactivable |
| P4 | Texto de 36 px a 1080 (`controles-tactiles.md` 4) | (a) dejar 36; (b) subir `text_min_px` (p. ej. 42) y revisar el ancho de ticket |
| P5 | Entrega solo por zona en móvil (`controles-tactiles.md` 5) | (a) confirmar zona automática (D26.5); (b) pedir además un toque explícito de entregar (vuelve un verbo ENTREGAR) |
| P6 | Muesca superior (`controles-tactiles.md` 6) | (a) dejar a la ficha de export (PUL-151) con la safe area real; (b) reservar ya un margen superior en el perfil táctil |
| P7 | Soltar al suelo por accidente (`lenguaje-acciones.md` 1) | (a) dejar la pulsación simple; (b) mantener 0,3 s para soltar al suelo (solo sin objetivo); (c) solo en móvil |
| P8 | Dispensador desde el lado de pase (`lenguaje-acciones.md` 2) | (a) dejar sin objetivo; (b) BLOQUEADO con 7.º motivo «otro lado» (icono de barra con flecha) |
| P9 | Limitación D27.3 (`decisions.md` D27, ADR-005) | (a) mantenerla (6,6-35,0 px a 1080 con la safe de diseño; 0 px con los discos en z −3,1); (b) pedir que la cámara descuente la safe area inferior de la zona de botones (ficha de cámara) |
| P10 | Cifras de ADR-005 D27.3 y del residuo de D27 (H-05 de PUL-152) | (a) corregirlas con las de PUL-152 (21-51 → 6,6-35,0 px; 6,4 → 0 px), cambio solo documental con gate de contrato; (b) dejarlas como histórico con una nota |
| P11 | Perfil de escritorio y safe area del sistema (H-05 de PUL-152) | (a) dejar como está (tickets ~31,5 px más abajo en Linux con panel); (b) el perfil de escritorio ignora la safe area del sistema (ficha de UI/cámara) |
| P12 | Teléfono por web (PUL-140 pregunta 2, PUL-153) | (a) aceptar el build web en red local como vía provisional; (b) esperar al APK (PUL-151) |
| P13 | Perfil táctil en PC sin pantalla táctil (PUL-140 pregunta 1, PUL-150 pregunta 1) | (a) tengo pantalla táctil: la ronda táctil se juega en PC; (b) la parte táctil solo en teléfono; (c) bandera de desarrollo que emule un toque con el ratón (sin multitáctil; toca `project.godot` o código: otra ficha) |

Nota: P9 se responde con la fila D27.3 del bloque G y con T6; P10 cambia un contrato
(`docs/arch/`), así que va con ADR y gate, no se decide solo en este playtest.
