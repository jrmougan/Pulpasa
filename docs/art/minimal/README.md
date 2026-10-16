# Exploración de Estética Minimalista (PUL-180)

Propuesta de **3 direcciones de arte minimalistas** para **PulpaSA** frente al estado actual **v2**
(D22, [`docs/art/art-bible.md`](../art-bible.md)), respetando todas las decisiones vigentes:
- **D14:** 3D con cámara ortográfica fija (`size = 12.74` en escritorio, `size = 7.0` en móvil).
- **D16 y D20:** 0 assets o imágenes de terceros; arte propio en Blender y prototipos directos en el motor.
- **D21:** Identidad de marca **PulpaSA** ([`docs/art/brand.md`](../brand.md): azul marino `#1D3557`, rojo pimentón `#D6361F`, crema `#F7F4EC`, dorado aceite `#F2C230`).
- **D26 y §3.4:** Lenguaje de acciones, doble codificación forma + color de los 5 condimentos y legibilidad garantizada también en móvil (`800×370`).

---

## 1. Documentos e imágenes de la exploración

Todas las imágenes son **prototipos ejecutados en el motor Godot 4.7.2** en tiempo de ejecución
([`docs/evidence/PUL-180/capture_minimal.gd`](../../evidence/PUL-180/capture_minimal.gd)) sobre la
misma escena `main.tscn`, conservando la cámara y las coordenadas exactas (`0.0 px` de desviación)
de los 4 puestos, las 2 ollas, la barra y los 2 cocineros:

1. **Estado de partida (v2 actual):** capturas en [`docs/evidence/PUL-180/partida/`](../../evidence/PUL-180/partida/) (`1920×1080` sin HUD, `1920×1080` con HUD y `800×370` móvil).
2. **[Dirección A · «Feira Clara»](direccion-a-color-plano.md)** ([imagen 1080p](direccion-a-color-plano.png) · [capturas completas](../../evidence/PUL-180/direccion_a/)): *Color plano cálido sin texturas, sombras suaves y recorte de atrezo ruidoso para que la romería gallega se lea con claridad de cartel serigrafiado.*
3. **[Dirección B · «Bloques de Romería»](direccion-b-geometrica.md)** ([imagen 1080p](direccion-b-geometrica.png) · [capturas completas](../../evidence/PUL-180/direccion_b/)): *Volúmenes geométricos puros de juguete arquitectónico sobre un escenario azul noche (`#18222C`) de contraste extremo.*
4. **[Dirección C · «Maqueta de Papel»](direccion-c-maqueta-papel.md)** ([imagen 1080p](direccion-c-maqueta-papel.png) · [capturas completas](../../evidence/PUL-180/direccion_c/)): *Maqueta arquitectónica de cartulina marfil y grafito mate donde el mundo estático es monocromo y el color se reserva en exclusiva a lo jugable.*

### Comparativa visual (con comprobación anotada de posiciones en 1080p y vista limpia en 800×370)

- **Comprobación visual anotada a `1920×1080` (AC3):** [`docs/evidence/PUL-180/comprobacion_posiciones_anotada.png`](../../evidence/PUL-180/comprobacion_posiciones_anotada.png)
- **Mosaico comparativo móvil a `800×370` (D26):** [`docs/evidence/PUL-180/comparativa_movil_800x370.png`](../../evidence/PUL-180/comparativa_movil_800x370.png)
- **Cálculo completo de contrastes WCAG de §3.4 (AC2):** [`docs/evidence/PUL-180/contrastes_sec34.md`](../../evidence/PUL-180/contrastes_sec34.md)

---

## 2. Tabla comparativa: v2 actual frente a las 3 direcciones minimalistas (AC4)

*(Métricas de base de la v2 tomadas de la auditoría real en [`docs/evidence/PUL-087/README.md`](../../evidence/PUL-087/README.md) y verificadas sobre `main.tscn`.)*

| Criterio | v2 actual (D22 — Diorama texturizado) | Dirección A · «Feira Clara» (Color plano sin texturas) | Dirección B · «Bloques de Romería» (Geométrica sobre vacío oscuro) | Dirección C · «Maqueta de Papel» (Maqueta blanca + acentos) |
|---|---|---|---|---|
| **Frase de intención** | Diorama denso de feria nocturna/atardecer con texturas PBR, desgaste, 16 props callejeros y 5 luces puntuales. | Color plano cálido sin texturas, sombras suaves y recorte de atrezo ruidoso con calidez de romería. | Volúmenes geométricos puros sobre vacío azul noche (`#18222C`) donde solo hablan la forma y el código cromático. | Maqueta de cartulina marfil y grafito mate (90 % monocroma) con color exclusivo en lo interactivo (10 %). |
| **Tamaño de paleta cerrada** | Abierta (~60 materiales + 69 texturas PNG con variaciones fotográficas). | **16 colores hex** (4 entorno/superficie, 4 jugables, 3 estado, 5 condimentos §3.4). | **14 colores hex** (4 fondo/bloques, 4 jugables, 1 estado extra, 5 condimentos §3.4). | **15 colores hex** (6 papel/grafito, 5 jugables/estado, 4+1 condimentos §3.4 con `#F7F4EC` compartido). |
| **Legibilidad a `1920×1080` (escritorio)** | **Media-alta con fricciones conocidas (PUL-087):** las rayas de la carpa compiten con `#1..#4` (D1), las luces omni crean brillos blancos en encimeras (D7) y los 16 props periféricos distraen la vista. | **Muy alta:** al pasar encimeras a crema mate (`#EDE8DF`), apagar las 5 `OmniLight3D` y eliminar los 16 props callejeros, los 4 puestos, las 2 ollas y la barra se leen sin brillos ni ruido periférico. | **Sobresaliente en foco central:** el vacío `#18222C` recorta la cocina como un tablero flotante; las comandas del HUD superior descansan sobre fondo oscuro uniforme sin geometría detrás. | **Máxima separación figura-fondo:** como el escenario no tiene color saturado, cualquier píxel rojo, azul, amarillo o verde en pantalla pertenece inequívocamente a un cocinero, ingrediente o pedido. |
| **Legibilidad en móvil a `800×370` (D26)** | **Media:** el grano de las texturas de suelo/acero y las sombras duras de múltiples luces reducen la nitidez de las pegatinas de aliño y del estado del pulpo en pantallas pequeñas. | **Muy alta:** superficies lisas `#EDE8DF` y `#D8C8B0` sin grano de textura; las pegatinas D26 y los números `#1..#4` en pastilla `#1D3557` se leen al instante a `800×370`. | **Alta-muy alta:** los bloques de piedra `#EFECE6` sobre faldón `#465666` dan máxima nitidez de bordes en baja resolución, aunque el alto contraste global oscuro/claro es más duro tras varias rondas. | **Sobresaliente:** es la dirección más descansada y clara en `800×370` (incluso con brillo bajo de pantalla móvil), especialmente si las comandas usan estilo ticket de papel `#F7F4EC`. |
| **Contraste WCAG de los 5 colores de §3.4 (requisito ≥ 3:1)** | Variable según la textura y el punto de luz especular donde caiga el ítem (no garantizado uniformemente). | **Cumple 100 % (mín. 3.91:1):** oscuros sobre `#EDE8DF` (**3.91:1** y **7.40:1**); claros sobre `#1D3557` (**7.38:1 a 11.24:1**) y sobre pulpo `#B8283D` (**4.03:1 a 6.14:1**). | **Cumple 100 % (mín. 4.03:1):** oscuros sobre `#EFECE6` (**4.04:1** y **7.66:1**); claros sobre `#1D3557` (**7.38:1 a 11.24:1**) y `#18222C` (**9.26:1 a 14.12:1**). | **Cumple 100 % (mín. 4.03:1):** oscuros sobre papel `#F7F4EC` (**4.34:1** y **8.21:1**); claros sobre grafito `#2A2320` (**9.04:1 a 13.78:1**) y `#1D3557` (**7.38:1 a 11.24:1**). |
| **Coherencia con la marca PulpaSA (`brand.md`, D21) y romería** | **Alta en ambiente, media en limpieza gráfica:** conserva la fiesta callejera, pero las texturas sucias se alejan de la limpieza corporativa del sello vectorial PulpaSA. | **Máxima coherencia global:** une el tono festivo gallego (piedra, prado, mesas de comensales) con el lenguaje plano y los colores exactos del sello **PulpaSA** (`#1D3557`, `#D6361F`, `#F7F4EC`, `#F2C230`). | **Alta con la paleta corporativa, baja con el entorno de romería:** el azul `#18222C`/`#1D3557` encaja con el logo, pero al eliminar el campo y las mesas se pierde la sensación de fiesta al aire libre. | **Media-alta (editorial / gourmet):** funciona muy bien como «planos de franquicia de PulpaSA» (humor corporativo del GDD), pero sacrifica el calor cromático de la carballeira y la feria tradicional. |
| **Coste estimado de rehacer assets (`.glb`, materiales, escenas)** | **0 (estado actual)**, pero arrastra deuda técnica de 239 recursos de material duplicados y 410 PNG importados (PUL-087 D5/D6). | **Bajo (el más rápido de implantar):** **0 `.glb` nuevos obligatorios**. Se reutiliza el 100 % de las mallas actuales de cocina/personajes/comida, se unifican los 239 materiales en **~16 `.tres` planos compartidos**, se eliminan las 69 texturas 3D y se borran 18 nodos de atrezo/luces en `main.tscn`. | **Medio-alto:** además de la paleta de **14 `.tres` planos** y limpiar `main.tscn`, pediría **remodelar en Blender ~10-14 `.glb`** (puestos, ollas, barra e ítems) a primitivas ortogonales puras sin biseles para que la geometría sea tan radical como promete la dirección. | **Bajo-medio:** puede aplicarse ya con **~15 `.tres` planos** sobre las mallas actuales (como demuestra el prototipo) + retoque del tema del HUD (`hud.tscn` / `order_card.tscn`) a tickets de papel `#F7F4EC`; opcionalmente simplificar 4-6 `.glb` de fondo a siluetas de cartulina plegada. |
| **Rendimiento esperado (GPU, VRAM, draw calls, móvil)** | **Base (PUL-087):** 699–728 draw calls, 80.1k tris visibles (149k con sombras), **412 MB de memoria de texturas** (~95 MB en PNGs de assets), 5 `OmniLight3D` + 1 `DirectionalLight3D` + shader DoF. | **Excelente (+ligero en móvil):** **-95 % de VRAM de texturas 3D** (0 PNGs en materiales 3D), **~35-45 % menos draw calls y cambios de estado** al compartir 16 materiales, **-15-20 % de triángulos** (sin 18 props ni farolillos), 1 sola luz direccional y 0 shaders de post-proceso. | **El más rápido en absoluto:** **-95 % de VRAM de texturas 3D**, **~50 % menos draw calls** y **~40 % menos triángulos** al eliminar todo el exterior (muralla, árboles, colinas, mesas y carpa). Ideal para móviles de gama de entrada. | **Excelente (empatado con A):** **-95 % de VRAM de texturas 3D**, **~35-45 % menos draw calls**, 1 sola luz direccional y 0 shaders de post-proceso (salvo que se active un contorno opcional de 1 px). |

---

## 3. Recomendación de dirección de arte

> **Recomendación principal: elegir la [Dirección A · «Feira Clara»](direccion-a-color-plano.md), incorporando dos aciertos puntuales de la Dirección C** (encimera muy clara y carpa sin rayas rojas estridentes).

### Por qué recomendamos la Dirección A (con guiños de C)
1. **Resuelve de golpe los problemas visuales y técnicos de la v2 sin perder el alma de PulpaSA:**
   elimina el grano de texturas, los 16 props callejeros que ensuciaban los bordes (contenedores,
   vallas, barriles, señales), la guirnalda de bombillas y las 5 `OmniLight3D` que quemaban las
   encimeras (D7 de `PUL-087`), pero **conserva la lectura inmediata de que estamos en una romería
   gallega al aire libre** (muralla de piedra, carballeira y mesas de comensales en segundo plano).
2. **Alineación directa con `docs/art/brand.md` (D21) y con §3.4 / D26:** la paleta de 16 colores
   nace directamente de los 4 colores de marca de PulpaSA y de los 5 colores normativos de §3.4,
   garantizando un contraste mínimo de **3.91:1** en todos los condimentos tanto a `1920×1080` como
   en móvil a `800×370`.
3. **Coste de producción mínimo y retorno inmediato:** no exige remodelar los `.glb` en Blender para
   empezar; basta con sustituir los 239 materiales duplicados y las 410 texturas importadas por una
   biblioteca limpia de **16 recursos `StandardMaterial3D` compartidos**, podar los nodos de atrezo
   en `main.tscn` y ajustar `WorldEnvironment` + `DirectionalLight3D`.

### Cuándo elegir en su lugar la Dirección B o la Dirección C
- Elige la **[Dirección B · «Bloques de Romería»](direccion-b-geometrica.md)** si priorizas un look
  de arcade abstracto de **contraste nocturno extremo** donde no exista nada fuera del rectángulo de
  la cocina y estás dispuesto a asumir el remodelado geométrico de estaciones en Blender.
- Elige la **[Dirección C · «Maqueta de Papel»](direccion-c-maqueta-papel.md)** si buscas la **máxima
  radicalidad minimalista y editorial** (donde absolutamente ningún elemento del escenario tenga
  color salvo los objetos interactivos y los tickets del HUD pasen a papel claro `#F7F4EC`).

---

## 4. Preguntas para el responsable (Gate humano)

Para cerrar la decisión y redactar a continuación la `art-bible.md` v3 y las fichas de
implementación, necesitamos que el responsable decida sobre estos 5 puntos:

1. **Elección de dirección base:** ¿adoptamos la **Dirección A («Feira Clara»)** recomendada, la
   **Dirección B («Bloques de Romería»)**, la **Dirección C («Maqueta de Papel»)** o un **híbrido A + C**
   (entorno cálido de romería de A pero con carpa monocroma y contraste de encimeras de C)?
2. **Nivel de contexto exterior alrededor de la cocina:** ¿prefieres conservar las **2 mesas de
   comensales, la muralla y los árboles en versión plana** (como en A y C, para dar contexto de
   romería) o **recortar la cocina como una isla flotante sobre fondo liso** (como en B)?
3. **Carpa superior (`TentA`):** ¿la mantenemos con **acentos suaves sin competir con `#1..#4`**
   (Dirección A), la pasamos a **lona neutra monocroma sin rayas rojas** (Dirección C) o la
   **eliminamos por completo** (Dirección B)?
4. **Tema cromático de las tarjetas del HUD (`OrderCard` y panel de turno):** ¿mantenemos las
   tarjetas actuales en **azul marino PulpaSA (`#1D3557`)** (Direcciones A y B) o las pasamos a
   **tickets de papel claro (`#F7F4EC`) con pastilla interior oscura para los aliños** (Dirección C)?
5. **Alcance sobre las mallas `.glb` en la siguiente oleada:** ¿aplicamos primero el cambio solo por
   **materiales planos compartidos + limpieza de escena e iluminación** (coste bajo, sin reabrir
   Blender) o quieres incluir también una pasada de **simplificación geométrica de mallas `.glb`**
   en Blender?
