# Exploración de Estética Minimalista (PUL-180)

Propuesta de **3 direcciones de arte minimalistas** para **PulpaSA** frente al estado actual **v2**
(D22, [`docs/art/art-bible.md`](../art-bible.md)), respetando todas las decisiones vigentes:
- **D14:** 3D con cámara ortográfica fija (`size = 12.74` en escritorio, `size = 7.0` en móvil).
- **D16 y D20:** 0 assets o imágenes de terceros; arte propio en Blender y prototipos directos en el motor.
- **D21:** Identidad de marca **PulpaSA** ([`docs/art/brand.md`](../brand.md): azul marino `#1D3557`, rojo pimentón `#D6361F`, crema `#F7F4EC`, dorado aceite `#F2C230`).
- **D26 y §3.4:** Lenguaje de acciones, doble codificación forma + color de los 5 condimentos y legibilidad también en móvil (`800×370`).

---

## 1. Documentos e imágenes de la exploración

Todas las imágenes son **prototipos ejecutados en el motor Godot 4.7.2** en tiempo de ejecución
([`docs/evidence/PUL-180/capture_minimal.gd`](../../evidence/PUL-180/capture_minimal.gd)) sobre la
escena `level_01.tscn`, conservando la cámara y las coordenadas exactas a `1920×1080` (`0.0 px` de
desviación máxima) y con una desviación máxima de `0.1 px` por eje (`0.14 px` euclídea, por redondeo de
proyección a baja resolución) en la vista móvil a `800×370` para los 4 puestos, las 2 ollas, la barra y
los 2 cocineros:

1. **Estado de partida (v2 actual):** capturas en [`docs/evidence/PUL-180/partida/`](../../evidence/PUL-180/partida/) (`1920×1080` sin HUD, `1920×1080` con HUD y `800×370` móvil).
2. **[Dirección A · «Feira Clara»](direccion-a-color-plano.md)** ([imagen 1080p](direccion-a-color-plano.png) · [capturas completas](../../evidence/PUL-180/direccion_a/)): *Color plano cálido sin texturas PBR, sombras suaves y recorte de atrezo ruidoso para que la romería gallega se lea con claridad de cartel serigrafiado.*
3. **[Dirección B · «Bloques de Romería»](direccion-b-geometrica.md)** ([imagen 1080p](direccion-b-geometrica.png) · [capturas completas](../../evidence/PUL-180/direccion_b/)): *Volúmenes geométricos puros de juguete arquitectónico sobre un escenario azul noche (`#18222C`) de contraste extremo.*
4. **[Dirección C · «Maqueta de Papel»](direccion-c-maqueta-papel.md)** ([imagen 1080p](direccion-c-maqueta-papel.png) · [capturas completas](../../evidence/PUL-180/direccion_c/)): *Maqueta arquitectónica de cartulina marfil (`#E4DFD5` / `#F7F4EC`) y grafito mate (`#2A2320`) donde el entorno exterior es monocromo y el color se reserva a lo jugable.*

### Comparativa visual (con comprobación anotada de posiciones en 1080p y vista limpia en 800×370)

- **Comprobación visual anotada a `1920×1080` (AC3):** [`docs/evidence/PUL-180/comprobacion_posiciones_anotada.png`](../../evidence/PUL-180/comprobacion_posiciones_anotada.png)
- **Mosaico comparativo móvil a `800×370` (D26):** [`docs/evidence/PUL-180/comparativa_movil_800x370.png`](../../evidence/PUL-180/comparativa_movil_800x370.png)
- **Cálculo completo de contrastes WCAG de §3.4 (AC2):** [`docs/evidence/PUL-180/contrastes_sec34.md`](../../evidence/PUL-180/contrastes_sec34.md)

---

## 2. Tabla comparativa: v2 actual frente a las 3 direcciones minimalistas (AC4)

*(Nota metodológica: las métricas de rendimiento de la v2 proceden de la auditoría histórica en [`docs/evidence/PUL-087/README.md`](../../evidence/PUL-087/README.md). Como `capture_minimal.gd` aplica overrides en memoria y oculta nodos con `visible = false` sin descargar texturas importadas ni unificar los `.glb`, las mejoras de VRAM, draw calls y triángulos de las 3 direcciones se expresan como **hipótesis de producción** para cuando se limpien los recursos en firme, no como mediciones del prototipo).*

| Criterio | v2 actual (D22 — Diorama texturizado) | Dirección A · «Feira Clara» (Color plano sin texturas PBR) | Dirección B · «Bloques de Romería» (Geométrica sobre vacío oscuro) | Dirección C · «Maqueta de Papel» (Maqueta blanca + acentos) |
|---|---|---|---|---|
| **Frase de intención** | Diorama denso de feria nocturna/atardecer con texturas PBR, desgaste, 16 props callejeros y 5 luces puntuales. | Color plano cálido sin texturas PBR, sombras suaves y recorte de atrezo ruidoso con calidez de romería. | Volúmenes geométricos puros sobre vacío azul noche (`#18222C`) donde solo hablan la forma y el código cromático. | Maqueta de cartulina marfil (`#E4DFD5` / `#F7F4EC`) y grafito mate (`#2A2320`) con entorno monocromo y acentos en lo interactivo. |
| **Tamaño de paleta cerrada** | Abierta (~60 materiales + 69 texturas PNG con variaciones fotográficas). | **16 colores hex** (4 entorno/superficie, 4 jugables, 3 estado, 5 condimentos §3.4). | **14 colores hex** (4 fondo/bloques, 5 jugables/estado, 5 condimentos §3.4). | **15 colores hex** (4 papel/grafito, 7 jugables/estado, 4+1 condimentos §3.4 con `#F7F4EC` compartido). |
| **Legibilidad a `1920×1080` (escritorio)** | **Media-alta con fricciones conocidas (PUL-087):** las rayas de la carpa compiten con la zona superior (D1), las luces omni crean brillos blancos en encimeras (D7) y los 16 props periféricos distraen la vista. | **Alta en zona de juego, con un detalle a corregir en el toldo:** encimeras crema mate (`#EDE8DF`), 0 `OmniLight3D` y 16 props ocultos limpian la cocina. *Punto a resolver en biblia v3:* al pintar `env_sign`/`env_board` en `#1D3557` plano mientras se conserva `env_plate` en el toldo, el cartel superior sobre la carpa (y las 2 pizarras del muro) queda como un **rectángulo vacío**. | **Muy alta en foco central:** el vacío `#18222C` recorta la cocina como un tablero flotante y elimina la carpa y el cartel superior; las comandas del HUD descansan sobre fondo oscuro uniforme. | **Alta separación figura-fondo:** el entorno exterior monocromo (`#E4DFD5` / `#CBC5B9`) hace que los colores saturados pertenezcan solo a cocineros, comida, puestos y condimentos (en el prototipo el cartel superior queda también como rectángulo neutro `#CBC5B9` vacío). |
| **Legibilidad en móvil a `800×370` (D26)** | **Media:** el grano de las texturas de suelo/acero y los brillos de múltiples luces restan limpieza a las encimeras, aunque los números `#1..#4` sobre placa blanca mantienen su trazo sólido original. | **Mejor en superficies y pegatinas, pero con regresión visual en `#1..#4` a corregir en v3:** las superficies lisas `#EDE8DF` y `#C4A882` mejoran la limpieza de los iconos D26, pero en [`comparativa_movil_800x370.png`](../../evidence/PUL-180/comparativa_movil_800x370.png) los números `#1..#4` (`OrderLabel` en `#F7F4EC` con `outline_size = 14` sobre placa `#F7F4EC`) se ven **delineados/huecos y degradados** respecto a la partida, y el número frontal `1..4` queda oscuro sobre `#1D3557`. | **Alta nitidez de bordes de estación, con la misma regresión en `#1..#4`:** las losas `#EFECE6` sobre `#1D3557`/`#18222C` recortan bien las estaciones en `800×370`, pero el prototipo arrastra la misma degradación de los números `#1..#4` delineados y `1..4` oscuros sobre `#1D3557`. | **Limpia en fondos, con la misma regresión en `#1..#4`:** los tickets claros `#F7F4EC` y las encimeras lisas dan buen contraste para los iconos D26, pero en `800×370` los números `#1..#4` presentan el mismo trazo hueco degradado del prototipo. *(No se han medido fatiga visual ni brillo bajo; son solo hipótesis).* |
| **Contraste WCAG de los 5 colores de §3.4 (requisito ≥ 3:1)** | Variable según la textura y el punto de luz especular donde caiga el ítem (no garantizado uniformemente). | **Cumple 100 % (mín. estación/UI: 3.9052:1 [3.91:1]; sobre pulpo `#B8283D`: 3.6770:1 [3.68:1]; en cuenco `#8E6B47`: 3.3390:1 [3.34:1]):** `dulce`/`#EDE8DF` = **3.9052:1**, `picante`/`#EDE8DF` = **7.3993:1**; claros sobre `#1D3557` (`aceite` **7.3773:1**, `cachelos` **8.5371:1**, `sal` **11.2449:1**), sobre `#2A2320` (**9.2187:1 a 14.0517:1**) y sobre pulpo `#B8283D` (`aceite` **3.6770:1**, `cachelos` **4.2551:1**, `sal` **5.6047:1**). | **Cumple 100 % (mín. estación/UI/vacío: 4.0418:1 [4.04:1]; sobre pulpo `#B8283D`: 3.6770:1 [3.68:1]):** `dulce`/`#EFECE6` = **4.0418:1**, `picante`/`#EFECE6` = **7.6580:1**; claros sobre `#1D3557` (**7.3773:1 a 11.2449:1**), sobre `#18222C` (`aceite` **9.6125:1**, `cachelos` **11.1237:1**, `sal` **14.6519:1**) y sobre pulpo `#B8283D` (`aceite` **3.6770:1**, `cachelos` **4.2551:1**, `sal` **5.6047:1**). | **Cumple 100 % (mín. estación/UI/grafito: 4.3358:1 [4.34:1]; sobre pulpo `#B8283D`: 3.6770:1 [3.68:1]):** `dulce`/`#F7F4EC` = **4.3358:1**, `picante`/`#F7F4EC` = **8.2150:1**; claros sobre grafito `#2A2320` (`aceite` **9.2187:1**, `cachelos` **10.6680:1**, `sal` **14.0517:1**), sobre `#1D3557` (**7.3773:1 a 11.2449:1**) y sobre pulpo `#B8283D` (`aceite` **3.6770:1**, `cachelos` **4.2551:1**, `sal` **5.6047:1**). |
| **Coherencia con la marca PulpaSA (`brand.md`, D21) y romería** | **Alta en ambiente, media en limpieza gráfica:** conserva la fiesta callejera, pero las texturas sucias se alejan de la limpieza corporativa del sello vectorial PulpaSA. | **Máxima coherencia global:** une el tono festivo gallego (piedra, prado, mesas de comensales) con el lenguaje plano y los colores del sello **PulpaSA** (`#1D3557`, `#D6361F`, `#F7F4EC`, `#F2C230`). | **Alta con la paleta corporativa, baja con el entorno de romería:** el azul `#18222C`/`#1D3557` encaja con el logo, pero al eliminar el campo y las mesas se pierde la sensación de fiesta al aire libre. | **Media-alta (editorial / gourmet):** funciona bien como «maqueta de franquicia de PulpaSA», pero sacrifica el calor cromático de la carballeira y la feria tradicional. |
| **Coste estimado de rehacer assets (`.glb`, materiales, escenas)** | **0 (estado actual)**, pero arrastra deuda técnica de 239 recursos de material duplicados y 410 PNG importados (PUL-087 D5/D6). | **Bajo (el más rápido de implantar):** **0 `.glb` nuevos obligatorios**. Se reutilizan las mallas actuales, se unifican los materiales 3D en **~16 `.tres` planos compartidos** (más la textura `env_plate` del logo e iconos D26/§3.4) y se podan los nodos de atrezo/luces en escena. | **Medio-alto:** además de la paleta de **14 `.tres` planos** y limpiar la escena, pediría **remodelar en Blender ~10-14 `.glb`** (puestos, ollas, barra e ítems) a primitivas ortogonales puras sin biseles para que la geometría sea tan radical como promete la dirección. | **Bajo-medio:** aplicable con **~15 `.tres` planos** sobre las mallas actuales (como demuestra el prototipo) + retoque del tema del HUD (`hud.tscn` / `order_card.tscn`) a tickets de papel `#F7F4EC`; opcionalmente simplificar 4-6 `.glb` de fondo. |
| **Rendimiento esperado (hipótesis de producción vs. base histórica PUL-087)** | **Base histórica (auditoría PUL-087):** 699–728 draw calls, 80.1k tris visibles (149k con sombras), **412 MB de memoria de texturas** (~95 MB en PNGs de assets), 5 `OmniLight3D` + 1 `DirectionalLight3D` + DoF + `Vignette`. | **Hipótesis de producción (alta mejora esperada, no medida con monitors en el prototipo):** ahorro importante de VRAM al retirar las texturas PBR 3D (conservando solo `env_plate` en `capture_minimal.gd:685` y los iconos UI/D26), menos draw calls al compartir ~16 materiales y borrar los props ocultos, y 1 sola luz direccional (0 `OmniLight3D`). *En el prototipo (`capture_minimal.gd:373-392`) se apagan `Vignette`, DoF y `glow`, pero **permanecen activos SSAO** (`radius = 0.45`, `intensity = 1.1`) y `adjustment_enabled`.* | **Hipótesis de producción (máximo ahorro geométrico, no medido en el prototipo):** mayor reducción esperada de draw calls y triángulos al eliminar todo el exterior Z3 (muralla, árboles, mesas y carpa, sin `env_plate`) y 0 `OmniLight3D`. *En el prototipo (`capture_minimal.gd:403-407`) se desactivan **SSAO**, `Vignette`, DoF y `glow`, manteniendo solo `adjustment_enabled`.* | **Hipótesis de producción (similar a A, no medida en el prototipo):** ahorro de VRAM y draw calls al retirar las texturas PBR 3D (conservando `env_plate` en `:685` e iconos D26) y apagar las 5 `OmniLight3D`. *En el prototipo (`capture_minimal.gd:418-425`) se apagan `Vignette`, DoF y `glow`, pero **permanecen activos un SSAO intenso** (`radius = 0.65`, `intensity = 2.8`) y `adjustment_enabled`.* |

---

## 3. Recomendación de dirección de arte

> **Recomendación principal: elegir la [Dirección A · «Feira Clara»](direccion-a-color-plano.md), incorporando dos aciertos puntuales de la Dirección C** (encimera muy clara y carpa sin rayas rojas estridentes) y corrigiendo en la biblia v3 las dos regresiones detectadas en el prototipo.

### Por qué recomendamos la Dirección A (con guiños de C)
1. **Resuelve los problemas visuales y técnicos de la v2 sin perder el alma de PulpaSA:**
   elimina el grano de texturas PBR, los 16 props callejeros que ensuciaban los bordes (contenedores,
   vallas, barriles, señales), la guirnalda de bombillas y las 5 `OmniLight3D` que quemaban las
   encimeras (D7 de `PUL-087`), pero **conserva la lectura inmediata de que estamos en una romería
   gallega al aire libre** (muralla de piedra, carballeira y mesas de comensales en segundo plano).
2. **Alineación directa con `docs/art/brand.md` (D21) y con §3.4 / D26:** la paleta de 16 colores
   nace directamente de los 4 colores de marca de PulpaSA y de los 5 colores normativos de §3.4,
   garantizando un contraste mínimo de **3.9052:1** (3.91:1) en los soportes primarios de estación/UI,
   **3.6770:1** (3.68:1) sobre la cama de pulpo cocido (`#B8283D`) y **3.3390:1** (3.34:1) en el cuenco
   de barro (`#8E6B47`).
3. **Coste de producción mínimo y retorno inmediato:** no exige remodelar los `.glb` en Blender para
   empezar; basta con sustituir los 239 materiales duplicados y las texturas PBR por una biblioteca
   limpia de **16 recursos `StandardMaterial3D` compartidos** (conservando `env_plate` e iconos D26),
   podar los nodos de atrezo en escena y ajustar `WorldEnvironment` + `DirectionalLight3D`.
4. **Puntos del prototipo a resolver obligatoriamente en la `art-bible.md` v3:**
   - **Números de puesto (`#1..#4` y `1..4`) en móvil (`800×370`):** corregir la regresión visual del
     prototipo (`capture_minimal.gd:758-765`), donde `OrderLabel` con texto blanco `#F7F4EC` y
     `outline_size = 14` sobre placa blanca `#F7F4EC` produjo números delineados/huecos y degradados
     respecto a la partida (y `StandNumber` oscuro sobre `#1D3557`). En la v3 deben usarse glifos
     sólidos sin contorno hueco (`#1D3557` macizo sobre `#F7F4EC`, o `#F7F4EC` macizo sobre pastilla
     `#1D3557`).
   - **Cartel superior vacío (`env_sign` / `env_board`) sobre el toldo:** en el prototipo de la
     Dirección A, al sustituir `env_sign` y `env_board` por `#1D3557` plano mientras el faldón del
     toldo ya muestra el logo `env_plate`, el cartel superior (y las dos pizarras pequeñas del muro)
     queda como un rectángulo azul marino vacío. En la v3 debe eliminarse ese cartel superior
     redundante (o dejar un único soporte con la marca).

### Cuándo elegir en su lugar la Dirección B o la Dirección C
- Elige la **[Dirección B · «Bloques de Romería»](direccion-b-geometrica.md)** si priorizas un look
  de arcade abstracto de **contraste nocturno extremo** donde no exista nada fuera del rectángulo de
  la cocina y estás dispuesto a asumir el remodelado geométrico de estaciones en Blender.
- Elige la **[Dirección C · «Maqueta de Papel»](direccion-c-maqueta-papel.md)** si buscas la **máxima
  radicalidad minimalista y editorial** (donde ningún elemento del escenario exterior tenga saturación
  y los tickets del HUD pasen a papel claro `#F7F4EC`).

---

## 4. Preguntas para el responsable (Gate humano) y decisión adoptada

### Decisión del responsable (Gate humano cerrado — 2026-10-17)
- **Dirección elegida:** **Dirección A · «Feira Clara»**.
- **Alcance aprobado:** **materiales y escena** (sustitución por biblioteca de materiales planos compartidos + limpieza de escena, atrezo e iluminación, sin remodelado de mallas `.glb` en Blender en esta fase).
- **Puntos recogidos para la redacción de `art-bible.md` v3 y fichas de implementación:** resolver la regresión visual de los números de puesto `#1..#4` (y `1..4`) en móvil (`800×370`) evitando textos delineados/huecos sobre fondo claro, y retirar o limpiar el cartel superior (`env_sign`/`env_board`) que quedaba como un rectángulo `#1D3557` vacío encima del toldo.

### Preguntas planteadas al responsable
Para cerrar la decisión y redactar a continuación la `art-bible.md` v3 y las fichas de
implementación, planteamos al responsable estos 5 puntos:

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
