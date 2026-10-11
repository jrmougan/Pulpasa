# Lenguaje de acciones: verbo, prompt y respuesta (Must, D26)

**Slug:** lenguaje-acciones · **Prototipo:** ninguno (nuevo en D26). **Estudio:**
`docs/evidence/PUL-119/README.md` (QA empírico + diseño UX + auditoría técnica, 2026-10-11).
**Contratos:** los fija la enmienda paralela PUL-120 (`docs/arch/`). Esta feature usa **nombres
neutrales**; los que van marcados *(propuesta)* son sugerencias que el contrato puede cambiar.

## Descripción
Tras el playtest de M3d, «no se distinguen muy bien las acciones». El contorno del objetivo solo dice
«esto es objetivo»; no dice **qué va a pasar** ni **por qué no pasa nada**. D26 fija un lenguaje común
para PC y móvil:

1. **Antes de pulsar**: sobre el objetivo activo de cada jugador aparece **un icono de verbo** (qué
   hará la pulsación) sobre una placa oscura. En móvil el botón de acción muestra el mismo icono.
2. **Al pulsar**: **siempre exactamente una respuesta** de ≥ 0,3 s, de éxito o de rechazo. Ninguna
   pulsación con objetivo queda muda.
3. **Entre pulsaciones**: el objetivo no salta de uno a otro por una diferencia pequeña (histéresis).
4. **Honestidad**: el verbo sale de **la misma regla que ejecuta la pulsación**, no de un
   `can_interact` aparte. Un objetivo cuya pulsación no haría nada **no se resalta ni muestra prompt**
   (se acaban los objetivos que «consumen sin hacer nada»: caja con la mano llena, olla con un cocido
   en la mano, `ItemSpawner` con la mano llena, `Slot` que rechaza, etc.), salvo que haya un **motivo
   útil** que enseñar (estado BLOQUEADO).

Pilares: *recetas más simples que Overcooked* (el verbo se lee de un vistazo, sin texto) y *caos
cooperativo* (cada jugador tiene su propio prompt).

## Vocabulario

### Verbos (8)
Id *(propuesta)* · rótulo de texto (tutorial, accesibilidad, tooltip de PC) · qué hace.

| Id | Rótulo | Qué hace |
|---|---|---|
| `PICK_UP` | COGER | Pasa a la mano un objeto suelto o de un pasaplatos; saca pulpo (nevera), cachelos crudos (cachelera) o una caja vacía (rack); retira de la olla el cocido listo |
| `DROP` | SOLTAR | Deja el objeto de la mano en un pasaplatos o mesa libre, o **en el suelo** delante del personaje cuando no hay objetivo |
| `COOK` | COCER | Mete pulpo o cachelos **crudos** en una plaza libre de la olla |
| `CUT` | CORTAR | Un corte del pulpo **cocido** de la mano sobre una caja no llena |
| `SEASON_SWEET` | ALIÑAR DULCE | Aplica el aliño dulce a la caja llena de la mano (o sustituye al picante) |
| `SEASON_HOT` | ALIÑAR PICANTE | Aplica el aliño picante a la caja llena de la mano (o sustituye al dulce) |
| `CACHELOS` | CACHELOS | En el cuenco: **repone** con cachelos cocidos de la mano, o **pone** cachelos en la caja llena de la mano |
| `TRASH` | TIRAR | Destruye lo que lleva la mano (cubo) o desecha el pulpo/cachelos **quemado** de la olla |

No hay verbo ENTREGAR: la entrega es **automática por zona** (D26 §5), el puesto no es objetivo.
No hay verbo QUITAR: lo mal hecho se tira (D25); el cuenco ya no quita (D26).

### Estados y motivos
| Estado | Se ve | Cuándo |
|---|---|---|
| **OK** | Icono del verbo **blanco** sobre la placa | La pulsación cambiará algo del mundo |
| **BLOQUEADO** | Icono del verbo **ámbar** + aspa **×** + **icono de motivo** | La pulsación no cambiará nada y el jugador ganaría con saber por qué |
| *(sin objetivo)* | Nada: ni contorno ni prompt | La pulsación no haría nada y no hay motivo útil que enseñar |

Motivos (6). Id *(propuesta)* · rótulo · cuándo:

| Id | Rótulo | Cuándo se muestra |
|---|---|---|
| `BOX_NOT_FULL` | caja a medias | Aliñar o poner cachelos en una caja vacía o a medio cortar |
| `BUSY` | ocupado | Meter crudo en una olla sin plaza libre; soltar al suelo donde no cabe (barra, pared) |
| `EMPTY` | vacío | Poner cachelos desde un cuenco con 0 raciones |
| `FULL` | lleno | Cortar sobre una caja ya llena (7.º corte); reponer un cuenco con 3 o 4 raciones |
| `ALREADY` | ya aplicado / ya lleva | Aliñar con el aliño que la caja ya lleva; poner cachelos en una caja que ya los lleva |
| `RAW` | sin cocer | Intentar cortar con pulpo crudo (concreción de D26: el pulso mudo más frecuente del estudio) |

**Prioridad cuando concurren varios motivos:** primero el estado del **objetivo** (`BUSY` > `FULL` >
`EMPTY`), luego el de lo que se **lleva** (`ALREADY` > `BOX_NOT_FULL` > `RAW`). Un único motivo por prompt.

## El prompt de acción
- **Dónde:** anclado sobre el objetivo activo, billboard **sin test de profundidad** (nunca queda
  tapado por el personaje, la barra o la caja que se lleva). Desplazamiento vertical `prompt_offset`
  *(0,9 m sobre la parte alta del objetivo)*. Para SOLTAR sin objetivo, anclado al **punto de soltar**
  (0,6 m delante, `PlayerConfig`) sobre el suelo.
- **Tamaño:** icono de verbo de **64 px a 1080 de alto** (`prompt_icon_px`), placa circular de 80 px
  (`prompt_plate_px`) color `#1B1B1F` al 85 %. Escala con el alto de pantalla (`alto / 1080`) con
  mínimo absoluto de **48 px** (`prompt_min_px`), también a 720. En móvil (2340×1080) es 64 px.
- **Colores** (en datos): OK `#FFFFFF`, BLOQUEADO `#FFB020` (ámbar), aspa ámbar. Contraste del icono
  sobre la placa ≥ 4,5:1 en los dos estados.
- **Icono de motivo:** 32 px a 1080, en la esquina inferior derecha de la placa, junto al aspa (el
  aspa de 24 px se superpone en la esquina superior derecha).
- **Jugadores:** cada jugador tiene su propio prompt; lleva un **marcador de jugador** (pastilla de
  16 px con el color del anillo del jugador y su número 1 o 2, solo en Local 2P). Si dos jugadores
  apuntan al mismo objetivo, los prompts se colocan lado a lado separados 8 px.
- **Sustituir:** cuando ALIÑAR vaya a **sustituir** el otro aliño, el prompt lleva una insignia de
  dos flechas circulares (16 px) en la esquina superior izquierda *(propuesta)*.
- **Contorno del objetivo:** se mantiene como refuerzo (no como señal principal), en **blanco
  cálido** `#FFF4D6` (el amarillo se retira: choca con el gorro de P2 y con el ámbar de BLOQUEADO);
  se dibuja también **a través** del personaje (silueta al 40 % de opacidad detrás de él) para que
  el jugador no tape lo que apunta. Un objetivo BLOQUEADO usa contorno ámbar.

```
        OK                      BLOQUEADO (caja a medias)       SOLTAR (sin objetivo)
     ┌──────┐                    ┌──────┐ ×                       (personaje)
     │ ALIÑ.│  placa 80 px        │ ALIÑ.│┌─┐ aspa 24 px            ↓ 0,6 m delante
     │ DULCE│  icono 64 px blanco │ DULCE││▭│ motivo 32 px        ┌──────┐
     └──────┘                    └──────┘└─┘ icono ámbar         │SOLTAR│  sobre el suelo
        ▼                           ▼                             └──────┘
   [dispensador]               [dispensador]
```

## La pulsación siempre responde
Cada pulsación con objetivo (o con la mano llena y sin objetivo) produce **exactamente una**
respuesta. Duraciones y desplazamientos en datos (`ActionLanguageData`, *propuesta*).

| Resultado | Respuesta visual (≥ 0,3 s; `response_duration` = 0,35 s) | Sonido |
|---|---|---|
| **Éxito (OK)** | El icono del verbo **salta**: sube 12 px y escala 1,0 → 1,25 → 1,0 en 0,35 s, y además la respuesta propia del objeto (gesto de aliño, vapor, polvo…) | El cue propio del verbo (tabla siguiente) |
| **Rechazo (BLOQUEADO)** | El **aspa ×** y el icono de motivo parpadean una vez y el prompt y el objetivo se **sacuden** ±6 px (`reject_shake_px`) en horizontal, 3 ciclos en 0,35 s | **Un único** cue `action_rejected` *(propuesta)* para todo rechazo, distinto de cualquier otro |

Pulsaciones consecutivas: cada pulsación reinicia su respuesta (no se apilan ni se pierden); el cue
suena una vez por pulsación. Mantener pulsado el corte no repite el rechazo (ver más abajo).

### Cues por verbo (nombres *propuesta* salvo los ya existentes en ADR-006)
| Verbo / evento | Cue | Notas |
|---|---|---|
| COGER | `pick_up` | Existente |
| SOLTAR | `drop` | Existente. Soltar en pasaplatos y en suelo comparten cue |
| COCER | `cook_start` | Existente |
| CORTAR | `cut` | Existente (corte). En cada corte |
| ALIÑAR (dulce o picante) | `season` | Existente; al sustituir suenan `unseason` y `season` (ADR-006 §4) |
| CACHELOS poner | `season` | Reutiliza el gesto del aliño |
| CACHELOS reponer | `drop` | Reutiliza |
| TIRAR en el cubo | `trash` | Existente; **sample propio**, distinto de `drop` y `discard` |
| TIRAR quemado en la olla | `discard` | Existente; **sample propio**, distinto de `trash` |
| Cocción lista | `cook_done` | Existente, pero con **sample propio** (hoy reutiliza `fx_ui_click`) |
| Aviso de quemado | `burn_warning` | Existente en el árbol de escena; sample propio, repetido cada 1 s |
| Caja llena (6.º corte) | `box_full` *(propuesta)* | Nuevo |
| Cambio de personaje | `character_switch` *(propuesta)* | Nuevo (hoy sin sonido) |
| Rechazo | `action_rejected` *(propuesta)* | Nuevo; sustituye a `season_error` para todos los rechazos de la tabla |

## Objetivo estable (histéresis)
- Un candidato **sustituye al activo** solo si su puntuación supera a la del activo en
  `hysteresis_margin` = **20 %** (`score_candidato > score_activo × 1,20`), o si el activo **deja de
  ser válido** (sale de alcance o del cono, se libera, o su estado pasa a «sin objetivo» en la
  tabla). El cambio de estado OK ↔ BLOQUEADO no invalida al activo.
- Puntuación, cono (±30°), `near_distance` (0,7 m) y alcance siguen siendo de `PlayerConfig`
  (`InteractionScoring`); D26 solo añade el margen. Con 2 jugadores, cada uno tiene su activo.

## Sin objetivo: SOLTAR al suelo
Con la mano **llena** y ningún objetivo, pulsar **suelta al suelo** delante del personaje (regla
vigente de `InteractionComponent`). D26 la hace **visible**: aparece el prompt SOLTAR (OK) en el punto
de soltar. Si ahí no cabe (`can_drop_freely()` = falso: barra, pared), el prompt es BLOQUEADO con
motivo `BUSY` y pulsar da el rechazo estándar (antes era una pulsación muda). Con la mano **vacía** y
sin objetivo no hay prompt ni respuesta.

## Mapa mano × objetivo → verbo / estado / motivo
Es la **especificación** que implementan las estaciones y que comprueba el test exhaustivo
(`test_action_matrix.gd`, tabla-guiada, AC1). Estados de la **mano**:

| Id | La mano lleva |
|---|---|
| M0 | Nada |
| M1 | Pulpo **crudo** |
| M2 | Pulpo **cocido** (entero o a medias) |
| M3 | Cachelos **crudos** |
| M4 | Cachelos **cocidos** |
| M5 | Caja **vacía** (fill = 0) |
| M6 | Caja **a medias** (0 < fill < 1) |
| M7 | Caja **llena** sin aliño |
| M8 | Caja **llena** con **aliño dulce** |
| M9 | Caja **llena** con **aliño picante** |

M7–M9 pueden llevar además cachelos (`+C`); solo importa para el cuenco (más abajo). El quemado
nunca llega a la mano. Notación de celda: `OK:VERBO` · `B:motivo` (BLOQUEADO) · `—` (no es objetivo:
ni contorno ni prompt; con la mano llena, pulsar cae en SOLTAR al suelo).

### A. Objetos simples (misma respuesta en toda la fila)
| Objetivo | M0 | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 | M9 |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 Nevera (spawner de pulpo crudo) | OK:COGER | — | — | — | — | — | — | — | — | — |
| A2 Cachelera (spawner de cachelos crudos) | OK:COGER | — | — | — | — | — | — | — | — | — |
| A3 Rack (spawner de caja vacía) | OK:COGER | — | — | — | — | — | — | — | — | — |
| A4 Ingrediente suelto (suelo o pasaplatos) | OK:COGER | — | — | — | — | — | — | — | — | — |
| A5 Pasaplatos o mesa **libre** (Slot vacío; el pasaplatos con objeto se rige por A4/B) | — | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR |
| A6 Cubo de basura (los 2) | — | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR | OK:TIRAR |
| A7 Puesto de entrega (**ya no es objetivo**, D26) | — | — | — | — | — | — | — | — | — | — |
| A8 Sin objetivo, con sitio delante (suelo) | — | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR | OK:SOLTAR |
| A9 Sin objetivo, sin sitio delante (barra, pared) | — | B:ocupado | B:ocupado | B:ocupado | B:ocupado | B:ocupado | B:ocupado | B:ocupado | B:ocupado | B:ocupado |

*Nota A5/A8:* un `Slot` con objeto y la mano llena tampoco es objetivo (hoy `Slot.can_interact` ya es
falso); el objeto del slot es el objetivo (fila B) y solo si su verbo no es `—`.

### B. Caja suelta (en el suelo o en un pasaplatos; no la que lleva otro jugador)
| Estado de la caja | M0 | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 | M9 |
|---|---|---|---|---|---|---|---|---|---|---|
| B1 Vacía (fill = 0) | OK:COGER | B:sin cocer | OK:CORTAR | — | — | — | — | — | — | — |
| B2 A medias (0 < fill < 1) | OK:COGER | B:sin cocer | OK:CORTAR | — | — | — | — | — | — | — |
| B3 Llena (con lo que lleve) | OK:COGER | B:lleno | B:lleno | — | — | — | — | — | — | — |

*B1/B2 con M2:* el 6.º corte llena la caja (cue `box_full`); si el pulpo se agota con la caja a medias,
la mano queda vacía (`EMPTY_EPSILON`, `corte-pulpo.md`).

### C. Olla (2 plazas; 4 estados según lo que contiene)
La olla evalúa dos cosas por separado: **qué se puede retirar** (para la mano vacía) y **si hay plaza
libre** (para el crudo).

| Estado de la olla | M0 | M1 / M3 (crudo) | M2 / M4 (cocido) | M5…M9 (cajas) |
|---|---|---|---|---|
| C1 Vacía o solo cociendo, con plaza libre | — | OK:COCER | — | — |
| C2 Con un cocido **listo**, sin quemado, con plaza libre | OK:COGER (el más antiguo) | OK:COCER | — | — |
| C3 Con un **quemado** (con o sin cocido; el quemado primero) | OK:TIRAR (desecha el más antiguo quemado) | OK:COCER si hay plaza libre; si no B:ocupado | — | — |
| C4 Sin plaza libre (2 plazas ocupadas), sin listo ni quemado | — | B:ocupado | — | — |
| C5 Sin plaza libre, con un cocido listo | OK:COGER | B:ocupado | — | — |

Tras TIRAR un quemado la siguiente pulsación (si queda un cocido listo) es COGER: el prompt cambia de verbo.
M2/M4 en la olla es `—` (hoy «consume sin hacer nada»).

### D. Dispensadores de aliño (solo con caja en la mano; solo desde el **lado de aliñar**)
Desde el **lado de pase** (cocina) los dispensadores no son objetivo para ninguna mano
(`operator_side_only`, `estacion-condimentos.md`).

| Dispensador | M0 | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 (dulce) | M9 (picante) |
|---|---|---|---|---|---|---|---|---|---|---|
| D1 Dulce | — | — | — | — | — | B:caja a medias | B:caja a medias | OK:ALIÑAR DULCE | B:ya aplicado | OK:ALIÑAR DULCE (sustituye) |
| D2 Picante | — | — | — | — | — | B:caja a medias | B:caja a medias | OK:ALIÑAR PICANTE | OK:ALIÑAR PICANTE (sustituye) | B:ya aplicado |

### E. Cuenco de cachelos (`stock` 0…4 raciones; reponer da +2)
| Caso | M0 | M1 | M2 | M3 | M4 | M5 / M6 | M7…M9 sin cachelos | M7…M9 con cachelos |
|---|---|---|---|---|---|---|---|---|
| E1 Lado de aliñar, `stock` 0 | — | — | — | — | OK:CACHELOS (repone) | B:caja a medias | B:vacío | B:ya aplicado («ya lleva») |
| E2 Lado de aliñar, `stock` 1 ó 2 | — | — | — | — | OK:CACHELOS (repone) | B:caja a medias | OK:CACHELOS (pone) | B:ya aplicado |
| E3 Lado de aliñar, `stock` 3 ó 4 | — | — | — | — | B:lleno | B:caja a medias | OK:CACHELOS (pone) | B:ya aplicado |
| E4 Lado de pase, `stock` 0 | — | — | — | — | OK:CACHELOS (repone) | — | — | — |
| E5 Lado de pase, `stock` 1 ó 2 | — | — | — | — | OK:CACHELOS (repone) | — | — | — |
| E6 Lado de pase, `stock` 3 ó 4 | — | — | — | — | B:lleno | — | — | — |

Reponer cabe si `stock + cachelos_portions_per_item (2) ≤ cachelos_stock_max (4)`, es decir con
`stock` ≤ 2. Poner gasta 1 ración. **El cuenco ya no quita** cachelos de la caja (D26); el antirrebote
`toggle_guard` desaparece.

### F. Zona de entrega (automática; no es objetivo de la pulsación)
| Zona del puesto N | M0…M6 | M7…M9 que **coincide** con la comanda viva del puesto | M7…M9 que **no coincide** (o puesto sin comanda) |
|---|---|---|---|
| F1 `DeliveryZone` | apagada | **Se ilumina** (≤ 0,1 s) y, al entrar, entrega sola | Apagada; entrar no entrega ni penaliza |

La zona no usa el prompt de acción: su señal es el color del toldo del puesto (`entrega-y-puntuacion.md`).

### Recuento
10 manos × 9 filas de A (A1–A9) = 90; × 3 estados de caja de B = 30; × 5 estados de olla de C = 50;
× 2 dispensadores × 2 lados de D = 40; 6 casos de E × 8 columnas de mano = 48; y 3 de F ⇒ **más de
250 combinaciones**; el mínimo exigido por la ficha es 40. Cada fila de «sin objetivo» (`—`) es también un caso: se comprueba que **no hay prompt ni
contorno** y que pulsar con la mano vacía no cambia nada.

## Estado legible en el mundo
Lo que el jugador debe leer sin acercarse. Medidas a 1080 de alto (`alto / 1080` en otros tamaños,
con los mínimos de píxel indicados).

| Elemento | Forma | Medida | Estados |
|---|---|---|---|
| **Cocción por plaza** | Anillo sobre la olla, una por plaza | Diámetro ≥ 64 px, **grosor ≥ 8 px** (`ring_thickness_px`) | Cociendo: arco blanco que crece 0 → 100 %. **Listo**: anillo completo verde + marca ✓ + destello + cue `cook_done`. **Quemándose**: ver siguiente fila. **Quemado**: anillo rojo fijo + humo |
| **Aviso de quemado** | Anillo + icono llama con «!» | Parpadeo ámbar `#FFB020` ↔ rojo `#E03A2F` a 3 Hz (±0,5) | Empieza a `warn_time` y dura hasta `burn_time` o hasta que se retire; ≥ **3 s** de antelación (`burn_time − warn_time ≥ 3`); cue `burn_warning` al empezar y cada 1 s |
| **Corte en la caja** | Barra de 6 segmentos + numeral `N/6` | Segmentos ≥ 14 px de ancho y **grosor ≥ 8 px**; numeral ≥ 36 px | Visible con 0 < N < 6; en el 6.º corte muestra `6/6` 0,5 s, cue `box_full` y desaparece. El numeral sale de `BoxData.presses_to_fill` |
| **Raciones del cuenco** | 4 muescas de cachelo sobre el cuenco | Cada muesca ≥ 24 px; relleno vs vacío con contraste ≥ 3:1 | `stock` muescas llenas, el resto huecas con contorno |
| **Personaje activo** | Anillo de suelo + marcador ▼ sobre la cabeza | Anillo activo **sólido, grosor ≥ 8 px**, color del jugador; marcador ▼ ≥ 24 px | Inactivo: anillo **discontinuo gris, ≤ 3 px**, sin marcador. Distinguibles en escala de grises (contraste ≥ 3:1 entre ambos) |

## Iconografía (lista para el asset-pipeline)
Todos los iconos: **monocromo** (silueta blanca; el ámbar/blanco lo aplica el prompt), fondo
transparente, arte vectorial exportado a 128×128 y utilizable a 64 px (verbos) y 32 px (motivos),
trazo grueso (≥ 8 % del lado), sin texto ni letras. Deben ser **distinguibles en gris a 64 px**: la
máscara binarizada de dos iconos distintos solapa **≤ 60 %** (IoU ≤ 0,6, AC4). Nombres de fichero
*(propuesta)*: `icon_verb_<id>` y `icon_reason_<id>`.

### Verbos
| Id | Silueta (descripción) | Se distingue de… por |
|---|---|---|
| `icon_verb_pick_up` | Silueta **alta y estrecha**: bloque pequeño (objeto) abajo con una **flecha gruesa hacia arriba** que lo sobrepasa, y dos tenazas curvas a los lados de la flecha | Flecha hacia arriba y forma vertical (SOLTAR es ancho y bajo) |
| `icon_verb_drop` | Silueta **ancha y baja**: **flecha gruesa hacia abajo** que termina sobre una **línea de suelo larga** que ocupa todo el ancho del icono, con el bloque (objeto) apoyado en ella | Línea de suelo horizontal y flecha hacia abajo |
| `icon_verb_cook` | **Cacerola de perfil**: cuerpo en trapecio ancho con dos asas laterales planas y tapa, más **tres volutas de vapor** onduladas encima | Asas laterales + vapor (ninguna otra silueta tiene dos asas) |
| `icon_verb_cut` | **Cuchillo de carnicero** en diagonal a 45°: hoja ancha trapezoidal con un agujero redondo cerca del lomo y mango corto | Silueta diagonal alargada con agujero |
| `icon_verb_season_sweet` | **Pimentonera**: bote cilíndrico bajo con tapa perforada, **inclinado** 30° y vertiendo **tres puntos redondos** (polvo) | Bote cilíndrico + puntos redondos |
| `icon_verb_season_hot` | **Guindilla**: pimiento alargado y curvo (forma de «C» estirada) con rabillo en la punta y **dos lenguas de llama** a un lado. Es el icono del aliño picante en dispensador, ticket y pegatina | Silueta curva con rabillo y llamas (no es un bote) |
| `icon_verb_cachelos` | **Trío de patatas** cocidas: tres piezas ovaladas irregulares apiladas en pirámide, una con un trozo recortado (cuña) y un ojo pequeño | Conjunto de bultos redondeados sin eje |
| `icon_verb_trash` | **Cubo** en trapecio con aros horizontales, **tapa levantada e inclinada** y una **flecha corta** que entra por arriba | Tapa inclinada + flecha entrante |

El aliño dulce usa la pimentonera en el dispensador, el ticket y la pegatina de la caja; el picante,
la guindilla (D26 §7): el par ya no depende del color.

### Motivos (32 px; se acompañan del aspa)
| Id | Silueta (descripción) | Se distingue de… por |
|---|---|---|
| `icon_reason_box_not_full` | **Caja** cuadrada con el **relleno sólido hasta la mitad** y una línea de nivel marcada a media altura | Caja medio llena |
| `icon_reason_busy` | **Reloj de arena**: dos triángulos unidos por el vértice, arena en el inferior | Forma de «X» rellena en vertical |
| `icon_reason_empty` | **Cuenco** (semicírculo) **vacío**: solo contorno discontinuo, sin relleno | Contorno punteado, hueco |
| `icon_reason_full` | **Cuenco** (semicírculo) **macizo con un montículo** que sobresale por encima del borde | Relleno sólido con copete |
| `icon_reason_already` | **Check ✓** dentro de un **círculo doble** | Marca ✓ con anillo |
| `icon_reason_raw` | **Llama** pequeña **tachada** con una barra diagonal | Llama + diagonal |

### Marcas y refuerzos
| Id | Silueta | Uso |
|---|---|---|
| `icon_mark_cross` | **Aspa ×** gruesa a 45°, extremos redondeados | Estado BLOQUEADO (ámbar) |
| `icon_mark_replace` | **Dos flechas circulares** formando un anillo | Insignia «sustituye» del prompt de aliño |
| `icon_mark_ready` | Check ✓ grueso | Anillo de cocción lista |
| `icon_mark_burn_warning` | Llama con signo «!» dentro | Aviso de quemado |
| `icon_mark_active` | **Triángulo** ▼ apuntando abajo, relleno | Sobre la cabeza del personaje activo |
| `icon_mark_offscreen` | **Chevron** ▶ grueso con un círculo pequeño detrás (el personaje) | Flecha de borde que señala al personaje inactivo fuera de cuadro (`controles-tactiles.md`) |
| `icon_mark_player_1`, `_2` | Pastilla redonda con «1» o «2» | Marcador de jugador en el prompt (Local 2P) |

## Criterios de aceptación
Los AC de reglas puras se testean contra el núcleo de acción (`RefCounted`, sin nodos 3D); los de
escena, con las estaciones instanciadas, el detector real y el **reloj de juego inyectado**
(sin `await` de tiempo real). La consulta «¿qué haría la pulsación?» tiene el nombre que fije el
contrato (PUL-120); aquí se llama **la consulta de acción** (devuelve verbo, estado y motivo).

- **AC1 (matriz exhaustiva)** Given la tabla A–F con todas las combinaciones de mano × objetivo × estado del objetivo, When un test tabla-guiada recorre cada una montando la escena real, Then la consulta de acción devuelve exactamente el verbo, el estado (OK / BLOQUEADO / sin objetivo) y el motivo de la celda, para ≥ 250 combinaciones y 0 discrepancias. *Test:* `test_action_matrix.gd` + fixture CSV de la tabla (no es dato de balance).
- **AC2 (el verbo no miente)** Given cualquier combinación de AC1, When se ejecuta la pulsación, Then si la consulta decía OK el mundo cambia (mano, contenido o estado de una estación) y se emite 1 señal de éxito; si decía BLOQUEADO no cambia nada del mundo y se emite 1 señal de rechazo con el motivo; si decía «sin objetivo» no se emite ninguna respuesta (salvo SOLTAR al suelo, que es OK). No existe ninguna combinación con cambio de mundo y sin señal, ni con señal de éxito y sin cambio. *Test:* `test_action_matrix.gd`.
- **AC3 (tamaño del prompt)** Given una captura a 1920×1080 con un objetivo OK, Then el icono de verbo mide ≥ 64×64 px, la placa ≥ 80 px, y el contraste icono/placa es ≥ 4,5:1; a 1280×720 el icono mide ≥ 48 px. *Test:* captura + medición del nodo.
- **AC4 (siluetas distinguibles)** Given los 8 iconos de verbo renderizados a 64 px en escala de grises y binarizados al 50 %, Then el solape (IoU) de cualquier par de máscaras es ≤ 0,6; y para los 6 motivos a 32 px, igual. *Test:* `test_icons_silhouettes.gd` (renderiza y calcula IoU).
- **AC5 (OK frente a BLOQUEADO)** Given un objetivo OK y uno BLOQUEADO, Then el primero muestra el icono blanco sin aspa; el segundo, icono ámbar + aspa + icono de motivo (no nulo), y sus colores y la presencia del aspa salen de datos. *Test:* `test_action_prompt.gd` (estado del nodo).
- **AC6 (éxito responde)** Given una pulsación OK, When se procesa, Then durante `response_duration` ≥ 0,3 s el icono salta (sube 12 px y escala 1,25) y suena exactamente 1 cue del verbo (tabla de cues). *Test:* `test_action_prompt.gd` (estado de la animación con reloj inyectado) + contador del servicio de audio.
- **AC7 (rechazo responde)** Given una pulsación BLOQUEADA (p. ej. cortar con pulpo crudo; 7.º corte; mismo aliño; olla sin plaza; cuenco vacío o lleno; caja a medias en un dispensador), When se procesa, Then el aspa y el motivo parpadean, el prompt y el objetivo se sacuden ±6 px durante ≥ 0,3 s, suena exactamente 1 `action_rejected` y no cambia nada del mundo. Dos pulsaciones a 0,1 s producen 2 cues y 2 respuestas (ninguna se pierde). *Test:* `test_action_prompt.gd`.
- **AC8 (cues distintos)** Given el mapa evento → sonido, Then `trash`, `discard`, `cook_done`, `burn_warning`, `box_full`, `character_switch` y `action_rejected` usan 7 streams **distintos entre sí y distintos** de `pick_up`, `drop`, `cook_start`, `cut` y `season`; y cada evento hace sonar su cue exactamente 1 vez. *Test:* test de datos del mapa de audio + `test_feedback_cues.gd`.
- **AC9 (histéresis, regla)** Given un objetivo activo A con puntuación s y un candidato B, When B puntúa 1,19·s, Then el activo sigue siendo A; When B puntúa 1,21·s, Then B pasa a activo en ≤ 1 frame; When A deja de ser válido (fuera de alcance o liberado), Then B pasa a activo aunque puntúe menos de 1,2·s. El margen sale de `hysteresis_margin`; con 0,0 en datos se comporta como hoy. *Test:* `test_interaction_scoring.gd`.
- **AC10 (sin parpadeo)** Given un jugador quieto entre dos objetivos cuyas puntuaciones oscilan ±10 % durante 5 s, Then el objetivo activo cambia 0 veces; Given el mismo jugador moviéndose 1 m hacia B hasta que B supera a A por > 20 %, Then cambia 1 vez. *Test:* `test_interaction_detector.gd` (puntuaciones inyectadas).
- **AC11 (sin objetivo, mano llena)** Given un jugador con una caja en la mano y ningún objetivo con sitio libre delante, Then aparece el prompt SOLTAR OK en el punto de soltar; When pulsa, Then la caja queda en el suelo y suena `drop`. Given el mismo jugador de cara a la barra o a una pared, Then el prompt es BLOQUEADO con motivo `busy`, y pulsar da 1 rechazo y la caja sigue en la mano. Given la mano vacía y ningún objetivo, Then no hay prompt. *Test:* `test_action_matrix.gd` (filas A8–A9).
- **AC12 (el jugador no tapa el objetivo)** Given un personaje que lleva una caja y apunta al cubo desde el sur (la cámara lo ve de espaldas), Then el prompt es visible en su totalidad y el contorno del objetivo se ve detrás del personaje (≥ 25 % de los píxeles del contorno visibles). *Test:* captura a 1920×1080 en `docs/evidence/<ficha>/`.
- **AC13 (corte: mantener pulsado)** Given pulpo cocido (100 u) y una caja vacía, When se mantiene pulsada la acción 1,05 s (reloj de juego), Then la caja tiene 6 cortes (llena) y el pulpo 50 u, sin 7.º corte ni rechazo mientras sigue pulsada; When se suelta y se vuelve a pulsar sobre la caja llena, Then hay 1 rechazo `full`. Given un toque de < 0,2 s, Then hay 1 corte. El primer corte ocurre al pulsar; los demás cada `cut_repeat_interval` = 0,2 s. La repetición se arma solo si el verbo al empezar era CORTAR y se para si el objetivo cambia, la caja se llena o el pulpo se agota. *Test:* `test_box_cut_hold.gd`.
- **AC14 (contador y estado del corte)** Given una caja con k cortes (k = 1…5), Then se ve el contador `k/6` con k segmentos llenos, numeral ≥ 36 px y barra de ≥ 8 px de grosor a 1080; con k = 0 no se ve; en k = 6 muestra `6/6` 0,5 s, suena `box_full` 1 vez y se oculta. *Test:* `test_box_counter.gd` + captura.
- **AC15 (anillos legibles)** Given la olla con una cocción en curso a 1080 de alto, Then el anillo mide ≥ 64 px de diámetro con trazo ≥ 8 px; Given la cocción lista, Then el anillo es verde con ✓ y suena `cook_done` 1 vez. *Test:* medición del nodo + captura.
- **AC16 (aviso de quemado)** Given un cocido que sigue en la olla (`warn_time` = 7 s, `burn_time` = 10 s), When pasan 7,0 s (±0,1) desde que quedó listo, Then el anillo parpadea ámbar ↔ rojo a 3 Hz (±0,5) y suena `burn_warning`; vuelve a sonar cada 1 s hasta 3 veces; When el jugador lo retira a los 8 s, Then el parpadeo y los avisos cesan; When pasan 10 s, Then queda quemado (anillo rojo fijo). Given los datos, Then `burn_time − warn_time ≥ 3` (test de datos). *Test:* `test_burn.gd` (ampliado) + test de datos.
- **AC17 (raciones del cuenco)** Given el cuenco con `stock` = 2, Then se ven 4 muescas, 2 llenas y 2 huecas, con contraste de relleno ≥ 3:1 y cada muesca ≥ 24 px a 1080; con 0 y con 4 se ven 0 y 4 llenas. *Test:* `test_cachelos_bowl_view.gd` + captura a 1920×1080.
- **AC18 (personaje activo)** Given Individual con dos personajes, Then el activo muestra anillo sólido ≥ 8 px y ▼ sobre la cabeza, y el inactivo un anillo discontinuo ≤ 3 px sin ▼; en escala de grises el contraste entre ambos anillos es ≥ 3:1; al cambiar (Q o botón) suena `character_switch` 1 vez y el cambio ocurre en < 0,2 s (D3). *Test:* `test_player_ring.gd` + captura.
- **AC19 (iconografía D26 §7)** Given los dispensadores, el ticket y la pegatina de la caja, Then el aliño picante usa `icon_verb_season_hot` y el dulce `icon_verb_season_sweet`, y sus siluetas tienen IoU ≤ 0,6 (distinguibles sin color); Given `rack.tscn` y `box.tscn`, Then no contienen etiquetas S, M ni L; Given el HUD, Then ningún texto ni clave de traducción contiene «Cajas / minuto» (ni «cajas/min»). *Test:* `test_icons_silhouettes.gd` + `test_hud.gd` + `test_level_01.gd`.
- **AC20 (no objetivo = no se resalta)** Given cualquier celda `—` de la tabla con una estación a ≤ 1,5 m dentro del cono, Then esa estación no emite contorno ni prompt y no se publica como objetivo; el objetivo activo pasa a otro candidato válido o a ninguno. *Test:* `test_action_matrix.gd`.
- **AC21 (Local 2P)** Given dos jugadores que apuntan al mismo objetivo, Then se ven 2 prompts, cada uno con su marcador de jugador, separados ≥ 8 px y sin solaparse; cada jugador ve el verbo de su propia mano. *Test:* `test_action_prompt.gd`.

## Datos (`.tres`)
`ActionLanguageData` *(propuesta; `data/config/action_language.tres`)*: `hysteresis_margin` (0,20),
`cut_repeat_interval` (0,2 s), `response_duration` (0,35 s), `reject_shake_px` (6),
`prompt_icon_px` (64 a 1080), `prompt_plate_px` (80), `prompt_min_px` (48), `prompt_offset` (0,9 m),
`ring_thickness_px` (8), `ring_diameter_px` (64), colores OK `#FFFFFF`, BLOQUEADO `#FFB020`, aviso
`#E03A2F`, placa `#1B1B1F`, contorno `#FFF4D6`; `warn_blink_hz` (3), `warn_repeat_interval` (1 s).
En `IngredientData`: `warn_time` (7) y `burn_time` (10) ya existen. En `BoxData`: `presses_to_fill` (6).
En el mapa de audio: los cues nuevos y los samples propios. Los iconos son assets
(`godot/assets/ui/…`, ficha de arte), no datos.

## Verificación
GUT para AC1, AC2, AC4, AC5–AC11, AC13, AC14, AC16–AC21 (núcleo + escena con reloj inyectado);
capturas a 1920×1080 en `docs/evidence/<ficha>/` para AC3, AC12, AC14, AC15, AC17, AC18.
El test exhaustivo AC1 es la **puerta**: ninguna estación se da por terminada si falla una celda.

## Preguntas abiertas
1. **Soltar al suelo por accidente.** Al hacerse objetivo SOLTAR en cualquier punto sin objetivo,
   una pulsación cerca de una estación que no admite lo que llevas deja el objeto en el suelo. Es
   el comportamiento vigente, ahora visible. Si el playtest lo ve peligroso (sobre todo en móvil),
   se exige mantener pulsado 0,3 s para soltar al suelo, sin tocar el resto.
2. **Dispensador desde el lado de pase.** Hoy no es objetivo. ¿Mostrar BLOQUEADO con un motivo
   «otro lado» (icono de barra con flecha)? Se deja para el playtest; añade un 7.º motivo.
3. **Rechazo de aliño `ALREADY`.** D25 decía «no hace nada» y se dejó una pregunta abierta
   (`condimentacion.md` nº 2); D26 la cierra: es BLOQUEADO con motivo `ALREADY` y cue de rechazo.
4. **Cue de rechazo único.** `action_rejected` sustituye a `season_error` y `deliver_error` en estos
   casos; el contrato decide si se conservan como alias.
5. **Háptica en móvil.** Vibración corta en OK y doble en rechazo (`controles-tactiles.md`, pregunta 3).
