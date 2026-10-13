# Tutorial breve (Should; D25, D26, D27)

**Slug:** tutorial-breve · **Cerrada en:** PUL-162 (evidencia `docs/evidence/PUL-162/README.md`).
**Contrato:** ADR-007 (PUL-163) fija núcleo, señales y escena; aquí todo lo que toca contrato es
*(propuesta)*. **Implementación:** PUL-169 (núcleo y datos), PUL-174 (panel), PUL-175 (montaje y
flujo), PUL-171 (botón del menú, solo si G0 lo elige).

## Descripción
Con D25 el tutorial enseña **solo la fase 1** (`dificultad-progresiva.md`): una sola receta, «Á feira»
(pulpo + aliño dulce, sin cachelos). El aliño picante y los cachelos se descubren en las fases 2 y 3
de la partida, con su comanda en el ticket. El cubo de basura se menciona al paso en el paso 3 (para
el pulpo que sobra) y en el 4 (para lo que salga mal).

El tutorial es **la misma escena de nivel** (`level_01`) con una configuración de ronda propia
(«Datos») y un panel de pasos encima. Cada paso enseña **un verbo** (D26) con su icono, resalta su
objetivo en el mundo y avanza cuando llega su señal. Al terminar (o al saltarlo) empieza la partida
normal desde 0 s (propuesta, «Entrada y salida»).

### Estado inicial (para PUL-175)
- Fase de tutorial: 1 puesto activo con una comanda «Á feira» de 90 s; reloj de ronda **oculto**.
- Una **caja vacía ya colocada** en el pasaplatos que se resalta en el paso 3 (así los pasos 1–5 los
  puede hacer un solo personaje: el corte exige una caja en un pasaplatos, `corte-pulpo.md`). En la
  partida normal el emplatador la pone él.
- Individual: el personaje activo empieza en la cocina. Local 2P: J1 en la cocina y J2 en el
  servicio (sus posiciones de inicio actuales si ya cumplen esto).

## Pasos
Avance: el núcleo cambia de paso **en el mismo frame** en que llega la señal; el panel muestra el
siguiente en `step_transition_time` = 0,3 s (≤ 0,5 s, AC2). `p` es el `player_index` del bus; en
Individual siempre 1, en Local 2P vale cualquiera de los dos para los pasos 1–5. Una señal que no es la
del paso en curso no hace nada (no hay pasos fuera de orden).

| # | Texto del paso (castellano; clave en `data/i18n/tutorial.*`) | Verbo (icono, `ActionVerb`) | Objetivo resaltado | Señal que lo completa | Avance |
|---|---|---|---|---|---|
| 1 | «Coge un pulpo de la nevera.» (táctil: «Mueve con el dedo a la izquierda y pulsa el botón».) | COGER `&"pick_up"` | Nevera del pulpo (táctil: además, fantasma del stick y aro en el botón de acción, AC8) | **Propuesta S1** `held_item_changed(p, &"octopus_raw")`. *Sin S1:* `interaction_resolved(p, &"pick_up", 1, &"")` (no distingue qué se coge: ver «Señales») | ≤ 0,5 s |
| 2 | «Échalo a la olla.» | COCER `&"cook"` | Plaza libre de la olla | `interaction_resolved(p, &"cook", 1, &"")` (`signals.md` §2 Interacción); con S1, además, que el último `held_item_changed(p, …)` fuera `&"octopus_raw"` (descarta los cachelos crudos) | ≤ 0,5 s |
| 3 | «Cuando esté listo, cógelo y córtalo sobre la caja: pulsa 6 veces (o mantén pulsado).» Tras el 6.º corte el texto cambia a: «Te sobra medio pulpo: déjalo en el pasaplatos de al lado (sirve para otra caja) o tíralo al cubo. Con la mano llena no puedes coger la caja.» | CORTAR `&"cut"`; tras el 6.º corte, SOLTAR `&"drop"` (o TIRAR `&"trash"`) | Olla hasta que la cocción acaba; después, la caja del pasaplatos; tras el 6.º corte, el pasaplatos libre contiguo a la caja (el cubo de la cocina solo se nombra en el texto) | Dos tramos: (a) contar `interaction_resolved(p, &"cut", 1, &"")` hasta `BoxData.presses_to_fill` (hoy 6, se lee del dato, no se copia; mantener pulsado emite una por repetición, así que cuenta igual); (b) después, el primer `interaction_resolved(p, &"drop", 1, &"")` o `interaction_resolved(p, &"trash", 1, &"")` del mismo `p` (con S1: `held_item_changed(p, &"")`). Motivo: tras 6 cortes quedan 50 u de pulpo en la mano (`corte-pulpo.md` AC2) y con la mano ocupada no se puede coger la caja (`HoldComponent.can_hold`) | ≤ 0,5 s tras (b) |
| 4 | «Coge la caja llena y pulsa el aliño **dulce**. Si te equivocas, pulsa el otro: lo sustituye. Lo que salga mal, al cubo.» | ALIÑAR DULCE `&"season_sweet"` | Dispensador de aliño dulce | `interaction_resolved(p, &"season_sweet", 1, &"")`. Con `&"season_hot"` OK **no** avanza y cambia el texto (AC6). Con `BLOCKED` `&"box_not_full"`: no avanza y el texto dice «la caja aún no está llena» | ≤ 0,5 s |
| 5 | «Llévala a la zona iluminada del puesto.» | — (sin verbo: la entrega es por zona, D26) | Zona de entrega del puesto activo (`DeliveryFrame` encendido) | `order_completed(order, points)` (`signals.md` §2 Comandas) | ≤ 0,5 s |
| 6 | Individual: «Cambia de personaje: el otro te espera al otro lado de la barra.» Local 2P: «Pasaos algo por un pasaplatos: uno lo deja, el otro lo coge.» | Individual: icono del botón de cambiar. Local 2P: SOLTAR `&"drop"` y COGER `&"pick_up"` | Individual: anillo del personaje inactivo (táctil: además, aro en el botón de cambiar, anclado al botón real, AC8). Local 2P: los 6 pasaplatos | Individual: `character_switched(1, c)` con `c` distinto del personaje activo al empezar el paso (la emisión de inicio de ronda no cuenta). Local 2P: **propuesta S2** `item_handed_over(from_player, to_player, pass_slot_id, item_kind)` con `from_player ≠ to_player`, emitida por el `PassSlot` en el que se dejó el objeto (ver «Señales»). Un `drop` de un jugador seguido de un `pick_up` del otro **no** basta: puede ser soltar al suelo y coger otra cosa | ≤ 0,5 s; al completar empieza la salida |

**Resaltado** *(propuesta para PUL-175)*: marcador de mundo propio del tutorial (flecha ▼ que pulsa a
1 Hz, ≥ 64 px a 1080 de alto) sobre el objetivo del paso, **distinto** del `Highlightable` y del prompt
de acción, que siguen funcionando igual (D26: el prompt solo sale si la pulsación haría algo). Solo hay
un marcador a la vez y desaparece en ≤ 0,5 s al completar el paso.

### Señales
Las del catálogo actual bastan para los pasos 2–5 y para el 6 en Individual. El paso 1 (y el filtro
del 2) necesita saber **qué** se ha cogido, y el paso 6 en Local 2P necesita saber que **el mismo
objeto** pasó de un jugador a otro **por un pasaplatos**, y eso no viaja por el bus: `item_picked_up(item)` es local del `Holder` y
`cooking_started(ingredient)` es local de la olla.

- **S1 (propuesta para ADR-007)** `held_item_changed(player_index: int, item_kind: StringName)`.
  Emisor: el `InteractionComponent` del personaje controlado (como `action_hint_changed`). Cuándo: al
  cambiar lo que lleva en la mano; `&""` con la mano vacía. `item_kind` de un conjunto cerrado
  (`&"octopus_raw"`, `&"octopus_cooked"`, `&"octopus_burnt"`, `&"cachelos_raw"`, …, `&"box"`).
  Oyente: el núcleo del tutorial.
- **Sin S1 (alternativa):** el paso 1 se da por bueno con cualquier `pick_up` OK. El falso positivo es
  coger otra cosa (cachelos crudos de su caja, o la caja del pasaplatos desde la cocina); el paso 2
  pediría entonces echar a la olla lo que se lleva y los cachelos crudos lo completarían. Coste: el
  tutorial puede «avanzar» sin haber hecho lo que dice. PUL-163 decide.
- **S2 (propuesta para ADR-007)** `item_handed_over(from_player: int, to_player: int, pass_slot_id: int, item_kind: StringName)`.
  Es un hecho explícito de transferencia: S1 no basta porque solo da la clase de objeto, no su
  identidad ni dónde estaba. Emisor: el `PassSlot` (capa específica; `PassSlot01..06` de
  `scene-tree.md`). Al recibir un objeto guarda el `player_index` de quien lo dejó; cuando un jugador
  lo coge de **ese** `PassSlot` y su `player_index` es distinto, emite S2 una vez y olvida al dueño. El
  objeto es el mismo porque nunca salió del pasaplatos; si lo recoge quien lo dejó, no se emite.
  `pass_slot_id` 1–6; `item_kind` del conjunto de S1. En Individual no se emite nunca (los dos
  personajes son del jugador 1). Oyente: el núcleo del tutorial.
- **Sin S2 (alternativa):** con el catálogo actual no hay una condición honesta para el paso 6 en
  Local 2P. El sustituto sería «entregad otra caja entre los dos» (`order_completed` con
  `interaction_resolved` OK de J1 y de J2 desde que empezó el paso), que añade ~30–40 s y pone en
  riesgo AC4 (≤ 90 s). PUL-163 decide.
- **Paso de tutorial** (`tutorial_step_changed(step: int)`, `tutorial_finished(skipped: bool)` o
  similar) para que el panel y el montaje escuchen al núcleo: lo propone y decide PUL-163 (Change 4).

### Pulpo quemado durante el tutorial *(propuesta)*
Con `burn_time` = 10 s tras la cocción (`octopus.tres`), un jugador que lee despacio puede quemar el
pulpo entre los pasos 2 y 3, y el tutorial no enseña a tirarlo.
- **Recomendada:** en el tutorial **no se quema** (`TutorialConfig.burn_enabled = false`). El aviso y
  el quemado se descubren en la partida.
- **Alternativa:** si se quema, el núcleo vuelve al paso 1 con el texto «Se te pasó: con la mano vacía,
  tíralo desde la olla y coge otro». Necesita una señal de bus de quemado (hoy `burnt` es local).

## Entrada y salida *(P5 de G0 sin responder: las 3 opciones son **propuesta**)*
Si G0 elige una, esta sección se queda solo con ella y PUL-175 implementa solo esa (PUL-175 AC1).

| | **(a) Automático en la primera partida** | **(b) Botón «Tutorial» en el menú** | **(c) Ambas** |
|---|---|---|---|
| Disparador | Empezar una partida (Individual o Local 2P) con el perfil sin `tutorial_done` en ajustes | Pulsar «Tutorial» en el menú principal | Cualquiera de los dos |
| Modo | El elegido en el menú (Individual o Local 2P) | **Individual** (desde el botón no hay elección de modo) | Botón: Individual; automático: el elegido |
| Saltar | Termina y marca `tutorial_done`: no vuelve a salir sola | Termina; `tutorial_done` no cambia nada (no hay disparador automático) | Termina y marca `tutorial_done` |
| Repetir | **Propuesta:** opción «Repetir tutorial» en Opciones que borra `tutorial_done` (1 AC más en PUL-171; depende de P2) | El propio botón | El botón |
| Coste | Núcleo + panel + montaje; estado `tutorial_done` (PUL-167). Sin tocar el menú. Quien ya sabe jugar lo ve una vez (lo salta con un botón) | Lo anterior + botón en `main_menu.tscn` (PUL-171, API de ADR-007) + **enmienda** de `menu-principal.md` AC6 y `controles-tactiles.md` AC1 (el menú táctil pasa a tener 2 botones: «Individual» y «Tutorial») + `test_main_menu_touch.gd`. Un jugador nuevo puede no encontrarlo | Suma de (a) y (b); dos caminos que probar |

**AC por opción** (solo se conserva la elegida):
- **E-a** Given el perfil sin `tutorial_done`, When se pulsa «Individual» o «Local 2P», Then arranca el
  tutorial en ese modo en ≤ 3 s; Given `tutorial_done`, Then arranca la partida normal (fase 1, reloj a
  300 s, 2 puestos). *Test:* `test_tutorial.gd`.
- **E-b** Given el menú (escritorio o táctil), When se pulsa «Tutorial», Then arranca el tutorial en
  Individual en ≤ 3 s; When se pulsa «Individual» o «Local 2P», Then arranca la partida normal aunque el
  tutorial no se haya visto nunca. El botón mide lo mismo que los demás (táctil: ≥ 120 px de alto, 24 px
  de separación). *Test:* `test_tutorial.gd` + `test_main_menu_touch.gd`.
- **E-c** Se conservan la condición automática de E-a y la entrada manual de E-b (no la parte de E-b
  «partida normal aunque no se haya visto»): Given el perfil sin `tutorial_done`, When se pulsa
  «Individual» o «Local 2P», Then arranca el tutorial en ese modo en ≤ 3 s; Given `tutorial_done`, When
  se pulsa «Individual» o «Local 2P», Then arranca la partida normal; Given cualquier perfil (con o sin
  `tutorial_done`), When se pulsa «Tutorial», Then arranca el tutorial en Individual en ≤ 3 s. *Test:*
  `test_tutorial.gd` + `test_main_menu_touch.gd`.

**Salida (las tres opciones):**
- **Recomendada (propuesta):** al completar el paso 6 sale «¡Listo! Empieza la feria» durante
  `end_banner_time` = 2,0 s y, sin volver a cargar la escena, empieza la **partida normal desde 0 s**
  en el mismo modo: `orders_reset`, `round_started(300)`, fase 1 con 2 puestos, recaudación 0 (lo
  cobrado en el tutorial no cuenta). Las cajas, pulpos y objetos del tutorial se retiran y los
  personajes vuelven a su posición de inicio. «Saltar» hace lo mismo sin el cartel.
- **Alternativa:** volver al menú principal. Coste: un clic más y corta el ritmo justo cuando el
  jugador acaba de aprender; ventaja: el montaje no tiene que reiniciar la ronda en caliente.
- **Tope:** el reloj oculto del tutorial dura `duration` = 180 s. Si llega a 0 sin completar el paso 6,
  el tutorial termina como «Saltar» pero **sin** marcar `tutorial_done` (en a/c vuelve a salir la
  próxima vez). No se muestra game over.
- Pausa: funciona igual que en la partida; desde la pausa, «Menú» sale sin marcar `tutorial_done`.

## Perfiles
| Perfil | Quién hace cada paso | Paso 6 | Panel | «Saltar» |
|---|---|---|---|---|
| **Individual** (escritorio) | El jugador, con el personaje que tenga activo | Cambiar de personaje (`p1_switch`) | Abajo en el centro, ≤ 900 × 220 px a 1080, texto ≥ 28 px | Acción `tutorial_skip` *(propuesta para ADR-004/007: Tab en teclado, Select/Back en mando)* o clic en el botón del panel |
| **Local 2P** | **Cualquiera** de los dos en los pasos 1–5 (el panel es uno, compartido; avanza con el primero que lo haga). No se reparten pasos fijos: si un jugador se despista, el otro no se queda bloqueado | Pasarse algo por un pasaplatos (`a` suelta, `b ≠ a` coge) | Uno solo, abajo en el centro, como Individual; muestra el marcador de jugador (J1/J2, `lenguaje-acciones.md` AC21) de quien completó el último paso durante 1 s | `tutorial_skip` de cualquiera de los dos |
| **Táctil** (solo Individual, D26) | El jugador | Cambiar de personaje con el botón de cambiar (D27: a la izquierda del de acción) | En la mitad derecha, bajo la banda superior y por encima de la zona de botones (AC8) | Botón del panel ≥ 120 px de alto |

## Criterios de aceptación
- **AC1** *(reescrito por D25; cerrado en PUL-162)* Given el tutorial, Then se muestran los 6 pasos de la
  tabla «Pasos» en ese orden: coger pulpo, cocer, cortar sobre la caja única (6 pulsaciones) y dejar el pulpo que sobra, aliñar con
  el aliño dulce (una pulsación; si te equivocas de aliño, pulsa el otro), entregar, cooperar. No se
  mencionan cachelos, aliño picante (salvo el texto de AC6) ni tamaños de caja. *Test:* `test_tutorial_steps.gd`.
- **AC2** Given cada paso, When llega su señal de la tabla, Then el núcleo pasa al siguiente en el mismo
  frame y el panel lo muestra en ≤ 0,5 s (`step_transition_time` = 0,3 s); Given la señal de otro paso,
  Then no avanza. *Test:* `test_tutorial_steps.gd` + `test_tutorial_panel.gd`.
- **AC3** *(precisado)* Given «Saltar» (`tutorial_skip`, clic o toque), Then el tutorial termina en ≤ 0,5 s
  y sigue la salida de «Entrada y salida»; con la opción a o c queda `tutorial_done` y no vuelve a
  aparecer sola en el perfil. *Test:* `test_tutorial_steps.gd`.
- **AC4** Given el tutorial completo por un bot, Then dura ≤ 90 s, la comanda tiene 90 s de paciencia y
  ninguna acción penaliza (`expire_penalty` = 0, `wrong_delivery_penalty` = 0). *Test:* `test_tutorial.gd`.
- **AC5 (D25)** Given el tutorial, Then la única comanda que genera es «Á feira» y las comandas del
  tutorial usan una configuración de fase 1 (aliño dulce, sin cachelos), con 1 puesto activo. *Test:* `test_data_tutorial.gd`.
- **AC6 (D25)** Given el paso de aliñar, When el jugador pulsa el aliño picante, Then el paso no avanza,
  la caja pasa a picante y el texto del paso le indica que el dulce sustituye al picante (sin penalizar,
  sin cubo obligatorio); When después pulsa el dulce, Then avanza. *Test:* `test_tutorial_steps.gd`.
- **AC7 (D26, el tutorial enseña el verbo)** Given cada uno de los 6 pasos, Then el panel muestra el
  **icono del verbo** de la tabla (de `action_icons.tres`, igual que el prompt del mundo; paso 5 sin
  verbo y señalando la zona iluminada; paso 6 el botón de cambiar en Individual) y el objetivo del paso
  tiene su marcador. En el paso de cortar, el texto dice que se puede **mantener pulsado** como atajo
  (pulsar 6 veces sigue valiendo). *Test:* `test_tutorial_panel.gd`.
- **AC1' (D26, matiz)** El paso «entregar» enseña la **zona iluminada** («entra con la caja correcta en
  la zona del puesto»); el puesto ya no se pulsa. *Test:* `test_tutorial_steps.gd`.
- **AC8 (D26, D27, táctil)** Given el perfil táctil a 2340×1080, Then: (1) el paso 1 muestra un fantasma
  semitransparente de la base del stick (300 px) centrado en (25 % del ancho, 70 % del alto) = (585, 756)
  que desaparece con el primer toque de stick, y un aro que pulsa a 1 Hz alrededor del botón de acción
  (gris: mano vacía y sin objetivo); (2) el panel usa texto ≥ 36 px y su «Saltar» mide ≥ 120 px de alto;
  (3) el panel cabe en x ∈ [50 % del ancho + 24, borde derecho de la safe area − 48] e y ∈ [224, 576]
  (≤ 300 px de alto: icono, texto y «Saltar» en una fila), así que no interseca la banda superior
  (≤ 200 px), la zona del stick (x < 50 %), la zona de botones de D27 (y ≥ alto − 240) ni la de AC16 de
  `controles-tactiles.md` (x ≥ ancho − 390, y ≥ 600); (4) el paso 6 es «cambia de personaje» y pone el
  aro en el botón de cambiar **anclado al botón real** (concéntrico con el centro que da la maquetación
  táctil, no una coordenada fija): (2028 ± 2, 972 ± 2) con safe area nula y (1896 ± 2, 909 ± 2) con la
  safe area de diseño (132/0/132/63), ADR-005 D27.1; lo mismo para el aro del botón de acción del paso 1:
  (2202, 942) y (2070, 879). El fantasma del stick queda entero dentro de la safe area en ambos casos;
  no hay Local 2P en móvil. *Test:* `test_tutorial_panel.gd` + `test_ui_scale.gd` + capturas a 1920×1080 y 2340×1080.
- **AC9 (Individual, escritorio)** Given Individual en escritorio a 1920×1080, When se pulsa cambiar en el
  paso 6, Then el tutorial termina en ≤ 0,5 s; Given el paso 6 recién empezado, Then el
  `character_switched` de inicio de ronda no lo completa; el panel mide ≤ 900 × 220 px y su texto ≥ 28 px.
  *Test:* `test_tutorial_steps.gd` + `test_tutorial_panel.gd`.
- **AC10 (Local 2P)** Given Local 2P, When J2 completa el paso 1 (o cualquier otro de los 1–5), Then avanza
  igual que con J1 en ≤ 0,5 s; Given el paso 6, When J1 deja un objeto en un pasaplatos y J2 coge ese
  objeto de ese pasaplatos, Then el tutorial termina en ≤ 0,5 s; When J1 lo suelta al suelo y J2 coge
  otro objeto, o el mismo jugador lo deja y lo recoge, Then no termina; «Saltar» de
  cualquiera de los dos lo termina. *Test:* `test_tutorial_steps.gd`.
- **AC11 (resaltado)** Given cada paso, Then hay exactamente 1 marcador de tutorial ≥ 64 px a 1080 sobre
  el objetivo de la tabla (paso 3: sobre la olla hasta `cooking_finished`, luego sobre la caja y, tras el 6.º corte, sobre el
  pasaplatos libre contiguo) y
  desaparece en ≤ 0,5 s al completar el paso; el prompt de acción del jugador sigue igual. *Test:* `test_tutorial.gd` + captura.
- **AC12 (salida, propuesta)** Given el paso 6 completado, Then a los 2,0 ± 0,1 s empieza la partida normal
  en el mismo modo con reloj a 300 s, fase 1, 2 puestos y recaudación 0; Given el tope de 180 s del
  tutorial, Then pasa lo mismo sin el cartel y sin marcar `tutorial_done`. *Test:* `test_tutorial.gd`.

## Datos (`.tres`) *(propuesta; rutas y clases las fija ADR-007)*
- `data/tutorial/tutorial_config.tres` (`TutorialConfig`):
  - `round_config: RoundConfig` → `data/tutorial/tutorial_round_config.tres`.
  - `step_transition_time` = 0,3 s; `end_banner_time` = 2,0 s; `burn_enabled` = `false` (si se
    acepta la recomendada); `steps`: los 6 pasos (clave de texto, verbo, objetivo, condición de avance)
    si ADR-007 decide que van en datos.
- `tutorial_round_config.tres` (`RoundConfig`, sin campos nuevos): `duration` = 180 (tope, reloj
  oculto), `first_order_delay` = 0, `time_bonus_max` = 0, `expire_penalty` = 0,
  `wrong_delivery_penalty` = 0, `rng_seed` fijo, `phases` = 1 `PhaseData` con `start_fraction` = 0,
  `active_slots` = 1, `orders` = [`a_feira.tres`] y `patience_multiplier` = 1,5 (60 s de «Á feira» ×
  1,5 = 90 s). Si el balance (PUL-165/166) cambia el `max_time` de «Á feira», hay que recalcular el
  multiplicador: `test_data_tutorial.gd` comprueba los 90 s, no el 1,5.
- `presses_to_fill` no se duplica: el paso 3 lo lee de `BoxData`.
- Estado `tutorial_done` (bool) en los ajustes persistentes (PUL-167, ADR-007); solo hace falta con a o c.

## Preguntas abiertas (para G0 y PUL-163)
1. **P5 (G0):** ¿entra en la alpha? ¿a, b o c? Si no entra, se cierra registrándolo y se cierran 169, 174 y 175.
2. **Salida (G0):** ¿partida normal desde 0 s (recomendada) o vuelta al menú?
3. **Repetir (G0, solo con a):** ¿opción «Repetir tutorial» en Opciones?
4. **S1 y S2 (PUL-163):** ¿se añade `held_item_changed` o se acepta el falso positivo del paso 1? ¿Se
   añade `item_handed_over` o el paso 6 en Local 2P pasa a «entregad otra caja entre los dos»?
5. **Quemado (PUL-163/G0):** ¿sin quemado en el tutorial (recomendada) o vuelta al paso 1?
6. **`tutorial_skip` (PUL-163):** ¿acción nueva del InputMap (ADR-004) o solo el botón del panel y la pausa?
