# Rediseño jugable de las estaciones (PUL-090, M3c)

**Estado:** propuesta para el gate humano. **Fecha:** 2026-10-07. **Rol:** game-designer.
**Alcance:** estación de condimentos (bandeja, dispensadores, cuenco, lados), circuito de las
bandejas/cajas (rack `box_shelf`, tamaño S/M/L, corte sobre la caja, pasaplatos `Slot`,
distintivos `badge_row`) y entrega en los kioscos `order_stand`, en `level_01.tscn` (planta B).
**Fuentes:** `features/estacion-condimentos.md`, `condimentacion.md`, `corte-pulpo.md`,
`entrega-y-puntuacion.md`, `comandas.md`, `movimiento-e-interaccion.md`, `level-layouts.md`;
decisiones D1, D3, D4, D10, D11, D13, D18, D19. **Evidencia:** `docs/evidence/PUL-090/`.
**Arte en paralelo:** PUL-091 (Codex) lee la sección 5.

Nada de este documento cambia el juego todavía: las features y los contratos se actualizan después
del gate, en las fichas de la sección 4.4.

---

## 1. Diagnóstico medido del flujo actual

### 1.1 Cómo se ha medido
- **Bot sobre el nivel real** (`docs/evidence/PUL-090/measure_flow.gd`): carga `level_01.tscn`,
  pulsa teclas simuladas (WASD/E, flechas/Intro, Q) y usa el **detector real** con el ayudante
  `tests/integration/level_walker.gd`, el mismo que los tests AC16/AC17 de PUL-061. Nunca llama a
  `interact()`. Cuenta pulsaciones, cambios de personaje, metros, segundos de juego (frames / 60),
  segundos quieto por personaje, rechazos de la estación y de la entrega, y los casos en que el
  detector no apuntaba al objetivo buscado («recolocaciones»).
- **Mapa de objetivos** (`target_map.gd`): coloca al personaje en 57 × 6 puntos delante de la barra
  (los dos lados, a 0,85/1,0/1,3 m del eje), mirando a la barra, con la mano vacía, con una caja
  llena y con pulpo cocido, y anota qué elige el detector. La bandeja tiene una caja llena.
- **Reproducir** (desde la raíz; ≈ 10 s cada uno, sin sonido):
  ```
  godot --headless --audio-driver Dummy --path godot --import     # solo la primera vez
  godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s "$PWD/docs/evidence/PUL-090/run_measure.gd"
  godot --headless --audio-driver Dummy --fixed-fps 60 --path godot -s "$PWD/docs/evidence/PUL-090/run_target_map.gd"
  ```
  Salida: `metrics.json`, `measure_flow.log`, `target_map.txt`. El antirrebote de los dispensadores
  usa el reloj de pared; el medidor le inyecta el reloj de juego (`clock`, ya previsto para tests)
  porque con `--fixed-fps` el juego corre más deprisa que la pared.

**Escenarios.** Comanda única activa con `max_time` 600 s, 2 pedidos seguidos del mismo tipo
(el 2.º aprovecha el pulpo sobrante: 1 pulpo = 2 cajas).
- **Solo**: Individual con un único personaje que rodea la barra por el hueco (col. 14, x 7,7).
- **Cambio**: Individual con el reparto de AC16 (cocinero en la cocina, emplatador en el servicio) y
  `p1_switch` (Q).
- **Coop**: Coop 2P, J1 emplata y J2 cocina **a la vez**.

Cada pedido: caja del rack → bandeja (servicio) · pulpo de la nevera → olla 1 · esperar 5 s ·
recoger · cortar en la bandeja por el pase (5/10/20 pulsaciones) · sobrante a un pasaplatos ·
condimentar (2 dispensadores o 1 + cuenco) · recoger la caja · entrar en la zona del puesto
(entrega sin pulsar). Con cachelos, además: saco → olla 2 · recoger · cuenco por el pase.

**Límite del método.** El bot anda en línea recta a 5 m/s, no duda, conoce los puntos exactos de
uso y pulsa a 15 Hz. Los segundos son **una cota inferior**; una persona aporrea a 5–7 Hz, lo que
añade ≈ 0,1 s por corte (S +0,5 s, M +1 s, L +2 s) además de dudas y recolocaciones. Como
referencia humana, en PUL-061 la primera comanda en Individual jugada con el MCP **caducó a los
79 s** «por lentitud» y en Local 2P se entregó una mediana en ≈ 1 min.

### 1.2 Resultados (bot, `metrics.json`)
Pedido 1 = desde cero (nevera y olla). Pedido 2 = con el pulpo sobrante en un pasaplatos.
«Quieto» = segundos sin moverse (incluye esperar a la olla y cortar).

| Modo | Tipo | s ped. 1 | s ped. 2 | Pulsaciones (1 / 2) | Cambios (1 / 2) | m Player1 (1 / 2) | m Player2 (1 / 2) | Quieto ped. 1, Player1 / Player2 (s) |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Solo | S sal+aceite | 23,3 | 13,8 | 14 / 11 | 0 | 78,9 / 58,6 | — | 7,3 / — |
| Solo | M sal+aceite | 23,7 | 14,1 | 19 / 16 | 0 | 78,9 / 58,4 | — | 7,7 / — |
| Solo | L sal+aceite | 24,3 | 14,7 | 29 / 26 | 0 | 78,9 / 58,1 | — | 8,3 / — |
| Solo | S aceite+cachelos | 27,4 | 22,4 | 18 / 15 | 0 | 94,6 / 72,7 | — | 8,2 / — |
| Cambio | S sal+aceite | 15,9 | 7,3 | 14 / 11 | 2 / 2 | 26,2 / 19,7 | 12,4 / 3,5 | 10,4 / 13,3 |
| Cambio | M sal+aceite | 16,2 | 7,5 | 19 / 16 | 2 / 2 | 26,4 / 19,4 | 12,4 / 3,5 | 10,8 / 13,7 |
| Cambio | L sal+aceite | 16,9 | 8,2 | 29 / 26 | 2 / 2 | 26,3 / 19,1 | 12,4 / 3,5 | 11,4 / 14,4 |
| Cambio | S aceite+cachelos | 20,1 | 16,3 | 18 / 15 | 2 / 2 | 30,0 / 23,2 | 25,5 / 16,1 | 14,0 / 14,9 |
| Coop | S sal+aceite | 10,5 | 6,1 | 14 / 11 | — | 26,2 / 19,7 | 12,4 / 3,5 | 5,1 / 8,0 |
| Coop | M sal+aceite | 10,9 | 6,4 | 19 / 16 | — | 26,4 / 19,4 | 12,4 / 3,5 | 5,5 / 8,4 |
| Coop | L sal+aceite | 11,5 | 7,0 | 29 / 26 | — | 26,3 / 19,1 | 12,4 / 3,5 | 6,1 / 9,0 |
| Coop | S aceite+cachelos | 14,8 | 13,2 | 18 / 15 | — | 30,0 / 23,2 | 25,5 / 16,1 | 8,7 / 9,5 |

Player1 empieza en el servicio (emplatador) y Player2 en la cocina (cocinero); en Solo solo se
mueve Player1. Quieto: solo pedido 1 (el 2.º está en `metrics.json`). Los 24 pedidos se
completaron; 0 rechazos de estación y de entrega, 0 recolocaciones (el bot usa los puntos de uso
calibrados en PUL-063; una persona no: ver 1.4).

### 1.3 Lectura de los números
1. **El corte es la mayor parte de las pulsaciones**: 36 % (S), 53 % (M) y **69 % (L)** del
   pedido. Una L cuesta 20 pulsaciones (≈ 3,3 s a 6 Hz) por 12 € frente a los 8 € de una S de 5.
2. **Coop: cada jugador pasa la mitad del pedido quieto.** El emplatador está quieto 5,1 de 10,5 s
   (49 %) esperando a que la caja esté llena; el cocinero, 8,0 s (espera de olla + corte). La
   bandeja única hace que corte y condimento vayan **en serie**: el pedido 2 tarda 6,1 s y no
   baja de ahí, porque la siguiente caja no puede entrar en la bandeja hasta que sale la anterior.
3. **Individual: el cambio funciona y el rodeo castiga mucho.** Con 2 cambios por pedido se
   recorren 38,6 m (16 s); sin cambiar, **78,9 m** (23 s): el doble de metros. El rodeo bandeja →
   bandeja por el hueco mide ≈ 16–17 m (salida a salida, 17,6 m en PUL-061), **frente a los 6–10 m**
   que fijaba `estacion-condimentos.md`. La planta B no cumple el rodeo de su propia feature.
4. **El tamaño apenas cambia el tiempo del bot** (+1 s de S a L) pero sí las pulsaciones (×2).
   Para una persona la L es la caja «cansada», no la difícil.
5. **Los cachelos duplican el pedido en régimen**: en coop, el 2.º pedido sin cachelos tarda 6,1 s y
   con cachelos 13,2 s (+116 %), porque cada cachelo cocido da **1 ración** y hay que cocerlo de
   nuevo para cada caja (olla 5 s + 16 m más del cocinero).
6. **La entrega no es cuello de botella**: estación → puesto 4–4,5 m (≈ 1 s) y la zona entrega sola
   con la caja correcta (0 pulsaciones). Su problema es de información (1.4, I3).
7. **La paciencia no aprieta a un experto** (comandas de 80–180 s × 0,7–1,0 frente a 6–16 s del
   bot), pero sí a quien no entiende el flujo (la caducada de PUL-061). La dificultad actual sale
   de la **claridad**, no del reloj: es lo primero que hay que arreglar.

### 1.4 Mapa de objetivos del detector (`target_map.txt`)
Un carácter = 0,25 m, de x −6 a +8. `T` caja de la bandeja · `d p s a` dulce, picante, sal, aceite
· `c` cuenco · `_` pasaplatos · `.` nada.

```
x:               |   |   |   |   |   |   |   |   |   |   |   |   |   |   |      (x = −6 … +8)
Mano vacía
cocina  z=-1.00  __________________.......TTT....._____________________...
servic. z=+1.00  ________________cccddd.ppTTTss.aaa____________________...
Caja llena o pulpo cocido en la mano
cocina  z=-1.00  ________________cccc.....TTT....._____________________...
servic. z=+1.00  ________________cccc....TTTTT...._____________________...
```

- **Lado de pase: 0,75 m útiles de 4 m.** Con la mano vacía o con pulpo solo se apunta a la caja en
  una franja de 0,75 m; a los lados, 1,75 m y 1,25 m de mostrador muerto. El cocinero tiene que
  pararse justo delante de la bandeja para cortar.
- **Lado de condimentar con la mano vacía:** cada dispensador gana en una franja de 0,5–0,75 m;
  hay **huecos sin objetivo** (x −0,5 y +1,5 a 1 m) y la caja de la bandeja solo gana en 0,25–0,75 m
  entre picante y sal: recogerla exige apuntar entre dos dispensadores.
- **El cuenco roba el objetivo con cualquier cosa en la mano** en 1–1,25 m de los dos lados (es
  objetivo para reponer): con una caja o con pulpo, pulsar ahí da `NOT_ACCEPTED` y suena el error.
  El cocinero pasa por ahí al ir de las ollas (x −1,3 / +0,7) a la bandeja.
- **Fuera de la estación, todo es pasaplatos**: los 9 `Slot` (invisibles desde M3b, D9 del QA de
  PUL-087) cubren la barra entera; con algo en la mano, pulsar en cualquier punto lo deja ahí sin
  aviso.

### 1.5 Cuellos de botella y puntos de error
| # | Dónde | Qué pasa | Tipo | Evidencia |
|---|---|---|---|---|
| B1 | Bandeja única | Corte y condimento se serializan; el emplatador espera; la caja siguiente no puede entrar | Regla + nivel | 1.3.2, quieto 49 % |
| B2 | Rodeo de la barra | 16–17 m por cruce (spec 6–10 m); Individual sin cambio = 2× metros | Nivel | 1.3.3 |
| B3 | Corte L | 20 pulsaciones en la bandeja, bloqueándola | Regla (datos) | 1.3.1 |
| B4 | Cachelos | 1 ración por cocido: cada caja con cachelos rehace olla + cuenco | Datos | 1.3.5 |
| B5 | Doble traspaso | La caja va servicio → bandeja → (corte) → servicio: en Individual, 2 cambios por pedido | Regla + nivel | 2 cambios/pedido |
| E1 | Cuenco | Objetivo con caja/pulpo en la mano → error | Interacción | 1.4 |
| E2 | Bandeja desde el servicio | Ventana de 0,25–0,75 m entre dispensadores para recoger la caja | Interacción | 1.4 |
| E3 | Dispensador con la caja a medio cortar | `BOX_NOT_FULL`: el emplatador no puede adelantar trabajo | Regla | `seasoning_rules.gd` |
| E4 | Dispensador desde el pase | No se resalta ni responde, sin explicar por qué | Información | AC7 de la feature |
| E5 | Pasaplatos invisibles | 9 huecos sin marca: se suelta en cualquier parte y se pierde de vista | Información | QA PUL-087 D9 |
| E6 | Tamaño de la caja | El ticket dice «Pulpo Individual/Doble/Familiar», no S/M/L; tamaño equivocado = caja errónea (−2 €) | Información | `ticket_entry.gd` |
| E7 | Zona de entrega | Entrega sola solo si la caja es correcta; con otra no pasa nada y hay que pulsar para enterarse (−2 €) | Información | `order_stand.gd` |
| E8 | Sobrante de pulpo | 50 unidades que hay que aparcar en un pasaplatos (1 pulsación y un hueco ocupado) | Regla | flujo medido |

---

## 2. Problemas priorizados

Impacto en diversión/claridad (1–3) × frecuencia por pedido (1–3). Frecuencia 3 = en casi todos.

| Pri. | Problema | Bloque | Categoría | Imp. | Frec. | Total |
|---|---|---|---|---:|---:|---:|
| P1 | Bandeja única: espera y serie (B1, E3) | Condimento | Regla | 3 | 3 | **9** |
| P2 | Apuntar en la estación: franjas estrechas, huecos, cuenco que roba (E1, E2, E4) | Condimento | Interacción | 3 | 3 | **9** |
| P3 | Rodeo de 16–17 m (B2) | Nivel | Distribución | 3 | 2 (Individual) | **6** |
| P4 | Tamaño no legible en el ticket (E6) | Bandejas | Información | 2 | 3 | **6** |
| P5 | Corte L aporreado 20 veces (B3) | Bandejas | Regla (datos) | 2 | 2 | 4 |
| P6 | Pasaplatos invisibles (E5) | Bandejas | Información | 2 | 2 | 4 |
| P7 | Cachelos de 1 ración (B4) | Condimento | Datos | 2 | 2 (≈ 1/3 de comandas) | 4 |
| P8 | Doble traspaso en Individual (B5) | Bandejas | Regla + nivel | 2 | 2 | 4 |
| P9 | Zona de entrega muda (E7) | Entrega | Información | 1 | 2 | 2 |
| P10 | Sobrante de pulpo que aparcar (E8) | Bandejas | Regla | 1 | 2 | 2 |

---

## 3. Alternativas por bloque

Leyenda de los bocetos (cenital, arriba el fondo, un carácter ≈ 0,5 m): `N` nevera · `K` saco de
cachelos · `O` olla · `B` rack de cajas · `▭` pasaplatos marcado · `[T]` bandeja · `d p s a`
dispensadores · `c` cuenco · `1–4` puestos · `░` hueco de paso · `#` barra.

### 3.1 Bloque condimento

#### C-A · Pase afinado (se queda la bandeja)
```
                 COCINA                          J2 corta por aquí ↓
  # # ▭ ▭ ▭ # # #  c  [T]  # # # ░ ▭ ▭ ▭ ▭ # # #      ← bandeja centrada, cuenco al extremo
                    d  p   s  a                      ← dispensadores a 1,0 m, simétricos
                 SERVICIO                        J1 condimenta ↑ mientras J2 corta
```
- **Reglas:** se puede condimentar la caja de la bandeja **desde fill > 0** (se quita el rechazo
  `BOX_NOT_FULL` de la estación; la entrega sigue exigiendo caja llena). El emplatador echa sal y
  aceite mientras el cocinero corta por el otro lado: los dos trabajan a la vez sobre la misma caja,
  sin exigirlo (Individual lo hace en serie). Cachelos: `cachelos_portions_per_item` 1 → 2.
- **Interacción:** el cuenco solo es objetivo con **cachelos cocidos** en la mano (con otra cosa,
  no es candidato, como los dispensadores con la mano llena). Dispensadores a 1,0 m entre centros
  y bandeja centrada en el hueco, sin dispensador delante: franja de bandeja ≥ 0,75 m a 1 m.
- **Individual:** igual que hoy (2 cambios por pedido). **Coop:** el emplatador deja de esperar
  ≈ 1–2 s por pedido (condimenta durante el corte); el cuello de la bandeja única sigue.
- **Gana:** coste bajo, mantiene D18 tal cual se aprobó. **Pierde:** no resuelve B1 (una caja a la
  vez) ni el doble traspaso.
- **Coste:** 2 fichas (reglas/estación + datos). Contratos: ninguno nuevo; cambia AC5 de
  `estacion-condimentos.md` y AC4 de `condimentacion.md` (gate de feature). `.tres`:
  `seasoning_station.tres` (`portions`, nuevo `allow_partial_box: bool`). InputMap: sin cambios.

#### C-B · Línea de condimentos «al paso» (recomendada)
```
                 COCINA                       J2 deja la caja cortada en un ▭ ↓
  # ▭ ▭ ▭ ▭ # # [ c  ·  ·  ·  · ] # ░ ▭ ▭ ▭ ▭ # #     ← sin bandeja: la estación es la línea
                  c   d  p  s  a                     ← J1 pasa con la caja en la mano y pulsa
                 SERVICIO        →  puestos 1–4
```
- **Reglas:** la caja **no se deja** en la estación. Con una caja llena **en la mano** y desde el
  lado de condimentar, pulsar un dispensador alterna su condimento en esa caja (mismo toggle,
  intercambio de pimentón y antirrebote de hoy). El cuenco igual: reponer desde cualquier lado con
  cachelos cocidos; alternar con la caja en la mano. Desaparece la bandeja (`Tray`); la caja se
  pasa por los pasaplatos de la barra, que ya existen.
- **Interacción:** con una caja en la mano, en el tramo de la estación solo hay dispensadores y
  cuenco (sin pasaplatos), así que no compiten con «soltar». Con la mano vacía los dispensadores no
  son objetivo (no hay caja a la que aplicar): desaparecen E2 y el «AC8» de PUL-064.
- **Individual:** el emplatador deja **dos cajas** en los pasaplatos, Q, el cocinero cuece un pulpo
  y corta las dos (1 pulpo = 2 cajas, sin sobrante que aparcar), Q, el emplatador recoge, condimenta
  al paso y entrega las dos. **1 cambio por pedido** (hoy 2). **Coop:** el cocinero puede cortar
  la caja N+1 en un pasaplatos mientras el emplatador condimenta la N: el ciclo pasa de la suma a
  ≈ el máximo de los dos trabajos (estimado: régimen coop de 6,1 s → ≈ 4 s del bot, −35 %).
- **Gana:** quita B1, E2, E3 y E8 de raíz; es el modelo mental de Overcooked («llevo el plato y le
  echo cosas»); las pegatinas de la caja se leen en la mano, que es donde se mira. Sigue forzando
  coordinación: la barra separa cocina y servicio y el traspaso es un pasaplatos.
- **Pierde:** la «bandeja que atraviesa el mostrador» de D18 (cambia su redacción, gate). Se pierde
  la regla de dos lados para la caja (queda para dispensadores y cuenco).
- **Coste:** 3 fichas (enmienda de contratos, estación sin bandeja, nivel/tests). Contratos:
  `scene-tree.md` (baja de `Tray` en `seasoning_station.tscn`), `signals.md` sin señales nuevas
  (`seasoned`/`seasoning_removed` ya existen). InputMap: sin cambios. `.tres`: `seasoning_station.tres`
  (quita `operator_side_only` si se decide que da igual el lado; ver G1). Arte: el modelo de
  PUL-052 pierde la bandeja (PUL-091).

#### C-C · Pase doble (dos estaciones gemelas)
```
                 COCINA
  # ▭ ▭ # [T1] c d p s a # # # [T2] c d p s a # ░ ▭ ▭ #     ← dos estaciones de 2,5 m
                 SERVICIO
```
- **Reglas:** como hoy, pero duplicado: cada estación tiene su bandeja, sus 4 dispensadores y su
  cuenco; cada dispensador actúa sobre la bandeja de su estación.
- **Individual:** igual que hoy por pedido; permite tener dos cajas en curso. **Coop:** dos cajas a
  la vez (corte en una, condimento en otra); también admite reparto «uno por estación».
- **Gana:** resuelve B1 sin cambiar reglas. **Pierde:** el doble de piezas en la barra (8
  dispensadores, 2 cuencos: más ruido visual y más franjas estrechas, P2 empeora); dos cuencos que
  reponer. **Coste:** alto: 3–4 fichas y arte duplicado. Contratos: `scene-tree.md` (dos
  instancias, nombres en el nivel). `.tres`: sin cambios. InputMap: sin cambios.

### 3.2 Bloque bandejas y corte

#### B-A · Datos y lectura (recomendada)
```
  Ticket                         Rack (servicio, pared izq.)     Barra
  ┌──────────────────────┐       ┌───┐                            ▭ ▭ ▭ ▭   ← 6 salvamanteles
  │ #2  (M) Pulpo Doble  │       │ S │ ← plato pequeño + «S»          visibles, no 9 invisibles
  │ (SAL)(ACE)           │       │ M │
  │ ███████░░░  01:12    │       │ L │
  └──────────────────────┘       └───┘
```
- **Reglas/datos:** cortes **4 / 6 / 10** pulsaciones (`presses_to_fill`, `int` desde PUL-104;
  antes `fill_per_press` 0,25 / 0,1667 / 0,1);
  sigue 1 pulpo = 2 cajas (`amount_per_full_box` 50) y la pulsación repetida (D13).
- **Información:** el ticket muestra el **tamaño** con la misma silueta y letra que el rack y el
  plato (S/M/L), antes del nombre. El rack rotula cada pila. Los pasaplatos pasan de 9 invisibles a
  **6 marcados** (salvamantel o recuadro pintado en la barra) y el resto de la barra no acepta
  objetos (sin `Slot`).
- **Individual/Coop:** igual que hoy, con L de 20 → 10 pulsaciones (−10 en cada L).
- **Gana:** P4, P5 y P6 con coste bajo. **Pierde:** algo de «esfuerzo» de la L (se compensa con
  sus 12 €, que se pueden bajar). **Coste:** 2 fichas (datos + ticket/nivel). Contratos:
  `scene-tree.md` (número de `PassSlot` en el nivel). `.tres`: `data/boxes/*.tres`. InputMap: no.

#### B-B · Rack en la cocina
```
                 COCINA
   N K   O     O                  ← el cocinero coge la caja (B junto al pase) y la corta
   B ▭ ▭ ▭ # # [ estación ] # ░ ▭ ▭ #
                 SERVICIO         ← el emplatador solo condimenta y entrega
```
- **Reglas:** el rack pasa al lado de la cocina, junto al pase. El cocinero arma la caja entera
  (coger, dejar en un pasaplatos, cortar) y la deja lista; el emplatador condimenta y entrega.
- **Individual:** 1 cambio por pedido (como C-B). **Coop:** más carga al cocinero (nevera, olla,
  caja, corte) y menos al emplatador (2–3 pulsaciones por pedido): desequilibra el reparto, salvo
  que el emplatador asuma los cachelos (que hoy están en la cocina, D10).
- **Gana:** quita el doble traspaso (B5) también con la bandeja de hoy. **Pierde:** reparto coop
  desigual; el emplatador vuelve a esperar. **Coste:** 1–2 fichas de nivel. Contratos: ninguno
  (posición en `level_01.tscn`). `.tres`: no.

#### B-C · Corte mantenido (cambia D13)
- **Reglas:** se corta manteniendo interactuar: 0,8 / 1,2 / 2,0 s para S/M/L, con barra de
  progreso; soltar pausa el corte.
- **Gana:** ninguna fatiga de dedo, tiempo de corte fijo y medible. **Pierde:** D13 lo rechazó
  («pulsación repetida, como en Unity»); el aporreo es parte del caos y del sonido del corte.
- **Coste:** 1 ficha + cambio de `PlayerInput` (pulsar → mantener; no cambia el InputMap pero sí el
  contrato de `interact`: ADR). Solo se incluye para que el gate lo descarte o no explícitamente.

### 3.3 Bloque entrega

#### E-A · Puesto que se reconoce (recomendada)
```
  Ticket #2 con franja AZUL       Puesto 2 con toldo AZUL
  ┌─[azul]────────────┐             ╔═══════╗
  │ #2 (M) Pulpo Doble│             ║  #2   ║ ← placa clara (QA PUL-087 D1)
  └───────────────────┘          ···║·······║···  ← zona de entrega pintada en el suelo:
                                       ↑           se ilumina si la caja de la mano
                                  J1 con la caja    coincide con la comanda del puesto
```
- **Información:** cada ticket lleva una franja del color del toldo de su puesto (rojo, azul,
  amarillo, verde, ya en el modelo de PUL-083), además del número. La zona de entrega se dibuja en
  el suelo y **se ilumina** cuando el portador lleva una caja que coincide con la comanda viva del
  puesto (la regla de PUL-039 ya existe: solo se muestra). Con una caja que no coincide, la zona se
  queda apagada: el jugador sabe que no va a entregar antes de pulsar y pagar −2 €.
- **Individual/Coop:** igual. **Gana:** P9 y parte de E6 por casi nada. **Pierde:** nada de
  reglas. **Coste:** 1–2 fichas (ui-engineer: ticket; gameplay/arte: zona y puesto). Contratos:
  ninguno nuevo (el puesto ya oye `order_generated`/`order_completed`; el resaltado lee la mano del
  portador en su `DeliveryZone`). `.tres`: color por `slot_id` en un dato de nivel.

#### E-B · Puestos pegados a la línea de condimentos
- **Nivel:** los 4 puestos se acercan a 2 m de la estación (fila 7 en vez de 10).
- **Gana:** −2,5 m por pedido (≈ 0,5 s). **Pierde:** se estrecha el servicio (choques en coop) y
  la entrega deja de ser un pequeño viaje con riesgo; no ataca ningún problema prioritario.
  **Coste:** 1 ficha de nivel + revisión de cámara/HUD (los puestos bajo los tickets).
  **No se recomienda.**

### 3.4 Distribución del nivel (transversal)
El rodeo (P3) es de la planta, no de un bloque. Propuesta **N-A**: mover el hueco de la barra de
x 7,7 (col. 14) a **x ≈ 3,2** (donde hoy está `PassSlot05`), a ≈ 3 m del extremo de la estación.
El rodeo bandeja/línea ↔ pase queda en ≈ 7–8 m (≈ 1,5 s), dentro del 6–10 m de la feature, y el
trayecto rack → nevera de un solo personaje baja de ≈ 28 m a ≈ 19 m. Coste: 1 ficha de nivel
(`level_01.tscn`, `kitchen_layout.tscn`, `level_walker.gd::GAP_X`, distancias de
`test_level_01.gd`). Alternativa N-B: segundo hueco a la izquierda (x −5,3), que acorta el rack →
nevera pero no el rodeo de la estación; no se recomienda (dos puertas = la barra deja de separar).

---

## 4. Recomendación

### 4.1 Paquete
**C-B (línea al paso) + B-A (datos y lectura) + E-A (puesto que se reconoce) + N-A (hueco a
x ≈ 3,2) + cachelos 2 raciones.** Es coherente porque todos empujan en la misma dirección: la caja
va siempre en la mano o en un pasaplatos visible, nunca «dentro» de una pieza; cada pieza tiene un
único verbo con la caja en la mano (pasaplatos = soltar, dispensador = echar, puesto = entregar) y
la barra sigue separando cocina y servicio con un rodeo que se nota pero no castiga.

Si el gate no quiere tocar la redacción de D18, la alternativa barata es **C-A + B-A + E-A + N-A**:
arregla la puntería, la lectura y el rodeo, pero deja la bandeja única (P1).

### 4.2 Efecto esperado (estimación sobre las medidas del bot)
| Medida | Hoy | Paquete | Cómo se estima |
|---|---:|---:|---|
| Pulsaciones pedido L (desde cero) | 29 | **19** | −10 cortes; bandeja → pasaplatos es la misma pulsación |
| Pulsaciones pedido S | 14 | **13** | −1 corte |
| Coop, régimen (pedido 2, S) | 6,1 s | **≈ 4 s** | corte N+1 en paralelo al condimento N |
| Coop, emplatador quieto (pedido 1) | 49 % | **≤ 30 %** | condimenta/entrega mientras se corta la siguiente |
| Individual, cambios por pedido | 2 | **1** | dos cajas por pulpo y por viaje |
| Individual sin cambio, metros (pedido 1) | 78,9 m | **≈ 45 m** | 2 cruces de ≈ 8 m en vez de ≈ 17 m |
| Pedido con cachelos, régimen coop | 13,2 s | **≈ 9 s** | un cocido de cachelos cada 2 cajas |
| Franjas sin objetivo en la estación | 2 huecos, cuenco roba | **0** | solo dispensadores en el tramo; cuenco solo con cachelos |

Son estimaciones; la ficha de QA las mide con el mismo `measure_flow.gd` adaptado.

### 4.3 Criterios de aceptación borrador
Para las features que se reescriban tras el gate (`estacion-condimentos.md`, `corte-pulpo.md`,
`entrega-y-puntuacion.md`, `level-layouts.md`). Números a datos (`.tres`) donde se indica.

**Condimento (C-B)**
- **R1** Given un jugador en el lado de condimentar con una caja llena en la mano, When pulsa
  interactuar frente al dispensador de sal, Then la caja sigue en la mano, lleva sal, se emite
  `seasoned(sal)` 1 vez y su fila de pegatinas muestra 1 icono.
- **R2** Given la caja anterior, When pulsa otra vez el mismo dispensador a ≥ 0,25 s
  (`toggle_guard`), Then la caja ya no lleva sal y se emite `seasoning_removed(sal)` 1 vez; a
  0,1 s, la segunda pulsación se ignora.
- **R3** Given una caja a medio cortar (fill 0,6) en la mano, When pulsa un dispensador, Then se
  rechaza (`BOX_NOT_FULL`), la caja no cambia y suena `season_error`.
- **R4** Given un jugador con la mano vacía en el lado de condimentar, Then ningún dispensador es
  objetivo ni se resalta.
- **R5** Given un jugador con una caja en la mano o con pulpo, en cualquier punto a ≤ 1,5 m del
  cuenco, Then el cuenco no es objetivo; con cachelos cocidos en la mano, sí (desde los dos lados).
- **R6** Given el cuenco con 0 raciones, When se echa 1 cachelo cocido, Then tiene **2** raciones
  (`cachelos_portions_per_item` = 2, máximo `cachelos_stock_max` = 4).
- **R7** Given `seasoning_station.tscn`, Then no tiene `Tray` y los únicos objetivos del tramo de la
  estación (4 m de barra) son los 4 dispensadores y el cuenco (barrido del mapa de objetivos:
  0 `_` en el tramo con caja en la mano).
- **R8** Given el mapa de objetivos (`target_map.gd`) con una caja en la mano, a 1,0 m del eje en el
  lado de condimentar, Then cada dispensador es objetivo en una franja continua ≥ 0,6 m y no hay
  ningún punto sin objetivo entre el primero y el último.

**Bandejas y corte (B-A)**
- **R9** Given una caja vacía S/M/L y pulpo cocido de 100 unidades, When se pulsa N veces (N = 4 /
  6 / 10, de `presses_to_fill` en `data/boxes/*.tres`), Then la caja está llena y quedan 50 unidades.
- **R10** Given una comanda de caja M, Then su ticket muestra la silueta y la letra «M» del mismo
  recurso que el rack (`BoxData.icon`/`short_label`, nuevo) antes del nombre de la receta.
- **R11** Given `level_01.tscn`, Then hay exactamente 6 `PassSlot`, cada uno con marca visible
  (≥ 18 px de lado a 1280×720), y pulsar con algo en la mano en la barra fuera de ellos y de la
  estación no suelta nada.

**Entrega (E-A)**
- **R12** Given el puesto 2 con una comanda viva y J1 con una caja que coincide, When J1 está a
  ≤ 2,0 m de la zona del puesto, Then la zona del suelo se ilumina en ≤ 0,1 s; con una caja que no
  coincide, se queda apagada.
- **R13** Given 4 comandas vivas, Then la franja de color de cada ticket es la del toldo de su
  puesto (`slot_id` 1–4 → rojo, azul, amarillo, verde).

**Nivel (N-A)**
- **R14** Given `level_01.tscn`, Then el camino más corto (Dijkstra de `test_level_01.gd`) de la
  cara de condimentar a la cara de pase de la estación mide 6–10 m.
- **R15** Given Individual con un solo personaje, When hace un pedido S sal+aceite desde cero con
  `measure_flow.gd`, Then recorre ≤ 50 m (hoy 78,9 m).

**Flujo completo**
- **R16** Given Individual con cambio, When se hacen 2 pedidos S con un solo pulpo (dos cajas en
  pasaplatos, corte de las dos, condimento y entrega), Then se completan 2 `order_completed` con
  exactamente 2 pulsaciones de `p1_switch` en total.
- **R17** Given Coop 2P con `measure_flow.gd`, When se encadenan 4 pedidos S, Then el tiempo medio
  de los pedidos 2–4 es ≤ 75 % del de hoy (≤ 4,6 s del bot).

### 4.4 Fichas de implementación propuestas (tras el gate)
| Orden | Ficha | Rol | Qué | Contratos |
|---|---|---|---|---|
| 1 | Enmienda de contratos de la estación sin bandeja | godot-architect | `scene-tree.md` (baja de `Tray`; dispensadores con caja en la mano, ADR-003 §8), redacción de D18 | **Gate** |
| 2 | Estación «al paso» | gameplay-engineer | dispensador/cuenco con la caja en la mano; cuenco solo con cachelos; `seasoning_station.tres`; tests R1–R8 | 1 |
| 3 | Datos de cajas y ticket con tamaño | gameplay + ui-engineer | `data/boxes/*.tres` 4/6/10, `BoxData` icono/letra, ticket; R9–R10 | — |
| 4 | Nivel: hueco a x ≈ 3,2 y 6 pasaplatos marcados | gameplay-engineer (nivel) | `level_01.tscn`, `kitchen_layout.tscn`, `level_walker.gd`; R11, R14 | 2, arte 6 |
| 5 | Zona de entrega iluminada y color de puesto | gameplay + ui-engineer | `order_stand`, ticket; R12–R13 | — |
| 6 | Arte de estación, rack, pasaplatos y puestos | asset-pipeline | sale de PUL-091 | — |
| 7 | QA y playtest del rediseño | qa-tester | `measure_flow.gd` adaptado (R15–R17) y playtest humano Individual/Coop | 2–6 |

---

## 5. Necesidades de arte (para PUL-091)

Qué debe **decir** cada pieza a la cámara del juego (1280×720, ortográfica, ≈ 56 px/m). Lo
condicionado a una alternativa va marcado.

| Pieza | Debe comunicar | Notas |
|---|---|---|
| Estación / línea de condimentos | «Aquí se echa, desde **este** lado»: frente de servicio claramente distinto del de cocina (color, rótulo, alfombrilla en el suelo del lado bueno) | En C-B, sin bandeja: la pieza es una **línea** que se recorre de izquierda a derecha en el orden del ticket (pimentón → sal → aceite → cachelos) |
| Dispensadores | Cuál es cuál **sin color** (forma + icono ≥ 20 px) y que dulce y picante son pareja exclusiva (juntos, con la llama en el picante); una marca de «pulsa aquí» en su frente | Separación ≥ 1,0 m entre centros (franja de objetivo ≥ 0,6 m, R8); icono en el frente de servicio; hoy los iconos flotan a 1,1 m y, por la inclinación de la cámara, se proyectan sobre el lado de la cocina (`PUL-087/despues/03_estacion_condimentos.png`) |
| Cuenco de cachelos | Raciones restantes (0–4) visibles de un vistazo; «se rellena desde la cocina» | En C-B, mismo frente que los dispensadores para alternar |
| Bandeja (solo C-A/C-C) | «Aquí va una caja», vacía/ocupada | Desaparece en C-B |
| Pasaplatos | 6 sitios **visibles** donde se deja algo (salvamantel, recuadro pintado), vacíos u ocupados | Hoy 9 invisibles (QA PUL-087 D9) |
| Cajas S/M/L | Tamaño legible por silueta (no solo escala) y la misma letra/icono que ticket y rack; progreso de corte (barra) y «llena» (tapa, brillo) | Con la caja en la mano, la fila de pegatinas sigue por encima del personaje |
| Rack de cajas | Qué pila es S, M y L, con el mismo icono del ticket | Igual en B-A y B-B; en B-B cambia de lado |
| Puestos | Número **y color** que casan con el ticket; placa clara detrás del `#id` (QA D1); zona de entrega en el suelo que se enciende con la caja correcta | E-A |
| Barra y hueco | Dónde se cruza (hueco de x ≈ 3,2 en N-A): umbral o cambio de suelo, que no parezca más barra | N-A |

---

## 6. Preguntas para el gate humano

| # | Pregunta | Opciones | Recomendación |
|---|---|---|---|
| G1 | ¿Cómo se condimenta? | **a)** C-B línea al paso, sin bandeja (cambia la redacción de D18) · b) C-A pase afinado con la bandeja · c) C-C dos estaciones | **a** — quita la espera de la bandeja única (P1) y los fallos de puntería (P2) |
| G2 | ¿Se puede condimentar una caja a medio cortar? | a) No, solo llena · b) Sí, desde fill > 0 | **a** con C-B (la caja ya llega llena a la mano); **b** solo si se elige C-A |
| G3 | Pulsaciones de corte S/M/L | **a)** 4/6/10 · b) 5/10/20 (hoy) · c) 3/5/8 | **a** — L pasa de 69 % a ≈ 53 % de las pulsaciones del pedido |
| G4 | Corte por pulsación o mantenido (D13) | **a)** Pulsación repetida (D13) · b) Mantener (B-C) | **a** — el aporreo es caos y sonido; el problema era la cantidad, no el gesto |
| G5 | Dónde está el rack de cajas | **a)** Servicio, como hoy · b) Cocina (B-B) | **a** — con C-B ya hay 1 cambio por pedido y el reparto coop sigue equilibrado |
| G6 | Hueco de la barra | **a)** Moverlo a x ≈ 3,2 (rodeo ≈ 8 m) · b) Dejarlo en x 7,7 (≈ 17 m) · c) Segundo hueco a la izquierda | **a** — cumple el 6–10 m de la feature |
| G7 | Raciones por cachelo cocido | **a)** 2 (máx. 4 en el cuenco) · b) 1 (hoy) | **a** — un pedido con cachelos cuesta hoy el doble en régimen |
| G8 | Entrega | **a)** E-A color + zona iluminada · b) E-A + E-B puestos más cerca · c) Sin cambios | **a** |
| G9 | Teclas | **a)** Una sola tecla de acción (D3/InputMap intactos) · b) Segunda tecla «soltar» | **a** — C-B no la necesita: cada pieza tiene un único verbo con la caja en la mano |
| G10 | Pasaplatos | **a)** 6 marcados, el resto de la barra no acepta objetos · b) 9 como hoy, pero visibles | **a** — menos sitios donde perder una caja |

## 7. Preguntas abiertas (no bloquean el gate)
1. **Paciencia y precio de la L.** Con L a 10 cortes, ¿se baja `base_points` de 12 a 11? Lo decide el
   playtest de la ficha 7 con las medidas de R17.
2. **Varias cajas en la mano.** C-B invita a pedir «llevar dos cajas»; queda fuera (rompe «un objeto
   en la mano», `movimiento-e-interaccion.md`).
3. **Lado de los dispensadores en C-B** (`operator_side_only`). Se propone mantenerlo: el cocinero no
   condimenta desde la cocina. Si el playtest de Individual lo pide, se libera en datos.
4. **Antirrebote con reloj de pared.** `SeasoningDispenser.clock` usa `Time.get_ticks_usec`: en
   pausa o a otra velocidad de juego cuenta tiempo real. No afecta al diseño; se apunta para la
   ficha 2 (usar el reloj de juego).
