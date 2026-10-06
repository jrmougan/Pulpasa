# Biblia de arte de Pulpasa — v2

Autor: PUL-072 (game-designer), 2026-10-06. Sustituye a la v1 ([`art-bible-v1.md`](art-bible-v1.md),
PUL-042), que queda archivada como referencia de los assets de M3. Rigen D14 (3D, cámara ortográfica
fija), D16 (solo licencias confirmadas), D18 (estación de condimentos y distintivos), D20 (arte propio
hecho en Blender por un agente con MCP) y D21 (marca **PulpaSA**). Si algo choca con
`docs/design/decisions.md`, manda `decisions.md`.

**Decisiones del responsable (2026-10-06)**, ya incorporadas: tono de **franquicia satírica** con raíz
de romería gallega (§7); marca **propuesta A · Mariña** de [`brand.md`](brand.md) (PUL-088), con la
paleta ajustada para que encaje (§2.7); muro del fondo de **granito gallego** (§1.4); **tilt-shift
opcional**, apagado por defecto (§1.3); objetivo de **60 fps a 1080p en la RTX 3090** de desarrollo,
sin máquina modesta de referencia (§4.3); comensales con **ropa de romería** (§1.4).

Todas las fichas de la estética v2 (PUL-073..PUL-087) deben cumplirla. Los criterios medibles
(medidas, triángulos, texturas, contrastes, píxeles) están en §2, §4 y §5 para que un test o una
captura los comprueben.

**Referencia visual única**: [`style-refs/referencia-elegida-2026-10-06.png`](style-refs/referencia-elegida-2026-10-06.png),
elegida por el responsable el 2026-10-06. Es del responsable y está en el repo; no se añaden imágenes de
terceros (D16). Lámina de paleta propia: [`moodboard-v2.svg`](moodboard-v2.svg) (la de la v1 sigue en
[`moodboard.svg`](moodboard.svg)). Estado de partida: [`style-refs/actual-2026-10-06/`](style-refs/actual-2026-10-06/).

## 0. Qué cambia respecto a la v1

| Tema | v1 (M3) | v2 (M3b) |
|---|---|---|
| Estilo | Low-poly caricaturesco, color plano, feria de verano luminosa | **Diorama estilizado** de puesto callejero, detallado y «vivido», luz cálida sobre ambiente algo apagado |
| Texturas | Prohibidas salvo 4 casos (≤ 256²) | **Permitidas**: texturas pequeñas pintadas/procedurales de la biblioteca v2 (PUL-074), atlas por asset, AO horneado, normal maps sencillos |
| Materiales | Un color plano por material, roughness 0,8 | Biblioteca cerrada de materiales estilizados con desgaste (§3) |
| Presupuestos | Personaje 2 500, estación 1 500, nivel 40 000 tris | 2–5 veces más (§4), con objetivo de rendimiento medido (60 fps a 1080p) |
| Detalle | Uniforme en todo | **Por zonas** (§5): fondo denso, lo jugable siempre limpio |
| Cocina | Caldeiro de cobre, arcón, cesto, platos de madera | Cocedores de acero, tanque de pulpos, sacos, **bandejas rojas**, encimeras de acero |
| Marca | Cartel «PULPO Á FEIRA» | **PulpaSA** (D21) en cartel, toldo, uniformes, bandejas, kioscos y UI (§7) |
| Legibilidad | §3 de la v1 | Se conserva y se amplía al estado **quemado** y a las bandejas (§6) |

Lo que **no** cambia (sigue vigente tal cual de la v1): unidades, escala y medidas de referencia
(§2.1 de la v1), orientación, origen y nodos de contrato (§2.3 de la v1), nombres y rutas (§2.4 de la
v1), la cámara y los colores de pegatinas y condimentos (§3.4 de la v1).

## 1. Estilo

### 1.1 Dirección

**Diorama estilizado de un puesto de comida callejero en una romería**, visto como una maqueta: todo
es pequeño, macizo y un poco gastado, como si alguien lo hubiera usado todo el verano. Los objetos son
**estilizados** (formas simplificadas, bordes biselados, proporciones algo gordas), pero sus
**superficies cuentan historias**: acero cepillado con arañazos, pintura descascarillada en las aristas,
plástico rojo con roces, madera clara gastada, arpillera, tierra apisonada con rodadas y charcos.

Tono (decidido): **franquicia satírica** con raíz de romería; la «franquicia» PulpaSA montada en un
campo de feria gallego (§7). El pilar de identidad gallega se mantiene con atrezo y vegetación (§1.4), no con el cobre de la v1.

Principios (por orden de prioridad):
1. **Lo jugable se lee primero.** Silueta, color y estado de cada objeto con el que se interactúa se
   reconocen en una captura a 1920×1080 sin acercarse (§6). Ningún detalle se pone encima de eso.
2. **Detalle donde no se juega.** El fondo y los laterales de las estaciones pueden ser densos (§5);
   las superficies de juego (huecos de encimera, bocas de olla, bandejas) son limpias.
3. **Estilizado, nunca fotorrealista.** Formas simples y biseles generosos (2–3 cm en piezas de 1 m);
   el realismo está en el material, no en la forma. Sin escaneos, sin fotografías, sin ruido fino.
4. **Gastado, no sucio.** El desgaste va en aristas y zonas de uso (bordes de encimera, asas, suelo de
   paso) y se ve a la distancia de la cámara; no hay manchas que parezcan comida o charcos que parezcan
   objetos.
5. **Un solo lenguaje.** Mismo bisel, misma biblioteca de materiales (§3), misma luz (§1.3) y misma
   escala de texel (§4.2) en todos los assets. Un asset nuevo se juzga junto a los ya hechos.

### 1.2 Análisis de la referencia

Descripción de `referencia-elegida-2026-10-06.png` (1024×572, plano cenital del nivel completo), para
que los agentes la traduzcan sin interpretarla cada uno a su manera:

- **Composición**: igual que `level_01` (cámara alta, frontal, ligeramente inclinada). Puesto en
  U: cocina al fondo, barra central, columna de encimeras a cada lado y cuatro kioscos de entrega
  abajo. Fuera del perímetro, a izquierda y derecha, mesas con comensales; arriba, tanques y valla.
- **Fondo del puesto**: muro de bloques de hormigón gris azulado con musgo en las juntas; encima, un
  **toldo rojo** grande con el cartel de la marca (letras con borde claro, aspecto de cartel
  luminoso) y dos tanques de gas plateados con tapa roja detrás. Cámaras de vigilancia en las
  esquinas del toldo (toque satírico de «franquicia»). Dos pizarras de menú oscuras colgadas.
- **Cocina**: tanque/acuario azul de plástico con agua clara, burbujas y pulpos rosas dentro, mangueras
  oscuras que salen al suelo; dos **cocedores cilíndricos de acero** con tapa, piloto rojo/verde,
  vapor blanco abundante y mangueras de gas roja y verde por el suelo hacia una bombona; mesitas de
  acero con pulpo troceado; sacos de arpillera con patatas; cajas de cartón; jarras de barro.
- **Encimeras**: acero inoxidable gris medio con tornillos en las esquinas, patas y balda inferior
  con cajas de cartón; encima tablas de madera, cuchillos, cuencos de barro con sal, botes rojos de
  pimentón, botellas de aceite y un limón. En el frente de la barra de condimentos, **etiquetas de
  color** (amarillo, rojo, rojo oscuro, blanco, amarillo) que identifican cada dispensador.
- **Bandejas**: pilas de **bandejas rojas de plástico** sobre las encimeras de la derecha y
  recipientes blancos; en cada kiosco, una caja blanca para llevar con faja roja.
- **Suelo**: tierra apisonada marrón claro con **rodadas** de neumático, **charcos** oscuros, piedrecitas,
  hojas secas y patatas sueltas; **rejillas de desagüe** metálicas oscuras delante de las ollas y en
  el paso inferior; algo de hierba en los bordes.
- **Kioscos de entrega**: cuerpo de acero gris oscuro, toldillo de lona con festón en **rojo, azul,
  amarillo y verde** (1–4), TPV con pantalla azul clara y teclado de colores, número negro en disco
  blanco en el frente.
- **Personajes**: cocineros pequeños y cabezones, camiseta blanca, pantalón azul marino, **gorra de
  color** (amarillo, azul) y aro azul en el suelo bajo el jugador activo.
- **Entorno**: valla de malla metálica, árboles frondosos y **helechos** en las esquinas, barriles de
  madera, cajas, sacos, generador beige con bidones, bombona azul, cables negros por el suelo,
  postes con **guirnaldas de bombillas** cálidas rodeando el puesto, banderines de colores en las mesas.
- **UI**: paneles gris pizarra oscuros con borde gris claro, título en ámbar, nombre de la comanda en
  blanco, condimentos como discos de color, barra de paciencia ámbar y **reloj tipo display de 7
  segmentos** en ámbar. HUD compacto abajo a la izquierda con el mismo panel.
- **Luz**: día nublado o final de tarde; luz principal suave desde arriba-izquierda con sombras
  cortas y blandas; ambiente algo apagado (verdes y marrones desaturados) y **bombillas cálidas**
  encendidas que añaden puntos de luz; ligera viñeta y oclusión ambiental marcada en contactos y
  esquinas. Lectura de **maqueta** (miniatura) por el grano del detalle y la luz suave.

Qué **no** se toma de la referencia:
- La marca «McPULPO», el lema «American octopus franchise» y la combinación rojo/amarillo con
  diagonales del toldo: se sustituyen por PulpaSA (D21, §7).
- Los textos en inglés de la UI (los textos siguen el idioma del juego).
- El gris pizarra y el ámbar de la UI: se usan los colores de la marca (§2.6, §2.7); se conserva
  la forma (paneles, reloj de 7 segmentos, barra).
- El muro de bloques de hormigón: es de granito (§1.4).
- Las patatas sueltas en el suelo jugable y la comida de atrezo en encimeras jugables (rompen §6.1).
- Los charcos tan oscuros como un objeto (se aclaran, §5).

### 1.3 Luz y post-proceso (lo aplica PUL-073)

- **Luz principal**: `DirectionalLight3D` cálida y suave (≈ `#FFE9C8`), elevación 50–60°, desde
  arriba-izquierda de la cámara; sombras activadas y blandas (PCF suave, sin bandas). Las sombras
  nunca ocultan una superficie jugable entera (§6.1, regla 6).
- **Ambiente**: cielo cubierto, algo apagado y frío (≈ `#9AA6A8`), energía baja para que las bombillas
  se noten; tonemapping **AgX** (o Filmic si AgX satura mal la comida), exposición fija.
- **Bombillas**: guirnaldas con material emisivo `bulb_warm` (§2.2). Como luces reales, **≤ 6
  `OmniLight3D` sin sombra** sobre la zona jugable y **≤ 2 con sombra** en total; el resto, solo
  emisivo con glow suave.
- **SSAO** activado (radio pequeño, contactos y esquinas); **glow** suave solo para emisivos.
- **Viñeta y gradación**: ligera, cálida en medios tonos; la saturación global no baja de la de
  la referencia para que la comida y las pegatinas sigan vivas.
- **Tilt-shift** (desenfoque de profundidad de campo arriba y abajo de la pantalla): **opcional y
  desactivado por defecto**; si se activa, la banda nítida cubre todo el perímetro de encimeras y los
  cuatro kioscos, y se apaga si resta legibilidad. Valor en `.tres` (PUL-073), apagado por defecto (decidido).
- El arte no incluye luces ni cámaras en los `.glb` (sigue la regla de la v1, comprobada por
  `test_assets_models.gd`).

### 1.4 Identidad gallega en la v2

La referencia es genérica de «comida callejera»; la identidad gallega (pilar del juego) se mete con
atrezo de fondo, sin tocar lo jugable:
- **Vegetación**: carballos (robles) y **fentos** (helechos) en las esquinas, hierba de campo.
- **Barro y madera**: **cuncas** y jarras de barro (vino), platos de madera en las mesas de los
  comensales, barriles y bancos corridos.
- **Romería**: banderines y guirnaldas de bombillas, mesas largas con mantel de papel.
- **Granito** (decidido): el muro del fondo es de **sillares de granito gallego** gris claro con
  mica, juntas oscuras y musgo abajo, en lugar de los bloques de hormigón de la referencia.
- **Comensales** (decidido): figuras **estáticas** con ropa de romería —boinas, pañuelos, chalecos,
  rebecas— en tonos apagados de Z3 (§5); nunca con `player_*`, `stand_*` ni el azul marino de la
  marca como color principal, para que no se lean como cocineros ni puestos. Comen pulpo en platos
  de madera y beben en cuncas; algunos con vaso de PulpaSA (guiño satírico).

## 2. Paleta v2 (hex sRGB)

Valores **de base** (albedo medio) de cada material. Las texturas de PUL-074 varían ±10 % de
luminosidad alrededor de ese valor y añaden desgaste, pero **el color medio de una superficie a la
distancia de la cámara debe quedar a ≤ 10 % de su hex**. Derivados de la referencia muestreando la
imagen y ajustados para cumplir los contrastes de §6.

Jerarquía: **lo jugable saturado y cálido** (comida, bandejas, pegatinas, toldillos, gorras);
**mobiliario en acero neutro**; **entorno apagado** (verdes y marrones de baja saturación).

### 2.1 Estructura y mobiliario

| Nombre | Hex | Uso |
|---|---|---|
| `steel_light` | `#B9BEC2` | Acero inoxidable claro: cocedores, tapas, frentes de cajón |
| `steel_top` | `#9EA5AA` | **Superficie de encimera** (tablero de apoyo; base de los contrastes de §6) |
| `steel_mid` | `#7D868D` | Frentes, patas y baldas de encimera |
| `steel_dark` | `#4E5458` | Cuerpo de kiosco, rejillas, sombras de acero |
| `paint_grey` | `#5F6A6E` | Metal pintado (postes, marcos); desconcha a `steel_mid` |
| `paint_beige` | `#B29770` | Metal pintado del generador y cajas eléctricas |
| `plastic_red` | `#C8402F` | **Bandejas**, tapas de tanque (= acento pimentón de la marca, §2.7) |
| `plastic_blue` | `#3E78B0` | Tanque de pulpos, bombona azul |
| `wood_used` | `#B58A5C` | Tablas de corte, cajas de fruta, bancos |
| `wood_dark` | `#553E30` | Barriles, vigas, mangos de cuchillo |
| `cardboard` | `#B8935F` | Cajas de cartón (bajo encimeras, fondo) |
| `burlap` | `#9C7D59` | Sacos de patatas |
| `clay` | `#A85A3A` | Cuncas, jarras y cuencos de barro |
| `canvas_red` | `#C8402F` | Rayas rojas del toldo grande (alternan con `brand_paper`) |
| `granite` | `#8C8A84` | Muro de sillares de granito (moteado de mica `#B5B2AA` y `#4F4D49`, juntas `#5E5C57`, musgo `#5E6B3A`) |
| `rubber_black` | `#24272A` | Cables, mangueras de agua, neumáticos |
| `hose_red` / `hose_green` | `#8E2F2A` / `#3F6B45` | Mangueras de gas de los cocedores |

### 2.2 Luz, agua y efectos

| Nombre | Hex | Uso |
|---|---|---|
| `bulb_warm` | `#FFD58A` | Bombillas (emisivo, energía 1,5–3) |
| `water_tank` | `#8FC6D8` | Agua del tanque (semitransparente, alfa 0,5–0,6) |
| `steam` | `#F4F7F8` | Vapor (partículas de PUL-065/069, no modelo) |
| `fire_gas` | `#5AA0FF` → `#FFB02E` | Llama de gas (base azul, punta naranja) |
| `screen_tpv` | `#8FD3F0` | Pantalla del TPV (emisivo suave) |

### 2.3 Suelo y entorno

| Nombre | Hex | Uso |
|---|---|---|
| `ground_dirt` | `#A18668` | Tierra apisonada de la zona jugable |
| `ground_track` | `#8A735A` | Rodadas y zonas pisadas (≤ 1,3:1 contra `ground_dirt`) |
| `ground_puddle` | `#6E6A60` | Charcos (aclarados respecto a la referencia, §5) |
| `grate_dark` | `#45484A` | Rejillas de desagüe |
| `grass` | `#66713C` | Hierba fuera de la zona jugable |
| `foliage` | `#3E5A2E` | Helechos y copas (sombra `#2C4324`) |
| `fence` | `#525E5E` | Valla de malla |

### 2.4 Comida (detalle y contrastes en §6)

| Nombre | Hex | Uso |
|---|---|---|
| `octopus_raw` | `#E0AFB2` | Pulpo crudo (rosa pálido) |
| `octopus_raw_dark` | `#9A6E7A` | Ventosas y contorno del crudo |
| `octopus_cooked` | `#B8283D` | Pulpo cocido (rojo-morado saturado) |
| `octopus_cooked_dark` | `#6E1A3A` | Ventosas y puntas del cocido |
| `octopus_pieces` | `#D4506A` | Rodajas (corte `#F4C6CC`) |
| `octopus_burnt` | `#2A2320` | Pulpo quemado (carbón; brasas `#5A2A1E`) |
| `potato_raw` | `#8E6B47` | Patata cruda con piel |
| `potato_cooked` | `#F2D56B` | Cachelo cocido (borde `#D8A93C`) |
| `potato_burnt` | `#2E2620` | Cachelo quemado |
| `tray_liner` | `#F4EFE6` | Papel salvamanteles dentro de la bandeja (= `brand_paper`; patrón de símbolos al 15 %, §6.4) |

### 2.5 Condimentos (pegatinas, dispensadores y etiquetas)

Sin cambios respecto a la v1 (§3.4 de la v1) para no tocar UI ni pegatinas de PUL-059/060:
pimentón dulce `#D6361F`, picante `#8F1A14`, sal `#F7F4EC` (borde `#6E4A2B`), aceite `#F2C230`,
cachelos `#F2D56B` (borde `#8E6B47`). Las etiquetas de color del frente de la barra (referencia) usan
exactamente estos valores.

### 2.6 Puestos, jugadores y UI

| Nombre | Hex | Uso |
|---|---|---|
| `stand_1` | `#D2473F` | Toldillo del puesto 1 (rojo) |
| `stand_2` | `#3F7CC8` | Puesto 2 (azul) |
| `stand_3` | `#E8C23A` | Puesto 3 (amarillo) |
| `stand_4` | `#4FA05A` | Puesto 4 (verde) |
| `player_1` | `#2F6FB5` | Gorra/delantal J1 y su aro (igual que la v1 y PUL-035) |
| `player_2` | `#E0A02E` | Gorra/delantal J2 y su aro |
| `uniform_shirt` | `#F2F0EC` | Camiseta |
| `uniform_pants` | `#1D3557` | Pantalón (= `brand_navy`) |
| `ui_panel` | `#13202F` | Cuerpo de tickets y HUD (= `brand_night`, alfa 0,92) |
| `ui_header` | `#1D3557` | Cabecera de ticket y paneles con la insignia (= `brand_navy`) |
| `ui_border` | `#8E9494` | Borde de panel (2–3 px a 1080p) |
| `ui_text` | `#F4EFE6` | Texto principal (= `brand_paper`; 14,4:1 sobre el panel) |
| `ui_bar` | `#C8402F` | Barra de paciencia (= `brand_red`; 3,3:1 sobre el panel) |
| `ui_digits` | `#5B8DB8` | Reloj de 7 segmentos y cifras del HUD (= `brand_support`; 4,7:1) |
| `ui_track` | `#0B141E` | Fondo de barras |
| `ui_alert` | `#FF6B57` | Paciencia baja: la barra pasa a neón y parpadea (5,9:1); nunca solo color |

### 2.7 Marca (propuesta A · Mariña, PUL-088)

Colores de [`brand.md`](brand.md), elegidos por el responsable; esta biblia los adopta tal cual y
**reajusta la paleta v2 alrededor de ellos** (no al revés):

| Nombre | Hex | Rol en la marca | Dónde entra en la v2 |
|---|---|---|---|
| `brand_navy` | `#1D3557` | Principal | Símbolo y «Pulpa»; pantalón del uniforme; cabecera de UI; marco de cartel y pizarras |
| `brand_red` | `#C8402F` | Acento (pimentón) | Placa «SA»; **bandejas** (`plastic_red`), rayas del toldo (`canvas_red`), visera de gorra, barra de paciencia |
| `brand_paper` | `#F4EFE6` | Papel | Papel de bandeja (`tray_liner`), rayas claras del toldo, vasos, texto de UI |
| `brand_night` | `#13202F` | Noche | Caja del cartel luminoso, cuerpo de tickets/HUD |
| `brand_support` | `#5B8DB8` | Apoyo | Patrón del papel de bandeja (al 15 %), cifras del HUD |
| `brand_neon` | `#FF6B57` | Neón | Tubo del cartel luminoso (emisivo), aviso de paciencia baja |

Tipografía: **Montserrat** Black (logotipo) y Bold (lema y textos de UI), OFL; el reloj de 7
segmentos usa una fuente de display libre aparte (PUL-086). Lema: **«Franquicia galega de polbo»**.

Ajustes hechos para que la marca encaje sin romper §6:
- Los rojos de plástico y lona se unifican en `brand_red` (antes `#C93A33`/`#C33E39`, diferencia
  imperceptible); papel/bandeja sigue en **4,3:1**.
- El papel de la bandeja pasa a `brand_paper`; rodajas sobre él **3,6:1**. El patrón de símbolos se
  pinta al **15 %** (no al 30 % de `brand.md`): al 30 % las rodajas bajan a 2,6:1; al 15 % el patrón
  queda en 1,16:1 contra el papel y las rodajas en ≥ 3,0:1. Símbolos ≥ 0,06 m (sin ruido fino, §3.2).
- La UI abandona el gris pizarra y el ámbar de la referencia por noche/marino/rojo/apoyo de la marca,
  con los contrastes de la tabla de §2.6.
- **Uniforme**: `brand.md` pone gorra y delantal en marino, pero gorra y delantal identifican al
  jugador (`player_1/2`, §6.5). Manda la legibilidad: copa de gorra y peto del delantal en el color del
  jugador; marino en pantalón, cinta del delantal y ribetes; visera en `brand_red`; insignia compacta
  y logotipo en `brand_paper`. `player_1` (`#2F6FB5`) y `brand_navy` se separan 2,4:1 y por saturación.
- `stand_1` (`#D2473F`) es casi igual que `brand_red`: no pasa nada porque el puesto se identifica por
  número y posición, pero **ningún toldillo de kiosco lleva el logo** sobre la lona (va en la caja).

Reglas de convivencia: el color **principal** de marca (`brand_navy`) no se usa como color de jugador
ni de puesto; nada de «Mc», arcos ni amarillo junto a `brand_red` en piezas de marca (PUL-088).

## 3. Materiales (biblioteca v2, la crea PUL-074)

### 3.1 Catálogo

Biblioteca cerrada en `art/blender/_materials_v2.blend` → `godot/assets/materials/v2/`. Un asset solo usa
materiales de aquí (más su atlas propio, §3.3). Nombres `mat_<nombre>`:

| Material | Base (§2) | Rough. | Metal. | Textura y desgaste |
|---|---|---|---|---|
| `mat_steel_brushed` | `steel_light`/`steel_top` | 0,35–0,45 | 1,0 | Cepillado direccional suave, arañazos finos solo en tableros, manchas de agua sutiles |
| `mat_steel_dark` | `steel_dark` | 0,5 | 0,8 | Igual, más mate; tornillos pintados en el atlas |
| `mat_paint_worn` | `paint_grey`/`paint_beige` | 0,6 | 0 (desconchado 1,0) | Desconchado en aristas que deja ver `steel_mid` (máscara de curvatura horneada) |
| `mat_plastic_red` | `plastic_red` | 0,45 | 0 | Roces claros en bordes, sin brillo de espejo |
| `mat_plastic_blue` | `plastic_blue` | 0,45 | 0 | Igual |
| `mat_wood_used` | `wood_used`/`wood_dark` | 0,7 | 0 | Veta pintada ancha, cortes de cuchillo en tablas, bordes oscurecidos |
| `mat_burlap` | `burlap` | 0,9 | 0 | Trama gruesa pintada (≥ 4 px por hilo a 1080p, si no, liso) |
| `mat_cardboard` | `cardboard` | 0,85 | 0 | Ondulado en el canto, cinta y garabatos sin texto legible |
| `mat_clay` | `clay` | 0,75 | 0 | Vidriado parcial más claro en el borde |
| `mat_canvas` | `canvas_red` / toldillos | 0,85 | 0 | Trama de lona, costuras, borde de festón más oscuro |
| `mat_granite` | `granite` | 0,85 | 0 | Sillares irregulares de granito, moteado grueso de mica (≥ 4 px), juntas y musgo abajo (Z3: el moteado no afecta a lo jugable) |
| `mat_rubber` | `rubber_black`, mangueras | 0,7 | 0 | Liso |
| `mat_ground_dirt` | `ground_dirt` | 0,95 | 0 | Tierra con piedrecitas pintadas, rodadas y zonas pisadas (`ground_track`), charcos con roughness 0,1 |
| `mat_grass` / `mat_foliage` | `grass` / `foliage` | 0,9 | 0 | Pintado, hojas por tarjetas con alfa en el fondo |
| `mat_glass_water` | `water_tank` | 0,05 | 0 | Transparente; burbujas como malla o partículas |
| `mat_emissive_bulb` | `bulb_warm` | — | — | Emisivo, sin textura |
| `mat_cloth` | uniforme | 0,9 | 0 | Tela de personaje, pliegues pintados grandes |
| `mat_skin` | dos tonos de la v1 | 0,7 | 0 | Liso |
| `mat_food_*` | §2.4 | §6 | 0 | **Sin ruido**: degradado suave y ventosas; quemado con grietas grandes |

`mat_copper` de la v1 deja de usarse en la cocina (los cocedores son de acero, PUL-078); puede quedar
en atrezo de fondo (cazos colgados) si casa.

### 3.2 Qué se permite y qué no

**Ahora sí** (la v1 lo prohibía):
- **Texturas de color** pintadas a mano o procedurales y horneadas, pequeñas (§4.2).
- **AO horneado**: en el canal AO de una textura ORM (Occlusion-Roughness-Metallic) o multiplicado en el
  albedo del atlas del asset. Es lo que da el aspecto de maqueta.
- **Normal maps sencillos**: solo en materiales tileables de la biblioteca (cepillado, trama, juntas,
  tierra) o en el atlas de una estación, a ≤ 512². Detalles de relieve grandes (tornillos, costuras,
  remaches), nunca microdetalle.
- **Roughness y metallic por textura** (ORM) y materiales metálicos de verdad (`metallic = 1` en acero).
- **Decals planos** (malla con offset de 1–2 mm o `Decal` de Godot) para rodadas, manchas, charcos,
  etiquetas y logos.
- **Transparencia** solo en agua del tanque, vapor (partículas) y tarjetas de vegetación del fondo.
- **Vértices de color** como máscara de desgaste en el shader, siempre que el color base venga de
  textura o material (sigue prohibido que sea el único portador del color).

**Sigue prohibido**:
- Fotorrealismo: fotografías, escaneos, texturas de terceros, PBR de bibliotecas externas (D16).
- **Ruido que mate la lectura**: ninguna textura con frecuencia más fina que **4 px a 1080p** en
  superficies jugables (≈ 0,05 m en el modelo); nada de grano fino en comida, bandejas ni pegatinas.
- Color de desgaste que imite comida o condimento (manchas rojas de «pimentón» o amarillas de
  «aceite» en encimeras jugables).
- Texto legible inventado en atrezo, salvo la marca PulpaSA (§7) y los números de puesto.
- Shaders personalizados por asset: el asset usa `StandardMaterial3D` (importado del `.glb`). Los
  únicos shaders son los del motor (resaltado `highlight_outline`, agua, partículas).
- Normal maps de alta frecuencia, parallax, subsurface, clearcoat y teselación.

### 3.3 Atlas por asset

Además de los materiales tileables, cada asset puede llevar **un atlas propio** (albedo + ORM y,
opcional, normal) para lo que no se repite: etiquetas, pantallas, tornillos, logotipo, desgaste
concreto. Se hornea desde Blender y va embebido en el `.glb` o en `godot/assets/textures/v2/<asset>/`
según decida PUL-074 (el test exige materiales embebidos).

## 4. Presupuestos

### 4.1 Triángulos (tras triangular, por pieza exportada)

| Tipo | v1 máx. | **v2 máx.** | Objetivo v2 |
|---|---|---|---|
| Personaje (con rig, ropa y gorra) | 2 500 | **6 000** | ≈ 4 000 |
| Objeto que se sostiene (pulpo, cachelos; cada variante de estado) | 600 | **1 500** | ≈ 800 |
| Bandeja (cada talla, con relleno al máximo) | 600 | **2 000** | ≈ 1 200 |
| Estación (cocedor, tanque, sacos, rack, condimentos, kiosco) | 1 500 | **6 000** | ≈ 3 500 |
| Encimera (módulo de 1 m, con cajones y balda) | 300 | **1 500** | ≈ 800 |
| Atrezo pequeño (bote, cuchillo, cuenco, saco, barril) | 300 | **800** | ≈ 300 |
| Atrezo grande de fondo (generador, tanque de gas, árbol, mesa con comensales) | — | **5 000** | ≈ 3 000 |
| Entorno completo (suelo, toldo, muro, valla, fondo y atrezo) | 6 000 | **80 000** | ≈ 50 000 |
| **Escena de nivel completa en pantalla** | 40 000 | **250 000** | ≈ 160 000 |

- Lo que nunca ve la cámara (caras inferiores, interiores cerrados, traseras contra el muro) se borra.
- La vegetación del fondo usa tarjetas con alfa, no geometría de hoja.
- Atrezo repetido (bombillas, tornillos, botes, sacos) se instancia (`MultiMeshInstance3D` o la misma
  malla) en vez de fusionarse en una malla única enorme.

### 4.2 Texturas

| Tipo | Resolución máx. | Notas |
|---|---|---|
| Material tileable de la biblioteca (albedo/ORM/normal) | **512²** | Suelo: hasta 1024² |
| Atlas de personaje | **1024²** | Compartido por J1/J2 (cambian colores por material o por zona del atlas) |
| Atlas de estación | **1024²** | Uno por estación |
| Atlas de objeto que se sostiene / bandeja | **512²** | Compartible entre estados (crudo/cocido/quemado) |
| Atlas de atrezo | **512²** | Un atlas compartido por familia (cocina, mesas, fondo) |
| Marca (cartel, toldo, logos) | **1024×512** | PUL-088 |
| Pegatinas / iconos | 256² (atlas existente) | Sin cambios |

- **Densidad de texel**: objetivo **≈ 256 px por metro** (≈ 3 texels por píxel de pantalla a 1080p,
  donde 1 m ≈ 85 px); nunca menos de 128 px/m en lo jugable. Así todos los assets tienen el mismo grano.
- Import en Godot: compresión VRAM (BPTC/S3TC de escritorio), mipmaps activados, filtro lineal con
  anisotropía. Las de UI, sin compresión.
- Memoria total de texturas del nivel: **≤ 256 MB** de VRAM.

### 4.3 Rendimiento (lo mide PUL-087)

- **Objetivo**: **60 fps estables a 1920×1080** en la máquina de desarrollo (Forward+, RTX 3090,
  24 hilos) con todos los efectos de §1.3 activos; **tiempo de frame de GPU ≤ 12 ms** de media y
  ≤ 16,6 ms en el percentil 99 durante una partida completa. No se fija una máquina modesta de
  referencia para la alpha (decidido): el margen de 12 ms es solo higiene.
- Límites de escena: **≤ 1 000 draw calls**, ≤ 60 materiales distintos en pantalla, ≤ 8 luces
  dinámicas (§1.3), ≤ 2 con sombra además de la direccional.
- Si no se cumple, el orden de recorte es: tilt-shift → sombras de luces puntuales → SSAO a calidad
  baja → densidad del atrezo de fondo → resolución de texturas del fondo. **Nunca** se recorta
  detalle de lo jugable ni contraste de §6.
- Cada ficha de asset anota en su Evidence sus triángulos y texturas; PUL-087 suma y mide.

## 5. Densidad de detalle por zonas

| Zona | Qué es | Detalle permitido | Colisión |
|---|---|---|---|
| **Z0 · Suelo jugable** | Tierra dentro del perímetro de encimeras, por donde caminan los cocineros | Solo en textura o decal plano (rodadas, piedrecitas, hojas, charcos, rejillas): relieve ≤ 2 cm, contraste ≤ 1,3:1 contra `ground_dirt` salvo rejillas. **Ningún objeto suelto** (ni patatas, ni piedras grandes, ni cables) | Ninguna nueva |
| **Z1 · Superficies de juego** | Tablero de encimeras en huecos de dejar, bocas de cocedor, tanque, sacos, rack, dispensadores, bandeja del kiosco | **Limpias**: material base + desgaste suave. Atrezo solo en la franja trasera (≤ 25 % del fondo del tablero), ≤ 0,25 m de alto, a ≥ 0,15 m de cualquier ancla (`Anchor_*`) o punto de dejar | La del contrato, sin cambios |
| **Z2 · Frentes y laterales** | Cara frontal y lateral de encimeras, estaciones y kioscos | Libre: cajones, tornillos, etiquetas de condimento, logos, pantallas, cables cortos, cajas en la balda inferior | La del contrato |
| **Z3 · Fondo y entorno** | Todo lo que queda fuera del perímetro: muro, toldo, tanques, valla, mesas, árboles | **Denso** (la referencia es el mínimo): barriles, sacos, cajas, cables, bombonas, generador, comensales estáticos. Algo más desaturado (≈ −15 %) que lo jugable. Nada por delante del plano de juego más alto de 1 m (regla de la v1) | **Sin colisión** |

Reglas comunes:
1. **El atrezo no imita lo jugable**: ni pulpos, ni patatas, ni bandejas rojas sueltas, ni botes de
   condimento en Z0/Z1 que no sean los de verdad. En Z3 sí (platos de los comensales, pilas de bandejas
   detrás del rack), siempre a ≥ 1 m de una estación del mismo tipo.
2. Las pilas de bandejas de la referencia sobre encimeras jugables se sustituyen por el **rack**
   (PUL-081), que es el que da bandejas.
3. Lo denso se agrupa en `.glb` de fondo separados (PUL-085) para poder bajar su detalle sin tocar lo jugable.
4. Cables y mangueras pueden cruzar Z0 **solo** pegados al suelo como decal o malla de ≤ 2 cm, y nunca
   atravesando la huella de una estación o el paso entre encimeras.

## 6. Legibilidad desde la cámara ortográfica

Cámara (`camera_rig.tscn`, sin cambios): ortográfica, `size = 12.74` m, inclinación ≈ 38°. A
1920×1080, 1 m ≈ 85 px; un objeto de 0,3 m ocupa 25–40 px. Importan la cara superior y la frontal.

### 6.1 Reglas generales

1. **Silueta**: en una captura 1920×1080 rellenada de negro, cada tipo jugable (pulpo, cachelos,
   bandeja de cada talla, estación, cocinero) se reconoce. Los estados de un mismo objeto cambian de
   silueta (§6.2, §6.3).
2. **Detalle mínimo**: todo lo que da información (pegatina, número, estado) ≥ **6 px** a 1080p
   (≈ 0,07 m). Lo decorativo menor de 4 px no se texturiza (se queda en color liso).
3. **Contraste entre estados**: crudo/cocido ≥ **3:1** de luminancia relativa; cocido/quemado
   ≥ **2,5:1** más cambio de silueta y humo (PUL-069); crudo/quemado ≥ 3:1.
4. **Contraste contra el apoyo**: los objetos que se sostienen se leen contra `steel_top` (encimera),
   `tray_liner` (dentro de la bandeja) y `ground_dirt` (en la mano, sobre el suelo). Si la luminancia
   no llega a 3:1, se separan por **saturación** y por **contorno oscuro** de 0,01–0,02 m o sombra de
   contacto (AO). Tabla en §6.4.
5. **Nada encima de lo jugable**: ningún atrezo, decal, cable, vapor opaco o rama tapa un ancla,
   una boca de cocedor, una bandeja o una pegatina desde la cámara. El vapor es semitransparente
   (alfa ≤ 0,5) y sube por detrás del borde.
6. **Luz**: ninguna superficie jugable queda con luminancia final < 0,08 (sombra ilegible) ni
   quemada > 0,95 en la captura con la luz de §1.3; lo comprueba PUL-073 (AC2).
7. **Resaltado**: el contorno de interacción (`highlight_outline`, `OutlineHull` si el modelo es
   abierto, nota de PUL-049) debe seguir viéndose sobre los materiales nuevos; si el acero claro lo
   apaga, se oscurece el borde, no se cambia el shader.

### 6.2 Pulpo: crudo, cocido, quemado y rodajas

| | Crudo | Cocido | Quemado |
|---|---|---|---|
| Color | `#E0AFB2` rosa pálido, ventosas `#9A6E7A` | `#B8283D` rojo-morado, ventosas `#6E1A3A` | `#2A2320` carbón, grietas `#5A2A1E` |
| Luminancia (L) | 0,50 | 0,12 | 0,02 |
| Forma | Patas **lacias y extendidas**, cabeza de saco | Patas **enroscadas** hacia arriba, cuerpo menor | Más pequeño, **arrugado y encogido**, puntas rotas |
| Brillo | Húmedo (rough. 0,4) | Satinado (0,5) | Mate (0,95) |
| Extra | — | — | Humo de PUL-069 |

Relaciones: crudo/cocido **3,2:1**, cocido/quemado **2,5:1**, crudo/quemado **8,1:1**. Rodajas
`#D4506A` con corte `#F4C6CC`, ≈ 0,05 m, sobre `tray_liner`: **3,6:1** (≥ 3,0:1 sobre el patrón).
El crudo sobre acero (`steel_top`) solo da 1,3:1: se separa por saturación (rosa frente a gris) y por
el contorno de ventosas `#9A6E7A`; dentro del tanque, el agua no baja su luminancia más de un 15 %.

### 6.3 Cachelos: crudo, cocido, quemado

| | Crudo | Cocido | Quemado |
|---|---|---|---|
| Color | `#8E6B47` piel opaca | `#F2D56B`, borde `#D8A93C` | `#2E2620` |
| Forma | Patata **entera**, ovalada | **Partida** en 2–3 trozos, caras de corte claras | Trozos encogidos y agrietados |

Relaciones: crudo/cocido **3,3:1**, cocido/quemado **10,3:1**, crudo/quemado **3,1:1** (más forma).
El cocido dentro de la bandeja se lee sobre `tray_liner` por **saturación y borde** (solo 1,26:1 de
luminancia): el borde `#D8A93C` de 0,01 m es obligatorio.

### 6.4 Bandejas (sustituyen a los platos de madera) y pegatinas

- **Bandeja de plástico rojo** `plastic_red` (`brand_red`) con **papel salvamanteles** `tray_liner`
  (`brand_paper`) en el fondo: el papel existe porque el pulpo cocido sobre rojo (1,2:1) no se leería.
  Papel/bandeja: **4,3:1**. El papel lleva el símbolo de la marca repetido en `brand_support` **al 15 %**
  (§2.7), nunca más fuerte. `brand.md` sugiere un marco marino: no se usa, la bandeja es roja entera.
- **Tres tallas distinguibles por forma**, no solo por tamaño (proporción de diámetro de la v1,
  0,34 : 0,42 : 0,49): pequeña **redonda**, mediana **ovalada**, grande **rectangular con asas**.
  Se mantiene el aro de color por talla de la v1 como banda fina en el canto (azul, verde, rojo) para
  leerlas apiladas.
- **Relleno visible por capas** (vacía, a medias, llena) con rodajas y cachelos desde arriba.
- **Pegatinas** (D18): sin cambios de forma ni color (disco 0,10 m, icono del atlas, fila billboard de
  PUL-059). Van **por encima** de la bandeja en la fila de PUL-059; el logotipo de la bandeja va en
  el canto frontal-inferior, nunca donde caen las pegatinas.
- Bandeja sobre `steel_top`: 2,0:1 más saturación; sobre `ground_dirt`: 1,5:1 más saturación y sombra
  de contacto.
- Pimentón dulce/picante en pegatinas y etiquetas: 1,9:1 más icono (con chispa o sin ella), como en la v1.

### 6.5 Puestos, jugadores y estaciones

- **Kioscos**: toldillo `stand_1..4` y número negro en disco blanco ≥ 0,25 m en el frente (Z2);
  `%OrderLabel` del motor sigue mostrando el `#id` de la comanda encima. El TPV no puede ser más
  llamativo que el número.
- **Jugadores**: copa de gorra y peto del delantal `player_1`/`player_2`, aro del mismo color (PUL-035);
  pantalón y ribetes `brand_navy`, visera `brand_red` (§2.7); rasgo de forma
  para daltónicos (v1 §3.1-6: J1 gorra redonda, J2 gorro alto, o el que fije PUL-075). La camiseta
  blanca debe destacar sobre el suelo (`uniform_shirt` / `ground_dirt`: 3,0:1).
- **Cocedores**: abiertos o con tapa levantada para ver lo que cuece desde la cámara (plazas
  `Anchor_Slot_*` a la vista); piloto de color por estado opcional, nunca rojo/verde como único aviso.
- **Tanque de pulpos**: el pulpo crudo de dentro se ve como el de la mano (lectura «de aquí sale el pulpo»).
- **Sacos**: patatas crudas visibles en la boca, del modelo de PUL-076.
- **Dispensadores de condimento**: recipiente del color del condimento (§2.5) y etiqueta del mismo
  color en el frente de la barra (como la referencia); ≤ 0,25 m de alto.

## 7. Marca PulpaSA (D21)

La identidad (logotipo, símbolo, colores de marca, versiones) la diseña **PUL-088** en
[`docs/art/brand.md`](brand.md); el responsable eligió la **propuesta A · Mariña** (colores en §2.7).
Las fichas usan los SVG/PNG de `art/brand/propuesta_a/` y `godot/assets/textures/brand/propuesta_a/`.
Esta biblia fija **dónde aparece y con qué reglas**.
Punto de partida permitido: `godot/assets/textures/logo/PulpaSA.png` (propio, del prototipo).

| Lugar | Asset / ficha | Versión del logo | Regla |
|---|---|---|---|
| Cartel luminoso sobre el toldo | Entorno, PUL-085 | Horizontal sin lema; caja `brand_night`, tubo `brand_neon`, «SA» en blanco | El elemento más llamativo del fondo, pero por encima del plano de juego y sin tapar la cocina |
| Toldo grande | Entorno, PUL-085 | Horizontal con lema «Franquicia galega de polbo», sobre placa `brand_paper` con borde marino | Rayas anchas `canvas_red`/`brand_paper` con faldón festoneado; el logo nunca directamente sobre las rayas; sin diagonales ni amarillo |
| Uniformes (gorra, delantal) | Personaje, PUL-075 | Compacta en la gorra; símbolo + logotipo en `brand_paper` en el delantal | Pequeño; no cambia el color de jugador de gorra y peto (§2.7) |
| Bandejas | PUL-077 | Símbolo en el canto frontal-inferior | Nunca en la zona de pegatinas ni en el fondo de la bandeja |
| Kioscos de entrega | PUL-083 | Compacta en la caja de llevar o el frente | Más pequeña que el número del puesto |
| Vasos y servilleteros de los comensales | Entorno, PUL-085 | Símbolo | Atrezo Z3 |
| Pizarras de menú | Entorno, PUL-085 | Horizontal pequeña | Sin texto inventado legible aparte de la marca |
| Tickets, HUD y menús | UI, PUL-086 | Compacta o monocromo | En cabecera de menús y pantalla de título; en tickets como mucho un símbolo pequeño |

Reglas de convivencia: ver §2.7.

**Tono (decidido por el responsable el 2026-10-06): franquicia satírica con raíz de romería**. «PulpaSA» se lee como *Pulpa, S.A.*: una sociedad anónima que ha convertido la
pulpería de feria en franquicia (uniformes, TPV, cámaras de vigilancia, cartel luminoso, «empregado do
mes»), pero montada en un campo de romería gallego con barro, fentos y cuncas. El humor sale del choque
entre lo corporativo y lo tradicional: el lema «Franquicia galega de polbo» con rótulo de neón sobre un
muro de granito, cámaras de vigilancia apuntando a unos comensales con boina. La sátira va en el
atrezo de fondo y en los textos de marca, nunca en lo jugable.

## 8. Tabla asset → cambio (PUL-073..PUL-086)

**Rehacer** = modelo nuevo (misma huella y contratos); **retexturizar** = mismo modelo o casi, materiales
v2; **nuevo** = atrezo que no existe. Todo conserva colisiones, anclas, nodos de contrato y posiciones
de `level_01`.

| Ficha | Asset actual | Acción | Qué cambia | Atrezo nuevo | Presupuesto (§4) | Depende de |
|---|---|---|---|---|---|---|
| PUL-073 | `WorldEnvironment`, luz del nivel | **Ajustar** | Luz y post de §1.3 (AgX, SSAO, ambiente apagado, luces de bombilla, tilt-shift opcional en `.tres`) | Luces de bombilla (las mallas las pone PUL-085) | ≤ 8 luces, §4.3 | — |
| PUL-074 | Materiales planos de la v1 | **Nuevo** | Biblioteca de §3.1, plantilla `_template.blend`, export de texturas | — | Texturas §4.2 | — |
| PUL-075 | Cocinero low-poly | **Rehacer** | Uniforme (camiseta, pantalón marino, gorra/gorro, delantal), materiales `mat_cloth`/`mat_skin`, logo compacto; mismo rig, clips y `Anchor_Hold` | — | 6 000 tris, atlas 1024² | PUL-074, PUL-088 |
| PUL-076 | Pulpo, cachelos (crudo/cocido/quemado), rodajas | **Rehacer** | Colores y formas de §6.2/§6.3, más detalle de ventosas y cortes, sin ruido; mismos nombres de malla | — | 1 500 c/u, atlas 512² | PUL-074 |
| PUL-077 | Platos de madera (3 tallas) | **Rehacer** | Bandejas de plástico rojo con papel, tres formas (§6.4), relleno por capas, logo en canto | — | 2 000 c/u, atlas 512² | PUL-074, PUL-076, PUL-088 |
| PUL-078 | Caldeiros de cobre con fogón | **Rehacer** | Cocedores cilíndricos de acero con quemador de gas, tapa levantada, piloto; boca abierta para ver las plazas | Mangueras de gas roja/verde al suelo, bombona junto al muro | 6 000 (cada cocedor + quemador) | PUL-074 |
| PUL-079 | Arcón de pulpo | **Rehacer** | Tanque azul de plástico con agua `mat_glass_water`, burbujas y pulpos crudos dentro (el modelo crudo de PUL-076); misma huella | Mangueras de agua, cartel pequeño sin texto inventado | 6 000 | PUL-074, **PUL-076** (pulpos del tanque: añadir a `deps` de la ficha) |
| PUL-080 | Cesta/cachelera | **Rehacer** | 1–2 sacos de arpillera abiertos con patatas crudas de PUL-076, cesto opcional | — | 6 000 | PUL-074, PUL-076 |
| PUL-081 | Estantería de platos | **Rehacer** | Rack de acero con pilas de bandejas por talla delante de cada spawner | — | 6 000 (sin contar las bandejas instanciadas) | PUL-074, PUL-077 |
| PUL-082 | Estación de condimentos (dispensadores, cuenco de cachelos) | **Rehacer** | Mostrador de acero, botes/latas de pimentón dulce y picante, salero, aceitera, cuenco de barro de cachelos, etiquetas de color en el frente | Tabla de corte y cuchillo en la franja trasera (Z1) | 6 000 el conjunto | PUL-074 |
| PUL-083 | Puestos de entrega 1–4 | **Rehacer** | Kiosco de acero oscuro, toldillo `stand_1..4` con festón, TPV, número en disco, logo compacto | Caja de llevar con faja de marca | 6 000 c/u (malla común + 4 materiales) | PUL-074, PUL-088 |
| PUL-084 | Encimeras de madera (kit) y suelo de la cocina | **Rehacer** | Encimeras de acero con tornillos, cajones/puertas, balda con cajas de cartón; tablero `steel_top` limpio (Z1) | Rejillas de desagüe, utensilios en franja trasera, cajas de cartón en baldas | 1 500 por módulo | PUL-074, PUL-073 |
| PUL-085 | Entorno de romería (carpa, cartel, mesas, decoración) | **Rehacer + nuevo** | Suelo de tierra con rodadas/charcos (Z0, decals), muro de **granito** (§1.4), toldo a rayas `canvas_red`/`brand_paper` y cartel luminoso PulpaSA (§7), valla | Tanques de gas, generador, bombonas, cables, barriles, cajas, sacos, carballos y fentos, mesas largas con comensales **estáticos con ropa de romería** (§1.4), cuncas, postes con guirnaldas de bombillas, pizarras de menú, cámaras de vigilancia, banderines. Dividido en `ground`, `tent`, `back`, `props` | 80 000 el entorno | PUL-074, PUL-073, PUL-088 |
| PUL-086 | HUD, tickets y menús | **Retexturizar (UI)** | Paneles `ui_panel` (noche) con cabecera `ui_header` (marino) e insignia compacta, textos en Montserrat Bold, reloj de 7 segmentos en `ui_digits` (fuente libre OFL), barra `ui_bar` con aviso `ui_alert`, pegatinas de PUL-060; HUD compacto | Fuentes OFL: Montserrat y la de display (registro del coordinador) | — | PUL-088 |

Orden recomendado: PUL-073 y PUL-074 primero (luz y materiales fijan el juicio); después
PUL-076 → PUL-077 → PUL-081 (comida, bandeja, rack); PUL-075; estaciones PUL-078/079/080/082/083;
por último PUL-084 y PUL-085 (lo más grande) y PUL-086 en paralelo.
PUL-079 depende también de PUL-076 (pulpos dentro del tanque); su ficha debe llevarlo en `deps`.

## 9. Lista de comprobación por asset (reviewer y asset-pipeline)

- [ ] Escala 1 u = 1 m, medidas de §2.1 de la v1 ±10 % (salvo huellas de contrato), escala aplicada
- [ ] Triángulos ≤ §4.1; texturas ≤ §4.2 con ≈ 256 px/m; anotados en Evidence
- [ ] Frente −Z (`Anchor_Front`), origen en el centro de la base; sin luces ni cámaras
- [ ] Solo materiales de la biblioteca v2 (§3) y su atlas; color medio a ≤ 10 % del hex de §2
- [ ] Nada fotorrealista ni ruido < 4 px en superficies jugables (§3.2)
- [ ] Zonas de §5 respetadas: Z0 sin objetos sueltos, Z1 limpia, atrezo sin colisión en Z3
- [ ] Contrastes y siluetas de §6 (crudo/cocido/quemado, bandejas, pegatinas, puestos, jugadores)
- [ ] Resaltado visible sobre el material nuevo (§6.1-7)
- [ ] Logo PulpaSA solo donde dice §7 y en la versión indicada
- [ ] Captura antes/después desde la cámara de `level_01` junto a la referencia y render del `.blend`
- [ ] Licencia propia anotada (a través del coordinador)

## 10. Decisiones cerradas y preguntas abiertas

Cerradas por el responsable el 2026-10-06: tono (franquicia satírica, §7), marca (propuesta A ·
Mariña, §2.7), muro de granito (§1.4), tilt-shift opcional y apagado por defecto (§1.3), rendimiento en
la RTX 3090 sin máquina modesta (§4.3), comensales con ropa de romería (§1.4).

Abiertas: ninguna para lanzar PUL-073..PUL-086. Lo que salga al medir (PUL-087) se resuelve con el
orden de recorte de §4.3.
