# ADR-005 — Dimensión: 3D o 2D

- **Estado:** aceptado (2026-10-03): opción A, 3D con cámara ortográfica fija (D14); Enmienda D26
  (escala de UI, perfil de plataforma, safe area y cámara móvil) **propuesta**, pendiente del gate
  humano (PUL-120)
- **Fecha:** 2026-10-03; enmienda 2026-10-11
- **Ficha:** PUL-003; enmienda PUL-120 (D26)
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
  `button_zone_width_px: float` (390), `button_zone_top_px: float` (600).
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
  stick (x < 50 % del ancho, y ≥ 200 px) y botones (x ≥ ancho − 390 px, y ≥ 600 px), en `UiProfile`. En `DESKTOP` la
  disposición actual no cambia.

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
    foco se recorta para que la vista no salga más de `camera_margin_m` de `play_area_min/max`.
    `position = posición_de_reposo + Vector3(foco.x − foco_reposo.x, 0, foco.y − foco_reposo.y)`;
    `foco_reposo` = corte del eje de la cámara de reposo con el suelo (y = 0). Se congela en pausa.
  - **Flecha de borde** (diseño): nodo `%OffscreenArrow` dentro de `camera_rig.tscn` (`CanvasLayer` +
    `TextureRect` con `icon_mark_offscreen`, como `Vignette` en `environment.tscn`): con el perfil
    móvil, si el personaje inactivo proyecta fuera de pantalla, la flecha (`offscreen_arrow_px` 48 a
    1080) señala su dirección dentro del safe area y a ≥ 16 px de la zona de botones (la lee de
    `GameState.ui_profile`, sin conocer `TouchControls`). Solo lectura de posiciones.
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
  (ollas, su anillo y su prompt) quede bajo la banda. Escritorio sin cambios. Pendiente (PUL-134): la
  flecha de borde y la zona de botones como rectángulo tapado.
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
