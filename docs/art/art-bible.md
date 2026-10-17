# Biblia de arte de Pulpasa — v3 · «Feira Clara»

Autor: PUL-181 (`game-designer`), 2026-10-17. Adopta la decisión **[D28](../design/decisions.md)** (2026-10-17), que elige la **Dirección A · «Feira Clara»** de PUL-180 ([`minimal/direccion-a-color-plano.md`](minimal/direccion-a-color-plano.md), [`minimal/README.md`](minimal/README.md) y el prototipo [`../evidence/PUL-180/capture_minimal.gd`](../evidence/PUL-180/capture_minimal.gd)) con una **primera oleada solo de materiales y escena**, sin remodelar `.glb` en Blender.

Sustituye en estilo, paleta, materiales, iluminación, atrezo y post-proceso a la **v2** ([`art-bible-v2.md`](art-bible-v2.md), PUL-072, D22), que queda archivada como referencia de las mallas `.glb` de M3b (PUL-073..PUL-087). La **v1** ([`art-bible-v1.md`](art-bible-v1.md), PUL-042) se mantiene archivada para las secciones normativas de escala, orientación, origen, nodos de contrato y nombres que la v2 y esta v3 referencian.

Rigen **D14** (3D con cámara ortográfica fija), **D16** (solo licencias confirmadas), **D20** (arte propio), **D21** (marca **PulpaSA**), **D25** (condimentos simplificados a 3 acciones: aliño dulce, aliño picante y cachelos), **D26** (iconos con doble codificación forma + color, prompts de acción y legibilidad en móvil), **D27** (soporte táctil y viewport móvil `800×370`) y **D28** (dirección artística minimalista «Feira Clara»). Si algo choca con [`docs/design/decisions.md`](../design/decisions.md), manda `decisions.md`.

- **Lámina de paleta propia v3**: [`moodboard-v3.svg`](moodboard-v3.svg) (las anteriores se conservan en [`moodboard-v2.svg`](moodboard-v2.svg) y [`moodboard.svg`](moodboard.svg)).
- **Referencia visual de la v3**: capturas del prototipo en [`../evidence/PUL-180/direccion_a/1920x1080_con_hud.png`](../evidence/PUL-180/direccion_a/1920x1080_con_hud.png), [`../evidence/PUL-180/direccion_a/1920x1080_sin_hud.png`](../evidence/PUL-180/direccion_a/1920x1080_sin_hud.png) y [`../evidence/PUL-180/direccion_a/800x370_movil.png`](../evidence/PUL-180/direccion_a/800x370_movil.png), aplicando las **4 correcciones normativas de revisión de PUL-180** (cartel superior, números de puesto en móvil, textura `env_plate` y SSAO; ver §3.2, §4.2, §5.2 y §6.3).
- **Cálculo reproducible de contrastes WCAG 2.1 (AC2)**: [`../evidence/PUL-181/contrastes_v3.md`](../evidence/PUL-181/contrastes_v3.md) y [`../evidence/PUL-181/calc_contrasts_v3.py`](../evidence/PUL-181/calc_contrasts_v3.py).

---

## 0. Qué cambia respecto a la v2

| Tema | v2 (M3b, [`art-bible-v2.md`](art-bible-v2.md)) | v3 · «Feira Clara» (M3f, [D28](../design/decisions.md)) |
|---|---|---|
| **Estilo** | Diorama estilizado y «vivido», con desgaste, suciedad, desconchones y ambiente nocturno/atardecer | **Color plano mate (flat-shaded PBR)** de feria gallega diurna, limpia y luminosa; separación de planos por valor tonal y silueta |
| **Geometría (`.glb`)** | Mallas biseladas con sub-objetos de desgaste y atrezo denso por zonas | **Se reutilizan los `.glb` de la v2 sin remodelar en Blender** (1.ª oleada D28); el ruido geométrico se poda ocultando sub-mallas en escena |
| **Paleta** | 29 colores base + variaciones por textura procedural | **Paleta cerrada de 16 colores en hex** (§2), agrupados en entorno (3), mobiliario/marca (4), comida/estados (7) y jugadores/UI (2+compartidos) |
| **Materiales** | 45 `.tres` en `materials/v2/` + 239 instancias en memoria por extracción de `.glb` | **Biblioteca cerrada de 18 `.tres` (≤ 20)** en `godot/assets/materials/v3/` (§3): `StandardMaterial3D` con `metallic = 0.0` y `specular_mode = SPECULAR_DISABLED` |
| **Texturas 3D** | 64 PNG en `textures/v2/` + 367 PNG extraídos junto a `.glb` (albedo, ORM, normal) | **0 texturas PBR de superficie** (0 albedo de ruido, 0 ORM, 0 normal maps). Solo se permite la placa gráfica de marca `env_plate` y los iconos planos de señalética/UI (§3.2) |
| **Iluminación** | 1 `DirectionalLight3D` (`energy = 1.34`) + 5 `OmniLight3D` (`Bulbs`) que creaban manchas especulares | **1 única `DirectionalLight3D` (`Sun`)** cálida (`#FFF4E0`, `energy = 1.18`, `shadow_blur = 3.2`) + luz ambiental uniforme (`#EDE8DF`, `energy = 0.72`); **0 `OmniLight3D`** (`Bulbs` apagadas) (§4) |
| **Post-proceso** | `WorldEnvironment` con SSAO, `glow` (bloom), LUT 3D, viñeta 2D (`Vignette`) y DoF opcional | **Sin `glow`, sin LUT, sin `Vignette` y sin DoF**. Se conserva únicamente **SSAO suave de contacto** (`radius = 0.45`, `intensity = 1.1`) para separar planos mates contiguos (§4.2) |
| **Atrezo** | Denso en Z3 (vallas, generador, bidones, guirnaldas) y en encimeras (cuncas, tablas, bombonas) | **Poda de atrezo decorativo** en Z1–Z3 y **eliminación del cartel superior vacío** (`env_sign`/`env_board`) sobre el toldo (§5) |
| **Números de puesto** | `Label3D` con contorno o tinte bajo contraste en el prototipo | **Glifos macizos sin contorno hueco (`outline_size = 0`)**: `#1..#4` en `#1D3557` sobre placa `#F7F4EC` (**11.24 : 1**) y `1..4` en `#F7F4EC` sobre frente `#1D3557` (**11.24 : 1**), nítidos a `800×370` (§6.3) |
| **Legibilidad §3.4** | Dependía de texturas y sombras locales | Los **5 colores de §3.4** tienen soporte de polaridad opuesta garantizado con **contraste ≥ 3.24 : 1** (mínimo en soportes primarios **3.91 : 1**) (§6.2) |

### 0.1 Refinamientos frente a la maqueta preliminar de Dirección A (PUL-180)
Respecto al prototipo de exploración rápida de PUL-180 (`capture_minimal.gd` y `minimal/direccion-a-color-plano.md`), la biblia v3 formaliza tres refinamientos cromáticos directos:
1. **`stone_steel #8C96A0` evoluciona a `wall_granite #9A948C` ($L = 0.2994$)**: tono ligeramente más cálido y pétreo para evocar el granito gallego en muros perimetrales, postes y carcasas metálicas, manteniendo `#8C96A0` como referencia histórica del prototipo.
2. **Frentes de encimera con azul marino corporativo**: reciben `brand_navy #1D3557` ($L = 0.0350$) mediante `surface_material_override` en las escenas de encimera (con base `counters_atlas` en `mat_wall_granite.tres` en el `.glb.import`), reforzando la identidad visual corporativa de **PulpaSA** (D21) en la línea de trabajo y proporcionando contraste tonal de **10.12 : 1** bajo los tableros claros `#EDE8DF`.
3. **`env_atlas` se fija en `#9A948C` (`mat_wall_granite.tres`)**: siguiendo exactamente el prototipo aprobado (`capture_minimal.gd:558`), donde `env_atlas` está en suelos, fondos y atrezo exterior, evitando teñir de rojo elementos no deseados.

### 0.2 Qué se conserva por referencia (no se duplica)
Siguen vigentes sin cambios los siguientes apartados de las versiones archivadas:
- **Unidades, escala y medidas de referencia de mundo y colisión**: [`art-bible-v1.md` §2.1](art-bible-v1.md) y [`art-bible-v2.md` §1.2](art-bible-v2.md) (1 u = 1 m; mostrador 1,10 m × 1,10 m × 0,90 m; estaciones, cajas y personajes en sus cajas actuales).
- **Orientación (`-Z` frente), origen en el suelo (`Y = 0`) y nodos de contrato (`Marker3D`, `Anchor_*`, `Slot_*`)**: [`art-bible-v1.md` §2.3](art-bible-v1.md) y [`docs/arch/scene-tree.md`](../arch/scene-tree.md). **Regla dura**: ninguna ficha de arte modifica posiciones de estaciones, colisiones ni `Marker3D` (**0.0 px** de deriva en pantalla).
- **Nombres de archivos, mallas y rutas de `.glb`**: [`art-bible-v1.md` §2.4](art-bible-v1.md), [`art-bible-v2.md` §8](art-bible-v2.md) y el inventario real de slots en [`../evidence/PUL-181/slots_reales.md`](../evidence/PUL-181/slots_reales.md).
- **Cámara ortográfica fija (`godot/entities/camera/camera_rig.tscn`)**: [`art-bible-v1.md` §3](art-bible-v1.md) (`size = 12.74` m, inclinación ≈ 38°, 1 m ≈ 85 px a `1920×1080` y ≈ 33 px a `800×370`).
- **Identidad y manual de marca PulpaSA (D21)**: [`brand.md`](brand.md) (propuesta A · Mariña: `#C8402F`, `#1D3557`, `#F7F4EC`, `#F2C230`).

---

## 1. Dirección artística «Feira Clara»

### 1.1 Principios visuales
1. **Color plano mate sin ruido de textura**: cada pieza de madera, piedra, tela, metal o alimento se lee por su **silueta**, su **valor tonal ($L$)** y un **único color sólido** por material. Se prohíben las texturas de ruido PBR (grano de madera, cemento manchado, óxido, arañazos, mapas ORM y mapas de normales).
2. **Separación figura / fondo por luminosidad**:
   - **Suelo de cocina** cálido medio (`#C4A882`, $L = 0.4135$).
   - **Tableros de trabajo** en piedra/madera clara (`#EDE8DF`, $L = 0.8105$) y **faldones estructurales** en azul marino corporativo (`#1D3557`, $L = 0.0350$).
   - **Ingredientes, cajas y condimentos** en colores saturados con relación de contraste **≥ 3:1** frente a la superficie donde descansan.
3. **Cero destellos especulares**: todos los materiales 3D desactivan el lóbulo especular (`specular_mode = SPECULAR_DISABLED`, `metallic = 0.0`, `roughness` entre `0.65` y `0.95`). El metal (olla, tanque, encimeras) se expresa por su color frío (`#9A948C` / `#EDE8DF`) y su forma, nunca por reflejos puntuales que compitan con los anillos de cocción o los iconos D26.
4. **Legibilidad simultánea en escritorio (`1920×1080`) y móvil (`800×370`, D26/D27)**: ningún elemento funcional depende de detalles menores de 6 px a 1080p (≈ 2,5 px a `800×370`) ni de textos con contorno hueco.

---

## 2. Paleta cerrada en hex (16 colores)

La paleta completa del juego (mundo 3D, comida, personajes, puestos y UI) queda cerrada en **16 colores en hex** (dentro del rango normativo de 12 a 20 colores de AC1). No se permite introducir códigos hex fuera de esta tabla salvo el tinte cálido de la luz solar (`#FFF4E0`, §4.1).

| # | Token | Hex | $L$ (WCAG 2.1) | Grupo | Uso obligatorio en el juego |
|---:|---|---|---:|---|---|
| 1 | `ground_sand` | `#C4A882` | 0.4135 | Entorno y arquitectura | Suelo interior de la cocina (`Floor/Mesh`), arena exterior de la romería (`ground_e`, `ground_w`) y sacos de arpillera de la cachelera (`cachelos_storage`) |
| 2 | `wall_granite` | `#9A948C` | 0.2994 | Entorno y arquitectura | Muro perimetral de granito (`Wall*`, `back_e/w_wall`), postes exteriores, cuerpo de acero de la olla (`pot`), del tanque (`octopus_storage`), de la estantería (`box_shelf`) y del cubo (`trash_bin`), más hojas de cuchillo/tijeras |
| 3 | `meadow_green` | `#4FA05A` | 0.2754 | Entorno / Puesto 4 / UI | Prado exterior, color de fondo de cámara (`BG_COLOR`), vegetación lejana (`*_trees`, `*_foliage`), toldillo del **puesto 4**, zona de entrega activa (`delivery_zone_on.tres`) y barra de paciencia alta (> 60 %) |
| 4 | `surface_top` | `#EDE8DF` | 0.8105 | Mobiliario y soportes claros | Tableros superiores de todas las encimeras, tablas de corte, interior de las cajas de reparto (`box_inside`), alfombrilla de condimentos (`ServiceMat`), collar superior de dispensadores y borde de 2 px de los paneles UI |
| 5 | `brand_navy` | `#1D3557` | 0.0350 | Marca PulpaSA y soportes oscuros | Faldones/frentes de encimeras y puestos de entrega, rayas pares del toldo, marco `OrderPlateFrame`, glifo `#1..#4` (`%OrderLabel`), zócalo `ServiceFascia`, cuenco de cachelos (`CachelosBowl`), pantalones de cocineros y fondo opaco de paneles HUD (`UiPanel`) |
| 6 | `brand_red` | `#C8402F` | 0.1615 | Marca PulpaSA y cajas | Cuerpo exterior de las 3 cajas de reparto (`box_outside`), toldillo del **puesto 1**, rayas principales del toldo, acento corporativo PulpaSA y barra de paciencia crítica (< 30 %) |
| 7 | `ui_cream` / `salt` | `#F7F4EC` | 0.9053 | Marca / §3.4 / UI | **Sal gruesa (§3.4)**, fondo de placa `OrderPlatePaper`, número frontal de puesto `StandNumber` (`1..4`), rayas claras del toldo, camisa y gorro de cocinero, papel de ticket y texto principal del HUD |
| 8 | `octopus_raw` | `#E0AFB2` | 0.4972 | Comida y personajes | **Pulpo crudo** (cuerpo y tentáculos en tanque, mano, encimera y olla) y tono de piel estilizado de los personajes |
| 9 | `octopus_cooked` | `#B8283D` | 0.1204 | Comida (estado) | **Pulpo cocido** entero (`octopus_cooked`) y capas de rodajas cortadas dentro de la caja (`octopus_pieces` en `Model/Octopus`) |
| 10 | `potato_raw` | `#8E6B47` | 0.1672 | Comida y madera cálida | **Patata cruda** con piel (`cachelos_raw`), mesas/bancos de madera de la romería (`props_e/w_tables`), mangos de madera y borde histórico de cachelos (§3.4) |
| 11 | `cachelos_cooked` | `#F2D56B` | 0.6753 | Comida (§3.4) | **Cachelos cocidos (§3.4)** en olla, cuenco y caja (`cachelos_pieces` en `Model/Cachelos`), y pegatina ovalada D26 de cachelos |
| 12 | `state_burnt` | `#2A2320` | 0.0180 | Comida (estado) y tinta | **Ingrediente quemado** (pulpo o cachelos), boca interior oscura de la olla y del cubo de basura, tinta `StickerInk.INK` (contorno e icono interior de pegatinas D26) y pozos oscuros del HUD (`UiHeader`, `DisplayWell`) |
| 13 | `paprika_sweet` | `#D6361F` | 0.1703 | Condimento (§3.4) | **Pimentón dulce (§3.4)**: cuerpo del dispensador `SweetDressing`, pegatina circular D26 y partículas de aliño dulce (`%Gesture`) |
| 14 | `paprika_hot` | `#8F1A14` | 0.0663 | Condimento (§3.4) | **Pimentón picante (§3.4)**: cuerpo del dispensador `HotDressing`, pegatina octogonal D26, marca `hot_mark` y partículas de aliño picante (`%Gesture`) |
| 15 | `p1_blue` | `#2F6FB5` | 0.1531 | Jugador 1 y puesto 2 | Delantal, pañuelo y aro de suelo (`ring_active_p1`) del **Jugador 1**, toldillo del **puesto 2** y agua interior del tanque de pulpo |
| 16 | `p2_amber` / `oil` | `#F2C230` | 0.5767 | Jugador 2 / §3.4 / UI | **Aceite de oliva (§3.4)**, delantal, pañuelo y aro de suelo (`ring_active_p2`) del **Jugador 2**, toldillo del **puesto 3**, marcas de pasaplatos (`pass_mark`), cifras/reloj del HUD y barra de paciencia media (30–60 %) |

---

## 3. Biblioteca de materiales planos compartidos (≤ 20 `.tres`)

### 3.1 Catálogo cerrado de 18 materiales en `godot/assets/materials/v3/`
Toda la escena 3D utiliza una biblioteca cerrada de **18 recursos `StandardMaterial3D`** en `godot/assets/materials/v3/` (cumpliendo el límite **≤ 20 `.tres`** de AC1).
- **Parámetros obligatorios comunes a los 16 materiales opacos (`#1..#16`)**:
  - `metallic = 0.0`
  - `specular_mode = BaseMaterial3D.SPECULAR_DISABLED` (`2`)
  - `albedo_texture = null`, `normal_enabled = false`, `ao_enabled = false`, `roughness_texture = null`, `metallic_texture = null`
- **Dos materiales técnicos adicionales (`#17` y `#18`)**:
  - `mat_tent_plate.tres` (`#17`): único material 3D con textura gráfica permitida para el cartel de marca PulpaSA en el faldón del toldo (`tent_plate`, §3.2).
  - `mat_hidden_alpha.tres` (`#18`): material transparente (`transparency = TRANSPARENCY_ALPHA`, `albedo_color = Color(0, 0, 0, 0)`) para ocultar sub-superficies de malla importada (como `env_sign` y `env_board` dentro de `tent_structure` en `tent.glb`, §5.2) sin remodelar el `.glb`.

| # | Recurso `.tres` (`res://assets/materials/v3/`) | Color hex | Roughness | Metallic | Specular | Superficies y slots de material (`.glb` / `.tscn`) a los que se aplica (ver `slots_reales.md`) |
|---:|---|---|---|---:|---:|---|
| 1 | `mat_ground_sand.tres` | `#C4A882` | `0.95` | `0.0` | `DISABLED` | Suelo interior de cocina (`Floor/Mesh` en `kitchen_layout.tscn`), arena exterior (`mat_ground_dirt` y `mat_paint_worn_beige` en `ground_e/w`, `back_e/w`), sacos de patatas (`mat_burlap` en `cachelos_storage.glb`) y cajas de cartón (`mat_cardboard` en `box_shelf.glb`, encimeras) |
| 2 | `mat_wall_granite.tres` | `#9A948C` | `0.92` | `0.0` | `DISABLED` | Muro perimetral (`mat_granite` en `back_e/w`), postes y vallas (`env_fence`), atrezo/fondos (`env_atlas`, `mat_paint_worn_grey`), cuerpo metálico de olla (`pot.glb`), tanque (`octopus_storage.glb`), estantería (`box_shelf.glb`), cubo (`trash_bin.glb`) (`mat_steel_brushed`, `mat_steel_brushed_mid`) y hojas de cuchillo |
| 3 | `mat_meadow_green.tres` | `#4FA05A` | `0.95` | `0.0` | `DISABLED` | Prado exterior y vegetación (`mat_grass`, `env_fern`, `env_foliage`), manguera de gas (`mat_rubber_hose_green` en `pot.glb`), toldillo del puesto 4 (`mat_canvas_stand_4` en `order_stand.glb`) y base activa de entrega (`delivery_zone_on.tres` en `order_stand.tscn`) |
| 4 | `mat_surface_top.tres` | `#EDE8DF` | `0.85` | `0.0` | `DISABLED` | Tableros superiores de encimeras (`mat_steel_brushed_top` en `counter_*.glb`, `pass_*.glb`, `rail_1m.glb`), interior de cajas de reparto (`atlas_box` en `box.glb` y `box_shelf.glb`), etiqueta de cubo (`mat_food_tray_liner`), soporte `seasoning_station_atlas`, alfombrilla `ServiceMat` y collar de dispensadores |
| 5 | `mat_brand_navy.tres` | `#1D3557` | `0.90` | `0.0` | `DISABLED` | Faldones frontales y zócalos (`mat_steel_dark`, `order_stand_atlas`, override en `counters_atlas`), soporte de cocineros (`mat_cook_atlas`), pantalones (`mat_cloth_pants` en `cook.glb`), cuenco exterior de `cachelos_bowl.glb`, marco `OrderPlateFrame` y frente de puesto en `order_stand.tscn` |
| 6 | `mat_brand_red.tres` | `#C8402F` | `0.80` | `0.0` | `DISABLED` | Exterior de las cajas de reparto (`mat_plastic_red` en `box.glb`), tapa del cubo (`trash_bin.glb`), acentos de `pot.glb` y `octopus_storage.glb`, rayas rojas del toldo (`mat_canvas_red` en `tent.glb`), toldillo del puesto 1 (`mat_canvas_stand_1` en `order_stand.glb`) y manguera (`mat_rubber_hose_red`) |
| 7 | `mat_ui_cream.tres` | `#F7F4EC` | `0.90` | `0.0` | `DISABLED` | Rayas claras del toldo (`mat_canvas_paper` en `tent.glb`, `awning_*` en `order_stand.glb`), camisa y gorro de cocinero (`mat_cloth_shirt` en `cook.glb`), placa `OrderPlatePaper` en `order_stand.tscn`, partículas de sal gruesa y papel de tickets |
| 8 | `mat_octopus_raw.tres` | `#E0AFB2` | `0.88` | `0.0` | `DISABLED` | Pulpo crudo (`mat_food_octopus_raw` en `octopus.glb` y tentáculos de `octopus_storage.glb`), tono de piel estilizado claro (`mat_skin_light` en `cook.glb` y `props_e/w`) |
| 9 | `mat_octopus_cooked.tres` | `#B8283D` | `0.65` | `0.0` | `DISABLED` | Pulpo cocido (`mat_food_octopus_cooked` y `mat_food_octopus_pieces` en `octopus.glb` y `octopus_pieces.glb`, `atlas_octopus` en pulpo cocido y almacén) |
| 10 | `mat_potato_raw.tres` | `#8E6B47` | `0.92` | `0.0` | `DISABLED` | Patata cruda con piel (`mat_food_potato_raw` en `cachelos.glb`), saco de patatas (`atlas_cachelos_storage` en `cachelos_storage.glb`), madera cálida (`mat_wood_used`, `mat_wood_dark`), cuenco de barro (`mat_clay`), tono de piel oscuro (`mat_skin_dark` en `cook.glb`) |
| 11 | `mat_cachelos_cooked.tres` | `#F2D56B` | `0.80` | `0.0` | `DISABLED` | Cachelos cocidos (`mat_food_potato_cooked` y `atlas_cachelos` en `cachelos.glb`, `cachelos_pieces.glb`, `cachelos_bowl.glb`), capa `Model/Cachelos` (`cachelos_pieces`) en `box.tscn` y disco de pegatina `cachelos` |
| 12 | `mat_state_burnt.tres` | `#2A2320` | `0.95` | `0.0` | `DISABLED` | Estado quemado (`mat_food_octopus_burnt` en `octopus.glb`, `mat_food_potato_burnt` en `cachelos.glb`), caucho/juntas/mangueras (`mat_rubber`), interior de boca de `pot.glb` y `trash_bin.glb`, y tinta delimitadora `StickerInk.INK` (`#2A2320`) |
| 13 | `mat_paprika_sweet.tres` | `#D6361F` | `0.75` | `0.0` | `DISABLED` | Cuerpo del dispensador dulce en `seasoning_dispenser.tscn` / `seasoning_station.tscn` (`surface_material_override` en malla `paprika_sweet` / cuerpo de escena), pegatina `paprika_sweet` en `box.tscn` y partículas de aliño dulce |
| 14 | `mat_paprika_hot.tres` | `#8F1A14` | `0.75` | `0.0` | `DISABLED` | Cuerpo del dispensador picante en `seasoning_dispenser.tscn` / `seasoning_station.tscn` (`surface_material_override` en malla `paprika_hot` / cuerpo de escena), pegatina `paprika_hot` en `box.tscn` y partículas de aliño picante |
| 15 | `mat_p1_blue.tres` | `#2F6FB5` | `0.75` | `0.0` | `DISABLED` | Delantal y gorro de J1 (`mat_cloth_player_1` en `cook.glb`), aro activo `ring_active_p1.tres`, toldillo del puesto 2 (`mat_canvas_stand_2` en `order_stand.glb`), agua (`pot_water`, `mat_glass_water`), plástico azul (`mat_plastic_blue` en `trash_bin`, `pot`, `box_shelf`, `octopus_storage`) |
| 16 | `mat_p2_amber.tres` | `#F2C230` | `0.75` | `0.0` | `DISABLED` | Delantal y gorro de J2 (`mat_cloth_player_2` en `cook.glb`), aro activo `ring_active_p2.tres`, toldillo del puesto 3 (`mat_canvas_stand_3` en `order_stand.glb`), marcas de pasaplatos (`counter_pass_signs`), bombillas `mat_emissive_bulb` y partículas de aceite |
| 17 | `mat_tent_plate.tres` | `#F7F4EC` (base) | `0.90` | `0.0` | `DISABLED` | Superficie `env_plate` de `tent_plate` en `tent.glb` (placa frontal del toldo con logotipo **PulpaSA**, §3.2) usando textura única `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` |
| 18 | `mat_hidden_alpha.tres` | `#00000000` | `1.00` | `0.0` | `DISABLED` | Superficies `env_sign` y `env_board` de `tent_structure` en `tent.glb` (`transparency = TRANSPARENCY_ALPHA`, `albedo_color.a = 0.0`) para ocultar el cartel superior vacío y las pizarras sin remodelar `.glb` (§5.2) |

### 3.2 Regla sobre el entorno con textura (`env_plate`) y texturas gráficas permitidas (punto débil 3 de PUL-180, AC3)
En el prototipo de PUL-180 se dejaron activas las texturas `env_plate` del toldo y las texturas de señalética mientras el resto del mundo pasaba a color plano, sin una regla escrita que delimitase qué texturas son válidas en la v3. La regla queda fijada así:

1. **Prohibición absoluta de texturas PBR de superficie en 3D**:
   - Ningún material 3D del juego puede usar texturas de albedo de ruido/desgaste, mapas ORM (`*_orm.png`) ni mapas de normales (`*_normal.png`).
   - En todos los `.glb.import`, los slots de material en `_subresources["materials"]` se redirigen a los `.tres` de `res://assets/materials/v3/` manteniendo `materials/extract = 0` y fijando obligatoriamente `gltf/embedded_image_handling = 0` (Discard All Textures). Se eliminan del repositorio las texturas PBR extraídas junto a los `.glb` (`godot/assets/models/**/*.png`) y la carpeta `godot/assets/textures/v2/`.
2. **Únicas texturas gráficas permitidas en todo el proyecto**:
   - **`env_plate` (`mat_tent_plate.tres` sobre `tent_plate` en `tent.glb`)**: se conserva como **único rótulo gráfico 3D de marca** en el faldón frontal del toldo, porque muestra el logotipo corporativo **PulpaSA** (D21, propuesta A · Mariña) con colores planos de la paleta (`#1D3557`, `#C8402F`, `#F7F4EC`). Para asegurar el alineamiento perfecto con el mapeo UV del modelo `tent_plate`, **se fija como única textura permitida `res://assets/models/environment/romeria_v2/tent_plate_albedo.png`** (única ubicación existente en el proyecto, preservada explícitamente en la limpieza de `PUL-188`), prohibiendo expresamente sustituirla por `pulpasa_horizontal.png` u otros atlas de proporciones distintas que desplazan el logotipo. El material lleva `metallic = 0.0`, `roughness = 0.90`, `specular_mode = SPECULAR_DISABLED` y 0 mapas de normales/ORM.
   - **Iconos vectoriales/planos de señalética y UI (D26 y §3.4)**: los 5 iconos de condimentos (`godot/assets/ui/seasonings/*.png`), los 4 iconos de acción contextual D26 (`godot/assets/ui/actions/*.png`), los emblemas de marca en `godot/assets/textures/brand/*.png` y las marcas planas de suelo/pasaplatos si usan máscara alfa de silueta limpia.

### 3.3 Cómo se asignan los materiales a los `.glb` en Godot 4.7 (sin remodelar mallas)
Para cumplir `test_assets_models.gd` (`materials/extract == 0` en todos los `.glb.import`) y evitar las 239 instancias duplicadas de materiales en memoria:

1. **Obligatoriedad de `embedded_image_handling = 0` en `.glb.import` (Finding 2)**:
   Actualmente todos los archivos `.glb.import` tienen configurado `gltf/embedded_image_handling = 1` (extraer texturas), lo que provoca que al reimportar se generen de nuevo los archivos `.png` en disco. Las fichas `PUL-186` y `PUL-187` deben fijar explícitamente `gltf/embedded_image_handling = 0` (Discard All Textures) en cada `.glb.import` que modifiquen, habilitando a `PUL-188` para eliminar definitivamente los `.png` extraídos sin riesgo de regeneración.
2. **Mapeo de slots en `_subresources`**:
   Cada `.glb.import` mapea sus slots de material internos dentro de `_subresources["materials"]["<slot_name>"]` con `"use_external/enabled": true` y `"use_external/path": "res://assets/materials/v3/mat_<nombre>.tres"`, manteniendo `materials/extract = 0`.
3. **Regla para atlas multicolor (Finding 1)**:
   - **`env_atlas`**: se mapea a `#9A948C` (`mat_wall_granite.tres`) en `back_e/w`, `ground_e/w`, `props_e/w` y `tent.glb`, siguiendo el prototipo probado (`capture_minimal.gd:558`).
   - **`counters_atlas`**: se mapea a `mat_wall_granite.tres` (`#9A948C`) en `furniture/counters/*.glb.import`. En los frentes donde se requiera faldón azul marino corporativo, se aplica `surface_material_override` a `mat_brand_navy.tres` en la escena dueña.
   - **`atlas_box`**: se mapea a `mat_surface_top.tres` (`#EDE8DF`), aportando el fondo claro interior de las cajas de reparto.
   - **`atlas_octopus`**: se mapea a `mat_octopus_cooked.tres` (`#B8283D`).
   - **`atlas_cachelos`**: se mapea a `mat_cachelos_cooked.tres` (`#F2D56B`).
   - **`atlas_cachelos_storage`**: se mapea a `mat_potato_raw.tres` (`#8E6B47`).
   - **`order_stand_atlas`**: se mapea a `mat_brand_navy.tres` (`#1D3557`).
   - **`seasoning_station_atlas`**: se mapea a `mat_surface_top.tres` (`#EDE8DF`).
   - **`mat_cook_atlas`**: se mapea a `mat_brand_navy.tres` (`#1D3557`).
4. **Regla para slots compartidos entre sub-mallas (Finding 1)**:
   - En `seasoning_dispenser.glb` (cuyos slots reales son `seasoning_signs`, `mat_steel_dark` y `mat_steel_brushed`), el aliño dulce (`#D6361F`) y picante (`#8F1A14`) se asignan en la escena `seasoning_dispenser.tscn` / `seasoning_station.tscn` mediante `surface_material_override` en las mallas activas (`paprika_sweet`, `paprika_hot`), sin suponer slots inexistentes en el `.glb` ni añadir mallas nuevas (D28).
   - En `octopus.glb` y `cachelos.glb`, las mallas de los 3 estados (`raw`, `cooked`, `burnt`) comparten slots de atlas pero su visualización se controla mediante la visibilidad de nodos en `octopus.tscn` y `cachelos.tscn`.
5. **Regla para slots funcionales y modelos de pipeline (Finding 5)**:
   - Se preservan con su material técnico o shader: `mat_outline_hull` (shader de silueta de selección), `mat_sticker_atlas` (pegatinas 3D), `delivery_zone_off.tres` / `delivery_zone_on.tres` (señal luminosa interactiva de entrega), `seasoning_signs`, `counter_pass_signs`, `kiosk_delivery_signs` y `mat_emissive_screen`.
   - Los modelos bajo `godot/assets/models/_pipeline/**` (`materials_v2_test.glb`, `test_cube.glb`) son bancos de prueba internos del pipeline de importación y quedan excluidos de la comprobación de materiales en la escena de juego.

---

## 4. Luz, `WorldEnvironment` y post-proceso

### 4.1 Iluminación (`godot/entities/environment/environment.tscn` y `render_config.tres`)
- **Luz direccional única (`Sun : DirectionalLight3D` en `environment.tscn`)**:
  - `light_color = Color("#FFF4E0")` (blanco solar cálido).
  - `light_energy = 1.18` (sustituye el `1.34` de la v2 que quemaba las superficies claras `#EDE8DF` y `#F7F4EC`).
  - `shadow_enabled = true`, `shadow_opacity = 0.75`, `shadow_blur = 3.2` (sombras suaves sin bordes dentados).
- **Cero luces puntuales (`Bulbs` apagadas)**:
  - Las 5 `OmniLight3D` bajo `Environment/Bulbs` se desactivan (`Bulbs.visible = false` y cada `OmniLight3D` con `visible = false`, conservando el nodo `Bulbs` en el árbol para respetar el contrato de `docs/arch/scene-tree.md` §3 sin abrir ADR). Esto elimina los brillos circulares sobre las encimeras delanteras (resolviendo de raíz D7 de `PUL-145`).
- **Luz ambiental y cielo (`godot/data/config/render_config.tres`)**:
  - `background_mode = BG_COLOR`, `background_color = Color("#4FA05A")` (`meadow_green`).
  - `ambient_light_source = AMBIENT_SOURCE_COLOR`, `ambient_light_color = Color("#EDE8DF")`, `ambient_light_energy = 0.72`, `ambient_light_sky_contribution = 0.0`.
  - `reflected_light_source = REFLECTION_SOURCE_DISABLED`.
  - `tonemap_mode = TONEMAPPER_FILMIC`, `tonemap_exposure = 1.0`, `tonemap_white = 6.0`.

### 4.2 Regla de post-proceso y SSAO (punto débil 4 de PUL-180, AC3)
En la revisión de PUL-180 se señaló que el prototipo mantenía `ssao_enabled = true` de la v2 sin una decisión explícita en la biblia sobre qué post-procesos están permitidos en el estilo plano. La regla en la v3 queda cerrada así:

| Efecto de post-proceso | Estado en v3 | Parámetros obligatorios en `render_config.tres` / `environment.tscn` | Justificación visual |
|---|:---:|---|---|
| **SSAO de contacto** | **PERMITIDO (activo por defecto)** | `ssao_enabled = true`, `ssao_radius = 0.45`, `ssao_intensity = 1.1`, `ssao_power = 1.3`, `ssao_detail = 0.0`, `ssao_light_affect = 0.1` | Al usar colores planos mates sin texturas ni biseles marcados, el SSAO suave de radio corto (`0.45` m, sin canal `detail`) aporta la línea de contacto entre módulos de encimera contiguos y entre estaciones y el suelo `#C4A882`, evitando que dos bloques del mismo `#EDE8DF` o `#1D3557` se fundan en una sola mancha plana. *(Ver §10 P1 por si el responsable prefiere desactivarlo en perfiles de bajo consumo).* |
| **Bloom / Glow** | **PROHIBIDO** | `glow_enabled = false` | Creaba halos lechosos alrededor de las placas blancas `#F7F4EC` y alteraba la luminancia de los colores de §3.4. |
| **LUT 3D de color** | **PROHIBIDO** | `adjustment_color_correction = null`, `adjustment_enabled = true`, `adjustment_brightness = 1.0`, `adjustment_contrast = 1.05`, `adjustment_saturation = 1.05` | La LUT cálida de la v2 (`warm_ lut.png`) teñía de amarillo los blancos `#F7F4EC` y desplazaba los códigos hex de la paleta cerrada. |
| **Viñeta 2D (`Vignette`)** | **PROHIBIDO** | `Environment/Vignette.visible = false` (conservando el nodo en `environment.tscn` por contrato `scene-tree.md` §3) | Oscurecía las esquinas donde viven los tickets del HUD y los contadores superiores. |
| **Tilt-shift / DoF** | **PROHIBIDO** | `tilt_shift_enabled = false`, `CameraRig` sin `CameraAttributesPractical` de desenfoque | En cámara ortográfica minimalista toda la pantalla (desde los tickets superiores hasta los 4 puestos inferiores) debe verse con nitidez total. |

### 4.3 Presupuesto de rendimiento y memoria de la v3
- **Materiales 3D activos en escena (`level_01.tscn`)**: **≤ 20 `.tres`** de la biblioteca v3 (frente a los 239 materiales instanciados en memoria en la v2).
- **Texturas 3D cargadas por `level_01.tscn`**: **≤ 5 texturas gráficas** (`env_plate` + iconos de señalética), frente a las > 60 texturas PBR de la v2.
- **Luminancia media de fotograma en `level_01`**: dentro del rango **`0.08–0.95`** (objetivo `0.30–0.45`, verificado en `test_level_01.gd` y en la ficha de QA visual `PUL-189`).
- **Rendimiento**: ≥ 60 fps estables a `1920×1080` y reducción neta de VRAM y tiempo de carga de `level_01.tscn` frente a la línea base v2. Para asegurar una comparación científica válida con idéntico método (Finding 3), la línea base («antes») se mide con el script fijado en `docs/evidence/PUL-189/measure_perf.gd` ejecutado sobre `main` antes de la oleada 1 (commit base `e86baf3`, inmediatamente anterior a `PUL-182`), durabilizando `docs/evidence/PUL-189/antes/perf_v2.json`, y la medición v3 («después») se ejecuta con ese idéntico script tras `PUL-188` (`docs/evidence/PUL-189/despues/perf_v3.json`).

---

## 5. Qué atrezo se quita y cuál se queda

Como en esta primera oleada no se remodelan los `.glb` (D28), la limpieza formal se ejecuta **ocultando (`visible = false`) las sub-mallas decorativas ruidosas** en las escenas `.tscn` correspondientes, sin alterar colisiones ni nodos de contrato.

### 5.1 Tabla de poda por zonas (Z0–Z3)

| Zona | Qué se QUITA (`visible = false` en `.tscn`) | Qué se QUEDA (visible y con material plano v3) | Escena donde se aplica |
|---|---|---|---|
| **Z0 · Jugadores y comida en mano** | Ningún nodo de contrato; se eliminan solo las texturas de tela/piel manchada por material plano | Cocineros J1 (`#2F6FB5`) y J2 (`#F2C230`), aros de suelo, cajas (`#C8402F`/`#EDE8DF`), pulpo (`#E0AFB2`/`#B8283D`/`#2A2320`) y cachelos (`#8E6B47`/`#F2D56B`/`#2A2320`) | `player.tscn`, `box.tscn`, `octopus.tscn`, `cachelos.tscn` |
| **Z1 · Superficies de trabajo y suelo de cocina** | - Charcos y rodadas del suelo (`ground_w_decals`, `ground_e_decals`)<br>- Tablas de corte y cuchillos decorativos (`BackRight/Model/props_board`, `WallRight/Model/props_board`)<br>- Cuncas y jarras decorativas (`BackBetweenStoragePot/Model/props_crock`, `BackRight/Model/props_crock`, `WallLeftKitchen/Model/props_crock`)<br>- Flechas y etiquetas pre-D25 en `seasoning_station.tscn` (`CounterArrow_*`, `Label_*`, `ServiceArrow_*` de `oil`, `salt` y las desalineadas de 5 huecos; ver §5.3)<br>- Paneles laterales y etiquetas de la estantería (`SizePanel_large`, `SizePanel_medium`, `SizePanel_small`, `labels`; **ocultos con `visible = false`, nunca borrados del árbol** para cumplir `test_rack_panels_cannot_be_walked_into` en `test_level_01.gd`) | - Suelo liso `#C4A882`<br>- Tableros de encimera limpios `#EDE8DF` con faldón `#1D3557`<br>- Marcas de los 6 pasaplatos en `#F2C230`<br>- Alfombrilla `ServiceMat` (`#EDE8DF`), zócalo `ServiceFascia` (`#1D3557`), los 2 dispensadores activos (`SweetDressing` `#D6361F`, `HotDressing` `#8F1A14`) y el `CachelosBowl` (`#1D3557` con cachelos `#F2D56B`) | `environment.tscn`, `kitchen_layout.tscn`, `seasoning_station.tscn`, `box_shelf.tscn` |
| **Z2 · Frentes y estaciones** | - Bombona y manguera trasera de la olla (`Model/Pot/pot/gas_bottle`)<br>- Bomba lateral del tanque de pulpo (`Model/octopus_storage/pump`)<br>- Cajas de cartón apiladas bajo el rack (`Model/box_shelf/cartons`) | - Cuerpo de olla, tanque, cachelera, estantería y cubo de basura en `#9A948C` / `#C4A882`<br>- Vapor `Steam` de la olla (reforzado al cocer, absorbiendo la parte de escena de `PUL-144`)<br>- Los 4 puestos de entrega (`OrderStand1..4`) con sus toldillos (`#C8402F`, `#2F6FB5`, `#F2C230`, `#4FA05A`) y sus números corregidos (§6.3) | `kitchen.tscn`, `octopus_storage.tscn`, `box_shelf.tscn`, `order_stand.tscn` |
| **Z3 · Fondo y romería** | - **Cartel superior vacío y pizarras sobre el muro** (`env_sign` y `env_board` en `tent_structure`, ver §5.2)<br>- Bombillas del toldo (`tent_bulbs`) y nodo `Bulbs`<br>- Guirnaldas y cables (`props_w_garlands`, `props_e_garlands`)<br>- Valla metálica (`back_w_fence`, `back_e_fence`)<br>- Generador, bidones, cajas y bultos traseros/laterales (`back_w_props`, `back_e_props`, `props_w_props`, `props_e_props`) | - Carpa principal a rayas (`#C8402F` y `#F7F4EC`) con la **placa `tent_plate` (`env_plate`) de PulpaSA**<br>- Muro de granito liso (`#9A948C`)<br>- Prado y masas de árboles en verde `#4FA05A`<br>- Mesas y bancos de madera de la romería (`props_w_tables`, `props_e_tables`) en `#8E6B47` | `environment.tscn` y `tent.glb.import` |

### 5.2 Regla del cartel superior y las pizarras traseras (punto débil 1 de PUL-180, AC3)
En el prototipo de PUL-180 (`capture_minimal.gd:556-557`), al sustituir los materiales `env_sign` y `env_board` de `tent.glb` por el color plano `#1D3557`, el cartel grande sobre el toldo y las dos pizarras colgadas del muro trasero quedaron como **rectángulos azul marino vacíos**, redundantes además con la placa `tent_plate` que ya muestra el logotipo **PulpaSA** en el faldón del toldo.
- **Diagnóstico técnico en `tent.glb`**: el nodo `tent_structure` contiene 4 superficies de material en una sola malla (`['mat_paint_worn_grey', 'env_atlas', 'env_sign', 'env_board']`), mientras que la placa buena del faldón es un nodo separado (`tent_plate` con material `env_plate`).
- **Regla normativa en la v3**:
  1. **Se eliminan visualmente el cartel superior vacío (`env_sign`) y las dos pizarras (`env_board`)**: en `tent.glb.import` (y/o en `surface_material_override/2` y `surface_material_override/3` de `Model/Tent/tent/tent_structure` en `environment.tscn`), los slots `env_sign` y `env_board` se asignan a **`res://assets/materials/v3/mat_hidden_alpha.tres`** (`transparency = TRANSPARENCY_ALPHA`, `albedo_color = Color(0, 0, 0, 0)`). Así desaparecen por completo sin remodelar `tent.glb`.
  2. **La marca PulpaSA en el entorno se concentra en un único soporte limpio**: el nodo `Model/Tent/tent/tent_plate` con `mat_tent_plate.tres` (`env_plate`) centrado en el faldón delantero de la carpa.

### 5.3 Alineación y limpieza de la estación de condimentos (`seasoning_station.tscn`)
En `seasoning_station.glb` (modelado antes de D25 para 5 condimentos en `x = -2, -1, 0, +1, +2`), las sub-mallas `CounterArrow_*`, `Label_*` y `ServiceArrow_*` estaban horneadas en 5 columnas que ya no coinciden con las 3 posiciones reales de D25 (`SweetDressing` en `x = -1`, `HotDressing` en `x = 0`, `CachelosBowl` en `x = +1`).
- **Regla en la v3**: en `seasoning_station.tscn` se ocultan (`visible = false`) las 15 sub-mallas pre-D25 (`CounterArrow_*`, `Label_*`, `ServiceArrow_*` de los 5 sufijos `sweet`, `hot`, `salt`, `oil`, `potato`) para evitar flechas desplazadas o etiquetas de condimentos oscuros sobre zócalo oscuro. La lectura de los 3 puestos activos la dan directamente el cuerpo rojo vivo de `SweetDressing` (`#D6361F`, `x = -1`) y el cuerpo granate de `HotDressing` (`#8F1A14`, `x = 0`) con collar `#EDE8DF` sobre la alfombrilla clara `ServiceMat` (`#EDE8DF`), junto al cuenco `CachelosBowl` (`#1D3557` con cachelos `#F2D56B`, `x = +1`).
- **Aclaración de nombres de slots vs. nodos (Finding 1)**: `SweetDressing` y `HotDressing` son nodos de escena / instancias de `seasoning_dispenser.tscn`, no nombres de slots en `seasoning_dispenser.glb` (cuyos slots reales son `seasoning_signs`, `mat_steel_dark` y `mat_steel_brushed`). Su color específico se asigna en escena mediante `surface_material_override` en las mallas de los dispensadores activos (`paprika_sweet`, `paprika_hot`), sin alterar geometría ni remodelar `.glb` (D28).

---

## 6. Legibilidad de estados, colores de §3.4 y números de puestos

### 6.1 Estados de cocción y llenado de caja
Todos los cambios de estado combinan **salto de luminosidad ≥ 3:1** + **cambio de silueta/efectos de mundo**:

| Elemento / transición | Estado A (`hex`, $L$) | Estado B (`hex`, $L$) | Contraste WCAG 2.1 | Doble codificación (silueta / mundo) |
|---|---|---|---:|---|
| **Pulpo: crudo → cocido** | `octopus_raw` (`#E0AFB2`, `0.4972`) | `octopus_cooked` (`#B8283D`, `0.1204`) | **3.21 : 1** (`3.2104 : 1`) | Tentáculos extendidos/lacios vs. tentáculos rizados + `%CookRing` verde |
| **Pulpo: crudo → quemado** | `octopus_raw` (`#E0AFB2`, `0.4972`) | `state_burnt` (`#2A2320`, `0.0180`) | **8.05 : 1** (`8.0490 : 1`) | Humo oscuro + icono de peligro en `%CookRing` |
| **Pulpo cocido sobre encimera** | `octopus_cooked` (`#B8283D`, `0.1204`) | `surface_top` (`#EDE8DF`, `0.8105`) | **5.05 : 1** (`5.0482 : 1`) | Silueta lobulada oscura sobre tablero claro |
| **Cachelos: crudo → cocido** | `potato_raw` (`#8E6B47`, `0.1672`) | `cachelos_cooked` (`#F2D56B`, `0.6753`) | **3.34 : 1** (`3.3390 : 1`) | Patata entera ovoide vs. trozos facetados amarillos |
| **Cachelos: cocido → quemado** | `cachelos_cooked` (`#F2D56B`, `0.6753`) | `state_burnt` (`#2A2320`, `0.0180`) | **10.67 : 1** (`10.6680 : 1`) | Cambio de amarillo brillante a carbón mate |
| **Cachelo crudo sobre encimera** | `potato_raw` (`#8E6B47`, `0.1672`) | `surface_top` (`#EDE8DF`, `0.8105`) | **3.96 : 1** (`3.9614 : 1`) | Sombra de contacto SSAO + silueta cerrada |
| **Quemado sobre encimera** | `state_burnt` (`#2A2320`, `0.0180`) | `surface_top` (`#EDE8DF`, `0.8105`) | **12.66 : 1** (`12.6564 : 1`) | Máximo contraste oscuro/claro de la paleta |
| **Caja vacía vs. llena de pulpo** | `surface_top` (`#EDE8DF`, `0.8105`) | `octopus_cooked` (`#B8283D`, `0.1204`) | **5.05 : 1** (`5.0482 : 1`) | Capas `Model/Octopus` (`octopus_pieces`) + contador `%CutCounter` (`1/6..6/6`) |

### 6.2 Los 5 colores normativos de §3.4 y sus contrastes recalculados (AC2: todos ≥ 3:1)
Se conservan intactos los 5 colores de [`art-bible-v1.md` §3.4](art-bible-v1.md) (`paprika_sweet` `#D6361F`, `paprika_hot` `#8F1A14`, `salt` `#F7F4EC`, `oil` `#F2C230`, `cachelos` `#F2D56B`). Tras D25, los 3 activos en jugabilidad son `paprika_sweet`, `paprika_hot` y `cachelos`, mientras que `salt` y `oil` permanecen integrados en el gesto de partículas de aliño (`%Gesture`) y como colores normativos de la paleta.

**Regla de polaridad de soporte (AC2)**:
- Los **2 condimentos oscuros** (`#D6361F` y `#8F1A14`) se colocan siempre sobre soporte claro (`#EDE8DF` o `#F7F4EC`) y todos los discos de pegatina llevan el anillo delimitador oscuro `StickerInk.INK` (`#2A2320`), con icono interior crema `#F7F4EC` en el picante (§6.2.1).
- Los **3 condimentos claros** (`#F7F4EC`, `#F2C230` y `#F2D56B`) se colocan siempre sobre soporte oscuro (`#1D3557`, `#2A2320`, `#B8283D`, `#C8402F` o `#8E6B47`).

Tabla completa verificada por [`docs/evidence/PUL-181/calc_contrasts_v3.py`](../evidence/PUL-181/calc_contrasts_v3.py) (salida íntegra en [`docs/evidence/PUL-181/contrastes_v3.md`](../evidence/PUL-181/contrastes_v3.md)):

| Condimento (§3.4) | Hex cond. ($L$) | Superficie donde aparece en la v3 | Hex sup. ($L$) | Contraste exacto | Contraste (2 dec.) | ≥ 3:1 | Forma D26 e icono |
|---|---|---|---|---:|---:|:---:|---|
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` (`0.1703`) | Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar de bote (`mat_surface_top.tres`) | `#EDE8DF` (`0.8105`) | **3.9052 : 1** | **3.91 : 1** | SÍ | Círculo + pimentón sin chispa |
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` (`0.1703`) | Soporte crema claro (`mat_ui_cream.tres`) | `#F7F4EC` (`0.9053`) | **4.3358 : 1** | **4.34 : 1** | SÍ | Círculo |
| **Pimentón dulce** (`paprika_sweet`) | `#D6361F` (`0.1703`) | Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt.tres`) | `#2A2320` (`0.0180`) | **3.2409 : 1** | **3.24 : 1** | SÍ | Contorno interior oscuro |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` (`0.0663`) | Encimera (`ServiceMat`), interior de caja (`box_inside`) y collar de bote (`mat_surface_top.tres`) | `#EDE8DF` (`0.8105`) | **7.3993 : 1** | **7.40 : 1** | SÍ | Octógono + guindilla/chispa + `hot_mark` |
| **Pimentón picante** (`paprika_hot`) | `#8F1A14` (`0.0663`) | Icono interior / chispa crema (`mat_ui_cream.tres`) | `#F7F4EC` (`0.9053`) | **8.2150 : 1** | **8.21 : 1** | SÍ | Octógono + chispa interior crema |
| **Sal gruesa** (`salt`) | `#F7F4EC` (`0.9053`) | Zócalo (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy.tres`) | `#1D3557` (`0.0350`) | **11.2449 : 1** | **11.24 : 1** | SÍ | Cuadrado + copos (reserva §3.4 / partículas) |
| **Sal gruesa** (`salt`) | `#F7F4EC` (`0.9053`) | Anillo `StickerInk` / pozo oscuro (`mat_state_burnt.tres`) | `#2A2320` (`0.0180`) | **14.0517 : 1** | **14.05 : 1** | SÍ | Cuadrado |
| **Sal gruesa** (`salt`) | `#F7F4EC` (`0.9053`) | Cama de pulpo cocido en la caja y partículas sobre pulpo (`mat_octopus_cooked.tres`) | `#B8283D` (`0.1204`) | **5.6047 : 1** | **5.60 : 1** | SÍ | Partículas sobre pulpo |
| **Sal gruesa** (`salt`) | `#F7F4EC` (`0.9053`) | Borde exterior rojo de la caja (`mat_brand_red.tres`) | `#C8402F` (`0.1615`) | **4.5166 : 1** | **4.52 : 1** | SÍ | Cuadrado sobre borde de caja |
| **Aceite de oliva** (`oil`) | `#F2C230` (`0.5767`) | Zócalo (`ServiceFascia`), pastilla de ticket HUD y faldón (`mat_brand_navy.tres`) | `#1D3557` (`0.0350`) | **7.3773 : 1** | **7.38 : 1** | SÍ | Gota (reserva §3.4 / partículas) |
| **Aceite de oliva** (`oil`) | `#F2C230` (`0.5767`) | Anillo `StickerInk` / pozo oscuro (`mat_state_burnt.tres`) | `#2A2320` (`0.0180`) | **9.2187 : 1** | **9.22 : 1** | SÍ | Gota |
| **Aceite de oliva** (`oil`) | `#F2C230` (`0.5767`) | Cama de pulpo cocido en la caja y partículas sobre pulpo (`mat_octopus_cooked.tres`) | `#B8283D` (`0.1204`) | **3.6770 : 1** | **3.68 : 1** | SÍ | Partículas sobre pulpo |
| **Cachelos** (`cachelos`) | `#F2D56B` (`0.6753`) | Cuenco de cachelos (`CachelosBowl`), zócalo `ServiceFascia` y pastilla HUD (`mat_brand_navy.tres`) | `#1D3557` (`0.0350`) | **8.5371 : 1** | **8.54 : 1** | SÍ | Óvalo + patata troceada |
| **Cachelos** (`cachelos`) | `#F2D56B` (`0.6753`) | Anillo e icono interior `StickerInk` en pegatina D26 y ticket (`mat_state_burnt.tres`) | `#2A2320` (`0.0180`) | **10.6680 : 1** | **10.67 : 1** | SÍ | Contorno interior oscuro |
| **Cachelos** (`cachelos`) | `#F2D56B` (`0.6753`) | Cama de pulpo cocido en la caja (`mat_octopus_cooked.tres`) | `#B8283D` (`0.1204`) | **4.2551 : 1** | **4.26 : 1** | SÍ | `Model/Cachelos` (`cachelos_pieces`) sobre pulpo |
| **Cachelos** (`cachelos`) | `#F2D56B` (`0.6753`) | Borde exterior rojo de la caja (`mat_brand_red.tres`) | `#C8402F` (`0.1615`) | **3.4290 : 1** | **3.43 : 1** | SÍ | Pegatina ovalada sobre borde de caja |
| **Cachelos** (`cachelos`) | `#F2D56B` (`0.6753`) | Piel de patata cruda / barro (`mat_potato_raw.tres`) | `#8E6B47` (`0.1672`) | **3.3390 : 1** | **3.34 : 1** | SÍ | Contraste crudo vs. cocido |

- **Mínimo absoluto de toda la tabla**: **3.2409 : 1** (`3.24 : 1`, ≥ 3:1).
- **Mínimo sobre superficies primarias de estación y caja**: **3.4290 : 1** (`3.43 : 1` sobre borde de caja `#C8402F`) y **3.9052 : 1** (`3.91 : 1` sobre tablero `#EDE8DF`).

### 6.2.1 Pegatinas en soportes de juego reales y regla del anillo `StickerInk.INK` (Finding 4)
En la partida real, las pegatinas de condimento se renderizan como billboards 3D sobre el exterior de la caja de reparto (`#C8402F`) y sobre el suelo de cocina/arena (`#C4A882`) cuando la caja reposa en el suelo o los cocineros se desplazan.
- **Análisis de contraste directo sin anillo (demostración de insuficiencia)**:
  - Dulce `#D6361F` ($L = 0.1703$) directo sobre caja roja `#C8402F` ($L = 0.1615$): contraste directo **1.0416 : 1** (**1.04 : 1**, imperceptible).
  - Dulce `#D6361F` ($L = 0.1703$) directo sobre suelo `#C4A882` ($L = 0.4135$): contraste directo **2.1039 : 1** (**2.10 : 1**, insuficiente frente a 3:1).
  - Cachelos `#F2D56B` ($L = 0.6753$) directo sobre suelo `#C4A882` ($L = 0.4135$): contraste directo **1.5648 : 1** (**1.56 : 1**, insuficiente frente a 3:1).
- **Regla normativa del anillo delimitador (WCAG 2.1 boundary technique, implementada en `PUL-185`)**:
  Para garantizar que **todas** las pegatinas cumplan la técnica de contorno delimitador (boundary technique) en cualquier superficie (caja, suelo, tickets o HUD) sin depender del fondo, **todos los discos de pegatina llevan obligatoriamente un anillo exterior oscuro `StickerInk.INK` (`#2A2320`, $L = 0.0180$)**:
  - **Frontera exterior del anillo `#2A2320` frente a los fondos del mundo**:
    - Sobre la caja roja `#C8402F`: **3.1103 : 1** (**3.11 : 1**, ≥ 3:1).
    - Sobre el suelo de arena `#C4A882`: **6.8162 : 1** (**6.82 : 1**, ≥ 3:1).
    - Sobre el tablero de encimera `#EDE8DF`: **12.6564 : 1** (**12.66 : 1**, ≥ 3:1).
    El anillo exterior oscuro garantiza así la separación de la pegatina frente a cualquier fondo del juego.
  - **Frontera interior disco / anillo y discriminación del picante**:
    - Dulce `#D6361F` contra el anillo `#2A2320`: **3.2409 : 1** (**3.24 : 1**, ≥ 3:1).
    - Cachelos `#F2D56B` contra el anillo `#2A2320`: **10.6680 : 1** (**10.67 : 1**, ≥ 3:1).
    - Sal `#F7F4EC` contra el anillo `#2A2320`: **14.0517 : 1** (**14.05 : 1**, ≥ 3:1).
    - Aceite `#F2C230` contra el anillo `#2A2320`: **9.2187 : 1** (**9.22 : 1**, ≥ 3:1).
    - Picante `#8F1A14` contra el anillo `#2A2320`: da **1.7105 : 1** (**1.71 : 1**). Se descartó dotar al picante de un anillo claro `#F7F4EC` porque sobre suelo `#C4A882` daría **2.06 : 1** y sobre encimera `#EDE8DF` **1.11 : 1** (fallando frente a 3:1). Con el anillo exterior oscuro uniforme `INK`, el picante queda separado del fondo con **3.11 : 1** (caja) y **6.82 : 1** (suelo), y su lectura unívoca se garantiza mediante **doble codificación D26**:
      1. Silueta octogonal (**octógono**), exclusiva del picante frente a dulce (círculo), cachelos (óvalo), sal (cuadrado) y aceite (gota).
      2. Icono interior / chispa en crema claro `#F7F4EC`, que sobre el disco `#8F1A14` ofrece un contraste nítido de **8.2150 : 1** (**8.21 : 1**, ≥ 3:1).
  La ficha `PUL-185` extiende `owns` a `godot/entities/items/badge_row.gd` y `godot/ui/tickets/ticket_entry.gd` para aplicar este anillo delimitador uniforme a todos los discos del juego.

### 6.3 Regla de los números de los puestos de entrega en escritorio y móvil (punto débil 2 de PUL-180, AC3)
En la revisión de PUL-180 se detectó que en el prototipo (`capture_minimal.gd:758-765`):
1. `%OrderLabel` (`#1..#4`) se configuró con relleno blanco `#F7F4EC` y un contorno oscuro grueso (`outline_size = 14`, `#1D3557`) sobre una placa blanca `OrderPlatePaper` (`#F7F4EC`), haciendo que el interior del número se fundiera con el fondo (1.00 : 1) y que a resolución móvil `800×370` los números se vieran huecos, delineados y degradados.
2. `StandNumber` (`1..4`, número fijo del puesto en el faldón delantero) se tiñó de `#1D3557` sin contorno sobre un faldón delantero que en la v3 también es `#1D3557`, quedando invisible (contraste 1.00 : 1).

**Regla normativa en la v3 (`godot/entities/stations/order_stand.tscn` y `stand_palette.tres`)**:
1. **Colores de los 4 puestos (`godot/data/config/stand_palette.tres`)**:
   - Puesto 1: `#C8402F` (`brand_red`)
   - Puesto 2: `#2F6FB5` (`p1_blue`)
   - Puesto 3: `#F2C230` (`p2_amber`)
   - Puesto 4: `#4FA05A` (`meadow_green`)
2. **Placa superior de comanda (`OrderPlateFrame` + `OrderPlatePaper` + `%OrderLabel` `#1..#4`)**:
   - `Model/order_stand/OrderPlateFrame`: material `mat_brand_navy.tres` (`#1D3557`).
   - `Model/order_stand/OrderPlatePaper`: material `mat_ui_cream.tres` (`#F7F4EC`).
   - `%OrderLabel` (`Label3D` que muestra `#1..#4`): **glifo macizo oscuro sobre fondo claro**, con **`modulate = Color("#1D3557")`**, **`outline_size = 0`** (prohibido el contorno que ahueca el glifo en móvil), `font_size = 76`, `pixel_size = 0.005`, `shaded = false`. Contraste directo glifo/placa = **11.2449 : 1** (`11.24 : 1`).
3. **Número fijo frontal del puesto (`StandNumber` `1..4`)**:
   - Como el frente del mostrador del puesto usa `mat_brand_navy.tres` (`#1D3557`), `StandNumber` (`Label3D`) usa **glifo macizo claro sobre fondo oscuro**: **`modulate = Color("#F7F4EC")`**, **`outline_size = 0`** (o `outline_size = 4` del mismo `#1D3557` solo como refuerzo exterior, nunca interior), `font_size = 96`, `pixel_size = 0.005`, `shaded = false`. Contraste directo glifo/frente = **11.2449 : 1** (`11.24 : 1`).
4. **Animación `StandPopNumber`**: hereda la misma legibilidad maciza en `#F7F4EC` / `#F2C230` sobre soporte oscuro sin contornos que cierren los ojales de las cifras a `800×370`.

---

## 7. Impacto en la UI y el HUD

Los paneles 2D (`godot/ui/theme/default_theme.tres`, `godot/ui/hud/hud.tscn`, `godot/ui/tickets/order_ticket.tscn` y `godot/ui/widgets/sticker_ink.gd`) adoptan exactamente los mismos códigos hex que el mundo 3D:

1. **Paneles principales (`UiPanel` en `default_theme.tres`)**:
   - Fondo sólido `Color("#1D3557")` (`brand_navy`, **opacidad 100 %**, sin transparencias que mezclen el suelo con el texto).
   - Borde limpio de `2 px` en `Color("#EDE8DF")` (`surface_top`) y radio de esquina `4 px`.
   - Sombra dura de `3 px` en `Color(0.07, 0.13, 0.22, 0.35)` sin desenfoque.
2. **Cabeceras y pozos de marcador (`UiHeader`, `DisplayWell`)**:
   - Fondo sólido `Color("#2A2320")` (`state_burnt`), con borde de `1 px` en `Color("#EDE8DF")`.
   - Texto principal en `Color("#F7F4EC")` → contraste **14.05 : 1** sobre `#2A2320` y **11.24 : 1** sobre `#1D3557`.
   - Cifras de reloj, monedas y combo en `Color("#F2C230")` → contraste **9.22 : 1** sobre `#2A2320` y **7.38 : 1** sobre `#1D3557`.
3. **Tickets de comanda (`order_ticket.tscn`)**:
   - Franja superior `%Stripe` del color exacto del puesto en `stand_palette.tres` (`#C8402F`, `#2F6FB5`, `#F2C230`, `#4FA05A`).
   - Barra de paciencia: verde `#4FA05A` (> 60 %), ámbar `#F2C230` (30–60 %) y rojo `#C8402F` (< 30 %).
   - Iconos de condimento con doble codificación forma + color D26 y tinta `StickerInk.INK = Color("#2A2320")`.
4. **Prompts e indicadores de mundo en móvil (`800×370`, D26/D27)**:
   - Al eliminar las texturas de suelo y los reflejos especulares de las encimeras, los anillos `%CookRing`, el contador `%CutCounter` (`3/6`) y los globos de acción D26 se leen sobre fondos planos uniformes sin cambios de tamaño ni de posición.

---

## 8. Plan de implementación en fichas (PUL-182 a PUL-189) y estado de PUL-144..146

La implementación de esta biblia v3 se divide en **8 fichas (`PUL-182` a `PUL-189`)** organizadas en **4 oleadas** sin solape de `owns` ni de `touches_scenes` dentro de cada oleada, y con `godot/scenes/levels/level_01.tscn` en una única ficha de integración (`PUL-188`). El detalle de dependencias y no-solape está en [`docs/evidence/PUL-181/README.md`](../evidence/PUL-181/README.md).

| Oleada | Ficha | Rol | Alcance resumido | `touches_scenes` |
|:---:|---|---|---|---|
| **1** | [`PUL-182`](../backlog/PUL-182-biblioteca-materiales-planos-v3.md) | `asset-pipeline` | Crear la biblioteca de 18 `.tres` en `godot/assets/materials/v3/` (con textura única `res://assets/models/environment/romeria_v2/tent_plate_albedo.png` en `mat_tent_plate.tres`) y su test unitario `test_materials_v3.gd` | `[]` |
| **1** | [`PUL-183`](../backlog/PUL-183-luz-entorno-y-postproceso-v3.md) | `asset-pipeline` | `render_config.tres` v3 (SSAO suave, sin glow/LUT), `environment.tscn` (1 `Sun` `1.18`, `Bulbs` y `Vignette` ocultos, poda de 11 sub-mallas Z1/Z3 y `test_render_config.gd`) | `[environment.tscn]` |
| **1** | [`PUL-185`](../backlog/PUL-185-tema-ui-hud-y-pegatinas-v3.md) | `ui-engineer` | `default_theme.tres`, `sticker_ink.gd`, `badge_row.gd`, `ticket_entry.gd`, `hud.tscn` y `order_ticket.tscn`: paleta v3 opaca, contrastes ≥ 7.38:1 y anillo `INK` en todos los discos de pegatina | `[hud.tscn, order_ticket.tscn]` |
| **2** | [`PUL-184`](../backlog/PUL-184-puestos-entrega-y-numeros-v3.md) | `ui-engineer` | `deps: [PUL-181, PUL-182]`. `order_stand.tscn` y `stand_palette.tres`: números macizos sin contorno hueco (`#1..#4` en `#1D3557` sobre `#F7F4EC` y `1..4` en `#F7F4EC` sobre `#1D3557`) usando `mat_brand_navy.tres` y `mat_ui_cream.tres` | `[order_stand.tscn]` |
| **2** | [`PUL-186`](../backlog/PUL-186-encimeras-suelo-y-estaciones-v3.md) | `asset-pipeline` | `gltf/embedded_image_handling = 0` en `.glb.import` de `furniture/counters/**` y `stations/**`; asignación de slots reales (`mat_steel_brushed_top`, `counters_atlas`, etc.), poda de atrezo Z1/Z2 y vapor visible en `kitchen.tscn` | `[kitchen_layout.tscn, kitchen.tscn, octopus_storage.tscn, cachelos_storage.tscn, box_shelf.tscn, seasoning_station.tscn, seasoning_dispenser.tscn, cachelos_bowl.tscn, trash_bin.tscn, slot.tscn]` |
| **2** | [`PUL-187`](../backlog/PUL-187-materiales-entorno-comida-y-personajes-v3.md) | `asset-pipeline` | `gltf/embedded_image_handling = 0` en `.glb.import` de `environment/romeria_v2/**` (`mat_hidden_alpha.tres` en `env_sign`/`env_board`, `mat_tent_plate.tres` en `env_plate`, `env_atlas` a `#9A948C`), `cook/**`, `food/**`, `box/**` y `_pipeline/**`; comida, cajas y cocineros | `[box.tscn, octopus.tscn, cachelos.tscn, player.tscn]` |
| **3** | [`PUL-188`](../backlog/PUL-188-integracion-level01-y-limpieza-v2.md) | `asset-pipeline` | Integración en `level_01.tscn`, borrado definitivo de `.png` extraídos en `assets/models/**/*.png`, limpieza de `materials/v2/**`, `textures/v2/**` y `romeria.blend`, y ajuste de `test_assets_models.gd` contemplando slots funcionales | `[level_01.tscn]` |
| **4** | [`PUL-189`](../backlog/PUL-189-qa-visual-y-rendimiento-v3.md) | `qa-tester` | QA visual antes/después con la misma cámara y script a `1920×1080` y `800×370` (deriva 0.0 px, contrastes §3.4 ≥ 3:1) y medida de rendimiento/memoria con idéntico método (línea base medida sobre `main` antes de oleada 1) | `[]` |

### 8.1 Relación con las fichas de arte v2 abiertas (`PUL-144`, `PUL-145`, `PUL-146`)
- **`PUL-144` (vapor y tapa de la olla)**: **parcialmente absorbida en `PUL-186` y pospuesta en geometría**. El refuerzo del vapor `Steam` en `kitchen.tscn` al cocer (D2 de PUL-087) se incluye en `PUL-186`; el remodelado de la tapa en `art/blender/pot.blend` (D3) queda fuera de esta primera oleada porque D28 prohíbe remodelar `.glb`.
- **`PUL-145` (ambiente y brillo del acero delantero)**: **obsoleta**, sustituida íntegramente por `PUL-183` y `PUL-186` (se apagan las `Bulbs` que creaban las manchas especulares sobre el frontal y se reemplaza el acero PBR por `mat_surface_top.tres` y `mat_brand_navy.tres` con `specular_mode = SPECULAR_DISABLED`).
- **`PUL-146` (compartir materiales y texturas entre `.glb` y retirar fuente v1)**: **absorbida y superada por `PUL-186`, `PUL-187` y `PUL-188`**, que redirigen los `.glb.import` a la biblioteca compartida de 18 `.tres` en `assets/materials/v3/`, fijan `embedded_image_handling = 0`, eliminan los cientos de `.png` PBR extraídos junto a los `.glb` y retiran `art/blender/romeria.blend`.

---

## 9. Checklist de verificación por ficha de implementación

1. **Paleta y materiales**: el recurso `.tres` pertenece a los 18 de `godot/assets/materials/v3/` (§3.1), usa uno de los 16 hex de §2, tiene `metallic == 0.0`, `specular_mode == SPECULAR_DISABLED` y 0 texturas PBR de ruido/ORM/normal.
2. **Importación `.glb`**: `materials/extract == 0` y `gltf/embedded_image_handling == 0` en todos los `.glb.import` (`test_assets_models.gd`).
3. **Geometría y contratos**: 0 `.glb` remodelados, 0 cambios de posición de estaciones o `Marker3D` (**0.0 px** de deriva en pantalla), y nodos requeridos por tests (`Bulbs`, `Vignette`, `SizePanel_*`) ocultos con `visible = false`, nunca eliminados del árbol.
4. **Legibilidad y §3.4**: todo color de §3.4 mantiene contraste **≥ 3:1** frente a su superficie de soporte (§6.2), las pegatinas llevan anillo exterior `StickerInk.INK` (§6.2.1) y los números de puesto usan glifos macizos con `outline_size = 0` y contraste **11.24 : 1** (§6.3).
5. **Verificación**: `tools/verify.sh` en verde y `tools/check_owns.py` limpio.

---

## 10. Decisiones cerradas y preguntas abiertas para el responsable

### 10.1 Decisiones ya cerradas e incorporadas
- **D28 (2026-10-17)**: adopción de la **Dirección A · «Feira Clara»** de PUL-180 con una primera oleada solo de materiales y escena, sin remodelar `.glb`.
- **Refinamientos de Dirección A (§0.1)**: evolución a `wall_granite #9A948C` (L=0.2994) para granito gallego, frentes de encimera con `brand_navy #1D3557` (L=0.0350) para identidad de marca y contraste tonal (10.12 : 1), y fijación de `env_atlas` en `#9A948C` siguiendo `capture_minimal.gd:558`.
- **D25 / D26 / D27**: 3 condimentos activos en estación, iconos con doble codificación forma + color y soporte móvil a `800×370`.
- **D14 / D16 / D20 / D21**: cámara ortográfica fija, licencias limpias, arte propio y marca **PulpaSA** (propuesta A · Mariña).

### 10.2 Preguntas abiertas para el responsable (sin suponer respuesta)
1. **P1 · SSAO en dispositivos móviles / perfiles modestos**: la biblia fija el SSAO suave de contacto (`ssao_radius = 0.45`, `ssao_intensity = 1.1`) activo por defecto porque separa los módulos planos contiguos en `1920×1080` y `800×370`. ¿Quieres mantenerlo siempre activo en todos los perfiles o añadir un ajuste automático/opción para desactivarlo en GPU móvil si en `PUL-189` representa más de 0,5 ms de tiempo de GPU?
2. **P2 · Disposición final de `PUL-144`, `PUL-145` y `PUL-146` en el backlog**: tras absorber el vapor de `PUL-144` en `PUL-186`, dejar obsoleta `PUL-145` con `PUL-183` y absorber `PUL-146` en `PUL-186..188`, ¿cerramos `PUL-144`, `PUL-145` y `PUL-146` como `cancelled`/`done (absorbed)` en `docs/backlog/README.md`, o prefieres conservar `PUL-144` en pausa para una futura segunda oleada con remodelado de `.glb` (tapa de la olla)?
3. **P3 · Segunda oleada opcional de geometría (`.glb`) tras `PUL-189`**: una vez completada y medida en `PUL-189` esta primera oleada sin tocar `.glb`, ¿querrás abrir una segunda oleada en Blender para simplificar mallas físicamente (eliminar vértices ocultos de `gas_bottle`, `pump`, `cartons`, `env_sign` y biselar cilindros de dispensadores), o damos por cerrado el arte de M3f si `PUL-189` valida calidad y rendimiento?
4. **P4 · Excepción de contraste del pimentón picante (`#8F1A14`) frente al anillo delimitador `StickerInk.INK` (`#2A2320`)**: el contraste directo entre el disco del picante y su anillo da **1,71 : 1** (exacto `1.7105 : 1`), siendo la única combinación de §3.4 por debajo de 3:1. Se justifica con la doble codificación D26 (silueta octogonal frente a circular/ovalada, e icono interior crema `#F7F4EC` con contraste **8.21 : 1**) y en que el propio anillo delimita frente al fondo con **3.11 : 1** (caja roja) y **6.82 : 1** (arena). ¿Se aprueba formalmente esta excepción a AC2 para mantener el anillo oscuro uniforme en todos los discos, o prefieres un tratamiento alternativo para el picante?

