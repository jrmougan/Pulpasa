# ADR-005 — Dimensión: 3D o 2D

- **Estado:** aceptado (2026-10-03): opción A, 3D con cámara ortográfica fija (D14); Enmienda D26
  (escala de UI, perfil de plataforma, safe area y cámara móvil) **propuesta**, pendiente del gate
  humano (PUL-120); Enmienda D27 (botones en fila y zona de botones con safe area, E4) **propuesta**,
  pendiente del gate humano (PUL-137)
- **Fecha:** 2026-10-03; enmiendas 2026-10-11 (D26) y 2026-10-12 (D27)
- **Ficha:** PUL-003; enmiendas PUL-120 (D26) y PUL-137 (D27)
- **Relacionado:** D6 y D14 (`docs/design/decisions.md`), roadmap (fases y gate de M0), ADR-003 §0
  (capa común / específica), ADR-004 §0, `scene-tree.md` §6, inventario §3 y §5

## Contexto

El prototipo Unity es 3D. El responsable duda entre seguir en 3D o pasar a 2D (D14, pendiente).
D14 bloquea las fases 3–8 de M0, no las 0–2: ADR-002, ADR-003 y ADR-004 ya separan una capa común
(núcleos y autoloads, `core/`, datos, UI de pantalla, InputMap, componentes de control) que no
cambia con la decisión.

### Hechos comprobados (prototipo y repositorio)
- **Cámara**: `Main Camera` de `Level_01.unity` es **ortográfica** (`orthographic: 1`, tamaño
  6,37), inclinada unos 38° hacia abajo (`m_LocalRotation.x = 0.323`), en (0,7; 7,49; −5,86).
  Vista 3/4 fija sin perspectiva.
- **Assets 3D existentes** (inventario §5): personaje `freakycapucha.fbx` con sus clips
  (Idle/Walk/Pick/WalkWhileHolding), `Octopus.fbx`, `Condiment.obj`, caja (`Boite Hamburger.fbx`,
  licencia por verificar), muebles propios (`Mueblecajas.fbx`, `order_stand.fbx`) y 6 modelos de
  Pandazole (olla, fogón, nevera, 3 mesas; uso incierto por D6). Candidato a 2.º personaje:
  `BillGatos.fbx`.
- **Assets 2D existentes**: ningún sprite de juego; solo iconos (`octopus`, `salt`, `pepper-hot`,
  `selection`), logo y fondo de ticket.
- **Gate de M0**: "partida lado a lado con Unity" (roadmap).
- **Export**: la fase 8 pide Linux/Web y el Must 1 builds Windows/Linux. `project.godot` usa
  `forward_plus`; en web Godot 4 usa el renderizador Compatibility (WebGL 2), así que una build web
  se verá con ese renderizador.
- **Verificación actual**: capturas del MCP de Godot y tests GUT headless.

### Hipótesis (no medidas en este proyecto)
Las valoraciones de rendimiento, tamaño de descarga, legibilidad y estabilidad de capturas de la
tabla siguiente son **hipótesis** basadas en la escala del juego (una cocina, ~30 objetos, 1–2
personajes) y en el comportamiento general del motor. Se marcan con **(H)** y se validan con las
mediciones de la sección «Mediciones antes del gate».

## Opciones

- **A. 3D con cámara ortográfica fija** (como el prototipo): reaprovecha FBX y layout.
- **B. 2D** (top-down u oblicua con orden por Y), con alguna de estas fuentes de arte:
  - **B1. Packs con licencia** (p. ej. packs top-down CC0 o comerciales de cocina/personajes),
    adaptados; hay que comprobar que cubren olla, cajas, condimentos, pulpo y 2 personajes con
    animación de cargar.
  - **B2. Primitivas y placeholders** (formas, colores e iconos existentes) para M0, sustituidos
    después por arte final. Desbloquea la paridad de reglas pronto, no la visual.
  - **B3. Generación con IA de imagen + revisión humana**: los agentes pueden producir y limpiar
    sprites e iconos con un pipeline (generar, recortar, normalizar tamaño/paleta, montar
    atlas/`SpriteFrames`); un humano aprueba estilo, coherencia entre poses y licencia/términos de
    uso de la herramienta. Las animaciones por direcciones coherentes son el punto débil (H).
- **C. Híbrido 2,5D**: los FBX actuales renderizados a sprites (pre-render por direcciones en
  Blender) y juego en 2D. Pipeline automatizable por script.

## Comparación para Pulpasa

| Criterio | A. 3D ortográfica | B. 2D | C. 2,5D pre-render |
|---|---|---|---|
| **Coste de migrar desde el prototipo** | Bajo: posiciones de `Level_01.unity` reutilizables (ejes: −Z adelante), cámara equivalente, `AnimationTree` desde los clips del FBX | Alto en la capa específica: rehacer layout, colisiones, animación por direcciones. La capa común no cambia | Medio-alto: script de render + todo lo de B salvo dibujar |
| **Assets disponibles** | Casi todos existen (≈ 8 modelos propios + 6 Pandazole); faltan materiales Godot y verificar licencias (caja, condimento) | Ninguno hoy. Necesidad: personaje × ≥ 4 direcciones × 4 animaciones × 2 personajes (M2), ~10 props, suelo, barras. Fuente: B1, B2 o B3 | Se generan desde los FBX; un cambio de modelo exige re-render (automatizable) |
| **Cámara cenital / 3/4** | Directa: `Camera3D` ortográfica a ~38°. Posible oclusión tras muebles altos (H) | Top-down sin oclusión; vista oblicua necesita Y-sort y cuidado con objetos en la mano | Como B |
| **Detección de interacción** | `Area3D` + `InteractionScoring` en el plano XZ (`Vector2`) | `Area2D` + el mismo `InteractionScoring` | Como B |
| **Legibilidad del caos coop** | Buena con contorno y cámara ortográfica; objetos pequeños (botes) quizá peor que en 2D (H) | Siluetas e iconos más claros por defecto (H) | Depende de la nitidez del pre-render a la escala final (H) |
| **Rendimiento / export web** | Holgado en escritorio para esta escena (H). En web, probar con Compatibility: aspecto y FPS sin medir; `.pck` mayor por mallas y texturas (H) | Más ligero y descarga menor (H) | Como B; atlas grandes si hay muchas direcciones (H) |
| **Trabajo para agentes (capturas)** | Capturas sensibles a luz y sombras; aserciones de posición requieren proyectar a pantalla. Estabilidad de capturas sin medir (H) | Capturas probablemente más estables y coordenadas ≈ píxeles (H). B3 añade trabajo de agentes de arte con revisión humana | Como B en ejecución |
| **Gate M0 "lado a lado con Unity"** | Comparación casi 1:1 | La paridad pasa a ser de reglas y flujo, no visual; habría que redefinir el gate | Visualmente cercano (mismos modelos), en otra proyección |
| **Riesgo de plazo** | Bajo: lo que falta es conversión (fase 3) | Depende de la fuente de arte: B2 bajo para M0 pero aplaza el arte; B1 depende de encontrar un pack que encaje; B3 depende de la coherencia entre poses (H) | Medio: pipeline de render |

## Mediciones antes del gate

Para convertir las hipótesis en datos antes de decidir (cada una cabe en una ficha corta de spike,
sin tocar la capa común):
1. **Spike 3D**: escena con la cámara del prototipo, `freakycapucha` y 4–5 props convertidos.
   Medir FPS y tiempo de frame en escritorio y en export web (Compatibility), tamaño del `.pck`/
   descarga web, y tomar capturas.
2. **Spike 2D**: la misma escena con B2 (primitivas + iconos) y, si se encuentra, un pack B1.
   Mismas medidas.
3. **Estabilidad de capturas**: capturar 5 veces la misma escena en headless (`xvfb-run`) para cada
   spike y comparar píxel a píxel; anotar la diferencia máxima.
4. **Legibilidad**: captura con 4 comandas activas, 2 personajes y objetos en mano, a 1280×720;
   revisión humana de si se distinguen pulpo crudo/cocido, cajas S/M/L y los 3 condimentos.
5. **Prueba de B3** (opcional): generar el personaje en 4 direcciones × caminar y valorar
   coherencia y tiempo de limpieza con revisión humana.

## Recomendación (propuesta)

**Opción A: 3D con cámara ortográfica fija**, manteniendo la separación de capas de ADR-003 §0, a
confirmar con las mediciones 1, 3 y 4.

Motivos comprobados: todos los assets necesarios para M0 existen ya en 3D, el prototipo ya usa una
cámara ortográfica 3/4 y el gate de M0 es una comparación visual con Unity. Motivo hipotético:
el coste de producir arte 2D coherente (por cualquiera de B1–B3) supera al de convertir los FBX.
Los riesgos de A (legibilidad de objetos pequeños, capturas menos estables, web) se mitigan con
contorno de resaltado, escala de props legible a tamaño ortográfico 6–7, iconos sobre los objetos
(como en los tickets, M1) y la prueba temprana de export web.

Cuándo elegir B: si las mediciones muestran problemas de legibilidad o web en A, o si aparece una
fuente de arte 2D suficiente (pack B1 que cubra el juego o un pipeline B3 aprobado) y el
responsable acepta redefinir el gate de M0 como paridad de reglas. B2 sirve como paso intermedio en
cualquier caso. La capa común y las fases 0–2 sirven igual.

C es razonable si se quiere 2D sin dibujar, pero suma el pipeline de render a los costes de B sin
ventaja clara frente a A con cámara ortográfica (H).

## Decisión

**Aceptada la opción A (3D con cámara ortográfica fija)** por el responsable el 2026-10-03 (D14).
Rige `scene-tree.md` §2–§3. La fase 3 de M0 incluye una ficha de prueba de export web con el
renderizador Compatibility.

## Consecuencias
- (+) La decisión queda acotada a la capa específica; no reabre ADR-002 ni ADR-004 ni el catálogo
  de señales.
- (+) La comparación separa hechos del prototipo de hipótesis y propone cómo medirlas.
- (−) Mantener la capa común "neutral" impone pequeñas conversiones en 3D (`Vector2(x, z)`).
- (−) Mientras D14 siga pendiente, las fases 3–8 no se pueden planificar en detalle; los spikes
  cuestan 1–2 fichas antes del gate.

## Enmienda D26 (2026-10-11, PUL-120) — Escala de UI, plataforma, safe area y cámara móvil

*Propuesta, pendiente del gate humano.* D26.8 lleva el juego a teléfonos (solo Individual,
apaisado). El estudio de PUL-119 midió que sin `window/stretch` la UI no escala (salvo HUD y tickets
con `UiScale` casero), no hay safe area y la cámara fija da 66,8 px/m sobre el personaje a 1080 de
alto. Especificación medible en `docs/design/features/controles-tactiles.md` (PUL-119). La cámara
ortográfica fija de D14 **se mantiene en PC**; el móvil gana un perfil propio.

### E1. Perfil de plataforma (común)
- `core/platform_profile.gd` (`class_name PlatformProfile extends RefCounted`, puro): `enum Kind {
  DESKTOP, MOBILE }` (MOBILE = «perfil táctil» del diseño); `static func detect(features:
  PackedStringArray, user_args: PackedStringArray) -> Kind`. Regla, en orden: un argumento de usuario
  `--touch` o `--profile=mobile` → `MOBILE`; `--profile=desktop` → `DESKTOP`; alguna de las features
  `mobile`, `web_android` o `web_ios` → `MOBILE`; si no, `DESKTOP`. El adaptador le pasa
  `OS.get_cmdline_user_args()` y las features comprobadas con `OS.has_feature()`. `--touch` (nombre del
  diseño) y `--profile=mobile` son equivalentes; se usan para verificar en PC y con el MCP
  (`godot -- --touch`).
- `GameState` (adaptador, ADR-002 Enmienda 2) gana `var platform: PlatformProfile.Kind` (calculado en
  `_ready`), `var ui_profile: UiProfile` (el del perfil) y `set_platform(kind: PlatformProfile.Kind)`
  (tests); al fijarlo aplica el `UiProfile` del perfil (E3). No hay señal: el perfil no cambia durante la sesión.
- Quién lo lee: el menú principal (ADR-004 §6.5), `TouchControls` (ADR-004 §6.3), `CameraRig` (E5),
  HUD y tickets (disposición, E4) y `GameState` (escala, pausa al perder el foco, pantalla encendida).

### E2. Escalado del lienzo (`project.godot`)
```
[display]
window/size/viewport_width=1280          (sin cambios: unidades de diseño de la UI)
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=4            (sensor_landscape: apaisado, gira con el sensor)
```
- La UI se diseña en unidades de 1280 × 720 y Godot la escala por `min(ancho / 1280, alto / 720)`;
  `expand` da el espacio extra de las pantallas anchas (de 16:9 a 2,4:1). El 3D se sigue pintando a la
  resolución nativa. En escritorio el resultado coincide con el `UiScale` actual (alto / 720) hasta
  1440 de alto: HUD y tickets conservan su tamaño (diseño AC21).
- **Baja de la escala casera**: `UiScale.factor()` y las líneas de `hud.gd` y
  `order_tickets_panel.gd` que ponen `scale` con él (con `stretch` escalarían dos veces).
- Renderizador: sin cambios (`forward_plus`; web en `gl_compatibility`). Renderizador móvil y export
  Android: ficha futura (`export.md`).

### E3. Escala por perfil y mínimos en datos (común)
- `resources/ui_profile.gd` (`class_name UiProfile extends Resource`; el diseño lo llama `UiScaleData`).
  Todas las medidas en **px de pantalla a 1080 de alto**:
  `content_scale: float = 1.0` (se aplica a `get_tree().root.content_scale_factor`, multiplica el
  estiramiento de E2), `text_min_px: float` (36 en móvil), `menu_button_min_px: float` (120),
  `menu_button_gap_px: float` (24), `ticket_width_min: float` (330), `ticket_width_max: float` (380),
  `ticket_height: float` (150), `ticket_gap: float` (16), `hud_block_width: float` (240),
  `top_band_max_px: float` (200), `ticket_icon_px: float` (48), `patience_bar_px: float` (12) y las
  zonas reservadas `stick_zone_fraction: float` (0,5), `stick_zone_top_px: float` (200),
  `button_zone_width_px: float` (390), `button_zone_height_px: float` (240; sustituye a
  `button_zone_top_px` 600, Enmienda D27).
  Instancias `data/config/ui_profile_desktop.tres` (`content_scale` 1,0; mínimos actuales) y
  `data/config/ui_profile_mobile.tres` (valores del diseño). El rango `[0,67, 1,5]` del diseño se cumple
  con el estiramiento de E2 entre 720 y 1080 de alto.
- Invariante (test sobre el tema y las escenas de `ui/` con el perfil móvil, diseño AC14): todo
  `Label`/`RichTextLabel`/`Button` visible mide en pantalla ≥ `text_min_px × alto / 1080` (36 px a
  1080, 24 px a 720). Para no inflar `content_scale`, la ficha sube los tamaños mínimos del tema.
- Conversión en `UiScale` (`ui/widgets/ui_scale.gd`, común, puro; sustituye a `factor()`):
  - `static func px_to_units(px_at_1080: float, canvas_height: float) -> float` = `px_at_1080 ×
    canvas_height / 1080` (unidades de lienzo que miden `px_at_1080` px a 1080 de alto en cualquier
    resolución, estiramiento y `content_scale`; `canvas_height` =
    `get_viewport().get_visible_rect().size.y`).
  - `static func dp_to_units(dp: float, px_per_dp_at_1080: float, canvas_height: float) -> float` =
    `px_to_units(dp × px_per_dp_at_1080, canvas_height)` (ADR-004 §6.2).
  - `static func safe_margins(window_size: Vector2, safe_rect: Rect2, canvas_size: Vector2) ->
    Vector4` (izquierda, arriba, derecha, abajo, en unidades de lienzo); `Vector4.ZERO` si `safe_rect`
    cubre la ventana o está vacío.

### E4. Safe area y zonas reservadas (común)
- `ui/widgets/safe_area_margin.gd` (`class_name SafeAreaMargin extends MarginContainer`): márgenes con
  `UiScale.safe_margins(DisplayServer.window_get_size(), DisplayServer.get_display_safe_area(),
  get_viewport().get_visible_rect().size)` en `_ready` y en `get_viewport().size_changed`. Inyección
  para tests: `set_safe_rect(rect: Rect2)` (el diseño simula 132 / 0 / 132 / 63 a 2340×1080).
- Lo usan como contenedor raíz `hud.tscn`, `order_tickets_panel.tscn`, `touch_controls.tscn`,
  `pause_menu.tscn`, `game_over.tscn` y `main_menu.tscn`.
- Disposición en `MOBILE` (`controles-tactiles.md`, «Maquetación de la banda superior»): HUD y 4
  tickets en una banda superior ≤ `top_band_max_px`; **zonas reservadas** que ni HUD ni tickets tocan:
  stick (x < 50 % del ancho, y ≥ 200 px) y botones (rectángulo anclado a la esquina inferior derecha
  de la safe area: x ≥ ancho − safe der. − 390 px, y ≥ alto − safe inf. − 240 px; Enmienda D27), en
  `UiProfile`. En `DESKTOP` la disposición actual no cambia.
- Colocación de los botones y zona de botones: **Enmienda D27** (sustituye «cambiar sobre el de
  acción» y la zona y ≥ 600 px).

### E5. Cámara: perfiles por datos (específica + núcleo común)
- `entities/camera/camera_rig.tscn` gana script `entities/camera/camera_rig.gd` (`class_name CameraRig
  extends Camera3D`). Rotación y posición de reposo siguen siendo las de la escena (D14: vista 3/4).
  - `@export var desktop_profile: CameraProfile = data/config/camera_desktop.tres`
  - `@export var mobile_profile: CameraProfile = data/config/camera_mobile.tres`
  - `@export var characters: Array[Node3D]` (en `level_01`: `[Player1, Player2]`, índice =
    `character_index − 1`; override de referencia permitido, ADR-003 §2).
  - En `_ready`: perfil = `mobile_profile` si `GameState.platform == MOBILE`, si no `desktop_profile`;
    `set_profile(profile: CameraProfile)` para tests. Aplica `size = profile.ortho_size`.
  - Con `profile.follow`: sigue al personaje activo de J1 (`EventBus.character_switched(1, c)`; empieza
    en `characters[0]`). En `_process`: el foco (punto del suelo al que mira) se mueve con
    `CameraFollow` (amortiguación crítica, `follow_time`); al cambiar de personaje, paneo ease-out de
    `switch_pan_time` hasta el nuevo activo y después sigue (el control no espera a la cámara, D3). El
    foco se recorta para que la vista no salga más de `camera_margin_m` de `play_area_min/max` (con
    `respect_top_band`, excepciones norte y este: notas «Banda superior tapada» y «Zonas tapadas de la
    flecha y de los botones»).
    `position = posición_de_reposo + Vector3(foco.x − foco_reposo.x, 0, foco.y − foco_reposo.y)`;
    `foco_reposo` = corte del eje de la cámara de reposo con el suelo (y = 0). Se congela en pausa.
  - **Flecha de borde** (diseño): nodo `%OffscreenArrow` dentro de `camera_rig.tscn` (`CanvasLayer` +
    `TextureRect` con `icon_mark_offscreen`, como `Vignette` en `environment.tscn`): con el perfil
    móvil, si el personaje inactivo proyecta fuera de pantalla, la flecha (`offscreen_arrow_px` 48 a
    1080) señala su dirección dentro del safe area y a ≥ 16 px de la zona de botones (la lee de
    `GameState.ui_profile`, sin conocer `TouchControls`). Solo lectura de posiciones. Con
    `respect_top_band` respeta también la banda superior (nota «Zonas tapadas de la flecha y de los
    botones»).
  - Sin `follow` (escritorio): no se mueve; idéntico a hoy.
- `resources/camera_profile.gd` (`class_name CameraProfile extends Resource`, común; el diseño lo llama
  `MobileCameraData`): `ortho_size: float = 12.74`, `follow: bool = false`, `follow_time: float = 0.2`,
  `switch_pan_time: float = 0.35`, `camera_margin_m: float = 1.0`, `play_area_min: Vector2`,
  `play_area_max: Vector2` (límite jugable en el suelo, `(x, z)`; los de `level_01` en el `.tres` del
  perfil: hay un solo nivel; un segundo nivel los movería a un recurso del nivel con enmienda),
  `px_per_meter_min: float = 0.0` (dato de verificación), `offscreen_arrow_px: float = 48.0`.
  - `camera_desktop.tres`: `ortho_size` **12,74**, `follow` `false` (66,8 px/m sobre el personaje a
    1080, sin regresión).
  - `camera_mobile.tres`: `ortho_size` **7,0**, `follow` `true`, `follow_time` 0,2, `switch_pan_time`
    0,35, `camera_margin_m` 1,0, `px_per_meter_min` **120**. Con la inclinación actual (factor ≈ 0,788,
    medido: 66,8 px/m con 12,74) da ≈ 121 px/m: el personaje de 1,6 m mide ≥ 192 px a 1080.
- **Medida** (diseño AC10): px/m = altura en pantalla de la proyección de pies y cabeza (1,6 m) del
  personaje activo / 1,6. La mide el test con la cámara real; `ortho_size` se ajusta si no llega.
- **Banda superior tapada** (PUL-133, hallazgo H-01 de PUL-132): `CameraProfile` gana
  `respect_top_band: bool = false` y `top_reach_height_m: float = 0.0` (móvil: `true` y 2,6 m). Con
  `respect_top_band`, la parte de arriba de la vista tapada por safe area + `UiProfile.top_band_max_px`
  (`top_cover_m`, fracción del alto) no cuenta: el foco es el centro de la parte visible
  (`CameraFollow.covered_focus`, `visible_top`) y el recorte (`CameraFollow.clamp_focus_covered`) deja
  que la vista salga por el norte hasta `camera_margin_m + top_reach + top_cover` para que lo alcanzable
  (ollas, su anillo y su prompt) quede bajo la banda. Si la vista es mayor que el área, se centra la
  parte visible (`y` = centro del área − `top_cover_m` / 2), no la vista entera. Escritorio sin cambios.
  Flecha de borde y zona de botones: nota siguiente.
- **Zonas tapadas de la flecha y de los botones** (PUL-134, revisión de PUL-133). Van con
  `respect_top_band` (solo móvil; sin interruptor propio): **sin campos nuevos en `CameraProfile`** ni
  señales nuevas; `signals.md` y `scene-tree.md` no cambian.
  - *Flecha de borde.* El alto tapado arriba (safe area superior + `UiProfile.top_band_max_px`, en
    unidades de lienzo; 0 sin `respect_top_band`) es uno solo para el foco, la detección y la flecha. Un
    inactivo cuyo centro (0,8 m sobre los pies) proyecta bajo la banda cuenta como fuera de cuadro. El
    rectángulo donde se coloca la flecha (safe area menos media flecha) empieza bajo la banda (arriba =
    máx(safe superior, alto tapado)); la flecha sigue a ≥ 16 px de la zona de botones
    (`CameraFollow.edge_point` la desliza hacia arriba o a la izquierda).
  - *Zona de botones como rectángulo tapado.* Es la zona reservada de E4 en unidades de lienzo, anclada
    a la safe area (Enmienda D27): x ≥ ancho − safe der. − `UiProfile.button_zone_width_px`,
    y ≥ alto − safe inf. − `UiProfile.button_zone_height_px` (390 y 240 a 1080), con el ancho y el alto
    leídos de `GameState.ui_profile` (`CameraRig.ui_profile` la sustituye en tests) y la safe area de
    los mismos márgenes que la banda y la flecha (`_safe_margins`, `set_safe_margins` en tests). La
    cámara no lee `TouchConfig` ni conoce `TouchControls`: que los botones quepan en la zona es contrato
    de E4 (Enmienda D27, «Invariante»). Se activa cuando los pies del activo, con el foco ya recortado
    por la banda, proyectan por debajo del borde superior de la zona (franja inferior). Entonces `CameraFollow.clear_east_cover(focus, target_x,
    half_x, area_max_x, margin, east_cover_m, pad) -> Vector2` (puro) mueve el foco al este lo justo
    para que el activo más `pad` (0,5 m de media anchura + 16 px) quede a la izquierda de la zona;
    `east_cover_m` es el ancho de la zona en metros de suelo. Solo mueve hacia el este y no toca `y`;
    fuera de la franja el encuadre es el de la nota anterior.
  - *Excepción este del recorte.* Con la zona activa la vista puede salir por el este hasta
    `camera_margin_m + east_cover_m` de `play_area_max.x` (lo tapado por los botones no cuenta como
    visible, como la banda al norte). La excepción vale para todo el alto de la vista: con el activo
    pegado al este en la franja, la esquina superior derecha enseña el exterior del nivel; se acepta. El
    oeste y el sur siguen en `camera_margin_m`; el norte, con su excepción.
  - *Garantía (opción C, decisión del responsable).* Con el activo en reposo en la plaza de una estación
    con widget (contador N/6 de cada pasaplatos, anillos de cada olla, medidor del cuenco), ni el activo
    ni los widgets de esa estación quedan bajo la zona de botones a 2340×1080, 1920×1080 y 800×370. No se
    garantiza para widgets de estaciones alejadas del activo.
  - *Caso 09 de PUL-133* (contador de los pasaplatos 04-06 bajo los botones con el activo en las ollas):
    era una limitación conocida; **resuelto por la Enmienda D27** (botones en fila, zona más baja) con
    safe area inferior nula, con el residuo aceptado por D27 (≤ 8 px a 800×370 con el activo en z −3,4)
    y el residuo con safe area inferior que se detalla allí («Caso 09»).
  - Escritorio sin cambios: `camera_desktop.tres` no tiene `follow` ni `respect_top_band`; sin flecha ni
    recorte este.
- `core/camera_follow.gd` (`class_name CameraFollow extends RefCounted`, puro, plano del suelo): estado
  `position: Vector2`, `velocity: Vector2`; `func follow(target: Vector2, smooth_time: float, delta:
  float) -> Vector2` (amortiguación crítica, sin oscilación); `func pan_to(target: Vector2, duration:
  float) -> void` y su avance en `follow` (ease-out); `static func clamp_focus(focus: Vector2,
  half_extents: Vector2, area_min: Vector2, area_max: Vector2, margin: float) -> Vector2` (centra si la
  vista es mayor que el área).

### E6. Qué no cambia
D14 (3D ortográfica), capas, `InteractionScoring` (salvo la histéresis, ADR-003 §11.3), el árbol del
nivel salvo `CameraRig` (script y `characters`) y `TouchControls` en `UI` (`scene-tree.md` §2). La capa
común sigue sin tipos de mundo: `PlatformProfile`, `UiProfile`, `UiScale`, `SafeAreaMargin`,
`CameraProfile` y `CameraFollow` usan solo primitivos, `Vector2`, `Vector4`, `Rect2` y `Control`.

**Alternativas descartadas (Enmienda D26).**
1. *Mantener `UiScale.factor()` sin `stretch`.* Solo escalaba HUD y tickets; menús, pausa y game over
   quedaban fijos, sin safe area ni espacio extra en pantallas anchas.
2. *`stretch/mode = "viewport"`.* Pintaría el 3D a 1280 × 720 y lo estiraría: borroso en un 1080p.
3. *Cámara en perspectiva o más alta en móvil.* Cambia la lectura de la planta (D14) y la oclusión;
   el zoom ortográfico + seguimiento conserva la vista 3/4.
4. *Elegir el perfil por «hay pantalla táctil».* Un portátil táctil acabaría con la cámara y los
   controles móviles; manda la plataforma o la bandera.
5. *Dos escenas de cámara.* El nivel tendría que elegir cuál instanciar; un `Resource` por perfil lo
   resuelve en datos.
6. *Flecha de borde en `ui/` escuchando posiciones por el bus.* Metería posiciones de mundo en el
   bus (D14); la cámara ya las conoce.

**Consecuencias (Enmienda D26).**
- (+) Toda la UI escala igual (menús incluidos) y se puede medir en píxeles reales por resolución.
- (+) La cámara de PC no cambia; el móvil gana zoom sin tocar el nivel.
- (−) Con `expand` el lienzo varía de proporción: HUD y tickets deben anclarse a bordes, no a
  posiciones fijas (lo comprueban los tests de disposición de la ficha de UI).
- (−) Con el perfil móvil la cámara no enseña toda la cocina: el jugador depende del seguimiento, la
  flecha de borde y los avisos (tickets, sonidos) para lo que queda fuera.

## Enmienda D27 (2026-10-12, PUL-137) — Botones en fila y zona de botones con safe area

*Propuesta, pendiente del gate humano.* D27 (gate de PUL-136) elige los **botones en fila** para sacar
el contador de los pasaplatos de debajo de los botones (caso 09 de PUL-133). Diseño y medidas:
`docs/design/features/controles-tactiles.md` «Contadores del pasaplatos bajo los botones» y
`docs/evidence/PUL-136/README.md`; recálculo con safe area en `docs/evidence/PUL-137/README.md`. Cambia
E4 (colocación y zona reservada de botones) y la nota «Zonas tapadas de la flecha y de los botones» de
E5. Solo perfil `MOBILE`: escritorio y Local 2P no cambian (no hay `TouchControls` y la cámara de
escritorio no usa la zona). Sin señales nuevas: `signals.md` no cambia.

Medidas en px de pantalla a 1080 de alto; a otra altura se multiplican por alto / 1080
(`UiScale.px_to_units`). «safe der.» y «safe inf.» son los márgenes derecho e inferior de la safe area
en las mismas unidades (`UiScale.safe_margins`).

### D27.1 Colocación (sustituye «cambiar sobre el de acción» de ADR-004 §6.2 y del diseño AC3)
- **Acción** sin cambios: 180 px (72 dp), centro a 48 + 90 px de los bordes derecho e inferior de la
  safe area; zona táctil radio 90 + 12 (`hit_slop_px_1080`).
- **Cambiar** (120 px, 48 dp) a la **izquierda** del de acción, **borde inferior alineado** y **hueco
  horizontal de 24 px** entre los bordes visibles (`button_gap_px_1080`, el mismo dato que el hueco
  vertical de hoy): centro = centro de acción + (−(90 + 24 + 60), 90 − 60) = (−174, +30). Entre centros
  174 px = 102 + 72: las zonas táctiles siguen sin solaparse aunque el de cambiar ganara 12 px de margen.
- **Pausa** sin cambios (esquina superior derecha, en la banda superior, fuera de la zona).

| Resolución | Safe area (izq/arr/der/inf a 1080) | Acción (centro) | Cambiar (centro) |
|---|---|---|---|
| 2340×1080 | nula | 2202, 942 | 2028, 972 |
| 2340×1080 | 132/0/132/63 | 2070, 879 | 1896, 909 |
| 1920×1080 | nula | 1782, 942 | 1608, 972 |
| 800×370 | nula | 752,7, 322,7 | 692,7, 333,0 |

### D27.2 Zona de botones anclada a la safe area (resuelve la duda de PUL-135)
- **Forma.** Rectángulo anclado a la **esquina inferior derecha de la safe area** que se extiende hasta
  los bordes del lienzo (incluye las franjas de safe area de su derecha y de abajo):
  `x ≥ ancho − safe der. − button_zone_width_px`, `y ≥ alto − safe inf. − button_zone_height_px`, con
  **390 × 240 px** a 1080. Con safe area nula: x ≥ ancho − 390, **y ≥ 840** a 1080 (287,8 a 370), el
  valor de D27. Con la de diseño (132/0/132/63) a 2340×1080: x ≥ 1818, y ≥ 777.
- **Por qué anclada y no ensanchada.** Los botones se colocan desde los bordes de la safe area: con la
  derecha de diseño (132 px) el de cambiar en fila llega a ancho − 504 px (ancho − 516 si ganara margen
  de toque), y con la inferior (63 px) el borde superior del toque de acción sube a alto − 303. Una zona
  fija desde el borde del lienzo tendría que ensancharse a ≥ 516 y subir a ≥ 303 px para la peor safe
  area concebible, y taparía mundo sin botones en los dispositivos sin muesca. Anclada, mide lo mismo
  respecto a los botones en cualquier dispositivo.
- **Dato** (`UiProfile`, E3): `button_zone_width_px` = 390 (sin cambios, ahora medido desde la safe
  area) y `button_zone_height_px` = 240, **que sustituye a `button_zone_top_px`** (600, medido desde
  arriba). Se expresa desde abajo porque desde arriba no puede seguir a la safe area inferior y porque
  240 es directamente el alto de la pila de botones (48 + 180 + 12). En `ui_profile_desktop.tres` el
  campo se renombra igual (240); escritorio no lo usa.
- **Invariante** (contrato de E4; lo comprueban los tests de PUL-135 y de maquetación): con cualquier
  safe area, el rectángulo de toque de cada botón de la zona (centro ± radio de toque) cae dentro de la
  zona. Con los datos actuales: ancho necesario 48 + 180 + 24 + 120 = 372 px (384 si el de cambiar ganara
  12 px de margen) ≤ 390; alto necesario 48 + 180 + 12 = 240 = 240 (holgura 0: los tests usan 1 px de
  tolerancia por el redondeo de `SafeAreaMargin`). Si `TouchConfig` cambia tamaños, margen o hueco, la
  ficha que lo cambie actualiza `button_zone_*` en el mismo cambio.
- **Qué lee la cámara.** `CameraRig._button_zone(canvas)` = rectángulo de arriba con `button_zone_width_px`
  y `button_zone_height_px` de `GameState.ui_profile` (o `CameraRig.ui_profile` en tests) y los márgenes
  de `_safe_margins(canvas)` (los mismos de la banda y la flecha; `set_safe_margins` en tests). No lee
  `TouchConfig` ni conoce `TouchControls`; `TouchControls` y la cámara leen la misma safe area de
  `DisplayServer` (por `SafeAreaMargin` y por `UiScale.safe_margins`). Sin campos nuevos en
  `CameraProfile`.
- **Efecto en la cámara.** La franja de botones empieza más abajo (840 frente a 600 con safe nula): el
  recorte este (`clear_east_cover`) se activa con el activo más al sur, y `east_cover_m` pasa a ser el
  ancho de la zona incluida la safe der. (390 + 132 px con la de diseño), así que con esa safe area la
  excepción este del recorte llega más lejos. La flecha de borde evita la zona nueva con la misma regla
  (≥ 16 px). La garantía de la opción C (activo en la plaza de cada estación con widget) se vuelve a
  medir en PUL-138 con las dos safe areas.

### D27.3 Caso 09 (limitación de E5) — resuelto, con residuos
Recalculado con los rectángulos de contador medidos en PUL-136 (`<res>-medidas.json`, variante
`actual`; el encuadre no depende de la safe area derecha ni de la inferior) frente a la zona de D27.2.
Solape = borde inferior del contador más bajo − borde superior de la zona (px reales).

| Resolución | Safe area | Plaza z −3,1 (olla O · E) | z −3,4 (olla O · E) |
|---|---|---|---|
| 2340×1080 | nula | 0 · 0 | 0 · 0 |
| 1920×1080 | nula | 0 · 0 | 0 · 0 |
| 800×370 | nula | 0 · 0 | **6,4** (04-06) · **6,4** (05-06) |
| 2340×1080 | 132/0/132/63 | **20,8 · 22,6** (04-06) | **51,0 · 51,0** (04-06) |
| 1920×1080 | 132/0/132/63 | **20,8 · 22,6** (04-06) | **51,0 · 51,0** (04-06) |
| 800×370 | 132/0/132/63 | **17,7 · 18,3** (04-06) | **28,0 · 28,0** (04-06) |

- **Safe area inferior nula** (Android sin barra de gestos, la mayoría de pantallas en apaisado): caso
  09 resuelto; residuo aceptado por D27, ≤ 8 px a 800×370 con el activo en z −3,4 (6,4 px con el margen
  de toque, 2,3 px con el botón visible). Se descarta B+A2.
- **Safe area inferior > 0** (p. ej. la de diseño, 63 px: indicador de inicio de iOS): los botones suben
  con la safe area y la vista no (la cámara solo descuenta la superior), así que el contador de 04-06
  vuelve a quedar en la zona y bajo los discos visibles (04-05 o 05-06 según la olla): 21-23 px en la
  plaza y 51 px en z −3,4 a 1080 (18 y 28 px a 800×370). **Limitación conocida**, aceptada por el
  responsable al redactar esta enmienda (opción A, consulta de PUL-137): la cámara sigue sin descontar
  la safe area inferior.

### D27.4 Qué no cambia
`TouchConfig` y `touch_config.tres` (se reutiliza `button_gap_px_1080` para el hueco horizontal),
`CameraProfile` y sus `.tres`, `signals.md`, el árbol de `touch_controls.tscn` (la colocación es código
de `refresh_layout`), la zona del stick, la pausa, el perfil de escritorio y Local 2P. La lista de
ficheros y campos de la implementación (PUL-138) está en la Evidence de PUL-137.

**Alternativas descartadas (Enmienda D27).**
1. *Zona fija desde el borde del lienzo y ensanchada* (x ≥ ancho − 516, y ≥ alto − 303): cubre la peor
   safe area de diseño pero tapa 126 px de ancho y 63 de alto de mundo sin botones en los dispositivos
   sin muesca, y deja de ser cierta con una safe area mayor.
2. *Mantener `button_zone_top_px` y restarle la safe area inferior en código*: el dato seguiría
   diciendo «600/840 desde arriba» y significaría otra cosa; desde abajo el dato es el alto real de la
   pila de botones.
3. *Que la cámara lea `TouchControls` o `TouchConfig`* para la zona exacta: acopla la cámara (específica)
   a la UI táctil; el invariante de D27.2 lo sustituye con un test.

**Consecuencias (Enmienda D27).**
- (+) El caso 09 se resuelve sin tocar la caja ni el nivel, solo en el perfil móvil.
- (+) La zona se mide desde la safe area y deja de depender de que la safe area derecha sea < 150 px.
- (−) Holgura 0 por arriba entre el toque de acción y la zona: cualquier cambio de tamaños táctiles
  obliga a revisar `button_zone_*` (lo atrapa el test de PUL-135).
- (−) Con safe area inferior el caso 09 queda como limitación conocida (D27.3).
