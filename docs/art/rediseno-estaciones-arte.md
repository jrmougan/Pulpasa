# PUL-091 · Lectura y rediseño artístico de estaciones

Propuesta para **gate humano**, 2026-10-07. No integrada; no autoriza fichas de implementación.
Fuentes: [biblia v2](art-bible.md), [marca Mariña](brand.md), [materiales](materials-v2.md),
[pipeline](pipeline.md), [referencia elegida](style-refs/referencia-elegida-2026-10-06.png),
[QA PUL-087](../evidence/PUL-087/README.md). Mandan D18 y los contratos actuales hasta que
el responsable apruebe el trabajo de PUL-090. No se ha cambiado ningún asset de producción.

**Recomendación artística:** desarrollar A como base; evaluar la placa elevada de comanda de B
solo si su prueba de oclusión en el nivel supera a A. A deja más aire en Z1 y necesita menos
volumen nuevo. Esto es una recomendación, no una selección aprobada.

## 1. Método y evidencia

- [Nivel con HUD, 1920×1080](../evidence/PUL-091/01_nivel_completo.png),
  [sin HUD](../evidence/PUL-091/00_nivel_sin_hud.png),
  [localizadores numerados](../evidence/PUL-091/auditoria_localizadores.png).
- [Matriz de estados S/M/L](../evidence/PUL-091/06_estados_controlados.png): columnas S, M, L;
  filas vacía, 50 %, llena con picante/sal/aceite/cachelos. Es un **fixture visual**:
  bandejas suspendidas en posiciones controladas, sin probar recetas, entrega ni input.
  La barra de 50 % se muestra explícitamente como lo hace `_cut`; no se cambia el juego.
- `level_01.tscn`, CameraRig real, proyección ortográfica, size **12,74 m**, posición Godot
  `(0,7; 7,49; 5,86)`. Eje trasero de cámara `(0; 0,615662; 0,788011)`: inclinación
  **38° bajo la horizontal**, sin yaw. 1920×1080: **84,77 px/m**; ancho visible 22,6489 m.
  La transformación y resolución medidas están en [states.log](../evidence/PUL-091/states.log).
- Captura nueva desde esta rama, Xvfb, Forward+, RTX 3090, audio Dummy. El script de referencia
  coloca una bandeja condimentada en el pase y objetos en manos; no es una partida jugada.
  Los únicos errores finales de captura son avisos de recursos vivos al cerrar SceneTree,
  también descritos en PUL-087; no hay errores de ejecución durante la captura válida.
- Se puntúa a **1:1**, sin usar el zoom como prueba de lectura. Los recortes `actual_*_1x.png`
  conservan píxeles originales. La lámina comparativa amplía para revisar formas.

### Auditoría de lectura actual

«Claro»: se identifica por forma/señal sin inspección; «dudoso»: requiere contexto, memoria o
comparación; «no se lee»: la imagen no comunica la información pedida. Es una evaluación visual
razonada, no un ensayo con usuarios ni una medición de acierto.

| Elemento / pregunta | Puntuación | Evidencia y observación a 1080p |
|---|---|---|
| Mostrador: ¿qué estación es? | **claro** | [estación](../evidence/PUL-091/actual_station_1x.png): fila de recipientes + cuenco; se separa de cocción y entrega. |
| Pimentón dulce, localizador 1 | **dudoso** | Recipiente rojo/anaranjado de unos 20 px; icono compartido con picante y etiqueta frontal pequeña. No basta el color para nombrarlo. |
| Pimentón picante, 2 | **dudoso** | Silueta más alta y tono oscuro ayudan, pero no hay una señal grande de picante en el cuerpo. No confundirlo con el símbolo de llama que sí aparece en badges. |
| Sal, 3 | **claro** | Salero claro y grano visible; icono blanco pierde contraste sobre el acero claro. Se reconoce mejor el recipiente que la señal de uso. |
| Aceite, 4 | **claro** | Amarillo y pico lateral lo separan de los botes. El icono aislado sigue siendo pequeño. |
| Cuenco de cachelos, 5 | **dudoso** | Cuenco de barro identificable, aparentemente vacío en esta vista; no comunica tan bien el ingrediente ni que se pulsa aquí. |
| ¿Dónde va la bandeja?, 6 | **dudoso** | Hay rectángulo de pase y un plato encima en la captura preparada; vacío parece otro slot y no explica prioridad frente a los botes. |
| ¿Desde qué lado se deja / se condimenta?, 7 | **no se lee** | Los botes hacia el jugador sugieren operar, pero no hay una señal inequívoca de los dos lados ni de la restricción de mano vacía. |
| ¿Qué se pulsa? | **dudoso** | Los iconos flotantes indican ingredientes, no distinguen claramente el objetivo de pulsar del objetivo de depositar. |
| S / M / L sostenida o aislada | **dudoso** | [estados](../evidence/PUL-091/actual_trays_1x.png): círculo/óvalo/rectángulo se distinguen juntos; S y M tienen pocos píxeles de diferencia y la mano/ángulo los oculta. L es la más clara. |
| Vacía frente a llena | **claro** | Fondo papel frente a rodajas rosas; los cachelos se separan por amarillo. |
| ¿Cuánto falta para llenar? | **dudoso** | La barra parcial sí muestra proporción; por comida sola se ven capas discretas, no progreso exacto. Con badges cercanos cuesta asociar cada indicador a su bandeja. |
| ¿Qué lleva? / `badge_row` | **claro**, asociación **dudosa** | Discos de 24 px, separación 3 px y borde de sal funcionan. En tres bandejas contiguas las filas se juntan; no es un fallo del icono individual. |
| Rack / qué talla sale, 8 | **dudoso** | [rack](../evidence/PUL-091/actual_rack_1x.png): pilas visibles; el rack aparece girado 90° respecto a nuestra vista frontal de concepto. Letras y profundidad no explican con rapidez cada pila. |
| Encimeras / slot libre, 9 | **claro** en fila central; **dudoso** delante | [encimeras](../evidence/PUL-091/actual_counters_1x.png): rectángulos oscuros delimitan lugares. D7: acero delantero brillante reduce su separación con la bandeja y las marcas claras. |
| Kiosco 1–4 estable | **claro** | [kioscos](../evidence/PUL-091/actual_kiosks_1x.png): número en disco frontal + color de toldillo, dos canales redundantes. |
| ID de comanda / kiosco libre, 10 | **dudoso** | `#1`, `#2` y guion se superponen a rayas; D1 confirmado. Número estable e ID de pedido pueden parecer duplicados cuando coinciden. |

D2 (vapor) y D3 (tapas) se consultaron: siguen visibles en la captura de cocina, pero son de
cocedores y quedan fuera de este rediseño. No se proponen cambios para ellos aquí.

**Divergencia de fuentes que debe resolverse antes de implementar:** la biblia §2.5 prescribe
pimentón dulce `#D6361F`, picante `#8F1A14`, cachelos `#F2D56B`; los `.tres` actuales contienen
respectivamente `(0.95,0.55,0.2)`, `(0.85,0.12,0.1)` y `(0.9,0.8,0.5)`. Los conceptos siguen
la biblia, pero una ficha futura deberá armonizar dispensador, ticket y badge juntos. No cambiar
solo una representación ni interpretar esta propuesta como permiso para editar datos.

## 2. Lenguaje común de affordances

| Significado | Forma e icono | Color/material | Regla visual |
|---|---|---|---|
| Aquí se deja | Contorno rectangular abierto hacia el usuario; esquinas en A / guía en U en B | Papel `#F4EFE6` + marino `#1D3557` | Interior despejado para el objeto; señal sobre la superficie, nunca badge flotante que parezca condimento. |
| Aquí se pulsa | Disco elevado A / paleta baja B, con icono canónico del ingrediente | Cara papel, tinta marino; recipiente en color de ingrediente | No usar un rectángulo igual al de depósito. Diámetro útil objetivo 0,20–0,24 m (17–20 px). |
| Desde este lado | Dos chevrones hacia el borde de uso, repetidos en el canto; retorno lateral en B | Marino sobre papel; desgaste fuera de la señal | Pintura/decal, relieve final ≤ 2 cm en suelo. Visibilidad de ambas caras se decide con PUL-090. |
| Vacío | Papel del fondo visible, ranura de depósito abierta | Papel / plástico pimentón | No añadir decoración que imite comida. |
| Parcial | Relleno por capas y barra con tramo lleno + tramo pendiente | Rodajas existentes; barra contrastada | La barra conserva la proporción real; no inventar un número fijo de cortes. |
| Lleno | Rodajas cubren el fondo; fin de barra | Comida saturada sobre papel | **Lleno no equivale a pedido correcto**. No poner un check de entrega. |
| Listo | Variante opcional de doble trazo / pestaña | Papel y marino, nunca solo verde | **Condicional PUL-090**: requiere definición y evento de “listo”; el `=` de B es una muestra, no lógica aprobada. |
| Lleva un condimento | Disco con icono canónico, sal con anillo; picante con llama | Paleta §2.5 | Conservar orden canónico y billboard. Logo en canto frontal inferior, fuera de badges. |
| Este es el kiosco | Cifra estable en disco, color en toldillo | `mat_canvas_stand_1..4`, papel + tinta | El ID variable va en placa rectangular aparte; no duplicar la misma forma. |

Los colores de ingredientes amarillos son funcionales, no una combinación de marca rojo/amarillo.
Marca: pimentón `#C8402F` con marino/papel; no logotipo inventado. La marca horizontal solo se
aplica si llega a 120 px; por debajo, símbolo oficial en el canto Z2. Las maquetas no añaden
logotipos diminutos que no serían legibles. Mantener biseles de 2–3 cm y desgaste grueso en Z2;
ningún patrón de alto contraste sobre Z1.

Objetivos para la implementación: símbolos informativos ≥ 6 px, iconos de dispensador ≥ 12 px,
marcas principales 0,07–0,10 m según orientación (la proyección acorta el eje de profundidad),
placa de comanda con cifras ≥ 18 px. Medir en Godot, no inferir cumplimiento por la ampliación.
Los rótulos secundarios «DOCE», «PIC.», «SAL», «ACEITE», «DEIXAR» son apoyo en gallego;
no se usan para dar por resuelta la lectura desde lejos.

## 3. Dos direcciones completas

[Lámina actual / A / B](../evidence/PUL-091/comparativa_actual_A_B.png).
[Blender A](../../art/concepts/estaciones/direction_A.blend) ·
[Blender B](../../art/concepts/estaciones/direction_B.blend).
Cada `.blend` contiene colecciones `station`, `trays`, `rack`, `counters`, `kiosks` y estudio.
Los textos 3D son marcadores de maqueta; en producción se usa Montserrat/atlas de la marca. No son escenas exportables de producción ni cambian anchors/colisiones. Renders originales CLI.

| Elemento | A · Señalética de pase | B · Guías y mandos físicos |
|---|---|---|
| Mostrador y lados | Faja marino fina, etiquetas de ingrediente en frente; chevron pintado hacia operación, pase trasero despejado. | Faja con retornos papel a los laterales; carril de colocación reconocible por volumen bajo. |
| Dulce | Lata ancha baja, botón circular papel con pimiento. | Paleta rectangular papel sobre lata; evita confundir la boca con depósito. |
| Picante | Lata estrecha facetada, pimiento + llama, lengüeta. | Paleta rectangular con llama desplazada; mismo código que el badge. |
| Sal | Salero ancho con tapa oscura, icono oscuro en botón claro. | Paleta clara sobre tapa; anillo oscuro conserva lectura sin depender del blanco. |
| Aceite | Botella con pico lateral visible y botón de icono. | Pico y paleta alargada; todos los mandos siguen una misma línea de uso. |
| Cuenco cachelos | Boca abierta con cachelos grandes visibles, sin falso vaciado. | Dos asas cortas de barro y placa de pulsación con patata en el borde; misma comida visible. No simula stock finito. |
| Bandeja de pase | Cuatro esquinas oscuras sobre campo papel; objeto dentro, dirección marcada fuera. | U clara alrededor del acero; entrada abierta hacia uso. |
| Bandejas S/M/L | Círculo/óvalo/rectángulo con asas y letra en borde para lectura secundaria. | Mismas siluetas, una/dos/tres muescas en borde; no nuevos tamaños ni capacidades. |
| Relleno | Capas actuales; barra proporcional separada del papel. | Capas actuales; posible pestaña de fin (`=`), **condicional**. No se decide receta ni corte. |
| Condimentos / badges | Discos canónicos encima, un único hueco claro respecto al plato. | Los mismos discos y colores sobre un subrayado que los agrupa por bandeja (condicional de vista); muescas del borde liberan la letra. La pestaña no sustituye badges. |
| Rack | Pilas separadas con guías finas, placa S/M/L en frente de cada pila. | Testero elevado de cada pila con S/M/L; muestra la talla por encima del acero, a costa de más oclusión. |
| Encimeras / slots | Esquinas, papel y flecha; no añade volumen a la zona de trabajo. | Guía U y pestaña frontal de cada slot; perfil final mínimo para no parecer obstáculo. |
| Kioscos | Placa papel detrás del ID sobre toldillo; número fijo en disco inferior. | Bandera elevada con ID, alejada de rayas; disco inferior estable igual a A. |

Renders por familia: [A estación](../../art/concepts/estaciones/A_station.png),
[B estación](../../art/concepts/estaciones/B_station.png),
[A bandejas](../../art/concepts/estaciones/A_trays.png), [B bandejas](../../art/concepts/estaciones/B_trays.png),
[A rack](../../art/concepts/estaciones/A_rack.png), [B rack](../../art/concepts/estaciones/B_rack.png),
[A encimeras](../../art/concepts/estaciones/A_counters.png), [B encimeras](../../art/concepts/estaciones/B_counters.png),
[A kioscos](../../art/concepts/estaciones/A_kiosks.png), [B kioscos](../../art/concepts/estaciones/B_kiosks.png).

### Qué demuestran y qué no los renders

Misma inclinación ortográfica real. Los detalles usan distinto encuadre para estudiar geometría;
las hojas [A nativa](../../art/concepts/estaciones/A_native_1080.png) y
[B nativa](../../art/concepts/estaciones/B_native_1080.png) usan **exactamente 84,77 px/m** sin
escalar las piezas. Su distribución es una mesa de revisión, no el layout de `level_01`.
La luz neutra de estudio no reproduce el entorno Godot: **no prueba** contraste final ni D7.
Blender de esta máquina avisa de incompatibilidad OCIO 2.5/2.4 y usa fallback; los hex de diseño
son normativos, los píxeles de los renders no son una prueba colorimétrica.

El rack se muestra frontal en el detalle para evaluar ambas alternativas; en el nivel está girado.
La implementación debe repetir rótulos en cara superior/lateral visible y validar esa orientación
antes de cerrar su ficha. Las letras S/M/L, las muescas y las señales de pulsar necesitan esa misma
prueba a escala nativa: no se afirma aquí que todos los detalles de los conceptos ya pasan ≥ 6 px.

## 4. Presupuesto y cambios para implementación después del gate

Los recuentos **medidos** del concepto están en `budget_A.json` / `budget_B.json`: malla evaluada,
modificadores y texto triangulado; incluyen todas las instancias de la lámina, no son un coste por
asset. Los rótulos de producción se hornearán en atlas; no se exportarán curvas tipográficas.

| Colección medida | A (tris) | B (tris) | Contenido contado |
|---|---:|---:|---|
| station | 3 618 | 4 250 | Conjunto completo, 4 dispensadores y cuenco |
| trays | 10 137 | 10 278 | Nueve bandejas, capas, tres filas de badges y barras |
| rack | 5 801 | 5 541 | Rack con 12 bandejas apiladas y rótulos |
| counters | 3 272 | 3 999 | Tres metros + dos bandejas con relleno |
| kiosks | 7 717 | 8 197 | Cuatro kioscos, IDs de ejemplo diferentes de 1–4 |

| Asset / futura unidad de trabajo | Objetivo de producción (tris) | Máximo biblia | Cambios a preparar después del gate |
|---|---:|---:|---|
| `seasoning_station` completo | 4 800 (A), 5 200 (B) | 6 000 conjunto | Mostrador y pase; cuatro recipientes ≤ 0,25 m, caras de pulsar; cuenco; marcas de lados en atlas. Conservar anchors, separaciones y acceso. |
| `box`, cada S/M/L con relleno máximo | 1 600 | 2 000 | Reborde/asa, letra o muescas sin tapar comida, conservar banda por talla y papel con patrón ≤ 15 %. Quitar caras ocultas. |
| `badge_row` | 24 extra como techo para 4 badges de 3 quads | Dentro de 2 000/bandeja | Reusar SVG y configuración actuales; composición y separación, no más mallas por condimento. Cambiar script solo en futura ficha autorizada. |
| `box_shelf` completo | 5 600 | 6 000 | Pilas diferenciadas; guías, paneles por talla; señales superior/lateral visibles con rotación real. Mantener origen de spawners. |
| `counters`, módulo 1 m | 1 000 | 1 500 | Atlas de esquinas/U, contraste con acero, preservar anchor de slot. Módulos 2/3 m reutilizan segmentos. |
| `order_stand`, un kiosco | 3 500 | 6 000 | Placa de comanda separada del número; toldillo y TPV secundario, variantes 1–4. No fijar el ID variable en textura. |

Materiales **enlazados y reutilizados** de `_materials_v2.blend`: `mat_steel_brushed_top`,
`mat_steel_brushed_mid`, `mat_steel_dark`, `mat_plastic_red`, `mat_food_tray_liner`, `mat_clay`,
`mat_food_potato_cooked`, `mat_food_octopus_pieces`, `mat_food_octopus_raw`, `mat_canvas_paper`,
`mat_canvas_stand_1..4`. No modificar biblioteca en esta ficha. Las superficies marino/papel y
etiquetas se resuelven con **atlas propio**, permitido por §3.3; el script usa muestras del atlas
para maquetar, que deberán consolidarse a un material por atlas en producción.

Propuesta de atlas: estación 512² (etiquetas, símbolos y desgaste Z2), bandejas/rack compartido
512², counters 512², kioscos 512²; reaprovechar los ya existentes antes de añadir. 256 px/m,
sin ruido informativo < 4 px, ningún mapa > 1024². Iconos usados aquí son los **ya existentes en
el repositorio**, rasterizados localmente con ImageMagick; no se descargó imagen/modelo externo.
El estudio y sus materiales no se exportan. Los PNG de iconos de esta carpeta son fuentes de
concepto, no nuevos assets de Godot.

D5/D6 del QA advierten de recursos duplicados por GLB: no vender este recuento por nombres como
prueba de deduplicación. La ficha futura de pipeline debe medir recursos reales y texturas, y
repetir el presupuesto de nivel ≤ 250 000 tris, ≤ 1 000 draw calls y 60 fps/1080p. Aquí no se ha
medido rendimiento de A/B en juego porque no están integradas.

## 5. Dependencias y gate

| Condición pendiente de PUL-090 / responsable | Tratamiento artístico provisional |
|---|---|
| Un lado o ambos pueden operar; quién deja/recoge | Chevrones y retornos son capas removibles. Si ambos operan, duplicar señal sin flecha exclusiva. No cambiar colliders por inferencia artística. |
| Pase obligatorio / alternancia / bandeja común | A y B conservan el pase actual; retirar o duplicar señal solo tras aprobar reglas. |
| Toggle, sustitución de pimentón, mano vacía | Mantener iconos de ingredientes; no grabar «añadir» ni «quitar» permanentemente. Confirmar semántica antes de animar botones. |
| Cómo se llena / cuánto falta | Barra proporcional a `fill`; capas como vista. No dividir el plato en un número de cortes supuesto. |
| Qué significa “listo” | B muestra una pestaña hipotética; apagada/ausente hasta definición. Ningún check implica comanda válida. |
| Stock de cachelos o dispensadores | Sin indicadores de cantidad; la comida del cuenco identifica su función. |
| Colisiones y layout / posición del rack | No cambian aquí. Si A/B requiere más hueco físico, pasa por diseño/arquitectura y gate. |
| Cambios de D18, `badge_row` o anchors/señales | Fuera de esta propuesta; ADR y gate si afectan contratos. |

**Gate humano solicitado para revisión, no ejecutado aquí:** escoger A/B o mezcla por familia,
confirmar lenguaje de depósito/pulsación y resolver dependencias PUL-090; después el producer
podrá crear las fichas de arte. Este documento no crea fichas nuevas ni modifica contratos.
Criterio de aceptación de esas futuras fichas: repetición de esta matriz con assets integrados,
slots vacío/ocupado, bandejas próximas y sostenidas por ambos jugadores, giro real del rack,
cuatro kioscos con IDs diferentes de su número y sin comanda; comprobar ≥ 6 px y oclusiones a
1920×1080, además de verify y presupuestos medidos.
