# Biblia de arte de Pulpasa — v1 (archivada)

> **Archivada el 2026-10-06 por PUL-072.** La vigente es [`art-bible.md`](art-bible.md) (v2). Se
> conserva como referencia de los assets de M3 (PUL-044..PUL-055); los §§ que la v2 cita «de la v1»
> siguen vigentes donde la v2 lo dice.

Autor: PUL-042 (game-designer). Rige D20 (arte propio hecho en Blender por un agente con MCP), D14
(3D, cámara ortográfica fija), D16 (solo licencias confirmadas) y D18 (estación de condimentos y
distintivos en la caja). Si algo choca con `docs/design/decisions.md`, manda `decisions.md`.
Todas las fichas de asset (PUL-044..PUL-055) deben cumplirla; los criterios medibles están en §2
y §3 para que un test o una captura los comprueben.

Moodboard: [`moodboard.svg`](moodboard.svg) (lámina propia: paleta, siluetas y pares crudo/cocido)
y las descripciones de §1.2.

## 1. Estilo

### 1.1 Dirección

**Low-poly estilizado, caricaturesco y cálido**, de formas gordas y simples, con **color plano
sin texturas fotográficas**. Tono: feria gallega de verano, lúdica y legible, no realista. Pilares
del juego que el arte debe servir: caos cooperativo (todo se lee de un vistazo en pantalla
compartida) e identidad gallega (cobre, madera, arpillera, pulpo, farolillos).

Principios:
1. **Silueta primero.** Cada objeto se reconoce por su silueta en negro desde la cámara.
2. **Formas grandes, detalle pequeño solo si aporta información** (pegatinas, número de puesto).
3. **Facetas planas** (shading flat o smooth con pocos polígonos y bordes marcados); sin
   normal maps ni roughness maps.
4. **Exageración de proporciones**: cabezas grandes, patas de pulpo gruesas, platos y cajas algo
   más grandes que su tamaño real para que se lean (véase §2.3).
5. **Un solo lenguaje**: mismo grosor de bisel, mismo nivel de detalle y misma paleta en todas las
   piezas. Sin piezas «realistas» entre piezas caricaturescas.

### 1.2 Referencias (descripciones, sin imágenes de terceros)

No se incluyen imágenes ajenas (D16). Referencias que guían el modelado, descritas con palabras:

- **Pulpería de romería** (Carballiño, O Grove): carpa o toldo blanco/crudo a rayas, mesas largas
  de madera con mantel de papel, bancos corridos, cartel pintado a mano con el nombre de la
  pulpería y el precio de la ración.
- **Caldeiro de cobre**: caldero panzudo, abierto, con dos asas de aro, cobre cálido con
  reflejos anaranjados, borde grueso, apoyado sobre un fogón de leña o una trébede de hierro negro;
  humo y vapor blanco.
- **Plato de madera (prato de madeira)**: plato redondo u ovalado de madera clara, algo hondo,
  donde el pulpo troceado «á feira» se sirve con rodajas de cachelos, aceite, sal gorda y pimentón
  rojo. Se usa también como «caja» del juego.
- **Pulpo á feira**: tentáculos rosa-morados con ventosas visibles, cortados en rodajas, sobre
  cachelos amarillentos; pimentón rojo espolvoreado; aceite de oliva dorado.
- **Ambiente**: tierra apisonada y hierba de campo de feria, farolillos y banderines de colores
  cruzando la calle, bancos de madera, sacos de arpillera, cajas de pescado de madera, cubos de
  hielo, neveras de feria.
- **Estilo gráfico**: la lectura limpia de los juegos de cocina cooperativos en cámara fija
  (siluetas gruesas, color por función) y el low-poly artesanal, **solo como principio de claridad,
  nunca copiando modelos de ningún juego**.

## 2. Reglas técnicas

### 2.1 Unidades, escala y proporciones

- **1 unidad Blender = 1 m = 1 unidad Godot.** Escala del objeto aplicada (`Ctrl+A → Scale`) y
  rotación aplicada antes de exportar; todo objeto exportado con escala (1,1,1).
- La escala se comprueba en `godot/scenes/scale_check.tscn` (cámara ortográfica `size = 12.74`,
  inclinación ≈ 38°). Hay que colocar el modelo junto al personaje placeholder y comprobar que
  encaja.
- Medidas de referencia (alto × ancho × fondo, en m; ±10 %):

| Pieza | Medidas objetivo |
|---|---|
| Personaje | 1,8 de alto (con cabeza grande; ancho de hombros 0,6) |
| Encimera / mesa | alto 1,0 (superficie en y = 1,0), fondo 0,8, módulos de 1 m de largo |
| Nevera / arcón | 1,6 × 0,9 × 1,0 (arcón de feria; el placeholder actual mide 1,61 × 2,33 × 0,91; se puede bajar mientras no tape estaciones detrás) |
| Olla (caldeiro + fogón) | boca a ≈ 1,0 de altura, diámetro del caldeiro 0,7, ancho total 0,9 |
| Cachelera | 0,6 × 0,5 × 0,5 |
| Estantería de cajas | 1,2 × 1,6 × 0,5 |
| Puesto de entrega | mostrador 1,0 de alto, 1,4 de ancho |
| Caja/plato pequeña, mediana, grande | 0,34 / 0,42 / 0,49 de diámetro; 0,10 de alto (más la comida) |
| Pulpo crudo / cocido (entero) | 0,45 de largo aprox. |
| Cachelos (patata) | 0,10–0,14 por pieza |

  Las piezas que se sostienen (caja, pulpo, cachelos) pueden ser algo mayores que lo real, nunca
  menores.
- **Cuadrícula del nivel: 1 m.** Estaciones y encimeras encajan en múltiplos de 1 m (kit modular
  de PUL-054). Se permiten medias unidades solo en piezas pequeñas.

### 2.2 Presupuesto de polígonos (triángulos tras triangular, por pieza exportada)

| Tipo | Triángulos máx. | Objetivo |
|---|---|---|
| Personaje (con rig) | 2 500 | ≈ 1 800 |
| Objeto que se sostiene (pulpo, caja, cachelos; cada variante) | 600 | ≈ 300 |
| Estación (olla, arcón, cachelera, estantería, estación de condimentos, puesto) | 1 500 | ≈ 800 |
| Encimera (módulo) | 300 | ≈ 150 |
| Prop de decoración (farolillo, banco, saco) | 300 | ≈ 100 |
| Entorno completo (suelo + carpa + decoración) | 6 000 | ≈ 3 500 |

Escena de nivel completa (todo en pantalla): ≤ 40 000 triángulos. Lo que no se ve desde la
cámara (cara inferior, interior de cajas cerradas) se elimina. Sin subdivisión en el export (los
modificadores se aplican, salvo `Mirror` y `Bevel`, que se aplican también al exportar).

### 2.3 Orientación, origen y colocación

- **Frente del objeto = −Z de Godot.** En Blender (eje Z arriba, eje Y adelante) equivale a
  modelar con el frente hacia **+Y** y exportar con «+Y Up» activado (el exportador glTF de
  Blender convierte a Y-up y el frente +Y de Blender pasa a −Z de Godot). Se comprueba con
  `test_assets_models.gd` (PUL-043).
- **Origen:**
  - Estaciones, encimeras, personaje, props de suelo: origen en el **centro de la base**, a nivel
    del suelo (y = 0).
  - Objetos sostenidos (caja, pulpo, cachelos): origen en el **centro de la base** del objeto
    (el `HoldPoint` lo coloca a la altura de las manos del personaje sin desplazamientos).
  - Módulos de encimera: origen en el centro de la base del módulo de 1 m.
- Los nodos de contrato de las escenas (`docs/arch/scene-tree.md` §3: colisiones, `Model`,
  puntos de anclaje) **no los crea el modelo**: el `.glb` solo trae mallas, materiales y, en el
  personaje, esqueleto y animaciones. Colisiones: no se exportan (`-colonly` prohibido).
- Cada asset es **una raíz `Node3D`/`Empty`** con el nombre del asset; hijos con nombres claros
  (`Body`, `Lid`…). Para marcadores usar `Empty` con prefijo `Anchor_` (p. ej.
  `Anchor_Sticker_Paprika`), que el ingeniero usa para colocar nodos.

### 2.4 Nombres y rutas

- Ficheros y objetos en `snake_case` inglés, sin espacios ni acentos: `octopus_raw`,
  `box_medium`, `seasoning_station`.
- Materiales: `mat_<nombre>` (`mat_copper`, `mat_wood_light`). Mallas: `<asset>_<parte>`.
  Animaciones: `Idle`, `Walk`, `Pick`, `WalkWhileHolding`, `Cut` (nombres exactos, PUL-044).
- Fuente: **`art/blender/<asset>.blend`** (un `.blend` por ficha).
- Export: **`godot/assets/models/<categoría>/<asset>/<asset>.glb`**. Categorías: `characters`,
  `food`, `items`, `stations`, `furniture`, `environment`. Una variante de color o de estado
  va en el mismo `.glb` como objetos separados (`octopus_raw`, `octopus_cooked`) o en `.glb`
  hermanos del mismo directorio, nunca en categorías distintas.
- Export con `tools/blender_export.py` (PUL-043): glTF 2.0 binario (`.glb`), solo la colección
  `export`, `+Y Up`, modificadores aplicados, **sin cámaras ni luces**, materiales exportados,
  texturas embebidas solo si las hay, animaciones solo en el personaje.
- Fuera del repo: no se guardan texturas de terceros. Licencia de todo el contenido: propia
  (se registra en `docs/assets/licenses.md` por el coordinador).

### 2.5 Materiales y texturas

- **Un material por color plano** (Principled BSDF: solo `Base Color`; `Roughness` 0,8; `Metallic` 0
  salvo el cobre con 0,3). Ninguna textura en piezas de gameplay.
- Se permite **una textura pequeña por asset (≤ 256×256, sin mipmaps especiales)** únicamente
  para: ventosas del pulpo, rayas de la carpa, iconos de pegatinas (ver §3.4) y número del puesto.
  Si varias piezas comparten texturas, usar un atlas de ≤ 512×512 en
  `godot/assets/models/<categoría>/<asset>/`.
- Sin vértices de color como único portador del color (el import de Godot los ignora por defecto).
- Los materiales de Blender deben usar nombres de la paleta (§2.6) y colores exactos.
- Godot importa los materiales del `.glb` como `StandardMaterial3D` sombreado (iluminado). El
  resaltado de interacción es un shader aparte (`asset-pipeline`), no se pinta en el modelo.

### 2.6 Paleta (hex sRGB)

Paleta cerrada: cada pieza usa **como máximo 5–6 colores** de esta tabla (los valores exactos se
aplican en Blender como `Base Color` hex). Tonos cálidos para lo interactivo, fríos/apagados para
el fondo, para que los objetos de gameplay destaquen sobre el escenario.

**Madera, tela y estructura**

| Nombre | Hex | Uso |
|---|---|---|
| `wood_light` | `#D9A86C` | Platos/cajas, encimeras (superficie) |
| `wood_mid` | `#B07A45` | Bancos, estantería, patas de mesa |
| `wood_dark` | `#6E4A2B` | Contornos, vigas, cajones |
| `canvas_cream` | `#F1E6CC` | Carpa, mantel de papel, arpillera clara |
| `canvas_stripe` | `#C9483D` | Rayas de la carpa (rojo feria) |
| `burlap` | `#B8955A` | Saco de la cachelera |
| `iron_black` | `#34302E` | Fogón, trébede, herrajes |
| `steel_grey` | `#A9B0B5` | Nevera/arcón, mostrador metálico |
| `ice_blue` | `#BFE3EE` | Hielo del arcón |

**Cobre y fuego**

| Nombre | Hex | Uso |
|---|---|---|
| `copper` | `#C8672E` | Caldeiro |
| `copper_light` | `#E8914F` | Reflejos/borde del caldeiro |
| `copper_dark` | `#8A4220` | Interior, abolladuras |
| `fire` | `#FFB02E` | Llamas |
| `steam` | `#F4F7F8` | Vapor (partículas, no modelo) |

**Comida** (versión detallada en §3)

| Nombre | Hex | Uso |
|---|---|---|
| `octopus_raw` | `#C9B0BC` | Pulpo crudo (rosa-grisáceo pálido) |
| `octopus_raw_dark` | `#9A8294` | Ventosas/sombra del pulpo crudo |
| `octopus_cooked` | `#B8283D` | Pulpo cocido (rojo-morado saturado) |
| `octopus_cooked_dark` | `#6E1A3A` | Ventosas/puntas del pulpo cocido |
| `potato_raw` | `#8E6B47` | Patata cruda con piel (marrón terroso) |
| `potato_cooked` | `#F2D56B` | Cachelo cocido (amarillo cálido claro) |
| `potato_cooked_dark` | `#D8A93C` | Corte/borde del cachelo |
| `paprika_sweet` | `#D6361F` | Pimentón dulce |
| `paprika_hot` | `#8F1A14` | Pimentón picante |
| `salt` | `#F7F4EC` | Sal gorda |
| `oil` | `#F2C230` | Aceite |

**Entorno**

| Nombre | Hex | Uso |
|---|---|---|
| `ground_dirt` | `#9C8566` | Suelo de tierra apisonada (zona jugable) |
| `ground_grass` | `#7DA05A` | Hierba (fuera de la zona jugable) |
| `ground_stone` | `#B9B2A5` | Losas de piedra |
| `bunting_blue` | `#2F6FB5` | Banderines, azul Galicia |
| `bunting_yellow` | `#F4C542` | Banderines |
| `bunting_green` | `#4E9B5F` | Banderines |
| `lantern_warm` | `#FFD27F` | Farolillos (emisivo suave) |

**Personajes** (dos variantes, J1 y J2)

| Nombre | J1 | J2 |
|---|---|---|
| Delantal / gorro | `#2F6FB5` (azul) | `#E0A02E` (ámbar) |
| Camisa | `#F7F4EC` | `#F7F4EC` |
| Pantalón | `#4A4F63` | `#4A4F63` |
| Piel (opcional, dos tonos) | `#EBC49A` | `#A8734D` |

El aro de selección de PUL-035 usa los mismos azul y ámbar, así que el color de la ropa y el del aro
coinciden.

**UI y distintivos de la caja**: ver §3.4; los colores de los iconos son los de la tabla de comida.

### 2.7 Iluminación y sombreado

- Una `DirectionalLight3D` y ambiente suave como `scale_check.tscn`/nivel; sombras activadas. El
  arte no incluye luces; los farolillos solo llevan material emisivo.
- **Contorno**: opcional, a cargo de un shader de post-proceso del motor, no geometría. El modelo no
  incluye «casco invertido».
- Cara oculta: sin dobles caras; normales hacia fuera (`Recalculate Outside`).

## 3. Legibilidad desde la cámara ortográfica

Condiciones de la cámara (`camera_rig.tscn`): ortográfica, `size = 12.74` m de alto visible,
inclinación ≈ 38° sobre el horizonte, fija. En una ventana de 1920×1080 un metro ocupa
≈ 85 px de alto en pantalla. Un objeto de 0,3 m ocupa unos 25–40 px: es el tamaño crítico de caja, pulpo y cachelos. Se ve desde arriba y por delante: **la
cara superior y la frontal importan, el reverso no.**

### 3.1 Reglas generales

1. **Silueta**: en una captura a 1920×1080 los objetos de gameplay se distinguen entre sí en negro
   puro. Prueba: convertir la captura a blanco/negro (o rellenar de negro) y reconocer cada tipo.
2. **Detalle mínimo**: ningún elemento significativo (pegatina, ventosa) menor de **6 px** en la
   captura de 1920×1080 (≈ 0,07 m en el objeto).
3. **Contraste**: los pares de estados (crudo/cocido) se separan al menos **3:1 de relación de
   luminancia** entre sí (§3.2, §3.3). Contra suelo (`ground_dirt`, L ≈ 0,25) y encimera
   (`wood_light`, L ≈ 0,44), los objetos sostenibles se distinguen por **saturación o borde oscuro**
   (`wood_dark`/`iron_black`, 0,02 m), no solo por luminosidad: una patata cruda (L ≈ 0,17) sobre
   el suelo solo da 1,4:1, así que lleva siempre borde o sombra de contacto.
4. **Jerarquía por color**: gameplay saturado (pulpo, cobre, pegatinas), mobiliario en madera/grises
   cálidos, entorno apagado y de baja saturación.
5. **Nada alto tapa la cámara**: el entorno (carpa, banderines, farolillos) va **fuera de la zona
   jugable** y por detrás o por encima del plano de las estaciones; ningún elemento por delante
   del plano de juego sobresale más de 1 m de alto.
6. Cada personaje se distingue por **color de delantal/gorro** (azul/ámbar) y por el aro de PUL-035;
   un tercer rasgo (p. ej. forma del gorro) distingue a daltónicos: J1 gorro redondo, J2 gorro alto
   de cocinero.

### 3.2 Pulpo crudo y cocido

| | Crudo | Cocido |
|---|---|---|
| Color principal | `#C9B0BC` rosa-grisáceo pálido | `#B8283D` rojo-morado saturado |
| Ventosas | `#9A8294` | `#6E1A3A` |
| Forma | Cuerpo y patas **lacias, flácidas, extendidas**; cabeza de saco redondeada | Patas **enroscadas y rizadas** hacia arriba, cuerpo más pequeño |
| Brillo | Mate (roughness 0,9) | Algo más brillante (roughness 0,5) |
| Luminosidad relativa | alta (≈ 0,47) | baja (≈ 0,12); relación 3,1:1 |

Los dos estados difieren **a la vez por color, luminosidad y silueta** (no solo por tono): se
distinguen aunque el jugador sea daltónico. Además existe el estado **troceado** (rodajas de patas,
`octopus_pieces`) para la caja: rodajas redondas de ≈ 0,05 m, color del cocido más claro
(`#D4506A`) con corte `#F4C6CC`.

### 3.3 Cachelos crudos y cocidos

| | Crudo | Cocido |
|---|---|---|
| Color | `#8E6B47` marrón terroso, piel opaca | `#F2D56B` amarillo cálido, borde `#D8A93C` |
| Forma | Patata **entera, ovalada, irregular** | Patata **partida en 2–3 trozos**, caras de corte planas y claras (a la vista desde arriba) |
| Cantidad | 1–2 patatas | 3–4 trozos amontonados |

Contraste crudo/cocido: marrón oscuro (L ≈ 0,17) frente a amarillo claro (L ≈ 0,68), relación 3,3:1, y
entero frente a partido. En el plato, los cachelos cocidos se leen como «montón amarillo» sobre el
pulpo rojo.

### 3.4 Cajas, platos y distintivos (D18)

- Tres tamaños con **proporción de diámetro 0,34 : 0,42 : 0,49** y **bordes de color por tamaño**
  para identificarlos incluso apilados en la estantería: pequeña `#D9A86C` con aro `#2F6FB5`,
  mediana con aro `#4E9B5F`, grande con aro `#C9483D` (el aro es una banda plana de 0,02 m).
- **Relleno progresivo de pulpo** (D8/PUL-047): las cajas muestran hasta 3 niveles de relleno
  visibles desde arriba (vacía, a medias, llena) con rodajas `#D4506A`.
- **Distintivos (pegatinas) de D18**: un disco plano de **0,10 m de diámetro** pegado en el **borde
  frontal-superior** de la caja (visible desde la cámara), uno por condimento, colocados
  en un máximo de 4 huecos (marcadores `Anchor_Sticker_0..3`) en arco sobre el borde. El color del
  disco **es el del condimento** y lleva icono en blanco/negro (el mismo icono del ticket de
  comanda, PUL-030/PUL-040):

| Condimento | Color del disco | Icono |
|---|---|---|
| Pimentón dulce | `#D6361F` | pimiento / flama simple |
| Pimentón picante | `#8F1A14` | pimiento + chispa |
| Sal gorda | `#F7F4EC` (borde `#6E4A2B`) | copos |
| Aceite | `#F2C230` | gota |
| Cachelos | `#F2D56B` (borde `#8E6B47`) | patata |

  Los discos del pimentón dulce y el picante deben distinguirse por **luminosidad** (`#D6361F` ≈ 0,17;
  `#8F1A14` ≈ 0,07: relación 2,0:1) **y** por icono (con chispa o sin ella), porque son exclusivos (D4) y no pueden
  confundirse. Las pegatinas se modelan como un único objeto reutilizable con la textura de iconos
  del atlas; en Godot el ingeniero decide cuáles se muestran según los condimentos de la caja.
- Los discos no se modelan en bajorrelieve; son planos con un offset de 1 mm para evitar z-fighting.

### 3.5 Estaciones y entorno

- **Olla**: el caldeiro de cobre es el objeto más saturado y claro de la zona del fogón; la boca
  abierta deja ver el interior `#8A4220`, con **plazas visibles** (anclas `Anchor_Slot_0..N`) para
  la capacidad (D9) y llamas `#FFB02E` bajo el caldero, sin tapar el borde.
- **Arcón de pulpo**: gris acero con tapa abierta y hielo `#BFE3EE` y un tentáculo asomando
  (señal «aquí está el pulpo»).
- **Cachelera**: saco de arpillera `#B8955A` con la boca enrollada y patatas `#8E6B47` visibles.
- **Estantería de cajas**: tres montones identificados por el aro de color del tamaño (§3.4).
- **Estación de condimentos**: mesa baja en madera con cinco recipientes (pimentón dulce, picante,
  sal, aceitera, cachelos) en el **color del condimento** (los mismos de las pegatinas); un recipiente
  por lado o zona según PUL-040. Los recipientes no superan 0,25 m de alto para no ocultar la caja.
- **Puesto de entrega**: mostrador con número grande y toldillo de color propio (4 colores),
  además de un hueco legible para el `#id` de la comanda.
- **Entorno**: suelo de tierra en la zona jugable; hierba y losas fuera; carpa con rayas
  `canvas_cream`/`canvas_stripe` al fondo; farolillos y banderines en la parte alta, nunca delante de
  una estación.

## 4. Lista de assets: revisión de PUL-044..PUL-055

Cobertura vs. el juego actual (`level_01`, PUL-016..PUL-018, D18). Estado: **ok** = la ficha cubre
el asset; **ajuste** = ficha existente con un cambio recomendado; **falta** = no está en ninguna
ficha.

| Ficha | Asset | Estado | Presupuesto (tris) | Observación |
|---|---|---|---|---|
| PUL-044 | Personaje + rig + 5 clips | ajuste | 2 500 | Falta confirmar clip `Idle` en bucle de 1–2 s y `Cut` con ciclo corto (pulsación repetida, D13). Dos variantes en **un mismo `.blend` con malla compartida** y materiales distintos, para no duplicar rig. Añadir marcador `Anchor_Hold` en las manos (altura de la caja) |
| PUL-045 | Pulpo crudo, cocido, troceado | ok | 600 c/u | Separar `octopus_pieces` (rodajas) para el contenido de la caja; el estado «cortado» de la caja usa esas rodajas |
| PUL-046 | Cachelos crudos y cocidos | ajuste | 300 c/u | Añadir variante **«cantidad»** (1, 2, 3 piezas) o piezas sueltas para montones en la caja y en la olla |
| PUL-047 | Platos/cajas (3 tamaños) + relleno + pegatinas | ajuste | 600 c/u | Añadir el objeto **`sticker`** reutilizable (disco 0,10 m con atlas de 5 iconos ≤ 256×256) y los 4 `Anchor_Sticker_*`. Tres niveles de relleno como objetos ocultables, no tres mallas distintas |
| PUL-048 | Caldeiro + fogón | ok | 1 500 | Separar `pot_body` (caldeiro) y `stove_base` (fogón) para que puedan moverse/animarse; llamas y vapor son partículas de motor, no modelo (lo dice la ficha) |
| PUL-049 | Arcón de pulpo | ok | 1 500 | Incluir **tapa separada** (`Lid`) por si se anima; tentáculo asomando |
| PUL-050 | Cachelera | ok | 1 500 | Alinear con PUL-046: patatas visibles del mismo modelo; retirar el placeholder `cachelera*` (ya en `owns`) |
| PUL-051 | Estantería de cajas | ok | 1 500 | Usa las 3 cajas de PUL-047 como referencia de tamaño; no incrusta las cajas del juego: estas se instancian aparte |
| PUL-052 | Estación de condimentos | ajuste | 1 500 | Bloqueada por PUL-040. Falta: **recipientes por condimento** con el color de §3.4 (la ficha enumera los cinco, correcto); **aceitera** como pieza propia; y **huecos/anclas para la caja** (`Anchor_Box_A/B` si hay dos lados). Sin `touches_scenes`: la escena la crea una ficha de gameplay |
| PUL-053 | Puesto de entrega | ajuste | 1 500 | 4 variantes de color de toldillo (puestos 1–4, D12) y sitio para el número; el número se dibuja con textura o se deja como `Label3D` del motor (preferible: legible a cualquier tamaño) |
| PUL-054 | Encimeras modulares (recta, esquina, extremo) | ajuste | 300 c/u | Valorar **módulos largos de 2 m y 3 m**: o bien un kit de 1 m que se repite (los placeholders `table_long/medium/square` miden 2,79 m, etc.), y **tablero de apoyo** para la caja con altura exacta 1,0 m |
| PUL-055 | Entorno de romería | ajuste | 6 000 | Dividir en **3 `.glb`** para que se puedan asignar a otros agentes sin chocar: `ground` (suelo), `tent` (carpa y vigas), `decor` (farolillos, banderines, bancos). Mantiene `owns` único (`romeria/**`) |

### 4.1 Assets que faltan (propuestas de ficha nueva)

| Asset | Motivo | Propuesta |
|---|---|---|
| **Botes de condimento** (pimentón dulce/picante, sal, aceitera) | D18 los sustituye por estación, pero el diseño de PUL-040 puede necesitar **recipientes manipulables** o solo recipientes fijos en la mesa | Decidir tras PUL-040; si son fijos, los cubre PUL-052 |
| **Aro de selección / indicador de personaje** (PUL-035) | Existe como placeholder; debe casar con la paleta (azul/ámbar) | Ficha pequeña de ajuste, no de modelado: usar `#2F6FB5`/`#E0A02E` |
| **Texto de puestos y números 1–4** | Ver PUL-053 | `Label3D` del motor o atlas |
| **Pegatinas** (disco + atlas de iconos) | Núcleo de D18; falta en PUL-047 si no se asigna | Incluido en PUL-047 (ajuste) |
| **Iconos de condimentos/estrellas** (UI) | Son 2D (PUL-030/PUL-031) y deben usar la misma paleta | Revisión de colores en la ficha de UI, no en estas fichas |
| **Partículas** (vapor, fuego, humo, chispas al cortar) | No son modelo; pertenecen a motor | Ficha de VFX posterior (M3/M4), con la paleta de §2.6 |
| **Mobiliario menor** (banco, saco, barril) | Útil para dar vida al entorno | Incluido en `decor` de PUL-055 |

### 4.2 Nada que quitar

No se propone retirar ninguna ficha. **PUL-013** (superada por PUL-044) queda fuera. Si PUL-041
cambia la planta, solo cambian PUL-054 y PUL-055 (cantidad y disposición de módulos), no los modelos
individuales.

### 4.3 Orden recomendado de modelado

1. **PUL-043** (pipeline) y la escala con un cubo.
2. **Pulpo, cachelos y caja** (PUL-045, 046, 047): son lo que más se ve y fija el lenguaje.
3. **Personaje** (PUL-044).
4. **Estaciones** (PUL-048, 049, 050, 051, 053, 052).
5. **Encimeras y entorno** (PUL-054, 055) al final: dependen de la planta elegida (PUL-041).

## 5. Lista de comprobación por asset (para el reviewer y el asset-pipeline)

- [ ] Escala 1 u = 1 m, medidas dentro del ±10 % de §2.1, escala aplicada (1,1,1)
- [ ] Triángulos ≤ presupuesto de §2.2
- [ ] Frente −Z, origen en el centro de la base
- [ ] Solo colores de §2.6 (hex exactos), un material por color, sin texturas salvo las permitidas
- [ ] Nombres y rutas de §2.4; `.blend` y `.glb` versionados
- [ ] Captura en `docs/evidence/<id>/` de la cámara del nivel: silueta reconocible, contrastes de §3
- [ ] Pares crudo/cocido distinguibles por forma, luminosidad y color
- [ ] Licencia propia anotada (a través del coordinador)

## 6. Preguntas abiertas

- ¿Estilo de contorno (shader de post-proceso) sí o no? Decisión de arte con el responsable.
- ¿Los botes de condimento se manipulan o son fijos? Depende de PUL-040.
- ¿Cuántos tonos de piel y variantes de personaje (más de dos)? Fuera de la alpha.
